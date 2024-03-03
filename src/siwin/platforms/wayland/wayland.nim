import unicode
import vmath, opengl
import libwayland, protocol, egl
import ../../../../tests/gl

var
  initialized: bool

  display: WlDisplay
  registry: WlRegistry

  compositor: WlCompositor
  shm: WlShm
  shell: XdgWmBase
  seat: WlSeat

  serverDecorations: Org_kde_kwin_server_decoration_manager

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

    of "org_kde_kwin_server_decoration_manager":
      serverDecorations = registry.bindTyped(name, Org_kde_kwin_server_decoration_manager, version)

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

  # tl.set_app_id("DMusic")
  # tl.set_app_id("Веб-браузер Firefox")
  tl.set_app_id("siwin")

  # tl.set_min_size(1280, 720)
  # tl.set_max_size(1280, 720)

  commit srf


  let ssd {.used.} = serverDecorations.create(srf)


  let eglctx = newOpenglContext(srf.proxy.raw, 1280, 720)
  makeCurrent eglctx
  loadExtensions()

  ssrf.onConfigure:
    ssrf.ackConfigure(serial)
    commit srf

  tl.onConfigure:
    eglctx.win.wl_egl_window_resize(width, height, 0, 0)
    ssrf.ackConfigure(0)  #? is it needed?
    glViewport 0, 0, width, height

  var windowClosed = false
  tl.onClose: windowClosed = true


  wl_display_roundtrip display

  commit srf


  let keyboard = seat.get_keyboard

  keyboard.onKey:
    echo cast[Rune](key), " ", key


  while not windowClosed:
    block:
      let ctx = newDrawContext()

      # glViewport 0, 0, 1280, 720

      glClearColor(32/255/2, 32/255/2, 32/255/2, 1/2)
      # glClearColor(32/255, 32/255, 32/255, 1)
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
