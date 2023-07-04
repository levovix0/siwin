version       = "0.8"
author        = "levovix0"
description   = "Simple Window Maker"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.6.10"
requires "chroma >= 0.2.6"
requires "vmath >= 1.1.4"

# note: nimble does not support "features", so just require all dependencies without any conditioning
requires "x11 >= 1.1"
requires "winim >= 3.6"


import strformat

task testDeps, "install test dependencies":
  exec "nimble install opengl"
  exec "nimble install pixie"
  exec "nimble install https://github.com/levovix0/wayland"

const testTargets = ["t_offscreen", "tests", "t_vulkan"]

proc runTests(args: string) =
  withDir "tests":
    for target in testTargets:
      try:    exec "nim c " & args & " --hints:off -r " & target
      except: discard

proc createZigccIfNeeded =
  let code = """
import std/osproc
import std/os

proc main =
  var args = @["cc"]
  args.add(commandLineParams())
  var p = startProcess("/usr/bin/zig", args = args, options = {poParentStreams})
  defer: p.close()
  quit p.waitForExit()

main()
  """
  if not fileExists("build/zigcc.nim"):
    writeFile "build/zigcc.nim", code
  if not fileExists("build/zigcc"):
    exec "nim c build/zigcc.nim"

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

task testMacos, "test macos":
  createZigccIfNeeded()
  let pwd = getCurrentDir()
  let target = "x86_64-macos-none"
  withDir "tests":
    for file in testTargets:
      try:
        exec &"nim c --os:macosx --cc:clang --clang.exe:{pwd}/build/zigcc --clang.linkerexe:{pwd}/build/zigcc --passc:--target={target} --passl:--target={target} --hints:off -o:{file}-macos {file}"
        exec &"echo ./{file}-macos | darling shell"
      except: discard

task testAll, "run all tests":
  runTests ""
  runTests "-d:wayland"
  runTests "--mm:orc"
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc"
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc --mm:orc"
