version       = "0.1.0"
author        = "levovix0"
description   = "Simple Window Maker Nim port"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.2.6"
requires "with"

when defined(windows):
  requires "winim"
else:
  requires "x11"

requires "imageman"
