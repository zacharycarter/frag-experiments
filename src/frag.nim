import fragpkg/api

export api

when isMainModule:
  import argparse,
         fragpkg/app

  discard allocShared(100000)

  let cmd = commandLineParams()

  var p = newParser:
    help("{prog} will load and execute a game/app module")
    option("-r", "--run", help="filepath of game/app module to load and run", required=true)
    run:
      entry(opts.run)
  
  p.run(cmd)