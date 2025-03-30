import unittest
import opengl
import siwin/[platforms, offscreen]

let globals = newSiwinGlobals()

test "offscreen rendering":
  let ctx {.used.} = globals.newOpenglContext()
  loadExtensions()
  glClear(GL_COLOR_BUFFER_BIT)  #? works without invisible window on linux?
