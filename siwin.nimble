version       = "0.7.2"
author        = "levovix0"
description   = "Simple Window Maker"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.6.6"
requires "chroma >= 0.2.6"
requires "vmath >= 1.1.4"

when defined linux:
  requires "x11 >= 1.1"
when defined windows:
  requires "winim >= 3.6"

task testDeps, "install test dependencies":
  exec "nimble install opengl"
  exec "nimble install pixie"
  exec "nimble install https://github.com/levovix0/wayland"

template runTests(args: string) =
  withDir "tests":
    try:    exec "nim c " & args & " --hints:off -r t_offscreen"
    except: discard
    try:    exec "nim c " & args & " --hints:off -r tests"
    except: discard

task test, "test":
  runTests ""

task testWayland, "test wayland":
  runTests "-d:wayland"

task testOrc, "test with --mm:orc":
  runTests "--mm:orc"

task testWindows, "test windows version with wine on linux":
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc"

task testOrcWindows, "test windows version with wine on linux with --mm:orc":
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc --mm:orc"

task testAll, "run all tests":
  runTests ""
  runTests "-d:wayland"
  runTests "--mm:orc"
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc"
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc --mm:orc"
