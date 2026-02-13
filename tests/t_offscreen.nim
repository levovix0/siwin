import unittest
import opengl
import siwin/[platforms, offscreen]

let globals = newSiwinGlobals(
  preferedPlatform = (when defined(linux) or defined(bsd): x11 else: defaultPreferedPlatform())
)

test "offscreen rendering":
  let ctx {.used.} = globals.newOpenglContext()
  if ctx == nil:
    echo "[SKIPPED] offscreen rendering unsupported on this backend"
  else:
    loadExtensions()
    glClear(GL_COLOR_BUFFER_BIT)  #? works without invisible window on linux?
