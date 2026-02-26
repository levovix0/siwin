# file is meant to be included in .nimble or in config.nims
# see https://github.com/levovix0/siwin/issues/19 for more details


proc createZigccIfNeeded* =
  let code = "import std/[os, osproc]; quit startProcess(\"/usr/bin/zig\", args = @[\"cc\"] & commandLineParams(), options = {poParentStreams}).waitForExit"
  if not fileExists("build/zigcc.nim"):
    writeFile "build/zigcc.nim", code
  if not fileExists("build/zigcc"):
    exec "nim c build/zigcc.nim"


task testMacos, "test macos":
  createZigccIfNeeded()
  let pwd = getCurrentDir()
  let target = "x86_64-macos-none"
  let args = &"--os:macosx --cc:clang --clang.exe:{pwd}/build/zigcc --clang.linkerexe:{pwd}/build/zigcc --passc:--target={target} --passl:--target={target} --hints:off"
  withDir "tests":
    for file in testTargets:
      if shouldSkipTarget(file, args):
        echo "Skipping ", file, " on macOS"
        continue
      try:
        exec &"nim c {args} -o:{file}-macos {file}"
        exec &"echo ./{file}-macos | darling shell"
      except: discard


