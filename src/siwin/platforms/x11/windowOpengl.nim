import std/importutils
import vmath
import x11/x except Window
import x11/[xlib, xutil, xrender]
import ../../[siwindefs]
import ../any/window as anyWindow
import ./[window {.all.}, glx, siwinGlobals]

privateAccess Window
privateAccess WindowX11

type
  WindowX11Opengl* = ref WindowX11OpenglObj
  WindowX11OpenglObj* = object of WindowX11
    glxContext: GlxContext
    vsyncEnabled: bool


proc `=trace`(x: var WindowX11OpenglObj, env: pointer) =
  #? for some reason, without this, nim produces invalid C code for =trace implementation
  `=trace`(cast[ptr WindowX11Obj](x.addr)[], env)

proc `=destroy`(x: WindowX11OpenglObj) {.siwin_destructor.} =
  #? for some reason, without this, nim produces invalid C code for =trace implementation
  x.globals.display.destroy(x.glxContext)
  `=destroy`(cast[ptr WindowX11Obj](x.addr)[])


proc initOpenglWindow(
  window: WindowX11Opengl,
  size: IVec2, screen: ScreenX11,
  fullscreen, frameless, transparent: bool, class: string
) =
  window.basicInitWindow size, screen

  window.m_transparent = transparent
  let root = window.globals.display.DefaultRootWindow
  
  var vi: XVisualInfo
  var fbc: GlxFbConfig

  if transparent:
    let fbcs = window.globals.display.glxChooseFbConfig(screen.number, [
      GLX_RENDER_TYPE, GLX_RGBA_BIT,
      GLX_DRAWABLE_TYPE, GLX_WINDOW_BIT,
      GLX_DOUBLEBUFFER, 1,
      GLX_RED_SIZE, 8,
      GLX_GREEN_SIZE, 8,
      GLX_BLUE_SIZE, 8,
      GLX_ALPHA_SIZE, 8,
      GLX_DEPTH_SIZE, 16,
    ])
    for i, x in fbcs:
      type
        XRenderDirectFormat = object
          red*: cshort
          redMask*: cshort
          green*: cshort
          greenMask*: cshort
          blue*: cshort
          blueMask*: cshort
          alpha*: cshort
          alphaMask*: cshort

        XRenderPictFormat = object
          id*: culong
          thetype*: cint
          depth*: cint
          direct*: XRenderDirectFormat
          colormap*: Colormap

      if window.globals.display.glxGetVisualFromFBConfig(x) == nil: continue
      var pf = cast[ptr XRenderPictFormat](
        window.globals.display.XRenderFindVisualFormat(window.globals.display.glxGetVisualFromFBConfig(x).visual)
      )
      if pf == nil: continue
      if pf.direct.alphaMask > 0:
        vi = window.globals.display.glxGetVisualFromFBConfig(x)[]
        fbc = x
        break
  
  else:
    discard window.globals.display.XMatchVisualInfo(window.screen, 24, TrueColor, vi.addr)
  
  let cmap = window.globals.display.XCreateColormap(root, vi.visual, AllocNone)
  var swa = XSetWindowAttributes(colormap: cmap)

  window.handle = window.globals.display.XCreateWindow(
    root, 0, 0, size.x.cuint, size.y.cuint, 0, vi.depth, InputOutput, vi.visual,
    CwColormap or CwEventMask or CwBorderPixel or CwBackPixel, swa.addr
  )

  window.setupWindow fullscreen, frameless, class

  if transparent:
    window.glxContext = window.globals.display.newGlxContext(fbc)
  else:
    window.glxContext = window.globals.display.newGlxContext(vi.addr)
  window.globals.display.makeCurrent(window.handle, window.glxContext)


method makeCurrent*(window: WindowX11Opengl) =
  window.globals.display.makeCurrent(window.handle, window.glxContext)


method `vsync=`*(window: WindowX11Opengl, v: bool, silent = false) =
  if window.vsyncEnabled == v: return
  window.vsyncEnabled = v
  
  if glxSwapIntervalExt != nil:
    window.globals.display.glxSwapIntervalExt(window.handle, if v: 1 else: 0)
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

  window.globals.display.glxSwapBuffers(window.handle)

method endSwapBuffers*(window: WindowX11Opengl) =
  if window.vsyncEnabled:
    window.vsync = true  # re-enable vsync


proc newOpenglWindowX11*(
  globals: SiwinGlobalsX11,
  size = ivec2(1280, 720),
  title = "",
  screen = globals.defaultScreenX11(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
  vsync = true,

  class = "", # window class (used in x11), equals to title if not specified
): WindowX11Opengl =
  new result
  result.globals = globals
  result.initOpenglWindow(size, screen, fullscreen, frameless, transparent, (if class == "": title else: class))
  result.title = title
  result.`vsync=`(vsync, silent=true)
  if not resizable: result.resizable = false
