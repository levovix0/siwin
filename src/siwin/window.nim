import times, os, options
import chroma, vmath
import bgrx, utils
export chroma, vmath, bgrx

when defined(linux):
  import sets
  import wrappers/x, wrappers/glx

when defined(windows):
  import wrappers/winapi


type
  MouseButton* {.pure.} = enum
    left right middle forward backward
  Mouse* = tuple
    pos: IVec2
    pressed: set[MouseButton]

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

  Keyboard* = tuple
    pressed: set[Key]

  Cursor* {.pure.} = enum
    arrow arrowUp arrowRight
    wait arrowWait
    pointingHand grab
    text cross
    sizeAll sizeHorisontal sizeVertical
    sizeTopLeft sizeTopRight sizeBottomLeft sizeBottomRight
    hided
  
  Edge* {.pure.} = enum
    left
    right
    top
    bottom
    topLeft
    topRight
    bottomLeft
    bottomRight

  Screen* = object
    when defined(linux):
      id: cint
      handle: PScreen

  Window* = ref object of RootObj
    onClose*:       proc(e: CloseEvent)

    onRender*:      proc(e: RenderEvent)
    onTick*:        proc(e: TickEvent)
    onResize*:      proc(e: ResizeEvent)
    onWindowMove*:  proc(e: WindowMoveEvent)

    onFocusChanged*:      proc(e: FocusEvent)
    onFullscreenChanged*: proc(e: StateChangedEvent)

    mouse*: Mouse
    onMouseMove*:   proc(e: MouseMoveEvent)
    onMouseLeave*:  proc(e: MouseMoveEvent)
    onMouseEnter*:  proc(e: MouseMoveEvent)
    onMouseDown*:   proc(e: MouseButtonEvent)
    onMouseUp*:     proc(e: MouseButtonEvent)
    onClick*:       proc(e: ClickEvent)
    onScroll*:      proc(e: ScrollEvent)

    keyboard*: Keyboard
    onKeydown*:     proc(e: KeyEvent)
    onKeyup*:       proc(e: KeyEvent)
    onTextInput*:   proc(e: TextInputEvent)

    m_size: IVec2

    closed: bool
    m_hasFocus: bool
    m_isFullscreen: bool

    clicking: set[MouseButton]
    
    waitForReDraw: bool
    curCursor: Option[Cursor]
    transparent: bool

    when defined(linux):
      xscr: cint
      xwin: x.Window
      xicon: Pixmap
      xiconMask: Pixmap
      xinContext: XIC
      xinMethod: XIM
      gc: GraphicsContext
      # xSyncCounter: XSyncCounter
      # lastSync: XSyncValue
      xcursor: x.Cursor

      m_visible: bool
      m_pos: IVec2
      bgraPixels: Option[seq[tuple[b, g, r, a: uint8]]]

    elif defined(windows):
      handle: HWnd
      wicon: HIcon
      hdc: Hdc
      buffer: tuple[x, y: int; bitmap: HBitmap, hdc: Hdc, pixels: ptr UncheckedArray[ColorBgrx]]

      m_minSize, m_maxSize: Option[IVec2]
      wcursor: HCursor

  OpenglWindow* = ref object of Window
    when defined(linux):
      ctx: GlxContext
    
    elif defined(windows):
      ctx: WglContext


  CloseEvent* = tuple

  RenderEvent* = tuple
  ResizeEvent* = tuple
    oldSize, size: IVec2
    initial: bool # is this initial resizing
  WindowMoveEvent* = tuple
    oldPos, pos: IVec2

  MouseMoveEvent* = tuple
    oldPos, pos: IVec2
  MouseButtonEvent* = tuple
    button: MouseButton
    pressed: bool
  ClickEvent* = tuple
    button: MouseButton
    pos: IVec2
    doubleClick: bool
  ScrollEvent* = tuple
    delta: float ## 1: scroll down, -1: scroll up

  FocusEvent* = tuple
    focused: bool
  StateChangedEvent* = tuple
    state: bool

  TickEvent* = tuple
    deltaTime: Duration
  # todo: FixedTickEvent

  KeyEvent* = tuple
    key: Key
    pressed: bool
    repeated: bool
  TextInputEvent* = tuple
    text: string # one utf-8 encoded letter


when defined(linux):
  proc xkeyToKey(sym: KeySym): Key =
    case sym
    of Xk_shiftL:       Key.lshift
    of Xk_shiftR:       Key.rshift
    of Xk_controlL:     Key.lcontrol
    of Xk_controlR:     Key.rcontrol
    of Xk_altL:         Key.lalt
    of Xk_altR:         Key.ralt
    of Xk_superL:       Key.lsystem
    of Xk_superR:       Key.rsystem
    of Xk_menu:         Key.menu
    of Xk_escape:       Key.escape
    of Xk_semicolon:    Key.semicolon
    of Xk_slash:        Key.slash
    of Xk_equal:        Key.equal
    of Xk_minus:        Key.minus
    of Xk_bracketleft:  Key.lbracket
    of Xk_bracketright: Key.rbracket
    of Xk_comma:        Key.comma
    of Xk_period:       Key.dot
    of Xk_apostrophe:   Key.quote
    of Xk_backslash:    Key.backslash
    of Xk_grave:        Key.tilde
    of Xk_space:        Key.space
    of Xk_return:       Key.enter
    of Xk_kpEnter:      Key.enter
    of Xk_backspace:    Key.backspace
    of Xk_tab:          Key.tab
    of Xk_prior:        Key.page_up
    of Xk_next:         Key.page_down
    of Xk_end:          Key.End
    of Xk_home:         Key.home
    of Xk_insert:       Key.insert
    of Xk_delete:       Key.del
    of Xk_kpAdd:        Key.add
    of Xk_kpSubtract:   Key.subtract
    of Xk_kpMultiply:   Key.multiply
    of Xk_kpDivide:     Key.divide
    of Xk_capsLock:     Key.capsLock
    of Xk_numLock:      Key.numLock
    of Xk_scrollLock:   Key.scrollLock
    of Xk_print:        Key.printScreen
    of Xk_kpSeparator:  Key.npadDot
    of Xk_pause:        Key.pause
    of Xk_f1:           Key.f1
    of Xk_f2:           Key.f2
    of Xk_f3:           Key.f3
    of Xk_f4:           Key.f4
    of Xk_f5:           Key.f5
    of Xk_f6:           Key.f6
    of Xk_f7:           Key.f7
    of Xk_f8:           Key.f8
    of Xk_f9:           Key.f9
    of Xk_f10:          Key.f10
    of Xk_f11:          Key.f11
    of Xk_f12:          Key.f12
    of Xk_f13:          Key.f13
    of Xk_f14:          Key.f14
    of Xk_f15:          Key.f15
    of Xk_left:         Key.left
    of Xk_right:        Key.right
    of Xk_up:           Key.up
    of Xk_down:         Key.down
    of Xk_kpInsert:     Key.npad0
    of Xk_kpEnd:        Key.npad1
    of Xk_kpDown:       Key.npad2
    of Xk_kpPagedown:   Key.npad3
    of Xk_kpLeft:       Key.npad4
    of Xk_kpBegin:      Key.npad5
    of Xk_kpRight:      Key.npad6
    of Xk_kpHome:       Key.npad7
    of Xk_kpUp:         Key.npad8
    of Xk_kpPageup:     Key.npad9
    of Xk_a:            Key.a
    of Xk_b:            Key.b
    of Xk_c:            Key.c
    of Xk_d:            Key.d
    of Xk_e:            Key.e
    of Xk_f:            Key.f
    of Xk_g:            Key.g
    of Xk_h:            Key.h
    of Xk_i:            Key.i
    of Xk_j:            Key.j
    of Xk_k:            Key.k
    of Xk_l:            Key.l
    of Xk_m:            Key.m
    of Xk_n:            Key.n
    of Xk_o:            Key.o
    of Xk_p:            Key.p
    of Xk_q:            Key.q
    of Xk_r:            Key.r
    of Xk_s:            Key.s
    of Xk_t:            Key.t
    of Xk_u:            Key.u
    of Xk_v:            Key.v
    of Xk_w:            Key.w
    of Xk_x:            Key.x
    of Xk_y:            Key.y
    of Xk_z:            Key.z
    of Xk_0:            Key.n0
    of Xk_1:            Key.n1
    of Xk_2:            Key.n2
    of Xk_3:            Key.n3
    of Xk_4:            Key.n4
    of Xk_5:            Key.n5
    of Xk_6:            Key.n6
    of Xk_7:            Key.n7
    of Xk_8:            Key.n8
    of Xk_9:            Key.n9
    else:               Key.unknown

  proc getScreenCount*(): int =
    x.init()
    display.ScreenCount.int

  proc screen*(n: int): Screen =
    if n notin 0..<getScreenCount(): raise IndexDefect.newException(&"screen {n} is not exist")
    result.id = n.cint
    result.handle = display.ScreenOfDisplay(result.id)

  proc defaultScreen*(): Screen =
    x.init()
    screen(display.DefaultScreen.int)
  proc screen*: Screen = defaultScreen()

  proc n*(a: Screen): int = a.id.int

  proc w*(this: Screen): int = this.handle.width.int
  proc h*(this: Screen): int = this.handle.height.int

elif defined(windows):
  proc wkeyToKey(key: WParam): Key =
    case key
    of Vk_lshift:       Key.lshift
    of Vk_rshift:       Key.rshift
    of Vk_lmenu:        Key.lalt
    of Vk_rmenu:        Key.ralt
    of Vk_lcontrol:     Key.lcontrol
    of Vk_rcontrol:     Key.rcontrol
    of Vk_lwin:         Key.lsystem
    of Vk_rwin:         Key.rsystem
    of Vk_apps:         Key.menu
    of Vk_escape:       Key.escape
    of Vk_oem1:         Key.semicolon
    of Vk_oem2:         Key.slash
    of Vk_oem_plus:     Key.equal
    of Vk_oem_minus:    Key.minus
    of Vk_oem4:         Key.lbracket
    of Vk_oem6:         Key.rbracket
    of Vk_oem_comma:    Key.comma
    of Vk_oem_period:   Key.dot
    of Vk_oem7:         Key.quote
    of Vk_oem5:         Key.backslash
    of Vk_oem3:         Key.tilde
    of Vk_space:        Key.space
    of Vk_return:       Key.enter
    of Vk_back:         Key.backspace
    of Vk_tab:          Key.tab
    of Vk_prior:        Key.page_up
    of Vk_next:         Key.page_down
    of Vk_end:          Key.End
    of Vk_home:         Key.home
    of Vk_insert:       Key.insert
    of Vk_delete:       Key.del
    of Vk_add:          Key.add
    of Vk_subtract:     Key.subtract
    of Vk_multiply:     Key.multiply
    of Vk_divide:       Key.divide
    of Vk_capital:      Key.capsLock
    of Vk_numLock:      Key.numLock
    of Vk_scroll:       Key.scrollLock
    of Vk_snapshot:     Key.printScreen
    of Vk_print:        Key.printScreen
    of Vk_decimal:      Key.npadDot
    of Vk_pause:        Key.pause
    of Vk_f1:           Key.f1
    of Vk_f2:           Key.f2
    of Vk_f3:           Key.f3
    of Vk_f4:           Key.f4
    of Vk_f5:           Key.f5
    of Vk_f6:           Key.f6
    of Vk_f7:           Key.f7
    of Vk_f8:           Key.f8
    of Vk_f9:           Key.f9
    of Vk_f10:          Key.f10
    of Vk_f11:          Key.f11
    of Vk_f12:          Key.f12
    of Vk_f13:          Key.f13
    of Vk_f14:          Key.f14
    of Vk_f15:          Key.f15
    of Vk_left:         Key.left
    of Vk_right:        Key.right
    of Vk_up:           Key.up
    of Vk_down:         Key.down
    of Vk_numpad0:      Key.npad0
    of Vk_numpad1:      Key.npad1
    of Vk_numpad2:      Key.npad2
    of Vk_numpad3:      Key.npad3
    of Vk_numpad4:      Key.npad4
    of Vk_numpad5:      Key.npad5
    of Vk_numpad6:      Key.npad6
    of Vk_numpad7:      Key.npad7
    of Vk_numpad8:      Key.npad8
    of Vk_numpad9:      Key.npad9
    of 'A'.ord:         Key.a
    of 'B'.ord:         Key.b
    of 'C'.ord:         Key.c
    of 'D'.ord:         Key.d
    of 'E'.ord:         Key.e
    of 'F'.ord:         Key.f
    of 'G'.ord:         Key.g
    of 'H'.ord:         Key.h
    of 'I'.ord:         Key.i
    of 'J'.ord:         Key.j
    of 'K'.ord:         Key.k
    of 'L'.ord:         Key.l
    of 'M'.ord:         Key.m
    of 'N'.ord:         Key.n
    of 'O'.ord:         Key.o
    of 'P'.ord:         Key.p
    of 'Q'.ord:         Key.q
    of 'R'.ord:         Key.r
    of 'S'.ord:         Key.s
    of 'T'.ord:         Key.t
    of 'U'.ord:         Key.u
    of 'V'.ord:         Key.v
    of 'W'.ord:         Key.w
    of 'X'.ord:         Key.x
    of 'Y'.ord:         Key.y
    of 'Z'.ord:         Key.z
    of '0'.ord:         Key.n0
    of '1'.ord:         Key.n1
    of '2'.ord:         Key.n2
    of '3'.ord:         Key.n3
    of '4'.ord:         Key.n4
    of '5'.ord:         Key.n5
    of '6'.ord:         Key.n6
    of '7'.ord:         Key.n7
    of '8'.ord:         Key.n8
    of '9'.ord:         Key.n9
    else:               Key.unknown
  
  proc wkeyToKey(key: WParam, flags: LParam): Key =
    let scancode = ((flags and 0xff0000) shr 16).Uint
    case key
    of Vk_shift:
      let key = MapVirtualKey(scancode, Map_vkVsc_to_vkEx)
      if key == Vk_lshift: Key.lshift else: Key.rshift
    of Vk_menu:
      if (flags and 0x1000000) != 0: Key.ralt else: Key.lalt
    of Vk_control:
      if (flags and 0x1000000) != 0: Key.rcontrol else: Key.lcontrol
    else: wkeyToKey(key)

  # todo: multiscreen support
  proc getScreenCount*(): int = 1

  proc screen*(n: int = 0): Screen = discard
  proc defaultScreen*(): Screen = screen()
  proc n*(a: Screen): int = 0

  proc w*(this: Screen): int = GetSystemMetrics(SmCxScreen).int
  proc h*(this: Screen): int = GetSystemMetrics(SmCyScreen).int

template screenCount*: int = getScreenCount()
proc size*(this: Screen): IVec2 = ivec2(this.w.int32, this.h.int32)


when defined(linux):
  type WmForFramelessKind {.pure.} = enum
    unsupported
    motiv
    kwm
    other
  var framelessAtom: Atom
  var wmForFramelessKind: WmForFramelessKind

  proc init =
    x.init()
    wmForFramelessKind =
      if (framelessAtom = atomIfExist"_MOTIF_WM_HINTS"; framelessAtom != 0):
        WmForFramelessKind.motiv
      elif (framelessAtom = atomIfExist"KWM_WIN_DECORATION"; framelessAtom != 0):
        WmForFramelessKind.kwm
      elif (framelessAtom = atomIfExist"_WIN_HINTS"; framelessAtom != 0):
        WmForFramelessKind.other
      else:
        WmForFramelessKind.unsupported

  proc `=destroy`(this: var typeof(Window()[])) =
    if this.xinContext != nil:
      destroy this.xinContext
      this.xinContext = nil
    
    if this.xinMethod != nil:
      close this.xinMethod
      this.xinMethod = nil
    
    if this.xcursor != 0:
      destroy this.xcursor
      this.xcursor = x.Cursor(0)
    
    if this.xicon != 0:
      destroy this.xicon
      this.xicon = 0.Pixmap

    if this.xiconMask != 0:
      destroy this.xiconMask
      this.xiconMask = 0.Pixmap
    
    if this.xwin != 0:
      destroy this.xwin
      this.xwin = x.Window(0)
    
    # if this.xSyncCounter.int != 0:
    #   display.XSyncDestroyCounter(this.xSyncCounter)
    #   this.xSyncCounter = 0.XSyncCounter

  proc `=destroy`(this: var typeof(OpenglWindow()[])) =
    if this.ctx != nil:
      if glxCurrentContext() == this.ctx:
        0.makeCurrent nil.GlxContext
      destroy this.ctx
      this.ctx = nil
    `=destroy` cast[ptr typeof(Window()[])](this.addr)[]


  template invoke(event: proc, args) =
    when args is tuple:
      if event != nil: event(args)
    else:
      if event != nil: event((args,))

  proc releaseAllKeys(window: Window) =
    ## release all pressed keys
    ## needed when window loses focus
    let pressed = window.keyboard.pressed
    for k in pressed:
      window.keyboard.pressed.excl k
      window.onKeyup.invoke (k, false, false)

    for b in window.mouse.pressed:
      window.mouse.pressed.excl b
      window.onMouseup.invoke (b, false)
  
  proc pressAllKeys(window: Window) =
    ## press pressed in system keys and mouse buttons
    ## needed when window gets focus
    let keys = queryKeyboardState().mapit(xkeyToKey display.XKeycodeToKeysym(it.char, 0))
    for k in keys: # press pressed in system keys
      if k == Key.unknown: continue
      window.keyboard.pressed.incl k
      window.onKeydown.invoke (k, false, false)
    
    # todo: press pressed in system mouse buttons

  
  proc `frameless=`*(this: Window, v: bool) =
    case wmForFramelessKind
    of WmForFramelessKind.motiv:
      type MWMHints = object
        flags: culong
        functions: culong
        decorations: culong
        input_mode: culong
        status: culong
      
      var hints = MWMHints(flags: culong (if v: 1 else: 0) shl 1)
      discard display.XChangeProperty(
        this.xwin, framelessAtom, framelessAtom, 32, PropModeReplace,
        cast[cstring](hints.addr), MWMHints.sizeof div 4
      )

    of WmForFramelessKind.kwm, WmForFramelessKind.other:
      var hints: clong = if v: 0 else: 1
      discard display.XChangeProperty(
        this.xwin, framelessAtom, framelessAtom, 32, PropModeReplace,
        cast[cstring](hints.addr), clong.sizeof div 4
      )

    else: discard display.XSetTransientForHint(this.xwin, display.RootWindow(this.xscr))

  proc basicInitWindow(this: Window; size: IVec2; screen: Screen) =
    this.xscr = screen.id
    this.m_size = size

    this.m_hasFocus = true
    this.curCursor = some arrow

  proc setupWindow(this: Window, fullscreen, frameless: bool, class: string) =
    this.xwin.input = [
      ExposureMask, KeyPressMask, KeyReleaseMask, PointerMotionMask, ButtonPressMask,
      ButtonReleaseMask, StructureNotifyMask, EnterWindowMask, LeaveWindowMask, FocusChangeMask
    ]

    this.m_isFullscreen = fullscreen
    if fullscreen:
      this.xwin.netWmState = [atom"_NET_WM_STATE_FULLSCREEN"]
      this.m_size = window.screen().size

    this.xwin.wmProtocols = [atom"WM_DELETE_WINDOW"]

    this.xinMethod = display.XOpenIM(nil, nil, nil)
    if this.xinMethod != nil:
      this.xinContext = this.xinMethod.XCreateIC(
        XNClientWindow, this.xwin, XNFocusWindow, this.xwin, XnInputStyle, XimPreeditNothing or XimStatusNothing, nil
      )
    
    this.frameless = frameless

    # todo: enable xsync (sync render and display for window manager)
    # block xsync:
    #   var vEv, vEr: cint
    #   if display.XSyncQueryExtension(vEv.addr, vEr.addr):
    #     var vMaj, vMin: cint
    #     display.XSyncInitialize(vMaj.addr, vMin.addr)
    #     this.xSyncCounter = display.XSyncCreateCounter(XSyncValue())
    #     this.xwin.setProperty(
    #       atom"_NET_WM_SYNC_REQUEST_COUNTER",
    #       xaCardinal,
    #       32,
    #       @[this.xSyncCounter].asString
    #     )
    
    # set window VM class (can be used by window managers)
    block vmHint:
      var hint: XClassHint
      let name = getAppFilename()
      hint.res_name = name.cstring    # use filename as application name
      hint.res_class = class.cstring  # use class (same as title by default) as window class
      discard display.XSetClassHint(this.xwin, hint.addr)


  proc initWindow(this: Window; size: IVec2; screen: Screen, fullscreen, frameless, transparent: bool, class: string) =
    init()
    this.basicInitWindow size, screen
    
    if transparent:
      this.transparent = true
      let root = defaultRootWindow()

      var vi: XVisualInfo
      discard display.XMatchVisualInfo(this.xscr, if transparent: 32 else: 24, TrueColor, vi.addr)

      let cmap = display.XCreateColormap(root, vi.visual, AllocNone)
      var swa = XSetWindowAttributes(colormap: cmap)

      this.xwin = x.newWindow(
        root, ivec2(), size, 0, vi.depth, InputOutput, vi.visual,
        CwColormap or CwEventMask or CwBorderPixel or CwBackPixel, swa
      )
    else:
      this.xwin = newSimpleWindow(defaultRootWindow(), ivec2(), size, 0, 0, this.xscr.blackPixel)

    this.setupWindow fullscreen, frameless, class

    this.waitForReDraw = true
    this.gc = this.xwin.newGC(GCForeground or GCBackground)

  proc initOpenglWindow(this: OpenglWindow; size: IVec2; screen: Screen, fullscreen, frameless, transparent: bool, class: string) =
    init()
    this.basicInitWindow size, screen

    let root = defaultRootWindow()
    var vi: XVisualInfo
    discard display.XMatchVisualInfo(this.xscr, if transparent: 32 else: 24, TrueColor, vi.addr)
    let cmap = display.XCreateColormap(root, vi.visual, AllocNone)
    var swa = XSetWindowAttributes(colormap: cmap)
    this.xwin = x.newWindow(root, ivec2(), size, 0, vi.depth, InputOutput, vi.visual, CwColormap or CwEventMask or CwBorderPixel or CwBackPixel, swa)

    this.setupWindow fullscreen, frameless, class

    this.ctx = newGlxContext(vi.addr)
    this.xwin.makeCurrent this.ctx

  proc `title=`*(this: Window, title: string) =
    ## set window title
    this.xwin.netWmName = title
    this.xwin.netWmIconName = title
    display.Xutf8SetWMProperties(this.xwin, title, title, nil, 0, nil, nil, nil)

  proc opened*(this: Window): bool = not this.closed
  proc close*(this: Window) =
    ## close request
    if this.closed: return
    this.xwin.send this.xwin.newClientMessage(atom"WM_PROTOCOLS", [atom"WM_DELETE_WINDOW", CurrentTime])
    this.closed = true

  proc redraw*(window: Window) = window.waitForReDraw = true
    ## render request

  proc updateSize(window: Window, v: IVec2) =
    let osize = window.m_size
    window.m_size = v
    window.waitForReDraw = true
    window.bgraPixels = none seq[tuple[b, g, r, a: uint8]]
    window.onResize.invoke (osize, window.m_size, false)

  proc fullscreen*(window: Window): bool = window.m_isFullscreen
  proc `fullscreen=`*(window: Window, v: bool) =
    if window.m_isFullscreen == v: return

    window.xwin.root.send(
      window.xwin.newClientMessage(atom"_NET_WM_STATE", [Atom 2, atom"_NET_WM_STATE_FULLSCREEN"]), # 2 - switch, 1 - set true, 0 - set false
      SubstructureNotifyMask or SubstructureRedirectMask
    )

    discard XFlush display

  proc pos*(window: Window): IVec2 = window.xwin.geometry.pos
  proc `pos=`*(window: Window, p: IVec2) =
    ## move window
    ## do nothing if window is fullscreen
    if window.m_isFullscreen: return
    window.xwin.pos = p
    window.m_pos = p

  proc size*(window: Window): IVec2 = window.m_size
  proc `size=`*(window: Window, size: IVec2) =
    ## resize window
    ## exit fullscreen if window is fullscreen
    if window.fullscreen:
      window.fullscreen = false
    
    window.xwin.size = size
    window.updateSize size

  proc newPixmap(source: tuple[pixels: openarray[ColorBgrx], size: IVec2], window: Window): Pixmap =
    result = newPixmap(ivec2(source.size.x, source.size.y), window.xwin, window.xscr.defaultDepth)
    var image = asXImage(source.pixels, ivec2(source.size.x, source.size.y))
    result.newGC.put image.addr

  proc `cursor=`*(window: Window, kind: Cursor) =
    ## set cursor font, used when mouse hover window
    if window.curCursor.isSome and kind == window.curCursor.get: return
    if window.xcursor != 0: destroy window.xcursor
    case kind
    of Cursor.arrow:           window.xcursor = cursorFromFont XcLeftPtr
    of Cursor.arrowUp:         window.xcursor = cursorFromFont XcCenterPtr
    of Cursor.arrowRight:      window.xcursor = cursorFromFont XcRightPtr
    of Cursor.wait:            window.xcursor = cursorFromFont XcWatch
    of Cursor.arrowWait:       window.xcursor = cursorFromFont XcWatch #! no needed cursor
    of Cursor.pointingHand:    window.xcursor = cursorFromFont XcHand1
    of Cursor.grab:            window.xcursor = cursorFromFont XcHand2
    of Cursor.text:            window.xcursor = cursorFromFont XcXterm
    of Cursor.cross:           window.xcursor = cursorFromFont XcTCross
    of Cursor.sizeAll:         window.xcursor = cursorFromFont XcFleur
    of Cursor.sizeVertical:    window.xcursor = cursorFromFont XcSb_v_doubleArrow
    of Cursor.sizeHorisontal:  window.xcursor = cursorFromFont XcSb_h_doubleArrow
    of Cursor.sizeTopLeft:     window.xcursor = cursorFromFont XC_ul_angle
    of Cursor.sizeTopRight:    window.xcursor = cursorFromFont XC_ur_angle
    of Cursor.sizeBottomLeft:  window.xcursor = cursorFromFont XC_ll_angle
    of Cursor.sizeBottomRight: window.xcursor = cursorFromFont XC_lr_angle
    of Cursor.hided:
      var data: array[1, char]
      let blank = display.XCreateBitmapFromData(rootWindow(0), data[0].addr, 1, 1)
      var pass: XColor
      window.xcursor = x.Cursor display.XCreatePixmapCursor(blank, blank, pass.addr, pass.addr, 0, 0)
      discard display.XFreePixmap blank
    window.xwin.cursor = window.xcursor
    syncX()
    window.curCursor = some kind

  proc `cursor=`*(window: Window, image: tuple[pixels: openarray[ColorBgrx], size: IVec2, origin: IVec2]) =
    # todo: animated cursors
    if image.size.x * image.size.y == 0: window.cursor = Cursor.hided
    assert image.pixels.len >= image.size.x * image.size.y, "not enougth pixels"
    if window.xcursor != 0: destroy window.xcursor
    var pixels = image.pixels.toArgb
    var ci = CursorImage(
      ver: 1,
      normalSize: (if image.size.x > image.size.y: image.size.x.uint32 else: image.size.y.uint32),
      size: image.size,
      origin: image.origin,
      pixels: pixels[0].addr
    )
    window.xcursor = display.XcursorImageLoadCursor(ci.addr)
    window.xwin.cursor = window.xcursor
    syncX()
    window.curCursor = none Cursor
  
  proc `icon=`*(window: Window, _: nil.typeof) =
    ## clear window icon
    if window.xicon != 0: destroy window.xicon
    if window.xiconMask != 0: destroy window.xiconMask
    window.xicon = 0.Pixmap
    window.xiconMask = 0.Pixmap
    window.xwin.setWmHints(IconPixmapHint or IconMaskHint, 0.Pixmap, 0.Pixmap)

  proc `icon=`*(window: Window, image: tuple[pixels: openarray[ColorBgrx], size: IVec2]) =
    ## set window icon
    if image.size.x * image.size.y == 0: window.icon = nil
    assert image.pixels.len >= image.size.x * image.size.y, "not enougth pixels"
    if window.xicon != 0: destroy window.xicon
    if window.xiconMask != 0: destroy window.xiconMask

    window.xicon = newPixmap(image, window)

    # convert alpha channel to bit mask (semi-transparency is not supported)
    var mask =  newSeq[ColorBgrx](image.size.x * image.size.y)
    for i in 0..<(image.size.x * image.size.y):
      mask[i] = if image.pixels[i].a > 127: ColorBgrx(b: 0, g: 0, r: 0, a: 255) else: ColorBgrx(b: 255, g: 255, r: 255, a: 255)
    window.xiconMask = newPixmap((mask.toOpenarray(0, mask.high), image.size), window)

    window.xwin.setWmHints(IconPixmapHint or IconMaskHint, window.xicon, window.xiconMask)

  method drawImage*(window: Window, pixels: openarray[ColorRGBX]) {.base, deprecated: "use toBgrx to convert pixels into bgrx format".} =
    assert pixels.len == window.size.x * window.size.y, "pixels count must be width * height"
    var ximg =
      if window.transparent:
        if window.bgraPixels.isNone:
          window.bgraPixels = some newSeq[tuple[b, g, r, a: uint8]](window.size.x * window.size.y)
        for i, v in window.bgraPixels.get.mpairs: v = (pixels[i].b, pixels[i].g, pixels[i].r, pixels[i].a)
        asXImageTransparent(window.bgraPixels.get, window.size)
      else:
        asXImage(pixels, window.size)
    window.gc.put ximg.addr

  method drawImage*(this: OpenglWindow, pixels: openarray[ColorRGBX]) {.deprecated: "use toBgrx to convert pixels into bgrx format".} =
    ## do nothing

  method drawImage*(window: Window, pixels: openarray[ColorBgrx]) {.base, deprecated: "you must explicitly pass size of image, use drawImage(window, pixels, size)".} =
    assert pixels.len == window.size.x * window.size.y, "pixels count must be width * height"
    var ximg = asXImage(pixels, window.size, window.transparent)
    window.gc.put ximg.addr

  method drawImage*(window: OpenglWindow, pixels: openarray[ColorBgrx]) {.deprecated: "you must explicitly pass size of image, use drawImage(window, pixels, size)".} =
    ## do nothing

  proc drawImage*(window: Window, pixels: openarray[ColorBgrx], size: IVec2, pos: IVec2 = ivec2(), srcPos: IVec2 = ivec2()) =
    ## put pixels into window
    ## note: no blending is performed, even if image or/and window is transparent
    assert not(window of OpenglWindow), "drawImage is not allowed on Opengl windows. Create texture from image and use Opengl to draw it"
    assert pixels.len >= size.x * size.y, "not enougth pixels"
    var ximg = asXImage(pixels, size, window.transparent)
    window.gc.put(ximg.addr, srcPos=srcPos, destPos=pos)


  proc maximized*(window: Window): bool =
    let wmState = window.xwin.wmState
    atom"_NET_WM_STATE_MAXIMIZED_HORZ" in wmState and atom"_NET_WM_STATE_MAXIMIZED_VERT" in wmState

  proc `maximized=`*(window: Window, v: bool) =
    ## maximize/unmaximize window
    ## exit fullscreen if window is fullscreen
    if window.fullscreen:
      window.fullscreen = false
    window.xwin.wmStateSend(v.int, atom"_NET_WM_STATE_MAXIMIZED_HORZ")
    window.xwin.wmStateSend(v.int, atom"_NET_WM_STATE_MAXIMIZED_VERT")

  proc minimized*(window: Window): bool =
    let wmState = window.xwin.wmState
    (wmState.len >= 1 and 3.Atom in wmState) or (atom"_NET_WM_STATE_HIDDEN" in wmState)

  proc `minimized=`*(window: Window, v: bool) =
    ## minimize/unminimize window
    if v:
      window.releaseAllKeys
      discard display.XIconifyWindow(window.xwin, display.DefaultScreen)
    else:
      discard display.XRaiseWindow(window.xwin)
  

  proc visible*(window: Window): bool = window.m_visible
  proc `visible=`*(window: Window, v: bool) =
    ## show/hide window
    if v == window.m_visible: return
    window.m_visible = v
    if v:
      discard display.XMapRaised(window.xwin)
    else:
      discard display.XUnmapWindow(window.xwin)
  

  proc resizable*(window: Window): bool =
    var hints: XSizeHints
    discard display.XGetNormalHints(window.xwin, hints.addr)
    (hints.flags and 0b110000) != 0b110000
  
  proc `resizable=`*(window: Window, v: bool) =
    ## enable/disable resizing
    let size = window.size

    var hints: XSizeHints
    discard display.XGetNormalHints(window.xwin, hints.addr)
    if v: hints.flags = hints.flags and not 0b110000
    else: hints.flags = hints.flags or 0b110000
    (hints.minWidth, hints.minHeight) = size
    (hints.maxWidth, hints.maxHeight) = size
    discard display.XSetNormalHints(window.xwin, hints.addr)
  

  proc minSize*(window: Window): IVec2 =
    var hints: XSizeHints
    discard display.XGetNormalHints(window.xwin, hints.addr)
    ivec2(hints.minWidth, hints.minHeight)
  
  proc `minSize=`*(window: Window, v: IVec2) =
    ## set minimum size
    ## window.resizable=true will disable this
    var hints: XSizeHints
    discard display.XGetNormalHints(window.xwin, hints.addr)
    hints.flags = hints.flags or 0b010000
    (hints.minWidth, hints.minHeight) = v
    discard display.XSetNormalHints(window.xwin, hints.addr)

  
  proc maxSize*(window: Window): IVec2 =
    var hints: XSizeHints
    discard display.XGetNormalHints(window.xwin, hints.addr)
    ivec2(hints.maxWidth, hints.maxHeight)
  
  proc `maxSize=`*(window: Window, v: IVec2) =
    ## set maximum size
    ## window.resizable=true will disable this
    var hints: XSizeHints
    discard display.XGetNormalHints(window.xwin, hints.addr)
    hints.flags = hints.flags or 0b100000
    (hints.maxWidth, hints.maxHeight) = v
    discard display.XSetNormalHints(window.xwin, hints.addr)
  

  proc startInteractiveMove*(window: Window) =
    let pos = cursor().pos
    window.releaseAllKeys
    discard display.XUngrabPointer(0)
    discard XFlush display

    window.xwin.root.send(
      window.xwin.newClientMessage(
        atom"_NET_WM_MOVERESIZE",
        [pos.x.int64, pos.y.int64, 8, 1, 0] #? int32 is working strange, but int64 is ok
      ),
      SubstructureNotifyMask or SubstructureRedirectMask
    )
    # todo: press all keys and mouse buttons that are pressed after move
  
  proc startInteractiveResize*(window: Window, edge: Edge) =
    let pos = cursor().pos
    window.releaseAllKeys
    discard display.XUngrabPointer(0)
    discard XFlush display

    window.xwin.root.send(
      window.xwin.newClientMessage(
        atom"_NET_WM_MOVERESIZE",
        [
          pos.x.int64, pos.y.int64, #? int32 is working strange, but int64 is ok
          case edge
          of Edge.topLeft: 0
          of Edge.top: 1
          of Edge.topRight: 2
          of Edge.right: 3
          of Edge.bottomRight: 4
          of Edge.bottom: 5
          of Edge.bottomLeft: 6
          of Edge.left: 7,
          1, 0
        ]
      ),
      SubstructureNotifyMask or SubstructureRedirectMask
    )
    # todo: press all keys and mouse buttons that are pressed after resize
  

  proc makeCurrent*(window: OpenglWindow) =
    window.xwin.makeCurrent window.ctx

  proc `vsync=`*(window: OpenglWindow, v: bool, silent = false) =
    if glxSwapIntervalExt != nil:
      display.glxSwapIntervalExt(window.xwin, if v: 1 else: 0)
    elif glxSwapIntervalMesa != nil:
      glxSwapIntervalMesa(if v: 1 else: 0)
    elif glxSwapIntervalSgi != nil:
      glxSwapIntervalSgi(if v: 1 else: 0)
    else:
      if not silent:
        raise OSError.newException("VSync is not supported")


  proc run*(this: Window, makeVisible = true) =
    ## run main loop of window
    # todo: run multiple windows

    if makeVisible:
      this.visible = true

    var ev: XEvent

    template button: MouseButton =
      case ev.xbutton.button
      of 1: MouseButton.left
      of 2: MouseButton.middle
      of 3: MouseButton.right
      of 8: MouseButton.backward
      of 9: MouseButton.forward
      else: MouseButton.left
    template isScroll: bool = ev.xbutton.button.int in 4..7
    template scrollDelta: float =
      case ev.xbutton.button
      of 4: -1
      of 5: 1
      else: 0

    this.m_pos = this.xwin.geometry.pos
    this.mouse.pos = x.cursor().pos - this.m_pos
    
    this.onResize.invoke (ivec2(), this.m_size, true)

    var lastClickTime: times.Time
    var lastTickTime = getTime()

    while not this.closed:
      var xevents: seq[XEvent]

      proc checkEvent(_: PDisplay, event: PXEvent, userData: XPointer): XBool {.cdecl.} =
        if cast[int](event.xany.window) == cast[int](userData): 1 else: 0
      while display.XCheckIfEvent(ev.addr, checkEvent, cast[XPointer](this.xwin)) == 1:
        xevents.add ev
      
      let catched = xevents.len > 0

      for ev in xevents.mitems:
        case ev.theType
        of Expose:
          redraw this

        of ClientMessage:
          if ev.xclient.data.l[0] == atom"WM_DELETE_WINDOW".clong:
            this.closed = true

          # elif ev.xclient.data.l[0] == atom"_NET_WM_SYNC_REQUEST".clong:
          #   this.lastSync = XSyncValue(
          #     lo: cast[uint32](ev.xclient.data.l[2]),
          #     hi: cast[int32](ev.xclient.data.l[3])
          #   )

        of ConfigureNotify:
          if ev.xconfigure.width != this.m_size.x or ev.xconfigure.height != this.m_size.y:
            this.updateSize ivec2(ev.xconfigure.width.int32, ev.xconfigure.height.int32)
          if ev.xconfigure.x.int != this.m_pos.x or ev.xconfigure.y.int != this.m_pos.y:
            let oldPos = this.m_pos
            this.m_pos = ivec2(ev.xconfigure.x.int32, ev.xconfigure.y.int32)
            this.mouse.pos = x.cursor().pos - this.m_pos
            this.onWindowMove.invoke (oldPos, this.m_pos)

          let state = this.xwin.netWmState
          if atom"_NET_WM_STATE_FULLSCREEN" in state != this.m_isFullscreen:
            this.m_isFullscreen = not this.m_isFullscreen
            this.onFullscreenChanged.invoke (this.m_isFullscreen)

        of MotionNotify:
          let oldPos = this.mouse.pos
          this.mouse.pos = ivec2(ev.xmotion.x.int32, ev.xmotion.y.int32)
          this.clicking = {}
          this.onMouseMove.invoke (oldPos, this.mouse.pos)

        of ButtonPress:
          if not isScroll:
            this.mouse.pressed.incl button
            this.clicking.incl button
            this.onMouseDown.invoke (button, true)
          elif scrollDelta != 0: this.onScroll.invoke (scrollDelta)
        of ButtonRelease:
          if not isScroll:
            let nows = getTime()
            this.mouse.pressed.excl button

            if button in this.clicking:
              this.onClick.invoke (button, this.mouse.pos, (nows - lastClickTime).inMilliseconds < 200)

            this.mouse.pressed.excl button
            lastClickTime = nows
            this.onMouseUp.invoke (button, false)

        of LeaveNotify:
          this.clicking = {}
          this.onMouseLeave.invoke (this.mouse.pos, ivec2(ev.xcrossing.x.int32, ev.xcrossing.y.int32))
        of EnterNotify:
          this.clicking = {}
          this.onMouseEnter.invoke (this.mouse.pos, ivec2(ev.xcrossing.x.int32, ev.xcrossing.y.int32))

        of FocusIn:
          this.m_hasFocus = true
          if this.xinContext != nil: XSetICFocus this.xinContext
          this.onFocusChanged.invoke (true)
          this.pressAllKeys
          
        of FocusOut:
          this.m_hasFocus = false
          if this.xinContext != nil: XUnsetICFocus this.xinContext
          this.onFocusChanged.invoke (false)
          this.releaseAllKeys

        of KeyPress:
          var key = Key.unknown
          block:
            var i = 0
            while i < 4 and key == Key.unknown:
              key = xkeyToKey(XLookupKeysym(ev.xkey.addr, i.cint))
              inc i
          if key != Key.unknown:
            let ev = ev
            let repeated = xevents.findBy(proc (a: XEvent): bool =
              a.theType == KeyRelease and a.xkey.keycode == ev.xkey.keycode and a.xkey.time - ev.xkey.time < 2
            ) >= 0
            this.keyboard.pressed.incl key
            this.onKeydown.invoke (key, true, repeated)

          if this.onTextInput != nil and this.xinContext != nil and (this.keyboard.pressed * {lcontrol, rcontrol, lalt, ralt}).len == 0:
            var status: Status
            var buffer: array[16, char]
            let length = this.xinContext.Xutf8LookupString(ev.xkey.addr, cast[cstring](buffer.addr), buffer.sizeof.cint, nil, status.addr)

            proc toString(str: openArray[char]): string =
              result = newStringOfCap(len(str))
              for ch in str:
                result.add ch

            if length > 0:
              let s = buffer[0..<length].toString()
              if s notin ["\u001B"]:
                this.onTextInput.invoke (s)

        of KeyRelease:
          var key = Key.unknown
          block:
            var i = 0
            while i < 4 and key == Key.unknown:
              key = xkeyToKey(XLookupKeysym(ev.xkey.addr, i.cint))
              inc i
          if key != Key.unknown:
            let ev = ev
            let repeated = xevents.findBy(proc (a: XEvent): bool =
              a.theType == KeyPress and a.xkey.keycode == ev.xkey.keycode and a.xkey.time - ev.xkey.time < 2
            ) >= 0
            this.keyboard.pressed.excl key
            this.onKeyup.invoke (key, false, repeated)

        else: discard

        if this.closed: break
      if this.closed: break

      if not catched: sleep(2)

      let nows = getTime()
      this.onTick.invoke (nows - lastTickTime)
      lastTickTime = nows

      if this.waitForReDraw:
        this.waitForReDraw = false
        this.onRender.invoke ()
        if this of OpenglWindow:
          this.xwin.toDrawable.glxSwapBuffers()
        # display.XSyncSetCounter(this.xSyncCounter, this.lastSync)

      if clipboardProcessEvents != nil: clipboardProcessEvents()

    this.onClose.invoke ()
    if this of OpenglWindow:
      `=destroy` this.OpenglWindow[]
    else:
      `=destroy` this[]


elif defined(windows):
  proc poolEvent(a: Window, message: Uint, wParam: WParam, lParam: LParam): LResult

  proc `=destroy`(this: var typeof(Window()[])) =
    DeleteDC this.hdc
    if this.buffer.pixels != nil:
      DeleteDC this.buffer.hdc
      DeleteObject this.buffer.bitmap
    if this.wicon != 0: DestroyIcon this.wicon
    if this.wcursor != 0: DestroyCursor this.wcursor
  
  proc `=destroy`(this: var typeof(OpenglWindow()[])) =
    if wglGetCurrentContext() == this.ctx:
      wglMakeCurrent(0, 0)
    wglDeleteContext this.ctx
    `=destroy` cast[ptr typeof(Window()[])](this.addr)[]

  proc windowProc(handle: HWnd, message: Uint, wParam: WParam, lParam: LParam): LResult {.stdcall.} =
    let win = if handle != 0: cast[Window](GetWindowLongPtr(handle, GwlpUserData)) else: nil

    if win != nil: win.poolEvent(message, wParam, lParam)
    else:          DefWindowProc(handle, message, wParam, lParam)
  
  const
    wClassName = "w"
    woClassName = "o"
  
  block winapiInit:
    var wcex = WndClassEx(
      cbSize:        WndClassEx.sizeof.int32,
      style:         CsHRedraw or CsVRedraw or CsDblClks,
      hInstance:     hInstance,
      hCursor:       LoadCursor(0, IdcArrow),
      lpfnWndProc:   windowProc,
      lpszClassName: wClassName,
    )
    RegisterClassEx(&wcex)

    wcex.lpszClassName = woClassName
    RegisterClassEx(&wcex)

  template pushEvent(this: Window, event, args) =
    if this.event != nil:
      this.event(when args is tuple: args else: (args,))

  proc updateSize(this: Window) =
    let rect = this.handle.clientRect
    let osize = this.m_size
    this.m_size = ivec2(rect.right.int32, rect.bottom.int32)
    if osize == this.m_size: return

    this.pushEvent onResize, (osize, this.m_size, false)

  proc fullscreen*(a: Window): bool = a.m_isFullscreen
  proc `fullscreen=`*(this: Window, v: bool) =
    if this.m_isFullscreen == v: return
    this.m_isFullscreen = v
    if v:
      this.handle.SetWindowLongPtr(GwlStyle, WsVisible)
      discard this.handle.ShowWindow(SwMaximize)
    else:
      this.handle.ShowWindow(SwShowNormal)
      discard this.handle.SetWindowLongPtr(GwlStyle, WsVisible or WsOverlappedWindow)
    this.updateSize()
    this.pushEvent onFullscreenChanged, (v)

  proc size*(this: Window): IVec2 = this.m_size
  proc `size=`*(this: Window, size: IVec2) =
    this.fullscreen = false
    let rcClient = this.handle.clientRect
    var rcWind = this.handle.windowRect
    let borderx = (rcWind.right - rcWind.left) - rcClient.right
    let bordery = (rcWind.bottom - rcWind.top) - rcClient.bottom
    this.handle.MoveWindow(rcWind.left, rcWind.top, (size.x + borderx).int32, (size.y + bordery).int32, True)
    this.updateSize()

  proc initWindow(this: Window; size: IVec2; screen: Screen, fullscreen, frameless, transparent: bool, class = wClassName) =
    this.handle = CreateWindow(
      class,
      "",
      if frameless: WsPopup or WsSysMenu
      else: WsOverlappedWindow,
      CwUseDefault,
      CwUseDefault,
      size.x, size.y,
      0, 0,
      hInstance,
      nil
    )
    discard ShowWindow(this.handle, SwHide)

    this.m_hasFocus = true  #? is it correct?
    this.curCursor = some arrow
    this.wcursor = LoadCursor(0, IdcArrow)
    this.handle.SetWindowLongPtrW(GwlpUserData, cast[LongPtr](this))
    this.handle.trackMouseEvent(TmeHover)
    this.size = size
    this.hdc = this.handle.GetDC
    
    this.fullscreen = fullscreen

    if transparent:
      this.transparent = true

      let region = CreateRectRgn(0, 0, -1, -1)
      defer: discard DeleteObject(region)

      var bb = DwmBlurBehind()
      bb.dwFlags = DwmbbEnable or DwmbbBlurRegion
      bb.hRgnBlur = region
      bb.fEnable = True

      this.handle.DwmEnableBlurBehindWindow(bb.addr)

  proc initOpenglWindow(this: OpenglWindow; size: IVec2; screen: Screen, fullscreen, frameless, transparent: bool) =
    this.initWindow size, screen, fullscreen, frameless, transparent, woClassName
    
    this.waitForReDraw = true

    var pfd = PixelFormatDescriptor(
      nSize: Word PixelFormatDescriptor.sizeof,
      nVersion: 1,
      dwFlags: Pfd_draw_to_window or Pfd_support_opengl or Pfd_double_buffer,
      iPixelType: Pfd_type_rgba,
      cColorBits: 32,
      cDepthBits: 24,
      cStencilBits: 8,
      iLayerType: Pfd_main_plane,
    )
    this.hdc.SetPixelFormat(this.hdc.ChoosePixelFormat(&pfd), &pfd)
    this.ctx = wglCreateContext(this.hdc)
    doassert this.hdc.wglMakeCurrent(this.ctx)


  proc `title=`*(this: Window, title: string) =
    this.handle.SetWindowText(title)

  proc opened*(window: Window): bool = not window.closed
  proc close*(window: Window) =
    if not window.closed: window.handle.SendMessage(WmClose, 0, 0)

  proc redraw*(this: Window) =
    var cr = this.handle.clientRect
    this.handle.InvalidateRect(&cr, false)
  
  proc redraw*(a: OpenglWindow) = a.waitForReDraw = true

  proc pos*(this: Window): IVec2 =
    let r = this.handle.clientRect
    ivec2(r.left.int32, r.top.int32)
  
  proc `pos=`*(this: Window, v: IVec2) =
    if this.m_isFullscreen: return
    this.handle.SetWindowPos(0, v.x, v.y, 0, 0, SwpNoSize)

  proc `cursor=`*(this: Window, kind: Cursor) =
    if this.curCursor.isSome and kind == this.curCursor.get: return
    if this.wcursor != 0: DestroyCursor this.wcursor
    
    var cu: HCursor = case kind
    of Cursor.arrow:           LoadCursor(0, IdcArrow)
    of Cursor.arrowUp:         LoadCursor(0, IdcUpArrow)
    of Cursor.pointingHand:    LoadCursor(0, IdcHand)
    of Cursor.arrowRight:      LoadCursor(0, IdcArrow) #! no needed cursor
    of Cursor.wait:            LoadCursor(0, IdcWait)
    of Cursor.arrowWait:       LoadCursor(0, IdcAppStarting)
    of Cursor.grab:            LoadCursor(0, IdcHand) #! no needed cursor
    of Cursor.text:            LoadCursor(0, IdcIBeam)
    of Cursor.cross:           LoadCursor(0, IdcCross)
    of Cursor.sizeAll:         LoadCursor(0, IdcSizeAll)
    of Cursor.sizeVertical:    LoadCursor(0, IdcSizens)
    of Cursor.sizeHorisontal:  LoadCursor(0, IdcSizewe)
    of Cursor.sizeTopLeft:     LoadCursor(0, IdcSizenwse)
    of Cursor.sizeTopRight:    LoadCursor(0, IdcSizenesw)
    of Cursor.sizeBottomLeft:  LoadCursor(0, IdcSizenesw)
    of Cursor.sizeBottomRight: LoadCursor(0, IdcSizenwse)
    of Cursor.hided:           LoadCursor(0, IdcNo)
    
    if cu != 0:
      SetCursor cu
      this.wcursor = cu
    this.curCursor = some kind
  
  proc `cursor=`*(window: Window, image: tuple[pixels: openarray[ColorBgrx], size: IVec2, origin: IVec2]) =
    if image.size.x * image.size.y == 0: window.cursor = Cursor.hided
    assert image.pixels.len >= image.size.x * image.size.y, "not enougth pixels"
    if window.wcursor != 0: DestroyCursor window.wcursor
    let pixels = image.pixels.mapit (
      (it.b.float / it.a.float * 255).byte,
      (it.g.float / it.a.float * 255).byte,
      (it.r.float / it.a.float * 255).byte,
      it.a
    )
    window.wcursor = CreateIcon(hInstance, image.size.x, image.size.y, 1, 32, nil, cast[ptr Byte](pixels.dataAddr))
    SetCursor window.wcursor
    window.curCursor = none Cursor
  
  proc `icon=`*(this: Window, _: nil.typeof) =
    ## clear icon
    if this.wicon != 0:
      DestroyIcon this.wicon
      this.wicon = 0
    
    this.handle.SendMessageW(WmSetIcon, IconBig, 0)
    this.handle.SendMessageW(WmSetIcon, IconSmall, 0)

  proc `icon=`*(this: Window, image: tuple[pixels: openarray[ColorBgrx], size: IVec2]) =
    ## set icon
    if image.size.x * image.size.y == 0: this.icon = nil
    assert image.pixels.len >= image.size.x * image.size.y, "not enougth pixels"
    if this.wicon != 0: DestroyIcon this.wicon
    
    let pixels = image.pixels.mapit (
      (it.b.float / it.a.float * 255).byte,
      (it.g.float / it.a.float * 255).byte,
      (it.r.float / it.a.float * 255).byte,
      it.a
    )
    this.wicon = CreateIcon(hInstance, image.size.x, image.size.y, 1, 32, nil, cast[ptr Byte](pixels.dataAddr))
    this.handle.SendMessageW(WmSetIcon, IconBig, this.wicon)
    this.handle.SendMessageW(WmSetIcon, IconSmall, this.wicon)

  proc resizeBufferIfNeeded(this: Window, size: IVec2) =
    if size.x != this.buffer.x or size.y != this.buffer.y:
      if this.buffer.pixels != nil:
        DeleteDC this.buffer.hdc
        DeleteObject this.buffer.bitmap
      
      this.buffer.x = size.x
      this.buffer.y = size.y
    
      var bmi = BitmapInfo(
        bmiHeader: BitmapInfoHeader(
          biSize: BitmapInfoHeader.sizeof.int32, biWidth: size.x.Long, biHeight: -size.y.Long,
          biPlanes: 1, biBitCount: 32, biCompression: Bi_rgb
        )
      )
      this.buffer.bitmap = CreateDibSection(0, &bmi, Dib_rgb_colors, cast[ptr pointer](this.buffer.pixels.addr), 0, 0)
      this.buffer.hdc = CreateCompatibleDC(0)
      this.buffer.hdc.SelectObject this.buffer.bitmap

  method drawImage*(this: Window, pixels: openarray[ColorRGBX]) {.base, deprecated: "use toBgrx to convert pixels into bgrx format".} =
    assert pixels.len == this.size.x * this.size.y, "pixels count must be width * height"
    if this.size.x * this.size.y == 0: return
    
    resizeBufferIfNeeded this, this.size
    
    let rect = this.handle.clientRect
    for i, c in pixels:
      this.buffer.pixels[i] = ColorBgrx(b: c.b, g: c.g, r: c.r, a: c.a)
      
    this.hdc.BitBlt(0, 0, rect.right, rect.bottom, this.buffer.hdc, 0, 0, SrcCopy)

  method drawImage*(this: OpenglWindow, pixels: openarray[ColorRGBX]) = {.deprecated: "use toBgrx to convert pixels into bgrx format".}
    ## do nothing

  method drawImage*(this: Window, pixels: openarray[ColorBgrx]) {.base, deprecated: "you must explicitly pass size of image, use drawImage(window, pixels, size)".} =
    assert pixels.len == this.size.x * this.size.y, "pixels count must be width * height"
    if this.size.x * this.size.y == 0: return
    
    resizeBufferIfNeeded this, this.size
    
    let rect = this.handle.clientRect
    copyMem(this.buffer.pixels, pixels.dataAddr, pixels.len * ColorBgrx.sizeof)

    this.hdc.BitBlt(0, 0, rect.right, rect.bottom, this.buffer.hdc, 0, 0, SrcCopy)

  method drawImage*(this: OpenglWindow, pixels: openarray[ColorBgrx]) {.deprecated: "you must explicitly pass size of image, use drawImage(window, pixels, size)".} =
    ## do nothing

  proc drawImage*(window: Window, pixels: openarray[ColorBgrx], size: IVec2, pos: IVec2 = ivec2(), srcPos: IVec2 = ivec2()) =
    ## put pixels into window
    ## note: no blending is performed, even if image or/and window is transparent
    assert not(window of OpenglWindow), "drawImage is not allowed on Opengl windows. Create texture from image and use Opengl to draw it"
    assert pixels.len >= size.x * size.y, "not enougth pixels"    
    resizeBufferIfNeeded window, size
    copyMem(window.buffer.pixels, pixels.dataAddr, pixels.len * ColorBgrx.sizeof)
    window.hdc.BitBlt(pos.x, pos.y, size.x, size.y, window.buffer.hdc, srcPos.x, srcPos.y, SrcCopy)


  proc maximized*(window: Window): bool =
    IsZoomed(window.handle) != 0

  proc `maximized=`*(window: Window, v: bool) =
    ## maximize/unmaximize window
    ## exit fullscreen if window is fullscreen
    discard ShowWindow(window.handle, if v: SwMaximize else: SwRestore)

  proc minimized*(window: Window): bool =
    IsIconic(window.handle) != 0

  proc `minimized=`*(window: Window, v: bool) =
    ## minimize/unminimize window
    discard ShowWindow(window.handle, if v: SwMinimize else: SwRestore)


  proc visible*(window: Window): bool =
    IsWindowVisible(window.handle) != 0
  
  proc `visible=`*(window: Window, v: bool) =
    ## show/hide window
    discard ShowWindow(window.handle, if v: SwShow else: SwHide)


  proc resizable*(window: Window): bool =
    let style = GetWindowLongW(window.handle, GwlStyle)
    (style and WsThickframe) != 0
  
  proc `resizable=`*(window: Window, v: bool) =
    let style = GetWindowLongW(window.handle, GwlStyle)
    discard SetWindowLongW(window.handle, GwlStyle, if v: style or WsThickframe else: style and not WsThickframe)
    window.m_minSize = none IVec2
    window.m_maxSize = none IVec2


  proc minSize*(window: Window): IVec2 =
    if window.m_minSize.isNone: ivec2()
    else: window.m_minSize.get

  proc `minSize=`*(window: Window, v: IVec2) =
    window.m_minSize = some v
    let style = GetWindowLongW(window.handle, GwlStyle)
    discard SetWindowLongW(window.handle, GwlStyle, style or WsThickframe)
  

  proc maxSize*(window: Window): IVec2 =
    if window.m_maxSize.isNone: ivec2()
    else: window.m_maxSize.get

  proc `maxSize=`*(window: Window, v: IVec2) =
    window.m_maxSize = some v
    let style = GetWindowLongW(window.handle, GwlStyle)
    discard SetWindowLongW(window.handle, GwlStyle, style or WsThickframe)


  proc startInteractiveMove*(window: Window) =
    wasMoved window.mouse.pressed
    wasMoved window.keyboard.pressed
    ReleaseCapture()

    window.handle.PostMessage(WmSysCommand, 0xF012, 0)
    # todo: press all keys and mouse buttons that are pressed after move

  proc startInteractiveResize*(window: Window, edge: Edge) =
    wasMoved window.mouse.pressed
    wasMoved window.keyboard.pressed
    ReleaseCapture()

    window.handle.PostMessage(
      WmSysCommand,
      case edge
      of Edge.left: 0xf001
      of Edge.right: 0xf002
      of Edge.top: 0xf003
      of Edge.topLeft: 0xf004
      of Edge.topRight: 0xf005
      of Edge.bottom: 0xf006
      of Edge.bottomLeft: 0xf007
      of Edge.bottomRight: 0xf008,
      0
    )
    # todo: press all keys and mouse buttons that are pressed after resize


  proc makeCurrent*(window: OpenglWindow) =
    doassert window.hdc.wglMakeCurrent(window.ctx)

  proc `vsync=`*(window: OpenglWindow, v: bool, silent = false) =
    if wglSwapIntervalExt == nil:
      wglSwapIntervalExt = cast[typeof wglSwapIntervalExt](wglGetProcAddress("wglSwapIntervalEXT"))
    if wglSwapIntervalExt == nil or wglSwapIntervalExt(if v: 1 else: 0) == 0:
      if not silent:
        raise OSError.newException("failed to " & (if v: "enable" else: "disable") & " vsync")

  method displayImpl(this: Window) {.base.} =
    var ps: PaintStruct
    this.handle.BeginPaint(&ps)
    this.pushEvent onRender, ()
    this.handle.EndPaint(&ps)

  method displayImpl(this: OpenglWindow) =
    this.pushEvent onRender, ()

  proc run*(this: Window, makeVisible = true) =
    ## run main loop of window
    
    if makeVisible:
      this.visible = true

    this.pushEvent onResize, (ivec2(), this.m_size, true)
    this.waitForRedraw = true

    this.handle.UpdateWindow()

    var lastTickTime = getTime()
    var msg: Msg
    while not this.closed:
      var catched = false
      while PeekMessage(&msg, 0, 0, 0, PmRemove):
        catched = true
        TranslateMessage(&msg)
        DispatchMessage(&msg)

        # force make tick if windows decided to spam events to us
        if (getTime() - lastTickTime) > initDuration(milliseconds=10):
          break

        if this.closed: break
      if this.closed: break

      if not catched: sleep(2)

      let nows = getTime()
      this.pushEvent onTick, (nows - lastTickTime)
      lastTickTime = nows

  proc poolEvent(a: Window, message: Uint, wParam: WParam, lParam: LParam): LResult =
    template button: MouseButton =
      case message
      of WM_lbuttonDown, WM_lbuttonUp, WM_lbuttonDblclk: MouseButton.left
      of WM_rbuttonDown, WM_rbuttonUp, WM_rbuttonDblclk: MouseButton.right
      of WM_mbuttonDown, WM_mbuttonUp, WM_mbuttonDblclk: MouseButton.middle
      of WM_xbuttonDown, WM_xbuttonUp, WM_xbuttonDblclk:
        let button = wParam.GetXButtonWParam()
        case button
        of MkXButton1: MouseButton.backward
        of MkXButton2: MouseButton.forward
        else: MouseButton.left
      else: MouseButton.left

    result = 0

    case message
    of WmPaint:
      let rect = a.handle.clientRect
      if rect.right != a.m_size.x or rect.bottom != a.m_size.y:
        a.updateSize()
        a.waitForRedraw = true

      if a.m_size.x * a.m_size.y > 0:
        a.displayImpl()
        a.waitForRedraw = false
        if a of OpenglWindow:
          a.OpenglWindow.hdc.SwapBuffers

    of WmDestroy:
      a.pushEvent onClose, ()
      a.closed = true
      PostQuitMessage(0)

    of WmMouseMove:
      let opos = a.mouse.pos
      a.mouse.pos = ivec2(lParam.GetX_LParam.int32, lParam.GetY_LParam.int32)
      a.clicking = {}
      a.pushEvent onMouseMove, (opos, a.mouse.pos)

    of WmMouseLeave:
      let npos = ivec2(lParam.GetX_LParam.int32, lParam.GetY_LParam.int32)
      a.clicking = {}
      a.pushEvent onMouseLeave, (a.mouse.pos, npos)
      a.handle.trackMouseEvent(TmeHover)

    of WmMouseHover:
      let npos = ivec2(lParam.GetX_LParam.int32, lParam.GetY_LParam.int32)
      a.clicking = {}
      a.pushEvent onMouseEnter, (a.mouse.pos, npos)
      a.handle.trackMouseEvent(TmeLeave)

    of WmMouseWheel:
      let delta = if wParam.GetWheelDeltaWParam > 0: -1.0 else: 1.0
      a.pushEvent onScroll, (delta)

    of WmSetFocus:
      a.m_hasFocus = true
      a.pushEvent onFocusChanged, (a.m_hasFocus)

      let keys = getKeyboardState().mapit(wkeyToKey(it))
      for k in keys: # press pressed in system keys
        if k == Key.unknown: continue
        a.keyboard.pressed.incl k
        a.pushEvent onKeydown, (k, false, false)

    of WmKillFocus:
      a.m_hasFocus = false
      a.pushEvent onFocusChanged, (a.m_hasFocus)
      let pressed = a.keyboard.pressed
      for key in pressed: # release all keys
        a.keyboard.pressed.excl key
        a.pushEvent onKeyup, (key, false, false)

    of WmLButtonDown, WmRButtonDown, WmMButtonDown, WmXButtonDown:
      a.handle.SetCapture()
      a.mouse.pressed.incl button
      a.clicking.incl button
      a.pushEvent onMouseDown, (button, true)

    of WmLButtonDblclk, WmRButtonDblclk, WmMButtonDblclk, WmXButtonDblclk:
      a.handle.SetCapture()
      a.mouse.pressed.incl button
      a.pushEvent onClick, (button, a.mouse.pos, true)

    of WmLButtonUp, WmRButtonUp, WmMButtonUp, WmXButtonUp:
      ReleaseCapture()
      a.mouse.pressed.excl button
      if button in a.clicking: a.pushEvent onClick, (button, a.mouse.pos, false)
      a.pushEvent onMouseUp, (button, false)

    of WmKeyDown, WmSysKeyDown:
      let key = wkeyToKey(wParam, lParam)
      if key != Key.unknown:
        let repeated = key in a.keyboard.pressed
        a.keyboard.pressed.incl key
        a.pushEvent onKeydown, (key, true, repeated)

    of WmKeyUp, WmSysKeyUp:
      let key = wkeyToKey(wParam, lParam)
      if key != Key.unknown:
        let repeated = key notin a.keyboard.pressed
        a.keyboard.pressed.excl key
        a.pushEvent onKeyup, (key, false, repeated)

    of WmChar, WmSyschar, WmUnichar:
      if a.onTextInput == nil: return 1  # no need to handle
      if (a.keyboard.pressed * {lcontrol, rcontrol, lalt, ralt}).len == 0:
        let s = %$[wParam.WChar]
        if s.len > 0 and s notin ["\u001B"]:
          a.pushEvent onTextInput, (s)

    of WmSetCursor:
      if lParam.LoWord == HtClient:
        SetCursor a.wcursor
        return 1
      return a.handle.DefWindowProc(message, wParam, lParam)
    
    of WmGetMinMaxInfo:
      let info = cast[LpMinMaxInfo](lParam)
      if a.m_minSize.isSome:
        (info[].ptMinTrackSize.x, info[].ptMinTrackSize.y) = a.m_minSize.get
      if a.m_maxSize.isSome:
        (info[].ptMaxTrackSize.x, info[].ptMaxTrackSize.y) = a.m_maxSize.get

    else: return a.handle.DefWindowProc(message, wParam, lParam)

else:
  {.error: "current OS is not supported".}


proc newWindow*(
  size = ivec2(1280, 720),
  title = "",
  screen = screen(),
  fullscreen = false,
  frameless = false,
  transparent = false,

  class = "", # window class (used in x11), equals to title if not specified
): Window =
  new result
  when defined(linux):
    result.initWindow(size, screen, fullscreen, frameless, transparent, (if class == "": title else: class))
  else:
    result.initWindow(size, screen, fullscreen, frameless, transparent)
  result.title = title

proc newOpenglWindow*(
  size = ivec2(1280, 720),
  title = "",
  screen = screen(),
  fullscreen = false,
  frameless = false,
  transparent = false,
  vsync = true,

  class = "", # window class (used in x11), equals to title if not specified
): OpenglWindow =
  new result
  when defined(linux):
    result.initOpenglWindow(size, screen, fullscreen, frameless, transparent, (if class == "": title else: class))
  else:
    result.initOpenglWindow(size, screen, fullscreen, frameless, transparent)
  result.title = title
  result.`vsync=`(vsync, silent=true)
