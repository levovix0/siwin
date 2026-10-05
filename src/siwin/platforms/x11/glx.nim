import std/dynlib
import sequtils
import x11/x except Window
import ../../[siwindefs]
import ./x11api

type
  GlxContext* = object
    raw: pointer
  
  GlxFbConfig* = ptr object

const
  GLX_USE_GL* = 1'i32
  GLX_BUFFER_SIZE* = 2'i32
  GLX_LEVEL* = 3'i32
  GLX_RGBA* = 4'i32
  GLX_DOUBLEBUFFER* = 5'i32
  GLX_STEREO* = 6'i32
  GLX_AUX_BUFFERS* = 7'i32
  GLX_RED_SIZE* = 8'i32
  GLX_GREEN_SIZE* = 9'i32
  GLX_BLUE_SIZE* = 10'i32
  GLX_ALPHA_SIZE* = 11'i32
  GLX_DEPTH_SIZE* = 12'i32
  GLX_STENCIL_SIZE* = 13'i32
  GLX_ACCUM_RED_SIZE* = 14'i32
  GLX_ACCUM_GREEN_SIZE* = 15'i32
  GLX_ACCUM_BLUE_SIZE* = 16'i32
  GLX_ACCUM_ALPHA_SIZE* = 17'i32

  GLX_CONFIG_CAVEAT* = 0x20'i32
  GLX_DONT_CARE* = 0xFFFFFFFF'i32
  GLX_X_VISUAL_TYPE* = 0x22'i32
  GLX_TRANSPARENT_TYPE* = 0x23'i32
  GLX_TRANSPARENT_INDEX_VALUE* = 0x24'i32
  GLX_TRANSPARENT_RED_VALUE* = 0x25'i32
  GLX_TRANSPARENT_GREEN_VALUE* = 0x26'i32
  GLX_TRANSPARENT_BLUE_VALUE* = 0x27'i32
  GLX_TRANSPARENT_ALPHA_VALUE* = 0x28'i32
  GLX_WINDOW_BIT* = 0x00000001'i32
  GLX_PIXMAP_BIT* = 0x00000002'i32
  GLX_PBUFFER_BIT* = 0x00000004'i32
  GLX_AUX_BUFFERS_BIT* = 0x00000010'i32
  GLX_FRONT_LEFT_BUFFER_BIT* = 0x00000001'i32
  GLX_FRONT_RIGHT_BUFFER_BIT* = 0x00000002'i32
  GLX_BACK_LEFT_BUFFER_BIT* = 0x00000004'i32
  GLX_BACK_RIGHT_BUFFER_BIT* = 0x00000008'i32
  GLX_DEPTH_BUFFER_BIT* = 0x00000020'i32
  GLX_STENCIL_BUFFER_BIT* = 0x00000040'i32
  GLX_ACCUM_BUFFER_BIT* = 0x00000080'i32
  GLX_NONE* = 0x8000'i32
  GLX_SLOW_CONFIG* = 0x8001'i32
  GLX_TRUE_COLOR* = 0x8002'i32
  GLX_DIRECT_COLOR* = 0x8003'i32
  GLX_PSEUDO_COLOR* = 0x8004'i32
  GLX_STATIC_COLOR* = 0x8005'i32
  GLX_GRAY_SCALE* = 0x8006'i32
  GLX_STATIC_GRAY* = 0x8007'i32
  GLX_TRANSPARENT_RGB* = 0x8008'i32
  GLX_TRANSPARENT_INDEX* = 0x8009'i32
  GLX_VISUAL_ID* = 0x800B'i32
  GLX_SCREEN* = 0x800C'i32
  GLX_NON_CONFORMANT_CONFIG* = 0x800D'i32
  GLX_DRAWABLE_TYPE* = 0x8010'i32
  GLX_RENDER_TYPE* = 0x8011'i32
  GLX_X_RENDERABLE* = 0x8012'i32
  GLX_FBCONFIG_ID* = 0x8013'i32
  GLX_RGBA_TYPE* = 0x8014'i32
  GLX_COLOR_INDEX_TYPE* = 0x8015'i32
  GLX_MAX_PBUFFER_WIDTH* = 0x8016'i32
  GLX_MAX_PBUFFER_HEIGHT* = 0x8017'i32
  GLX_MAX_PBUFFER_PIXELS* = 0x8018'i32
  GLX_PRESERVED_CONTENTS* = 0x801B'i32
  GLX_LARGEST_PBUFFER* = 0x801C'i32
  GLX_WIDTH* = 0x801D'i32
  GLX_HEIGHT* = 0x801E'i32
  GLX_EVENT_MASK* = 0x801F'i32
  GLX_DAMAGED* = 0x8020'i32
  GLX_SAVED* = 0x8021'i32
  GLX_WINDOW* = 0x8022'i32
  GLX_PBUFFER* = 0x8023'i32
  GLX_PBUFFER_HEIGHT* = 0x8040'i32
  GLX_PBUFFER_WIDTH* = 0x8041'i32
  GLX_RGBA_BIT* = 0x00000001'i32
  GLX_COLOR_INDEX_BIT* = 0x00000002'i32
  GLX_PBUFFER_CLOBBER_MASK* = 0x08000000'i32


const dllname =
  when defined(linux) or defined(bsd): "libGL.so.1"
  elif defined(windows): "GL.dll"
  elif defined(macosx): "/usr/X11R6/lib/libGL.dylib"
  else: "libGL.so"


let libGlHandle =
  loadLibPattern(when defined(linux) or defined(bsd): "libGL.so(.1|)" else: dllname)

siwin_loadDynlibIfExists libGlHandle:
  proc glxChooseVisualProc(dpy: ptr Display, screen: cint, attribList: ptr int32): PXVisualInfo {.importc: "glXChooseVisual", raises: [].}
  proc glxChooseFbConfigProc(dpy: ptr Display, screen: cint, attribList: ptr int32, nitems: ptr cint): ptr UncheckedArray[GlxFbConfig] {.importc: "glXChooseFBConfig", raises: [].}
  proc glxGetVisualFromFbConfigProc(dpy: ptr Display, config: GlxFbConfig): PXVisualInfo {.importc: "glXGetVisualFromFBConfig", raises: [].}
  proc glxGetCurrentContextProc(): pointer {.importc: "glXGetCurrentContext", raises: [].}
  proc glxMakeCurrentProc(dpy: PDisplay, drawable: Drawable, ctx: pointer): cint {.importc: "glXMakeCurrent", raises: [].}
  proc glxDestroyContextProc(dpy: PDisplay, ctx: pointer) {.importc: "glXDestroyContext", raises: [].}
  proc glxCreateContextProc(dpy: PDisplay, vis: PXVisualInfo, shareList: pointer, direct: cint): pointer {.importc: "glXCreateContext", raises: [].}
  proc glxCreateNewContextProc(dpy: PDisplay, fbc: GlxFbConfig, renderType: cint, shareList: pointer, direct: cint): pointer {.importc: "glXCreateNewContext", raises: [].}
  proc glxSwapBuffersProc(dpy: PDisplay, drawable: Drawable) {.importc: "glXSwapBuffers", raises: [].}
  proc glxSwapIntervalExt*(d: ptr Display, drawable: Drawable, interval: cint) {.importc: "glXSwapIntervalEXT", raises: [].}
  proc glxSwapIntervalMesaRaw(interval: cuint): cint {.importc: "glXSwapIntervalMESA", raises: [].}
  proc glxSwapIntervalSgiRaw(interval: cint): cint {.importc: "glXSwapIntervalSGI", raises: [].}

var glxSwapIntervalMesa* =
  if glxSwapIntervalMesaRaw == nil: nil
  else:
    proc(interval: cint) {.cdecl, raises: [].} =
      discard glxSwapIntervalMesaRaw(interval.cuint)

var glxSwapIntervalSgi* =
  if glxSwapIntervalSgiRaw == nil: nil
  else:
    proc(interval: cint) {.cdecl, raises: [].} =
      discard glxSwapIntervalSgiRaw(interval)

proc requireGlx*() =
  if libGlHandle == nil or glxChooseVisualProc == nil or glxChooseFbConfigProc == nil or
      glxGetVisualFromFbConfigProc == nil or glxGetCurrentContextProc == nil or
      glxMakeCurrentProc == nil or glxDestroyContextProc == nil or
      glxCreateContextProc == nil or glxCreateNewContextProc == nil or
      glxSwapBuffersProc == nil:
    raise OSError.newException("OpenGL/GLX libraries are not available")

proc glxChooseVisual*(display: ptr Display, screen: int, attr: openarray[int32]): PXVisualInfo =
  requireGlx()
  let attr = attr.toSeq & 0
  glxChooseVisualProc(display, screen.cint, attr[0].addr)

proc glxChooseFbConfig*(display: ptr Display, screen: int, attr: openarray[int32]): seq[GlxFbConfig] =
  requireGlx()
  let attr = attr.toSeq & 0
  var nitems: cint
  let p = glxChooseFbConfigProc(display, screen.cint, attr[0].addr, nitems.addr)
  if nitems == 0 or p == nil:
    return
  result = newSeq[GlxFbConfig](nitems)
  for i in 0..<nitems:
    result[i] = p[i]

proc glxGetVisualFromFBConfig*(display: ptr Display, config: GlxFbConfig): PXVisualInfo =
  requireGlx()
  glxGetVisualFromFbConfigProc(display, config)

proc cGlxCurrentContext*(): pointer =
  requireGlx()
  glxGetCurrentContextProc()

proc glxCurrentContext*(): GlxContext =
  result.raw = cGlxCurrentContext()

proc makeCurrent*(display: ptr Display, a: Drawable, ctx: GlxContext) =
  requireGlx()
  discard glxMakeCurrentProc(display, a, ctx.raw)

proc destroy*(display: ptr Display, context: GlxContext) {.siwin_destructor, raises: [].} =
  if context.raw == nil or glxDestroyContextProc == nil:
    return
  if glxGetCurrentContextProc != nil and glxGetCurrentContextProc() == context.raw and
      glxMakeCurrentProc != nil:
    discard glxMakeCurrentProc(display, 0, nil)
  glxDestroyContextProc(display, context.raw)

proc newGlxContext*(display: ptr Display, vis: PXVisualInfo, direct: bool = true, shareList: GlxContext = GlxContext()): GlxContext =
  requireGlx()
  result.raw = glxCreateContextProc(display, vis, shareList.raw, direct.cint)

proc newGlxContext*(
  display: ptr Display, fbc: GlxFbConfig, renderType: cint = GLX_RGBA_TYPE, direct: bool = true, shareList: GlxContext = GlxContext()
): GlxContext =
  requireGlx()
  result.raw = glxCreateNewContextProc(display, fbc, renderType, shareList.raw, direct.cint)

proc glxSwapBuffers*(display: ptr Display, d: Drawable) =
  requireGlx()
  glxSwapBuffersProc(display, d)
