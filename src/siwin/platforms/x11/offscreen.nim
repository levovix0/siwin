
import pkg/x11/xlib
import pkg/x11/x except Window
import pkg/x11/[xutil]
import ../../[siwindefs]
import ../any/window
import globalDisplay, glx

type
  InvisibleOpenglWindowX11* = ref InvisibleOpenglWindowX11Obj
  InvisibleOpenglWindowX11Obj = object of Window
    handle: x.Window
    ctx: GlxContext


proc `=destroy`(window: InvisibleOpenglWindowX11Obj) {.siwin_destructor.} =
  if window.handle != 0:
    discard display.XDestroyWindow(window.handle)

proc newOpenglContextX11*: InvisibleOpenglWindowX11 =
  new result
  globalDisplay.init()
  let root = display.DefaultRootWindow

  var vi: XVisualInfo
  discard display.XMatchVisualInfo(display.DefaultScreen, 24, TrueColor, vi.addr)
  let cmap = display.XCreateColormap(root, vi.visual, AllocNone)
  var swa = XSetWindowAttributes(colormap: cmap)
  result.handle = display.XCreateWindow(root, 0, 0, 1, 1, 0, vi.depth, InputOutput, vi.visual, CwColormap or CwEventMask or CwBorderPixel or CwBackPixel, swa.addr)

  result.ctx = newGlxContext(vi.addr)
  result.handle.makeCurrent result.ctx

method makeCurrent*(windows: InvisibleOpenglWindowX11) =
  windows.handle.makeCurrent windows.ctx
