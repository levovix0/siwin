import std/[importutils]
import pkg/[vmath]
import ../any/window {.all.}
import ./[libwayland, protocol, egl, globals]
import window {.all.}

privateAccess Window
privateAccess WindowWayland

type
  WindowWaylandOpengl* = ref object of WindowWayland
    eglContext: OpenglContext


proc initOpenglWindow(
  window: WindowWaylandOpengl,
  size: IVec2, screen: ScreenWayland,
  fullscreen, frameless, transparent: bool, class: string
) =
  globals.init()
  initEgl(globals.display.raw)

  window.basicInitWindow size, screen
  
  window.setupWindow fullscreen, frameless, transparent, size, class

  window.eglContext = newOpenglContext(window.surface.proxy.raw, size.x, size.y)
  makeCurrent window.eglContext

  commit window.surface


method makeCurrent*(window: WindowWaylandOpengl) =
  makeCurrent window.eglContext


method swapBuffers(window: WindowWaylandOpengl) =
  swapBuffers window.eglContext


method doResize(window: WindowWaylandOpengl, size: IVec2) =
  procCall window.WindowWayland.doResize(size)
  wl_egl_window_resize(window.eglContext.win, size.x, size.y, 0, 0)


proc newOpenglWindowWayland*(
  size = ivec2(1280, 720),
  title = "",
  screen = defaultScreenWayland(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
  vsync = true,

  class = "", # window class (used in x11), equals to title if not specified
): WindowWaylandOpengl =
  new result
  result.initOpenglWindow(size, screen, fullscreen, frameless, transparent, (if class == "": title else: class))
  result.title = title
  result.`vsync=`(vsync, silent=true)
  if not resizable: result.resizable = false
