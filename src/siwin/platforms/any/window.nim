import std/[times, options, sequtils, tables]
import pkg/[vmath]
import ../../[siwindefs, colorutils]
import ./[clipboards]


when siwin_use_pure_enums:
  {.pragma: siwin_enum, pure.}
else:
  {.pragma: siwin_enum.}


type
  MouseButton* {.siwin_enum.} = enum
    left right middle forward backward

  Key* {.siwin_enum.} = enum
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
    capsLock numLock scrollLock printScreen pause

    level3_shift level5_shift
  
  Touch* = object
    id*: int
    pos*: Vec2


  Mouse* = object
    pos*: Vec2
    pressed*: set[MouseButton]

  Keyboard* = object
    pressed*: set[Key]
  
  TouchScreen* = object
    pressed*: Table[int, Touch]  # id -> touch
  

  Edge* {.siwin_enum.} = enum
    left
    right
    top
    bottom
    topLeft
    topRight
    bottomLeft
    bottomRight


  CursorKind* {.siwin_enum.} = enum
    builtin
    image

  Cursor* = object
    case kind*: CursorKind
    of builtin: builtin*: BuiltinCursor
    of image: image*: ImageCursor

  BuiltinCursor* {.siwin_enum.} = enum
    arrow arrowUp arrowRight
    wait arrowWait
    pointingHand grab
    text cross
    sizeAll sizeHorizontal sizeVertical
    sizeTopLeft sizeTopRight sizeBottomLeft sizeBottomRight
    hided
  
  ImageCursor* = object
    origin*: IVec2
    pixels*: PixelBuffer


  WindowTypeDefect* = object of Defect
    ## raised when trying to get pixel buffer from non-softwareRendering window
  
  
  Platform* {.siwin_enum.} = enum
    x11
    wayland
    winapi
    cocoa
    android


  Screen* = distinct int

  
  SiwinGlobalsVtable = object
    screenCount*: proc(globals: SiwinGlobals): int {.nimcall.}
    defaultScreen*: proc(globals: SiwinGlobals): Screen {.nimcall.}
    screenSize*: proc(globals: SiwinGlobals, n: Screen): IVec2 {.nimcall, raises: [ValueError].}


  SiwinGlobals* = ptr SiwinGlobalsObj
  SiwinGlobalsObj* = object of RootObj
    platform*: Platform
    vtable: SiwinGlobalsVtable

    softwareRenderingVtable: WindowVtable
    openglVtable: WindowVtable
    vulkanVtable: WindowVtable


  MouseMoveKind* {.siwin_enum.} = enum
    move
    enter
    leave
    moveWhileDragging  ## (from this or other window)

  
  DragStatus* {.siwin_enum.} = enum
    rejected
    accepted


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

  MouseMoveEvent* = object of AnyWindowEvent
    pos*: Vec2
    kind*: MouseMoveKind
  
  MouseButtonEvent* = object of AnyWindowEvent
    button*: MouseButton
    pressed*: bool
    generated*: bool  ## generated, for example, by releaseAllKeys when alt-tab. Means user don't actually do this action
  
  ScrollEvent* = object of AnyWindowEvent
    delta*: float
    deltaX*: float
  
  ClickEvent* = object of AnyWindowEvent
    button*: MouseButton
    pos*: Vec2
    double*: bool

  KeyEvent* = object of AnyWindowEvent
    key*: Key
    pressed*: bool
    repeated*: bool  ## means user is holding this key and system is repeating keydown+keyup
    generated*: bool  ## generated, for example, by releaseAllKeys when alt-tab. Means user don't actually do this action
  
  TextInputEvent* = object of AnyWindowEvent
    text*: string
    repeated*: bool
  
  TouchEvent* = object of AnyWindowEvent
    touchId*: int
    pressed*: bool
    pos*: Vec2
  
  TouchMoveEvent* = object of AnyWindowEvent
    touchId*: int
    pos*: Vec2
  
  StateBoolChangedEventKind* {.siwin_enum.} = enum
    focus
    fullscreen
    maximized
    frameless

  StateBoolChangedEvent* = object of AnyWindowEvent
    value*: bool
    kind*: StateBoolChangedEventKind
    isExternal*: bool  ## changed by user via compositor (server-side change)
  

  DropEvent* = object of AnyWindowEvent


  WindowEventsHandler* = object
    onClose*:       proc(e: CloseEvent)
    onRender*:      proc(e: RenderEvent)
    onTick*:        proc(e: TickEvent)
    onResize*:      proc(e: ResizeEvent)
    onWindowMove*:  proc(e: WindowMoveEvent)

    onMouseMove*:    proc(e: MouseMoveEvent)
    onMouseButton*:  proc(e: MouseButtonEvent)
    onScroll*:       proc(e: ScrollEvent)
    onClick*:        proc(e: ClickEvent)

    onKey*:          proc(e: KeyEvent)
    onTextInput*:    proc(e: TextInputEvent)

    onTouch*:        proc(e: TouchEvent)
    onTouchMove*:    proc(e: TouchMoveEvent)

    onStateBoolChanged*: proc(e: StateBoolChangedEvent)
      ## binary state of focus/fullscreen/maximized/frameless changed
      ## fullscreen and maximized changes are sent before ResizeEvent

    onDrop*:             proc(e: DropEvent)


  WindowVtable = object
    close*: proc(window: Window) {.nimcall.}
    redraw*: proc(window: Window) {.nimcall.}

    destroy*: proc(window: Window) {.nimcall.}
    displayImpl*: proc(window: Window) {.nimcall.}

    set_frameless*: proc(window: Window, v: bool) {.nimcall.}
    set_cursor*: proc(window: Window, v: Cursor) {.nimcall.}
    set_separateTouch*: proc(window: Window, v: bool) {.nimcall.}
    
    set_size*: proc(window: Window, v: IVec2) {.nimcall.}
    set_pos*: proc(window: Window, v: IVec2) {.nimcall.}
    set_title*: proc(window: Window, v: string) {.nimcall.}
    
    set_fullscreen*: proc(window: Window, v: bool) {.nimcall.}
    set_maximized*: proc(window: Window, v: bool) {.nimcall.}
    set_minimized*: proc(window: Window, v: bool) {.nimcall.}
    set_visible*: proc(window: Window, v: bool) {.nimcall.}
    
    set_resizable*: proc(window: Window, v: bool) {.nimcall.}
    set_minSize*: proc(window: Window, v: IVec2) {.nimcall.}
    set_maxSize*: proc(window: Window, v: IVec2) {.nimcall.}
    
    set_icon*: proc(window: Window, v: PixelBuffer) {.nimcall.}
    clear_icon*: proc(window: Window) {.nimcall.}
    
    startInteractiveMove*: proc(window: Window, pos: Option[Vec2] = none Vec2) {.nimcall.}
    startInteractiveResize*: proc(window: Window, edge: Edge, pos: Option[Vec2] = none Vec2) {.nimcall.}
    
    showWindowMenu*: proc(window: Window, pos: Option[Vec2] = none Vec2) {.nimcall.}
    setInputRegion*: proc(window: Window, pos, size: Vec2) {.nimcall.}
    setTitleRegion*: proc(window: Window, pos, size: Vec2) {.nimcall.}
    setBorderWidth*: proc(window: Window, innerWidth, outerWidth: float32, diagonalSize: float32) {.nimcall.}
    
    set_dragStatus*: proc(window: Window, v: DragStatus) {.nimcall.}
    
    pixelBuffer*: proc(window: Window): PixelBuffer {.nimcall.}
    
    makeCurrent*: proc(window: Window) {.nimcall.}
    set_vsync*: proc(window: Window, v: bool, silent = false) {.nimcall.}
    
    vulkanSurface*: proc(window: Window): pointer {.nimcall.}
    
    firstStep*: proc(window: Window, makeVisible = true) {.nimcall.}
    step*: proc(window: Window): bool {.nimcall.}


  Window* = ptr object of RootObj
    globals*: SiwinGlobals
    vtable: ptr WindowVtable
    
    mouse*: Mouse
    keyboard*: Keyboard
    touchScreen*: TouchScreen
    eventsHandler*: WindowEventsHandler

    clicking: set[MouseButton]
    
    redrawRequested: bool

    lastTickTime: times.Time

    m_closed: bool
    
    m_transparent: bool
    m_frameless: bool
    m_cursor: Cursor
    m_separateTouch: bool
    
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

    m_clipboard: Clipboard
    m_selectionClipboard: Clipboard
    m_dragndropClipboard: Clipboard

    inputRegion, titleRegion: Option[tuple[pos, size: Vec2]]
    borderWidth: Option[tuple[innerWidth, outerWidrth, diagonalSize: float32]]


proc screenCount*(globals: SiwinGlobals): int = globals.vtable.screenCount(globals)
proc defaultScreen*(globals: SiwinGlobals): Screen = globals.vtable.defaultScreen(globals)
proc screenSize*(globals: SiwinGlobals, n: Screen): IVec2 {.raises: [ValueError].} = globals.vtable.screenSize(globals, n)
  ## returns size of screen in pixels


proc transparent*(window: Window): bool = window.m_transparent
proc frameless*(window: Window): bool = window.m_frameless
proc cursor*(window: Window): Cursor = window.m_cursor
proc separateTouch*(window: Window): bool = window.m_separateTouch
  ## is handling touch events separately from mouse events enabled/disabled

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



proc close*(window: Window) = window.vtable.close(window)
  ## request window close

proc redraw*(window: Window) = window.vtable.redraw(window)
  ## request render


proc `frameless=`*(window: Window, v: bool) = window.vtable.set_frameless(window, v)
  ## enable/disable window decorations

proc `cursor=`*(window: Window, v: Cursor) = window.vtable.set_cursor(window, v)
  ## set cursor
  ## used when mouse hover window

proc `separateTouch=`*(window: Window, v: bool) = window.vtable.set_separateTouch(window, v)
  ## enable/disable handling touch events separately from mouse events


proc `size=`*(window: Window, v: IVec2) = window.vtable.set_size(window, v)
  ## resize window
  ## exit fullscreen if window is fullscreen

proc `pos=`*(window: Window, v: IVec2) = window.vtable.set_pos(window, v)
  ## move window
  ## do nothing if window is fullscreen


proc `title=`*(window: Window, v: string) = window.vtable.set_title(window, v)
  ## set window title


proc `fullscreen=`*(window: Window, v: bool) = window.vtable.set_fullscreen(window, v)
  ## fullscreen/unfullscreen window

proc `maximized=`*(window: Window, v: bool) = window.vtable.set_maximized(window, v)
  ## maximize/unmaximize window
  ## exit fullscreen if window is fullscreen

proc `minimized=`*(window: Window, v: bool) = window.vtable.set_minimized(window, v)
  ## minimize/unminimize window

proc `visible=`*(window: Window, v: bool) = window.vtable.set_visible(window, v)
  ## show/hide window


proc `resizable=`*(window: Window, v: bool) = window.vtable.set_resizable(window, v)
  ## enable/disable resizing

proc `minSize=`*(window: Window, v: IVec2) = window.vtable.set_minSize(window, v)
  ## set minimum size
  ## `window.resizable=` will disable this

proc `maxSize=`*(window: Window, v: IVec2) = window.vtable.set_maxSize(window, v)
  ## set maximum size
  ## `window.resizable=` will disable this


proc `icon=`*(window: Window, v: PixelBuffer) = window.vtable.set_icon(window, v)
  ## set window icon

proc `icon=`*(window: Window, v: typeof(nil)) = window.vtable.clear_icon(window)
  ## clear window icon


proc startInteractiveMove*(window: Window, pos: Option[Vec2] = none Vec2) = window.vtable.startInteractiveMove(window, pos)
  ## allow user to move window interactivly
  ## useful to create client-side decorated windows
  ## it's recomended to start interactive move after user grabbed window header and started to move mouse

proc startInteractiveResize*(window: Window, edge: Edge, pos: Option[Vec2] = none Vec2) = window.vtable.startInteractiveResize(window, edge, pos)
  ## allow user to resize window interactivly
  ## useful to create client-side decorated windows
  ## it's recomended to start interactive resize after user grabbed window border and started to move mouse


proc showWindowMenu*(window: Window, pos: Option[Vec2] = none Vec2) = window.vtable.showWindowMenu(window, pos)
  ## show OS/platform/DE-specific window menu
  ## it's recomended to show menu after user right-clicked on window header
  ## for now works only on Linux(Wayland)

proc setInputRegion*(window: Window, pos, size: Vec2) = window.vtable.setInputRegion(window, pos, size)
  ## set the rect (in window-local coordinates) where actual window is placed (inluding titlebar, if has one).
  ## this is used by Windows and Linux(Wayland) to correctly anchor the window and to correctly send mouse and touch events.
  ## it's recomended to set input region if you draw shadows for window.
  ## setInputRegion, if called once, must be called after each resize of the window

proc setTitleRegion*(window: Window, pos, size: Vec2) = window.vtable.setTitleRegion(window, pos, size)
  ## set the rect (in window-local coordinates) where titlebar is placed.
  ## this is used by Windows to allow user to move window interactivly. siwin will replicate this behaviour on other platforms.
  ## it's recomended to set title region if you have custom titlebar.

proc setBorderWidth*(window: Window, innerWidth, outerWidth: float32, diagonalSize: float32) =
  ## set window border width. This will not change the look of window, it is for resizing window.
  ## this is used on Windows to allow user to resize window interactivly. siwin will replicate this behaviour on other platforms.
  ## it's recomended to set border width if you have custom titlebar.
  window.vtable.setBorderWidth(window, innerWidth, outerWidth, diagonalSize)


proc `dragStatus=`*(window: Window, v: DragStatus) = window.vtable.set_dragStatus(window, v)
  ## respond to a drop request


proc pixelBuffer*(window: Window): PixelBuffer = window.vtable.pixelBuffer(window)
  ## returns pixel buffer attached to window


proc makeCurrent*(window: Window) = window.vtable.makeCurrent(window)
  ## set window as current opengl rendering target

proc `vsync=`*(window: Window, v: bool, silent = false) = window.vtable.set_vsync(window, v, silent)
  ## enable/disable vsync


proc vulkanSurface*(window: Window): pointer = window.vtable.vulkanSurface(window)
  ## get a VkSurfaceKHR attached to window


proc firstStep*(window: Window, makeVisible = true) = window.vtable.firstStep(window, makeVisible)
  ## init window main loop
  ## don't call this proc if you will manage window events via run()

proc step*(window: Window): bool = window.vtable.step(window)
  ## make window main loop step
  ## ! don't forget to call firstStep()


proc clipboard*(window: Window): Clipboard = window.m_clipboard

proc selectionClipboard*(window: Window): Clipboard = window.m_selectionClipboard

proc dragndropClipboard*(window: Window): Clipboard = window.m_dragndropClipboard


proc run*(window: sink Window, makeVisible = true) =
  ## run whole window main loops
  window.firstStep(makeVisible)
  while true:
    if window.step(): break

proc run*(window: sink Window, eventsHandler: WindowEventsHandler, makeVisible = true) =
  ## set window eventsHandler and run whole window main loops
  if eventsHandler != WindowEventsHandler():
    window.eventsHandler = eventsHandler
  run(window, makeVisible)

proc runMultiple*(windows: varargs[tuple[window: Window, makeVisible: bool]]) =
  ## run for multiple windows
  for (window, makeVisible) in windows:
    window.firstStep(makeVisible)

  var windows = windows.mapit(it.window)
  while windows.len > 0:
    var i = 0
    while i < windows.len:
      let window = windows[i]
      if window.step():
        windows.del i
      else:
        inc i

proc runMultiple*(windows: varargs[tuple[window: Window, eventsHandler: WindowEventsHandler, makeVisible: bool]]) =
  ## run for multiple windows
  for (window, eventsHandler, makeVisible) in windows:
    if eventsHandler != WindowEventsHandler():
      window.eventsHandler = eventsHandler
    window.firstStep(makeVisible)

  var windows = windows.mapit(it.window)
  while windows.len > 0:
    var i = 0
    while i < windows.len:
      let window = windows[i]
      if window.step():
        windows.del i
      else:
        inc i
