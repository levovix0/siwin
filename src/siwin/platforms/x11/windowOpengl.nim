import std/importutils
import vmath
import x11/x except Window
import x11/[xlib, xutil]
import ../any/window as anyWindow
import window {.all.}, glx, globalDisplay

privateAccess Window
privateAccess WindowX11

type
  WindowX11Opengl* = ref object of WindowX11
    glxContext: GlxContext
    vsyncEnabled: bool


proc initOpenglWindow(
  window: WindowX11Opengl,
  size: IVec2, screen: ScreenX11,
  fullscreen, frameless, transparent: bool, class: string
) =
  globalDisplay.init()
  window.basicInitWindow size, screen

  window.m_transparent = transparent
  let root = display.DefaultRootWindow
  var vi: XVisualInfo
  discard display.XMatchVisualInfo(window.screen, if transparent: 32 else: 24, TrueColor, vi.addr)
  let cmap = display.XCreateColormap(root, vi.visual, AllocNone)
  var swa = XSetWindowAttributes(colormap: cmap)
  window.handle = display.XCreateWindow(
    root, 0, 0, size.x.cuint, size.y.cuint, 0, vi.depth, InputOutput, vi.visual,
    CwColormap or CwEventMask or CwBorderPixel or CwBackPixel, swa.addr
  )

  window.setupWindow fullscreen, frameless, class

  window.glxContext = newGlxContext(vi.addr)
  window.handle.makeCurrent window.glxContext


method makeCurrent*(window: WindowX11Opengl) =
  window.handle.makeCurrent window.glxContext


method `vsync=`*(window: WindowX11Opengl, v: bool, silent = false) =
  window.vsyncEnabled = v
  if glxSwapIntervalExt != nil:
    display.glxSwapIntervalExt(window.handle, if v: 1 else: 0)
  elif glxSwapIntervalMesa != nil:
    glxSwapIntervalMesa(if v: 1 else: 0)
  elif glxSwapIntervalSgi != nil:
    glxSwapIntervalSgi(if v: 1 else: 0)
  else:
    if not silent:
      raise OSError.newException("VSync is not supported")


method beginSwapBuffers*(window: WindowX11Opengl) =
  if window.vsyncEnabled and window.syncState == SyncState.syncAndConfigureRecieved:
    window.vsync = false  # temporary disable vsync to avoid flickering

  window.handle.glxSwapBuffers()

method endSwapBuffers*(window: WindowX11Opengl) =
  if window.vsyncEnabled:
    window.vsync = true  # re-enable vsync


proc newOpenglWindowX11*(
  size = ivec2(1280, 720),
  title = "",
  screen = defaultScreenX11(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
  vsync = true,

  class = "", # window class (used in x11), equals to title if not specified
): WindowX11Opengl =
  new result
  result.initOpenglWindow(size, screen, fullscreen, frameless, transparent, (if class == "": title else: class))
  result.title = title
  result.`vsync=`(vsync, silent=true)
  if not resizable: result.resizable = false