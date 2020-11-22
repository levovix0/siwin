import times, os
import with
import image
when defined(linux):
  import libx11 as x
when defined(windows):
  import libwinapi
  type Color = image.Color

type
  MouseButton* {.pure.} = enum
    left right middle forward backward
  Mouse* = tuple
    position: tuple[x, y: int]
    pressed: array[MouseButton.left..MouseButton.backward, bool]
  Key* {.pure.} = enum
    unknown = -1
    a = 0, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z,
    n0, n1, n2, n3, n4, n5, n6, n7, n8, n9,
    escape, lcontrol, lshift, lalt, lsystem, rcontrol, rshift, ralt, rsystem, menu, lbracket, rbracket,
    semicolon, comma, dot, quote, slash, backslash, tilde, equal, minus, space, enter, backspace, tab,
    pageUp, pageDown, End, home, insert, del, add, subtract, multiply, divide, left, right, up, down,
    numpad0, numpad1, numpad2, numpad3, numpad4, numpad5, numpad6, numpad7, numpad8, numpad9,
    f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15, pause
  Keyboard* = tuple
    pressed: array[Key.a..Key.pause, bool]
    
  Cursor* {.pure.} = enum
    arrow sizeAll hand sizeHorisontal sizeVertical arrowUp

  Window* = object
    m_data: ArrayPtr[Color]
    m_size: tuple[x, y: int]

    onClose*:       proc(e: CloseEvent)
    
    onRender*:      proc(e: RenderEvent)
    onFocus*:       proc(e: FocusEvent)
    onTick*:        proc(e: TickEvent)
    onResize*:      proc(e: ResizeEvent)
    onWindowMove*:  proc(e: WindowMoveEvent)

    mouse*: Mouse # состояние мыши
    onMouseMove*:   proc(e: MouseMoveEvent)
    onMouseLeave*:  proc(e: MouseMoveEvent)
    onMouseEnter*:  proc(e: MouseMoveEvent)
    onMouseDown*:   proc(e: MouseButtonEvent)
    onMouseUp*:     proc(e: MouseButtonEvent)
    onClick*:       proc(e: ClickEvent)
    onDoubleClick*: proc(e: ClickEvent)
    onScroll*:      proc(e: ScrollEvent)

    keyboard*: Keyboard # состояние клавиатуры
    onKeydown*:     proc(e: KeyEvent)
    onKeyup*:       proc(e: KeyEvent)
    onTextEnter*:   proc(e: TextEnterEvent)

    when defined(linux):
      screen: cint
      xwin: x.Window
      gc: x.GC
      gcv: x.XGCValues
      ximg: x.PXImage
      xicon: x.Pixmap
      xiconMask: x.Pixmap
      xinContext: x.XIC
      xinMethod: x.XIM

      xcursor: x.Cursor
      clicking: array[MouseButton.left..MouseButton.backward, bool]

      m_isOpen: bool
      m_hasFocus: bool
      m_isFullscreen: bool

      waitForDisplay: bool

      m_pos: tuple[x, y: int]

    elif defined(windows):
      handle: HWND
      wimage: HBITMAP
      hdc: HDC

      m_hasFocus: bool

  CloseEvent* = tuple

  RenderEvent* = tuple
    data: ArrayPtr[Color]
    size: tuple[x, y: int]
  ResizeEvent* = tuple
    oldSize, size: tuple[x, y: int]
  WindowMoveEvent* = tuple
    olsPositin, position: tuple[x, y: int]

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
    doubleClick: bool
  ScrollEvent* = tuple
    mouse: Mouse
    delta: float

  FocusEvent* = tuple
    focused: bool

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

  Screen* = object

var screen*: Screen

when defined(linux):
  template d: x.PDisplay = x.display

  proc malloc(a: culong): pointer {.importc.}
  
  proc `=destroy`*(a: var Window) = with a:
    if ximg != nil: xcheck XDestroyImage(ximg)
    if gc != nil: xcheck d.XFreeGC(gc)
    if xinContext != nil: XDestroyIC(xinContext)
    if xinMethod != nil: xcheck XCloseIM(xinMethod)
    if xcursor != 0: xcheck d.XFreeCursor(xcursor)
    if xicon != 0: xcheck d.XFreePixmap(xicon)
    if xiconMask != 0: xcheck d.XFreePixmap(xiconMask)
    if xwin != 0: xcheck d.XDestroyWindow(xwin)
    x.disconnect()

  proc newWindowImpl(w, h: int): Window = with result:
    x.connect()
    screen = d.DefaultScreen
    m_size = (w, h)
    xwin = d.XCreateSimpleWindow(d.DefaultRootWindow, 0, 0, w.cuint, h.cuint, 0, 0, d.BlackPixel(screen))
    doassert xwin != 0
    xcheck d.XSelectInput(xwin, 
      x.ExposureMask or x.KeyPressMask or x.KeyReleaseMask or x.PointerMotionMask or x.ButtonPressMask or
      x.ButtonReleaseMask or x.StructureNotifyMask or x.EnterWindowMask or x.LeaveWindowMask
    )
    xcheck d.XMapWindow xwin
    gc = d.XCreateGC(xwin, x.GCForeground or x.GCBackground, gcv.addr)

    xcheck d.XSetWMProtocols(xwin, x.patom(x.WM_DELETE_WINDOW), 1)

    xinMethod = d.XOpenIM(nil, nil, nil)
    if xinMethod != nil:
      xinContext = xinMethod.XCreateIC(
        x.XNClientWindow, xwin, x.XNFocusWindow, xwin, x.XNInputStyle, x.XIMPreeditNothing or x.XIMStatusNothing, nil
      )
    
    m_data = ArrayPtr[Color](cast[ptr Color](malloc(culong Color.sizeof * w * h)))
    ximg = d.XCreateImage(d.DefaultVisual(screen), d.DefaultDepth(screen).cuint, ZPixmap, 0, cast[cstring](cast[ptr Color](m_data)),
      w.cuint, h.cuint, 32, 0
    )
    doassert ximg != nil

    m_isOpen = true
    m_hasFocus = true
    m_isFullscreen = false

    waitForDisplay = true
  
  proc `title=`*(a: Window, title: string) = with a:
    let useUtf8 = x.atom(UTF8_STRING)
    xcheck d.XChangeProperty(xwin, x.atom(NET_WM_NAME), useUtf8, 8, PropModeReplace, title, title.len.cint)
    xcheck d.XChangeProperty(xwin, x.atom(NET_WM_ICON_NAME), useUtf8, 8, PropModeReplace, title, title.len.cint)

    d.Xutf8SetWMProperties(a.xwin, title, title, nil, 0, nil, nil, nil)
  
  proc opened*(a: Window): bool = a.m_isOpen

  proc updateGeometry(a: var Window) = with a:
    let (_, x, y, w, h, _, _) = xwin.getGeometry()
    m_pos = (x.int, y.int)
    m_size = (w.int, h.int)

    xcheck XDestroyImage ximg
    m_data = ArrayPtr[Color](cast[ptr Color](malloc(culong Color.sizeof * w.int * h.int)))
    ximg = d.XCreateImage(
      d.DefaultVisual(screen), d.DefaultDepth(screen).cuint, ZPixmap, 0, cast[cstring](cast[ptr Color](m_data)),
      w, h, 32, 0
    )
    doassert ximg != nil
    waitForDisplay = true
  
  proc fullscreen*(a: Window): bool = a.m_isFullscreen
  proc `fullscreen =`*(a: var Window, v: bool) = with a:
    if a.fullscreen == v: return

    var xwa: x.XWindowAttributes
    xcheck d.XGetWindowAttributes(xwin, xwa.addr)
    
    var e: XEvent
    e.xclient.theType      = ClientMessage
    e.xclient.message_type = x.atom(NET_WM_STATE, true)
    e.xclient.display      = d
    e.xclient.window       = xwin
    e.xclient.format       = 32
    e.xclient.data.l[0]    = 2 #* 2 - переключить, 1 - добавить, 0 - убрать
    e.xclient.data.l[1]    = x.atom(NET_WM_STATE_FULLSCREEN).clong
    e.xclient.data.l[2]    = 0
    e.xclient.data.l[3]    = 0
    e.xclient.data.l[4]    = 0
    xcheck d.XSendEvent(xwa.root, 0, SubstructureNotifyMask or SubstructureRedirectMask, e.addr)
  
    m_isFullscreen = v

  proc close*(a: Window) = with a:
    var e: XEvent
    e.xclient.theType      = ClientMessage
    e.xclient.window       = xwin
    e.xclient.message_type = x.atom(WM_PROTOCOLS)
    e.xclient.format       = 32
    e.xclient.data.l[0]    = x.atom(WM_DELETE_WINDOW).clong
    e.xclient.data.l[1]    = CurrentTime
    xcheck d.XSendEvent(xwin, 0, NoEventMask, e.addr)
  
  proc xkeyToKey(sym: KeySym): Key =
    case sym
    of XK_Shift_L:      Key.lshift
    of XK_Shift_R:      Key.rshift
    of XK_Control_L:    Key.lcontrol
    of XK_Control_R:    Key.rcontrol
    of XK_Alt_L:        Key.lalt
    of XK_Alt_R:        Key.ralt
    of XK_Super_L:      Key.lsystem
    of XK_Super_R:      Key.rsystem
    of XK_Menu:         Key.menu
    of XK_Escape:       Key.escape
    of XK_semicolon:    Key.semicolon
    of XK_slash:        Key.slash
    of XK_equal:        Key.equal
    of XK_minus:        Key.minus
    of XK_bracketleft:  Key.lbracket
    of XK_bracketright: Key.rbracket
    of XK_comma:        Key.comma
    of XK_period:       Key.dot
    of XK_apostrophe:   Key.quote
    of XK_backslash:    Key.backslash
    of XK_grave:        Key.tilde
    of XK_space:        Key.space
    of XK_Return:       Key.enter
    of XK_KP_Enter:     Key.enter
    of XK_BackSpace:    Key.backspace
    of XK_Tab:          Key.tab
    of XK_Prior:        Key.page_up
    of XK_Next:         Key.page_down
    of XK_End:          Key.End
    of XK_Home:         Key.home
    of XK_Insert:       Key.insert
    of XK_Delete:       Key.del
    of XK_KP_Add:       Key.add
    of XK_KP_Subtract:  Key.subtract
    of XK_KP_Multiply:  Key.multiply
    of XK_KP_Divide:    Key.divide
    of XK_Pause:        Key.pause
    of XK_F1:           Key.f1
    of XK_F2:           Key.f2
    of XK_F3:           Key.f3
    of XK_F4:           Key.f4
    of XK_F5:           Key.f5
    of XK_F6:           Key.f6
    of XK_F7:           Key.f7
    of XK_F8:           Key.f8
    of XK_F9:           Key.f9
    of XK_F10:          Key.f10
    of XK_F11:          Key.f11
    of XK_F12:          Key.f12
    of XK_F13:          Key.f13
    of XK_F14:          Key.f14
    of XK_F15:          Key.f15
    of XK_Left:         Key.left
    of XK_Right:        Key.right
    of XK_Up:           Key.up
    of XK_Down:         Key.down
    of XK_KP_Insert:    Key.numpad0
    of XK_KP_End:       Key.numpad1
    of XK_KP_Down:      Key.numpad2
    of XK_KP_Page_Down: Key.numpad3
    of XK_KP_Left:      Key.numpad4
    of XK_KP_Begin:     Key.numpad5
    of XK_KP_Right:     Key.numpad6
    of XK_KP_Home:      Key.numpad7
    of XK_KP_Up:        Key.numpad8
    of XK_KP_Page_Up:   Key.numpad9
    of XK_a:            Key.a
    of XK_b:            Key.b
    of XK_c:            Key.c
    of XK_d:            Key.d
    of XK_e:            Key.r
    of XK_f:            Key.f
    of XK_g:            Key.g
    of XK_h:            Key.h
    of XK_i:            Key.i
    of XK_j:            Key.j
    of XK_k:            Key.k
    of XK_l:            Key.l
    of XK_m:            Key.m
    of XK_n:            Key.n
    of XK_o:            Key.o
    of XK_p:            Key.p
    of XK_q:            Key.q
    of XK_r:            Key.r
    of XK_s:            Key.s
    of XK_t:            Key.t
    of XK_u:            Key.u
    of XK_v:            Key.v
    of XK_w:            Key.w
    of XK_x:            Key.x
    of XK_y:            Key.y
    of XK_z:            Key.z
    of XK_0:            Key.n0
    of XK_1:            Key.n1
    of XK_2:            Key.n2
    of XK_3:            Key.n3
    of XK_4:            Key.n4
    of XK_5:            Key.n5
    of XK_6:            Key.n6
    of XK_7:            Key.n7
    of XK_8:            Key.n8
    of XK_9:            Key.n9
    else:               Key.unknown

  proc position*(a: var Window): tuple[x, y: int] = with a:
    let (_, x, y, _, _, _, _) = xwin.getGeometry()
    m_pos = (x.int, y.int)
    return m_pos
  proc `position=`*(a: var Window, p: tuple[x, y: int]) = with a:
    xcheck d.XMoveWindow(xwin, p.x.cint, p.y.cint)
    m_pos = p
  proc size*(a: Window): tuple[x, y: int] = a.m_size
  proc `size=`*(a: var Window, size: tuple[x, y: int]) = with a:
    xcheck d.XResizeWindow(xwin, size.x.cuint, size.y.cuint)
    a.updateGeometry()

  proc `cursor=`*(a: var Window, kind: Cursor) = with a:
    if xcursor != 0: xcheck d.XFreeCursor(xcursor)
    case kind
    of Cursor.arrow:          xcursor = d.XCreateFontCursor(XC_left_ptr)
    of Cursor.arrowUp:        xcursor = d.XCreateFontCursor(XC_center_ptr)
    of Cursor.hand:           xcursor = d.XCreateFontCursor(XC_hand1)
    of Cursor.sizeAll:        xcursor = d.XCreateFontCursor(XC_fleur)
    of Cursor.sizeVertical:   xcursor = d.XCreateFontCursor(XC_sb_v_double_arrow)
    of Cursor.sizeHorisontal: xcursor = d.XCreateFontCursor(XC_sb_h_double_arrow)
    xcheck d.XDefineCursor(xwin, xcursor)
    xcheck d.XSync(0)

  proc newPixmap(img: Picture, a: Window): x.Pixmap = with a:
    var ddata = cast[ptr Color](malloc(culong Color.sizeof * img.size.x * img.size.y))
    copyMem(ddata, cast[ptr Color](img.data), Color.sizeof * img.size.x * img.size.y)
    result = d.XCreatePixmap(xwin, img.size.x.cuint, img.size.y.cuint, d.DefaultDepth(screen).cuint)
    
    var gcv2: XGCValues
    let gc2 = d.XCreateGC(xwin, x.GCForeground or x.GCBackground, gcv2.addr)

    let image = d.XCreateImage(
      d.DefaultVisual(screen), d.DefaultDepth(screen).cuint, ZPixmap, 0, cast[cstring](cast[ptr Color](ddata)),
      img.size.x.cuint, img.size.y.cuint, 32, 0
    )
    xcheckStatus d.XPutImage(result, gc2, image, 0, 0, 0, 0, img.size.x.cuint, img.size.y.cuint)
    xcheck XDestroyImage(image)
    xcheck d.XFreeGC(gc2)

  proc `icon=`*(a: var Window, img: Picture) = with a:
    if xicon != 0: xcheck d.XFreePixmap(xicon)
    if xiconMask != 0: xcheck d.XFreePixmap(xiconMask)

    xicon = newPixmap(img, a)

    var mask = newImage(img.size.x, img.size.y)
    for i in 0..<(img.size.x * img.size.y):
      mask.data[i] = if img.data[i].a > 127: color(0, 0, 0) else: color(255, 255, 255)
    xiconMask = newPixmap(mask, a)

    var wmh = XAllocWMHints()
    wmh.flags = IconPixmapHint or IconMaskHint
    wmh.icon_pixmap = xicon
    wmh.icon_mask   = xiconMask
    xcheck d.XSetWMHints(xwin, wmh)
    xcheck XFree(wmh)
  
  proc `icon=`*(a: var Window, _: nil.typeof) = with a:
    if xicon != 0: xcheck d.XFreePixmap(xicon)
    if xiconMask != 0: xcheck d.XFreePixmap(xiconMask)
    xicon = 0
    xiconMask = 0
    var wmh = XAllocWMHints()
    wmh.flags = IconPixmapHint or IconMaskHint
    wmh.icon_pixmap = xicon
    wmh.icon_mask   = xiconMask
    xcheck d.XSetWMHints(xwin, wmh)
    xcheck XFree(wmh)

  proc display*(a: var Window) = a.waitForDisplay = true
  proc displayImpl(a: var Window) = with a:
    xcheckStatus d.XPutImage(xwin, gc, ximg, 0, 0, 0, 0, m_size.x.cuint, m_size.y.cuint)
  
  proc run*(a: var Window) = with a:
    template push_event(event, args) =
      when args is tuple: 
        if a.event != nil: a.event(args)
      else:
        if a.event != nil: a.event((args,))
    
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
        return if event.xany.window == (x.Window)(cast[int](userData)): 1 else: 0
      while d.XCheckIfEvent(ev.addr, checkEvent, cast[XPointer](xwin)) == 1:
        catched = true

        case ev.theType
        of Expose:
          if ev.xexpose.width != m_size.x or ev.xexpose.height != m_size.y:
            let osize = m_size
            a.updateGeometry()
            push_event onResize, (osize, m_size)
          display a
        of ClientMessage:
          if ev.xclient.data.l[0] == (clong)x.atom(WM_DELETE_WINDOW, false):
            m_isOpen         = false;
            m_isFullscreen   = false;
            m_hasFocus       = false;
            waitForDisplay   = false;
            push_event onClose, ()
          
        of ConfigureNotify:
          if ev.xconfigure.width != m_size.x or ev.xconfigure.height != m_size.y:
            let osize = m_size
            a.updateGeometry()
            push_event on_resize, (osize, m_size)
          if ev.xconfigure.x.int != m_pos.x or ev.xconfigure.y.int != m_pos.y:
            let oldPos = m_pos
            m_pos = (ev.xconfigure.x.int, ev.xconfigure.y.int)
            push_event onWindowMove, (oldPos, m_pos)

        of MotionNotify:
          let oldPos = mouse.position
          mouse.position = (ev.xmotion.x.int, ev.xmotion.y.int)
          for v in clicking.mitems: v = false
          push_event onMouseMove, (mouse, oldPos, mouse.position)

        of ButtonPress:
          if not isScroll:
            mouse.pressed[button] = true
            clicking[button] = true
            push_event onMouseDown, (mouse, button, true)
          elif scrollDelta != 0: push_event onScroll, (mouse, scrollDelta)
        of ButtonRelease:
          if not isScroll:
            let nows = getTime()
            mouse.pressed[button] = false
            
            if clicking[button]:
              if (nows - lastClickTime).inMilliseconds < 200: push_event onDoubleClick, (mouse, button, true)
              else: push_event onClick, (mouse, button, false)

            mouse.pressed[button] = false
            lastClickTime = nows
            push_event onMouseUp, (mouse, button, false)

        of LeaveNotify:
          push_event onMouseLeave, (mouse, mouse.position, (ev.xcrossing.x.int, ev.xcrossing.y.int))
        of EnterNotify:
          push_event onMouseEnter, (mouse, mouse.position, (ev.xcrossing.x.int, ev.xcrossing.y.int))

        of FocusIn:
          m_hasFocus = true
          if xinContext != nil: XSetICFocus xinContext
          push_event onFocus, (true)
        of FocusOut:
          m_hasFocus = false
          if xinContext != nil: XSetICFocus xinContext
          push_event onFocus, (false)
        
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
            push_event onKeydown, (keyboard, key, true, mk Mod1Mask, mk ControlMask, mk ShiftMask, mk Mod4Mask)
          
          if xinContext != nil:
            var status: Status
            var buffer: array[16, char]
            let length = Xutf8LookupString(xinContext, ev.xkey.addr, cast[cstring](buffer.addr), buffer.sizeof.cint, nil, status.addr)

            proc toString(str: openArray[char]): string =
              result = newStringOfCap(len(str))
              for ch in str:
                result.add ch

            if length > 0:
              push_event onTextEnter, (keyboard, buffer.toString())
        
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
            push_event onKeyup, (keyboard, key, false, mk Mod1Mask, mk ControlMask, mk ShiftMask, mk Mod4Mask)

        else: discard

      let nows = getTime()
      push_event onTick, (mouse, keyboard, nows - lastTickTime)
      lastTickTime = nows

      if waitForDisplay:
        waitForDisplay = false
        push_event on_render, (m_data, m_size)
        a.displayImpl()

      if not catched: sleep(2) # не так быстро!

  #* Screen
  proc size*(a: Screen): tuple[x, y: int] =
    connect()
    let screen = d.XScreenOfDisplay(d.XDefaultScreen)
    result = (screen.width.int, screen.height.int)
    disconnect()

elif defined(windows):
  proc poolEvent(a: var Window, message: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT

  proc wndProc(handle: HWND, message: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
    let win = if handle != 0: cast[ptr Window](GetWindowLongPtr(handle, GWLP_USERDATA)) else: nil
    if win != nil: return win[].poolEvent(message, wParam, lParam)

    if message == WM_CLOSE: return 0
    if (message == WM_SYSCOMMAND) and (wParam == SC_KEYMENU): return 0
    return DefWindowProc(handle, message, wParam, lParam)

  const wClassName = "win64app"
  block winapiInit:
    var wcex: WNDCLASSEX
    wcex.cbSize        = WNDCLASSEX.sizeof.int32
    wcex.style         = CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
    wcex.lpfnWndProc   = wndProc
    wcex.cbClsExtra    = 0
    wcex.cbWndExtra    = 0
    wcex.hInstance     = hInstance
    wcex.hCursor       = LoadCursor(0, IDC_ARROW)
    wcex.hbrBackground = 0
    wcex.lpszMenuName  = nil
    wcex.lpszClassName = wClassName
    wcex.hIconSm       = 0
    winassert RegisterClassEx(wcex) != 0
  
  proc trackMouseEvent(a: HWND, e: DWORD) =
    var ev = TTRACKMOUSEEVENT(cbSize: TTRACKMOUSEEVENT.sizeof.DWORD, dwFlags: e, hwndTrack: a, dwHoverTime: 0)
    TrackMouseEvent(ev.addr)
  
  proc size*(a: Window): tuple[x, y: int] = a.m_size
  proc `size=`*(a: var Window, size: tuple[x, y: int]) = with a:
    var rcClient, rcWind: RECT
    GetClientRect(handle, &rcClient)
    GetWindowRect(handle, &rcWind)
    let borderx = (rcWind.right - rcWind.left) - rcClient.right
    let bordery = (rcWind.bottom - rcWind.top) - rcClient.bottom
    MoveWindow(handle, rcWind.left, rcWind.top, (size.x + borderx).int32, (size.y + bordery).int32, TRUE)

    m_size = size
  
  proc `=destroy`*(a: var Window) = with a:
    DeleteDC(hdc)
    DeleteObject(wimage)

  proc newWindowImpl(w, h: int): Window = with result:
    handle = CreateWindow(wClassName, "", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 
                          w.int32, h.int32, 0, 0, hInstance, nil)
    winassert handle != 0
    m_hasFocus = true
    discard handle.SetWindowLongPtrW(GWLP_USERDATA, cast[LONG_PTR](result.addr))
    handle.trackMouseEvent(TME_HOVER)
    result.size = (w, h)

    var bmi = BITMAPINFO(bmiHeader: BITMAPINFOHEADER(biSize: BITMAPINFOHEADER.sizeof.int32, biWidth: w.LONG, biHeight: -h.LONG,
                         biPlanes: 1, biBitCount: 32, biCompression: BI_RGB, biSizeImage: 0, biXPelsPerMeter: 0, biYPelsPerMeter: 0, biClrUsed: 0, biClrImportant: 0));
    wimage  = CreateDIBSection(0, bmi.addr, DIB_RGB_COLORS, cast[ptr pointer](m_data.addr), 0, 0)
    hdc     = CreateCompatibleDC(0)
    winassert wimage != 0
    winassert hdc != 0
    discard hdc.SelectObject(wimage)

  proc `title=`*(a: Window, title: string) = with a:
    handle.SetWindowText(title)

  proc poolEvent(a: var Window, message: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT = with a:
    discard
else:
  {.error: "current OS is not supported".}

proc newWindow*(w: int = 1280, h: int = 720, title: string = ""): Window =
  result = newWindowImpl(w, h)
  result.title = title

template w*(a: Screen): int = a.size.x
template h*(a: Screen): int = a.size.y

converter toPicture*(a: Window): Picture = Picture(size: a.m_size, data: a.m_data)
