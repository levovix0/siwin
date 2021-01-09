import times, os
import image, utils
when defined(linux):
  import strformat, options
  import libx11 as x
  import libglx
  from nimgl/opengl import glInit
when defined(windows):
  import libwinapi
  type Color = image.Color




publicInterface:
  Window:
    close() {.lazy.}
    opened -> bool

    onEvent => proc(Event)

    fullscreen => bool {.lazy.}
    size => Vec2
    position => Vec2

    cursor = Cursor
    icon = Picture|nil
  
  OpenglWindow of Window:
    onRender => proc(OpneglRenderer)
    redraw() {.lazy.}

  PictureWindow of Window:
    onRender => proc(Renderer)
    getPicture -> Picture
    redraw() {.lazy.}

  newWindow(w, h: int, title: string, Screen, RenderEngine)
  newWindow(size: Vec2, title: string, Screen, RenderEngine)
  run SomeWindow
  
  MouseButton enum
  Mouse:
    position -> Vec2
    pressed[MouseButton] -> bool
  Cursor enum
  
  Key enum
  Keyboard:
    pressed[Key] -> bool

  Screen:
    screen(void|int)

    size -> Vec2




type
  MouseButton* {.pure.} = enum
    left right middle forward backward
  AllMouseButtons* = MouseButton.left..MouseButton.backward
  Mouse* = tuple
    position: tuple[x, y: int]
    pressed: array[AllMouseButtons, bool]

  Key* {.pure.} = enum
    unknown = -1

    a = 0, b c d e f g h i j k l m n o p q r s t u v w x y z
    tilde n1 n2 n3 n4 n5 n6 n7 n8 n9 n0 minus equal
    f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15
    lcontrol rcontrol  lshift rshift  lalt ralt  lsystem rsystem  lbracket rbracket
    space escape enter tab backspace menu
    slash dot comma  semicolon quote  backslash

    pageUp pageDown  home End  insert del
    left right up down
    npad0 npad1 npad2 npad3 npad4 npad5 npad6 npad7 npad8 npad9
    add subtract multiply divide

    pause
  AllKeys* = Key.a..Key.pause

  Keyboard* = tuple
    pressed: array[AllKeys, bool]

  Cursor* {.pure.} = enum
    arrow arrowUp
    hand
    sizeAll sizeHorisontal sizeVertical

type
  Screen* = object
    when defined(linux):
      id: cint
      xid: PScreen

type
  Window* {.inheritable.} = object
    onClose*:       proc(e: CloseEvent)
    
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
    onDoubleClick*: proc(e: ClickEvent)
    onScroll*:      proc(e: ScrollEvent)

    keyboard*: Keyboard
    onKeydown*:     proc(e: KeyEvent)
    onKeyup*:       proc(e: KeyEvent)
    onTextEnter*:   proc(e: TextEnterEvent)

    m_size: tuple[x, y: int]
      
    m_isOpen: bool
    m_hasFocus: bool
    m_isFullscreen: bool

    clicking: array[AllMouseButtons, bool]

    when defined(linux):
      xscr: cint
      xwin: x.Window
      xicon: Pixmap
      xiconMask: Pixmap
      xinContext: XIC
      xinMethod: XIM

      xcursor: x.Cursor
      curCursor: Cursor

      m_pos: tuple[x, y: int]
      requestedSize: Option[tuple[x, y: int]]

    elif defined(windows):
      handle: HWnd
      wimage: HBitmap
      hdc: HDC
      wicon: HIcon
      
      wcursor: HCursor
      curCursor: Cursor
  
  PictureWindow* = object of Window
    onRender*: proc(e: PictureRenderEvent)

    when defined(linux):
      gc: GraphicsContext
      ximg: PXImage

      m_data: ArrayPtr[Color]
      waitForReDraw: bool

    elif defined(windows):
      wimage: HBitmap
      hdc: HDC
  
  OpenglWindow* = object of Window
    onRender*: proc(e: OpenglRenderEvent)
    
    when defined(linux):
      waitForReDraw: bool

  SomeWindow = Window|PictureWindow|OpenglWindow
  RenderEngine* {.pure.} = enum
    none
    picture
    opengl


  CloseEvent* = tuple

  PictureRenderEvent* = tuple
    data: ArrayPtr[Color]
    size: tuple[x, y: int]
  OpenglRenderEvent* = tuple
  ResizeEvent* = tuple
    oldSize, size: tuple[x, y: int]
  WindowMoveEvent* = tuple
    oldPosition, position: tuple[x, y: int]

  MouseMoveEvent* = tuple
    mouse: Mouse
    oldPosition, position: tuple[x, y: int]
  MouseButtonEvent* = tuple
    mouse: Mouse
    button: MouseButton
    pressed: bool
  ClickEvent* = tuple
    mouse: Mouse
    button: MouseButton
    position: tuple[x, y: int]
    doubleClick: bool
  ScrollEvent* = tuple
    mouse: Mouse
    delta: float ## 1: scroll down, -1: scroll up

  FocusEvent* = tuple
    focused: bool
  StateChangedEvent* = tuple
    state: bool

  TickEvent* = tuple
    mouse: Mouse
    keyboard: Keyboard
    deltaTime: Duration

  KeyEvent* = tuple
    keyboard: Keyboard
    key: Key
    pressed: bool
    alt, control, shift, system: bool
  TextEnterEvent* = tuple
    keyboard: Keyboard
    text: string # строка, т.к. введённый символ может быть закодирован в unicode

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
    of Xk_e:            Key.r
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

  template d: x.PDisplay = x.display

  proc getScreenCount*(): int = d.ScreenCount.int

  proc screen*(n: int): Screen = with result:
    if n notin 0..<getScreenCount(): raise IndexDefect.newException(&"screen {n} is not exist")
    id = n.cint
    xid = d.ScreenOfDisplay(id)

  proc defaultScreen*(): Screen = screen(d.DefaultScreen.int)
  proc screen*(): Screen = defaultScreen()

  proc n*(a: Screen): int = a.id.int

  proc size*(a: Screen): tuple[x, y: int] =
    result = (a.xid.width.int, a.xid.height.int)
  
  proc rootWindow(a: Screen): x.Window {.used.} = x.Window a.xid.root

elif defined(windows):
  proc wkeyToKey(key: WParam, flags: LParam): Key =
    case key
    of VK_shift:
      let lshift = MapVirtualKeyW(VK_shift, MAPVK_VK_TO_VSC)
      let scancode = flags and ((0xFF shl 16) shr 16)
      if scancode == lshift: Key.lshift else: Key.rshift
    of VK_menu:
      if (flags and KF_EXTENDED) != 0: Key.ralt else: Key.lalt
    of VK_control:
      if (flags and KF_EXTENDED) != 0: Key.rcontrol else: Key.lcontrol
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
    of 'E'.ord:         Key.r
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

  #TODO: многоэкранность
  proc getScreenCount*(): int = 1

  proc screen*(n: int = 0): Screen = discard
  proc defaultScreen*(): Screen = screen()
  proc n*(a: Screen): int = 0

  proc size*(a: Screen): tuple[x, y: int] =
    result.x = GetSystemMetrics(SmCxScreen).int
    result.y = GetSystemMetrics(SmCyScreen).int

template screenCount*: int = getScreenCount()



when defined(linux):
  proc `=destroy`*(a: var Window) {.with.} =
    if xinContext != nil: destroy xinContext
    if xinMethod != nil: close xinMethod
    if xcursor != 0: destroy xcursor
    if xicon != 0: destroy xicon
    if xiconMask != 0: destroy xiconMask
    destroy xwin

  proc `=destroy`*(a: var PictureWindow) {.with.} =
    destroy ximg
    `=destroy` a.Window
  
  proc `=destroy`*(a: var OpenglWindow) {.with.} =
    nil.GlxContext.target = 0
    `=destroy` a.Window
  
  proc initWindow(a: var Window; w, h: int; screen: Screen) {.with.} =
    xscr = screen.id
    m_size = (w, h)

    m_isOpen = true
    m_hasFocus = true
    curCursor = arrow

  proc setupWindow(a: var Window, fullscreen: bool) {.with.} =
    xwin.input = [ 
      ExposureMask, KeyPressMask, KeyReleaseMask, PointerMotionMask, ButtonPressMask,
      ButtonReleaseMask, StructureNotifyMask, EnterWindowMask, LeaveWindowMask, FocusChangeMask
    ]
    
    m_isFullscreen = fullscreen
    if fullscreen:
      xwin.netWmState = [NetWmStateFullscreen]
      m_size = window.screen().size

    map xwin
    xwin.wmProtocols = [WmDeleteWindow]

    xinMethod = d.XOpenIM(nil, nil, nil)
    if xinMethod != nil:
      xinContext = xinMethod.XCreateIC(
        XNClientWindow, xwin, XNFocusWindow, xwin, XnInputStyle, XimPreeditNothing or XimStatusNothing, nil
      )

  proc initNoRenderWindow(a: var Window; w, h: int; screen: Screen, fullscreen: bool) {.with.} =
    a.initWindow w, h, screen
    xwin = newSimpleWindow(defaultRootWindow(), 0, 0, w, h, 0, 0, xscr.blackPixel)
    a.setupWindow fullscreen
  
  proc initPictureWindow(a: var PictureWindow; w, h: int; screen: Screen, fullscreen: bool) {.with.} =
    a.initWindow w, h, screen
    xwin = newSimpleWindow(defaultRootWindow(), 0, 0, w, h, 0, 0, xscr.blackPixel)
    a.setupWindow fullscreen

    waitForReDraw = true
    gc = xwin.newGC(GCForeground or GCBackground)

    m_data = malloc[Color](m_size.x * m_size.y)
    ximg = newXImage(m_size, m_data, xscr.defaultVisual, xscr.defaultDepth)
    doassert ximg != nil

  proc initOpenglWindow(a: var OpenglWindow; w, h: int; screen: Screen, fullscreen: bool) {.with.} =
    a.initWindow w, h, screen
    
    let root = defaultRootWindow()
    let vi = glxChooseVisual(0, [GlxRgba, GlxDepthSize, 24, GlxDoublebuffer])
    let cmap = d.XCreateColormap(root, vi.visual, AllocNone)
    var swa: XSetWindowAttributes
    swa.colormap = cmap
    xwin = x.newWindow(root, 0, 0, w, h, 0, vi.depth, InputOutput, vi.visual, CwColormap or CwEventMask, swa)
    
    a.setupWindow fullscreen

    let ctx = newGlxContext(vi)
    glxAssert ctx != nil
    ctx.target = xwin
    
    doassert glInit()

  template pushEvent(a: Window, event, args) =
    when args is tuple: 
      if a.event != nil: a.event(args)
    else:
      if a.event != nil: a.event((args,))

  proc `title=`*(a: Window, title: string) {.with.} =
    ## set window title
    xwin.netWmName = title
    xwin.netWmIconName = title
    d.Xutf8SetWMProperties(xwin, title, title, nil, 0, nil, nil, nil)
  
  proc opened*(a: Window): bool = a.m_isOpen
  proc close*(a: var Window) {.lazy, with.} =
    ## close request
    if not m_isOpen: return
    xwin.send xwin.newClientMessage(WmProtocols, [atom WmDeleteWindow, CurrentTime])
    m_isOpen = false

  proc redraw*(a: var PictureWindow) {.lazy.} = a.waitForReDraw = true
    ## render request
  proc redraw*(a: var OpenglWindow) {.lazy.} = a.waitForReDraw = true
    ## render request

  proc updateSize(a: var Window) {.with.} =
    m_size = xwin.geometry.size
  proc updateSize(a: var PictureWindow) {.with.} =
    updateSize a.Window
    destroy ximg
    m_data = malloc[Color](m_size.x * m_size.y)
    ximg = newXImage(m_size, m_data, xscr.defaultVisual, xscr.defaultDepth)
    waitForReDraw = true
  
  proc fullscreen*(a: Window): bool = a.m_isFullscreen
    ## get real fullscreen state of window
  proc `fullscreen=`*(a: var Window, v: bool) {.lazy, with.} =
    ## set fullscreen
    ##* this proc is lazy, don't try get size of window after it
    ## track when the fullscreen state will be applied in the onFullscreenChanged event
    if m_isFullscreen == v: return
    
    xwin.root.send(
      xwin.newClientMessage(NetWmState, [Atom 2, atom NetWmStateFullscreen]), # 2 - переключить, 1 - добавить, 0 - убрать
      SubstructureNotifyMask or SubstructureRedirectMask
    )
  
  proc position*(a: Window): tuple[x, y: int] = a.xwin.geometry.position
  proc `position=`*(a: var Window, p: tuple[x, y: int]) {.with.} =
    ## move window
    ## do nothing if window is fullscreen
    if m_isFullscreen: return
    xwin.position = p
    m_pos = p
  
  proc size*(a: Window): tuple[x, y: int] = a.m_size
  proc `size=`*(a: var Window, size: tuple[x, y: int]) {.with.} =
    ## resize window
    ## exit fullscreen if window is fullscreen
    if not a.fullscreen:
      xwin.size = size
      a.updateSize()
    else:
      a.fullscreen = false
      requestedSize = some size

  proc `cursor=`*(a: var Window, kind: Cursor) {.with.} =
    ## set cursor font, used when mouse hover window
    if kind == curCursor: return
    if xcursor != 0: destroy xcursor
    case kind
    of Cursor.arrow:          xcursor = cursorFromFont XcLeftPtr
    of Cursor.arrowUp:        xcursor = cursorFromFont XcCenterPtr
    of Cursor.hand:           xcursor = cursorFromFont XcHand1
    of Cursor.sizeAll:        xcursor = cursorFromFont XcFleur
    of Cursor.sizeVertical:   xcursor = cursorFromFont XcSb_v_doubleArrow
    of Cursor.sizeHorisontal: xcursor = cursorFromFont XcSb_h_doubleArrow
    xwin.cursor = xcursor
    syncX()
    curCursor = kind

  proc newPixmap(img: Picture, a: Window): Pixmap {.with: a.} =
    var ddata = malloc[Color](img.size.x * img.size.y)
    copyMem(ddata, img.data, Color.sizeof * img.size.x * img.size.y)
    let image = newXImage(img.size, ddata, xscr.defaultVisual, xscr.defaultDepth)
    
    result = newPixmap(img.size, xwin, xscr.defaultDepth)
    result.newGC.put image
    destroy image

  proc `icon=`*(a: var Window, img: Picture) {.with.} =
    ## set window icon
    if xicon != 0: destroy xicon
    if xiconMask != 0: destroy xiconMask

    xicon = newPixmap(img, a)

    var mask = newImage(img.size.x, img.size.y)
    for i in 0..<(img.size.x * img.size.y):
      mask.data[i] = if img.data[i].a > 127: color(0, 0, 0) else: color(255, 255, 255)
    xiconMask = newPixmap(mask, a)

    xwin.wmHints = newWmHints(xicon, xiconMask)
  proc `icon=`*(a: var Window, _: nil.typeof) {.with.} =
    ## clear window icon
    if xicon != 0: destroy xicon
    if xiconMask != 0: destroy xiconMask
    xicon = 0.Pixmap
    xiconMask = 0.Pixmap
    xwin.wmHints = newWmHints(xicon, xiconMask)

  proc run*(a: var SomeWindow) {.with.} =
    ## run main loop of window
    template pushEvent(event, args) = a.pushEvent(event, args)
    
    var ev: XEvent

    template button: MouseButton =
      case ev.xbutton.button
      of 1: MouseButton.left
      of 2: MouseButton.middle
      of 3: MouseButton.right
      of 8: MouseButton.backward
      of 9: MouseButton.forward
      else: MouseButton.left
    template scrollDelta: float =
      case ev.xbutton.button
      of 4: -1
      of 5: 1
      else: 0
    template isScroll: bool = ev.xbutton.button.int in 4..7

    var lastClickTime: times.Time
    var lastTickTime = getTime()
    
    while m_isOpen:
      var catched = false

      proc checkEvent(_: PDisplay, event: PXEvent, userData: XPointer): XBool {.cdecl.} =
        if cast[int](event.xany.window) == cast[int](userData): 1 else: 0
      while d.XCheckIfEvent(ev.addr, checkEvent, cast[XPointer](xwin)) == 1:
        catched = true

        case ev.theType
        of Expose:
          if ev.xexpose.width != m_size.x or ev.xexpose.height != m_size.y:
            let osize = m_size
            a.updateSize()
            pushEvent onResize, (osize, m_size)
          when a is PictureWindow|OpenglWindow:
            redraw a
        of ClientMessage:
          if ev.xclient.data.l[0] == atom(WmDeleteWindow).clong:
            m_isOpen = false
          
        of ConfigureNotify:
          if ev.xconfigure.width != m_size.x or ev.xconfigure.height != m_size.y:
            let osize = m_size
            a.updateSize()
            pushEvent on_resize, (osize, m_size)
          if ev.xconfigure.x.int != m_pos.x or ev.xconfigure.y.int != m_pos.y:
            let oldPos = m_pos
            m_pos = (ev.xconfigure.x.int, ev.xconfigure.y.int)
            pushEvent onWindowMove, (oldPos, m_pos)
          
          let state = xwin.netWmState
          if atom(NetWmStateFullscreen) in state != m_isFullscreen:
            m_isFullscreen = not m_isFullscreen
            pushEvent onFullscreenChanged, (m_isFullscreen)
            if not m_isFullscreen and isSome a.requestedSize:
              a.size = get a.requestedSize
              a.requestedSize = none tuple[x, y: int]

        of MotionNotify:
          let oldPos = mouse.position
          mouse.position = (ev.xmotion.x.int, ev.xmotion.y.int)
          for v in clicking.mitems: v = false
          pushEvent onMouseMove, (mouse, oldPos, mouse.position)

        of ButtonPress:
          if not isScroll:
            mouse.pressed[button] = true
            clicking[button] = true
            pushEvent onMouseDown, (mouse, button, true)
          elif scrollDelta != 0: pushEvent onScroll, (mouse, scrollDelta)
        of ButtonRelease:
          if not isScroll:
            let nows = getTime()
            mouse.pressed[button] = false
            
            if clicking[button]:
              if (nows - lastClickTime).inMilliseconds < 200: pushEvent onDoubleClick, (mouse, button, mouse.position, true)
              else: pushEvent onClick, (mouse, button, mouse.position, false)

            mouse.pressed[button] = false
            lastClickTime = nows
            pushEvent onMouseUp, (mouse, button, false)

        of LeaveNotify:
          pushEvent onMouseLeave, (mouse, mouse.position, (ev.xcrossing.x.int, ev.xcrossing.y.int))
        of EnterNotify:
          pushEvent onMouseEnter, (mouse, mouse.position, (ev.xcrossing.x.int, ev.xcrossing.y.int))

        of FocusIn:
          m_hasFocus = true
          if xinContext != nil: XSetICFocus xinContext
          pushEvent onFocusChanged, (true)
        of FocusOut:
          m_hasFocus = false
          if xinContext != nil: XUnsetICFocus xinContext
          pushEvent onFocusChanged, (false)

          for key, k in keyboard.pressed.mpairs: # отпустить все клавиши
            if k:
              template mk(a): bool = (ev.xkey.state and a).bool
              pushEvent onKeyup, (keyboard, key, false, mk Mod1Mask, mk ControlMask, mk ShiftMask, mk Mod4Mask)
              k = false
        
        of KeyPress:
          var key = Key.unknown
          block:
            var i = 0
            while i < 4 and key == Key.unknown:
              key = xkeyToKey(XLookupKeysym(ev.xkey.addr, i.cint))
              inc i
          if key != Key.unknown:
            keyboard.pressed[key] = true
            template mk(a): bool = (ev.xkey.state and a).bool
            pushEvent onKeydown, (keyboard, key, true, mk Mod1Mask, mk ControlMask, mk ShiftMask, mk Mod4Mask)
          
          if xinContext != nil and not keyboard.pressed[lcontrol] and not keyboard.pressed[rcontrol] and not keyboard.pressed[lalt] and not keyboard.pressed[ralt]:
            var status: Status
            var buffer: array[16, char]
            let length = Xutf8LookupString(xinContext, ev.xkey.addr, cast[cstring](buffer.addr), buffer.sizeof.cint, nil, status.addr)

            proc toString(str: openArray[char]): string =
              result = newStringOfCap(len(str))
              for ch in str:
                result.add ch

            if length > 0:
              let s = buffer[0..<length].toString()
              if s notin ["\u001B"]:
                pushEvent onTextEnter, (keyboard, s)
        
        of KeyRelease:
          var key = Key.unknown
          block:
            var i = 0
            while i < 4 and key == Key.unknown:
              key = xkeyToKey(XLookupKeysym(ev.xkey.addr, i.cint))
              inc i
          if key != Key.unknown:
            keyboard.pressed[key] = false
            template mk(a): bool = (ev.xkey.state and a).bool
            pushEvent onKeyup, (keyboard, key, false, mk Mod1Mask, mk ControlMask, mk ShiftMask, mk Mod4Mask)

        else: discard
      
        if not m_isOpen: break
      if not m_isOpen: break

      if not catched: sleep(2) # не так быстро!

      let nows = getTime()
      pushEvent onTick, (mouse, keyboard, nows - lastTickTime)
      lastTickTime = nows

      when a is PictureWindow|OpenglWindow:
        if waitForReDraw:
          waitForReDraw = false
          when a is PictureWindow:
            pushEvent on_render, (m_data, m_size)
            gc.put ximg
          when a is OpenglWindow:
            pushEvent on_render, ()
            xwin.toDrawable.glxSwapBuffers()
      
      clipboardProcessEvents()

    pushEvent onClose, ()
  
  proc systemHandle*(a: Window): x.Window = a.xwin
    ## get system handle of window
    ##* result depends on OS or platmofm



elif defined(windows):
  proc poolEvent(a: var Window, message: Uint, wParam: WParam, lParam: LParam): LResult

  proc wndProc(handle: HWnd, message: Uint, wParam: WParam, lParam: LParam): LResult {.stdcall.} =
    let win = if handle != 0: cast[ptr Window](GetWindowLongPtr(handle, GwlpUserData)) else: nil
    if win != nil: return win[].poolEvent(message, wParam, lParam)

    if message == WmClose: return 0
    if (message == WmSysCommand) and (wParam == ScKeyMenu): return 0
    return DefWindowProc(handle, message, wParam, lParam)

  const wClassName = "win64app"
  block winapiInit:
    var wcex: WndClasseX
    wcex.cbSize        = WndClasseX.sizeof.int32
    wcex.style         = CsHRedraw or CsVRedraw or CsDblClks
    wcex.lpfnWndProc   = wndProc
    wcex.cbClsExtra    = 0
    wcex.cbWndExtra    = 0
    wcex.hInstance     = hInstance
    wcex.hCursor       = LoadCursor(0, IdcArrow)
    wcex.hbrBackground = 0
    wcex.lpszMenuName  = nil
    wcex.lpszClassName = wClassName
    wcex.hIconSm       = 0
    winassert RegisterClassEx(wcex) != 0

  const defaultVisualMode = VisualMode()
  
  proc `=destroy`*(a: var Window) = with a:
    DeleteDC hdc
    DeleteObject wimage

  template pushEvent(a: Window, event, args) =
    when args is tuple: 
      if a.event != nil: a.event(args)
    else:
      if a.event != nil: a.event((args,))

  proc updateSize(a: var Window) = with a:
    let rect = handle.clientRect
    let osize = m_size
    m_size = (rect.right.int, rect.bottom.int)
    if osize == m_size: return

    if m_usingPictureForRender:
      DeleteDC hdc
      DeleteObject wimage

      if m_size.x * m_size.y > 0:
        var bmi = BitmapInfo(bmiHeader: BitmapInfoHeader(biSize: BitmapInfoHeader.sizeof.int32, biWidth: m_size.x.Long, biHeight: -m_size.y.Long,
                             biPlanes: 1, biBitCount: 32, biCompression: BiRgb, biSizeImage: 0, biXPelsPerMeter: 0, biYPelsPerMeter: 0, biClrUsed: 0, biClrImportant: 0));
        wimage  = CreateDibSection(0, &bmi, DibRgbColors, cast[ptr pointer](&m_data), 0, 0)
        hdc     = CreateCompatibleDC(0)
        winassert wimage != 0
        winassert hdc != 0
      else:
        m_data = nil
      let old = hdc.SelectObject(wimage)
      if old != 0: discard DeleteObject old
    
    a.pushEvent onResize, (osize, m_size)
    
  proc fullscreen*(a: Window): bool = a.m_isFullscreen
  proc `fullscreen=`*(a: var Window, v: bool) = with a:
    if m_isFullscreen == v: return
    m_isFullscreen = v
    if v:
      discard handle.SetWindowLongPtr(GwlStyle, WsVisible)
      discard handle.ShowWindow(SwMaximize)
    else:
      discard handle.ShowWindow(SwShowNormal)
      discard handle.SetWindowLongPtr(GwlStyle, WsVisible or WsOverlappedWindow)
    a.updateSize()
    a.pushEvent onFullscreenChanged, (v)

  proc size*(a: Window): tuple[x, y: int] = a.m_size
  proc `size=`*(a: var Window, size: tuple[x, y: int]) = with a:
    a.fullscreen = false
    let rcClient = handle.clientRect
    var rcWind = handle.windowRect
    let borderx = (rcWind.right - rcWind.left) - rcClient.right
    let bordery = (rcWind.bottom - rcWind.top) - rcClient.bottom
    MoveWindow(handle, rcWind.left, rcWind.top, (size.x + borderx).int32, (size.y + bordery).int32, True)
    a.updateSize()
  
  proc newWindowImpl(w, h: int, screen: Screen, fullscreen: bool, visualMode: VisualMode): Window = with result:
    handle = CreateWindow(wClassName, "", WsOverlappedWindow, CwUseDefault, CwUseDefault, 
                          w.int32, h.int32, 0, 0, hInstance, nil)
    winassert handle != 0
    m_hasFocus = true
    m_isOpen = true
    curCursor = arrow
    wcursor = LoadCursor(0, IdcArrow)
    discard handle.SetWindowLongPtrW(GwlpUserData, cast[LongPtr](result.addr))
    handle.trackMouseEvent(TmeHover)
    result.size = (w, h)

    result.fullscreen = fullscreen

  proc initRender*(w: var Window) = with w:
    if m_usingPictureForRender: return
    m_usingPictureForRender = true

    if m_size.x * m_size.y > 0:
      var bmi = BitmapInfo(bmiHeader: BitmapInfoHeader(biSize: BitmapInfoHeader.sizeof.int32, biWidth: m_size.x.Long, biHeight: -m_size.y.Long,
                           biPlanes: 1, biBitCount: 32, biCompression: BI_RGB, biSizeImage: 0, biXPelsPerMeter: 0, biYPelsPerMeter: 0, biClrUsed: 0, biClrImportant: 0));
      wimage  = CreateDibSection(0, &bmi, DibRgbColors, cast[ptr pointer](&m_data), 0, 0)
      hdc     = CreateCompatibleDC(0)
      winassert wimage != 0
      winassert hdc != 0
    else:
      m_data = nil
    discard hdc.SelectObject(wimage)

  proc `title=`*(a: Window, title: string) = with a:
    handle.SetWindowText(title)

  proc opened*(a: Window): bool = a.m_isOpen
  proc close*(a: var Window) {.lazy.} = with a:
    if m_isOpen: handle.SendMessage(WmClose, 0, 0)
    
  proc redraw*(a: var Window) {.lazy.} = with a:
    var cr = handle.clientRect
    handle.InvalidateRect(&cr, false)
    
  proc position*(a: Window): tuple[x, y: int] = with a:
    let r = handle.clientRect
    return (r.left.int, r.top.int)
  proc `position=`*(a: var Window, v: tuple[x, y: int]) = with a:
    if m_isFullscreen: return
    handle.SetWindowPos(0, v.x.int32, v.y.int32, 0, 0, SwpNoSize)
    
  proc `cursor=`*(a: var Window, kind: Cursor) = with a:
    if kind == curCursor: return
    var cu: HCursor = 0
    case kind
    of Cursor.arrow:          cu = LoadCursor(0, IdcArrow)
    of Cursor.arrowUp:        cu = LoadCursor(0, IdcUpArrow)
    of Cursor.hand:           cu = LoadCursor(0, IdcHand)
    of Cursor.sizeAll:        cu = LoadCursor(0, IdcSizeAll)
    of Cursor.sizeVertical:   cu = LoadCursor(0, IdcSizens)
    of Cursor.sizeHorisontal: cu = LoadCursor(0, IdcSizewe)
    if cu != 0:
      SetCursor cu
      wcursor = cu
    curCursor = kind
  
  proc `icon=`*(a: var Window, img: Picture) = with a:
    if wicon != 0: DestroyIcon wicon
    wicon = CreateIcon(hInstance, img.size.x.int32, img.size.y.int32, 1, 32, nil, cast[ptr Byte](img.data))
    if wicon != 0:
      handle.SendMessageW(WmSetIcon, IconBig, wicon)
      handle.SendMessageW(WmSetIcon, IconSmall, wicon)
  proc `icon=`*(a: var Window, _: nil.typeof) = with a:
    if wicon != 0: DestroyIcon wicon
    handle.SendMessageW(WmSetIcon, IconBig, 0)
    handle.SendMessageW(WmSetIcon, IconSmall, 0)
  proc displayImpl(a: var Window) = with a:
    var ps: PaintStruct
    handle.BeginPaint(&ps)
    if m_usingPictureForRender and m_size.x * m_size.y > 0:
      let hhdc = handle.GetDC()
      let rect = handle.clientRect

      BitBlt(hhdc, 0, 0, rect.right, rect.bottom, hdc, 0, 0, SrcCopy)
      handle.ReleaseDC(hhdc)
    handle.EndPaint(&ps)

  proc run*(a: var Window) = with a:
    ## run main loop of window
    var lastTickTime = getTime()
    handle.ShowWindow(SwShow)
    handle.UpdateWindow()
    var msg: Msg
    while m_isOpen:
      var catched = false
      while PeekMessage(&msg, 0, 0, 0, PmRemove):
        catched = true
        TranslateMessage(&msg)
        DispatchMessage(&msg)

        if not m_isOpen: break
      if not m_isOpen: break

      if not catched: sleep(2) # не так быстро!
      
      let nows = getTime()
      if a.onTick != nil: onTick (mouse, keyboard, nows - lastTickTime)
      lastTickTime = nows

  proc poolEvent(a: var Window, message: Uint, wParam: WParam, lParam: LParam): LResult = with a:
    template pushEvent(event, args) =
      a.pushEvent(event, args)

    template button: MouseButton =
      case message
      of WM_lbuttonDown, WM_lbuttonUp, WM_lbuttonDblclk: MouseButton.left
      of WM_rbuttonDown, WM_rbuttonUp, WM_rbuttonDblclk: MouseButton.right
      of WM_mbuttonDown, WM_mbuttonUp, WM_mbuttonDblclk: MouseButton.middle
      of WM_xbuttonDown, WM_xbuttonUp, WM_xbuttonDblclk:
        let button = wParam.GetXButtonWParam()
        if button == MkXButton1: MouseButton.backward elif button == MkXButton2: MouseButton.forward else: MouseButton.left
      else: MouseButton.left

    result = 0

    case message
    of WmPaint:
      let rect = handle.clientRect
      if rect.right != m_size.x or rect.bottom != m_size.y:
        a.updateSize()
      if m_size.x * m_size.y > 0:
        pushEvent onRender, (m_data, m_size)
      a.displayImpl()
    
    of WmDestroy:
      pushEvent onClose, ()
      m_isOpen = false
      PostQuitMessage(0)
    
    of WmMouseMove:
      let opos = mouse.position
      mouse.position = (lParam.GetX_LParam, lParam.GetY_LParam)
      for v in clicking.mitems: v = false
      pushEvent onMouseMove, (mouse, opos, mouse.position)
    
    of WmMouseLeave:
      let npos = (lParam.GetX_LParam, lParam.GetY_LParam)
      pushEvent onMouseLeave, (mouse, mouse.position, npos)
      handle.trackMouseEvent(TmeHover)
    
    of WmMouseHover:
      let npos = (lParam.GetX_LParam, lParam.GetY_LParam)
      pushEvent onMouseEnter, (mouse, mouse.position, npos)
      handle.trackMouseEvent(TmeLeave)
    
    of WmMouseWheel:
      let delta = if wParam.GetWheelDeltaWParam > 0: -1.0 else: 1.0
      pushEvent onScroll, (mouse, delta)
    
    of WmSetFocus:
      m_hasFocus = true
      pushEvent onFocusChanged, (m_hasFocus)
    
    of WmKillFocus:
      m_hasFocus = false
      pushEvent onFocusChanged, (m_hasFocus)
      for key, k in keyboard.pressed.mpairs: # отпустить все клавиши
        if k:
          template mk(vk): bool = HIWord(GetKeyState(vk)) != 0
          pushEvent onKeyup, (keyboard, key, false, mk VkMenu, mk VkControl, mk VkShift, mk(VkLWin) or mk(VkRWin))
          k = false
    
    of WmLButtonDown, WmRButtonDown, WmMButtonDown, WmXButtonDown:
      handle.SetCapture()
      mouse.pressed[button] = true
      clicking[button] = true
      pushEvent onMouseDown, (mouse, button, true)
    
    of WmLButtonUp, WmRButtonUp, WmMButtonUp, WmXButtonUp:
      ReleaseCapture()
      mouse.pressed[button] = false
      if clicking[button]: pushEvent onClick, (mouse, button, mouse.position, false)
      clicking[button] = false
      pushEvent onMouseDown, (mouse, button, false)
    
    of WmLButtonDblclk, WmRButtonDblclk, WmMButtonDblclk, WmXButtonDblclk:
      pushEvent onDoubleClick, (mouse, button, mouse.position, true)

    of WmKeyDown, WmSysKeyDown:
      let key = wkeyToKey(wParam, lParam)
      keyboard.pressed[key] = true
      template mk(vk): bool = HIWord(GetKeyState(vk)) != 0
      pushEvent onKeydown, (keyboard, key, true, mk VkMenu, mk VkControl, mk VkShift, mk(VkLWin) or mk(VkRWin))
    
    of WmKeyUp, WmSysKeyUp:
      let key = wkeyToKey(wParam, lParam)
      keyboard.pressed[key] = false
      template mk(vk): bool = HIWord(GetKeyState(vk)) != 0
      pushEvent onKeyup, (keyboard, key, false, mk VkMenu, mk VkControl, mk VkShift, mk(VkLWin) or mk(VkRWin))

    of WmChar:
      pushEvent onTextEnter, (keyboard, %$[wParam.WChar])
    
    of WmSetCursor:
      if lParam.LoWord == HtClient:
        SetCursor wcursor
        return 1
      return handle.DefWindowProc(message, wParam, lParam)

    else: return handle.DefWindowProc(message, wParam, lParam)

  proc systemHandle*(a: Window): HWnd = a.handle
    ## get system handle of window
    ##* result depends on OS or platmofm
else:
  {.error: "current OS is not supported".}



proc newNoRenderWindow*(w: int = 1280, h: int = 720, title: string = "", screen = screen(), fullscreen: bool = false): Window =
  result.initNoRenderWindow(w, h, screen, fullscreen)
  result.title = title
proc newNoRenderWindow*(size: tuple[x, y: int], title: string = "", screen = screen(), fullscreen: bool = false): Window =
  newNoRenderWindow(size.x, size.y, title, screen, fullscreen)

proc newPictureWindow*(w: int = 1280, h: int = 720, title: string = "", screen = screen(), fullscreen: bool = false): PictureWindow =
  result.initPictureWindow(w, h, screen, fullscreen)
  result.title = title
proc newPictureWindow*(size: tuple[x, y: int], title: string = "", screen = screen(), fullscreen: bool = false): PictureWindow =
  newPictureWindow(size.x, size.y, title, screen, fullscreen)

proc newOpenglWindow*(w: int = 1280, h: int = 720, title: string = "", screen = screen(), fullscreen: bool = false): OpenglWindow =
  result.initOpenglWindow(w, h, screen, fullscreen)
  result.title = title
proc newOpenglWindow*(size: tuple[x, y: int], title: string = "", screen = screen(), fullscreen: bool = false): OpenglWindow =
  newOpenglWindow(size.x, size.y, title, screen, fullscreen)

template newWindow*(w: int = 1280, h: int = 720, title: string = "", screen = screen(), fullscreen: bool = false, renderEngine: RenderEngine = RenderEngine.opengl): SomeWindow =
  when renderEngine == RenderEngine.none:    newNoRenderWindow(w, h, title, screen, fullscreen)
  elif renderEngine == RenderEngine.picture: newPictureWindow(w, h, title, screen, fullscreen)
  elif renderEngine == RenderEngine.opengl:  newOpenglWindow(w, h, title, screen, fullscreen)
template newWindow*(size: tuple[x, y: int], title: string = "", screen = screen(), fullscreen: bool = false, renderEngine: RenderEngine = RenderEngine.opengl): SomeWindow =
  newWindow(size.x, size.y, title, screen, fullscreen, renderEngine)

template w*(a: Screen): int = a.size.x
  ## width of screen
template h*(a: Screen): int = a.size.y
  ## height of screen

converter getPicture*(a: PictureWindow): Picture =
  Picture(size: a.m_size, data: a.m_data)
