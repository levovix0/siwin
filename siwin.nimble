version       = "0.2.0"
author        = "levovix0"
description   = "Nim Simple Window Maker"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.2.6"
requires "with"

when defined linux:
  requires "x11"
when defined windows:
  requires "winim"
