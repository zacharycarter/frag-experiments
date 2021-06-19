# Package

version       = "0.1.0"
author        = "carterza"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["frag"]
backend       = "cpp"

# Tasks
task deps, "build and install dependencies":
  when defined(macosx):
    exec "cc -O0 -ffunction-sections -fdata-sections -g -m64 -fPIC  -DBOOST_CONTEXT_EXPORT= -I./src/fragpkg/asm -o ./src/fragpkg/asm/make_combined_all_macho_gas.S.o -c ./src/fragpkg/asm/make_combined_all_macho_gas.S"
    exec "cc -O0 -ffunction-sections -fdata-sections -g -m64 -fPIC  -DBOOST_CONTEXT_EXPORT= -I./src/fragpkg/asm -o ./src/fragpkg/asm/jump_combined_all_macho_gas.S.o -c ./src/fragpkg/asm/jump_combined_all_macho_gas.S"
    exec "cc -O0 -ffunction-sections -fdata-sections -g -m64 -fPIC  -DBOOST_CONTEXT_EXPORT= -I./src/fragpkg/asm -o ./src/fragpkg/asm/ontop_combined_all_macho_gas.S.o -c ./src/fragpkg/asm/ontop_combined_all_macho_gas.S"
  elif defined(windows):
    # exec "gcc -O0 -ffunction-sections -fdata-sections -g -m64 -fPIC  -DBOOST_CONTEXT_EXPORT= -I./src/fragpkg/asm -o ./src/fragpkg/asm/make_x86_64_ms_pe_gas.S.o -c ./src/fragpkg/asm/make_x86_64_ms_pe_gas.S"
    # exec "gcc -O0 -ffunction-sections -fdata-sections -g -m64 -fPIC  -DBOOST_CONTEXT_EXPORT= -I./src/fragpkg/asm -o ./src/fragpkg/asm/jump_x86_64_ms_pe_gas.S.o -c ./src/fragpkg/asm/jump_x86_64_ms_pe_gas.S"
    # exec "gcc -O0 -ffunction-sections -fdata-sections -g -m64 -fPIC  -DBOOST_CONTEXT_EXPORT= -I./src/fragpkg/asm -o ./src/fragpkg/asm/ontop_x86_64_ms_pe_gas.S.o -c ./src/fragpkg/asm/ontop_x86_64_ms_pe_gas.S"
    exec "\"C:\\Program Files (x86)\\Microsoft Visual Studio 14.0\\VC\\bin\\amd64\\ml64.exe\" /nologo /c /Fo./src/fragpkg/asm/make_x86_64_ms_pe_masm.o /Zd /Zi /I./src/fragpkg/asm /DBOOST_CONTEXT_EXPORT= ./src/fragpkg/asm/make_x86_64_ms_pe_masm.asm"
    exec "\"C:\\Program Files (x86)\\Microsoft Visual Studio 14.0\\VC\\bin\\amd64\\ml64.exe\" /nologo /c /Fo./src/fragpkg/asm/jump_x86_64_ms_pe_masm.o /Zd /Zi /I./src/fragpkg/asm /DBOOST_CONTEXT_EXPORT= ./src/fragpkg/asm/jump_x86_64_ms_pe_masm.asm"
    exec "\"C:\\Program Files (x86)\\Microsoft Visual Studio 14.0\\VC\\bin\\amd64\\ml64.exe\" /nologo /c /Fo./src/fragpkg/asm/ontop_x86_64_ms_pe_masm.o /Zd /Zi /I./src/fragpkg/asm /DBOOST_CONTEXT_EXPORT= ./src/fragpkg/asm/ontop_x86_64_ms_pe_masm.asm"

  else:
    echo "platform not supported"

task shaders, "compile shaders":
  when defined(macosx):
    exec "glslc assets/shaders/src/shader.vert -o assets/shaders/vert.spv"
    exec "glslc assets/shaders/src/shader.frag -o assets/shaders/frag.spv"
  else:
    echo "platform not supported"

task examples, "build examples":
  exec "nim c --app:lib --out:minimal.dylib examples/minimal.nim"



# Dependencies

requires "nim >= 1.4.8"
requires "argparse >= 2.0.0"
requires "ptr_math >= 0.3.0"
requires "lockfreequeues >= 2.0.0"
requires "winim >= 3.6.1"