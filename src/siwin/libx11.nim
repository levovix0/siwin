import os, strutils, strformat, tables, sequtils, sugar
import x11/[xlib, xutil, xatom, xshm, cursorfont, keysym]
import x11/x except Window, Pixmap, Cursor
export xlib, xutil, xatom, xshm, cursorfont, keysym
export x except Window, Pixmap, Cursor
import utils

type
  X11ValueError* = object of CatchableError
  X11Defect* = object of Defect

  Window* = distinct x.Window
  Pixmap* = distinct x.Pixmap
  Cursor* = distinct x.Cursor

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

proc atom*(a: AtomKind, onlyIfExist: bool = false): Atom =
  if atoms.hasKey(a): return atoms[a]
  result = atomImpl(a, onlyIfExist)
  atoms[a] = result



converter toXID*(a: Window|Pixmap|Cursor): XID = a.XID
converter toPXID*(a: ptr Window|Pixmap|Cursor): PXID = cast[PXID](a)



proc cmalloc(size: culong): pointer {.importc: "malloc".}
proc malloc*[T](): ptr T = cast[ptr T](cmalloc(culong T.sizeof))
proc malloc*[T](len: int): ArrayPtr[T] = cast[ArrayPtr[T]](cmalloc(culong T.sizeof * len))



proc syncX*() = discard display.XSync(0)

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

proc attributes*(a: Window): XWindowAttributes =
  discard display.XGetWindowAttributes(a, result.addr)
proc root*(a: Window): Window =
  Window a.attributes.root

proc map*(a: Window) =
  discard display.XMapWindow(a)

proc wmProtocols*(a: Window): seq[Atom] =
  var
    protocols: ArrayPtr[Atom]
    n: cint
  discard display.XGetWMProtocols(a, cast[ptr ptr Atom](protocols.addr), n.addr)
  protocols.toSeq(n.int)

proc `wmProtocols=`*(a: Window, v: openarray[Atom]) =
  discard display.XSetWMProtocols(a, v.dataAddr, v.len.cint)
proc `wmProtocols=`*(a: Window, v: openarray[AtomKind]) =
  a.wmProtocols = v.map(a => atom a)

proc destroy*(a: Window) =
  discard display.XDestroyWindow(a)
proc destroy*(a: Pixmap) =
  discard display.XFreePixmap(a)
proc destroy*(a: Cursor) =
  discard display.XFreeCursor(a)
proc destroy*(a: GC) =
  discard display.XFreeGC(a)
proc destroy*(a: PXImage) =
  discard XDestroyImage(a)
proc destroy*(a: XIC) =
  XDestroyIC(a)
proc close*(a: XIM) =
  discard XCloseIM(a)

proc `input=`*(a: Window, v: openarray[int]) =
  var inputs = 0
  for inp in v: inputs = inputs or inp
  discard display.XSelectInput(a, inputs)

proc newSimpleWindow*(parent: Window, x, y: int, w, h: int, borderW: int, border: culong, background: culong): Window =
  result = Window display.XCreateSimpleWindow(parent, x.cint, y.cint, w.cuint, h.cuint, borderW.cuint, border, background)
  doassert result != 0

proc blackPixel*(a: cint): culong =
  display.BlackPixel(a)
proc whitePixel*(a: cint): culong =
  display.WhitePixel(a)

proc property*(a: Window, name: Atom): tuple[data: seq[byte], kind: Atom] =
  var
    format: cint
    n: culong
    remainingBytes: culong
    data: ArrayPtr[byte]
  if display.XGetWindowProperty(
    a, name, 0, clong.high, 0, AnyPropertyType,
    result.kind.addr, format.addr, n.addr, remainingBytes.addr, cast[PPCUchar](data.addr)
  ) != Success:
    raise X11Defect.newException("failed to get property " & $name)
  result.data = data.toSeq(n.int)
  discard XFree cast[pointer](data)

proc `netWmState=`*(a: Window, v: openarray[Atom]) =
  discard display.XChangeProperty(a, atom NetWmState, XaAtom, 32, PropModeReplace, cast[PCUchar](v.dataAddr), v.len.cint)
proc `netWmState=`*(a: Window, v: openarray[AtomKind]) =
  a.netWmState = v.map(a => atom a)

proc `netWmName=`*(a: Window, v: string) =
  discard display.XChangeProperty(a, atom NetWmName, atom Utf8String, 8, PropModeReplace, cast[PCUchar](v.dataAddr), v.len.cint)
proc `netWmIconName=`*(a: Window, v: string) =
  discard display.XChangeProperty(a, atom NetWmIconName, atom Utf8String, 8, PropModeReplace, cast[PCUchar](v.dataAddr), v.len.cint)

proc send*(a: Window, e: XEvent, mask: clong = NoEventMask) =
  discard display.XSendEvent(a, 0, mask, e.unsafeAddr)


proc newClientMessage*[T](window: Window, messageKind: Atom, data: openarray[T], serial: int = 0, sendEvent: bool = false): XEvent =
  result.theType = ClientMessage
  result.xclient.messageType = messageKind
  if data.len * T.sizeof > 20:
    raise X11ValueError.newException("to much data in client message (>20 bytes)")
  copyMem(result.xclient.data.addr, data.dataAddr, data.len * T.sizeof)
  result.xclient.format = case T.sizeof
    of 1: 8
    of 2: 16
    of 4: 32
    else: 8
  result.xclient.window = window
  result.xclient.display = display
  result.xclient.serial = serial.culong
  result.xclient.sendEvent = sendEvent.XBool
proc newClientMessage*[T](window: Window, messageKind: AtomKind, data: openarray[T], serial: int = 0, sendEvent: bool = false): XEvent =
  newClientMessage(window, atom messageKind, data, serial, sendEvent)

proc `position=`*(a: Window, position: tuple[x, y: int]) =
  discard display.XMoveWindow(a, position.x.cint, position.y.cint)
proc `size=`*(a: Window, size: tuple[x, y: int]) =
  discard display.XResizeWindow(a, size.x.cuint, size.y.cuint)

proc cursorFromFont*(a: cuint): Cursor =
  Cursor display.XCreateFontCursor(a)

proc `cursor=`*(a: Window, c: Cursor) =
  discard display.XDefineCursor(a, c.toXID)



var clipboardProcessEvents*: proc() = proc() = discard
