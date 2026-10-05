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

let
  libeglHandle = loadLibPattern("libEGL.so(|.1)")
  libwaylandeglHandle = loadLibPattern("libwayland-egl.so(|.1)")


siwin_loadDynlibIfExists libeglHandle:
  proc eglGetError*(): EglError
  proc eglGetDisplay*(native: pointer): EglDisplay

  proc eglInitializeRaw(d: EglDisplay; major: ptr int32; minor: ptr int32): cuint {.importc: "eglInitialize".}
  proc eglTerminateRaw(d: EglDisplay): cuint {.importc: "eglTerminate".}

  proc eglChooseConfigRaw(d: EglDisplay; attrs: ptr int32; retConfigs: ptr EglConfig;
      maxConfigs: int32; retConfigCount: ptr int32): cuint {.importc: "eglChooseConfig".}

  proc eglCreateContext*(d: EglDisplay; config: EglConfig; share: EglContext = nil;
      attrs: ptr int32 = nil): EglContext

  proc eglCreatePbufferSurface*(d: EglDisplay; config: EglConfig;
      attrs: ptr int32 = nil): EglSurface

  proc eglCreateWindowSurface*(d: EglDisplay; config: EglConfig; native_window: pointer; attrs: ptr int32 = nil): EglSurface
  proc eglCreatePlatformWindowSurface*(d: EglDisplay; config: EglConfig; native_window: pointer; attrs: ptr int32 = nil): EglSurface

  proc eglMakeCurrentRaw(d: EglDisplay; draw, read: EglSurface; ctx: EglContext): cuint {.importc: "eglMakeCurrent".}
  proc eglGetCurrentContext*(): EglContext
  proc eglSwapBuffersRaw(d: EglDisplay; srf: EglSurface): cuint {.importc: "eglSwapBuffers".}

  proc eglDestroyContextRaw(d: EglDisplay; ctx: EglContext): cuint {.importc: "eglDestroyContext".}
  proc eglDestroySurfaceRaw(d: EglDisplay; srf: EglSurface): cuint {.importc: "eglDestroySurface".}


# EGLBoolean is a C unsigned int; preserve the existing bool API for callers.
var eglInitialize* =
  if eglInitializeRaw == nil: nil
  else:
    proc(d: EglDisplay; major: ptr int32 = nil; minor: ptr int32 = nil): bool {.cdecl.} =
      eglInitializeRaw(d, major, minor) != 0

var eglTerminate* =
  if eglTerminateRaw == nil: nil
  else:
    proc(d: EglDisplay) {.cdecl.} =
      discard eglTerminateRaw(d)

var eglChooseConfig* =
  if eglChooseConfigRaw == nil: nil
  else:
    proc(d: EglDisplay; attrs: ptr int32; retConfigs: ptr EglConfig;
        maxConfigs: int32; retConfigCount: ptr int32): bool {.cdecl.} =
      eglChooseConfigRaw(d, attrs, retConfigs, maxConfigs, retConfigCount) != 0

var eglMakeCurrent* =
  if eglMakeCurrentRaw == nil: nil
  else:
    proc(d: EglDisplay; draw, read: EglSurface; ctx: EglContext): bool {.cdecl.} =
      eglMakeCurrentRaw(d, draw, read, ctx) != 0

var eglSwapBuffers* =
  if eglSwapBuffersRaw == nil: nil
  else:
    proc(d: EglDisplay; srf: EglSurface): bool {.cdecl.} =
      eglSwapBuffersRaw(d, srf) != 0

var eglDestroyContext* =
  if eglDestroyContextRaw == nil: nil
  else:
    proc(d: EglDisplay; ctx: EglContext): bool {.cdecl.} =
      eglDestroyContextRaw(d, ctx) != 0

var eglDestroySurface* =
  if eglDestroySurfaceRaw == nil: nil
  else:
    proc(d: EglDisplay; srf: EglSurface): bool {.cdecl.} =
      eglDestroySurfaceRaw(d, srf) != 0

siwin_loadDynlibIfExists libwaylandeglHandle:
  proc wl_egl_window_create*(surface: pointer, width, height: int32): EglWindow
  proc wl_egl_window_destroy*(win: EglWindow)
  proc wl_egl_window_resize*(win: EglWindow, width, height: int32, dx, dy: int32)
  proc wl_egl_window_get_attached_size*(win: EglWindow, width, height: ptr int32)


proc expect(x: bool) =
  if not x: raise OsError.newException("Error creating OpenGL context (" & $eglGetError() & ")")


proc requireEgl() =
  if libeglHandle == nil or eglGetError == nil or eglGetDisplay == nil or
      eglInitializeRaw == nil or eglTerminateRaw == nil or eglChooseConfigRaw == nil or
      eglCreateContext == nil or eglCreatePbufferSurface == nil or
      eglCreateWindowSurface == nil or eglMakeCurrentRaw == nil or
      eglGetCurrentContext == nil or eglSwapBuffersRaw == nil or eglDestroyContextRaw == nil or
      eglDestroySurfaceRaw == nil:
    raise OSError.newException("EGL library is not available")

proc requireEglInitialized() =
  requireEgl()
  if not initialized or egl_display == nil:
    raise OSError.newException("EGL has not been initialized")

proc requireWaylandEgl*() =
  requireEglInitialized()
  if libwaylandeglHandle == nil or wl_egl_window_create == nil or
      wl_egl_window_destroy == nil or wl_egl_window_resize == nil:
    raise OSError.newException("wayland-egl library is not available")

proc initEgl*(nativeDisplay: pointer) =
  if initialized: return
  requireEgl()

  egl_display = eglGetDisplay(nativeDisplay)
  expect egl_display != nil
  expect eglInitialize(egl_display)
  initialized = true

proc destroy*(context: OpenglContext) =
  if initialized and context.ctx != nil and eglGetCurrentContext != nil and
      eglMakeCurrentRaw != nil and eglGetCurrentContext() == context.ctx:
    discard egl_display.eglMakeCurrent(nil, nil, nil)
  if initialized and context.srf != nil and eglDestroySurfaceRaw != nil:
    discard egl_display.eglDestroySurface(context.srf)
  if initialized and context.ctx != nil and eglDestroyContextRaw != nil:
    discard egl_display.eglDestroyContext(context.ctx)
  if context.win != nil and wl_egl_window_destroy != nil:
    wl_egl_window_destroy(context.win)


proc newOpenglContext*: OpenglContext =
  ## creates opengl context (on new dummy surface)
  requireEglInitialized()
  try:
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
  except:
    destroy result
    result = OpenglContext()
    raise

proc newOpenglContext*(surface: pointer, w, h: int32): OpenglContext =
  ## creates opengl context (on window surface)
  requireWaylandEgl()
  try:
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
  except:
    destroy result
    result = OpenglContext()
    raise


proc makeCurrent*(context: OpenglContext) =
  requireEglInitialized()
  expect egl_display.eglMakeCurrent(context.srf, context.srf, context.ctx)


proc swapBuffers*(context: OpenglContext) =
  requireEglInitialized()
  expect egl_display.eglSwapBuffers(context.srf)


proc terminateEgl* =
  if not initialized: return
  initialized = false

  if eglTerminateRaw != nil:
    eglTerminate(egl_display)
  egl_display = nil
