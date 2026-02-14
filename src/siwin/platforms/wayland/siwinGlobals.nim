import std/[tables, os, posix]
import ../any/[window, clipboards]
import ./[libwayland, protocol, bitfields]

type
  WaylandExtensionNotFound* = object of CatchableError

  SiwinGlobalsWayland* = ref SiwinGlobalsWaylandObj
  SiwinGlobalsWaylandObj* = object of SiwinGlobals
    seatEventsInitialized*: bool
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

    serverDecorationManager*: Zxdg_decoration_manager_v1
    plasmaShell*: Org_kde_plasma_shell
    layerShell*: Zwlr_layer_shell_v1
    idleInhibitManager*: Zwp_idle_inhibit_manager_v1
    
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

    associatedWindows*: Table[uint32, Window]  # surface proxy id -> window
    associatedWindows_queueRemove_insteadOf_removingInstantly* = false
    associatedWindows_removeQueue*: seq[uint32]

    seat_pointer_currentWindow*: Window
    seat_keyboard_currentWindow*: Window
    # seat_touch_currentWindow*: Window

    seat_keyboard_repeatSettings*: tuple[rate, delay: int32]

    primaryClipboard*: Clipboard
    selectionClipboard*: Clipboard
    dragndropClipboard*: Clipboard

    lastSeatEventSerial*: uint32


proc `=destroy`*(globals: SiwinGlobalsWaylandObj) =
  try:
    wl_display_disconnect globals.display
  except: discard


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
    
    discard wl_display_roundtrip globals.display


  addRegistry Zxdg_decoration_manager_v1:
    globals.serverDecorationManager = binded

  addRegistry Org_kde_plasma_shell:
    globals.plasmaShell = binded

  addRegistry Zwlr_layer_shell_v1:
    globals.layerShell = binded

  addRegistry Zwp_idle_inhibit_manager_v1:
    globals.idleInhibitManager = binded

  addRegistry Wl_data_device_manager:
    globals.dataDeviceManager = binded


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


proc roundtrip*(globals: SiwinGlobalsWayland) =
  discard wl_display_roundtrip globals.display


proc expectExtension*[T](x: T) =
  if x.proxy == nil: raise WaylandExtensionNotFound.newException("Extension required, but not found: " & ifaceName(T))
