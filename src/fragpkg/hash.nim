const 
  FNV132Init = 0x811c9dc5'u32
  FNV132Prime = 0x01000193'u32

proc fnv32Str*(str: string): uint32 =
  result = FNV132Init
  for c in str:
    result = result xor uint32(c)
    result *= FNV132Prime