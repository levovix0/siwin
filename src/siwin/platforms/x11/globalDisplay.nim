import os, tables
import x11/[xlib, x]

type WmForFramelessKind* {.pure.} = enum
  unsupported
  motiv
  kwm
  other

var display*: ptr Display
var wmForFramelessKind*: WmForFramelessKind
var atoms*: tuple[
  frameless, wmDeleteWindow, utf8String, netWmName, netWmIconName,
  netWmState, netWmStateFullscreen, netWmStateMaximizedHorz, netWmStateMaximizedVert, netWmStateHidden, netWmMoveResize,
  netWmSyncRequest, netWmSyncRequestCounter,
  clipboard, siwin_clipboardTargetProperty, targets, text,
  xDndAware, xDndEnter, xDndTypeList, xDndSelection
  : Atom
]

var clipboardProcessEvents*: Table[int, proc()]


proc init* {.raises: [OsError].} =
  if display != nil: return
  display = XOpenDisplay(getEnv("DISPLAY").cstring)
  if display == nil: raise OsError.newException("failed to open X11 display, make sure the DISPLAY environment variable is set correctly")
  
  wmForFramelessKind =
    if (atoms.frameless = display.XInternAtom("_MOTIF_WM_HINTS", 1); atoms.frameless != 0):
      WmForFramelessKind.motiv
    elif (atoms.frameless = display.XInternAtom("KWM_WIN_DECORATION", 1); atoms.frameless != 0):
      WmForFramelessKind.kwm
    elif (atoms.frameless = display.XInternAtom("_WIN_HINTS", 1); atoms.frameless != 0):
      WmForFramelessKind.other
    else:
      WmForFramelessKind.unsupported

  atoms.wmDeleteWindow = display.XInternAtom("WM_DELETE_WINDOW", 0)
  atoms.utf8String = display.XInternAtom("UTF8_STRING", 0)
  atoms.netWmName = display.XInternAtom("_NET_WM_NAME", 0)
  atoms.netWmIconName = display.XInternAtom("_NET_WM_ICON_NAME", 0)
  atoms.netWmState = display.XInternAtom("_NET_WM_STATE", 0)
  atoms.netWmStateFullscreen = display.XInternAtom("_NET_WM_STATE_FULLSCREEN", 0)
  atoms.netWmStateMaximizedHorz = display.XInternAtom("_NET_WM_STATE_MAXIMIZED_HORZ", 0)
  atoms.netWmStateMaximizedVert = display.XInternAtom("_NET_WM_STATE_MAXIMIZED_VERT", 0)
  atoms.netWmStateHidden = display.XInternAtom("_NET_WM_STATE_HIDDEN", 0)
  atoms.netWmMoveResize = display.XInternAtom("_NET_WM_MOVERESIZE", 0)
  atoms.netWmSyncRequest = display.XInternAtom("_NET_WM_SYNC_REQUEST", 0)
  atoms.netWmSyncRequestCounter = display.XInternAtom("_NET_WM_SYNC_REQUEST_COUNTER", 0)
  atoms.clipboard = display.XInternAtom("CLIPBOARD", 0)
  atoms.siwin_clipboardTargetProperty = display.XInternAtom("siwin_clipboardTargetProperty", 0)
  atoms.targets = display.XInternAtom("TARGETS", 0)
  atoms.text = display.XInternAtom("TEXT", 0)
  atoms.xDndAware = display.XInternAtom("XdndAware", 0)
  atoms.xDndEnter = display.XInternAtom("XdndEnter", 0)
  atoms.xDndTypeList = display.XInternAtom("XdndTypeList", 0)
  atoms.xDndSelection = display.XInternAtom("XdndSelection", 0)

proc uninit* =
  if display == nil: return
  discard XCloseDisplay display


proc property*(window: x.Window, name: Atom, t: typedesc = typedesc[byte]): tuple[kind: Atom, data: seq[t]] =
  var
    format: cint
    n: culong
    remainingBytes: culong
    data: ptr UncheckedArray[t]

  discard display.XGetWindowProperty(
    window, name, 0, clong.high, 0, AnyPropertyType,
    result.kind.addr, format.addr, n.addr, remainingBytes.addr, cast[PPCUchar](data.addr)
  )

  if n != 0:
    result.data.setLen n.int
    copyMem(result.data[0].addr, data, n.int * t.sizeof)
  
  discard XFree data

proc property*(window: Window, name: Atom, t: typedesc[string]): tuple[kind: Atom, data: string] =
  let a = window.property(name, char)
  result.kind = a.kind
  result.data = cast[string](a.data)
