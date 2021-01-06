import macros, unicode, strutils, sequtils
import libx11

const dllname = 
  when defined(linux): "libGL.so.1"
  elif defined(windows): "GL.dll"
  elif defined(macosx): "/usr/X11R6/lib/libGL.dylib"
  else: "libGL.so"

macro glx(f: static[string], def: untyped) =
  result = def
  let cname = "glX" & $f.toRunes[0].toUpper & f[f.runeLenAt(0)..^1]
  result[result.len - 3] = quote do: {.cdecl, dynlib: dllname, importc: `cname`.}

const
  GlxUseGl* = 1'i32
  GlxBufferSize* = 2'i32
  GlxLevel* = 3'i32
  GlxRgba* = 4'i32
  GlxDoublebuffer* = 5'i32
  GlxStereo* = 6'i32
  GlxAux_buffers* = 7'i32
  GlxRedSize* = 8'i32
  GlxGreenSize* = 9'i32
  GlxBlueSize* = 10'i32
  GlxAlphaSize* = 11'i32
  GlxDepthSize* = 12'i32
  GlxStencilSize* = 13'i32
  GlxAccumRedSize* = 14'i32
  GlxAccumGreenSize* = 15'i32
  GlxAccumBlueSize* = 16'i32
  GlxAccumAlphaSize* = 17'i32
  GlxXVisualTypeExt* = 0x00000022
  GlxTransparentTypeExt* = 0x00000023
  GlxTransparentIndexValueExt* = 0x00000024
  GlxTransparentRedValueExt* = 0x00000025
  GlxTransparentGreenValueExt* = 0x00000026
  GlxTransparentBlueValueExt* = 0x00000027
  GlxTransparentAlphaValueExt* = 0x00000028
  GlxBadScreen* = 1
  GlxBadAttribute* = 2
  GlxNoExtension* = 3
  GlxBadVisual* = 4
  GlxBadContext* = 5
  GlxBadValue* = 6
  GlxBadEnum* = 7
  GlxVendor* = 1
  GlxVersion* = 2
  GlxExtensions* = 3
  GlxTrueColorExt* = 0x00008002
  GlxDirectColorExt* = 0x00008003
  GlxPseudoColorExt* = 0x00008004
  GlxStaticColorExt* = 0x00008005
  GlxGrayScaleExt* = 0x00008006
  GlxStaticGrayExt* = 0x00008007
  GlxNoneExt* = 0x00008000
  GlxTransparentRgbExt* = 0x00008008
  GlxTransparentIndexExt* = 0x00008009

type
  GlxContext* = ptr object
  GlxPixmap* = XID
  GlxContextID* = XID

  GlxBool* = distinct cint
  GlxDefect* = object of Defect

converter toGlxBool*(a: bool): GlxBool = a.cint.GlxBool
converter toBool*(a: GlxBool): bool = a.cint.bool

template glxAssertImpl*(a: untyped, s: string) =
  try: doassert a
  except AssertionDefect: raise GlxDefect.newException "assertion failed: `" & s & "`"
template glxAssert*(a: bool) = glxAssertImpl(a, astToStr(a))

proc `==`*(a: GlxContext, b: typeof nil): bool = a.pointer == nil

proc glxQueryVersion(dpy: PDisplay, maj, min: var cint): GlxBool {.glx: "queryVersion".}
proc glxQueryExtension*(dpy: PDisplay, errorb, event: var cint): GlxBool {.glx: "queryExtension".}
proc glxGetConfig*(dpy: PDisplay, visual: PXVisualInfo, attrib: cint, value: var cint): cint {.glx: "getConfig".}
proc glxChooseVisual(dpy: PDisplay, screen: cint, attribList: ptr int32): PXVisualInfo {.glx: "chooseVisual".}

proc glxChooseVisual*(screen: int, attr: openArray[int32]): PXVisualInfo =
  let attr = attr.toSeq & 0
  result = display.glxChooseVisual(screen.cint, attr[0].unsafeAddr)
  glxAssert result != nil

proc glxVersion*: tuple[maj, min: int] =
  var mj, mn: cint
  glxAssert display.glxQueryVersion(mj, mn)
  return (mj.int, mn.int)

proc glxCreateContext(dpy: PDisplay, vis: PXVisualInfo, shareList: GlxContext, direct: GlxBool): GlxContext {.glx: "createContext".}
proc glxDestroyContext(dpy: PDisplay, ctx: GlxContext) {.glx: "destroyContext".}
proc glxMakeCurrent*(dpy: PDisplay, drawable: Drawable, ctx: GlxContext): GlxBool {.glx: "makeCurrent".}
proc glxCopyContext(dpy: PDisplay, src, dst: GlxContext, mask: int32) {.glx: "copyContext".}
proc glxIsDirect(dpy: PDisplay, ctx: GlxContext): GlxBool {.glx: "isDirect".}

proc newGlxContext*(vis: PXVisualInfo, direct: bool = true, shareList: GlxContext = nil): GlxContext = display.glxCreateContext(vis, shareList, direct)
proc destroy*(a: GlxContext) = display.glxDestroyContext(a)
proc `target=`*(ctx: GlxContext, a: Drawable) = glxAssert display.glxMakeCurrent(a, ctx)
proc copyState*(src, dst: GlxContext, mask: int32) = display.glxCopyContext(src, dst, mask)
proc isDirect*(a: GlxContext): bool = display.glxIsDirect(a)

proc glxCurrentContext*(): GlxContext {.glx: "getCurrentContext".}
proc glxCurrentDrawable*(): Drawable {.glx: "getCurrentDrawable".}

proc glxCreatePixmap*(dpy: PDisplay, visual: PXVisualInfo, pixmap: Pixmap): GlxPixmap {.glx: "createGLXPixmap".}
proc glxDestroyPixmap*(dpy: PDisplay, pixmap: GlxPixmap) {.glx: "destroyGLXPixmap".}

proc glxSwapBuffers*(dpy: PDisplay, drawable: Drawable) {.glx: "swapBuffers".}

proc glxWaitGL*() {.glx: "waitGL".}
proc glxWaitX*() {.glx: "waitX".}
proc glxUseXFont*(font: Font, first, count, list: cint) {.glx: "useXFont".}

proc glxQueryExtensionsString*(dpy: PDisplay, screen: cint): cstring {.glx: "queryExtensionsString".}
proc glxQueryServerString*(dpy: PDisplay, screen, name: cint): cstring {.glx: "queryServerString".}
proc glxGetClientString*(dpy: PDisplay, name: cint): cstring {.glx: "getClientString".}

proc glxCreateGlxPixmapMESA*(dpy: PDisplay, visual: PXVisualInfo, pixmap: Pixmap, cmap: Colormap): GlxPixmap {.glx: "createGLXPixmapMESA".}
proc glxReleaseBufferMESA*(dpy: PDisplay, d: Drawable): GlxBool {.glx: "releaseBufferMESA".}
proc glxCopySubBufferMESA*(dpy: PDisplay, drawbale: Drawable, x, y, width, height: cint) {.glx: "copySubBufferMESA".}
proc glxGetVideoSyncSGI*(counter: var int32): cint {.glx: "getVideoSyncSGI".}
proc glxWaitVideoSyncSGI*(divisor, remainder: cint, count: var int32): cint {.glx: "waitVideoSyncSGI".}
