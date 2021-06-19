import tables, hashes, locks,
       config, api, internal, handle, hash, io

type
  AssetState = enum
    asZombie
    asOk
    asFailed
    asLoading
  
  AssetJobState = enum
    ajsSpawn
    ajsLoadFailed
    ajsSuccess

  AssetAsyncJob = ref object
    loadData: AssetLoadData
    lparams: AssetLoadParameters
    mem: ptr MemBlock
    mgr: ptr AssetManager
    job: Job
    state: AssetJobState
    asset: Asset
    next: AssetAsyncJob
    prev: AssetAsyncJob

  AssetData = object
    handle: Handle
    paramsId: uint32
    resourceId: uint32
    assetMgrId: int32
    refCount: int32
    obj: AssetObj
    deadObj: AssetObj
    hash: Hash
    state: AssetState

  AssetResource = object
    path: string
    realPath: string
    pathHash: uint32
    lastModified: uint64
    assetMgrId: int32
    used: bool

  AssetAsyncLoadRequest* = object
    pathHash: uint32
    asset: Asset

  AssetManager* = object
    name: string
    callbacks: AssetCallbacks
    nameHash: uint32
    paramsSize: int32
    paramsTypeName: string
    asyncObj: AssetObj
    paramsBuff: seq[uint8]
  
  AssetLibrary* = object
    managers: seq[AssetManager]
    typeHashes: seq[uint32]
    assets: seq[AssetData]
    assetHandles: ptr HandlePool
    assetTbl: Table[Hash, Handle]
    resourceTbl: Table[uint32, int32]
    resources: seq[AssetResource]
    asyncReqs: seq[AssetAsyncLoadRequest]
    asyncJobList: AssetAsyncJob
    asyncJobListLast: AssetAsyncJob
    assetLock: Lock

var
  assetLib: AssetLibrary

proc hashAsset(path: string): Hash =
  var h: Hash = 0
  h = h !& hash(path)
  result = !$h

proc findAsyncReq(path: string): int32 =
  let pathHash = fnv32Str(path)
  for i in 0'i32 ..< int32(len(assetLib.asyncReqs)):
    let req = addr(assetLib.asyncReqs[i])
    if req.pathHash == pathHash:
      return i
  result = -1

proc findAssetManager(hashedAssetType: uint32): int32 =
  for i in 0'i32 ..< int32(len(assetLib.typeHashes)):
    if assetLib.typeHashes[i] == hashedAssetType:
      return i
  result = -1

proc assetJobAddList(pFirst, pLast: ptr AssetAsyncJob; node: AssetAsyncJob) =
  if pLast[] != nil:
    plast[].next = node
    node.prev = pLast[]
  plast[] = node
  if isNil(pFirst[]):
    pFirst[] = node


proc assetLoadJobCb(start, finish, threadIdx: int32; userData: pointer) {.cdecl.} =
  echo "in asset load job callback"
  let j = cast[AssetAsyncJob](userData)

  let m = cast[ptr Model](j.loadData.obj.p)
  echo m.numMeshes
  echo m.numNodes

  j.state = if j.mgr.callbacks.onLoad(addr(j.loadData), addr(j.lparams), j.mem):
              ajsSuccess
            else:
              ajsLoadFailed

proc onRead(path: string; readMem: ptr MemBlock) =
  let asyncReqIdx = findAsyncReq(path)

  if isNil(readMem):
    # error opening file
    if asyncReqIdx != -1:
      let 
        req = addr(assetLib.asyncReqs[asyncReqIdx])
        asset = req.asset
        a = addr(assetLib.assets[handleIndex(asset.id)])
      
      assert(a.resourceId > 0)

      let
        res = addr(assetLib.resources[toIndex(a.resourceId)])
        mgr = addr(assetLib.managers[a.assetMgrId])

      a.state = asFailed
      
      del(assetLib.asyncReqs, asyncReqIdx)
    elif asyncReqIdx == -1:
      destroyMemBlock(readMem)
      return
  
  let 
    req = addr(assetLib.asyncReqs[asyncReqIdx])
    asset = req.asset
    a = addr(assetLib.assets[handleIndex(asset.id)])
  
  assert(a.resourceId > 0)

  let
    res = addr(assetLib.resources[toIndex(a.resourceId)])
    mgr = addr(assetLib.managers[a.assetMgrId])
  
  var paramsPtr: pointer = nil
  if a.paramsId > 0:
    paramsPtr = addr(mgr.paramsBuff[toIndex(a.paramsId)])
  
  var loadParams = AssetLoadParameters(
    path: path,
    params: paramsPtr
  )
  let loadData = mgr.callbacks.onPrepare(addr(loadParams), readMem)

  del(assetLib.asyncReqs, asyncReqIdx)

  let m = cast[ptr Model](loadData.obj.p)
  echo m.numMeshes
  echo m.numNodes
  # if loadData.obj.id <= 0:
  #   destroyMemBlock(readMem)
  #   return

  # var j = AssetAsyncJob(
  #   loadData: loadData,
  #   mem: readMem,
  #   mgr: mgr,
  #   asset: asset,
  # )

  # let j = createShared(AssetAsyncJob, 1)
  var j = new AssetAsyncJob
  j.loadData = loadData
  j.mem = readMem
  j.mgr = mgr
  j.asset = asset
  j.lParams = loadParams

  j.job = coreAPI.dispatchJob(1, assetLoadJobCb, cast[pointer](j), jpHigh, 0'u32)
  assetJobAddList(addr(assetLib.asyncJobList), addr(assetLib.asyncJobListLast), j)

proc registerAssetType*(typeName: string; callbacks: AssetCallbacks; paramsTypeName: string; paramsSize: int32) {.cdecl.} =
  let typeHash = fnv32Str(typeName)
  for th in assetLib.typeHashes:
    if typeHash == th:
      assert(false, "asset type already registered")
      return

  let mgr = AssetManager(
    callbacks: callbacks,
    nameHash: typeHash,
    paramsSize: paramsSize,
    paramsTypeName: paramsTypeName,
    name: typeName,
  )

  add(assetLib.managers, mgr)
  add(assetLib.typeHashes, typeHash)

proc createNewAsset(path: string; params: pointer; obj: AssetObj; nameHash: uint32): Asset =
  let mgrId = findAssetManager(nameHash)
  assert(mgrId != -1, "asset type is not registered")
  let mgr = addr(assetLib.managers[mgrId])

  let pathHash = fnv32Str(path)
  var resIdx = assetLib.resourceTbl.getOrDefault(pathHash, -1)
  if (resIdx == -1):
    let res = AssetResource(
      used: true,
      path: path,
      realPath: path,
      pathHash: pathHash,
      assetMgrId: mgrId,
    )
    resIdx = int32(len(assetLib.resources))
    add(assetLib.resources, res)
    assetLib.resourceTbl[pathHash] = resIdx
  else:
    assetLib.resources[resIdx].used = true
  
  let paramsSize = mgr.paramsSize
  var paramsId = 0'u32
  if paramsSize > 0:
    paramsId = toId(len(mgr.paramsBuff))
    add(mgr.paramsBuff, toOpenArray[uint8](cast[ptr UncheckedArray[uint8]](params), 0, paramsSize))
  
  let handle = handleNewAndGrow(assetLib.assetHandles)
  assert(uint32(handle) > 0'u32)

  echo uint32(handle)

  let assetData = AssetData(
    handle: handle,
    paramsId: paramsId,
    resourceId: toId(resIdx),
    assetMgrId: mgrId,
    refCount: 1,
    obj: obj,
    hash: hashAsset(path),
    state: asZombie,  
  )

  withLock(assetLib.assetLock):
    pushByIdx(assetLib.assets, assetData, handleIndex(handle))
  
  assetLib.assetTbl[assetData.hash] = handle

  result = Asset(
    id: uint32(handle)
  )
  
proc loadHashed*(hashedAssetType: uint32; path: string; params: pointer): Asset =
  if len(path) == 0:
    echo "empty asset path"
    return result

  assert coreAPI.jobThreadIndex() == 0, "assets must be loaded from the main thread"

  let mgrId = findAssetManager(hashedAssetType)
  assert(mgrId != -1, "asset type is not registered")
  let mgr = addr(assetLib.managers[mgrId])
  
  let hashedAsset = hashAsset(path)
  if assetLib.assetTbl.contains(hashedAsset):
    let asset = cast[Asset](assetLib.assetTbl[hashedAsset])
    inc(assetLib.assets[handleIndex(asset.id)].refCount)
  else:
    echo "getting resource id"
    let resIdx = assetLib.resourceTbl.getOrDefault(fnv32Str(path), -1)
    var
      res: ptr AssetResource = nil 
      realPath = path
    
    if resIdx != -1:
      echo "getting resource"
      res = addr(assetLib.resources[resIdx])
      realPath = res.realPath
    
    echo "creating new asset"
    
    result = createNewAsset(path, params, mgr.asyncObj, hashedAssetType)

    echo "asset created"

    echo result.id
    echo handleIndex(result.id)
    echo len(assetLib.assets)
    let a = addr(assetLib.assets[handleIndex(result.id)])
    a.state = asLoading

    echo "set asset state to loading"

    let req = AssetAsyncLoadRequest(
      pathHash: fnv32Str(realPath),
      asset: result,
    )
    add(assetLib.asyncReqs, req)

    vfsAPI.readAsync(
      realPath,
      {vfAbsolutePath},
      onRead
    )


proc load*(assetType: string; path: string; params: pointer): Asset {.cdecl.} =
  result = loadHashed(fnv32Str(assetType), path, params)

proc update*() =
  discard

proc init*(): bool =
  assetLib.assetHandles = handleCreatePool(AssetPoolSize)

  initLock(assetLib.assetLock)

  result = true

proc shutdown*() =
  deinitLock(assetLib.assetLock)
  
  if assetLib.assetHandles != nil:
    handleDestroyPool(assetLib.assetHandles)

assetAPI = APIAsset(
  load: load,
  registerAssetType: registerAssetType,
)