import libwayland, protocol

type
  Wl_registry* = object
    proxy*: WlProxy
  `Wl_registry/Callbacks`* = object
    destroy: proc(cb: pointer) {.cdecl, raises: [].}
    global*: proc(name: uint32, iface: cstring, version: uint32)

var `Wl_registry/iface`: WlInterface
proc iface*(t: type Wl_registry): ptr WlInterface = `Wl_registry/iface`.addr

`Wl_registry/iface` = newWlInterface(
  "wl_registry", 1,
  [
    # newWlMessage("f", "in", [nil, R.iface]),
  ],
  [
    newWlMessage("wl_registry.global", "usu", [(ptr WlInterface)nil, nil, nil]),
  ]
)

proc `Wl_registry/dispatch`(impl: pointer, obj: pointer, opcode: uint32, msg: ptr WlMessage, args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Wl_registry/Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (uint32, cstring, uint32)](args)[]
    if callbacks.global != nil:
      callbacks.global(args[0], args[1], args[2])
  else: discard

proc get_registry*(this: Wl_display): Wl_registry =
  let args = (0'u32,)
  wl_proxy_marshal_array_flags(this.raw, 1, Wl_registry.iface, 1, 0, args.addr).construct(Wl_registry, `Wl_registry/dispatch`, `Wl_registry/Callbacks`)

template onGlobal*(this: Wl_registry; body) =
  cast[ptr `Wl_registry/Callbacks`](this.proxy.raw.impl).global = proc(name {.inject.}: uint32, iface {.inject.}: cstring, version {.inject.}: uint32) =
    body

var
  initialized: bool

  display: Wl_display
  registry: Wl_registry

  # compositor: Compositor
  # shm: Shm
  # shell: XdgWmBase

  # pixelFormats: seq[PixelFormat]

proc init* =
  if initialized: return

  display = wl_display_connect()
  registry = display.get_registry
  # registry.onGlobal:
  #   echo iface, ", ", name, ", ", version
  wl_display_roundtrip display

  # registry = display.registry

  # registry.onGlobal:
  #   case iface
  #   of Compositor.iface:
  #     compositor = registry.bindInterface(Compositor, name, iface, version)

  #   of Shm.iface:
  #     shm = registry.bindInterface(Shm, name, iface, version)

  #     shm.onFormat:
  #       pixelFormats.add format

  #   of XdgWmBase.iface:
  #     shell = registry.bindInterface(XdgWmBase, name, iface, version)

  #     shell.onPing:
  #       shell.pong(serial)

  # sync display

#   if compositor == nil or shm == nil or shell == nil:
#     raise WindyError.newException(
#       "Not enough Wayland interfaces, missing: " &
#       (if compositor == nil: "wl_compositor " else: "") &
#       (if shm == nil: "wl_shm " else: "") &
#       (if shell == nil: "xdg_wm_base " else: "")
#     )

#   sync display

#   initEgl()

#   initialized = true

when isMainModule:
  init()
#   let srf = compositor.newSurface
#   let ssrf = shell.shellSurface(srf)
#   let tl = ssrf.toplevel

#   commit srf

#   ssrf.onConfigure:
#     ssrf.ackConfigure(serial)
#     commit srf

#   tl.onClose: quit()

#   sync display

#   let buf = shm.create(ivec2(128, 128), PixelFormat.xrgb8888)
#   attach srf, buf.buffer, ivec2(0, 0)
#   commit srf

#   makeCurrent newOpenglContext()

  # how to draw on window?
  # i tried:
  #   creating context on window (incompatible native window (wl_window vs. protocol.Window))
  #   eglCreateDRMImageMESA/eglExportDRMImageMESA/wl_drm.newBuffer (fails via BadAlloc)
  # in this code works:
  #   setting pixels manually on buf.dataAddr (no OpenGL)

  # while true: sync display
