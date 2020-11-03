import times
import with
import color, image, geometry
import libx11 as x

type
  MouseButton* = enum
    left right middle forward backward
  Mouse* = tuple
    position: Vec2i
    pressed: array[left..backward, bool]
    
  Cursor* {.pure.} = enum
    arrow sizeAll hand sizeHorisontal sizeVertical arrowUp

  Window* = object
    m_data: ArrayPtr[Color]
    m_size: Vec2i

    onClose*:       proc(e: CloseEvent)
    
    onRender*:      proc(e: RenderEvent)
    onResize*:      proc(e: ResizeEvent)
    onWindowMove*:  proc(e: ResizeEvent)

    mouse*: Mouse # состояние мыши
    onMouseMove*:   proc(e: MouseMoveEvent)
    onMouseLeave*:  proc(e: MouseMoveEvent)
    onMouseEnter*:  proc(e: MouseMoveEvent)
    onMouseDown*:   proc(e: MouseButtonEvent)
    onMouseUp*:     proc(e: MouseButtonEvent)
    onClick*:       proc(e: ClickEvent)
    onDoubleClick*: proc(e: ClickEvent)
    onScroll*:      proc(e: ScrollEvent)
    
    onFocus*:       proc(e: FocusEvent)

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
      clicking: array[left..backward, bool]

      m_isOpen: bool
      m_hasFocus: bool
      m_isFullscreen: bool

      waitForDisplay: bool

      m_pos: Vec2i

  CloseEvent* = tuple

  RenderEvent* = tuple
    data: ArrayPtr[Color]
    size: Vec2i
  ResizeEvent* = tuple
    oldSize, size: Vec2i
  WindowMoveEvent* = tuple
    olsPositin, position: Vec2i

  MouseMoveEvent* = tuple
    mouse: Mouse
    oldPosition, position: Vec2i
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
  # TODO

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

  proc position*(a: var Window): Vec2i = with a:
    let (_, x, y, _, _, _, _) = xwin.getGeometry()
    m_pos = (x.int, y.int)
    return m_pos
  proc `position=`*(a: var Window, p: Vec2i) = with a:
    xcheck d.XMoveWindow(xwin, p.x.cint, p.y.cint)
    m_pos = p
  proc size*(a: Window): Vec2i = a.m_size
  proc `size=`*(a: var Window, size: Vec2i) = with a:
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

    var mask = newImage(img.size)
    for i in 0.vec2..<img.size:
      mask[i] = if img[i].a > 127: color(0, 0, 0) else: color(255, 255, 255)
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
    # TODO
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
    
    while m_isOpen:

      proc checkEvent(_: PDisplay, event: PXEvent, userData: XPointer): XBool {.cdecl.} =
        return if event.xany.window == (x.Window)(cast[int](userData)): 1 else: 0
      while d.XCheckIfEvent(ev.addr, checkEvent, cast[XPointer](xwin)) == 1:
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
            m_pos = vec2i (ev.xconfigure.x, ev.xconfigure.y)
            push_event onWindowMove, (oldPos, m_pos)

        of MotionNotify:
          let oldPos = mouse.position
          mouse.position = vec2i (ev.xmotion.x, ev.xmotion.y)
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
          push_event onMouseLeave, (mouse, mouse.position, vec2i (ev.xcrossing.x, ev.xcrossing.y))
        of EnterNotify:
          push_event onMouseEnter, (mouse, mouse.position, vec2i (ev.xcrossing.x, ev.xcrossing.y))

        of FocusIn:
          m_hasFocus = true
          if xinContext != nil: XSetICFocus xinContext
          push_event onFocus, (true)
        of FocusOut:
          m_hasFocus = false
          if xinContext != nil: XSetICFocus xinContext
          push_event onFocus, (false)

        else: discard

      if waitForDisplay:
        waitForDisplay = false
        push_event on_render, (m_data, m_size)
        a.displayImpl()

else:
  proc newWindowImpl(w, h: int): Window = new result

proc newWindow*(w: int = 1280, h: int = 720, title: string = ""): Window =
  result = newWindowImpl(w, h)
  result.title = title

converter toPicture*(a: Window): Picture = Picture(size: a.m_size, data: a.m_data)
