import macros, unicode, strutils, sequtils, dynlib
import x11/[x, xlib, xutil]
import globalDisplay

type
  GlxContext* = object
    raw: pointer

const
  GlxRgba* = 4'i32
  GlxDoublebuffer* = 5'i32
  GlxDepthSize* = 12'i32


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
  result = display.impl(screen.cint, attr[0].unsafeAddr)

proc cGlxCurrentContext*(): pointer {.glx: "getCurrentContext".}
proc glxCurrentContext*(): GlxContext {.glx: "getCurrentContext".}

proc cMakeCurrent(dpy: PDisplay, drawable: Drawable, ctx: pointer): cint {.glx: "makeCurrent".}
proc makeCurrent*(a: Drawable, ctx: GlxContext) =
  proc impl(dpy: PDisplay, drawable: Drawable, ctx: pointer): cint {.glx: "makeCurrent".}
  discard display.impl(a, ctx.raw)

proc `=destroy`*(context: GlxContext) =
  proc impl(dpy: PDisplay, ctx: GlxContext) {.glx: "destroyContext".}
  if context.raw == nil: return
  if cGlxCurrentContext() == context.raw:
    discard display.cMakeCurrent(0, nil)
  if context.raw != nil: display.impl(context)

proc newGlxContext*(vis: PXVisualInfo, direct: bool = true, shareList: GlxContext = GlxContext()): GlxContext =
  proc impl(dpy: PDisplay, vis: PXVisualInfo, shareList: GlxContext, direct: cint): GlxContext {.glx: "createContext".}
  display.impl(vis, shareList, direct.cint)

proc glxSwapBuffers*(d: Drawable) =
  proc impl(dpy: PDisplay, drawable: Drawable) {.glx: "swapBuffers".}
  display.impl(d)

let lib = loadLib dllname
let glxSwapIntervalExt* = cast[proc(d: ptr Display, drawable: Drawable, interval: cint) {.stdcall.}](lib.symAddr("glXSwapIntervalEXT"))
let glxSwapIntervalMesa* = cast[proc(interval: cint) {.stdcall.}](lib.symAddr("glXSwapIntervalMESA"))
let glxSwapIntervalSgi* = cast[proc(interval: cint) {.stdcall.}](lib.symAddr("glXSwapIntervalSGI"))
