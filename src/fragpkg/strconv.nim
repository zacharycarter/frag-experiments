proc strcpy*(
  dst: var openArray[char];
  dstSz: int;
  src: var cstring;
): cstring =
  assert(src != nil)

  let
    len = len(src)
    max = dstSz - 1
    num = if len < max: len else: max

  if num > 0:
    copymem(addr dst[0], addr src[0], num)

  dst[num] = '\0'

  result = addr(dst[num])