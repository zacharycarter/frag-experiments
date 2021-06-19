import os

when defined(host):
  when defined(windows):
    {.passL: "-ldbghelp".}
  {.compile: "./cr.cpp".}

type
  PluginFailure* = distinct int32

  PluginOp* = distinct int32

  CRPlugin* = object
    p*: pointer
    userData*: pointer
    version*: uint32
    failure*: PluginFailure
    nextVersion*: uint32
    lastWorkingVersion*: uint32

const
  pfNone = PluginFailure(0)
  pfSegfault = PluginFailure(1)
  pfIllegal = PluginFailure(2)
  pfAbort = PluginFailure(3)
  pfMisalign = PluginFailure(4)
  pfBounds = PluginFailure(5)
  psStackOverflow = PluginFailure(6)
  pfStateInvalidated = PluginFailure(7)
  pfBadImage = PluginFailure(8)
  pfOther = PluginFailure(9)
  pfUser = PluginFailure(0x100)

  poLoad* = PluginOp(0)
  poStep* = PluginOp(1)
  poUnload* = PluginOp(2)
  poClose* = PluginOp(3)

proc pluginOpen*(ctx: CRPlugin, fullpath: cstring): bool {.importc: "cr_plugin_open".}
proc pluginUpdate*(ctx: CRPlugin, reloadCheck: bool = true): int32 {.importc: "cr_plugin_update".}
proc pluginClose*(ctx: CRPlugin) {.importc: "cr_plugin_close".}