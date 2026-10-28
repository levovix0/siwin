import std/importutils
import vmath
import ../any/window as anyWindow
import window, winapi

privateAccess Window
privateAccess WindowWinapi

type
  WindowWinapiOpengl* = ref object of WindowWinapi
    ctx: WglContext

  WinapiOpenGlFallback* = ref object
    ## An OpenGL context attached to an existing Win32 window.
    ctx: WglContext
    window {.cursor.}: WindowWinapi
    hdc: Hdc

proc newWinapiOpenGlFallback*(window: WindowWinapi): WinapiOpenGlFallback =
  ## Creates a context for an existing window after its other presenter is released.
  ## The window must remain open until the context is destroyed.
  if window == nil or window.m_closed or window.hdc == 0:
    raise newException(ValueError, "Win32 window is unavailable for OpenGL")

  var pfd = PixelFormatDescriptor(
    nSize: Word PixelFormatDescriptor.sizeof,
    nVersion: 1,
    dwFlags:
      Pfd_draw_to_window or Pfd_support_opengl or Pfd_double_buffer or
      Pfd_support_composition,
    iPixelType: Pfd_type_rgba,
    cColorBits: 32,
    cDepthBits: 24,
    cAlphaBits: 8,
    iLayerType: Pfd_main_plane,
  )
  var pixelFormat = GetPixelFormat(window.hdc)
  if pixelFormat == 0:
    pixelFormat = ChoosePixelFormat(window.hdc, pfd.addr)
    if pixelFormat == 0 or SetPixelFormat(window.hdc, pixelFormat, pfd.addr) == 0:
      raise newException(OSError, "Could not set the Win32 OpenGL pixel format")
  else:
    var existing: PixelFormatDescriptor
    if DescribePixelFormat(
      window.hdc, pixelFormat, UINT(sizeof(existing)), existing.addr
    ) == 0 or existing.iPixelType != Pfd_type_rgba or
        (
          existing.dwFlags and
          (Pfd_draw_to_window or Pfd_support_opengl or Pfd_double_buffer)
        ) != (Pfd_draw_to_window or Pfd_support_opengl or Pfd_double_buffer):
      raise
        newException(OSError, "The existing Win32 pixel format does not support OpenGL")

  new result
  result.window = window
  result.hdc = window.hdc
  result.ctx.raw = wglCreateContext(window.hdc)
  if result.ctx.raw == 0:
    raise newException(OSError, "Could not create the Win32 OpenGL context")

proc makeCurrent*(fallback: WinapiOpenGlFallback) =
  ## Makes the fallback context current on the calling thread.
  if fallback == nil or fallback.window.m_closed or IsWindow(fallback.window.handle) == 0 or
      wglMakeCurrent(fallback.hdc, fallback.ctx.raw) == 0:
    raise newException(OSError, "Could not activate the Win32 OpenGL context")

proc swapBuffers*(fallback: WinapiOpenGlFallback) =
  ## Presents the current frame to the existing window.
  if fallback == nil or fallback.window.m_closed or IsWindow(fallback.window.handle) == 0 or
      SwapBuffers(fallback.hdc) == 0:
    raise newException(OSError, "Could not swap the Win32 OpenGL buffers")

proc initWindowWinapiOpengl(
    window: WindowWinapiOpengl,
    size: IVec2,
    screen: ScreenWinapi,
    fullscreen, frameless, transparent: bool,
    globals: SiwinGlobalsWinapi,
) =
  window.initWindow(
    size, screen, fullscreen, frameless, transparent, woClassName, globals
  )

  var pfd = PixelFormatDescriptor(
    nSize: Word PixelFormatDescriptor.sizeof,
    nVersion: 1,
    dwFlags:
      Pfd_draw_to_window or Pfd_support_opengl or Pfd_double_buffer or
      Pfd_support_composition,
    iPixelType: Pfd_type_rgba,
    cColorBits: 32,
    cDepthBits: 24,
    cAlphaBits: 8,
    iLayerType: Pfd_main_plane,
  )

  window.hdc.SetPixelFormat(window.hdc.ChoosePixelFormat(pfd.addr), pfd.addr)
  window.ctx = WglContext(raw: wglCreateContext(window.hdc))
  discard window.hdc.wglMakeCurrent(window.ctx.raw)

method makeCurrent*(window: WindowWinapiOpengl) =
  discard window.hdc.wglMakeCurrent(window.ctx.raw)

method `vsync=`*(window: WindowWinapiOpengl, v: bool, silent = false) =
  if wglSwapIntervalExt == nil:
    wglSwapIntervalExt =
      cast[typeof wglSwapIntervalExt](wglGetProcAddress("wglSwapIntervalEXT"))
  if wglSwapIntervalExt == nil or wglSwapIntervalExt(if v: 1 else: 0) == 0:
    if not silent:
      raise
        OSError.newException("failed to " & (if v: "enable" else: "disable") & " vsync")

method displayImpl(window: WindowWinapiOpengl) =
  window.makeCurrent()
  window.eventsHandler.pushEvent onRender, RenderEvent(window: window)
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
    globals: SiwinGlobalsWinapi = nil,
): WindowWinapiOpengl =
  new result
  result.initWindowWinapiOpengl(
    size, screen, fullscreen, frameless, transparent, globals
  )
  result.title = title
  result.`vsync=`(vsync, silent = true)
  if not resizable:
    result.resizable = false
