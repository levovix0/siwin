version       = "1.0.0"
author        = "levovix0"
description   = "Cross-platform window creation and event handling library"
license       = "MIT"
srcDir        = "src"

requires "nim >= 2.0"
requires "chroma >= 0.2.6"
requires "vmath >= 1.1.4"

# note: require platform dependencies only if it is the platform on which userprogrammer works.
#       ask a userprogrammer to install specific platform dependencies if cross compiling.
when defined(linux) or defined(bsd):
  requires "x11 >= 1.1"
  requires "https://github.com/planetis-m/vulkan#b223dc9"
  #requires "https://github.com/DanielBelmes/vulkan"

when defined(windows):
  requires "winim >= 3.6"

when defined(android):
  requires "jnim >= 0.5.2"
  requires "https://github.com/yglukhov/android"

when defined(macosx):
  requires "darwin >= 0.2.3"

feature "dev":
  requires "opengl"
  requires "nimgl"
  requires "pixie"
  requires "sdl2"



when fileExists("src/siwin/build_utils/tasks.nim"):
  include "src/siwin/build_utils/tasks.nim"

when fileExists("src/siwin/build_utils/android.nim"):
  import "src/siwin/build_utils/android.nim"
  when fileExists("src/siwin/build_utils/androidTasks.nim"):
    include "src/siwin/build_utils/androidTasks.nim"

when fileExists("src/siwin/build_utils/macosTasks.nim"):
  include "src/siwin/build_utils/macosTasks.nim"


