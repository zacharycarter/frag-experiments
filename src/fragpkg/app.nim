import strformat, dynlib, os,
       ../../thirdparty/[sokol],
       api, core, plugin, strconv

var
  entryModulePath: string
  conf: Config

when defined(windows):
  import winim/lean

  proc messageBox(msg: string) =
    MessageBoxA(HWND(0), msg, "frag", MB_OK or MB_ICONERROR)

template saveConfigStr(cacheStr, str: untyped) =
  if str != nil:
    discard strcpy(cacheStr, sizeof(cacheStr), str)
    str = cast[cstring](addr(cacheStr[0]))
  else:
    str = cast[cstring](addr(cacheStr[0]))

proc init() {.cdecl.} =
  if not init(conf):
    quit(QuitFailure)

  if not loadAbs(entryModulePath, true):
    quit(QuitFailure)
  
  if not initPlugins():
    quit(QuitFailure)


proc update() {.cdecl.} =
  core.update()

proc shutdown() {.cdecl.} =
  core.shutdown()
  sapp_quit()

proc entry*(modulePath: string) =
  if not fileExists(modulePath):
    messageBox(fmt"game module {modulePath} does not exist")
    quit(QuitFailure)

  let dll = loadLib(modulePath)
  if isNil(dll):
    messageBox(fmt"game module '{modulePath}' is not a valid shared library")
    quit(QuitFailure)
  
  let configFn = cast[ConfigCallback](symAddr(dll, "configureFrag"))
  if isNil(configFn):
    messageBox(fmt"symbol 'configureFrag' not found in module: {modulePath}")
    quit(QuitFailure)
  
  entryModulePath = modulePath

  var defaultTitle: array[64, char]
  
  configFn(conf)

  saveConfigStr(defaultTitle, conf.appTitle)

  var appDesc = sapp_desc(
    init_cb: init,
    frame_cb: update,
    cleanup_cb: shutdown,
    width: conf.windowWidth,
    height: conf.windowHeight,
    window_title: conf.appTitle,
    sample_count: conf.multisampleCount,
    swap_interval: conf.swapInterval,
  )

  unloadLib(dll)
  
  sapp_run(addr(appDesc))