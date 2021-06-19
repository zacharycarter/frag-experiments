import api, internal, job, plugin, vfs, asset

var
  jobCtx: ptr JobContext

proc jobThreadIndex*(): int32 {.cdecl.} =
  jobThreadIndex(jobCtx)

proc dispatchJob*(count: int32; callback: proc(start, finish, threadIdx: int32; userData: pointer) {.cdecl.},
                  userData: pointer; priority: JobPriority; tags: uint32): Job {.cdecl.} =
  assert(not isNil(jobCtx))
  jobDispatch(jobCtx, count, callback, userData, priority, tags)

proc init*(conf: var Config): bool =
  vfs.init()
  jobCtx = createJobContext(JobContextDesc())

  if not asset.init():
    echo "failed initializing asset system"
    return false
  result = true

proc update*() =
  vfs.asyncUpdate()
  asset.update()
  plugin.update()

proc shutdown*() =
  destroyJobContext(jobCtx)

coreAPI = APICore(
  jobThreadIndex: jobThreadIndex,
  dispatchJob: dispatchJob,
)