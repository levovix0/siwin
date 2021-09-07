version       = "0.3.0"
author        = "levovix0"
description   = "Nim Simple Window Maker"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.4"

when defined linux:
  requires "x11"
when defined windows:
  requires "winim"

task test, "test":
  requires "nimgl"
  withDir "tests":
    exec "nim c -r tests"
