import std/[times, importutils, strformat, options, tables, os]
import pkg/[vmath]
import ../../[utils, colorutils, siwindefs]
import ../any/window {.all.}
import ../any/[windowUtils]
import ./[libwayland, protocol, globals, sharedBuffer, bitfields, xkb]

{.experimental: "overloadableEnums".}

privateAccess Window

type
  ScreenWayland* = ref object of Screen
    id: cint

  WindowWaylandKind* {.pure.} = enum
    XdgSurface
    LayerSurface
  
  WindowWayland* = ref WindowWaylandObj
  WindowWaylandObj* = object of Window
    surface: Wl_surface
    xdgSurface: Xdg_surface
    xdgToplevel: Xdg_toplevel

    serverDecoration: Zxdg_toplevel_decoration_v1
      # will be nil if compositor doesn't support this protocol

    plasmaSurface: Org_kde_plasma_surface
      # will be nil if compositor doesn't support this protocol
    
    layerShellSurface: Zwlr_layer_surface_v1
      # will be nil if compositor doesn't support this protocol (eg. GNOME)
    layer: Layer
    namespace: string

    lastClickTime: Duration
    doubleClickHandled: bool

    lastMouseButtonEventSerial: uint32
    enterSerial: uint32
    kind: WindowWaylandKind ## is this a normal window or is it a layer shell surface?

    lastKeyPressed: Key
    lastTextEntered: string
    lastKeyPressedTime: Time
    lastKeyRepeatedTime: Time


  WindowWaylandSoftwareRendering* = ref WindowWaylandSoftwareRenderingObj
  WindowWaylandSoftwareRenderingObj* = object of WindowWayland
    buffer: SharedBuffer


var
  associatedWindows: Table[uint32, WindowWayland]  # surface proxy id -> window

  seat_pointer_currentWindow: WindowWayland
  seat_keyboard_currentWindow: WindowWayland
  seat_touch_currentWindow: WindowWayland

  seat_keyboard_repeatSettings: tuple[rate, delay: int32]


proc waylandKeyToKey(keycode: uint32): Key =
  case global_xkb_state_unmodified.xkb_state_key_get_one_sym(keycode + 8)
  of XKB_KEY_shiftL:       Key.lshift
  of XKB_KEY_shiftR:       Key.rshift
  of XKB_KEY_controlL:     Key.lcontrol
  of XKB_KEY_controlR:     Key.rcontrol
  of XKB_KEY_altL:         Key.lalt
  of XKB_KEY_altR:         Key.ralt
  of XKB_KEY_superL:       Key.lsystem
  of XKB_KEY_superR:       Key.rsystem
  of XKB_KEY_menu:         Key.menu
  of XKB_KEY_escape:       Key.escape
  of XKB_KEY_semicolon:    Key.semicolon
  of XKB_KEY_slash:        Key.slash
  of XKB_KEY_equal:        Key.equal
  of XKB_KEY_minus:        Key.minus
  of XKB_KEY_bracketleft:  Key.lbracket
  of XKB_KEY_bracketright: Key.rbracket
  of XKB_KEY_comma:        Key.comma
  of XKB_KEY_period:       Key.dot
  of XKB_KEY_apostrophe:   Key.quote
  of XKB_KEY_backslash:    Key.backslash
  of XKB_KEY_grave:        Key.tilde
  of XKB_KEY_space:        Key.space
  of XKB_KEY_return:       Key.enter
  of XKB_KEY_kpEnter:      Key.enter
  of XKB_KEY_backspace:    Key.backspace
  of XKB_KEY_tab:          Key.tab
  of XKB_KEY_prior:        Key.page_up
  of XKB_KEY_next:         Key.page_down
  of XKB_KEY_end:          Key.End
  of XKB_KEY_home:         Key.home
  of XKB_KEY_insert:       Key.insert
  of XKB_KEY_delete:       Key.del
  of XKB_KEY_kpAdd:        Key.add
  of XKB_KEY_kpSubtract:   Key.subtract
  of XKB_KEY_kpMultiply:   Key.multiply
  of XKB_KEY_kpDivide:     Key.divide
  of XKB_KEY_capsLock:     Key.capsLock
  of XKB_KEY_numLock:      Key.numLock
  of XKB_KEY_scrollLock:   Key.scrollLock
  of XKB_KEY_print:        Key.printScreen
  of XKB_KEY_kpSeparator:  Key.npadDot
  of XKB_KEY_pause:        Key.pause
  of XKB_KEY_f1:           Key.f1
  of XKB_KEY_f2:           Key.f2
  of XKB_KEY_f3:           Key.f3
  of XKB_KEY_f4:           Key.f4
  of XKB_KEY_f5:           Key.f5
  of XKB_KEY_f6:           Key.f6
  of XKB_KEY_f7:           Key.f7
  of XKB_KEY_f8:           Key.f8
  of XKB_KEY_f9:           Key.f9
  of XKB_KEY_f10:          Key.f10
  of XKB_KEY_f11:          Key.f11
  of XKB_KEY_f12:          Key.f12
  of XKB_KEY_f13:          Key.f13
  of XKB_KEY_f14:          Key.f14
  of XKB_KEY_f15:          Key.f15
  of XKB_KEY_left:         Key.left
  of XKB_KEY_right:        Key.right
  of XKB_KEY_up:           Key.up
  of XKB_KEY_down:         Key.down
  of XKB_KEY_kpInsert:     Key.npad0
  of XKB_KEY_kpEnd:        Key.npad1
  of XKB_KEY_kpDown:       Key.npad2
  of XKB_KEY_kpPagedown:   Key.npad3
  of XKB_KEY_kpLeft:       Key.npad4
  of XKB_KEY_kpBegin:      Key.npad5
  of XKB_KEY_kpRight:      Key.npad6
  of XKB_KEY_kpHome:       Key.npad7
  of XKB_KEY_kpUp:         Key.npad8
  of XKB_KEY_kpPageup:     Key.npad9
  of XKB_KEY_a:            Key.a
  of XKB_KEY_b:            Key.b
  of XKB_KEY_c:            Key.c
  of XKB_KEY_d:            Key.d
  of XKB_KEY_e:            Key.e
  of XKB_KEY_f:            Key.f
  of XKB_KEY_g:            Key.g
  of XKB_KEY_h:            Key.h
  of XKB_KEY_i:            Key.i
  of XKB_KEY_j:            Key.j
  of XKB_KEY_k:            Key.k
  of XKB_KEY_l:            Key.l
  of XKB_KEY_m:            Key.m
  of XKB_KEY_n:            Key.n
  of XKB_KEY_o:            Key.o
  of XKB_KEY_p:            Key.p
  of XKB_KEY_q:            Key.q
  of XKB_KEY_r:            Key.r
  of XKB_KEY_s:            Key.s
  of XKB_KEY_t:            Key.t
  of XKB_KEY_u:            Key.u
  of XKB_KEY_v:            Key.v
  of XKB_KEY_w:            Key.w
  of XKB_KEY_x:            Key.x
  of XKB_KEY_y:            Key.y
  of XKB_KEY_z:            Key.z
  of XKB_KEY_0:            Key.n0
  of XKB_KEY_1:            Key.n1
  of XKB_KEY_2:            Key.n2
  of XKB_KEY_3:            Key.n3
  of XKB_KEY_4:            Key.n4
  of XKB_KEY_5:            Key.n5
  of XKB_KEY_6:            Key.n6
  of XKB_KEY_7:            Key.n7
  of XKB_KEY_8:            Key.n8
  of XKB_KEY_9:            Key.n9
  of XKB_KEY_ISO_Level3_Shift:  Key.level3_shift
  of XKB_KEY_ISO_Level5_Shift:  Key.level5_shift
  else:               Key.unknown

proc waylandKeyToString(keycode: uint32): string =
  result = newStringOfCap(8)
  result.setLen 1
  result.setLen global_xkb_state.xkb_state_key_get_utf8(keycode + 8, cast[cstring](result[0].addr), 7)


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


method release(window: WindowWayland) {.base, raises: [].}


proc `=destroy`(window: WindowWaylandObj) {.siwin_destructor.} =
  release cast[WindowWayland](window.addr)

  for x in window.fields:
    when compiles(`=destroy`(x)):
      `=destroy`(x)


proc `=trace`(x: var WindowWaylandSoftwareRenderingObj, env: pointer) =
  #? for some reason, without this, nim produces invalid C code for =trace implementation
  `=trace`(cast[ptr WindowWaylandObj](x.addr)[], env)


proc `=destroy`(window: WindowWaylandSoftwareRenderingObj) {.siwin_destructor.} =
  release cast[WindowWaylandSoftwareRendering](window.addr)

  for x in window.fields:
    when compiles(`=destroy`(x)):
      `=destroy`(x)


method release(window: WindowWayland) {.base, raises: [].} =
  ## destroy wayland part of window
  template destroy(x, f) =
    if x != typeof(x).default:
      f x
      x = typeof(x).default

  if window.surface != nil:
    associatedWindows.del window.surface.proxy.raw.id
  
  destroy window.plasmaSurface, destroy
  destroy window.serverDecoration, destroy
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
  window.m_focused = false
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
  
  case window.kind
  of WindowWaylandKind.XdgSurface:
    if not window.m_resizable:
      window.xdgToplevel.set_min_size(window.m_size.x, window.m_size.y)
      window.xdgToplevel.set_max_size(window.m_size.x, window.m_size.y)

    commit window.surface

    window.eventsHandler.pushEvent onResize, ResizeEvent(window: window, size: window.m_size)
    redraw window
  of WindowWaylandKind.LayerSurface:
    window.layerShellSurface.set_size(window.m_size.x.uint32, window.m_size.y.uint32)
    window.surface.commit()
    window.redraw()

method `title=`*(window: WindowWayland, v: string) =
  case window.kind
  of WindowWaylandKind.XdgSurface:
    window.xdgToplevel.set_title(v)
  else: discard

proc setFrameless(window: WindowWayland, v: bool) =
  if serverDecorationManager != nil:
    if window.serverDecoration == nil:
      window.serverDecoration = serverDecorationManager.get_toplevel_decoration(window.xdg_toplevel)
      
      window.serverDecoration.onConfigure:
        let newFrameless = case mode
        of client_side: true
        else: false
        if newFrameless == window.m_frameless: return
        
        window.m_frameless = newFrameless
        window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
          window: window, kind: StateBoolChangedEventKind.frameless, value: window.m_frameless, isExternal: true
        )

    window.serverDecoration.set_mode:
      if v: client_side
      else: server_side
    
    window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
      window: window, kind: StateBoolChangedEventKind.frameless, value: window.m_frameless, isExternal: false
    )


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
  if window.m_pos == v: return
  window.m_pos = v

  if window.fullscreen:
    window.fullscreen = false
  
  if window.plasmaSurface != nil:
    window.plasmaSurface.set_position(v.x, v.y)
  
  else:
    # there are no protocol to force move window for Mutter (Gnome) and Weston compositors.
    # there are zwlr_layer_shell_v1 for wlroots-based (and kde) compositors,
    # but it doesnt seem to be the right protocol to use to move window
    discard
  
  # since no compositor notifies us about window movement, let's emulate such event
  window.eventsHandler.pushEvent onWindowMove, WindowMoveEvent(window: window, pos: v)


method `cursor=`*(window: WindowWayland, v: Cursor) =
  if v.kind == builtin and window.m_cursor.kind == builtin and v.builtin == window.m_cursor.builtin: return
  ## todo


method `icon=`*(window: WindowWayland, v: nil.typeof) =
  ## todo

method `icon=`*(window: WindowWayland, v: PixelBuffer) =
  if v.size.x * v.size.y == 0: window.icon = nil
  ## todo


method pixelBuffer*(window: WindowWaylandSoftwareRendering): PixelBuffer =
  PixelBuffer(
    data: window.buffer.dataAddr,
    size: window.m_size,
    format: (if window.transparent: PixelBufferFormat.xrgb_32bit else: PixelBufferFormat.urgb_32bit)
  )


method swapBuffers(window: WindowWaylandSoftwareRendering) =
  window.surface.attach(window.buffer.buffer, 0, 0)
  window.surface.damage_buffer(0, 0, window.m_size.x, window.m_size.y)
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

  window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
    window: window, kind: StateBoolChangedEventKind.maximized, value: window.m_maximized
  )

method setLayer*(window: WindowWayland, layer: Layer) =
  let converted = `Zwlr_layer_shell_v1/Layer`(layer)

  if window.layerShellSurface == nil:
    raise newException(
      ValueError, 
      "Attempt to set surface layer when layer shell surface hasn't been initialized." &
      "\nHint: Pass `kind` as `WindowWaylandKind.LayerSurface` when constructing this window."
    )

  window.layerShellSurface.set_layer(converted)

proc releaseAllKeys(window: WindowWayland) =
  ## release all pressed keys
  ## needed when window loses focus
  for k in window.keyboard.pressed.items.toSeq:
    window.keyboard.pressed.excl k
    window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: k, pressed: false, repeated: false, generated: true)


method `minimized=`*(window: WindowWayland, v: bool) =
  window.m_minimized = v
  if not v:
    ## todo
  else:
    if window.kind == WindowWaylandKind.XdgSurface:
      window.xdgToplevel.set_minimized()


method `visible=`*(window: WindowWayland, v: bool) =
  if v == window.m_visible: return
  window.m_visible = v
  ## todo


method `resizable=`*(window: WindowWayland, v: bool) =
  if window.kind != WindowWaylandKind.XdgSurface: return
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
  if window.kind == WindowWaylandKind.XdgSurface: window.xdgToplevel.set_min_size(v.x, v.y)


method `maxSize=`*(window: WindowWayland, v: IVec2) =
  window.m_maxSize = v
  if not window.m_resizable: return

  if window.kind == WindowWaylandKind.XdgSurface: window.xdgToplevel.set_max_size(v.x, v.y)

method startInteractiveMove*(window: WindowWayland, pos: Option[Vec2]) =
  expectExtension seat
  if window.kind == WindowWaylandKind.XdgSurface: window.xdgToplevel.move(seat, window.lastMouseButtonEventSerial)

method startInteractiveResize*(window: WindowWayland, edge: Edge, pos: Option[Vec2]) =
  expectExtension seat

  if window.kind == WindowWaylandKind.XdgSurface:
    window.xdgToplevel.resize(
      seat, window.lastMouseButtonEventSerial,
      case edge
      of Edge.topLeft:     `Xdg_toplevel/Resize_edge`.top_left
      of Edge.top:         `Xdg_toplevel/Resize_edge`.top
      of Edge.topRight:    `Xdg_toplevel/Resize_edge`.top_right
      of Edge.right:       `Xdg_toplevel/Resize_edge`.right
      of Edge.bottomRight: `Xdg_toplevel/Resize_edge`.bottom_right
      of Edge.bottom:      `Xdg_toplevel/Resize_edge`.bottom
      of Edge.bottomLeft:  `Xdg_toplevel/Resize_edge`.bottom_left
      of Edge.left:        `Xdg_toplevel/Resize_edge`.left
    )

method showWindowMenu*(window: WindowWayland, pos: Option[Vec2]) =
  let pos = pos.get(window.mouse.pos).ivec2
  window.xdgToplevel.show_window_menu(seat, window.lastMouseButtonEventSerial, pos.x, pos.y)


method setInputRegion*(window: WindowWayland, pos, size: Vec2) =
  procCall window.Window.setInputRegion(pos, size)
  let region = compositor.create_region
  region.add(pos.x.int32, pos.y.int32, size.x.int32, size.y.int32)
  window.surface.set_input_region(region)
  window.xdgSurface.set_window_geometry(pos.x.int32, pos.y.int32, size.x.int32, size.y.int32)


proc replicateWindowTitleAndBorderBehaviour(window: WindowWayland, prevMousePos: Vec2) =
  if window.mouse.pressed != {MouseButton.left} or window.clicking != {MouseButton.left}: return
  
  case window.windowPartAt(prevMousePos)
  of WindowPart.title:                window.startInteractiveMove(some prevMousePos)
  of WindowPart.border_top_left:      window.startInteractiveResize(Edge.topLeft, some prevMousePos)
  of WindowPart.border_top_right:     window.startInteractiveResize(Edge.topRight, some prevMousePos)
  of WindowPart.border_bottom_left:   window.startInteractiveResize(Edge.bottomLeft, some prevMousePos)
  of WindowPart.border_bottom_right:  window.startInteractiveResize(Edge.bottomRight, some prevMousePos)
  of WindowPart.border_top:           window.startInteractiveResize(Edge.top, some prevMousePos)
  of WindowPart.border_bottom:        window.startInteractiveResize(Edge.bottom, some prevMousePos)
  of WindowPart.border_left:          window.startInteractiveResize(Edge.left, some prevMousePos)
  of WindowPart.border_right:         window.startInteractiveResize(Edge.right, some prevMousePos)
  else: discard


proc initSeatEvents* =
  if seatEventsInitialized: return
  if not waylandAvailable: return
  seatEventsInitialized = true

  if seat == nil: return

  if `WlSeat / Capability`.`pointer` in seatCapabilities:
    seat_pointer = seat.get_pointer

    seat_pointer.onEnter:
      if surface == nil or surface.proxy.raw.id notin associatedWindows: return
      let window = associatedWindows[surface.proxy.raw.id]
      seat_pointer_currentWindow = window
      
      window.clicking = {}
      window.enterSerial = serial
      window.mouse.pos = vec2(surface_x, surface_y)

      replicateWindowTitleAndBorderBehaviour(window, window.mouse.pos)

      window.eventsHandler.pushEvent onMouseMove, MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.enter)
    

    seat_pointer.onLeave:
      seat_pointer_currentWindow = nil
      if surface == nil or surface.proxy.raw.id notin associatedWindows: return
      let window = associatedWindows[surface.proxy.raw.id]

      replicateWindowTitleAndBorderBehaviour(window, window.mouse.pos)
      
      window.clicking = {}
      window.eventsHandler.pushEvent onMouseMove, MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.leave)
      
      # we don't unpress buttons on leave, because we "capture" mouse
    

    seat_pointer.onMotion:
      for window in associatedWindows.values:
        if (
          (window.mouse.pressed.len == 0) and
          window != seat_pointer_currentWindow
        ): continue

        replicateWindowTitleAndBorderBehaviour(window, window.mouse.pos)

        window.clicking = {}
        window.mouse.pos = vec2(surface_x, surface_y)
        window.eventsHandler.pushEvent onMouseMove, MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.move)
    

    seat_pointer.onButton:
      let button = case button
      of 0x110: MouseButton.left
      of 0x111: MouseButton.right
      of 0x112: MouseButton.middle
      of 0x115: MouseButton.forward
      of 0x116: MouseButton.backward
      else: return  # todo?

      let nows = initDuration(milliseconds = time.int64)

      # iterate over all windows, in case there are some which currently "holding" pressed mouse
      for window in associatedWindows.values:
        if (
          (state != `WlPointer / Button_state`.released or button notin window.mouse.pressed) and
          window != seat_pointer_currentWindow
        ): continue

        window.lastMouseButtonEventSerial = serial
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


    seat_pointer.onAxis:
      if seat_pointer_currentWindow == nil: return
      let window = seat_pointer_currentWindow

      if axis == `WlPointer / Axis`.vertical_scroll:
        window.eventsHandler.pushEvent onScroll, ScrollEvent(window: window, delta: value, deltaX: 0)
      elif axis == `WlPointer / Axis`.horizontal_scroll:
        window.eventsHandler.pushEvent onScroll, ScrollEvent(window: window, delta: 0, deltaX: value)
      else:
        return


  if `WlSeat / Capability`.keyboard in seatCapabilities:
    seat_keyboard = seat.get_keyboard

    seat_keyboard.onKeymap:
      updateKeymap(fd, size)


    seat_keyboard.onEnter:
      if surface == nil or surface.proxy.raw.id notin associatedWindows: return
      let window = associatedWindows[surface.proxy.raw.id]
      seat_keyboard_currentWindow = window
      
      for key in keys.toSeq(uint32):
        let siwinKey = waylandKeyToKey(key)
        if siwinKey == Key.unknown: continue

        window.keyboard.pressed.incl siwinKey
        window.eventsHandler.pushEvent onKey, KeyEvent(
          window: window, key: siwinKey, pressed: true, generated: true
        )
        window.lastKeyPressed = siwinKey
        window.lastTextEntered = ""
        window.lastKeyPressedTime = getTime()


    seat_keyboard.onLeave:
      seat_keyboard_currentWindow = nil
      if surface == nil or surface.proxy.raw.id notin associatedWindows: return
      let window = associatedWindows[surface.proxy.raw.id]

      window.releaseAllKeys()
    

    seat_keyboard.onKey:
      if seat_keyboard_currentWindow == nil: return
      let window = seat_keyboard_currentWindow

      let pressed = state == `WlKeyboard / Key_state`.pressed

      if pressed:
        window.lastKeyPressedTime = getTime()
      
      let siwinKey = waylandKeyToKey(key)

      if siwinKey != Key.unknown:
        if pressed:
          window.keyboard.pressed.incl siwinKey
        else:
          window.keyboard.pressed.excl siwinKey

        window.eventsHandler.pushEvent onKey, KeyEvent(
          window: window, key: siwinKey, pressed: pressed
        )

        if pressed and siwinKey notin Key.lcontrol..Key.rsystem:
          window.lastKeyPressed = siwinKey

      var text = waylandKeyToString(key)
      if Key.lcontrol in window.keyboard.pressed or Key.rcontrol in window.keyboard.pressed: text = ""
      if text.len == 1 and text[0] < 32.char: text = ""

      if pressed and text != "":
        window.eventsHandler.pushEvent onTextInput, TextInputEvent(
          window: window, text: text
        )

        window.lastTextEntered = text

    
    seat_keyboard.onModifiers:
      discard global_xkb_state.xkb_state_update_mask(mods_depressed, mods_latched, mods_locked, 0, 0, group)
    

    seat_keyboard.onRepeat_info:
      seat_keyboard_repeatSettings = (rate: rate, delay: delay)

proc setupWindow(window: WindowWayland, fullscreen, frameless, transparent: bool, size: IVec2, class: string) =
  expectExtension compositor
  expectExtension xdgWmBase
  
  initSeatEvents()
  
  window.surface = compositor.create_surface
  associatedWindows[window.surface.proxy.raw.id] = window

  case window.kind
  of WindowWaylandKind.XdgSurface:
    window.xdgSurface = xdgWmBase.get_xdg_surface(window.surface)
    window.xdgToplevel = window.xdgSurface.get_toplevel

    window.xdgSurface.onConfigure:
      window.xdgSurface.ack_configure(serial)
      commit window.surface

    window.fullscreen = fullscreen

    window.m_frameless = frameless
    window.setFrameless(frameless)

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
      window.resize(ivec2(width, height))

      let states = states.toSeq(`XdgToplevel / State`)
    
      template checkState(state: `XdgToplevel / State`): bool = state in states
      template handleState(k, n, m: untyped) =
        if window.m != checkState(`XdgToplevel / State`.n):
          window.m = checkState(`XdgToplevel / State`.n)
          window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
            window: window, kind: StateBoolChangedEventKind.k, value: window.m, isExternal: true
          )
    
      handleState maximized, maximized, m_maximized
      handleState fullscreen, fullscreen, m_fullscreen
      handleState focus, activated, m_focused

      redraw window
  
    if plasmaShell != nil:
      window.plasmaSurface = plasmaShell.get_surface(window.surface)
  of LayerSurface:
    window.layerShellSurface = layerShell.get_layer_surface(
      window.surface,
      Wl_output(proxy: Wl_proxy(raw: nil)),
      `Zwlr_layer_shell_v1/Layer`(window.layer),
      window.namespace.cstring
    )
    window.layerShellSurface.set_size(400, 400)
    window.surface.commit()
    window.redraw()

    window.layerShellSurface.onConfigure:
      window.layerShellSurface.ack_configure(serial)
      window.resize(ivec2(width.int32, height.int32))
      redraw window

    window.layerShellSurface.onClosed:
      window.m_closed = true
      window.surface.destroy()

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

method setAnchor*(window: WindowWayland, edge: LayerEdge | array[2, LayerEdge], marginSize: int) {.base.} =
  if window.layerShellSurface == nil:
    raise newException(
      ValueError,
      "Attempt to set surface anchor when layer shell surface hasn't been initialized." &
      "\nHint: Pass `kind` as `WindowWaylandKind.LayerSurface` when constructing this window."
    )
  
  when edge is LayerEdge:
    window.layerShellSurface.set_anchor(
      case edge
      of LayerEdge.Top:
        `Zwlr_layer_surface_v1/Anchor`.top
      of LayerEdge.Left:
        `Zwlr_layer_surface_v1/Anchor`.left
      of LayerEdge.Right:
        `Zwlr_layer_surface_v1/Anchor`.right
      of LayerEdge.Bottom:
        `Zwlr_layer_surface_v1/Anchor`.bottom
    )
  else:
    proc mixWith(l1: `Zwlr_layer_surface_v1/Anchor`): `Zwlr_layer_surface_v1/Anchor` =
      `Zwlr_layer_surface_v1/Anchor`(case edge[1]
      of LayerEdge.Top:
        l1.uint or `Zwlr_layer_surface_v1/Anchor`.top.uint
      of LayerEdge.Left:
        l1.uint or `Zwlr_layer_surface_v1/Anchor`.left.uint
      of LayerEdge.Right:
        l1.uint or `Zwlr_layer_surface_v1/Anchor`.right.uint
      of LayerEdge.Bottom:
        l1.uint or `Zwlr_layer_surface_v1/Anchor`.bottom.uint)

    window.layerShellSurface.set_anchor(
      case edge[0]
      of LayerEdge.Top:
        mixWith `Zwlr_layer_surface_v1/Anchor`.top
      of LayerEdge.Left:
        mixWith `Zwlr_layer_surface_v1/Anchor`.left
      of LayerEdge.Right:
        mixWith `Zwlr_layer_surface_v1/Anchor`.right
      of LayerEdge.Bottom:
        mixWith `Zwlr_layer_surface_v1/Anchor`.bottom
    )

  window.redraw()

method setKeyboardInteractivity*(window: WindowWayland, mode: LayerInteractivityMode) =
  if window.layerShellSurface == nil:
    raise newException(
      ValueError, 
      "Attempt to set keyboard interactivity when layer shell surface hasn't been initialized." &
      "\nHint: Pass `kind` as `WindowWaylandKind.LayerSurface` when constructing this window."
    )

  window.layerShellSurface.set_keyboard_interactivity(
    case mode
    of LayerInteractivityMode.None:
      `Zwlr_layer_surface_v1/Keyboard_interactivity`.none
    of LayerInteractivityMode.Exclusive:
      `Zwlr_layer_surface_v1/Keyboard_interactivity`.exclusive
    of LayerInteractivityMode.OnDemand:
      `Zwlr_layer_surface_v1/Keyboard_interactivity`.on_demand
  )

method setExclusiveZone*(window: WindowWayland, zone: int32) =
  if window.layerShellSurface == nil:
    raise newException(
      ValueError, 
      "Attempt to set keyboard interactivity when layer shell surface hasn't been initialized." &
      "\nHint: Pass `kind` as `WindowWaylandKind.LayerSurface` when constructing this window."
    )

  window.layerShellSurface.set_exclusive_zone(zone)

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
      window.eventsHandler.pushEvent onClose, CloseEvent(window: window)
      return

  closeIfNeeded()
  
  let eventCount = wl_display_roundtrip(globals.display)
  if eventCount < 0:
    raise newException(RoundtripFailed, "wl_display_roundtrip() returned " & $eventCount)

  closeIfNeeded()
  if eventCount == 0: sleep(1)

  if seat_keyboard_currentWindow == window:
    # repeat keys if needed
    if (
      (seat_keyboard_repeatSettings.rate > 0 and seat_keyboard_repeatSettings.rate < 1000) and
      (window.keyboard.pressed - {Key.lcontrol, Key.lshift, Key.lalt, Key.rcontrol, Key.rshift, Key.ralt}).len != 0
    ):
      let repeatStartTime = window.lastKeyPressedTime + initDuration(milliseconds = seat_keyboard_repeatSettings.delay)
      let nows = getTime()
      let interval = initDuration(milliseconds = 1000 div seat_keyboard_repeatSettings.rate)

      if repeatStartTime <= nows and window.lastKeyRepeatedTime < repeatStartTime - interval:
        window.lastKeyRepeatedTime = repeatStartTime - interval
      
      while repeatStartTime <= nows and window.lastKeyRepeatedTime + interval <= nows:
        window.lastKeyRepeatedTime += interval
        
        if window.lastKeyPressed != Key.unknown:
          window.eventsHandler.pushEvent onKey, KeyEvent(
            window: window, key: window.lastKeyPressed, pressed: false, repeated: true
          )
          window.eventsHandler.pushEvent onKey, KeyEvent(
            window: window, key: window.lastKeyPressed, pressed: true, repeated: true
          )

        if window.lastTextEntered != "":
          window.eventsHandler.pushEvent onTextInput, TextInputEvent(
            window: window, text: window.lastTextEntered, repeated: true
          )

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

export Layer, LayerEdge, LayerInteractivityMode
