import std/importutils
import vmath
import ../../[colorutils]
import ../any/[window {.all.} as anyWindow, windowUtils]
import window {.all.}, winapi

privateAccess Window
privateAccess WindowWinapi
privateAccess SiwinGlobalsObj


type
  WindowWinapiOpengl* = ptr WindowWinapiOpenglObj
  WindowWinapiOpenglObj = object of WindowWinapi
    ctx: WglContext


proc initWindowWinapiOpengl(
  window: WindowWinapiOpengl; size: IVec2; screen: Screen,
  fullscreen, frameless, transparent: bool,
) =
  window.initWindow size, screen, fullscreen, frameless, transparent, woClassName
  
  var pfd = PixelFormatDescriptor(
    nSize: Word PixelFormatDescriptor.sizeof,
    nVersion: 1,
    dwFlags: Pfd_draw_to_window or Pfd_support_opengl or Pfd_double_buffer or Pfd_support_composition,
    iPixelType: Pfd_type_rgba,
    cColorBits: 32,
    cDepthBits: 24,
    cAlphaBits: 8,
    iLayerType: Pfd_main_plane,
  )

  window.hdc.SetPixelFormat(window.hdc.ChoosePixelFormat(pfd.addr), pfd.addr)
  window.ctx = WglContext(raw: wglCreateContext(window.hdc))
  discard window.hdc.wglMakeCurrent(window.ctx.raw)



proc winapi_opengl_displayImpl(window: WindowWinapiOpengl) {.cdecl.} =
  window.eventsHandler.pushEvent onRender, RenderEvent(window: window)
  window.hdc.SwapBuffers


proc winapi_opengl_destroy(window: WindowWinapiOpengl) {.cdecl.} =
  `=destroy`(window.ctx)
  `=destroy`(cast[WindowWinapi](window)[])



proc winapi_opengl_pixelBuffer(window: WindowWinapiOpengl): PixelBuffer {.cdecl.} = discard


proc winapi_opengl_makeCurrent(window: WindowWinapiOpengl) {.cdecl.} =
  discard window.hdc.wglMakeCurrent(window.ctx.raw)


proc winapi_opengl_set_vsync(window: WindowWinapiOpengl, v: bool, silent = false) {.cdecl.} =
  if wglSwapIntervalExt == nil:
    wglSwapIntervalExt = cast[typeof wglSwapIntervalExt](wglGetProcAddress("wglSwapIntervalEXT"))
  if wglSwapIntervalExt == nil or wglSwapIntervalExt(if v: 1 else: 0) == 0:
    if not silent:
      raise OSError.newException("failed to " & (if v: "enable" else: "disable") & " vsync")


proc winapi_opengl_vulkanSurface(window: WindowWinapiOpengl): pointer {.cdecl.} = discard



proc winapiOpenglWindowVtalbe: WindowVtable =
  makeWindowVtable(winapi, winapi_opengl)


proc newOpenglWindowWinapi*(
  globals: SiwinGlobals,
  size = ivec2(1280, 720),
  title = "",
  screen = -1.Screen,
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
  vsync = true,
): WindowWinapiOpengl =
  if globals.openglVtable.close == nil:
    globals.openglVtable = winapiOpenglWindowVtalbe()

  result = create(WindowWinapiOpenglObj)
  result.globals = globals
  result.vtable = globals.openglVtable.addr
  let screen = (if screen.int == -1: globals.defaultScreen else: screen)
  result.initWindowWinapiOpengl(size, screen, fullscreen, frameless, transparent)
  result.title = title
  result.`vsync=`(vsync, silent=true)
  if not resizable: result.resizable = false
