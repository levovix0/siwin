import std/[tables, os, posix, times, monotimes]
import ../../[siwindefs]
import ../any/[window, clipboards]
import ./[libwayland, protocol, bitfields, libdecor]

type
  WaylandExtensionNotFound* = object of CatchableError

  WaylandOutput* = object
    registryName*: uint32
    output*: Wl_output

  WaylandWakeFd = object
    readFd, writeFd: cint

  SiwinGlobalsWayland* = ref SiwinGlobalsWaylandObj
  SiwinGlobalsWaylandObj* = object of SiwinGlobals
    seatEventsInitialized*: bool
    seatCapabilitiesChanged*: proc(globals: SiwinGlobalsWayland)
    dataDeviceManagerEventsInitialized*: bool

    display*: WlDisplay
    registry: WlRegistry

    registryCallbacks*: Table[string, proc(registry: Wl_registry, name: uint32, version: uint32)]

    interfaces*: WaylandInterfaces
    
    compositor*: WlCompositor
    shm*: WlShm
    xdgWmBase*: XdgWmBase
    seat*: WlSeat
    dataDeviceManager*: WlDataDeviceManager
    viewporter*: Wp_viewporter
    fractionalScaleManager*: Wp_fractional_scale_manager_v1
    xdgToplevelIconManager*: Xdg_toplevel_icon_manager_v1
    outputs*: seq[WaylandOutput]

    serverDecorationManager*: Zxdg_decoration_manager_v1
    plasmaShell*: Org_kde_plasma_shell
    blurManager*: Org_kde_kwin_blur_manager
    layerShell*: Zwlr_layer_shell_v1
    idleInhibitManager*: Zwp_idle_inhibit_manager_v1
    cursorShapeManager*: Wp_cursor_shape_manager_v1
    
    shmFormats*: seq[`WlShm / Format`]
    seatCapabilities*: Bitfield[`WlSeat / Capability`]

    seat_pointer*: Wl_pointer
    seat_keyboard*: Wl_keyboard
    seat_touch*: Wl_touch

    data_device*: Wl_data_device
    current_selection_data_source*: Wl_data_source
    unindentified_data_offer*: Wl_data_offer
    unindentified_data_offer_mimeTypes*: seq[string]
    current_selection_data_offer*: Wl_data_offer

    current_dnd_data_offer*: Wl_data_offer
    current_dnd_data_offer_mimeTypes*: seq[string]
    current_dnd_surface_id*: uint32

    associatedWindows*: Table[uint32, Window]  # surface proxy id -> window
    associatedWindows_queueRemove_insteadOf_removingInstantly* = false
    associatedWindows_removeQueue*: seq[uint32]

    seat_pointer_currentWindow*: Window
    seat_pointer_lastAxisSource*: `Wl_pointer / Axis_source`
    seat_keyboard_currentWindow*: Window
    # seat_touch_currentWindow*: Window

    seat_keyboard_repeatSettings*: tuple[rate, delay: int32]

    tabletManager*: Zwp_tablet_manager_v2
    seat_tablet*: Zwp_tablet_seat_v2

    primaryClipboard*: Clipboard
    selectionClipboard*: Clipboard
    dragndropClipboard*: Clipboard

    lastSeatEventSerial*: uint32
    lastTouchId*: int

    libdecorCtx*: LibdecorContext
    libdecorIface*: LibdecorInterface
    wake: ptr WaylandWakeFd
    repeatWakeDeadline*: MonoTime
    repeatWakeWindow*: Window

proc `=destroy`*(globals: SiwinGlobalsWaylandObj) {.siwin_destructor.} =
  cast[SiwinGlobals](globals.addr).shutdownEventLoopWakeState()
  try:
    if globals.libdecorCtx != nil and libdecor_unref != nil:
      libdecor_unref(globals.libdecorCtx)
    wl_display_disconnect globals.display
  except: discard


proc signalWaylandWake(data: pointer) {.gcsafe, raises: [].} =
  let wake = cast[ptr WaylandWakeFd](data)
  if wake != nil and wake.writeFd >= 0:
    var byte = '\x01'
    {.cast(gcsafe).}:
      while write(wake.writeFd, byte.addr, 1) < 0 and errno == EINTR:
        discard

proc closeWaylandWake(data: pointer) {.gcsafe, raises: [].} =
  let wake = cast[ptr WaylandWakeFd](data)
  if wake != nil:
    if wake.readFd >= 0:
      discard close(wake.readFd)
    if wake.writeFd >= 0:
      discard close(wake.writeFd)
    dealloc(wake)

proc configureWakeFd(fd: cint) =
  let flags = fcntl(fd, F_GETFL)
  if flags < 0 or fcntl(fd, F_SETFL, flags or O_NONBLOCK) < 0:
    raiseOSError(osLastError())
  let fdFlags = fcntl(fd, F_GETFD)
  if fdFlags < 0 or fcntl(fd, F_SETFD, fdFlags or FD_CLOEXEC) < 0:
    raiseOSError(osLastError())

proc drainWaylandWake(globals: SiwinGlobalsWayland): bool =
  let wake = globals.wake
  if wake == nil:
    return false
  var buffer: array[64, char]
  while true:
    let count = read(wake.readFd, buffer[0].addr, buffer.len)
    if count > 0:
      result = true
    elif count < 0 and errno == EINTR:
      continue
    else:
      break
  if result:
    globals.consumeEventLoopWake()

proc waitTimeoutMilliseconds(timeout: Duration): cint =
  if timeout == Duration.high:
    return -1
  let nanoseconds = timeout.inNanoseconds
  if nanoseconds <= 0:
    return 0
  let milliseconds =
    nanoseconds div 1_000_000 + int64(nanoseconds mod 1_000_000 != 0)
  min(milliseconds, cint.high.int64).cint

proc waitTimeout(globals: SiwinGlobalsWayland, timeout: Duration): Duration =
  result = timeout
  if globals.repeatWakeDeadline != MonoTime.default:
    let remaining = globals.repeatWakeDeadline - getMonoTime()
    if remaining <= initDuration():
      return initDuration()
    if result == Duration.high or remaining < result:
      result = remaining

proc repeatWakeIsDue(globals: SiwinGlobalsWayland): bool =
  globals.repeatWakeDeadline != MonoTime.default and
    globals.repeatWakeDeadline <= getMonoTime()

proc libdecorFd(globals: SiwinGlobalsWayland): cint =
  if globals.libdecorCtx != nil and libdecor_get_fd != nil:
    result = libdecor_get_fd(globals.libdecorCtx)
  else:
    result = -1

proc dispatchLibdecor(globals: SiwinGlobalsWayland) =
  if globals.libdecorCtx != nil and libdecor_dispatch != nil and
      libdecor_dispatch(globals.libdecorCtx, 0) < 0:
    raise WaylandProtocolError.newException("failed to dispatch libdecor events")


proc initRegistryCallbacks(globals: SiwinGlobalsWayland) =
  template addRegistry(target: type, body) =
    globals.registryCallbacks[ifaceName(target)] = proc(registry {.inject.}: Wl_registry, name {.inject.}: uint32, version {.inject.}: uint32) =
      let binded {.inject.} = registry.bindTyped(name, target, version)
      body


  addRegistry Wl_compositor:
    globals.compositor = binded


  addRegistry Wl_shm:
    globals.shm = binded

    globals.shmFormats = @[]
    globals.shm.onFormat:
      globals.shmFormats.add format
    
    discard wl_display_roundtrip globals.display


  addRegistry Xdg_wm_base:
    globals.xdgWmBase = binded

    globals.xdgWmBase.onPing:
      globals.xdgWmBase.pong(serial)


  addRegistry Wl_seat:
    globals.seat = binded

    globals.seatCapabilities = globals.seatCapabilities.typeof.default
    globals.seat.onCapabilities:
      globals.seatCapabilities = capabilities.asBitfield
      if not globals.seatCapabilitiesChanged.isNil:
        globals.seatCapabilitiesChanged(globals)
    
    discard wl_display_roundtrip globals.display


  addRegistry Zxdg_decoration_manager_v1:
    globals.serverDecorationManager = binded

  addRegistry Org_kde_plasma_shell:
    globals.plasmaShell = binded

  addRegistry Org_kde_kwin_blur_manager:
    globals.blurManager = binded

  addRegistry Zwlr_layer_shell_v1:
    globals.layerShell = binded

  addRegistry Zwp_idle_inhibit_manager_v1:
    globals.idleInhibitManager = binded

  addRegistry Wl_data_device_manager:
    globals.dataDeviceManager = binded

  addRegistry Wp_viewporter:
    globals.viewporter = binded

  addRegistry Wp_fractional_scale_manager_v1:
    globals.fractionalScaleManager = binded

  addRegistry Xdg_toplevel_icon_manager_v1:
    globals.xdgToplevelIconManager = binded

  addRegistry Zwp_tablet_manager_v2:
    globals.tabletManager = binded

  addRegistry Wp_cursor_shape_manager_v1:
    globals.cursorShapeManager = binded 

  addRegistry Wl_output:
    globals.outputs.add WaylandOutput(registryName: name, output: binded)


proc isWaylandAvailable*: bool =
  proc isSocket(filename: string): bool =
    var res: Stat
    return stat(filename, res) >= 0'i32 and S_ISSOCK(res.st_mode)

  if wl_display_connect == nil: return false
  
  let isWayland = getEnv("XDG_SESSION_TYPE") == "wayland"
  if not isWayland: return false

  let runtimeDir = getEnv("XDG_RUNTIME_DIR")
  if runtimeDir == "": return false

  var serverName = getEnv("WAYLAND_DISPLAY")
  if serverName == "": serverName = "wayland-0"
  
  let waylandServer = runtimeDir / serverName

  result = isSocket(waylandServer)


proc newWaylandGlobals*(): SiwinGlobalsWayland =
  ## Create globals for wayland platform,
  ## ! roundtrip must be called after this to finish initialization
  ## registers callbacks for registry globals siwin care about,
  ## additional registryCallbacks can be added before calling roundtrip
  new result

  if wl_display_connect == nil:
    raise OSError.newException("Wayland is not available")

  result.display = wl_display_connect(nil)
  if result.display == nil:
    raise OSError.newException("Wayland is not available")

  result.wake = cast[ptr WaylandWakeFd](alloc0(sizeof(WaylandWakeFd)))
  var wakeFds: array[2, cint]
  if pipe(wakeFds) != 0:
    dealloc(result.wake)
    raiseOSError(osLastError())
  result.wake.readFd = wakeFds[0]
  result.wake.writeFd = wakeFds[1]
  try:
    configureWakeFd(result.wake.readFd)
    configureWakeFd(result.wake.writeFd)
  except:
    closeWaylandWake(result.wake)
    result.wake = nil
    raise
  result.installOwnedEventLoopWakeProc(signalWaylandWake, result.wake, closeWaylandWake)

  result.interfaces.initInterfaces()

  result.registry = result.display.get_registry(result.interfaces.addr)
  initRegistryCallbacks(result)

  let globals = result

  globals.registry.onGlobal:
    let interfaceString = $`interface`

    when defined(siwin_debug_echoWaylandSupportedProtocols):
      echo interfaceString

    for targetIface, callback in globals.registryCallbacks:
      if interfaceString == targetIface:
        callback(globals.registry, name, version)

  globals.registry.onGlobal_remove:
    for idx in countdown(globals.outputs.high, 0):
      if globals.outputs[idx].registryName == name:
        release globals.outputs[idx].output
        globals.outputs.delete(idx)


method pollEventsImpl(globals: SiwinGlobalsWayland): bool =
  result = globals.drainWaylandWake()
  if globals.display.dispatchPending() > 0:
    result = true

  while wl_display_prepare_read(globals.display) != 0:
    if globals.display.dispatchPending() > 0:
      result = true

  let
    displayFd = globals.display.wl_display_get_fd().cint
    decorationFd = globals.libdecorFd()
  var fds = [
    TPollfd(fd: displayFd, events: POLLIN),
    TPollfd(fd: globals.wake.readFd, events: POLLIN),
    TPollfd(
      fd: (if decorationFd != displayFd: decorationFd else: -1),
      events: POLLIN,
    ),
  ]
  let flushResult = wl_display_flush(globals.display)
  if flushResult < 0:
    if errno == EAGAIN:
      fds[0].events = fds[0].events or POLLOUT
    else:
      wl_display_cancel_read(globals.display)
      raise WaylandProtocolError.newException("failed to flush Wayland requests")

  let count = poll(fds[0].addr, fds.len.Tnfds, 0)
  if count < 0:
    wl_display_cancel_read(globals.display)
    if errno == EINTR:
      return
    raiseOSError(osLastError())
  if count == 0:
    wl_display_cancel_read(globals.display)
    return result or globals.repeatWakeIsDue()

  if (fds[0].revents and (POLLERR or POLLHUP or POLLNVAL)) != 0:
    wl_display_cancel_read(globals.display)
    raise OSError.newException("Wayland display connection closed while polling")
  if (fds[1].revents and (POLLERR or POLLHUP or POLLNVAL)) != 0:
    wl_display_cancel_read(globals.display)
    raise OSError.newException("Wayland event-loop wake pipe closed while polling")
  if (fds[2].revents and (POLLERR or POLLHUP or POLLNVAL)) != 0:
    wl_display_cancel_read(globals.display)
    raise OSError.newException("libdecor connection closed while polling")

  let
    displayReadable = (fds[0].revents and POLLIN) != 0
    decorationReadable = (fds[2].revents and POLLIN) != 0
  if displayReadable:
    if wl_display_read_events(globals.display) < 0:
      raise WaylandProtocolError.newException("failed to read Wayland events")
    result = true
  else:
    wl_display_cancel_read(globals.display)

  if (fds[1].revents and POLLIN) != 0:
    result = globals.drainWaylandWake() or result
  if (fds[0].revents and POLLOUT) != 0:
    let retryFlushResult = wl_display_flush(globals.display)
    if retryFlushResult < 0 and errno != EAGAIN:
      raise WaylandProtocolError.newException("failed to flush Wayland requests")

  if displayReadable:
    result = globals.display.dispatchPending() > 0 or result
  if displayReadable or decorationReadable:
    globals.dispatchLibdecor()
    result = true
  result = globals.repeatWakeIsDue() or result

method waitEventsImpl(
  globals: SiwinGlobalsWayland,
  timeout: Duration,
): EventWaitResult =
  if globals.pollEventsImpl():
    return eventActivity

  let started = getMonoTime()
  while true:
    while wl_display_prepare_read(globals.display) != 0:
      if globals.display.dispatchPending() > 0:
        return eventActivity

    let
      displayFd = globals.display.wl_display_get_fd().cint
      decorationFd = globals.libdecorFd()
    var fds = [
      TPollfd(fd: displayFd, events: POLLIN),
      TPollfd(fd: globals.wake.readFd, events: POLLIN),
      TPollfd(
        fd: (if decorationFd != displayFd: decorationFd else: -1),
        events: POLLIN,
      ),
    ]
    let flushResult = wl_display_flush(globals.display)
    if flushResult < 0:
      if errno == EAGAIN:
        fds[0].events = fds[0].events or POLLOUT
      else:
        wl_display_cancel_read(globals.display)
        raise WaylandProtocolError.newException("failed to flush Wayland requests")

    let callerRemaining =
      if timeout == Duration.high:
        Duration.high
      else:
        max(initDuration(), timeout - (getMonoTime() - started))
    let count = poll(
      fds[0].addr,
      fds.len.Tnfds,
      waitTimeoutMilliseconds(globals.waitTimeout(callerRemaining)),
    )
    if count == 0:
      wl_display_cancel_read(globals.display)
      if globals.repeatWakeIsDue():
        return eventActivity
      if timeout != Duration.high and getMonoTime() - started >= timeout:
        return eventTimeout
      continue
    if count < 0:
      wl_display_cancel_read(globals.display)
      if errno == EINTR:
        if timeout != Duration.high and getMonoTime() - started >= timeout:
          return eventTimeout
        continue
      raiseOSError(osLastError())

    if (fds[0].revents and (POLLERR or POLLHUP or POLLNVAL)) != 0:
      wl_display_cancel_read(globals.display)
      raise OSError.newException("Wayland display connection closed while waiting")
    if (fds[1].revents and (POLLERR or POLLHUP or POLLNVAL)) != 0:
      wl_display_cancel_read(globals.display)
      raise OSError.newException("Wayland event-loop wake pipe closed while waiting")
    if (fds[2].revents and (POLLERR or POLLHUP or POLLNVAL)) != 0:
      wl_display_cancel_read(globals.display)
      raise OSError.newException("libdecor connection closed while waiting")

    let
      displayReadable = (fds[0].revents and POLLIN) != 0
      decorationReadable = (fds[2].revents and POLLIN) != 0
      wakeReadable = (fds[1].revents and POLLIN) != 0
    if displayReadable:
      if wl_display_read_events(globals.display) < 0:
        raise WaylandProtocolError.newException("failed to read Wayland events")
    else:
      wl_display_cancel_read(globals.display)

    if wakeReadable:
      discard globals.drainWaylandWake()
    if (fds[0].revents and POLLOUT) != 0:
      let retryFlushResult = wl_display_flush(globals.display)
      if retryFlushResult < 0 and errno != EAGAIN:
        raise WaylandProtocolError.newException("failed to flush Wayland requests")

    if displayReadable:
      discard globals.display.dispatchPending()
    if displayReadable or decorationReadable:
      globals.dispatchLibdecor()

    if displayReadable or decorationReadable or wakeReadable:
      return eventActivity
    # POLLOUT only means queued protocol output can proceed; keep waiting for
    # application-visible activity without turning writability into a busy loop.


proc roundtrip*(globals: SiwinGlobalsWayland) =
  discard wl_display_roundtrip globals.display


proc initLibdecor*(globals: SiwinGlobalsWayland) =
  if globals.libdecorCtx != nil: return
  if not libdecorAvailable(): return

  globals.libdecorIface = LibdecorInterface(
    # raise is unsafe in cdecl callbacks:
    # with --exceptions:goto, the exception is silently lost
    # and C code continues executing as if nothing happened.
    # with --exceptions:setjmp, longjmp skips C cleanup code (free, etc).
    # see also https://github.com/nim-lang/c2nim/issues/243
    # so it uses writing to stderr as workaround
    error: proc(context: LibdecorContext, error: LibdecorError, message: cstring) {.cdecl.} =
      stderr.writeLine "siwin: libdecor error: ", message)

  globals.libdecorCtx = libdecor_new(globals.display.raw, globals.libdecorIface.addr)


proc expectExtension*[T](x: T) =
  if x.proxy == nil: raise WaylandExtensionNotFound.newException("Extension required, but not found: " & ifaceName(T))
