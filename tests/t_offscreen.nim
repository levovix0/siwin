import unittest
import opengl
import siwin/offscreen

test "offscreen rendering":
  let ctx {.used.} = newOpenglContext()
  loadExtensions()
  glClear(GL_COLOR_BUFFER_BIT)  # without this call, opengl won't be linked
