version       = "0.4"
author        = "levovix0"
description   = "Nim Simple Window Maker"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.4"
requires "chroma >= 0.2.5"

when defined linux:
  requires "x11 >= 1.1"
  requires "https://github.com/levovix0/wayland"
when defined windows:
  requires "winim >= 3.6"

task test, "test":
  requires "nimgl >= 1.1", "pixie >= 2.1"

  withDir "tests":
    try:    exec "nim c -r tests"
    except: discard
