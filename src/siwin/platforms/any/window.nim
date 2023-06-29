import std/[times, options, sequtils]
import pkg/[vmath]
import ../../bgrx

{.experimental: "overloadableEnums".}

type
  MouseButton* {.pure.} = enum
    left right middle forward backward

  Key* {.pure.} = enum
    unknown = 0

    a b c d e f g h i j k l m n o p q r s t u v w x y z
    tilde n1 n2 n3 n4 n5 n6 n7 n8 n9 n0 minus equal
    f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15
    lcontrol rcontrol  lshift rshift  lalt ralt  lsystem rsystem  lbracket rbracket
    space escape enter tab backspace menu
    slash dot comma  semicolon quote  backslash

    pageUp pageDown  home End  insert del
    left right up down
    npad0 npad1 npad2 npad3 npad4 npad5 npad6 npad7 npad8 npad9 npadDot
    add subtract multiply divide
    capsLock numLock scrollLock printScreen

    pause

  Mouse* = object
    pos*: IVec2
    pressed*: set[MouseButton]

  Keyboard* = object
    pressed*: set[Key]

  
  CursorKind* {.pure.} = enum
    builtin
    image

  Cursor* = object
    case kind*: CursorKind
    of builtin: builtin*: BuiltinCursor
    of image: image*: ImageCursor

  BuiltinCursor* {.pure.} = enum
    arrow arrowUp arrowRight
    wait arrowWait
    pointingHand grab
    text cross
    sizeAll sizeHorisontal sizeVertical
    sizeTopLeft sizeTopRight sizeBottomLeft sizeBottomRight
    hided
  
  ImageCursor* = object
    size*, origin*: IVec2
    data*: seq[ColorBgrx]
  

  Edge* {.pure.} = enum
    left
    right
    top
    bottom
    topLeft
    topRight
    bottomLeft
    bottomRight
  

  Screen* = ref object of RootObj


  MouseMoveKind* {.pure.} = enum
    move
    enter
    leave

  AnyWindowEvent* = object of RootObj
    window*: Window
  
  CloseEvent* = object of AnyWindowEvent
  RenderEvent* = object of AnyWindowEvent

  TickEvent* = object of AnyWindowEvent
    deltaTime*: Duration
  
  ResizeEvent* = object of AnyWindowEvent
    size*: IVec2
    initial*: bool
  
  WindowMoveEvent* = object of AnyWindowEvent
    pos*: IVec2

  FocusChangedEvent* = object of AnyWindowEvent
    focus*: bool
  
  FullscreenChangedEvent* = object of AnyWindowEvent
    fullscreen*: bool

  MouseMoveEvent* = object of AnyWindowEvent
    pos*: IVec2
    kind*: MouseMoveKind
  
  MouseButtonEvent* = object of AnyWindowEvent
    button*: MouseButton
    pressed*: bool
  
  ScrollEvent* = object of AnyWindowEvent
    delta*: float
  
  ClickEvent* = object of AnyWindowEvent
    button*: MouseButton
    pos*: IVec2
    double*: bool

  KeyEvent* = object of AnyWindowEvent
    key*: Key
    pressed*: bool
    repeated*: bool
  
  TextInputEvent* = object of AnyWindowEvent
    text*: string

  WindowEventsHandler* = object
    onClose*:       proc(e: CloseEvent)
    onRender*:      proc(e: RenderEvent)
    onTick*:        proc(e: TickEvent)
    onResize*:      proc(e: ResizeEvent)
    onWindowMove*:  proc(e: WindowMoveEvent)

    onFocusChanged*:       proc(e: FocusChangedEvent)
    onFullscreenChanged*:  proc(e: FullscreenChangedEvent)

    onMouseMove*:    proc(e: MouseMoveEvent)
    onMouseButton*:  proc(e: MouseButtonEvent)
    onScroll*:       proc(e: ScrollEvent)
    onClick*:        proc(e: ClickEvent)

    onKey*:   proc(e: KeyEvent)
    onTextInput*:  proc(e: TextInputEvent)


  Window* = ref object of RootObj
    mouse*: Mouse
    keyboard*: Keyboard
    eventsHandler*: WindowEventsHandler

    clicking: set[MouseButton]
    
    redrawRequested: bool

    lastTickTime: times.Time

    m_closed: bool
    
    m_transparent: bool
    m_frameless: bool
    m_cursor: Cursor
    
    m_size: IVec2
    m_pos: IVec2
    m_focused: bool
    m_fullscreen: bool
    m_maximized: bool
    m_minimized: bool
    m_visible: bool
    m_resizable: bool
    m_minSize: IVec2
    m_maxSize: IVec2


method number*(screen: Screen): int32 {.base.} = discard

method width*(screen: Screen): int32 {.base.} = discard
method height*(screen: Screen): int32 {.base.} = discard

proc size*(screen: Screen): IVec2 = ivec2(screen.width, screen.height)


proc closed*(window: Window): bool = window.m_closed
proc opened*(window: Window): bool = not window.closed

method close*(window: Window) {.base.} =
  ## request window close
  window.m_closed = true

proc transparent*(window: Window): bool = window.m_transparent
proc frameless*(window: Window): bool = window.m_frameless
proc cursor*(window: Window): Cursor = window.m_cursor

proc size*(window: Window): IVec2 = window.m_size
proc pos*(window: Window): IVec2 = window.m_pos
proc fullscreen*(window: Window): bool = window.m_fullscreen
proc maximized*(window: Window): bool = window.m_maximized
proc minimized*(window: Window): bool = window.m_minimized
proc visible*(window: Window): bool = window.m_visible
proc resizable*(window: Window): bool = window.m_resizable
proc minSize*(window: Window): IVec2 = window.m_minSize
proc maxSize*(window: Window): IVec2 = window.m_maxSize

proc focused*(window: Window): bool = window.m_focused


# note: locks: "unknown" usualy means that function can cause event outside of event loop


method redraw*(window: Window) {.base.} = window.redrawRequested = true
  ## request render

method `frameless=`*(window: Window, v: bool) {.base, locks: "unknown".} = discard

method `cursor=`*(window: Window, v: Cursor) {.base, locks: "unknown".} = discard
  ## set cursor
  ## used when mouse hover window

method `size=`*(window: Window, v: IVec2) {.base, locks: "unknown".} = discard
  ## resize window
  ## exit fullscreen if window is fullscreen

method `pos=`*(window: Window, v: IVec2) {.base.} = discard
  ## move window
  ## do nothing if window is fullscreen

method `title=`*(window: Window, v: string) {.base, locks: "unknown".} = discard
  ## set window title

method `fullscreen=`*(window: Window, v: bool) {.base, locks: "unknown".} = discard
  ## fullscreen/unfullscreen window

method `maximized=`*(window: Window, v: bool) {.base, locks: "unknown".} = discard
  ## maximize/unmaximize window
  ## exit fullscreen if window is fullscreen

method `minimized=`*(window: Window, v: bool) {.base, locks: "unknown".} = discard
  ## minimize/unminimize window

method `visible=`*(window: Window, v: bool) {.base.} = discard
  ## show/hide window

method `resizable=`*(window: Window, v: bool) {.base.} = discard
  ## enable/disable resizing

method `minSize=`*(window: Window, v: IVec2) {.base.} = discard
  ## set minimum size
  ## `window.resizable=` will disable this

method `maxSize=`*(window: Window, v: IVec2) {.base.} = discard
  ## set maximum size
  ## `window.resizable=` will disable this

method `icon=`*(window: Window, v: nil.typeof) {.base.} = discard
  ## clear window icon

method `icon=`*(window: Window, v: tuple[pixels: openarray[ColorBgrx], size: IVec2]) {.base, locks: "unknown".} = discard
  ## set window icon

method startInteractiveMove*(window: Window, pos: Option[IVec2] = none IVec2) {.base, locks: "unknown".} = discard
  ## allow user to move window interactivly
  ## useful to create client-side decorated windows
  ## it's recomended to start interactive move after user grabbed window header and started to move mouse

method startInteractiveResize*(window: Window, edge: Edge, pos: Option[IVec2] = none IVec2) {.base, locks: "unknown".} = discard
  ## allow user to resize window interactivly
  ## useful to create client-side decorated windows
  ## it's recomended to start interactive move after user grabbed window border and started to move mouse


method drawImage*(window: Window, pixels: openarray[ColorBgrx], size: IVec2, pos: IVec2 = ivec2(), srcPos: IVec2 = ivec2()) {.base.} = discard
  ## put pixels into window
  ## note: no blending is performed, even if image or/and window is transparent


method makeCurrent*(window: Window) {.base.} = discard
  ## set window as current opengl rendering target

method `vsync=`*(window: Window, v: bool, silent = false) {.base, locks: "unknown".} = discard
  ## enable/disable vsync


method vulkanSurface*(window: Window): pointer {.base.} = discard
  ## get a VkSurfaceKHR attached to window


method firstStep*(window: Window, makeVisible = true) {.base, locks: "unknown".} = discard
  ## init window main loop
  ## don't call window proc if you will manage window events via run()

method step*(window: Window) {.base, locks: "unknown".} = discard
  ## make window main loop step
  ## ! don't forget to call firstStep()


proc run*(window: sink Window, eventsHandler: WindowEventsHandler, makeVisible = true) =
  ## run whole window main loops
  window.eventsHandler = eventsHandler
  window.firstStep(makeVisible)
  while window.opened:
    window.step()

proc runMultiple*(windows: varargs[tuple[window: Window, eventsHandler: WindowEventsHandler, makeVisible: bool]]) =
  ## run for multiple windows
  for (window, eventsHandler, makeVisible) in windows:
    window.eventsHandler = eventsHandler
    window.firstStep(makeVisible)

  var windows = windows.mapit(it.window)
  while windows.len > 0:
    var i = 0
    while i < windows.len:
      let window = windows[i]
      if window.closed:
        windows.del i
        continue
      window.step()
      inc i
