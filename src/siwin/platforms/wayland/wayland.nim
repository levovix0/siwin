import vmath, opengl
import libwayland, protocol, sharedBuffer, egl
import ../../../../tests/gl

var
  initialized: bool

  display: WlDisplay
  registry: WlRegistry

  compositor: WlCompositor
  shm: WlShm
  seat: WlSeat
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

    of "wl_seat":
      seat = registry.bindTyped(name, WlSeat, version)

  wl_display_roundtrip display

  if compositor == nil or shm == nil or shell == nil:
    raise WaylandProtocolError.newException(
      "Not enough Wayland interfaces, missing: " &
      (if compositor == nil: "wl_compositor " else: "") &
      (if shm == nil: "wl_shm " else: "") &
      (if shell == nil: "xdg_wm_base " else: "")
    )

  wl_display_roundtrip display

  initEgl(display.raw)

  initialized = true


when isMainModule:
  init()

  let srf = compositor.create_surface
  let ssrf = shell.get_xdg_surface(srf)
  let tl = ssrf.get_toplevel

  # let opaque_region = compositor.create_region
  # opaque_region.add(0, 0, 1280, 720)
  # # opaque_region.subtract(0, 0, 1280, 720)
  # srf.set_opaque_region(opaque_region)

  # let buf = shm.create(ivec2(128, 128), xrgb8888)
  # srf.attach(buf.buffer, 0, 0)
  # commit srf

  tl.set_title("siwin wayland test")

  commit srf

  let eglctx = newOpenglContext(srf.proxy.raw, 1280, 720)
  makeCurrent eglctx
  loadExtensions()

  ssrf.onConfigure:
    ssrf.ackConfigure(serial)
    commit srf

  var windowClosed = false
  tl.onClose: windowClosed = true

  wl_display_roundtrip display

  commit srf


  while not windowClosed:
    block:
      let ctx = newDrawContext()

      # glViewport 0, 0, 1280, 720

      glClearColor(32/255/2, 32/255/2, 32/255/2, 1/2)
      # glClearColor(0, 0, 0, 0)
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

      let shader = ctx.makeShader:
        {.version: "320 es".}
        proc vert(
          gl_Position: var Vec4,
          pos: var Vec2,
          in_pos: Vec2,
        ) =
          gl_Position = vec4(in_pos.x - 0.5, in_pos.y - 0.5, 0, 1)
          pos = in_pos

        proc frag(
          glCol: var Vec4,
          pos: Vec2,
        ) =
          # glCol = vec4(pos.x, pos.y, 0, pos.x * pos.y)
          glCol = vec4(pos.x, pos.y, 0, 1)
      
      # glEnable(GlBlend)
      # glBlendFuncSeparate(GlOne, GlOneMinusSrcAlpha, GlOne, GlOne)
      use shader.shader
      draw ctx.rect
      # glDisable(GlBlend)

    swapBuffers eglctx


    wl_display_roundtrip display
