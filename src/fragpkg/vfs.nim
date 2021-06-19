import options, os,
       lockfreequeues,
       api, internal, threading, io

type
  VfsResponseCode = enum
    vrcReadFailed
    vrcReadOk
    vrcWriteFailed
    vrcWriteOk

  VfsAsyncCommand = enum
    vacRead
    vacWrite

  VfsAsyncRequest = object
    case cmd: VfsAsyncCommand
    of vacRead:
      readFn: VfsAsyncReadCallback
    of vacWrite:
      writeFn: proc(path: string; writeBytes: int64; writeMem: ptr MemBlock)
    flags: set[VfsFlag]
    path: string
  
  VfsAsyncResponse = object
    code: VfsResponseCode
    case cmd: VfsAsyncCommand
    of vacRead:
      readMem: ptr MemBlock
      readFn: VfsAsyncReadCallback
    of vacWrite:
      writeMem: ptr MemBlock
      writeFn: proc(path: string; writeBytes: int64; writeMem: ptr MemBlock)
    writeBytes: int64
    path: string

var
  quit = false
  requestQueue: ptr SipSic[128, VfsAsyncRequest]
  responseQueue: ptr SipSic[128, VfsAsyncResponse]
  worker: Thread[void]
  workerSem: Semaphore

proc readFile(filepath: string; flags: set[VfsFlag]): ptr MemBlock =
  if vfTextFile in flags: nil else: loadBinaryFile(filepath)

proc readAsync*(path: string; flags: set[VfsFlag], readFn: VfsAsyncReadCallback) {.cdecl.} =
  var req = VfsAsyncRequest(
    path: path,
    cmd: vacRead,
    flags: flags,
    readFn: readFn,
  )

  assert(requestQueue[].push(req))
  post(workerSem, 1)


proc workerFn() {.gcsafe.} =
  while not quit:
    let consumed = requestQueue[].pop()
    if isSome(consumed):
      var res = VfsAsyncResponse(writeBytes: -1)

      let req = get(consumed)
      res.path = req.path
      case req.cmd
      of vacRead:
        res.readFn = req.readFn
        let mem = readFile(req.path, req.flags)
        
        if mem != nil:
          res.code = vrcReadOk
          res.readMem = mem
        else:
          res.code = vrcReadFailed
        discard responseQueue[].push(res)
        break
      of vacWrite:
        break

    wait(workerSem)

proc init*() =
  requestQueue = createShared(Sipsic[128, VfsAsyncRequest])
  requestQueue[] = initSipSic[128, VfsAsyncRequest]()

  responseQueue = createShared(Sipsic[128, VfsAsyncResponse])
  responseQueue[] = initSipSic[128, VfsAsyncResponse]()

  init(workerSem)
  createThread(worker, workerFn)

proc asyncUpdate*() =
  var consumed = responseQueue[].pop()
  while(isSome(consumed)):
    let res = get(consumed)
    case res.code
    of vrcReadOk, vrcReadFailed:
      res.readFn(res.path, res.readMem)
      break
    of vrcWriteOk, vrcWriteFailed:
      res.writeFn(res.path, res.writeBytes, res.readMem)
      break
    consumed = responseQueue[].pop()

proc shutdown*() =
  quit = true
  signal(workerSem)
  joinThread(worker)
  freeShared(requestQueue)
  freeShared(responseQueue)

vfsAPI = APIVFS(
  readAsync: readAsync,
)