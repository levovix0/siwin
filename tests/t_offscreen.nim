import unittest
import opengl
import siwin/[platforms, offscreen]

let globals = newSiwinGlobals()

test "offscreen rendering":
  let ctx {.used.} = globals.newOpenglContext()
  if ctx == nil:
    echo "[SKIPPED] offscreen rendering unsupported on this backend"
  else:
    loadExtensions()
    glClear(GL_COLOR_BUFFER_BIT)  #? works without invisible window on linux?
