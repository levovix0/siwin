import std/[os, tables, posix, times, monotimes]
import ../../[siwindefs]
import ../any/[window, timeutils]
import x11/[xlib, x]

type
  WmForFramelessKind* {.pure.} = enum
    unsupported
    motiv
    kwm
    other
  
  SiwinGlobalsX11* = ref SiwinGlobalsX11Obj
  SiwinGlobalsX11Obj* = object of SiwinGlobals
    display*: ptr Display
    windows*: Table[uint, window.Window]
    wake*: ptr X11WakeFd
    wmForFramelessKind*: WmForFramelessKind
    atoms*: tuple[
      frameless, wmDeleteWindow, utf8String, netWmName, netWmIconName,
      netSupported, netWmState, netWmStateFullscreen, netWmStateMaximizedHorz,
      netWmStateMaximizedVert, netWmStateHidden, netWmMoveResize,
      netWmSyncRequest, netWmSyncRequestCounter, netFrameExtents,
      kdeNetWmBlurBehindRegion,
      clipboard, siwin_clipboardTargetProperty, targets, text, primary,
      xDndAware, xDndEnter, xDndTypeList, xDndSelection, xDndPosition, xDndLeave, xDndDrop, xDndFinished, xDndStatus, xDndActionCopy, xDndActionPrivate
      : Atom
    ]

  X11WakeFd = object
    readFd*, writeFd*: cint


proc `=destroy`(x: SiwinGlobalsX11Obj) {.siwin_destructor.} =
  cast[SiwinGlobals](x.addr).shutdownEventLoopWakeState()
  if x.display != nil:
    discard XCloseDisplay(x.display)

proc signalX11Wake(data: pointer) {.gcsafe, raises: [].} =
  let wake = cast[ptr X11WakeFd](data)
  if wake != nil and wake.writeFd >= 0:
    var byte = '\x01'
    {.cast(gcsafe).}:
      while write(wake.writeFd, byte.addr, 1) < 0 and errno == EINTR:
        discard

proc closeX11Wake(data: pointer) {.gcsafe, raises: [].} =
  let wake = cast[ptr X11WakeFd](data)
  if wake != nil:
    if wake.readFd >= 0: discard close(wake.readFd)
    if wake.writeFd >= 0: discard close(wake.writeFd)
    dealloc(wake)

proc configureWakeFd(fd: cint) =
  let flags = fcntl(fd, F_GETFL)
  if flags < 0 or fcntl(fd, F_SETFL, flags or O_NONBLOCK) < 0:
    raiseOSError(osLastError())
  let fdFlags = fcntl(fd, F_GETFD)
  if fdFlags < 0 or fcntl(fd, F_SETFD, fdFlags or FD_CLOEXEC) < 0:
    raiseOSError(osLastError())

proc drainX11Wake*(globals: SiwinGlobalsX11): bool =
  if globals.wake == nil: return false
  var buffer: array[64, char]
  while true:
    let count = read(globals.wake.readFd, buffer[0].addr, buffer.len)
    if count > 0:
      result = true
    elif count < 0 and errno == EINTR:
      continue
    else:
      break
  if result: globals.consumeEventLoopWake()

proc newX11Globals*: SiwinGlobalsX11 {.raises: [OsError].} =
  new result
  result.display = XOpenDisplay(getEnv("DISPLAY").cstring)
  if result.display == nil: raise OsError.newException("failed to open X11 display, make sure the DISPLAY environment variable is set correctly")
  result.wake = cast[ptr X11WakeFd](alloc0(sizeof(X11WakeFd)))
  var wakeFds: array[2, cint]
  if pipe(wakeFds) != 0:
    dealloc(result.wake)
    raiseOSError(osLastError())
  result.wake.readFd = wakeFds[0]
  result.wake.writeFd = wakeFds[1]
  try:
    configureWakeFd(result.wake.readFd)
    configureWakeFd(result.wake.writeFd)
  except OSError:
    closeX11Wake(result.wake)
    result.wake = nil
    raise
  result.installEventLoopWakeProc(signalX11Wake, result.wake, closeX11Wake)
  
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
  result.atoms.netSupported = result.display.XInternAtom("_NET_SUPPORTED", 0)
  result.atoms.netWmState = result.display.XInternAtom("_NET_WM_STATE", 0)
  result.atoms.netWmStateFullscreen = result.display.XInternAtom("_NET_WM_STATE_FULLSCREEN", 0)
  result.atoms.netWmStateMaximizedHorz = result.display.XInternAtom("_NET_WM_STATE_MAXIMIZED_HORZ", 0)
  result.atoms.netWmStateMaximizedVert = result.display.XInternAtom("_NET_WM_STATE_MAXIMIZED_VERT", 0)
  result.atoms.netWmStateHidden = result.display.XInternAtom("_NET_WM_STATE_HIDDEN", 0)
  result.atoms.netWmMoveResize = result.display.XInternAtom("_NET_WM_MOVERESIZE", 0)
  result.atoms.netWmSyncRequest = result.display.XInternAtom("_NET_WM_SYNC_REQUEST", 0)
  result.atoms.netWmSyncRequestCounter = result.display.XInternAtom("_NET_WM_SYNC_REQUEST_COUNTER", 0)
  result.atoms.netFrameExtents = result.display.XInternAtom("_NET_FRAME_EXTENTS", 0)
  result.atoms.kdeNetWmBlurBehindRegion = result.display.XInternAtom(
    "_KDE_NET_WM_BLUR_BEHIND_REGION", 0
  )
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


method pollEventsImpl(globals: SiwinGlobalsX11): bool =
  proc dispatchWindowEvent(
    window: window.Window,
    ev, nextEvent: XEvent,
    hasNextEvent: bool,
  ) {.importc: "siwin_x11_dispatch_window_event".}
    # this needs to be forward-declared, because with --experimental:vtables methods can not be declared outside the module the type was declared in


  result = globals.drainX11Wake()
  while globals.display.XPending() > 0:
    var events = newSeqOfCap[XEvent](globals.display.XPending().int)
    while globals.display.XPending() > 0:
      var event: XEvent
      discard globals.display.XNextEvent(event.addr)
      events.add(event)

    var
      nextForWindow = initTable[uint, int]()
      nextEventIndices = newSeq[int](events.len)
    for i in countdown(events.high, 0):
      let windowId = events[i].xany.window.uint
      nextEventIndices[i] = nextForWindow.getOrDefault(windowId, -1)
      nextForWindow[windowId] = i

    for i, event in events:
      let window = globals.windows.getOrDefault(event.xany.window.uint)
      if window != nil and not window.closed:
        let nextIndex = nextEventIndices[i]
        window.dispatchWindowEvent(
          event,
          events[if nextIndex >= 0: nextIndex else: 0],
          nextIndex >= 0,
        )

    result = true
    discard XFlush(globals.display)


method waitEventsImpl(
  globals: SiwinGlobalsX11,
  timeout: Duration,
): EventWaitResult =
  if globals.pollEventsImpl():
    return eventActivity
  discard XFlush(globals.display)
  let started = getMonoTime()
  while true:
    var fds = [
      TPollfd(fd: globals.display.XConnectionNumber(), events: POLLIN),
      TPollfd(fd: globals.wake.readFd, events: POLLIN),
    ]
    let remaining =
      if timeout == Duration.high:
        Duration.high
      else:
        max(initDuration(), timeout - (getMonoTime() - started))
    let count = poll(
      fds[0].addr,
      fds.len.Tnfds,
      remaining.inTimeoutMilliseconds(
        infinite = -1.cint,
        maxFinite = cint.high,
      ),
    )
    if count == 0:
      return eventTimeout
    if count < 0:
      if errno == EINTR:
        if timeout != Duration.high and getMonoTime() - started >= timeout:
          return eventTimeout
        continue
      raiseOSError(osLastError())

    if (fds[0].revents and (POLLERR or POLLHUP or POLLNVAL)) != 0:
      raise OSError.newException("X11 display connection closed while waiting")
    if (fds[1].revents and (POLLERR or POLLHUP or POLLNVAL)) != 0:
      raise OSError.newException("X11 event-loop wake pipe closed while waiting")
    if (fds[1].revents and POLLIN) != 0:
      discard globals.drainX11Wake()
    if (fds[0].revents and POLLIN) != 0:
      discard globals.pollEventsImpl()
    return eventActivity
