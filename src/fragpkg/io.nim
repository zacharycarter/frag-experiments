import atomics,
       ptr_math,
       config, alloc

type
  MemBlock* = object
    data*: pointer
    size*: int64
    startOffset: int64
    align: int32
    refcount: Atomic[int32]

proc addOffset*(mem: ptr MemBlock; offset: int64) =
  mem.data = cast[ptr uint8](mem.data + int(offset))
  mem.size -= offset
  mem.startOffset += offset

proc createMemBlock(size: int64; data: pointer; desiredAlignment: int32): ptr MemBlock =
  let align = uint32(max(desiredAlignment, NaturalAlignment))
  result = cast[ptr MemBlock](allocShared0(size + sizeof(MemBlock) + int64(align)))
  if result != nil:
    result.data = alignPtr(result + 1, 0, align)
    result.size = size
    result.startOffset = 0
    result.align = align.int32
    store(result.refcount, 1)
    if data != nil:
      copyMem(result.data, data, size)
  else:
    echo "out of memory!"

proc loadBinaryFile*(filepath: string): ptr MemBlock =
  var f: File
  if open(f, filepath):
    let size = getFileSize(f)
    if size > 0:
      result = createMemBlock(size, nil, 0)
      if result != nil:
        discard readBuffer(f, result.data, size)
        close(f)
    close(f)

proc destroyMemBlock*(mem: ptr MemBlock) =
  assert(not isNil(mem))
  assert(load(mem.refCount) >= 1)

  atomicDec(mem.refCount)
  if load(mem.refCount) == 0:
    deallocShared(mem)

when isMainModule:
  discard loadBinaryFile("H:\\DBCheatSheet.pdf")