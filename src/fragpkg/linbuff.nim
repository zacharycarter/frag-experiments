import ptr_math,
       config, alloc

const MaxBufferFields = 32

type
  LinearBufferField = object
    pptr: ptr pointer
    offset: uint
    offsetInParent: int32

  LinearBuffer* = object
    parentType*: string
    fields: array[MaxBufferFields, LinearBufferField]
    size: uint
    parentAlign: uint32
    numFields: int32

proc init(buf: ptr LinearBuffer; parentType: string; parentSize: uint; align: var uint32 = 0'u32) =
  assert(parentSize > 0)

  buf.parentType = parentType

  buf.fields[0].pptr = nil
  buf.fields[0].offset = 0
  buf.fields[0].offsetInParent = -1

  align = uint32(max(NaturalAlignment, int32(align)))

  buf.size = alignMask(parentSize, align - 1)
  buf.parentAlign = align
  buf.numFields = 1

proc add(buf: ptr LinearBuffer; size: var uint; offsetInStruct: int32; pptr: ptr pointer; align: var uint32) =
  assert(not isNil(buf))

  let index = buf.numFields
  assert(index < MaxBufferFields)

  align = if align < NaturalAlignment: uint32(NaturalAlignment) else: align

  size = alignMask(size, align - 1)
  var offset = buf.size
  if offset mod align != 0:
    offset = alignMask(offset, align - 1)

  let field = addr(buf.fields[index])
  field.pptr = pptr
  field.offset = offset
  field.offsetInParent = offsetInStruct

  buf.size = offset + size
  inc(buf.numFields)

proc calloc*(buf: ptr LinearBuffer): pointer =
  result = if buf.parentAlign <= NaturalAlignment: allocShared(buf.size) else: allocAligned(int(buf.size), buf.parentAlign)

  if isNil(result):
    return nil
  zeroMem(result, buf.size)
  let tmpMem = cast[ptr uint8](result)

  for i in 1 ..< buf.numFields:
    if buf.fields[i].offsetInParent != -1:
      assert(isNil(buf.fields[i].pptr))
      cast[ptr pointer](tmpMem + buf.fields[i].offsetInParent)[] = tmpMem + int(buf.fields[i].offset)
    else:
      assert(buf.fields[i].offsetInParent == -1)
      buf.fields[i].pptr[] = tmpMem + int(buf.fields[i].offset)

template initLinearBuffer*(buf, struct, align: untyped): untyped =
  var mAlign = align
  init(buf, astToStr(struct), uint(sizeof(struct)), mAlign)
template addType*(buf, structName, `type`, fieldName, count, align: untyped): untyped =
  assert(buf.parentType == astToStr(structName))
  var 
    mSize = uint(sizeof(`type`) * count)
    mAlign = align
  add(buf, mSize, int32(cast[uint](unsafeAddr(cast[ptr structName](0).fieldName))), nil, mAlign)
template addPtr*(buf, pptr, `type`, count, align: untyped): untyped =
  var
    mSize = uint(sizeof(`type`) * count)
    mAlign = align
  add(buf, mSize, -1, cast[ptr pointer](pptr), mAlign)

# when isMainModule:
#   import api

#   var
#     buff: LinearBuffer
#     nodes = @[ModelNode()]
#   initLinearBuffer(addr(buff), Model, 0'u32)
#   addType(addr(buff), Model, ModelNode, nodes, 1, 0'u32)

#   echo int32(cast[uint](unsafeAddr(cast[ptr Model](0).nodes)))
#   echo offsetOf(Model, nodes)