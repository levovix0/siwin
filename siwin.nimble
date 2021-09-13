version       = "0.4"
author        = "levovix0"
description   = "Nim Simple Window Maker"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.4"
requires "chroma >= 0.2.5"

when defined linux:
  requires "x11 >= 1.1"
when defined windows:
  requires "winim >= 3.6"

task test, "test":
  requires "nimgl >= 1.1", "pixie >= 2.1"

  withDir "tests":
    exec "nim c -r tests"
