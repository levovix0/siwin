import os, tables
import ../../[siwindefs]
import ../any/[window]
import x11/[xlib, x]

type
  WmForFramelessKind* {.pure.} = enum
    unsupported
    motiv
    kwm
    other
  
  SiwinGlobalsX11* = ptr SiwinGlobalsX11Obj
  SiwinGlobalsX11Obj* = object of SiwinGlobals
    display*: ptr Display
    wmForFramelessKind*: WmForFramelessKind
    atoms*: tuple[
      frameless, wmDeleteWindow, utf8String, netWmName, netWmIconName,
      netWmState, netWmStateFullscreen, netWmStateMaximizedHorz, netWmStateMaximizedVert, netWmStateHidden, netWmMoveResize,
      netWmSyncRequest, netWmSyncRequestCounter,
      clipboard, siwin_clipboardTargetProperty, targets, text, primary,
      xDndAware, xDndEnter, xDndTypeList, xDndSelection, xDndPosition, xDndLeave, xDndDrop, xDndFinished, xDndStatus, xDndActionCopy, xDndActionPrivate
      : Atom
    ]


proc `=destroy`*(x: SiwinGlobalsX11Obj) {.siwin_destructor.} =
  if x.display != nil:
    discard XCloseDisplay(x.display)


proc newX11Globals*: SiwinGlobalsX11 {.raises: [OsError].} =
  result = create(SiwinGlobalsX11Obj)
  result.platform = Platform.x11

  result.display = XOpenDisplay(getEnv("DISPLAY").cstring)
  if result.display == nil: raise OsError.newException("failed to open X11 display, make sure the DISPLAY environment variable is set correctly")
  
  result.wmForFramelessKind =
    if (result.atoms.frameless = result.display.XInternAtom("_MOTIF_WM_HINTS", 1); result.atoms.frameless != 0):
      WmForFramelessKind.motiv
    elif (result.atoms.frameless = result.display.XInternAtom("KWM_WIN_DECORATION", 1); result.atoms.frameless != 0):
      WmForFramelessKind.kwm
    elif (result.atoms.frameless = result.display.XInternAtom("_WIN_HINTS", 1); result.atoms.frameless != 0):
      WmForFramelessKind.other
    else:
      WmForFramelessKind.unsupported

  result.atoms.wmDeleteWindow = result.display.XInternAtom("WM_DELETE_WINDOW", 0)
  result.atoms.utf8String = result.display.XInternAtom("UTF8_STRING", 0)
  result.atoms.netWmName = result.display.XInternAtom("_NET_WM_NAME", 0)
  result.atoms.netWmIconName = result.display.XInternAtom("_NET_WM_ICON_NAME", 0)
  result.atoms.netWmState = result.display.XInternAtom("_NET_WM_STATE", 0)
  result.atoms.netWmStateFullscreen = result.display.XInternAtom("_NET_WM_STATE_FULLSCREEN", 0)
  result.atoms.netWmStateMaximizedHorz = result.display.XInternAtom("_NET_WM_STATE_MAXIMIZED_HORZ", 0)
  result.atoms.netWmStateMaximizedVert = result.display.XInternAtom("_NET_WM_STATE_MAXIMIZED_VERT", 0)
  result.atoms.netWmStateHidden = result.display.XInternAtom("_NET_WM_STATE_HIDDEN", 0)
  result.atoms.netWmMoveResize = result.display.XInternAtom("_NET_WM_MOVERESIZE", 0)
  result.atoms.netWmSyncRequest = result.display.XInternAtom("_NET_WM_SYNC_REQUEST", 0)
  result.atoms.netWmSyncRequestCounter = result.display.XInternAtom("_NET_WM_SYNC_REQUEST_COUNTER", 0)
  result.atoms.clipboard = result.display.XInternAtom("CLIPBOARD", 0)
  result.atoms.siwin_clipboardTargetProperty = result.display.XInternAtom("siwin_clipboardTargetProperty", 0)
  result.atoms.targets = result.display.XInternAtom("TARGETS", 0)
  result.atoms.text = result.display.XInternAtom("TEXT", 0)
  result.atoms.primary = result.display.XInternAtom("PRIMARY", 0)
  result.atoms.xDndAware = result.display.XInternAtom("XdndAware", 0)
  result.atoms.xDndEnter = result.display.XInternAtom("XdndEnter", 0)
  result.atoms.xDndTypeList = result.display.XInternAtom("XdndTypeList", 0)
  result.atoms.xDndSelection = result.display.XInternAtom("XdndSelection", 0)
  result.atoms.xDndPosition = result.display.XInternAtom("XdndPosition", 0)
  result.atoms.xDndLeave = result.display.XInternAtom("XdndLeave", 0)
  result.atoms.xDndDrop = result.display.XInternAtom("XdndDrop", 0)
  result.atoms.xDndFinished = result.display.XInternAtom("XdndFinished", 0)
  result.atoms.xDndStatus = result.display.XInternAtom("XdndStatus", 0)
  result.atoms.xDndActionCopy = result.display.XInternAtom("XdndActionCopy", 0)
  result.atoms.xDndActionPrivate = result.display.XInternAtom("XdndActionPrivate", 0)


proc property*(globals: SiwinGlobalsX11, window: x.Window, name: Atom, t: typedesc = typedesc[byte]): tuple[kind: Atom, data: seq[t]] =
  var
    format: cint
    n: culong
    remainingBytes: culong
    data: ptr UncheckedArray[t]

  discard globals.display.XGetWindowProperty(
    window, name, 0, clong.high, 0, AnyPropertyType,
    result.kind.addr, format.addr, n.addr, remainingBytes.addr, cast[PPCUchar](data.addr)
  )

  if n != 0:
    result.data.setLen n.int
    copyMem(result.data[0].addr, data, n.int * t.sizeof)
  
  discard XFree data

proc property*(globals: SiwinGlobalsX11, window: x.Window, name: Atom, t: typedesc[string]): tuple[kind: Atom, data: string] =
  let a = globals.property(window, name, char)
  result.kind = a.kind
  result.data = cast[string](a.data)
