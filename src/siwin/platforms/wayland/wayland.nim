import libwayland, protocol

var
  initialized: bool

  display: WlDisplay
  registry: WlRegistry

  compositor: WlCompositor
  shm: WlShm
  shell: XdgWmBase

  pixelFormats: seq[`WlShm / Format`]

proc init* =
  if initialized: return

  display = wl_display_connect()

  registry = display.get_registry

  registry.onGlobal:
    case `interface`
    of "wl_compositor":
      compositor = registry.bindTyped(name, WlCompositor, version)

    of "wl_shm":
      shm = registry.bindTyped(name, WlShm, version)

      shm.onFormat:
        pixelFormats.add format
    
    of "xdg_wm_base":
      shell = registry.bindTyped(name, XdgWmBase, version)

      shell.onPing:
        shell.pong(serial)

  wl_display_roundtrip display

  if compositor == nil or shm == nil or shell == nil:
    raise WaylandProtocolError.newException(
      "Not enough Wayland interfaces, missing: " &
      (if compositor == nil: "wl_compositor " else: "") &
      (if shm == nil: "wl_shm " else: "") &
      (if shell == nil: "xdg_wm_base " else: "")
    )

  wl_display_roundtrip display

  echo pixelFormats

  # initEgl()

  initialized = true

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
