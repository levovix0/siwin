
import pkg/x11/xlib
import pkg/x11/x except Window
import pkg/x11/[xutil]
import ../../[siwindefs]
import ../any/window
import ./[glx, siwinGlobals]

type
  InvisibleOpenglWindowX11* = ref InvisibleOpenglWindowX11Obj
  InvisibleOpenglWindowX11Obj = object of Window
    globals: SiwinGlobalsX11
    handle: x.Window
    ctx: GlxContext


proc `=destroy`(window: InvisibleOpenglWindowX11Obj) {.siwin_destructor.} =
  if window.handle != 0:
    discard window.globals.display.XDestroyWindow(window.handle)

proc newOpenglContextX11*(globals: SiwinGlobalsX11): InvisibleOpenglWindowX11 =
  new result
  result.globals = globals
  let root = globals.display.DefaultRootWindow

  var vi: XVisualInfo
  discard globals.display.XMatchVisualInfo(globals.display.DefaultScreen, 24, TrueColor, vi.addr)
  let cmap = globals.display.XCreateColormap(root, vi.visual, AllocNone)
  var swa = XSetWindowAttributes(colormap: cmap)
  result.handle = globals.display.XCreateWindow(root, 0, 0, 1, 1, 0, vi.depth, InputOutput, vi.visual, CwColormap or CwEventMask or CwBorderPixel or CwBackPixel, swa.addr)

  result.ctx = globals.display.newGlxContext(vi.addr)
  globals.display.makeCurrent(result.handle, result.ctx)


method makeCurrent*(window: InvisibleOpenglWindowX11) =
  window.globals.display.makeCurrent(window.handle, window.ctx)
