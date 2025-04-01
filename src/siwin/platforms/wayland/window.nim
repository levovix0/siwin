import std/[times, importutils, strformat, options, tables, os, uri, sequtils, strutils]
from std/posix import pipe, close, write, read
import pkg/[vmath]
import ../../[colorutils, siwindefs]
import ../any/[window {.all.}, clipboards]
import ../any/[windowUtils]
import ./[libwayland, protocol, siwinGlobals, sharedBuffer, bitfields, xkb]

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
    globals: SiwinGlobalsWayland
    surface: Wl_surface
    xdgSurface: Xdg_surface
    xdgToplevel: Xdg_toplevel

    serverDecoration: Zxdg_toplevel_decoration_v1
      # will be nil if compositor doesn't support this protocol

    plasmaSurface: Org_kde_plasma_surface
      # will be nil if compositor doesn't support this protocol
    
    layerShellSurface: Zwlr_layer_surface_v1
      # will be nil if compositor doesn't support this protocol (eg. GNOME)
    
    idleInhibitor: Zwp_idle_inhibitor_v1

    layer: Layer
    namespace: string

    lastClickTime: Duration
    doubleClickHandled: bool

    lastMouseButtonEventSerial: uint32
    enterSerial: uint32
    kind: WindowWaylandKind ## Is this a normal window or is it a layer shell surface?

    lastPressedKey: Key
    lastTextEntered: string
    lastPressedKeyTime: Time
    lastKeyRepeatedTime: Time
  
  ClipboardWayland* = ref object of Clipboard
    globals: SiwinGlobalsWayland
    userContent: ClipboardConvertableContent
    dataSource: Wl_data_source
  
  ClipboardWaylandDnd* = ref object of Clipboard
    globals: SiwinGlobalsWayland


  WindowWaylandSoftwareRendering* = ref WindowWaylandSoftwareRenderingObj
  WindowWaylandSoftwareRenderingObj* = object of WindowWayland
    buffer: SharedBuffer
    oldBuffer: SharedBuffer


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

proc screenCountWayland*(globals: SiwinGlobalsWayland): int32 =
  ## todo
  1

proc screenWayland*(globals: SiwinGlobalsWayland, number: int32): ScreenWayland =
  new result
  if number notin 0..<globals.screenCountWayland(): raise IndexDefect.newException(&"screen {number} doesn't exist")
  result.id = number.cint

proc defaultScreenWayland*(globals: SiwinGlobalsWayland): ScreenWayland =
  ScreenWayland(id: 0.cint)

method number*(screen: ScreenWayland): int32 = screen.id

method width*(screen: ScreenWayland): int32 = 1920  # todo
method height*(screen: ScreenWayland): int32 = 1080  # todo


method release(window: WindowWayland) {.base, raises: [].}


proc `=destroy`(window: WindowWaylandObj) {.siwin_destructor.} =
  release cast[WindowWayland](window.addr)

  for x in window.fields:
    when compiles(`=destroy`(x)):
      try:
        `=destroy`(x)
      except: discard


proc `=trace`(x: var WindowWaylandSoftwareRenderingObj, env: pointer) =
  #? for some reason, without this, nim produces invalid C code for =trace implementation
  `=trace`(cast[ptr WindowWaylandObj](x.addr)[], env)


proc `=destroy`(window: WindowWaylandSoftwareRenderingObj) {.siwin_destructor.} =
  release cast[WindowWaylandSoftwareRendering](window.addr)

  for x in window.fields:
    when compiles(`=destroy`(x)):
      try:
        `=destroy`(x)
      except: discard


method release(window: WindowWayland) {.base, raises: [].} =
  ## destroy wayland part of window
  template destroy(x, f) =
    if x != typeof(x).default:
      f x
      x = typeof(x).default

  if window.surface != nil:
    if window.globals.associatedWindows_queueRemove_insteadOf_removingInstantly:
      window.globals.associatedWindows_removeQueue.add window.surface.proxy.raw.id
    else:
      window.globals.associatedWindows.del window.surface.proxy.raw.id

  try:
    destroy window.idleInhibitor, destroy
    destroy window.layerShellSurface, destroy
    destroy window.plasmaSurface, destroy
    destroy window.serverDecoration, destroy
    destroy window.xdgToplevel, destroy
    destroy window.xdgSurface, destroy
    destroy window.surface, destroy
  except:
    discard


proc removeQueuedAssociatedWindows(globals: SiwinGlobalsWayland) =
  for id in globals.associatedWindows_removeQueue:
    globals.associatedWindows.del id
  globals.associatedWindows_removeQueue = @[]


method release(window: WindowWaylandSoftwareRendering) =
  ## destroy wayland part of window
  
  try:
    if window.buffer != nil:
      release window.buffer
      window.buffer = nil  # should call destructor
    
    if window.oldBuffer != nil:
      release window.oldBuffer
      window.oldBuffer = nil
  except: discard

  procCall window.WindowWayland.release()


proc pushEvent[T](event: proc(e: T), args: T) =
  if event != nil: event(args)


method close*(window: WindowWayland) =
  window.m_closed = true
  window.eventsHandler.onClose.pushEvent CloseEvent(window: window)
  release window


proc initClipboardsIfNeeded(globals: SiwinGlobalsWayland) =
  if globals.primaryClipboard == nil:
    globals.primaryClipboard = ClipboardWayland(globals: globals)
  if globals.selectionClipboard == nil:
    globals.selectionClipboard = ClipboardWayland(globals: globals)
  if globals.dragndropClipboard == nil:
    globals.dragndropClipboard = ClipboardWaylandDnd(globals: globals)


proc basicInitWindow(window: WindowWayland; size: IVec2; screen: ScreenWayland) =
  window.m_size = size
  window.m_focused = false
  window.m_resizable = true
  window.m_frameless = true

  window.globals.initClipboardsIfNeeded()

  window.m_clipboard = window.globals.primaryClipboard
  window.m_selectionClipboard = window.globals.selectionClipboard
  window.m_dragndropClipboard = window.globals.dragndropClipboard


method doResize(window: WindowWayland, size: IVec2) {.base.} =
  window.m_size = size

  if not window.m_transparent:
    let opaqueRegion = window.globals.compositor.create_region
    opaqueRegion.add(0, 0, window.m_size.x, window.m_size.y)
    window.surface.set_opaque_region(opaqueRegion)
    destroy opaqueRegion


method doResize(window: WindowWaylandSoftwareRendering, size: IVec2) =
  procCall window.WindowWayland.doResize(size)

  if window.buffer.locked:
    swap window.buffer, window.oldBuffer

  if window.buffer == nil:
    window.buffer = window.globals.create(window.globals.shm, size, (if window.m_transparent: argb8888 else: xrgb8888), bufferCount = 2)
  else:
    window.buffer.resize(size)

  # no need to attach buffer yet


proc resize(window: WindowWayland, size: IVec2) =
  if size.x <= 0 or size.y <= 0:
    ## todo: means we should decide the size by ourselves
    return
    
  window.doResize size
  
  case window.kind
  of WindowWaylandKind.XdgSurface:
    if not window.m_resizable:
      window.xdgToplevel.set_min_size(window.m_size.x, window.m_size.y)
      window.xdgToplevel.set_max_size(window.m_size.x, window.m_size.y)

    window.eventsHandler.onResize.pushEvent ResizeEvent(window: window, size: window.m_size)

  of WindowWaylandKind.LayerSurface:
    window.layerShellSurface.set_size(window.m_size.x.uint32, window.m_size.y.uint32)
    window.eventsHandler.onResize.pushEvent ResizeEvent(window: window, size: window.m_size)
    window.redraw()


method `title=`*(window: WindowWayland, v: string) =
  case window.kind
  of WindowWaylandKind.XdgSurface:
    window.xdgToplevel.set_title(v)
  else: discard


proc setFrameless(window: WindowWayland, v: bool) =
  if window.globals.serverDecorationManager != nil:
    if window.serverDecoration == nil:
      window.serverDecoration = window.globals.serverDecorationManager.get_toplevel_decoration(window.xdg_toplevel)
      
      window.serverDecoration.onConfigure:
        let newFrameless = case mode
        of client_side: true
        else: false
        if newFrameless == window.m_frameless: return
        
        window.m_frameless = newFrameless
        window.eventsHandler.onStateBoolChanged.pushEvent StateBoolChangedEvent(
          window: window, kind: StateBoolChangedEventKind.frameless, value: window.m_frameless, isExternal: true
        )

    window.serverDecoration.set_mode:
      if v: client_side
      else: server_side
    
    window.eventsHandler.onStateBoolChanged.pushEvent StateBoolChangedEvent(
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

  if v.x <= 0 or v.y <= 0:
    raise RangeDefect.newException("size must be > 0")

  window.resize(v)
  redraw window


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
  if window.opened: window.eventsHandler.onWindowMove.pushEvent WindowMoveEvent(window: window, pos: v)


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
  window.buffer.swapBuffers()


method `maximized=`*(window: WindowWayland, v: bool) =
  if window.m_maximized == v: return
  if window.fullscreen:
    window.fullscreen = false
  window.m_maximized = v

  if v:
    window.xdgToplevel.set_maximized()
  else:
    window.xdgToplevel.unsetMaximized()

  if window.opened: window.eventsHandler.onStateBoolChanged.pushEvent StateBoolChangedEvent(
    window: window, kind: StateBoolChangedEventKind.maximized, value: window.m_maximized
  )


proc setLayer*(window: WindowWayland, layer: Layer) =
  let converted = `Zwlr_layer_shell_v1/Layer`(layer.int)

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
    if window.opened: window.eventsHandler.onKey.pushEvent KeyEvent(window: window, key: k, pressed: false, repeated: false, generated: true)


method `minimized=`*(window: WindowWayland, v: bool) =
  window.m_minimized = v
  if not v:
    ## todo
  else:
    if window.kind == WindowWaylandKind.XdgSurface:
      window.xdgToplevel.set_minimized()


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
  expectExtension window.globals.seat
  if window.kind == WindowWaylandKind.XdgSurface:
    window.xdgToplevel.move(window.globals.seat, window.lastMouseButtonEventSerial)

method startInteractiveResize*(window: WindowWayland, edge: Edge, pos: Option[Vec2]) =
  expectExtension window.globals.seat

  if window.kind == WindowWaylandKind.XdgSurface:
    window.xdgToplevel.resize(
      window.globals.seat, window.lastMouseButtonEventSerial,
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
  window.xdgToplevel.show_window_menu(window.globals.seat, window.lastMouseButtonEventSerial, pos.x, pos.y)


method setInputRegion*(window: WindowWayland, pos, size: Vec2) =
  procCall window.Window.setInputRegion(pos, size)
  
  let region = window.globals.compositor.create_region
  region.add(pos.x.int32, pos.y.int32, size.x.int32, size.y.int32)
  
  window.surface.set_input_region(region)
  # window.xdgSurface.set_window_geometry(pos.x.int32, pos.y.int32, size.x.int32, size.y.int32)
  
  destroy region


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


method `visible=`*(window: WindowWayland, v: bool) =
  if v == window.m_visible: return
  window.m_visible = v
  ## todo


proc initSeatEvents*(globals: SiwinGlobalsWayland) =
  if globals.seatEventsInitialized: return
  globals.seatEventsInitialized = true

  if globals.seat == nil: return

  if `WlSeat / Capability`.`pointer` in globals.seatCapabilities:
    globals.seat_pointer = globals.seat.get_pointer

    globals.seat_pointer.onEnter:
      if surface == nil: return
      let window = globals.associatedWindows.getOrDefault(surface.proxy.raw.id, nil).WindowWayland
      if window == nil: return
      globals.seat_pointer_currentWindow = window
      
      window.clicking = {}
      window.enterSerial = serial
      globals.lastSeatEventSerial = serial
      window.mouse.pos = vec2(surface_x, surface_y)

      replicateWindowTitleAndBorderBehaviour(window, window.mouse.pos)

      if window.opened: window.eventsHandler.onMouseMove.pushEvent MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.enter)
    

    globals.seat_pointer.onLeave:
      globals.seat_pointer_currentWindow = nil
      if surface == nil: return
      let window = globals.associatedWindows.getOrDefault(surface.proxy.raw.id, nil).WindowWayland
      if window == nil: return

      replicateWindowTitleAndBorderBehaviour(window, window.mouse.pos)
      
      window.clicking = {}
      if window.opened: window.eventsHandler.onMouseMove.pushEvent MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.leave)
      
      # we don't unpress buttons on leave, because we "capture" mouse
    

    globals.seat_pointer.onMotion:
      globals.associatedWindows_queueRemove_insteadOf_removingInstantly = true
      defer:
        globals.associatedWindows_queueRemove_insteadOf_removingInstantly = false
        globals.removeQueuedAssociatedWindows()

      for window in globals.associatedWindows.values:
        let window = window.WindowWayland
        if (
          (window.mouse.pressed.len == 0) and
          window != globals.seat_pointer_currentWindow.WindowWayland
        ): continue

        replicateWindowTitleAndBorderBehaviour(window, window.mouse.pos)

        window.clicking = {}
        window.mouse.pos = vec2(surface_x, surface_y)
        if window.opened: window.eventsHandler.onMouseMove.pushEvent MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.move)
    

    globals.seat_pointer.onButton:
      let button = case button
      of 0x110: MouseButton.left
      of 0x111: MouseButton.right
      of 0x112: MouseButton.middle
      of 0x115: MouseButton.forward
      of 0x116: MouseButton.backward
      else: return  # todo?

      let nows = initDuration(milliseconds = time.int64)

      # iterate over all windows, in case there are some which currently "holding" pressed mouse
      globals.associatedWindows_queueRemove_insteadOf_removingInstantly = true
      defer:
        globals.associatedWindows_queueRemove_insteadOf_removingInstantly = false
        globals.removeQueuedAssociatedWindows()
      
      for window in globals.associatedWindows.values:
        let window = window.WindowWayland
        if (
          (state != `WlPointer / Button_state`.released or button notin window.mouse.pressed) and
          window != globals.seat_pointer_currentWindow.WindowWayland
        ): continue

        window.lastMouseButtonEventSerial = serial
        globals.lastSeatEventSerial = serial
        if state == `WlPointer / Button_state`.pressed:
          window.mouse.pressed.incl button
          window.clicking.incl button

          if (nows - window.lastClickTime).inMilliseconds < 200:
            if window.opened: window.eventsHandler.onClick.pushEvent ClickEvent(
              window: window, button: button, pos: window.mouse.pos, double: true
            )
            window.doubleClickHandled = true
          else:
            window.doubleClickHandled = false
        else:
          window.mouse.pressed.excl button
          if button in window.clicking:
            if not window.doubleClickHandled:
              if window.opened: window.eventsHandler.onClick.pushEvent ClickEvent(
                window: window, button: button, pos: window.mouse.pos, double: false
              )
              window.lastClickTime = nows
            window.clicking.excl button

        if window.opened: window.eventsHandler.onMouseButton.pushEvent MouseButtonEvent(window: window, button: button, pressed: state == `WlPointer / Button_state`.pressed, generated: false)


    globals.seat_pointer.onAxis:
      if globals.seat_pointer_currentWindow == nil: return
      let window = globals.seat_pointer_currentWindow.WindowWayland

      const kde_default_mousewheel_scroll_length = 15

      if axis == `WlPointer / Axis`.vertical_scroll:
        if window.opened: window.eventsHandler.onScroll.pushEvent ScrollEvent(
          window: window, delta: value / kde_default_mousewheel_scroll_length, deltaX: 0
        )
      elif axis == `WlPointer / Axis`.horizontal_scroll:
        if window.opened: window.eventsHandler.onScroll.pushEvent ScrollEvent(
          window: window, delta: 0, deltaX: value / kde_default_mousewheel_scroll_length
        )
      else:
        return


  if `WlSeat / Capability`.keyboard in globals.seatCapabilities:
    globals.seat_keyboard = globals.seat.get_keyboard

    globals.seat_keyboard.onKeymap:
      updateKeymap(fd, size)


    globals.seat_keyboard.onEnter:
      if surface == nil or surface.proxy.raw.id notin globals.associatedWindows: return
      let window = globals.associatedWindows[surface.proxy.raw.id].WindowWayland
      globals.seat_keyboard_currentWindow = window
      globals.lastSeatEventSerial = serial
      
      for key in keys.toSeq(uint32):
        let siwinKey = waylandKeyToKey(key)
        if siwinKey == Key.unknown: continue

        window.keyboard.pressed.incl siwinKey
        if window.opened: window.eventsHandler.onKey.pushEvent KeyEvent(
          window: window, key: siwinKey, pressed: true, generated: true
        )
        window.lastPressedKey = siwinKey
        window.lastTextEntered = ""
        window.lastPressedKeyTime = getTime()


    globals.seat_keyboard.onLeave:
      globals.seat_keyboard_currentWindow = nil
      if surface == nil or surface.proxy.raw.id notin globals.associatedWindows: return
      let window = globals.associatedWindows[surface.proxy.raw.id].WindowWayland
      globals.lastSeatEventSerial = serial

      window.releaseAllKeys()
    

    globals.seat_keyboard.onKey:
      if globals.seat_keyboard_currentWindow == nil: return
      let window = globals.seat_keyboard_currentWindow.WindowWayland

      let pressed = state == `WlKeyboard / Key_state`.pressed

      if pressed:
        window.lastPressedKeyTime = getTime()
      globals.lastSeatEventSerial = serial
      
      let siwinKey = waylandKeyToKey(key)

      if siwinKey != Key.unknown:
        if pressed:
          window.keyboard.pressed.incl siwinKey
        else:
          window.keyboard.pressed.excl siwinKey

        if window.opened: window.eventsHandler.onKey.pushEvent KeyEvent(
          window: window, key: siwinKey, pressed: pressed
        )

        if pressed:
          if siwinKey notin Key.lcontrol..Key.rsystem:
            window.lastPressedKey = siwinKey
          else:
            window.lastPressedKey = Key.unknown
      else:
        window.lastPressedKey = Key.unknown

      var text = waylandKeyToString(key)
      if Key.lcontrol in window.keyboard.pressed or Key.rcontrol in window.keyboard.pressed: text = ""
      if text.len == 1 and text[0] < 32.char: text = ""

      if pressed and text != "":
        if window.opened: window.eventsHandler.onTextInput.pushEvent TextInputEvent(
          window: window, text: text
        )

        window.lastTextEntered = text

    
    globals.seat_keyboard.onModifiers:
      globals.lastSeatEventSerial = serial
      discard global_xkb_state.xkb_state_update_mask(mods_depressed, mods_latched, mods_locked, 0, 0, group)
    

    globals.seat_keyboard.onRepeat_info:
      globals.seat_keyboard_repeatSettings = (rate: rate, delay: delay)


proc setIdleInhibit*(window: WindowWayland, state: bool) =
  #? should the proc be named `idleInhibit=`?
  if window.globals.idleInhibitManager == nil:
    return

  if state:
    if window.idleInhibitor != nil:
      #? should we return without an error here instead?
      raise newException(ValueError, "`setIdleInhibit(true)` was called even though this window already has an active inhibitor")

    window.idleInhibitor = window.globals.idleInhibitManager.create_inhibitor(window.surface)
  else:
    if window.idleInhibitor == nil:
      #? should we return without an error here instead?
      raise newException(ValueError, "`setIdleInhibit(false)` was called even though the window has no active inhibitor")
    
    window.idleInhibitor.destroy()
    window.idleInhibitor.proxy.raw = nil


proc initDataDeviceManagerEvents*(globals: SiwinGlobalsWayland) =
  if globals.dataDeviceManagerEventsInitialized: return
  globals.dataDeviceManagerEventsInitialized = true

  if globals.dataDeviceManager == nil: return
  if globals.seat == nil: return

  globals.data_device = globals.dataDeviceManager.get_data_device(globals.seat)

  globals.data_device.onDataOffer:
    if globals.unindentified_data_offer != nil:
      destroy globals.unindentified_data_offer
      globals.unindentified_data_offer_mimeTypes = @[]

    globals.unindentified_data_offer = id.proxy.raw.construct(
      globals.interfaces.`iface Wl_data_offer`.addr, Wl_data_offer, `Wl_data_offer/dispatch`, `Wl_data_offer/Callbacks`
    )

    globals.unindentified_data_offer.onOffer:
      globals.unindentified_data_offer_mimeTypes.add $mime_type

  globals.data_device.onSelection:
    if globals.current_selection_data_offer != nil:
      destroy globals.current_selection_data_offer
    
    globals.current_selection_data_offer = globals.unindentified_data_offer
    var offered_mime_types = globals.unindentified_data_offer_mimeTypes
    
    globals.unindentified_data_offer.proxy.raw = nil
    globals.unindentified_data_offer_mimeTypes = @[]
  
    globals.initClipboardsIfNeeded()
  
    globals.primaryClipboard.availableKinds = {}
    globals.primaryClipboard.availableMimeTypes = @[]

    if globals.current_selection_data_offer == nil:
      return

    globals.current_selection_data_offer.onOffer:
      offered_mime_types.add $mime_type
    
    discard wl_display_roundtrip globals.display  # get all the mime types
    
    for mime_type in offered_mime_types:
      if mime_type in ["UTF8_STRING", "STRING", "TEXT", "text/plain", "text/plain;charset=utf-8"]:
        globals.primaryClipboard.availableKinds.incl ClipboardContentKind.text

      if mime_type in ["text/uri-list"]:
        globals.primaryClipboard.availableKinds.incl ClipboardContentKind.files

      if mime_type notin globals.primaryClipboard.availableMimeTypes:
        globals.primaryClipboard.availableMimeTypes.add mime_type

    globals.primaryClipboard.onContentChanged.pushEvent ClipboardContentChangedEvent(
      clipboard: globals.primaryClipboard,
      availableKinds: globals.primaryClipboard.availableKinds,
      availableMimeTypes: globals.primaryClipboard.availableMimeTypes,
    )

  discard wl_display_roundtrip globals.display


proc setupWindow(window: WindowWayland, fullscreen, frameless, transparent: bool, size: IVec2, class: string) =
  expectExtension window.globals.compositor
  expectExtension window.globals.xdgWmBase
  
  window.globals.initSeatEvents()
  
  window.surface = window.globals.compositor.create_surface
  window.globals.associatedWindows[window.surface.proxy.raw.id] = window

  case window.kind
  of WindowWaylandKind.XdgSurface:
    window.xdgSurface = window.globals.xdgWmBase.get_xdg_surface(window.surface)
    window.xdgToplevel = window.xdgSurface.get_toplevel

    window.xdgSurface.onConfigure:
      window.xdgSurface.ack_configure(serial)
      redraw window

    window.fullscreen = fullscreen
    window.frameless = frameless

    window.m_transparent = transparent
    if not transparent:
      let opaqueRegion = window.globals.compositor.create_region
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
          if window.opened: window.eventsHandler.onStateBoolChanged.pushEvent StateBoolChangedEvent(
            window: window, kind: StateBoolChangedEventKind.k, value: window.m, isExternal: true
          )
    
      handleState maximized, maximized, m_maximized
      handleState fullscreen, fullscreen, m_fullscreen
      handleState focus, activated, m_focused
  
    if window.globals.plasmaShell != nil:
      window.plasmaSurface = window.globals.plasmaShell.get_surface(window.surface)
  
  of LayerSurface:
    window.layerShellSurface = window.globals.layerShell.get_layer_surface(
      window.surface,
      Wl_output(proxy: Wl_proxy(raw: nil)),
      `Zwlr_layer_shell_v1/Layer`(window.layer.int),
      window.namespace.cstring
    )
    window.layerShellSurface.set_size(window.size.x.uint32, window.size.y.uint32)
    window.redraw()

    window.layerShellSurface.onConfigure:
      window.layerShellSurface.ack_configure(serial)
      window.resize(ivec2(width.int32, height.int32))

    window.layerShellSurface.onClosed:
      window.m_closed = true
      window.surface.destroy()


proc initSoftwareRenderingWindow(
  window: WindowWaylandSoftwareRendering,
  size: IVec2, screen: ScreenWayland,
  fullscreen, frameless, transparent: bool, class: string
) =
  expectExtension window.globals.shm

  window.basicInitWindow size, screen
  
  window.setupWindow fullscreen, frameless, transparent, size, class

  window.buffer = window.globals.create(window.globals.shm, size, (if transparent: argb8888 else: xrgb8888), bufferCount = 2)


proc setAnchor*(window: WindowWayland, edge: LayerEdge | seq[LayerEdge]) =
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
    if edge.len < 2:
      raise newException(ValueError, "Not enough edges provided")

    func convert(x: LayerEdge): `Zwlr_layer_surface_v1/Anchor` {.inline.} =
      case x
      of LayerEdge.Top:
        `Zwlr_layer_surface_v1/Anchor`.top
      of LayerEdge.Left:
        `Zwlr_layer_surface_v1/Anchor`.left
      of LayerEdge.Right:
        `Zwlr_layer_surface_v1/Anchor`.right
      of LayerEdge.Bottom:
        `Zwlr_layer_surface_v1/Anchor`.bottom

    var final = edge[0].uint

    for val in edge[1 ..< edge.len]:
      final = final or val.uint

    window.layerShellSurface.set_anchor(cast[`Zwlr_layer_surface_v1/Anchor`](final))

  window.redraw()

proc setKeyboardInteractivity*(window: WindowWayland, mode: LayerInteractivityMode) =
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


proc setExclusiveZone*(window: WindowWayland, zone: int32) =
  if window.layerShellSurface == nil:
    raise newException(
      ValueError,
      "Attempt to set keyboard interactivity when layer shell surface hasn't been initialized." &
      "\nHint: Pass `kind` as `WindowWaylandKind.LayerSurface` when constructing this window."
    )

  window.layerShellSurface.set_exclusive_zone(zone)


proc constructClipboardContent*(
  data: sink string, kind: ClipboardContentKind, mimeType: string
): ClipboardContent =
  case kind
  of ClipboardContentKind.text:
    result = ClipboardContent(kind: ClipboardContentKind.text, text: data)
  
  of ClipboardContentKind.files:
    let uris = data.splitLines
    var files: seq[string]
    
    for uri in uris:
      let uri = parseUri(uri)
      if uri.scheme == "file":
        files.add uri.path.decodeUrl
    
    result = ClipboardContent(kind: ClipboardContentKind.files, files: files)
  
  of ClipboardContentKind.other:
    result = ClipboardContent(kind: ClipboardContentKind.other, mimeType: mimeType, data: data)


proc toString*(
  content: ClipboardConvertableContent, targetType: string
): string =
  var conv: ClipboardContentConverter
  for cv in content.converters:
    case cv.kind
    of ClipboardContentKind.text:
      if targetType in ["UTF8_STRING", "STRING", "TEXT", "text/plain", "text/plain;charset=utf-8"]:
        conv = cv
        break
    
    of ClipboardContentKind.files:
      if targetType in ["text/uri-list"]:
        conv = cv
        break
    
    of ClipboardContentKind.other:
      if targetType == cv.mimeType:
        conv = cv
        break
  
  if conv.f == nil:
    return ""

  var content = conv.f(content.data, conv.kind, conv.mimeType)

  case conv.kind
  of ClipboardContentKind.text:
    result = content.text
  
  of ClipboardContentKind.files:
    result = content.files.mapIt($Uri(scheme: "file", path: it.encodeUrl(usePlus=false))).join("\n")
  
  of ClipboardContentKind.other:
    result = content.data



method content*(
  clipboard: ClipboardWayland, kind: ClipboardContentKind, mimeType: string = "text/plain"
): ClipboardContent =
  clipboard.globals.initDataDeviceManagerEvents()
  
  var mimeType =
    case kind
    of ClipboardContentKind.text:
      if "text/plain;charset=utf-8" in clipboard.availableMimeTypes: "text/plain;charset=utf-8"
      elif "UTF8_STRING" in clipboard.availableMimeTypes: "UTF8_STRING"
      elif "STRING" in clipboard.availableMimeTypes: "STRING"
      elif "TEXT" in clipboard.availableMimeTypes: "TEXT"
      else: "text/plain"
    
    of ClipboardContentKind.files:
      "text/uri-list"
    
    of ClipboardContentKind.other:
      mimeType

  if mimeType notin clipboard.availableMimeTypes:
    return constructClipboardContent("", kind, mimeType)


  if clipboard == clipboard.globals.primaryClipboard.ClipboardWayland:
    if clipboard.globals.current_selection_data_offer == nil:
      return constructClipboardContent("", kind, mimeType)

    var fds: array[2, FileHandle]  # [0] - read, [1] - write
    if pipe(fds) < 0:  #? use O_NONBLOCK?
      raiseOSError(osLastError())

    clipboard.globals.current_selection_data_offer.receive(mimeType.cstring, fds[1])
    discard close fds[1]

    discard wl_display_roundtrip clipboard.globals.display

    var data: string
    var cbuffer: array[1024, char]

    while (let c = read(fds[0], cbuffer[0].addr, 1024); c != 0):
      data.add $cast[cstring](cbuffer[0].addr)
      if c != 1024: break

    discard close fds[0]

    return constructClipboardContent(data, kind, mimeType)


method `content=`*(clipboard: ClipboardWayland, content: ClipboardConvertableContent) =
  clipboard.userContent = content

  if clipboard.dataSource != nil:
    destroy clipboard.dataSource
  
  if content.converters.len != 0:
    clipboard.dataSource = clipboard.globals.dataDeviceManager.create_data_source()

    var offeredMimeTypes: seq[string]
    proc incl(arr: var seq[string], item: string) =
      if item notin arr:
        arr.add item

    for cv in content.converters:
      case cv.kind
      of ClipboardContentKind.text:
        offeredMimeTypes.incl "text/plain;charset=utf-8"
        offeredMimeTypes.incl "UTF8_STRING"
        offeredMimeTypes.incl "STRING"
        offeredMimeTypes.incl "TEXT"
        offeredMimeTypes.incl "text/plain"

      of ClipboardContentKind.files:
        offeredMimeTypes.incl "text/uri-list"
      
      of ClipboardContentKind.other:
        offeredMimeTypes.incl cv.mimeType
    
    if offeredMimeTypes.len > 0:
      for mimeType in offeredMimeTypes:
        clipboard.dataSource.offer(mimeType.cstring)
    
    clipboard.dataSource.onSend:
      let data = content.toString($mimeType)

      discard write(fd, data.cstring, data.len)
      discard close fd

  else:
    clipboard.dataSource.proxy.raw = nil

  if clipboard == clipboard.globals.primaryClipboard.CLipboardWayland:
    clipboard.globals.dataDevice.set_selection(clipboard.dataSource, clipboard.globals.lastSeatEventSerial)
  
  discard wl_display_roundtrip clipboard.globals.display


method firstStep*(window: WindowWayland, makeVisible = true) =
  if makeVisible:
    window.visible = true

  # window.m_pos = window.handle.geometry.pos
  # window.mouse.pos = cursor().pos - window.m_pos
  
  if window.opened: window.eventsHandler.onResize.pushEvent ResizeEvent(window: window, size: window.m_size, initial: true)
  window.lastTickTime = getTime()
  redraw window


method step*(window: WindowWayland) =
  ## make window main loop step
  ## ! don't forget to call firstStep()

  template closeIfNeeded =
    if window.m_closed:
      window.eventsHandler.onClose.pushEvent CloseEvent(window: window)
      release window
      return

  closeIfNeeded()
  
  let eventCount = wl_display_roundtrip(window.globals.display)
  if eventCount < 0:
    raise newException(RoundtripFailed, "wl_display_roundtrip() returned " & $eventCount)

  closeIfNeeded()
  if eventCount <= 2:  # seems like idle event count is 2
    sleep(1)

  if window.globals.seat_keyboard_currentWindow == window:
    # repeat keys if needed
    if (
      (window.globals.seat_keyboard_repeatSettings.rate > 0 and window.globals.seat_keyboard_repeatSettings.rate < 1000) and
      (window.keyboard.pressed - {Key.lcontrol, Key.lshift, Key.lalt, Key.rcontrol, Key.rshift, Key.ralt}).len != 0
    ):
      let repeatStartTime = window.lastPressedKeyTime + initDuration(milliseconds = window.globals.seat_keyboard_repeatSettings.delay)
      let nows = getTime()
      let interval = initDuration(milliseconds = 1000 div window.globals.seat_keyboard_repeatSettings.rate)

      if repeatStartTime <= nows and window.lastKeyRepeatedTime < repeatStartTime - interval:
        window.lastKeyRepeatedTime = repeatStartTime - interval
      
      while repeatStartTime <= nows and window.lastKeyRepeatedTime + interval <= nows:
        window.lastKeyRepeatedTime += interval
        
        if window.lastPressedKey != Key.unknown and window.keyboard.pressed.contains(window.lastPressedKey):
          window.keyboard.pressed.excl window.lastPressedKey
          if window.opened: window.eventsHandler.onKey.pushEvent KeyEvent(
            window: window, key: window.lastPressedKey, pressed: false, repeated: true
          )
          window.keyboard.pressed.incl window.lastPressedKey
          if window.opened: window.eventsHandler.onKey.pushEvent KeyEvent(
            window: window, key: window.lastPressedKey, pressed: true, repeated: true
          )

        if window.lastTextEntered != "":
          if window.opened: window.eventsHandler.onTextInput.pushEvent TextInputEvent(
            window: window, text: window.lastTextEntered, repeated: true
          )

  let nows = getTime()
  if window.opened: window.eventsHandler.onTick.pushEvent TickEvent(window: window, deltaTime: nows - window.lastTickTime)
  closeIfNeeded()
  window.lastTickTime = nows

  if window.redrawRequested:
    window.redrawRequested = false

    if window.m_visible:
      if window.opened: window.eventsHandler.onRender.pushEvent RenderEvent(window: window)
      closeIfNeeded()

      window.swapBuffers()

      wl_display_flush window.globals.display


proc newSoftwareRenderingWindowWayland*(
  globals: SiwinGlobalsWayland,
  size = ivec2(1280, 720),
  title = "",
  screen: ScreenWayland,
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,

  class = "", # window class (used on linux), equals to title if not specified
): WindowWaylandSoftwareRendering =
  new result
  result.globals = globals
  result.initSoftwareRenderingWindow(size, screen, fullscreen, frameless, transparent, (if class == "": title else: class))
  result.title = title
  if not resizable: result.resizable = false

export Layer, LayerEdge, LayerInteractivityMode
