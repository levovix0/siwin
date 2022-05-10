import os, strutils, strformat, tables, hashes, sets
import x11/[xlib, xutil, xatom, xshm, cursorfont, keysym]
import x11/x except Window, Pixmap, Cursor
export xlib, xutil, xatom, xshm, cursorfont, keysym
export x except Window, Pixmap, Cursor
import chroma
import utils, image

type
  X11ValueError* = object of CatchableError
  X11Defect* = object of Defect

  Window* = distinct x.Window
  Pixmap* = distinct x.Pixmap
  Cursor* = distinct x.Cursor

  GraphicsContext* = object
    gc*: GC
    gcv*: XGCValues
    target*: Drawable

  XSyncValue* = object
    hi*: int32
    lo*: uint32
  
  XSyncCounter* = distinct XID

const
  xaPrimary* = Atom 1
  xaSecondary* = Atom 2
  xaArc* = Atom 3
  xaAtom* = Atom 4
  xaBitmap* = Atom 5
  xaCardinal* = Atom 6
  xaColormap* = Atom 7
  xaCursor* = Atom 8
  xaCutBuffer0* = Atom 9
  xaCutBuffer1* = Atom 10
  xaCutBuffer2* = Atom 11
  xaCutBuffer3* = Atom 12
  xaCutBuffer4* = Atom 13
  xaCutBuffer5* = Atom 14
  xaCutBuffer6* = Atom 15
  xaCutBuffer7* = Atom 16
  xaDrawable* = Atom 17
  xaFont* = Atom 18
  xaInteger* = Atom 19
  xaPixmap* = Atom 20
  xaPoint* = Atom 21
  xaRectangle* = Atom 22
  xaResourceManager* = Atom 23
  xaRgbColorMap* = Atom 24
  xaRgbBestMap* = Atom 25
  xaRgbBlueMap* = Atom 26
  xaRgbDefaultMap* = Atom 27
  xaRgbGrayMap* = Atom 28
  xaRgbGreenMap* = Atom 29
  xaRgbRedMap* = Atom 30
  xaString* = Atom 31
  xaVisualid* = Atom 32
  xaWindow* = Atom 33
  xaWmCommand* = Atom 34
  xaWmHints* = Atom 35
  xaWmClientMachine* = Atom 36
  xaWmIconName* = Atom 37
  xaWmIconSize* = Atom 38
  xaWmName* = Atom 39
  xaWmNormalHints* = Atom 40
  xaWmSizeHints* = Atom 41
  xaWmZoomHints* = Atom 42
  xaMinSpace* = Atom 43
  xaNormSpace* = Atom 44
  xaMaxSpace* = Atom 45
  xaEndSpace* = Atom 46
  xaSuperscriptX* = Atom 47
  xaSuperscriptY* = Atom 48
  xaSubscriptX* = Atom 49
  xaSubscriptY* = Atom 50
  xaUnderlinePosition* = Atom 51
  xaUnderlineThickness* = Atom 52
  xaStrikeoutAscent* = Atom 53
  xaStrikeoutDescent* = Atom 54
  xaItalicAngle* = Atom 55
  xaXHeight* = Atom 56
  xaQuadWidth* = Atom 57
  xaWeight* = Atom 58
  xaPointSize* = Atom 59
  xaResolution* = Atom 60
  xaCopyright* = Atom 61
  xaNotice* = Atom 62
  xaFontName* = Atom 63
  xaFamilyName* = Atom 64
  xaFullName* = Atom 65
  xaCapHeight* = Atom 66
  xaWmClass* = Atom 67
  xaWmTransientFor* = Atom 68
  xaLastPredefined* = Atom 68


const libXExt* =
  when defined(macosx):
    "libXext.dylib"
  else:
    "libXext.so(|.6)"


var display*: PDisplay
display = XOpenDisplay(getEnv("DISPLAY").cstring)
if display == nil: raise X11Defect.newException("failed to open X11 display, make sure the DISPLAY environment variable is set correctly")

type LibX11GarbageCollector = object
proc `=destroy`(a: var LibX11GarbageCollector) =
  discard XCloseDisplay display
var libx11gc {.used.}: LibX11GarbageCollector


var atoms: Table[Hash, Atom]

proc atom*(name: static string): Atom =
  const i = hash name
  if not atoms.hasKey(i):
    atoms[i] = display.XInternAtom(name, 0)
  atoms[i]

proc atomIfExist*(name: string): Atom =
  display.XInternAtom(name, 1)


converter toXID*(a: Window): XID = a.XID
converter toXID*(a: Pixmap): XID = a.XID
converter toXID*(a: Cursor): XID = a.XID
converter toDrawable*(a: Window|Pixmap|Cursor): Drawable = a.toXID
converter toPXID*(a: ptr Window): PXID = cast[PXID](a)
converter toPXID*(a: ptr Pixmap): PXID = cast[PXID](a)
converter toPXID*(a: ptr Cursor): PXID = cast[PXID](a)
converter toPDrawable*(a: Window|Pixmap|Cursor): PDrawable = a.toPXID


proc destroy*(a: Window)    = discard display.XDestroyWindow(a)
proc destroy*(a: Pixmap)    = discard display.XFreePixmap(a)
proc destroy*(a: Cursor)    = discard display.XFreeCursor(a)
proc destroy*(a: GC)        = discard display.XFreeGC(a)
proc destroy*(a: PXImage)   = discard XDestroyImage(a)
proc destroy*(a: XIC)       = XDestroyIC(a)
proc destroy*(a: PXWmHints) = discard XFree(a)
proc close*(a: XIM)         = discard XCloseIM(a)

proc `=destroy`(this: var GraphicsContext) =
  if this.gc != nil: destroy this.gc


proc syncX*() = discard display.XSync(0)

proc newSimpleWindow*(parent: Window, x, y: int, w, h: int, borderW: int, border: culong, background: culong): Window =
  result = Window display.XCreateSimpleWindow(parent, x.cint, y.cint, w.cuint, h.cuint, borderW.cuint, border, background)
  doassert result != 0
proc newWindow*(parent: Window, x, y: int, w, h: int, borderW: int, depth: int, class: cuint, visual: PVisual, valuemask: culong, attributes: XSetWindowAttributes): Window =
  result = Window display.XCreateWindow(parent, x.cint, y.cint, w.cuint, h.cuint, borderW.cuint, depth.cint, class, visual, valuemask, attributes.unsafeAddr)
  doassert result != 0

proc geometry*(a: Window): tuple[root: Window; x, y: int; w, h: int; borderW: int, depth: int] =
  var
    root: Window
    x, y: cint
    w, h: cuint
    borderW: cuint
    depth: cuint
  discard display.XGetGeometry(a, root.addr, x.addr, y.addr, w.addr, h.addr, borderW.addr, depth.addr)
  (root, x.int, y.int, w.int, h.int, borderW.int, depth.int)
proc size*(a: tuple[root: Window; x, y: int; w, h: int; borderW: int, depth: int]): tuple[x, y: int] = (a.w, a.h)
proc pos*(a: tuple[root: Window; x, y: int; w, h: int; borderW: int, depth: int]): tuple[x, y: int] = (a.x, a.y)

proc cursor*(): tuple[x, y: int; root, child: Window; winX, winY: int; mask: uint; exists: bool] =
  ## find cursor and return where it is
  var
    root, child: Window
    x, y: cint
    winX, winY: cint
    mask: cuint
  for i in 0..display.ScreenCount:
    if display.XQueryPointer(display.XRootWindow(i), root.addr, child.addr, x.addr, y.addr, winX.addr, winY.addr, mask.addr) != 0:
      return (x.int, y.int, root, child, winX.int, winY.int, mask.uint, true)
proc pos*(a: tuple[x, y: int; root, child: Window; winX, winY: int; mask: uint; exists: bool]): tuple[x, y: int] = (a.x, a.y)

proc queryKeyboardState*(): set[0..255] =
  var r: array[32, char]
  discard display.XQueryKeymap(r)
  result = cast[ptr set[0..255]](r.addr)[]

proc attributes*(a: Window): XWindowAttributes =
  discard display.XGetWindowAttributes(a, result.addr)
proc root*(a: Window): Window =
  Window a.attributes.root

proc map*(a: Window) =
  discard display.XMapWindow(a)


proc wmProtocols*(a: Window): seq[Atom] =
  var
    protocols: ptr UncheckedArray[Atom]
    n: cint
  discard display.XGetWMProtocols(a, cast[PPAtom](protocols.addr), n.addr)
  result.setLen n.int
  for i in 0..<n.int: result[i] = protocols[i]
  discard XFree protocols

proc `wmProtocols=`*(a: Window, v: openarray[Atom]) =
  discard display.XSetWMProtocols(a, v.dataAddr, v.len.cint)

proc setWmHints*(a: Window, flags: clong, icon: Pixmap = 0.Pixmap, iconMask: Pixmap = 0.Pixmap) =
  var hints = XWmHints(flags: flags, iconPixmap: icon, iconMask: iconMask)
  discard display.XSetWMHints(a, hints.addr)

proc `input=`*(a: Window, v: openarray[int]) =
  var inputs = 0
  for inp in v: inputs = inputs or inp
  discard display.XSelectInput(a, inputs)


proc property*(a: Window, name: Atom, t: typedesc = typedesc[byte]): tuple[data: seq[t], kind: Atom] =
  var
    format: cint
    n: culong
    remainingBytes: culong
    data: ptr UncheckedArray[t]
  if display.XGetWindowProperty(
    a, name, 0, clong.high, 0, AnyPropertyType,
    result.kind.addr, format.addr, n.addr, remainingBytes.addr, cast[PPCUchar](data.addr)
  ) != Success:
    raise X11Defect.newException("failed to get property " & $name)
  result.data.setLen n.int
  for i in 0..<n.int: result.data[i] = data[i]
  discard XFree data

proc property*(a: Window, name: Atom, t: typedesc[string]): tuple[data: string, kind: Atom] =
  let a = a.property(name, char)
  result.kind = a.kind
  result.data = $cast[cstring]((a.data & '\0').dataAddr)


proc netWmState*(a: Window): seq[Atom] =
  let v = a.property(atom"_NET_WM_STATE", Atom)
  if v.kind == XaAtom: v.data else: @[]

proc `netWmState=`*(a: Window, v: openarray[Atom]) =
  discard display.XChangeProperty(a, atom"_NET_WM_STATE", XaAtom, 32, PropModeReplace, cast[PCUchar](v.dataAddr), v.len.cint)

proc `netWmName=`*(a: Window, v: string) =
  discard display.XChangeProperty(a, atom"_NET_WM_NAME", atom"UTF8_STRING", 8, PropModeReplace, cast[PCUchar](v.dataAddr), v.len.cint)
proc `netWmIconName=`*(a: Window, v: string) =
  discard display.XChangeProperty(a, atom"_NET_WM_ICON_NAME", atom"UTF8_STRING", 8, PropModeReplace, cast[PCUchar](v.dataAddr), v.len.cint)


proc `pos=`*(a: Window, v: tuple[x, y: int]) =
  discard display.XMoveWindow(a, v.x.cint, v.y.cint)
proc `size=`*(a: Window, size: tuple[x, y: int]) =
  discard display.XResizeWindow(a, size.x.cuint, size.y.cuint)


proc cursorFromFont*(a: cuint): Cursor =
  Cursor display.XCreateFontCursor(a)

proc `cursor=`*(a: Window, c: Cursor) =
  discard display.XDefineCursor(a, c.toXID)


proc rootWindow*(screen: cint): Window = Window display.RootWindow(screen)
proc defaultRootWindow*(): Window = Window display.DefaultRootWindow
proc defaultDepth*(screen: cint): cuint = cuint display.DefaultDepth(screen)
proc defaultVisual*(screen: cint): PVisual = display.DefaultVisual(screen)
proc blackPixel*(screen: cint): culong = display.BlackPixel(screen)
proc whitePixel*(screen: cint): culong = display.WhitePixel(screen)


proc newPixmap*(w, h: int, window: Window, depth: cuint): Pixmap =
  Pixmap display.XCreatePixmap(window, w.cuint, h.cuint, depth)


proc asXImage*(data: openarray[ColorRGBX], w, h: int): XImage = XImage(
  width: cint w,
  height: cint h,
  depth: 24,
  bitsPerPixel: 32,
  format: ZPixmap,
  data: cast[cstring](cast[int](data.dataAddr) - 1),
  byteOrder: MSBFirst,
  bitmapUnit: display.BitmapUnit,
  bitmapBitOrder: MSBFirst,
  bitmapPad: 32,
  bytesPerLine: cint w * ColorRGBX.sizeof
)

proc asXImageTransparent*(data: seq[tuple[b, g, r, a: uint8]], w, h: int): XImage = XImage(
  width: cint w,
  height: cint h,
  depth: 32,
  bitsPerPixel: 32,
  format: ZPixmap,
  data: cast[cstring](data.dataAddr),
  byteOrder: LSBFirst,
  bitmapUnit: display.BitmapUnit,
  bitmapBitOrder: LSBFirst,
  bitmapPad: 32,
  bytesPerLine: cint w * ColorRGBX.sizeof
)

proc asXImage*(data: openarray[ColorBgrx], w, h: int, transparent = false): XImage = XImage(
  width: cint w,
  height: cint h,
  depth: if transparent: 32 else: 24,
  bitsPerPixel: 32,
  format: ZPixmap,
  data: cast[cstring](data.dataAddr),
  byteOrder: LSBFirst,
  bitmapUnit: display.BitmapUnit,
  bitmapBitOrder: LSBFirst,
  bitmapPad: 32,
  bytesPerLine: cint w * ColorBgrx.sizeof
)


proc newGC*(a: Drawable, mask: culong = GcForeground or GcBackground): GraphicsContext =
  if a == 0: raise X11ValueError.newException("nil target")
  result.target = a
  result.gc = display.XCreateGC(a, mask, result.gcv.addr)
  if result.gc == nil: raise X11Defect.newException("failed to create gc")

proc put*(a: GraphicsContext, image: PXImage, w, h: int, srcPos: tuple[x, y: int] = (0, 0), destPos: tuple[x, y: int] = (0, 0)) =
  discard display.XPutImage(a.target, a.gc, image, cint srcPos.x, cint srcPos.y, cint destPos.x, cint destPos.y, cuint w, cuint h)
proc put*(a: GraphicsContext, image: PXImage, srcPos: tuple[x, y: int] = (0, 0), destPos: tuple[x, y: int] = (0, 0)) =
  a.put(image, image.width, image.height, srcPos, destPos)


proc send*(a: Window, e: XEvent, mask: clong = NoEventMask, propagate: bool = false) =
  discard display.XSendEvent(a, propagate.XBool, mask, e.unsafeAddr)

proc newClientMessage*[T](window: Window, messageKind: Atom, data: openarray[T], serial: int = 0, sendEvent: bool = false): XEvent =
  result.theType = ClientMessage
  result.xclient.messageType = messageKind
  if data.len * T.sizeof > XClientMessageData.sizeof:
    raise X11ValueError.newException(&"to much data in client message (>{XClientMessageData.sizeof} bytes)")
  copyMem(result.xclient.data.addr, data.dataAddr, data.len * T.sizeof)
  result.xclient.format = case T.sizeof
    of 1: 8
    of 2: 16
    of 4: 32
    of 8: 32 #?
    else: 8
  result.xclient.window = window
  result.xclient.display = display
  result.xclient.serial = serial.culong
  result.xclient.sendEvent = sendEvent.XBool


var clipboardProcessEvents*: proc()


proc setProperty*(
  window: Window, property: Atom, kind: Atom, format: cint, data: string
) =
  discard display.XChangeProperty(
    window,
    property,
    kind,
    format,
    0,
    data,
    data.len.cint div (format div 8)
  )

proc delProperty*(window: Window, property: Atom) =
  discard display.XDeleteProperty(window, property)

proc asSeq*(s: string, T: type = uint8): seq[T] =
  if s.len == 0:
    return
  result = newSeq[T]((s.len + T.sizeof - 1) div T.sizeof)
  copyMem(result[0].addr, s[0].unsafeaddr, s.len)

proc asString*[T](x: seq[T]|HashSet[T]): string =
  result = newStringOfCap(x.len * T.sizeof)
  for v in x:
    for v in cast[array[T.sizeof, char]](v):
      result.add v

proc invert*[T](x: var set[T], v: T) =
  if x.contains v:
    x.excl v
  else:
    x.incl v

proc wmState*(window: Window): HashSet[Atom] =
  window.property(atom"_NET_WM_STATE", Atom).data.toHashSet

proc wmStateSend*(window: Window, op: int, atom: Atom) =
  # op: 2 - switch, 1 - set true, 0 - set false
  display.DefaultRootWindow.Window.send(
    window.newClientMessage(atom"_NET_WM_STATE", [Atom op, atom]),
    SubstructureNotifyMask or SubstructureRedirectMask
  )


{.push, cdecl, dynlib: libXExt, importc.}

proc XSyncQueryExtension*(d: ptr Display, vEv, vEr: ptr cint): bool
proc XSyncInitialize*(d: ptr Display, verMaj, verMin: ptr cint)

proc XSyncCreateCounter*(d: ptr Display, v: XSyncValue): XSyncCounter
proc XSyncDestroyCounter*(d: ptr Display, c: XSyncCounter)

proc XSyncSetCounter*(d: ptr Display, c: XSyncCounter; v: XSyncValue)

{.pop.}
