const
  HandleGenBits* = 14

  AssetPoolSize* = 256

when defined(macosx):
  const NaturalAlignment* = 16
else:
  const NaturalAlignment* = 8