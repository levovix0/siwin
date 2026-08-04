import std/[atomics, times, options, sequtils, tables]
import pkg/[vmath]
import ../../[siwindefs, colorutils]
import ./[clipboards]


when siwin_use_pure_enums:
  {.pragma: siwin_enum, pure.}
else:
  {.pragma: siwin_enum.}


type
  EventWaitResult* = enum
    ## The event loop dispatched native activity, including a wake notification.
    eventActivity
    ## A timed wait reached its deadline without native activity.
    eventTimeout

  EventLoopWakeStateObj = object
    ## Shared by copies of an EventLoopWaker and owns the backend wake resource.
    alive: Atomic[bool]
    pending: Atomic[bool]
    backendData: pointer
    wakeProc: proc() {.gcsafe, raises: [].}
    ownedWakeProc: proc(data: pointer) {.gcsafe, raises: [].}
    closeProc: proc(data: pointer) {.gcsafe, raises: [].}

  EventLoopWakeState = ref EventLoopWakeStateObj

  EventLoopWaker* = object
    ## A narrow, copyable capability for waking an event loop from another thread.
    state: EventLoopWakeState

  EventLoopUnsupportedDefect* = object of Defect
    ## Raised on platforms whose global event loop is not implemented yet.

  MouseButton* {.siwin_enum.} = enum
    left right middle forward backward

  ModifierKey* {.siwin_enum.} = enum
    shift
    control
    alt
    system
    capsLock
    numLock

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


  TouchDeviceKind* {.siwin_enum.} = enum
    touchScreen
    touchPad
    graphicsTablet
  
  Touch* = ref object
    id*: int  # begins at 1, increments for each new touch
    pos*: Vec2
    pressed*: bool
    pressure*: float  # 0..1
    button*: Option[MouseButton]
    device*: TouchDeviceKind


  Mouse* = object
    pos*: Vec2
    pressed*: set[MouseButton]

  Keyboard* = object
    pressed*: set[Key]
    modifiers*: set[ModifierKey]
  
  TouchScreen* = object
    touches*: Table[int, Touch]  # id -> touch
  

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
  

  SiwinGlobalsObj = object of RootObj
    eventLoopState: EventLoopWakeState

  SiwinGlobals* = ref SiwinGlobalsObj
  

  Screen* = ref object of RootObj

  MouseMoveKind* {.siwin_enum.} = enum
    move
    enter
    leave
    moveWhileDragging  ## (from this or other window)

  
  DragStatus* {.siwin_enum.} = enum
    rejected
    accepted

  PopupConstraintAdjustment* {.siwin_enum.} = enum
    pcaSlideX
    pcaSlideY
    pcaFlipX
    pcaFlipY
    pcaResizeX
    pcaResizeY

  PopupDismissReason* {.siwin_enum.} = enum
    pdrClientClosed
    pdrCompositorDismissed
    pdrParentClosed

  PopupPlacement* = object
    anchorRectPos*: IVec2
    anchorRectSize*: IVec2
    size*: IVec2
    anchor*: Edge
    gravity*: Edge
    offset*: IVec2
    constraintAdjustment*: set[PopupConstraintAdjustment]
    reactive*: bool

  WindowVisualCapability* {.siwin_enum.} = enum
    wvcBackdropBlur
    wvcBackdropBlurRegion
    wvcBackdropMaterial

  WindowBackdropKind* {.siwin_enum.} = enum
    wbkNone
    wbkBlur
    wbkMaterial

  WindowBackdropMaterial* {.siwin_enum.} = enum
    wbmDefault
    wbmLight
    wbmDark
    wbmTitlebar
    wbmSidebar
    wbmHud
    wbmPopover

  WindowVisualRegion* = object
    ## Window-local region in Siwin window coordinates.
    pos*: IVec2
    size*: IVec2

  WindowBackdropConfig* = object
    regions*: seq[WindowVisualRegion] ## empty means the whole content area
    case kind*: WindowBackdropKind
    of wbkMaterial:
      material*: WindowBackdropMaterial
    of wbkNone, wbkBlur:
      discard

  WindowVisualEffectError* = object of CatchableError
    ## raised by strict visual-effect APIs when a backend cannot apply the request


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
  
  ScrollDeviceKind* {.siwin_enum.} = enum
    unknown     ## device not reported by the platform
    discrete    ## mouse wheel
    continuous  ## touchpad or touchscreen

  ScrollEvent* = object of AnyWindowEvent
    delta*: float
    deltaX*: float
    device*: ScrollDeviceKind
  
  ClickEvent* = object of AnyWindowEvent
    button*: MouseButton
    pos*: Vec2
    double*: bool

  KeyEvent* = object of AnyWindowEvent
    key*: Key
    pressed*: bool
    repeated*: bool  ## means user is holding this key and system is repeating keydown+keyup
    generated*: bool  ## generated, for example, by releaseAllKeys when alt-tab. Means user don't actually do this action
    modifiers*: set[ModifierKey]
  
  TextInputEvent* = object of AnyWindowEvent
    text*: string
    repeated*: bool
  
  TouchEvent* = object of AnyWindowEvent
    touch*: Touch
    pressed*: bool
  
  TouchMoveEvent* = object of AnyWindowEvent
    touch*: Touch
    kind*: MouseMoveKind
    pos*: Vec2
  
  TouchPressureChangedEvent* = object of AnyWindowEvent
    touch*: Touch
    pressure*: float  # 0..1
  
  StateBoolChangedEventKind* {.siwin_enum.} = enum
    focus
    fullscreen
    maximized
    frameless

  StateBoolChangedEvent* = object of AnyWindowEvent
    value*: bool
    kind*: StateBoolChangedEventKind
    isExternal*: bool  ## changed by user via compositor (server-side change)

  PopupEvent* = object of AnyWindowEvent
    reason*: PopupDismissReason
  

  DropEvent* = object of AnyWindowEvent


  WindowEventsHandler* = object
    onClose*:        proc(e: CloseEvent)  ## this window was closed (by pressing window close button, alt+f4, or by code)
    onRender*:       proc(e: RenderEvent)  ## this window is beeng redrawn, a full frame should be drawn on window until this callback finishes
    onTick*:         proc(e: TickEvent)  ## some time has passed and all pending events was handled
    onResize*:       proc(e: ResizeEvent)  ## this window changed it's width or height
    onWindowMove*:   proc(e: WindowMoveEvent)  ## this window changed it's position on screen

    onMouseMove*:    proc(e: MouseMoveEvent)  ## the mouse cursor changed it's position
    onMouseButton*:  proc(e: MouseButtonEvent)  ## a mouse button become pressed or released
    onScroll*:       proc(e: ScrollEvent)  ## a mouse wheel rotated (or scrolled by touchpad)
    onClick*:        proc(e: ClickEvent)  ## a mouse released a button without moving from position is was pressed this button

    onKey*:          proc(e: KeyEvent)  ## a key on a keyboard become pressed or released
    onTextInput*:    proc(e: TextInputEvent)  ## a (input method managed) unicode characters was inputed

    onTouch*:        proc(e: TouchEvent)  ## a touch either become pressed or released
    onTouchMove*:    proc(e: TouchMoveEvent)  ## a touch changed it's position (can be either pressed or released)
    onTouchPressureChanged*: proc(e: TouchPressureChangedEvent)  ## a touch changed it's pressure (can be either pressed or released)

    onStateBoolChanged*: proc(e: StateBoolChangedEvent)
      ## binary state of focus/fullscreen/maximized/frameless changed
      ## fullscreen and maximized changes are sent before ResizeEvent

    onPopupDone*:      proc(e: PopupEvent)  ## popup was dismissed or explicitly closed

    onDrop*:         proc(e: DropEvent)  ## drag&drop clipboard content is beeng pasted to this window


  Window* = ref object of RootObj
    mouse*: Mouse
    keyboard*: Keyboard
    touchScreen*: TouchScreen
    eventsHandler*: WindowEventsHandler

    clicking: set[MouseButton]
    
    redrawRequested: bool

    lastTickTime: times.Time

    m_closed: bool
    
    m_transparent: bool
    m_backdrop: WindowBackdropConfig
    m_frameless: bool
    m_customTitlebar: bool
    m_cursor: Cursor
    m_separateTouch: bool
    m_isPopup: bool
    m_popupGrab: bool
    m_popupDismissed: bool
    m_popupParent: Window
    m_popupPlacement: PopupPlacement
    
    m_size: IVec2
    m_pos: IVec2
    m_focused: bool
    m_fullscreen: bool
    m_maximized: bool
    m_minimized: bool
    m_visible: bool
    m_resizable: bool
    m_preservesContentDuringLiveResize: bool
    m_minSize: IVec2
    m_maxSize: IVec2

    m_clipboard: Clipboard
    m_selectionClipboard: Clipboard
    m_dragndropClipboard: Clipboard

    inputRegion, titleRegion: Option[tuple[pos, size: Vec2]]
    borderWidth: Option[tuple[innerWidth, outerWidrth, diagonalSize: float32]]


proc `=destroy`(state: EventLoopWakeStateObj) {.siwin_destructor.} =
  if state.closeProc != nil:
    state.closeProc(state.backendData)

proc `=destroy`(globals: SiwinGlobalsObj) {.siwin_destructor.} =
  if globals.eventLoopState != nil:
    globals.eventLoopState.alive.store(false)

proc shutdownEventLoopWakeState*(globals: SiwinGlobals) {.raises: [].} =
  ## Backend destructor hook for globals types that define a custom destructor.
  if globals != nil and globals.eventLoopState != nil:
    globals.eventLoopState.alive.store(false)
    globals.eventLoopState = nil

method number*(screen: Screen): int32 {.base.} = discard

method width*(screen: Screen): int32 {.base.} = discard
method height*(screen: Screen): int32 {.base.} = discard

proc size*(screen: Screen): IVec2 = ivec2(screen.width, screen.height)

type PopupWindow* = Window

func popupSize*(placement: PopupPlacement): IVec2 =
  if placement.size.x > 0 and placement.size.y > 0:
    placement.size
  elif placement.anchorRectSize.x > 0 and placement.anchorRectSize.y > 0:
    placement.anchorRectSize
  else:
    ivec2(1, 1)

func popupAnchorOffset*(anchor: Edge, size: IVec2): IVec2 =
  case anchor
  of Edge.topLeft: ivec2(0, 0)
  of Edge.top: ivec2(size.x div 2, 0)
  of Edge.topRight: ivec2(size.x, 0)
  of Edge.left: ivec2(0, size.y div 2)
  of Edge.right: ivec2(size.x, size.y div 2)
  of Edge.bottomLeft: ivec2(0, size.y)
  of Edge.bottom: ivec2(size.x div 2, size.y)
  of Edge.bottomRight: ivec2(size.x, size.y)

func popupRelativePos*(placement: PopupPlacement): IVec2 =
  let anchorPoint = placement.anchorRectPos + placement.anchor.popupAnchorOffset(placement.anchorRectSize)
  anchorPoint - placement.gravity.popupAnchorOffset(placement.popupSize()) + placement.offset

proc flipPopupEdgeX*(edge: Edge): Edge =
  case edge
  of Edge.topLeft: Edge.topRight
  of Edge.topRight: Edge.topLeft
  of Edge.left: Edge.right
  of Edge.right: Edge.left
  of Edge.bottomLeft: Edge.bottomRight
  of Edge.bottomRight: Edge.bottomLeft
  else: edge

proc flipPopupEdgeY*(edge: Edge): Edge =
  case edge
  of Edge.topLeft: Edge.bottomLeft
  of Edge.top: Edge.bottom
  of Edge.topRight: Edge.bottomRight
  of Edge.bottomLeft: Edge.topLeft
  of Edge.bottom: Edge.top
  of Edge.bottomRight: Edge.topRight
  else: edge

proc popupOverflowX*(posX, width, boundsWidth: int32): int32 {.inline.} =
  max(0'i32, -posX) + max(0'i32, posX + width - boundsWidth)

proc popupOverflowY*(posY, height, boundsHeight: int32): int32 {.inline.} =
  max(0'i32, -posY) + max(0'i32, posY + height - boundsHeight)

proc resolvePopupRect*(parentPos, boundsPos, boundsSize: IVec2, placement: PopupPlacement): tuple[pos, size: IVec2] =
  proc popupRectFor(placement: PopupPlacement): tuple[pos, size: IVec2] =
    (parentPos + placement.popupRelativePos(), placement.popupSize())

  var resolvedPlacement = placement
  result = popupRectFor(resolvedPlacement)

  if PopupConstraintAdjustment.pcaFlipX in placement.constraintAdjustment:
    var flipped = resolvedPlacement
    flipped.anchor = flipped.anchor.flipPopupEdgeX()
    flipped.gravity = flipped.gravity.flipPopupEdgeX()
    let flippedRect = popupRectFor(flipped)
    if popupOverflowX(flippedRect.pos.x - boundsPos.x, flippedRect.size.x, boundsSize.x) <
        popupOverflowX(result.pos.x - boundsPos.x, result.size.x, boundsSize.x):
      resolvedPlacement = flipped
      result = flippedRect

  if PopupConstraintAdjustment.pcaFlipY in placement.constraintAdjustment:
    var flipped = resolvedPlacement
    flipped.anchor = flipped.anchor.flipPopupEdgeY()
    flipped.gravity = flipped.gravity.flipPopupEdgeY()
    let flippedRect = popupRectFor(flipped)
    if popupOverflowY(flippedRect.pos.y - boundsPos.y, flippedRect.size.y, boundsSize.y) <
        popupOverflowY(result.pos.y - boundsPos.y, result.size.y, boundsSize.y):
      resolvedPlacement = flipped
      result = flippedRect

  if PopupConstraintAdjustment.pcaSlideX in placement.constraintAdjustment:
    result.pos.x = clamp(result.pos.x, boundsPos.x, max(boundsPos.x, boundsPos.x + boundsSize.x - result.size.x))

  if PopupConstraintAdjustment.pcaSlideY in placement.constraintAdjustment:
    result.pos.y = clamp(result.pos.y, boundsPos.y, max(boundsPos.y, boundsPos.y + boundsSize.y - result.size.y))

  if PopupConstraintAdjustment.pcaResizeX in placement.constraintAdjustment:
    if result.pos.x < boundsPos.x:
      result.size.x -= boundsPos.x - result.pos.x
      result.pos.x = boundsPos.x
    if result.pos.x + result.size.x > boundsPos.x + boundsSize.x:
      result.size.x = max(1'i32, boundsPos.x + boundsSize.x - result.pos.x)
    result.size.x = max(1'i32, result.size.x)

  if PopupConstraintAdjustment.pcaResizeY in placement.constraintAdjustment:
    if result.pos.y < boundsPos.y:
      result.size.y -= boundsPos.y - result.pos.y
      result.pos.y = boundsPos.y
    if result.pos.y + result.size.y > boundsPos.y + boundsSize.y:
      result.size.y = max(1'i32, boundsPos.y + boundsSize.y - result.pos.y)
    result.size.y = max(1'i32, result.size.y)


proc closed*(window: Window): bool = window.m_closed
proc opened*(window: Window): bool = not window.closed

method close*(window: Window) {.base.} =
  ## request window close
  window.m_closed = true

proc transparent*(window: Window): bool = window.m_transparent
proc backdrop*(window: Window): WindowBackdropConfig = window.m_backdrop
proc frameless*(window: Window): bool = window.m_frameless
proc cursor*(window: Window): Cursor = window.m_cursor
proc separateTouch*(window: Window): bool = window.m_separateTouch
  ## enable/disable handling touch events separately from mouse events
proc isPopup*(window: Window): bool = window.m_isPopup
proc popupGrab*(window: Window): bool = window.m_popupGrab

method reportedSize*(window: Window): IVec2 {.base.} = window.m_size
  ## Size reported to API users/events (backing pixels on HiDPI platforms).

proc size*(window: Window): IVec2 = window.reportedSize()
proc pos*(window: Window): IVec2 = window.m_pos
proc fullscreen*(window: Window): bool = window.m_fullscreen
proc maximized*(window: Window): bool = window.m_maximized
proc minimized*(window: Window): bool = window.m_minimized
proc visible*(window: Window): bool = window.m_visible
proc resizable*(window: Window): bool = window.m_resizable
proc preservesContentDuringLiveResize*(window: Window): bool =
  window.m_preservesContentDuringLiveResize
proc minSize*(window: Window): IVec2 = window.m_minSize
proc maxSize*(window: Window): IVec2 = window.m_maxSize

proc focused*(window: Window): bool = window.m_focused
proc customTitlebar*(window: Window): bool = window.m_customTitlebar
method parentWindow*(window: Window): Window {.base.} = window.m_popupParent
method placement*(window: Window): PopupPlacement {.base.} = window.m_popupPlacement
proc popupOpen*(window: Window): bool = window.opened and window.visible

proc initPopupState*(window, parent: Window, placement: PopupPlacement, grab: bool) =
  window.m_isPopup = true
  window.m_popupGrab = grab
  window.m_popupDismissed = false
  window.m_popupParent = parent
  window.m_popupPlacement = placement
  window.m_size = placement.popupSize()

proc notifyPopupDone*(window: Window, reason: PopupDismissReason) =
  if not window.m_isPopup or window.m_popupDismissed:
    return
  window.m_popupDismissed = true
  if window.eventsHandler.onPopupDone != nil:
    window.eventsHandler.onPopupDone(PopupEvent(window: window, reason: reason))

method uiScale*(window: Window): float32 {.base.} = 1'f32
  ## UI scale factor (device pixels per logical point).


# note: locks: "unknown" usualy means that function can cause event outside of event loop


method redraw*(window: Window) {.base.} = window.redrawRequested = true
  ## request render

method `frameless=`*(window: Window, v: bool) {.base.} = discard

method `cursor=`*(window: Window, v: Cursor) {.base.} = discard
  ## set cursor
  ## used when mouse hover window


method `separateTouch=`*(window: Window, v: bool) {.base.} = discard
  ## enable/disable handling touch events separately from mouse events

method `placement=`*(window: Window, v: PopupPlacement) {.base.} =
  window.m_popupPlacement = v

method reposition*(window: Window, v: PopupPlacement) {.base.} =
  window.placement = v


method `size=`*(window: Window, v: IVec2) {.base.} = discard
  ## resize window
  ## exit fullscreen if window is fullscreen

method `pos=`*(window: Window, v: IVec2) {.base.} = discard
  ## move window
  ## do nothing if window is fullscreen

method `title=`*(window: Window, v: string) {.base.} = discard
  ## set window title

method `customTitlebar=`*(window: Window, v: bool) {.base.} =
  ## enable/disable custom titlebar integration when backend supports it.
  window.m_customTitlebar = v

method supportsCustomTitlebar*(window: Window): bool {.base.} = false
  ## reports whether this backend currently applies customTitlebar behavior.

method visualCapabilities*(window: Window): set[WindowVisualCapability] {.base.} =
  ## reports which compositor/window visual effects this window can currently use.
  {}

proc supports*(window: Window, capability: WindowVisualCapability): bool =
  capability in window.visualCapabilities()

proc initWindowBackdrop*(
  regions: openArray[WindowVisualRegion] = []
): WindowBackdropConfig =
  ## Configure ordinary background blur. An empty region list means the whole window.
  WindowBackdropConfig(kind: wbkBlur, regions: @regions)

proc initWindowBackdrop*(
  material: WindowBackdropMaterial,
  regions: openArray[WindowVisualRegion] = [],
): WindowBackdropConfig =
  ## Configure a platform material. This is currently supported on macOS.
  WindowBackdropConfig(kind: wbkMaterial, material: material, regions: @regions)

method trySetBackdrop*(window: Window, config: WindowBackdropConfig): bool {.base.} =
  ## Try to apply a compositor/window-manager backdrop effect.
  ## Returns false if the backend cannot apply the requested effect.
  ## Non-empty effects require a window created with `transparent = true`.
  if config.kind == wbkNone:
    window.m_backdrop = WindowBackdropConfig(kind: wbkNone)
    return true

proc clearBackdrop*(window: Window) =
  ## Disable the current backdrop effect.
  discard window.trySetBackdrop(WindowBackdropConfig(kind: wbkNone))

proc setBackdrop*(window: Window, config: WindowBackdropConfig) =
  ## Strict version of trySetBackdrop. Raises if the backend cannot apply it.
  if not window.trySetBackdrop(config):
    raise WindowVisualEffectError.newException(
      "window backdrop effect is not supported by this backend or configuration"
    )

method `fullscreen=`*(window: Window, v: bool) {.base.} = discard
  ## fullscreen/unfullscreen window

method `maximized=`*(window: Window, v: bool) {.base.} = discard
  ## maximize/unmaximize window
  ## exit fullscreen if window is fullscreen

method `minimized=`*(window: Window, v: bool) {.base.} = discard
  ## minimize/unminimize window

method `visible=`*(window: Window, v: bool) {.base.} = discard
  ## show/hide window

method `resizable=`*(window: Window, v: bool) {.base.} = discard
  ## enable/disable resizing

method `preservesContentDuringLiveResize=`*(window: Window, v: bool) {.base.} =
  window.m_preservesContentDuringLiveResize = v

method `minSize=`*(window: Window, v: IVec2) {.base.} = discard
  ## set minimum size
  ## `window.resizable=` will disable this

method `maxSize=`*(window: Window, v: IVec2) {.base.} = discard
  ## set maximum size
  ## `window.resizable=` will disable this

method canBecomeKeyWindow*(window: Window): bool {.base.} = true
  ## whether this window is allowed to become key window.
  ## only macOS backend uses this property.

method canBecomeMainWindow*(window: Window): bool {.base.} = true
  ## whether this window is allowed to become main window.
  ## only macOS backend uses this property.

method `canBecomeKeyWindow=`*(window: Window, v: bool) {.base.} = discard
method `canBecomeMainWindow=`*(window: Window, v: bool) {.base.} = discard

method `icon=`*(window: Window, v: nil.typeof) {.base.} = discard
  ## clear window icon

method `icon=`*(window: Window, v: PixelBuffer) {.base.} = discard
  ## set window icon


method startInteractiveMove*(window: Window, pos: Option[Vec2] = none Vec2) {.base.} = discard
  ## allow user to move window interactivly
  ## useful to create client-side decorated windows
  ## it's recomended to start interactive move after user grabbed window header and started to move mouse


method startInteractiveResize*(window: Window, edge: Edge, pos: Option[Vec2] = none Vec2) {.base.} = discard
  ## allow user to resize window interactivly
  ## useful to create client-side decorated windows
  ## it's recomended to start interactive resize after user grabbed window border and started to move mouse


method showWindowMenu*(window: Window, pos: Option[Vec2] = none Vec2) {.base.} = discard
  ## show OS/platform/DE-specific window menu
  ## it's recomended to show menu after user right-clicked on window header
  ## for now works only on Linux(Wayland)


method setInputRegion*(window: Window, pos, size: Vec2) {.base.} =
  ## set the rect (in window-local coordinates) where actual window is placed (inluding titlebar, if has one).
  ## this is used by Windows and Linux(Wayland) to correctly anchor the window and to correctly send mouse and touch events.
  ## it's recomended to set input region if you draw shadows for window.
  ## setInputRegion, if called once, must be called after each resize of the window
  assert size.x > 0 and size.y > 0, "there must be at least one pixel of the actual window"
  window.inputRegion = some (pos, size)


method setTitleRegion*(window: Window, pos, size: Vec2) {.base.} =
  ## set the rect (in window-local coordinates) where titlebar is placed.
  ## this is used by Windows to allow user to move window interactivly. siwin will replicate this behaviour on other platforms.
  ## it's recomended to set title region if you have custom titlebar.
  window.titleRegion = some (pos, size)


method setBorderWidth*(window: Window, innerWidth, outerWidth: float32, diagonalSize: float32) {.base.} =
  ## set window border width. This will not change the look of window, it is for resizing window.
  ## this is used on Windows to allow user to resize window interactivly. siwin will replicate this behaviour on other platforms.
  ## it's recomended to set border width if you have custom titlebar.
  window.borderWidth = some (innerWidth, outerWidth, diagonalSize)


method pixelBuffer*(window: Window): PixelBuffer {.base.} =
  ## returns pixel buffer attached to window
  raise WindowTypeDefect.newException("this Window has no pixel buffer. only SoftwareRendering windows have one")


method makeCurrent*(window: Window) {.base.} = discard
  ## set window as current opengl rendering target

method `vsync=`*(window: Window, v: bool, silent = false) {.base.} = discard
  ## enable/disable vsync


method vulkanSurface*(window: Window): pointer {.base.} = discard
  ## get a VkSurfaceKHR attached to window


proc clipboard*(window: Window): Clipboard = window.m_clipboard

proc selectionClipboard*(window: Window): Clipboard = window.m_selectionClipboard

proc dragndropClipboard*(window: Window): Clipboard = window.m_dragndropClipboard


method `dragStatus=`*(window: Window, v: DragStatus) {.base.} = discard


method firstStep*(window: Window, makeVisible = true) {.base.} = discard
  ## init window main loop
  ## don't call this proc if you will manage window events via run()

method step*(window: Window) {.base.} = discard
  ## make window main loop step
  ## ! don't forget to call firstStep()

method serviceWindow*(window: Window) {.base.} =
  ## Run per-window tick, rendering, and presentation without waiting for input.
  discard window
  raise EventLoopUnsupportedDefect.newException(
    "Nonblocking window service is not implemented on this platform",
  )

method pollEventsImpl(globals: SiwinGlobals): bool {.base.} =
  discard globals
  raise EventLoopUnsupportedDefect.newException(
    "Global event-loop pumping is not implemented on this platform",
  )

method waitEventsImpl(
  globals: SiwinGlobals, timeout: Duration,
): EventWaitResult {.base.} =
  discard globals
  discard timeout
  raise EventLoopUnsupportedDefect.newException(
    "Global event-loop waiting is not implemented on this platform",
  )

proc eventLoopWaker*(globals: SiwinGlobals): EventLoopWaker =
  ## Returns a thread-safe capability that remains harmless after loop shutdown.
  if globals.eventLoopState == nil:
    globals.eventLoopState = EventLoopWakeState()
    globals.eventLoopState.alive.store(true)
  EventLoopWaker(state: globals.eventLoopState)

proc installEventLoopWakeProc*(
  globals: SiwinGlobals,
  wakeProc: proc() {.gcsafe, raises: [].},
) =
  ## Install the backend notification primitive during globals initialization.
  discard globals.eventLoopWaker()
  globals.eventLoopState.wakeProc = wakeProc

proc installOwnedEventLoopWakeProc*(
  globals: SiwinGlobals,
  wakeProc: proc(data: pointer) {.gcsafe, raises: [].},
  backendData: pointer,
  closeProc: proc(data: pointer) {.gcsafe, raises: [].},
) =
  ## Install a backend wake primitive and transfer its resource during startup.
  discard globals.eventLoopWaker()
  globals.eventLoopState.backendData = backendData
  globals.eventLoopState.ownedWakeProc = wakeProc
  globals.eventLoopState.closeProc = closeProc

proc consumeEventLoopWake*(waker: EventLoopWaker): bool =
  ## Clears this waker's coalesced notification after the backend consumes it.
  ##
  ## Platform event pumps call this on the application thread before returning
  ## control to the application, so work enqueued by a racing producer is either
  ## observed in the current drain or causes a later wake. Returns `false` when
  ## `waker` has no state or its owning event loop is no longer alive.
  if waker.state != nil and waker.state.alive.load():
    waker.state.pending.store(false)
    result = true

proc consumeEventLoopWake*(globals: SiwinGlobals) =
  ## Clears the pending notification for `globals`, if it has a waker.
  ##
  ## This is a backend event-pump hook. Applications normally call
  ## `pollEvents` or `waitEvents`, which consume wake notifications themselves.
  if globals.eventLoopState != nil:
    discard EventLoopWaker(state: globals.eventLoopState).consumeEventLoopWake()

proc wake*(waker: EventLoopWaker) {.gcsafe, raises: [].} =
  ## Notify the owning event loop after enqueuing application work.
  let state = waker.state
  if state == nil or not state.alive.load():
    return

  if not state.pending.exchange(true):
    # The backend is selected when the waker is created. A backend may coalesce
    # repeated notifications while this sentinel is pending.
    if state.wakeProc != nil:
      state.wakeProc()
    elif state.ownedWakeProc != nil:
      state.ownedWakeProc(state.backendData)

proc wakeEventLoop*(globals: SiwinGlobals) {.gcsafe, raises: [].} =
  ## Wakes the event loop owned by `globals` from any thread.
  ##
  ## Enqueue application work before calling this procedure. The notification
  ## carries no data and repeated calls may be coalesced. Prefer copying an
  ## `EventLoopWaker` when a worker should not retain the complete globals owner.
  globals.eventLoopWaker().wake()

proc pollEvents*(globals: SiwinGlobals): bool =
  ## Dispatch all immediately available native events on the application thread.
  globals.pollEventsImpl()

proc waitEvents*(globals: SiwinGlobals) =
  ## On the application thread, wait for native input or a waker notification.
  discard globals.waitEventsImpl(high(Duration))

proc waitEvents*(globals: SiwinGlobals, timeout: Duration): EventWaitResult =
  ## On the application thread, wait up to `timeout` for input or a notification.
  globals.waitEventsImpl(timeout)


proc run*(window: sink Window, makeVisible = true) =
  ## run whole window main loops
  window.firstStep(makeVisible)
  while window.opened:
    window.step()

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
      if window.closed:
        windows.del i
        continue
      window.step()
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
      if window.closed:
        windows.del i
        continue
      window.step()
      inc i
