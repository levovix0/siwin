import std/[times, importutils, strformat, options]
import pkg/[vmath]
import ../../utils, ../../bgrx
import ../any/window {.all.}
import ./[libwayland, protocol, globals, sharedBuffer, bitfields]

{.experimental: "overloadableEnums".}

privateAccess Window

type
  ScreenWayland* = ref object of Screen
    id: cint


  WindowWayland* = ref WindowWaylandObj
  WindowWaylandObj* = object of Window
    surface: Wl_surface
    xdgSurface: Xdg_surface
    xdgToplevel: Xdg_toplevel

    kdeDecorations: Org_kde_kwin_server_decoration

    lastClickTime: Duration
    doubleClickHandled: bool

    lastActionSerial: uint32
    isPointerInside: bool

    seat_pointer: Wl_pointer
    seat_keyboard: Wl_keyboard
    seat_touch: Wl_touch
  
  WindowWaylandSoftwareRendering* = ref object of WindowWayland
    buffer: SharedBuffer


proc waylandKeyToKey(keycode: uint32): Key =
  ## todo
  case keycode
  # of Xk_shiftL:       Key.lshift
  # of Xk_shiftR:       Key.rshift
  # of Xk_controlL:     Key.lcontrol
  # of Xk_controlR:     Key.rcontrol
  # of Xk_altL:         Key.lalt
  # of Xk_altR:         Key.ralt
  # of Xk_superL:       Key.lsystem
  # of Xk_superR:       Key.rsystem
  # of Xk_menu:         Key.menu
  # of Xk_escape:       Key.escape
  # of Xk_semicolon:    Key.semicolon
  # of Xk_slash:        Key.slash
  # of Xk_equal:        Key.equal
  # of Xk_minus:        Key.minus
  # of Xk_bracketleft:  Key.lbracket
  # of Xk_bracketright: Key.rbracket
  # of Xk_comma:        Key.comma
  # of Xk_period:       Key.dot
  # of Xk_apostrophe:   Key.quote
  # of Xk_backslash:    Key.backslash
  # of Xk_grave:        Key.tilde
  # of Xk_space:        Key.space
  # of Xk_return:       Key.enter
  # of Xk_kpEnter:      Key.enter
  # of Xk_backspace:    Key.backspace
  # of Xk_tab:          Key.tab
  # of Xk_prior:        Key.page_up
  # of Xk_next:         Key.page_down
  # of Xk_end:          Key.End
  # of Xk_home:         Key.home
  # of Xk_insert:       Key.insert
  # of Xk_delete:       Key.del
  # of Xk_kpAdd:        Key.add
  # of Xk_kpSubtract:   Key.subtract
  # of Xk_kpMultiply:   Key.multiply
  # of Xk_kpDivide:     Key.divide
  # of Xk_capsLock:     Key.capsLock
  # of Xk_numLock:      Key.numLock
  # of Xk_scrollLock:   Key.scrollLock
  # of Xk_print:        Key.printScreen
  # of Xk_kpSeparator:  Key.npadDot
  # of Xk_pause:        Key.pause
  # of Xk_f1:           Key.f1
  # of Xk_f2:           Key.f2
  # of Xk_f3:           Key.f3
  # of Xk_f4:           Key.f4
  # of Xk_f5:           Key.f5
  # of Xk_f6:           Key.f6
  # of Xk_f7:           Key.f7
  # of Xk_f8:           Key.f8
  # of Xk_f9:           Key.f9
  # of Xk_f10:          Key.f10
  # of Xk_f11:          Key.f11
  # of Xk_f12:          Key.f12
  # of Xk_f13:          Key.f13
  # of Xk_f14:          Key.f14
  # of Xk_f15:          Key.f15
  # of Xk_left:         Key.left
  # of Xk_right:        Key.right
  # of Xk_up:           Key.up
  # of Xk_down:         Key.down
  # of Xk_kpInsert:     Key.npad0
  # of Xk_kpEnd:        Key.npad1
  # of Xk_kpDown:       Key.npad2
  # of Xk_kpPagedown:   Key.npad3
  # of Xk_kpLeft:       Key.npad4
  # of Xk_kpBegin:      Key.npad5
  # of Xk_kpRight:      Key.npad6
  # of Xk_kpHome:       Key.npad7
  # of Xk_kpUp:         Key.npad8
  # of Xk_kpPageup:     Key.npad9
  # of Xk_a:            Key.a
  # of Xk_b:            Key.b
  # of Xk_c:            Key.c
  # of Xk_d:            Key.d
  # of Xk_e:            Key.e
  # of Xk_f:            Key.f
  # of Xk_g:            Key.g
  # of Xk_h:            Key.h
  # of Xk_i:            Key.i
  # of Xk_j:            Key.j
  # of Xk_k:            Key.k
  # of Xk_l:            Key.l
  # of Xk_m:            Key.m
  # of Xk_n:            Key.n
  # of Xk_o:            Key.o
  # of Xk_p:            Key.p
  # of Xk_q:            Key.q
  # of Xk_r:            Key.r
  # of Xk_s:            Key.s
  # of Xk_t:            Key.t
  # of Xk_u:            Key.u
  # of Xk_v:            Key.v
  # of Xk_w:            Key.w
  # of Xk_x:            Key.x
  # of Xk_y:            Key.y
  # of Xk_z:            Key.z
  # of Xk_0:            Key.n0
  # of Xk_1:            Key.n1
  # of Xk_2:            Key.n2
  # of Xk_3:            Key.n3
  # of Xk_4:            Key.n4
  # of Xk_5:            Key.n5
  # of Xk_6:            Key.n6
  # of Xk_7:            Key.n7
  # of Xk_8:            Key.n8
  # of Xk_9:            Key.n9
  else:               Key.unknown


method swapBuffers(window: WindowWayland) {.base.} = discard


proc screenCountWayland*: int32 =
  globals.init()
  ## todo
  1

proc screenWayland*(number: int32): ScreenWayland =
  new result
  globals.init()
  if number notin 0..<screenCountWayland(): raise IndexDefect.newException(&"screen {number} doesn't exist")
  result.id = number.cint

proc defaultScreenWayland*: ScreenWayland =
  globals.init()
  ScreenWayland(id: 0.cint)

method number*(screen: ScreenWayland): int32 = screen.id

method width*(screen: ScreenWayland): int32 = 1920  # todo
method height*(screen: ScreenWayland): int32 = 1080  # todo


proc `=destroy`(window: WindowWaylandObj) =
  let window = window.addr
  template destroy(x, f) =
    if x != typeof(x).default:
      f x
      x = typeof(x).default

  destroy window.seat_pointer, release
  destroy window.seat_keyboard, release
  destroy window.seat_touch, release

  destroy window.kdeDecorations, release
  destroy window.xdgToplevel, destroy
  destroy window.xdgSurface, destroy
  destroy window.surface, destroy

  for x in window[].fields:
    when compiles(`=destroy`(x)):
      try:
        `=destroy`(x)
      except:
        discard


method release(window: WindowWayland) {.base.} =
  ## destroy wayland part of window
  template destroy(x, f) =
    if x != typeof(x).default:
      f x
      x = typeof(x).default

  destroy window.seat_pointer, release
  destroy window.seat_keyboard, release
  destroy window.seat_touch, release
  
  destroy window.kdeDecorations, release
  destroy window.xdgToplevel, destroy
  destroy window.xdgSurface, destroy
  destroy window.surface, destroy

method release(window: WindowWaylandSoftwareRendering) =
  ## destroy wayland part of window
  window.buffer = SharedBuffer()

  procCall window.WindowWayland.release()


template pushEvent(eventsHandler: WindowEventsHandler, event, args) =
  if eventsHandler.event != nil:
    eventsHandler.event(args)


proc basicInitWindow(window: WindowWayland; size: IVec2; screen: ScreenWayland) =
  window.m_size = size
  window.m_focused = true
  window.m_resizable = true
  window.m_frameless = true


method doResize(window: WindowWayland, size: IVec2) {.base.} =
  window.m_size = size

  if not window.m_transparent:
    let opaqueRegion = compositor.create_region
    opaqueRegion.add(0, 0, window.m_size.x, window.m_size.y)
    window.surface.set_opaque_region(opaqueRegion)
    destroy opaqueRegion


method doResize(window: WindowWaylandSoftwareRendering, size: IVec2) =
  procCall window.WindowWayland.doResize(size)
  window.buffer.resize(size)
  # no need to attach buffer yet


proc resize(window: WindowWayland, size: IVec2) =
  if size.x * size.y == 0:
    ## hmm, ignore
    return
    
  window.doResize size
  
  if not window.m_resizable:
    window.xdgToplevel.set_min_size(window.m_size.x, window.m_size.y)
    window.xdgToplevel.set_max_size(window.m_size.x, window.m_size.y)

  commit window.surface

  window.eventsHandler.pushEvent onResize, ResizeEvent(window: window, size: window.m_size)
  redraw window


method `title=`*(window: WindowWayland, v: string) =
  window.xdgToplevel.set_title(v)


proc setFrameless(window: WindowWayland, v: bool) =
  if not v:
    if kdeServerDecorationsManager.proxy.raw != nil:
      window.kdeDecorations = kdeServerDecorationsManager.create(window.surface)
  else:
    if window.kdeDecorations.proxy.raw != nil:
      release window.kdeDecorations
      window.kdeDecorations.proxy.raw = nil


method `fullscreen=`*(window: WindowWayland, v: bool) =
  if window.m_fullscreen == v: return
  window.m_fullscreen = v

  if v:
    if window.m_frameless: window.setFrameless(true)
    window.xdgToplevel.set_fullscreen(Wl_output(proxy: Wl_proxy(raw: nil)))
  
  else:
    window.xdgToplevel.unset_fullscreen()
    if not window.m_frameless: window.setFrameless(false)


method `frameless=`*(window: WindowWayland, v: bool) =
  if window.m_frameless == v: return
  window.m_frameless = v
  if window.m_fullscreen: return  # no system decorations needed for fullscreen windows
  window.setFrameless(v)


method `size=`*(window: WindowWayland, v: IVec2) =
  if window.fullscreen:
    window.fullscreen = false
  window.resize(v)


method `pos=`*(window: WindowWayland, v: IVec2) =
  ## todo


method `cursor=`*(window: WindowWayland, v: Cursor) =
  if v.kind == builtin and window.cursor.kind == builtin and v.builtin == window.cursor.builtin: return
  ## todo


method `icon=`*(window: WindowWayland, v: nil.typeof) =
  ## todo

method `icon=`*(window: WindowWayland, v: tuple[pixels: openarray[ColorBgrx], size: IVec2]) =
  if v.size.x * v.size.y == 0: window.icon = nil
  assert v.pixels.len >= v.size.x * v.size.y, "not enougth pixels"
  ## todo


method drawImage*(window: WindowWaylandSoftwareRendering, pixels: openarray[ColorBgrx], size: IVec2, pos: IVec2 = ivec2(), srcPos: IVec2 = ivec2()) =
  assert pixels.len >= size.x * size.y, "not enougth pixels"
  ## todo: pos, srcPos
  for i in 0..<(size.x * size.y):
    cast[ptr UncheckedArray[byte]](window.buffer.dataAddr)[i * ColorBgrx.sizeof] = pixels[i].a
    cast[ptr UncheckedArray[byte]](window.buffer.dataAddr)[i * ColorBgrx.sizeof + 1] = pixels[i].r
    cast[ptr UncheckedArray[byte]](window.buffer.dataAddr)[i * ColorBgrx.sizeof + 2] = pixels[i].g
    cast[ptr UncheckedArray[byte]](window.buffer.dataAddr)[i * ColorBgrx.sizeof + 3] = pixels[i].b
  window.surface.attach(window.buffer.buffer, 0, 0)
  window.surface.damage_buffer(0, 0, size.x, size.y)
  commit window.surface


method `maximized=`*(window: WindowWayland, v: bool) =
  if window.m_maximized == v: return
  if window.fullscreen:
    window.fullscreen = false
  window.m_maximized = v

  if v:
    window.xdgToplevel.set_maximized()
  else:
    window.xdgToplevel.unsetMaximized()

  window.eventsHandler.pushEvent onMaximizedChanged, MaximizedChangedEvent(window: window, maximized: window.m_maximized)


proc releaseAllKeys(window: WindowWayland) =
  ## release all pressed keys
  ## needed when window loses focus
  for k in window.keyboard.pressed.items:
    window.keyboard.pressed.excl k
    window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: k, pressed: false, repeated: false, generated: true)

  for b in window.mouse.pressed:
    window.mouse.pressed.excl b
    window.eventsHandler.pushEvent onMouseButton, MouseButtonEvent(window: window, button: b, pressed: false, generated: true)


method `minimized=`*(window: WindowWayland, v: bool) =
  window.m_minimized = v
  if not v:
    ## todo
  else:
    window.xdgToplevel.set_minimized()


method `visible=`*(window: WindowWayland, v: bool) =
  if v == window.m_visible: return
  window.m_visible = v
  ## todo


method `resizable=`*(window: WindowWayland, v: bool) =
  window.m_resizable = v
  let size = window.size

  if v:
    window.xdgToplevel.set_min_size(window.m_minSize.x, window.m_minSize.y)
    window.xdgToplevel.set_max_size(window.m_maxSize.x, window.m_maxSize.y)
  else:
    window.xdgToplevel.set_min_size(size.x, size.y)
    window.xdgToplevel.set_max_size(size.x, size.y)


method `minSize=`*(window: WindowWayland, v: IVec2) =
  window.m_minSize = v
  if not window.m_resizable: return
  window.xdgToplevel.set_min_size(v.x, v.y)


method `maxSize=`*(window: WindowWayland, v: IVec2) =
  window.m_maxSize = v
  if not window.m_resizable: return
  window.xdgToplevel.set_max_size(v.x, v.y)


method startInteractiveMove*(window: WindowWayland, pos: Option[IVec2]) =
  expectExtension seat
  window.xdgToplevel.move(seat, window.lastActionSerial)


method startInteractiveResize*(window: WindowWayland, edge: Edge, pos: Option[IVec2]) =
  expectExtension seat
  window.xdgToplevel.resize(
    seat, window.lastActionSerial,
    case edge
    of Edge.topLeft: `Xdg_toplevel/Resize_edge`.top_left
    of Edge.top: `Xdg_toplevel/Resize_edge`.top
    of Edge.topRight: `Xdg_toplevel/Resize_edge`.top_right
    of Edge.right: `Xdg_toplevel/Resize_edge`.right
    of Edge.bottomRight: `Xdg_toplevel/Resize_edge`.bottom_right
    of Edge.bottom: `Xdg_toplevel/Resize_edge`.bottom
    of Edge.bottomLeft: `Xdg_toplevel/Resize_edge`.bottom_left
    of Edge.left: `Xdg_toplevel/Resize_edge`.left
  )


proc setupWindow(window: WindowWayland, fullscreen, frameless, transparent: bool, size: IVec2, class: string) =
  expectExtension compositor
  expectExtension xdgWmBase
  
  window.surface = compositor.create_surface
  window.xdgSurface = xdgWmBase.get_xdg_surface(window.surface)
  window.xdgToplevel = window.xdgSurface.get_toplevel

  window.xdgSurface.onConfigure:
    window.xdgSurface.ack_configure(serial)
    commit window.surface

  window.fullscreen = fullscreen
  window.frameless = frameless

  window.m_transparent = transparent
  if not transparent:
    let opaqueRegion = compositor.create_region
    opaqueRegion.add(0, 0, size.x, size.y)
    window.surface.set_opaque_region(opaqueRegion)
    destroy opaqueRegion
  
  if class != "":
    window.xdgToplevel.set_app_id(class)

  window.xdgToplevel.onClose:
    window.m_closed = true

  window.xdgToplevel.onConfigure:
    window.xdgSurface.ackConfigure(0)  #? is it needed?    
    window.resize(ivec2(width, height))
  

  if seat.proxy.raw != nil:
    if `WlSeat / Capability`.`pointer` in seatCapabilities:
      window.seat_pointer = seat.get_pointer

      window.seat_pointer.onEnter:
        if surface != window.surface: return
        window.lastActionSerial = serial
        window.isPointerInside = true
        window.mouse.pos = vec2(surface_x, surface_y).ivec2
        window.eventsHandler.pushEvent onMouseMove, MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.enter)
      
      window.seat_pointer.onLeave:
        if surface != window.surface: return
        window.lastActionSerial = serial
        window.isPointerInside = false
        window.eventsHandler.pushEvent onMouseMove, MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.leave)
      
      window.seat_pointer.onMotion:
        if not window.isPointerInside: return
        window.mouse.pos = vec2(surface_x, surface_y).ivec2
        window.eventsHandler.pushEvent onMouseMove, MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.move)
      
      window.seat_pointer.onButton:
        let nows = initDuration(milliseconds = time.int64)

        let button = case button
        of 0x110: MouseButton.left
        of 0x111: MouseButton.right
        of 0x112: MouseButton.middle
        of 0x115: MouseButton.forward
        of 0x116: MouseButton.backward
        else: return  # todo?

        if (
          (state != `WlPointer / Button_state`.released or button in window.mouse.pressed) and
          not window.isPointerInside
        ): return

        window.lastActionSerial = serial
        if state == `WlPointer / Button_state`.pressed:
          window.mouse.pressed.incl button
          window.clicking.incl button

          if (nows - window.lastClickTime).inMilliseconds < 200:
            window.eventsHandler.pushEvent onClick, ClickEvent(
              window: window, button: button, pos: window.mouse.pos, double: true
            )
            window.doubleClickHandled = true
          else:
            window.doubleClickHandled = false
        else:
          window.mouse.pressed.excl button
          if button in window.clicking:
            if not window.doubleClickHandled:
              window.eventsHandler.pushEvent onClick, ClickEvent(
                window: window, button: button, pos: window.mouse.pos, double: false
              )
              window.lastClickTime = nows
            window.clicking.excl button

        window.eventsHandler.pushEvent onMouseButton, MouseButtonEvent(window: window, button: button, pressed: state == `WlPointer / Button_state`.pressed, generated: false)

      window.seat_pointer.onAxis:
        if not window.isPointerInside: return

        if axis == `WlPointer / Axis`.vertical_scroll:
          window.eventsHandler.pushEvent onScroll, ScrollEvent(window: window, delta: value, deltaX: 0)
        elif axis == `WlPointer / Axis`.horizontal_scroll:
          window.eventsHandler.pushEvent onScroll, ScrollEvent(window: window, delta: 0, deltaX: value)
        else:
          return


    if `WlSeat / Capability`.keyboard in seatCapabilities:
      window.seat_keyboard = seat.get_keyboard



proc initSoftwareRenderingWindow(
  window: WindowWaylandSoftwareRendering,
  size: IVec2, screen: ScreenWayland,
  fullscreen, frameless, transparent: bool, class: string
) =
  globals.init()
  expectExtension shm

  window.basicInitWindow size, screen
  
  window.setupWindow fullscreen, frameless, transparent, size, class

  window.buffer = shm.create(size, (if transparent: argb8888 else: xrgb8888))
  window.surface.attach(window.buffer.buffer, 0, 0)
  commit window.surface


method firstStep*(window: WindowWayland, makeVisible = true) =
  if makeVisible:
    window.visible = true

  # window.m_pos = window.handle.geometry.pos
  # window.mouse.pos = cursor().pos - window.m_pos
  
  window.eventsHandler.pushEvent onResize, ResizeEvent(window: window, size: window.m_size, initial: true)
  window.lastTickTime = getTime()
  redraw window


method step*(window: WindowWayland) =
  ## make window main loop step
  ## ! don't forget to call firstStep()
  template closeIfNeeded =
    if window.m_closed: 
      release window
      return
  
  wl_display_roundtrip(globals.display)
  closeIfNeeded()

  let nows = getTime()
  window.eventsHandler.pushEvent onTick, TickEvent(window: window, deltaTime: nows - window.lastTickTime)
  closeIfNeeded()
  window.lastTickTime = nows

  if window.redrawRequested:
    window.redrawRequested = false
    window.eventsHandler.pushEvent onRender, RenderEvent(window: window)
    closeIfNeeded()

    window.swapBuffers()


proc newSoftwareRenderingWindowWayland*(
  size = ivec2(1280, 720),
  title = "",
  screen = defaultScreenWayland(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,

  class = "", # window class (used on linux), equals to title if not specified
): WindowWaylandSoftwareRendering =
  new result
  result.initSoftwareRenderingWindow(size, screen, fullscreen, frameless, transparent, (if class == "": title else: class))
  result.title = title
  if not resizable: result.resizable = false
