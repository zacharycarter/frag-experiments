import atomics, osproc, os,
       fiber, platform, pool, threading
type
  JobPriority = distinct int32
  Job* = ptr int32
  
const
  jpHigh = JobPriority(0)
  jpNormal = JobPriority(1)
  jpLow = JobPriority(2)
  jpCount = JobPriority(3)

type
  JobCallback* = proc(rangeStart, rangeEnd, threadIdx: int32; userData: pointer) {.cdecl, gcsafe.}

  JobObj = object
    jobIndex: int32
    done: bool
    ownerTid: uint32
    tags: uint32
    stackMem: FiberStack
    fiber: Fiber
    selectorFiber: Fiber
    counter: Job
    waitCounter: Job
    ctx: ptr JobContext
    callback: JobCallback
    userData: pointer
    rangeStart: int32
    rangeEnd: int32
    priority: JobPriority
    next: ptr JobObj
    prev: ptr JobObj

  JobThreadData = object
    curJob: ptr JobObj
    selectorStack: FiberStack
    selectorFiber: Fiber
    threadIdx: int32
    tid: uint32
    tags: uint32
    mainThread: bool

  JobPending = object
    counter: Job
    rangeSize: int32
    rangeRemainder: int32
    callback: JobCallback
    userData: pointer
    priority: JobPriority
    tags: uint32
    
  JobContextDesc* = object
    numThreads*: int32
    fiberStackSize*: int32
    maxFibers*: int32

  JobSelectResult = object
    job: ptr JobObj
    waitingListAlive: bool

  JobContext* = object
    threads: ptr UncheckedArray[Thread[tuple[one: pointer; two: pointer]]]
    numThreads: int32
    stackSize: int32
    jobPool {.align: 16.}: ptr Pool
    counterPool {.align: 16.}: ptr Pool
    waitingList: array[jpCount, ptr JobObj]
    waitingListLast: array[jpCount, ptr JobObj]
    tags: seq[uint32]
    jobLock: SpinLock
    counterLock: SpinLock
    dummyCounter: int32
    sem: Semaphore
    quit: bool
    pending: seq[JobPending]

const
  counterPoolSize = 256
  defaultMaxFibers = 64
  defaultFiberStackSize = 1048576 # 1MB

var tData {.threadvar.}: ptr JobThreadData

converter toInt32(jp: JobPriority): int32 = int32(jp)

proc delJob(ctx: ptr JobContext; job: ptr JobObj) =
  withLock(ctx.jobLock):
    poolDel(ctx.jobPool, job)

proc fiberFn(transfer: FiberTransfer) =
  let
    job = cast[ptr JobObj](transfer.userData)
    ctx = job.ctx

  job.selectorFiber = transfer.prev
  tData.selectorFiber = transfer.prev
  tData.curJob = job

  job.callback(job.rangeStart, job.rangeEnd, tData.threadIdx, job.userData)
  job.done = true

  discard fiberSwitch(transfer.prev, transfer.userData)

proc jobAddList(pFirst, pLast: ptr ptr JobObj; node: ptr JobObj) {.inline.} =
  if not isNil(pLast[]):
    (pLast[]).next = node
    node.prev = pLast[]
  pLast[] = node
  if isNil(pFirst[]):
    pFirst[] = node

proc jobRemoveList(pFirst, pLast: ptr ptr JobObj; node: ptr JobObj) {.inline.} =
  if not isNil(node.prev):
    node.prev.next = node.next
  if not isNil(node.next):
    node.next.prev = node.prev
  if pFirst[] == node:
    pFirst[] = node.next
  if pLast[] == node:
    pLast[] = node.prev
  node.next = nil
  node.prev = node.next

proc newJob(ctx: ptr JobContext; idx: int32; callback: JobCallback;
            userData: pointer; rangeStart, rangeEnd: int32;
            counter: Job; tags: uint32; priority: JobPriority): ptr JobObj =
  result = cast[ptr JobObj](poolNew(ctx.jobPool))

  if result != nil:
    result.jobIndex = idx
    result.ownerTid = 0
    result.tags = tags
    result.done = false
    if isNil(result.stackMem.stack):
      discard fiberStackInit(addr result.stackMem, ctx.stackSize)
    result.fiber = fiberCreate(result.stackMem, fiberFn)
    result.counter = counter
    result.waitCounter = cast[Job](addr ctx.dummyCounter)
    result.ctx = ctx
    result.callback = callback
    result.userData = userData
    result.rangeStart = rangeStart
    result.rangeEnd = rangeEnd
    result.priority = priority
    result.prev = nil
    result.next = result.prev

proc jobSelect(ctx: ptr JobContext; tid, tags: uint32): JobSelectResult =
  withLock(ctx.jobLock):
    var jp = jpHigh
    while jp < jpCount:
      var node = ctx.waitingList[jp]
      while node != nil:
        result.waitingListAlive = true
        if cast[ptr int32](node.waitCounter)[] == 0:
          if (node.ownerTid == 0'u32 or node.ownerTid == tid) and
            (node.tags == 0'u32 or (node.tags and tags) != 0):
            result.job = node
            jobRemoveList(addr ctx.waitingList[jp], addr ctx.waitingListLast[jp], node)
            jp = jpCount
            break
        node = node.next
      inc(jp)

proc jobSelectorMainThread(transfer: FiberTransfer) {.gcsafe.} =
  let ctx = cast[ptr JobContext](transfer.userData)

  let r = jobSelect(ctx, tData.tid, if ctx.numThreads > 0: tData.tags else: 0xffffffff'u32)

  if r.job != nil:
    if r.job.ownerTid > 0:
      r.job.ownerTid = 0

    tData.selectorFiber = r.job.selectorFiber
    tData.curJob = r.job
    r.job.fiber = fiberSwitch(r.job.fiber, r.job).prev

    if r.job.done:
      tData.curJob = nil
      atomicDec(cast[var Atomic[int32]](r.job.counter))
      delJob(ctx, r.job)

  tData.selectorFiber = fiberCreate(tData.selectorStack, jobSelectorMainThread)
  discard fiberSwitch(transfer.prev, transfer.userData)

proc jobSelectorFn(transfer: FiberTransfer) {.gcsafe.}  =
  let ctx = cast[ptr JobContext](transfer.userData)

  while not ctx.quit:
    semaphoreWait(ctx.sem)

    var r = jobSelect(ctx, tData.tid, tData.tags)

    if r.job != nil:
      if r.job.ownerTid > 0:
        r.job.ownerTid = 0

      tData.selectorFiber = r.job.selectorFiber
      tData.curJob = r.job
      r.job.fiber = fiberSwitch(r.job.fiber, r.job).prev

      if r.job.done:
        tData.curJob = nil
        atomicDec(cast[var Atomic[int32]](r.job.counter))
        delJob(ctx, r.job)
    elif r.waitingListAlive:
      semaphorePost(ctx.sem, 1)
      cpuRelax()

  discard fiberSwitch(transfer.prev, transfer.userData)

proc jobCreateTData(tid: uint32; idx: int32; mainThread: bool  = false): ptr JobThreadData =
  result = createShared(JobThreadData)
  result.threadIdx = idx
  result.tid = tid
  result.tags = 0xffffffff'u32
  result.mainThread = mainThread

  discard fiberStackInit(addr result.selectorStack, minStackSize)

proc jobDestroyTData(tData: ptr JobThreadData) =
  fiberStackDestroy(addr tData.selectorStack)
  freeShared(tData)
  
proc jobThreadFn(userData: tuple[one: pointer; two: pointer]) {.thread, gcsafe.} =
  let
    ctx = cast[ptr JobContext](userData.one)
    idx = cast[int32](cast[int](userData.two))
    threadId = threadTid()

  tData = jobCreateTData(threadId, idx + 1'i32)

  let fiber = fiberCreate(tData.selectorStack, jobSelectorFn)
  discard fiberSwitch(fiber, ctx)

  jobDestroyTData(tData)

proc jobDispatch*(ctx: ptr JobContext; count: int32;
                  callback: JobCallback; userData: pointer; priority: JobPriority;
                  tags: uint32): Job =
  let
    numWorkers = ctx.numThreads + 1'i32
    rangeSize = int32(count div numWorkers)
  var rangeRemainder = int32(count mod numWorkers)
  let numJobs = int32(if rangeSize > 0: numWorkers else: (
      if rangeRemainder > 0: rangeRemainder else: 0
    )
  )

  var counter: Job
  withLock(ctx.counterLock):
    counter = cast[Job](poolNewAndGrow(ctx.counterPool))

  if isNil(counter):
    return

  counter[] = numJobs

  if tData.curJob != nil:
    tData.curJob.waitCounter = counter

  withLock(ctx.jobLock):
    if not poolFullN(ctx.jobPool, numJobs):
      var
        rangeStart = 0'i32
        rangeEnd = int32(rangeSize + (if rangeRemainder > 0: 1 else: 0))
      dec(rangeRemainder)

      for i in 0 ..< numJobs:
        jobAddList(
          addr ctx.waitingList[priority],
          addr ctx.waitingListLast[priority],
          newJob(
            ctx, i, callback, userData, rangeStart,
            rangeEnd, cast[Job](counter), tags, priority
          )
        )
        rangeStart = rangeEnd
        rangeEnd += int32(rangeSize + (if rangeRemainder > 0: 1 else: 0))
        dec(rangeRemainder)

      semaphorePost(ctx.sem, numJobs)
    else:
      let pending = JobPending(
        counter: cast[Job](counter),
        rangeSize: rangeSize,
        rangeRemainder: rangeRemainder,
        callback: callback,
        userData: userData,
        priority: priority,
        tags: tags,
      )
      add(ctx.pending, pending)

  result = cast[Job](counter)

proc jobTestAndDel(ctx: ptr JobContext, job: Job): bool =
  if job[] == 0:
    withLock(ctx.counterLock):
      poolDel(ctx.counterPool, cast[pointer](job))
    return true
  return false

proc jobCreateContext*(desc: JobContextDesc): ptr JobContext =
  result = createShared(JobContext)

  result.numThreads = if desc.numThreads > 0: desc.numThreads else: int32(countProcessors() - 1)
  result.stackSize = defaultFiberStackSize
  let maxFibers = if desc.maxFibers > 0: desc.maxFibers else: defaultMaxFibers

  semaphoreInit(result.sem)

  tData = jobCreateTData(threadTid(), 0, true)
  tData.selectorFiber = fiberCreate(tData.selectorStack, jobSelectorMainThread)

  result.jobPool = poolCreate(int32(sizeof(JobObj)), maxFibers)
  result.counterPool = poolCreate(int32(sizeof(int)), counterPoolSize)
  zeroMem(result.jobPool.pages.buff, sizeof(JobObj) * maxFibers)

  if result.numThreads > 0:
    result.threads = cast[ptr UncheckedArray[Thread[tuple[one: pointer, two: pointer]]]](
      allocShared0(int32(sizeof(Thread[tuple[one: pointer, two: pointer]])) * result.numThreads))
        

    for i in 0 ..< result.numThreads:
      createThread(result.threads[i], jobThreadFn, (cast[pointer](result), cast[pointer](cast[int](i))))

proc jobDestroyContext*(ctx: ptr JobContext) =
  ctx.quit = true

  semaphorePost(ctx.sem, ctx.numThreads + 1'i32)

  joinThreads(toOpenArray(ctx.threads, 0, ctx.numThreads - 1))
  deallocShared(ctx.threads)

  jobDestroyTData(tData)

  poolDestroy(ctx.jobPool)
  poolDestroy(ctx.counterPool)

  freeShared(ctx)

when isMainModule:
  import os

  type
    JobData = object
      job: Job
      next: ptr JobData
      prev: ptr JobData

  let
    ctx = jobCreateContext(JobContextDesc())
    jd {.align: 8.} = createShared(JobData)
    
  proc cb(rageStart, rangeEnd, threadIdx: int32; userData: pointer) {.cdecl.} =
    echo "in job callback!!"

  let j = jobDispatch(ctx, 1, cb, jd, jpHigh, 0'u32)

  while true:
    if jobTestAndDel(ctx, j):
      break

  freeShared(jd)

  jobDestroyContext(ctx)