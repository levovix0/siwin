import std/[importutils]
import pkg/[vmath]
import ../../[siwindefs]
import ../any/window {.all.}
import ./[libwayland, protocol, egl, siwinGlobals]
import window {.all.}

privateAccess Window
privateAccess WindowWayland

type
  WindowWaylandOpengl* = ref WindowWaylandOpenglObj
  WindowWaylandOpenglObj* = object of WindowWayland
    eglContext: OpenglContext


proc `=trace`(x: var WindowWaylandOpenglObj, env: pointer) =
  #? for some reason, without this, nim produces invalid C code for =trace implementation
  `=trace`(cast[ptr WindowWaylandObj](x.addr)[], env)


proc `=destroy`(window: WindowWaylandOpenglObj) {.siwin_destructor.} =
  release cast[WindowWaylandOpengl](window.addr)

  for x in window.fields:
    when compiles(`=destroy`(x)):
      try:
        `=destroy`(x)
      except: discard


method release(window: WindowWaylandOpengl) =
  ## destroy wayland part of window
  try:
    destroy window.eglContext
  except:
    discard

  procCall window.WindowWayland.release()

proc initOpenglWindow(
  window: WindowWaylandOpengl,
  size: IVec2, screen: ScreenWayland,
  fullscreen, frameless, transparent: bool, class: string
) =
  initEgl(window.globals.display.raw)

  window.basicInitWindow size, screen
  
  window.setupWindow fullscreen, frameless, transparent, size, class

  let scaledSize = window.bufferSize(size)
  window.eglContext = newOpenglContext(window.surface.proxy.raw, scaledSize.x, scaledSize.y)
  makeCurrent window.eglContext

  # commit window.surface


method makeCurrent*(window: WindowWaylandOpengl) =
  makeCurrent window.eglContext


method swapBuffers(window: WindowWaylandOpengl) =
  swapBuffers window.eglContext
  commit window.surface


method doResize(window: WindowWaylandOpengl, size: IVec2) =
  procCall window.WindowWayland.doResize(size)
  let scaledSize = window.bufferSize(size)
  wl_egl_window_resize(window.eglContext.win, scaledSize.x, scaledSize.y, 0, 0)


proc newOpenglWindowWayland*(
  globals: SiwinGlobalsWayland,
  size = ivec2(1280, 720),
  title = "",
  screen: ScreenWayland,
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
  vsync = true,
  kind = WindowWaylandKind.XdgSurface,
  layer = Layer.Overlay,
  namespace = "siwin",

  class = "", # application ID; defaults to title
): WindowWaylandOpengl =
  new result
  result.globals = globals
  result.kind = kind
  result.namespace = namespace
  result.layer = layer
  result.initOpenglWindow(size, screen, fullscreen, frameless, transparent, (if class == "": title else: class))
  result.title = title
  result.`vsync=`(vsync, silent=true)
  if not resizable: result.resizable = false

proc newOpenglLayerSurfaceWindowWayland*(
  globals: SiwinGlobalsWayland,
  size = ivec2(1280, 32),
  title = "",
  screen: ScreenWayland,
  config: LayerSurfaceConfig,
  transparent = false,
  vsync = true,
): WindowWaylandOpengl =
  ## Creates an OpenGL window backed by a Wayland layer-shell surface.
  ##
  ## `config` controls the layer-shell role. Anchoring to both horizontal or
  ## both vertical edges lets the compositor determine that dimension;
  ## otherwise `size` is requested.
  ##
  ## Raises `WaylandExtensionNotFound` when a required Wayland extension is
  ## unavailable.
  new result
  result.globals = globals
  initEgl(result.globals.display.raw)
  result.initLayerSurfaceWindow(size, screen, config, transparent, title)

  let scaledSize = result.bufferSize(size)
  result.eglContext = newOpenglContext(
    result.surface.proxy.raw, scaledSize.x, scaledSize.y
  )
  makeCurrent result.eglContext
  result.title = title
  result.`vsync=`(vsync, silent = true)
