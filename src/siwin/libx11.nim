import os, strutils, strformat, tables, sequtils, sugar
import x11/[xlib, xutil, xatom, xshm, cursorfont, keysym]
import x11/x except Window, Pixmap, Cursor
export xlib, xutil, xatom, xshm, cursorfont, keysym
export x except Window, Pixmap, Cursor
import utils
import chroma

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
  
  WmHints* = object
    wmh*: PXWmHints

  AtomKind* {.pure.} = enum
    WM_DELETE_WINDOW
    WM_PROTOCOLS
    UTF8_STRING
    CLIPBOARD
    TARGETS
    TEXT
    INCR
    NET_WM_STATE_FULLSCREEN
    NET_WM_STATE
    NET_WM_NAME
    NET_WM_ICON_NAME
    SIWIN_CLIPBOARD_TARGET_PROPERTY



var display*: PDisplay
display = XOpenDisplay(getEnv("DISPLAY").cstring)
if display == nil: raise X11Defect.newException("failed to open X11 display, make sure the DISPLAY environment variable is set correctly")

type LibX11GarbageCollector = object
proc `=destroy`(a: var LibX11GarbageCollector) =
  discard XCloseDisplay display
var libx11gc {.used.}: LibX11GarbageCollector



var atoms: Table[AtomKind, Atom]

proc internAtom*(a: string, onlyIfExist: bool = false): Atom =
  display.XInternAtom(a, onlyIfExist.XBool)

proc atomImpl(a: AtomKind, onlyIfExist: bool): Atom =
  let s = if ($a).startsWith("NET_"): &"_{$a}" else: $a
  internAtom(s, onlyIfExist)

proc atom*(a: AtomKind, onlyIfExist: bool): Atom =
  if atoms.hasKey(a): return atoms[a]
  result = atomImpl(a, onlyIfExist)
  atoms[a] = result
proc atom*(a: AtomKind): Atom = atom(a, false)



converter toXID*(a: Window): XID = a.XID
converter toXID*(a: Pixmap): XID = a.XID
converter toXID*(a: Cursor): XID = a.XID
converter toDrawable*(a: Window|Pixmap|Cursor): Drawable = a.toXID
converter toPXID*(a: ptr Window): PXID = cast[PXID](a)
converter toPXID*(a: ptr Pixmap): PXID = cast[PXID](a)
converter toPXID*(a: ptr Cursor): PXID = cast[PXID](a)
converter toPDrawable*(a: Window|Pixmap|Cursor): PDrawable = a.toPXID
converter toPXWmHints*(a: WmHints): PXWmHints = a.wmh


proc destroy*(a: Window)    = discard display.XDestroyWindow(a)
proc destroy*(a: Pixmap)    = discard display.XFreePixmap(a)
proc destroy*(a: Cursor)    = discard display.XFreeCursor(a)
proc destroy*(a: GC)        = discard display.XFreeGC(a)
proc destroy*(a: PXImage)   = discard XDestroyImage(a)
proc destroy*(a: XIC)       = XDestroyIC(a)
proc destroy*(a: PXWmHints) = discard XFree(a)
proc close*(a: XIM)         = discard XCloseIM(a)


proc `=destroy`(a: var GraphicsContext) =
  if a.gc != nil: destroy a.gc
proc `=destroy`(a: var WmHints) =
  destroy a.wmh


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
  result = (root, x.int, y.int, w.int, h.int, borderW.int, depth.int)
proc size*(a: tuple[root: Window; x, y: int; w, h: int; borderW: int, depth: int]): tuple[x, y: int] = (a.w, a.h)
proc position*(a: tuple[root: Window; x, y: int; w, h: int; borderW: int, depth: int]): tuple[x, y: int] = (a.x, a.y)

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
proc position*(a: tuple[x, y: int; root, child: Window; winX, winY: int; mask: uint; exists: bool]): tuple[x, y: int] = (a.x, a.y)
proc windowPosition*(a: tuple[x, y: int; root, child: Window; winX, winY: int; mask: uint; exists: bool]): tuple[x, y: int] = (a.winX, a.winY)

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
proc `wmProtocols=`*(a: Window, v: openarray[AtomKind]) =
  a.wmProtocols = v.map(atom)

proc newWmHints*(flags: clong = 0, icon: Pixmap = 0.Pixmap, iconMask: Pixmap = 0.Pixmap): WmHints =
  result.wmh = XAllocWMHints()
  result.wmh.flags = flags
  result.wmh.iconPixmap = icon
  result.wmh.iconMask = iconMask
proc newWmHints*(icon: Pixmap, iconMask: Pixmap): WmHints =
  newWmHints(IconPixmapHint or IconMaskHint, icon=icon, iconMask=iconMask)

proc `wmHints=`*(a: Window, hints: PXWmHints) =
  discard display.XSetWMHints(a, hints)

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

proc property*(a: Window, name: AtomKind, t: typedesc = typedesc[byte]): auto =
  a.property(atom name, t)


proc netWmState*(a: Window): seq[Atom] =
  #TODO: вылетает на linux/manjaro/gnome/wayland
  let v = a.property(NetWmState, Atom)
  if v.kind != XaAtom: raise X11Defect.newException("failed to get netWmState (got incorrect property kind)")
  result = v.data

proc `netWmState=`*(a: Window, v: openarray[Atom]) =
  discard display.XChangeProperty(a, atom NetWmState, XaAtom, 32, PropModeReplace, cast[PCUchar](v.dataAddr), v.len.cint)
proc `netWmState=`*(a: Window, v: openarray[AtomKind]) =
  a.netWmState = v.map(atom)

proc `netWmName=`*(a: Window, v: string) =
  discard display.XChangeProperty(a, atom NetWmName, atom Utf8String, 8, PropModeReplace, cast[PCUchar](v.dataAddr), v.len.cint)
proc `netWmIconName=`*(a: Window, v: string) =
  discard display.XChangeProperty(a, atom NetWmIconName, atom Utf8String, 8, PropModeReplace, cast[PCUchar](v.dataAddr), v.len.cint)


proc `position=`*(a: Window, position: tuple[x, y: int]) =
  discard display.XMoveWindow(a, position.x.cint, position.y.cint)
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


proc asXImage*(data: seq[ColorRGBX], w, h: int): XImage = XImage(
  width: cint w,
  height: cint h,
  depth: 24,
  bitsPerPixel: 32,
  xoffset: 0,
  format: ZPixmap,
  data: cast[cstring](cast[int](data.dataAddr) - 1),
  byteOrder: MSBFirst,
  bitmapUnit: display.BitmapUnit,
  bitmapBitOrder: MSBFirst,
  bitmapPad: 32,
  bytesPerLine: cint w * ColorRGBX.sizeof
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
proc newClientMessage*[T](window: Window, messageKind: AtomKind, data: openarray[T], serial: int = 0, sendEvent: bool = false): XEvent =
  newClientMessage(window, atom messageKind, data, serial, sendEvent)



var clipboardProcessEvents*: proc() = proc() = discard
