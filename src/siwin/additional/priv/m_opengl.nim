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
    handle: x.Window

when defined(linux):
  proc getOpenglVisualMode*: VisualMode =
    x.connect()
    result.vi = glxChooseVisual(0, [GlxRgba, GlxDepthSize, 24, GlxDoublebuffer])
    x.disconnect()
  template openglVisualMode*: VisualMode = getOpenglVisualMode()

  proc initOpenglRender*(w: var Window) = with w:
    let vi = openglVisualMode.vi
    let ctx = newGlxContext(vi)
    glxAssert ctx != nil
    ctx.target = w.systemHandle

  proc `=destroy`*(a: var OpenGLRenderer) =
    d.glxSwapBuffers(a.handle)
    
  proc openglRender*(a: Window): OpenGLRenderer =
    result.handle = a.systemHandle
  
  proc closeOpenglRender*() =
    glxAssert d.glxMakeCurrent(0, nil.GlxContext)

when defined(windows):
  proc initOpenglRender*(w: var Window) = with w:
    discard
  proc openglRender*(a: Window): OpenGLRenderer = with a:
    discard
