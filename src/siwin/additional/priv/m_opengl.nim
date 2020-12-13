# TODO
import siwin/[window, image]
import with
when defined(linux):
  from siwin/libx11 as x import nil
when defined(window):
  import siwin/libwinapi

type OpenGLRenderer* = object

when defined(windows):
  proc initOpenglRender*(w: var Window) = with w:
    discard
  proc openglRender*(a: Picture): OpenGLRenderer = with a:
    discard
