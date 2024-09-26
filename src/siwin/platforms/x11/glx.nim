import macros, unicode, strutils, sequtils, dynlib
import x11/[x, xlib, xutil]
import globalDisplay
import ../../[siwindefs]

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
  when defined(linux): "libGL.so.1"
  elif defined(windows): "GL.dll"
  elif defined(macosx): "/usr/X11R6/lib/libGL.dylib"
  else: "libGL.so"


macro glx(f: static[string], def: untyped) =
  result = def
  let cname = "glX" & $f.toRunes[0].toUpper & f[f.runeLenAt(0)..^1]
  result.pragma = quote do: {.cdecl, dynlib: dllname, importc: `cname`.}


proc glxChooseVisual*(screen: int, attr: openarray[int32]): PXVisualInfo =
  proc impl(dpy: ptr Display, screen: cint, attribList: ptr int32): PXVisualInfo {.glx: "chooseVisual".}
  let attr = attr.toSeq & 0
  result = display.impl(screen.cint, attr[0].addr)


proc glxChooseFbConfig*(screen: int, attr: openarray[int32]): seq[GlxFbConfig] =
  proc impl(dpy: ptr Display, screen: cint, attribList: ptr int32, nitems: ptr cint): ptr UncheckedArray[GlxFbConfig] {.glx: "chooseFBConfig".}
  let attr = attr.toSeq & 0
  var nitems: cint
  let p = display.impl(screen.cint, attr[0].addr, nitems.addr)
  if nitems == 0: return
  result = newSeq[GlxFbConfig](nitems)
  for i in 0..<nitems:
    result[i] = p[i]


proc glxGetVisualFromFBConfig*(config: GlxFbConfig): PXVisualInfo =
  proc impl(dpy: ptr Display, config: GlxFbConfig): PXVisualInfo {.glx: "getVisualFromFBConfig".}
  result = display.impl(config)


proc cGlxCurrentContext*(): pointer {.glx: "getCurrentContext".}
proc glxCurrentContext*(): GlxContext {.glx: "getCurrentContext".}


proc cMakeCurrent(dpy: PDisplay, drawable: Drawable, ctx: pointer): cint {.glx: "makeCurrent".}
proc makeCurrent*(a: Drawable, ctx: GlxContext) =
  proc impl(dpy: PDisplay, drawable: Drawable, ctx: pointer): cint {.glx: "makeCurrent".}
  discard display.impl(a, ctx.raw)


proc `=destroy`*(context: GlxContext) {.siwin_destructor.} =
  proc impl(dpy: PDisplay, ctx: GlxContext) {.glx: "destroyContext".}
  if context.raw == nil: return
  if cGlxCurrentContext() == context.raw:
    discard display.cMakeCurrent(0, nil)
  if context.raw != nil: display.impl(context)


proc newGlxContext*(vis: PXVisualInfo, direct: bool = true, shareList: GlxContext = GlxContext()): GlxContext =
  proc impl(dpy: PDisplay, vis: PXVisualInfo, shareList: GlxContext, direct: cint): GlxContext {.glx: "createContext".}
  display.impl(vis, shareList, direct.cint)


proc newGlxContext*(fbc: GlxFbConfig, renderType: cint = GLX_RGBA_TYPE, direct: bool = true, shareList: GlxContext = GlxContext()): GlxContext =
  proc impl(dpy: PDisplay, fbc: GlxFbConfig, renderType: cint, shareList: GlxContext, direct: cint): GlxContext {.glx: "createNewContext".}
  display.impl(fbc, renderType, shareList, direct.cint)


proc glxSwapBuffers*(d: Drawable) =
  proc impl(dpy: PDisplay, drawable: Drawable) {.glx: "swapBuffers".}
  display.impl(d)


let lib = loadLib dllname
let glxSwapIntervalExt* = cast[proc(d: ptr Display, drawable: Drawable, interval: cint) {.stdcall.}](lib.symAddr("glXSwapIntervalEXT"))
let glxSwapIntervalMesa* = cast[proc(interval: cint) {.stdcall.}](lib.symAddr("glXSwapIntervalMESA"))
let glxSwapIntervalSgi* = cast[proc(interval: cint) {.stdcall.}](lib.symAddr("glXSwapIntervalSGI"))
