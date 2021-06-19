when defined(windows):
  proc alloca*(size: int): pointer {.header: "<malloc.h>".}
else:
  proc alloca*(size: int): pointer {.header: "<alloca.h>".}

template alignMask*(value, mask: untyped): untyped =
  (((value.uint) + (mask.uint)) and ((not 0'u) and (not(mask.uint))))

proc alignPtr*(p: pointer; extra: uint; alignment: uint32): pointer =
  type
    AnonUn {.union.} = object
      p: pointer
      address: uint
  
  var un: AnonUn
  un.p = p
  
  let 
    unaligned = un.address + extra
    mask = alignment - 1
    aligned = alignMask(unaligned, mask)
  un.address = aligned
  return un.p

proc isPowerOfTwo*(n: int): bool {.inline.} =
  (n and (n - 1)) == 0

func roundNextMultipleOf*(x: Natural, n: Natural): int {.inline.} =
  assert isPowerOfTwo(n)
  result = (x + n - 1) and not(n - 1)

proc posix_memalign(mem: var pointer, alignment, size: csize_t){.sideeffect,importc, header:"<stdlib.h>".}
proc aligned_alloc(size, alignment: csize_t): pointer {.sideeffect,importc:"_aligned_malloc", header:"<malloc.h>".}
proc aligned_free(p: pointer) {.sideeffect,importc:"_aligned_free", header:"<malloc.h>".}
proc allocAlignedImpl(alignment, size: csize_t): pointer {.inline.} =
  when defined(windows):
    result = aligned_alloc(size, alignment)
  else:
    posix_memalign(result, alignment, size)

proc allocAligned*(size: int; alignment: static Natural): pointer {.inline.} =
  static:
    assert isPowerOfTwo(alignment)

  let requiredMem = roundNextMultipleOf(size, alignment)
  result = allocAlignedImpl(csize_t(alignment), csize_t(requiredMem))

proc allocAligned*(size: int; alignment: Natural): pointer {.inline.} =
  assert isPowerOfTwo(alignment)

  let requiredMem = roundNextMultipleOf(size, alignment)
  result = allocAlignedImpl(csize_t(alignment), csize_t(requiredMem))

proc freeAligned*(p: pointer) {.inline.} =
  when defined(windows):
    aligned_free(p)
  else:
    c_free(p)