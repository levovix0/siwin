import std/[dynlib]
import ../../[siwindefs]
import ./[libwayland]

type
  OpenglContext* = object
    ctx*: EglContext
    srf*: EglSurface
    win*: EglWindow

  EglDisplay* = ptr object
  
  EglConfig* = ptr object
  
  EglContext* = ptr object

  EglWindow* = ptr object
    version: int

    width: int32
    height: int32
    dx: int32
    dy: int32

    attached_width: int32
    attached_height: int32

    driver_private: pointer
    resize_callback: proc(win: EglWindow, userdata: pointer) {.cdecl.}
    destroy_window_callback: proc(userdata: pointer) {.cdecl.}

    surface: pointer

  EglSurface* = ptr object
  
  EglError* {.pure, size: 4.} = enum
    badAccess = 0x3002
    badAlloc = 0x3003
    badAttribute = 0x3004
    badConfig = 0x3005
    badContext = 0x3006
    badCurrentSurface = 0x3007
    badDisplay = 0x3008
    badMatch = 0x3009
    badNativePixmap = 0x300A
    badNativeWindow = 0x300B
    badParameter = 0x300C
    badSurface = 0x300D


const
  eglSurfaceType* = int32 0x3033
  eglPBufferBit* = int32 0x0001
  eglPixmapBit* = int32 0x0002
  eglWindowBit* = int32 0x0004

  eglRenderableType* = int32 0x3040
  eglOpenglEs2Bit* = int32 0x0004
  eglOpenglBit* = int32 0x0008

  eglAlphaSize* = int32 0x3021
  eglBlueSize* = int32 0x3022
  eglGreenSize* = int32 0x3023
  eglRedSize* = int32 0x3024

  eglWidth* = int32 0x3057
  eglHeight* = int32 0x3056

  eglNone* = int32 0x3038

  EGL_CONTEXT_CLIENT_VERSION* = int32 0x3098


var
  initialized: bool
  egl_display: EglDisplay

  libeglHandle = loadLib("libEGL.so")
  libwaylandeglHandle = loadLib("libwayland-egl.so")


if libeglHandle == nil or libwaylandeglHandle == nil:
  waylandAvailable = false


siwin_loadDynlibIfExists libeglHandle:
  proc eglGetError*(): EglError
  proc eglGetDisplay*(native: pointer): EglDisplay

  proc eglInitialize*(d: EglDisplay; major: ptr int32 = nil; minor: ptr int32 = nil): bool
  proc eglTerminate*(d: EglDisplay)

  proc eglChooseConfig*(d: EglDisplay; attrs: ptr int32; retConfigs: ptr EglConfig;
      maxConfigs: int32; retConfigCount: ptr int32): bool

  proc eglCreateContext*(d: EglDisplay; config: EglConfig; share: EglContext = nil;
      attrs: ptr int32 = nil): EglContext

  proc eglCreatePbufferSurface*(d: EglDisplay; config: EglConfig;
      attrs: ptr int32 = nil): EglSurface

  proc eglCreateWindowSurface*(d: EglDisplay; config: EglConfig; native_window: pointer; attrs: ptr int32 = nil): EglSurface
  proc eglCreatePlatformWindowSurface*(d: EglDisplay; config: EglConfig; native_window: pointer; attrs: ptr int32 = nil): EglSurface

  proc eglMakeCurrent*(d: EglDisplay; draw, read: EglSurface; ctx: EglContext): bool
  proc eglSwapBuffers*(d: EglDisplay; srf: EglSurface): bool

  proc eglDestroyContext*(d: EglDisplay; ctx: EglContext): bool
  proc eglDestroySurface*(d: EglDisplay; srf: EglSurface): bool


siwin_loadDynlibIfExists libwaylandeglHandle:
  proc wl_egl_window_create*(surface: pointer, width, height: int32): EglWindow
  proc wl_egl_window_destroy*(win: EglWindow)
  proc wl_egl_window_resize*(win: EglWindow, width, height: int32, dx, dy: int32)
  proc wl_egl_window_get_attached_size*(win: EglWindow, width, height: ptr int32)


proc expect(x: bool) =
  if not x: raise OsError.newException("Error creating OpenGL context (" & $eglGetError() & ")")


proc initEgl*(nativeDisplay: pointer) =
  if initialized: return
  initialized = true

  if libeglHandle == nil: return

  egl_display = eglGetDisplay(nativeDisplay)
  expect egl_display != nil
  expect eglInitialize(egl_display)


proc destroy*(context: OpenglContext) =
  # if context.win != nil:  #? causes crush
  #   wl_egl_window_destroy(context.win)
  if context.srf != nil:
    discard egl_display.eglDestroySurface(context.srf)
  if context.ctx != nil:
    discard egl_display.eglDestroyContext(context.ctx)


proc newOpenglContext*: OpenglContext =
  ## creates opengl context (on new dummy surface)
  var
    config: EglConfig
    configCount: int32
  var attrs = [
    eglSurfaceType, eglPBufferBit,
    eglRenderableType, eglOpenglEs2Bit,
    eglRedSize, 8,
    eglGreenSize, 8,
    eglBlueSize, 8,
    eglAlphaSize, 8,
    eglNone
  ]
  expect egl_display.eglChooseConfig(attrs[0].addr, config.addr, 1, configCount.addr)
  expect configCount == 1

  result.ctx = egl_display.eglCreateContext(config)
  expect result.ctx != nil

  var attrs2 = [
    eglWidth, 1,
    eglHeight, 1,
    eglNone
  ]
  result.srf = egl_display.eglCreatePbufferSurface(config, attrs2[0].addr)
  expect result.srf != nil


proc newOpenglContext*(surface: pointer, w, h: int32): OpenglContext =
  ## creates opengl context (on window surface)
  var
    config: EglConfig
    configCount: int32
  let attrs = [
    eglSurfaceType, eglWindowBit,
    eglRedSize, 8,
    eglGreenSize, 8,
    eglBlueSize, 8,
    eglAlphaSize, 8,
    eglRenderableType, eglOpenglEs2Bit,
    eglNone,
  ]
  expect egl_display.eglChooseConfig(attrs[0].addr, config.addr, 1, configCount.addr)
  expect configCount == 1

  let context_attrs = [
    EGL_CONTEXT_CLIENT_VERSION, 2,
    eglNone,
  ]
  result.ctx = egl_display.eglCreateContext(config, nil, context_attrs[0].addr)
  expect result.ctx != nil
  
  result.win = wl_egl_window_create(surface, w, h)
  expect result.win != nil

  result.srf = egl_display.eglCreateWindowSurface(config, result.win, nil)
  expect result.srf != nil


proc makeCurrent*(context: OpenglContext) =
  expect egl_display.eglMakeCurrent(context.srf, context.srf, context.ctx)


proc swapBuffers*(context: OpenglContext) =
  expect egl_display.eglSwapBuffers(context.srf)


proc terminateEgl* =
  if not initialized: return
  initialized = false
  
  eglTerminate(egl_display)
