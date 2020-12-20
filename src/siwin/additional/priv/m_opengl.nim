# TODO
import siwin/[window, image], m_glx
import with
when defined(linux):
  from siwin/libx11 as x import nil
when defined(window):
  import siwin/libwinapi

when defined(linux):
  template d*: x.PDisplay = x.display

type OpenGLRenderer* = object

when defined(linux):
  proc initOpenglRender*(w: var Window) = with w:
    let vi = glxChooseVisual(0, [GlxRgba, GlxDepthSize, 24, GlxDoublebuffer, 0])
    let ctx = newGlxContext(vi)
    discard
  proc openglRender*(a: Window): OpenGLRenderer = with a:
    discard

when defined(windows):
  proc initOpenglRender*(w: var Window) = with w:
    discard
  proc openglRender*(a: Window): OpenGLRenderer = with a:
    discard
