import std/importutils
import vmath
import ../any/window as anyWindow
import window {.all.}, winapi

privateAccess Window
privateAccess WindowWinapi

type
  WindowWinapiOpengl* = ref object of WindowWinapi
    ctx: WglContext


proc initWindowWinapiOpengl(window: WindowWinapiOpengl; size: IVec2; screen: ScreenWinapi, fullscreen, frameless, transparent: bool) =
  window.initWindow size, screen, fullscreen, frameless, transparent, woClassName
  
  var pfd = PixelFormatDescriptor(
    nSize: Word PixelFormatDescriptor.sizeof,
    nVersion: 1,
    dwFlags: Pfd_draw_to_window or Pfd_support_opengl or Pfd_double_buffer,
    iPixelType: Pfd_type_rgba,
    cColorBits: 32,
    cDepthBits: 24,
    cStencilBits: 8,
    iLayerType: Pfd_main_plane,
  )
  window.hdc.SetPixelFormat(window.hdc.ChoosePixelFormat(pfd.addr), pfd.addr)
  window.ctx = WglContext(raw: wglCreateContext(window.hdc))
  discard window.hdc.wglMakeCurrent(window.ctx.raw)


method makeCurrent*(window: WindowWinapiOpengl) =
  discard window.hdc.wglMakeCurrent(window.ctx.raw)

method `vsync=`*(window: WindowWinapiOpengl, v: bool, silent = false) =
  if wglSwapIntervalExt == nil:
    wglSwapIntervalExt = cast[typeof wglSwapIntervalExt](wglGetProcAddress("wglSwapIntervalEXT"))
  if wglSwapIntervalExt == nil or wglSwapIntervalExt(if v: 1 else: 0) == 0:
    if not silent:
      raise OSError.newException("failed to " & (if v: "enable" else: "disable") & " vsync")

method displayImpl(window: WindowWinapiOpengl, eventsHandler: ptr WindowEventsHandler) =
  eventsHandler.pushEvent onRender, RenderEvent(window: window)
  window.hdc.SwapBuffers


proc newOpenglWindowWinapi*(
  size = ivec2(1280, 720),
  title = "",
  screen = defaultScreenWinapi(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
  vsync = true,
): WindowWinapiOpengl =
  new result
  result.initWindowWinapiOpengl(size, screen, fullscreen, frameless, transparent)
  result.title = title
  result.`vsync=`(vsync, silent=true)
  if not resizable: result.resizable = false
