import tables
import ./[libwayland, protocol, bitfields]

type
  WaylandExtensionNotFound* = object of CatchableError

var
  initialized: bool
  seatEventsInitialized*: bool

  display*: WlDisplay
  registry: WlRegistry

  registryCallbacks*: Table[string, proc(registry: Wl_registry, name: uint32, version: uint32)]
  
  compositor*: WlCompositor
  shm*: WlShm
  xdgWmBase*: XdgWmBase
  seat*: WlSeat

  serverDecorationManager*: Zxdg_decoration_manager_v1
  plasmaShell*: Org_kde_plasma_shell
  layerShell*: Zwlr_layer_shell_v1
  idleInhibitor*: Zwp_idle_inhibitor_v1
  
  shmFormats*: seq[`WlShm / Format`]
  seatCapabilities*: Bitfield[`WlSeat / Capability`]

  waylandAvailable* = true

  seat_pointer*: Wl_pointer
  seat_keyboard*: Wl_keyboard
  seat_touch*: Wl_touch


template addRegistry*(target: type, body) =
  registryCallbacks[$target.iface[].name] = proc(registry {.inject.}: Wl_registry, name {.inject.}: uint32, version {.inject.}: uint32) =
    let binded {.inject.} = registry.bindTyped(name, target, version)
    body


addRegistry Wl_compositor:
  compositor = binded


addRegistry Wl_shm:
  shm = binded

  shmFormats = @[]
  shm.onFormat:
    shmFormats.add format
  
  discard wl_display_roundtrip display


addRegistry Xdg_wm_base:
  xdgWmBase = binded

  xdgWmBase.onPing:
    xdgWmBase.pong(serial)


addRegistry Wl_seat:
  seat = binded

  seatCapabilities = seatCapabilities.typeof.default
  seat.onCapabilities:
    seatCapabilities = capabilities.asBitfield
  
  discard wl_display_roundtrip display


addRegistry Zxdg_decoration_manager_v1:
  serverDecorationManager = binded

addRegistry Org_kde_plasma_shell:
  plasmaShell = binded

addRegistry Zwlr_layer_shell_v1:
  layerShell = binded

addRegistry Zwp_idle_inhibitor_v1:
  idleInhibitor = binded

proc init* =
  if initialized: return
  if not waylandAvailable: return
  initialized = true

  display = wl_display_connect()
  if display == nil:
    initialized = false
    waylandAvailable = false
    return

  registry = display.get_registry

  registry.onGlobal:
    let interfaceString = $`interface`

    when defined(siwin_debug_echoWaylandSupportedProtocols):
      echo interfaceString

    for targetIface, callback in registryCallbacks:
      if interfaceString == targetIface:
        callback(registry, name, version)
  
  discard wl_display_roundtrip display


proc uninit* =
  if not initialized: return
  initialized = false
  seatEventsInitialized = false

  wl_display_disconnect display


proc expectExtension*[T](x: T) =
  if x.proxy == nil: raise WaylandExtensionNotFound.newException("Extension required, but not found: " & $T.iface[].name)
