import api

var
  coreAPI* {.exportc.}: APICore
  pluginAPI* {.exportc.}: APIPlugin
  vfsAPI* {.exportc.}: APIVFS
  assetAPI* {.exportc.}: APIAsset