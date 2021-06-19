when not compileOption("threads"):
  {.error: "Scheduler requires --threads:on option.".}

when not compileOption("gc", "arc") and not compileOption("gc", "orc"):
  {.error: "Scheduler requires --gc:arc or --gc:orc option.".}

#[
type
  Task* = proc(start, step: int) {.closure, gcsafe.}
  Signal = object
  Worker = object
    input: Channel[Task]
    output: Channel[Signal]
    thread: Thread[ptr Worker]
    index, step: int
  Scheduler* = object
    workers: seq[Worker]
    running, active: bool

proc runWorker(w: ptr Worker) {.thread.} =
  while true:
    var task = w.input[].recv()
    if task == nil:
      w.output[].send(Signal())
      return
    task(w.index, w.step)
    w.output[].send(Signal())

proc run*(g: var Scheduler, t: Task) =
  assert g.active and not g.running
  g.running = true
  for w in g.workers.mitems:
    w.input[].send(t)

proc wait*(g: var Scheduler) =
  assert g.running and g.active
  g.running = false
  for w in g.workers.mitems:
    discard w.output[].recv()

template cycle*(g: var Scheduler, t: Task) =
  g.run(t)
  g.wait()

proc dropThreads*(g: var Scheduler) =
  if not g.active:
    return

  if g.running:
    g.wait()
  g.run(nil)
  g.wait()

  g.channels.deallocShared()

  g.active = false

proc setThreads*(g: var Scheduler, threadCount: int) =
  g.dropThreads()
  g.active = true
  
  g.workers.setLen(threadCount)
  g.channels = allocShared0((sizeof(Channel[Task]) + sizeof(Channel[Signal])) * threadCount)
  var cursor = cast[uint64](g.channels) 
  for i in 0..threadCount-1:
    var w = g.workers[i].addr
    w.index = i
    w.step = threadCount

    w.input = cast[ptr Channel[Task]](cursor)
    cursor += uint64(sizeof(Channel[Task]))
    w.output = cast[ptr Channel[Signal]](cursor)
    cursor += uint64(sizeof(Channel[Signal]))

    w.input[].open()
    w.output[].open()

    createThread(w.thread, runWorker, w)

when isMainModule:
  type A = ref object
    gate: Scheduler
    data: seq[int]
  
  proc update(a: A) =
    a.gate.run(proc(start, step: int) {.closure, gcsafe.} =
        for i in countup(start, a.data.len-1, step):
          a.data[i] += 1
      )
    a.gate.wait()

  proc main =
    let a = A()
    a.gate.setThreads(4)

    a.data.setLen(1_000)

    while true: # crash will stop it
      a.update() 

    a.gate.dropThreads()
  main()
]#

import atomics, locks, cpuinfo

type
  Task* = proc(start, step: int) {.closure, gcsafe.}
  
  Gate* = object
    cond: Cond
    lock: Lock
  
  Scheduler* = ref object 
    running: bool
    gate: Gate
    task: Task
    workers: seq[tuple[thread: Thread[(Scheduler, int)], gate: Gate]]
    progress: Atomic[int]

template wait*(s: var Gate) =
  s.cond.wait(s.lock)

template init(s: var Gate) =
  initLock(s.lock)
  initCond(s.cond)

template deinit(s: var Gate) =
  deinitLock(s.lock)
  deinitCond(s.cond)

template signal(s: var Gate) =
  s.cond.signal()

proc runWorker(args: (Scheduler, int)) {.thread.} =
  let 
    (s, id) = args
    step = s.workers.len
    w = s.workers[id].addr
  
  
  while true:
    w.gate.wait()
    if s.task == nil:
      return
    s.task(id, step)
    s.progress.atomicInc()
    if s.progress.load == step:
      s.gate.signal()

proc newScheduler(): Scheduler =
  result = Scheduler()
  result.gate.init()

proc setThreads(s: Scheduler, amount = countProcessors()) =
  s.workers.setLen(amount)
  for id, w in s.workers.mpairs:
    w.gate.init()
    createThread(w.thread, runWorker, (s, id))

proc run(s: Scheduler, task: Task) =
  assert not s.running, "cannot run before previous cycle finished"
  s.running = true

  s.progress.store(0)
  s.task = task
  for w in s.workers.mitems:
    w.gate.signal()

proc wait(s: Scheduler) =
  assert s.running, "there has to be cycle running in order to wait for it"
  s.running = false

  s.gate.wait()

template cycle(s: Scheduler, task: Task) =
  s.run(task)
  s.wait()


when isMainModule:
  import os

  let scheduler = newScheduler()
  scheduler.setThreads()

  for _ in 0..10:
    scheduler.run(proc(idx, step: int) = 
      echo idx, " ", step
    )
    scheduler.wait()
    echo "--"