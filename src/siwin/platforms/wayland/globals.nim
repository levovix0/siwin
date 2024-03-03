import tables
import ./[libwayland, protocol]

type
  WaylandExtensionNotFound* = object of CatchableError

var
  initialized: bool

  display*: WlDisplay
  registry: WlRegistry

  registryCallbacks*: Table[string, proc(registry: Wl_registry, name: uint32, version: uint32)]
  
  compositor*: WlCompositor
  shm*: WlShm
  xdgWmBase*: XdgWmBase
  seat*: WlSeat

  kdeServerDecorationsManager*: Org_kde_kwin_server_decoration_manager

  shmFormats*: seq[`WlShm / Format`]

  waylandAvailable* = true


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

addRegistry Xdg_wm_base:
  xdgWmBase = binded

  xdgWmBase.onPing:
    xdgWmBase.pong(serial)

addRegistry Wl_seat:
  seat = binded

addRegistry Org_kde_kwin_server_decoration_manager:
  kdeServerDecorationsManager = binded


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
    for targetIface, callback in registryCallbacks:
      if interfaceString == targetIface:
        callback(registry, name, version)
  
  wl_display_roundtrip display


proc uninit* =
  if not initialized: return
  initialized = false

  wl_display_disconnect display


proc expectExtension*[T](x: T) =
  if x.proxy == nil: raise WaylandExtensionNotFound.newException("Extension required, but not found: " & $T.iface[].name)
