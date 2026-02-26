# file is meant to be included in .nimble or in config.nims
# see https://github.com/levovix0/siwin/issues/19 for more details


const dynlibName =
  when defined(windows): "siwin.dll"
  elif defined(macosx): "siwin.dynlib"
  else: "libsiwin.so"

const staticlibName =
  when defined(windows): "siwin.lib"
  else: "libsiwin.a"



task buildDynlib, "build siwin as a dynamic library":
  when not defined(windows):
    exec "nim c --experimental:vtables -d:siwin_build_lib:on --app:lib -o:bindings/" & dynlibName & " src/siwin.nim"
  
  else:
    exec "nim c --passl:-static --experimental:vtables -d:siwin_build_lib:on --app:lib -o:bindings/" & dynlibName & " src/siwin.nim"


task buildStaticlib, "build siwin as a dynamic library":
  exec "nim c --noMain --experimental:vtables -d:siwin_build_lib:on --app:staticlib -o:bindings/" & staticlibName & " src/siwin.nim"


task testBindings, "build and run tests/et_bindings with static and dynamic siwin":
  exec "gcc tests/et_bindings.c bindings/" & dynlibName & " -o tests/et_bindings"
  
  when not defined(windows):
    exec "gcc tests/et_bindings.c bindings/" & staticlibName & " -DSIWIN_STATIC -o tests/et_bindings_static"
  
  when not defined(windows):
    exec "./tests/et_bindings_static"
    exec "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD ./tests/et_bindings"
  
  else:
    cpFile "bindings/siwin.dll", "tests/siwin.dll"
    exec "./tests/et_bindings.exe"


task testUseLib, "build and run tests/t_opengl using dynamic linking to siwin":
  const dynlibName =
    when defined(windows): "siwin.dll"
    elif defined(macosx): "siwin.dynlib"
    else: "libsiwin.so"

  
  exec "nim c --experimental:vtables -d:siwin_use_lib:on --passl:bindings/" & dynlibName & " -r tests/t_opengl.nim"



import strformat, os, strutils

task installTestDeps, "install test dependencies":
  exec "nimble install opengl"
  exec "nimble install nimgl"
  exec "nimble install pixie"


const testTargets = ["t_opengl_es", "t_opengl", "t_swrendering", "t_multiwindow", "t_vulkan", "t_offscreen"]

proc shouldSkipTarget(target, args: string): bool =
  let targetingMacos =
    (when defined(macosx): true else: false) or
    args.contains("--os:macosx")
  targetingMacos and target in ["t_opengl", "t_opengl_es"]

proc runTests(args: string, envPrefix = "") =
  withDir "tests":
    for target in testTargets:
      if shouldSkipTarget(target, args):
        echo "Skipping ", target, " on macOS"
        continue
      exec (if envPrefix.len != 0: envPrefix & " " else: "") & "nim c " & args & " --hints:off -r " & target

proc runTestsForSession(args: string) =
  when defined(linux) or defined(bsd):
    let
      sessionType = getEnv("XDG_SESSION_TYPE").toLowerAscii()
      hasWaylandDisplay = getEnv("WAYLAND_DISPLAY").len != 0
      hasX11Display = getEnv("DISPLAY").len != 0

    var ranAtLeastOne = false

    if hasWaylandDisplay or sessionType == "wayland":
      echo "Running tests with Wayland session env (XDG_SESSION_TYPE=wayland, DISPLAY=)"
      runTests(args, "XDG_SESSION_TYPE=wayland ")
      ranAtLeastOne = true

    if hasX11Display or sessionType == "x11":
      echo "Running tests with X11 session env (XDG_SESSION_TYPE=x11, WAYLAND_DISPLAY=)"
      runTests(args, "XDG_SESSION_TYPE=x11 ")
      ranAtLeastOne = true

    if not ranAtLeastOne:
      echo "No DISPLAY/WAYLAND_DISPLAY detected; running tests once with current environment"
      runTests(args)
  else:
    runTests(args)


task test, "test":
  runTestsForSession("")

task testRefc, "test with --mm:refc":
  runTests "--mm:refc"

task testWindows, "test windows version with wine on linux":
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc"

task testRefcWindows, "test windows version with wine on linux with --mm:refc":
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc --mm:refc"


task testAll, "run all tests":
  runTests ""
  runTests "--mm:refc"
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc"
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc --mm:refc"


task testIc, "test incremental compilation":
  exec "nim c -r --mm:refc --incremental:on tests/et_ic.nim"
