import atomics,
       ../../thirdparty/[hmm, sokol],
       alloc, io, linbuff

export io, linbuff, alloc

type
  Config*  = object
    appTitle*: cstring
    appVersion*: uint32
    
    windowWidth*: int32
    windowHeight*: int32
    multisampleCount*: int32
    swapInterval*: int32

  APIKind* = distinct int32

  PluginEvent = distinct int32

  PluginCrash = distinct int32

  JobPriority* = enum
    jpHigh
    jpNormal
    jpLow
    jpCount

  Job* = ptr Atomic[int32]

  APICore* = object
    jobThreadIndex*: proc(): int32 {.cdecl.}
    dispatchJob*: proc(count: int32; callback: proc(start, finish, threadIdx: int32; userData: pointer) {.cdecl.},
                       userData: pointer; priority: JobPriority; tags: uint32): Job {.cdecl.}

  Plugin*  = object
    p*: pointer
    api*: ptr ApiPlugin
    iteration*: uint32
    crashReason: PluginCrash
    nextIteration*: uint32
    lastWorkingIteration*: uint32

  APIPlugin*  = object
    getAPI*: proc(api: APIKind; version: uint32): pointer {.cdecl.}
  
  VfsFlag* = enum
    vfNone
    vfAbsolutePath
    vfTextFile
    vfAppend
  
  VfsAsyncReadCallback* = proc(path: string; readMem: ptr MemBlock)
  
  APIVFS* = object
    readAsync*: proc(path: string; flags: set[VfsFlag], readFn: VfsAsyncReadCallback) {.cdecl.}
  
  AssetObj* {.union.} = object
    id*: uint
    p*: pointer

  Asset* = object
    id*: uint32
  
  AssetLoadData* = object
    obj*: AssetObj
    userData1*: pointer
    userData2*: pointer

  AssetLoadParameters* = object
    path*: string
    params*: pointer # must be cast to asset-specific implementation type

  AssetCallbacks* = object
    onPrepare*: proc(params: ptr AssetLoadParameters; mem: ptr MemBlock): AssetLoadData {.cdecl.}
    onLoad*: proc(data: ptr AssetLoadData; params: ptr AssetLoadParameters; mem: ptr MemBlock): bool {.cdecl.}
    onFinalize*: proc(data: AssetLoadData; params: ptr AssetLoadParameters; mem: ptr MemBlock) {.cdecl.}
  
  APIAsset* = object
    load*: proc(assetType: string; path: string; params: pointer): Asset {.cdecl.}
    registerAssetType*: proc(name: string; callbacks: AssetCallbacks; paramsTypeName: string; paramsSize: int32) {.cdecl.}

  VertexAttr* = object
    semantic*: string
    semanticIdx*: int32
    offset*: int32
    format*: sg_vertex_format
    bufferIndex*: int32

  ConfigCallback*  = proc(conf: var Config) {.cdecl.}

  Cpu = object
    vbuffs*: array[SG_MAX_SHADERSTAGE_BUFFERS, pointer]
    ibuff*: pointer
  
  Gpu = object
    vbuffs*: array[SG_MAX_SHADERSTAGE_BUFFERS, sg_buffer]
    ibuff*: sg_buffer

    vbuffNameHandles*: array[SG_MAX_SHADERSTAGE_BUFFERS, uint32]
    ibuffNameHandle*: uint32
  
  ModelGeometryLayout* = object
    attrs*: array[SG_MAX_VERTEX_ATTRIBUTES, VertexAttr]
    bufferStrides*: array[SG_MAX_SHADERSTAGE_BUFFERS, int32]

  ModelLoadParams* = object
    layout*: ModelGeometryLayout
    vbuffUsage*: sg_usage
    ibuffUsage*: sg_usage
  
  ModelSubmesh* = object
    startIndex*: int32
    numIndices*: int32

  ModelMesh* = object
    name*: string
    numSubmeshes*: int32
    numVertices*: int32
    numIndices*: int32
    numVbuffs*: int32
    indexType*: sg_index_type
    submeshes*: ptr UncheckedArray[ModelSubmesh]

    cpu*: Cpu
    gpu*: Gpu

  ModelNode* = object
    name*: string
    meshId*: int32
    parentId*: int32
    localPos*: hmm_vec3
    localRot*: hmm_mat4
    children*: ptr UncheckedArray[int32]

  Model* = object
    numMeshes*: int32
    numNodes*: int32

    rootPos*: hmm_vec3
    rootRot*: hmm_mat4

    nodes*: ptr UncheckedArray[ModelNode]
    meshes*: ptr UncheckedArray[ModelMesh]
    layout*: ModelGeometryLayout

const
  atCore* = APIKind(0)
  atPlugin* = APIKind(1)
  atVFS* = APIKind(2)
  atAsset* = APIKind(3)

  peLoad* = PluginEvent(0)
  peStep* = PluginEvent(1)
  peUnload* = PluginEvent(2)
  peClose* = PluginEvent(3)
    
  pcNone* = PluginCrash(0)
  pcSegfault* = PluginCrash(1)
  pcIllegal* = PluginCrash(2)
  pcAbort* = PluginCrash(3)
  pcMisalign* = PluginCrash(4)
  pcBounds* = PluginCrash(5)
  pcStackOverflow* = PluginCrash(6)
  pcStateInvalidated* = PluginCrash(7)
  pcBadImage* = PluginCrash(8)
  pcOther* = PluginCrash(9)
  pcUser* = PluginCrash(0x100)

template pluginApis*() =
  when defined(macosx):
    {.pragma: state, codegenDecl: "$# $# __attribute__((used, section(\"__DATA,__state\")))".}
  elif defined(windows):
    # {.pragma: state, codegenDecl: "$# $# __attribute__((section(\".state\")))".}
    {.pragma: state, codegenDecl: "$# $# __declspec(allocate(\".state\"))".}

template pluginDeclMain*(name, pluginParamName, eventParamName, body: untyped) =
  proc pluginMain*(pluginParamName: ptr Plugin; eventParamName: PluginEvent): int32 {.cdecl, exportc, dynlib.} =
    body

template toId*(idx: int): untyped =
  (uint32(idx) + 1'u32)

template toIndex*(id: uint32): untyped =
  (int(id) - 1)

template pushByIdx*(a, v, idx: untyped): untyped =
  if idx >= len(a):
    add(a, v)
  else:
    a[idx] = v