import std/[times, os, options, importutils, sequtils]
import pkg/[vmath]
import ./[winapi]
import ../../[colorutils, siwindefs]
import ../any/[window, clipboards]
import ../any/[windowUtils]

privateAccess Window

{.experimental: "overloadableEnums".}

type
  ScreenWinapi* = ref object of Screen
  
  Buffer = object
    x, y: int
    bitmap: HBitmap
    hdc: Hdc
    pixels: pointer

  ClipboardWinapi* = ref object of Clipboard

  ClipboardWinapiDnd* = ref object of Clipboard

  WindowWinapi* = ref WindowWinapiObj
  WindowWinapiObj* = object of Window
    handle: HWnd
    wicon: HIcon
    hdc: Hdc
    wcursor: HCursor
    restoreSize, restorePos: IVec2

  WindowWinapiSoftwareRendering* = ref object of WindowWinapi
    buffer: Buffer


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
proc screenCountWinapi*(): int32 = 1

proc screenWinapi*(number: int32): ScreenWinapi = new result
proc defaultScreenWinapi*(): ScreenWinapi = screenWinapi(0)
method number*(screen: ScreenWinapi): int32 = 0

method width*(screen: ScreenWinapi): int32 = GetSystemMetrics(SmCxScreen)
method height*(screen: ScreenWinapi): int32 = GetSystemMetrics(SmCyScreen)


proc `=destroy`(buffer: Buffer) {.siwin_destructor.} =
  if buffer.hdc != 0:
    DeleteDC buffer.hdc
    DeleteObject buffer.bitmap


proc `=destroy`(window: WindowWinapiObj) {.siwin_destructor.} =
  if window.hdc != 0:
    DeleteDC window.hdc

  if window.wicon != 0:
    DestroyIcon window.wicon

  if window.wcursor != 0:
    DestroyCursor window.wcursor


proc poolEvent(window: WindowWinapi, message: Uint, wParam: WParam, lParam: LParam): LResult

proc windowProc(handle: HWnd, message: Uint, wParam: WParam, lParam: LParam): LResult {.stdcall.} =
  let win = if handle != 0: cast[WindowWinapi](GetWindowLongPtr(handle, GwlpUserData)) else: nil

  if win != nil: win.poolEvent(message, wParam, lParam)
  else:          DefWindowProc(handle, message, wParam, lParam)

const
  wClassName = L"w"
  woClassName = L"o"

block winapiInit:
  var wcex = WndClassEx(
    cbSize:        WndClassEx.sizeof.int32,
    style:         CsHRedraw or CsVRedraw or CsDblClks,
    hInstance:     hInstance,
    hCursor:       LoadCursor(0, IdcArrow),
    lpfnWndProc:   windowProc,
    lpszClassName: wClassName,
  )
  RegisterClassEx(wcex.addr)

  wcex.lpszClassName = woClassName
  RegisterClassEx(wcex.addr)

template pushEvent(eventsHandler: WindowEventsHandler, event, args) =
  if eventsHandler.event != nil:
    eventsHandler.event(args)

method `fullscreen=`*(window: WindowWinapi, v: bool) =
  if window.m_fullscreen == v: return
  window.m_fullscreen = v
  if v:
    window.handle.SetWindowLongPtr(GwlStyle, WsVisible)
    discard window.handle.ShowWindow(SwMaximize)
  else:
    window.handle.ShowWindow(SwShowNormal)
    discard window.handle.SetWindowLongPtr(GwlStyle, WsVisible or WsOverlappedWindow)
    window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
      window: window, kind: StateBoolChangedEventKind.fullscreen, value: v
    )

method `size=`*(window: WindowWinapi, size: IVec2) =
  window.fullscreen = false
  let rcClient = window.handle.clientRect
  var rcWind = window.handle.windowRect
  let borderx = (rcWind.right - rcWind.left) - rcClient.right
  let bordery = (rcWind.bottom - rcWind.top) - rcClient.bottom
  window.handle.MoveWindow(rcWind.left, rcWind.top, (size.x + borderx).int32, (size.y + bordery).int32, True)


proc enableTransparency*(window: WindowWinapi) =
  let region = CreateRectRgn(0, 0, -1, -1)

  # enabling blur will force Windows to compose our window with transparency
  var bb = DwmBlurBehind()
  bb.dwFlags = DwmbbEnable or DwmbbBlurRegion
  bb.fEnable = True
  bb.hRgnBlur = region  # "blur" somewhere outside the window, ideally nothing

  window.handle.DwmEnableBlurBehindWindow(bb.addr)

  DeleteObject(region)


proc initWindow(window: WindowWinapi; size: IVec2; screen: ScreenWinapi, fullscreen, frameless, transparent: bool, class = wClassName) =
  window.handle = CreateWindow(
    class,
    "",
    if frameless: WsPopup or WsMinimizeBox
    else: WsOverlappedWindow,
    CwUseDefault, CwUseDefault,
    size.x, size.y,
    0, 0,
    hInstance,
    nil
  )
  discard ShowWindow(window.handle, SwHide)
  window.m_frameless = frameless

  window.m_focused = true  #? is it correct?
  window.wcursor = LoadCursor(0, IdcArrow)
  window.handle.SetWindowLongPtrW(GwlpUserData, cast[LongPtr](window))
  window.handle.trackMouseEvent(TmeHover)
  window.handle.trackMouseEvent(TmeLeave)
  window.hdc = window.handle.GetDC
  
  window.m_size = size
  if fullscreen:
    window.m_fullscreen = true
    window.handle.SetWindowLongPtr(GwlStyle, WsVisible)
    discard window.handle.ShowWindow(SwMaximize)

  if transparent:
    window.m_transparent = true
    window.enableTransparency()
  
  window.m_clipboard = ClipboardWinapi(availableKinds: {ClipboardContentKind.text})  # todo: other types
  window.m_selectionClipboard = window.m_clipboard
  window.m_dragndropClipboard = ClipboardWinapiDnd()  # todo


method `title=`*(window: WindowWinapi, title: string) =
  window.handle.SetWindowText(title)

method close*(window: WindowWinapi) =
  if not window.m_closed: window.handle.SendMessage(WmClose, 0, 0)

method redraw*(window: WindowWinapi) =
  if window.redrawRequested: return
  window.redrawRequested = true

  var cr = window.handle.clientRect
  window.handle.InvalidateRect(cr.addr, false.WinBool)

method `pos=`*(window: WindowWinapi, v: IVec2) =
  if window.m_fullscreen: return
  window.handle.SetWindowPos(0, v.x, v.y, 0, 0, SwpNoSize)


method `cursor=`*(window: WindowWinapi, v: Cursor) =
  if window.m_cursor.kind == builtin and v.kind == builtin and v.builtin == window.m_cursor.builtin: return
  if window.wcursor != 0: DestroyCursor window.wcursor
  window.m_cursor = v

  case v.kind
  of builtin:
    var cu: HCursor = case v.builtin
    of BuiltinCursor.arrow:           LoadCursor(0, IdcArrow)
    of BuiltinCursor.arrowUp:         LoadCursor(0, IdcUpArrow)
    of BuiltinCursor.pointingHand:    LoadCursor(0, IdcHand)
    of BuiltinCursor.arrowRight:      LoadCursor(0, IdcArrow) #! no needed cursor
    of BuiltinCursor.wait:            LoadCursor(0, IdcWait)
    of BuiltinCursor.arrowWait:       LoadCursor(0, IdcAppStarting)
    of BuiltinCursor.grab:            LoadCursor(0, IdcHand) #! no needed cursor
    of BuiltinCursor.text:            LoadCursor(0, IdcIBeam)
    of BuiltinCursor.cross:           LoadCursor(0, IdcCross)
    of BuiltinCursor.sizeAll:         LoadCursor(0, IdcSizeAll)
    of BuiltinCursor.sizeVertical:    LoadCursor(0, IdcSizens)
    of BuiltinCursor.sizeHorizontal:  LoadCursor(0, IdcSizewe)
    of BuiltinCursor.sizeTopLeft:     LoadCursor(0, IdcSizenwse)
    of BuiltinCursor.sizeTopRight:    LoadCursor(0, IdcSizenesw)
    of BuiltinCursor.sizeBottomLeft:  LoadCursor(0, IdcSizenesw)
    of BuiltinCursor.sizeBottomRight: LoadCursor(0, IdcSizenwse)
    of BuiltinCursor.hided:           LoadCursor(0, IdcNo)

    if cu != 0:
      SetCursor cu
      window.wcursor = cu
  
  of image:
    if v.image.pixels.size.x * v.image.pixels.size.y == 0:
      window.cursor = Cursor(kind: builtin, builtin: BuiltinCursor.hided)
      return

    if window.wcursor != 0: DestroyCursor window.wcursor

    let sourceFormat = v.image.pixels.format  # to convert pixels back later
    var buffer = v.image.pixels
    convertPixelsInplace(buffer.data, buffer.size, sourceFormat, PixelBufferFormat.bgra_32bit)

    window.wcursor = CreateIcon(hInstance, buffer.size.x, buffer.size.y, 1, 32, nil, cast[ptr Byte](buffer.data))
    SetCursor window.wcursor

    convertPixelsInplace(buffer.data, buffer.size, PixelBufferFormat.bgra_32bit, sourceFormat)
  

method `icon=`*(window: WindowWinapi, _: nil.typeof) =
  ## clear icon
  if window.wicon != 0:
    DestroyIcon window.wicon
    window.wicon = 0
  
  window.handle.SendMessageW(WmSetIcon, IconBig, 0)
  window.handle.SendMessageW(WmSetIcon, IconSmall, 0)

method `icon=`*(window: WindowWinapi, v: PixelBuffer) =
  ## set icon
  if v.size.x * v.size.y == 0:
    window.icon = nil
    return

  if window.wicon != 0: DestroyIcon window.wicon
  
  let sourceFormat = v.format  # to convert pixels back later
  var buffer = v
  convertPixelsInplace(buffer.data, buffer.size, sourceFormat, PixelBufferFormat.bgra_32bit)

  window.wicon = CreateIcon(hInstance, v.size.x, v.size.y, 1, 32, nil, cast[ptr Byte](v.data))
  window.handle.SendMessageW(WmSetIcon, IconBig, window.wicon)
  window.handle.SendMessageW(WmSetIcon, IconSmall, window.wicon)

  convertPixelsInplace(buffer.data, buffer.size, PixelBufferFormat.bgra_32bit, sourceFormat)


proc resizeBufferIfNeeded(buffer: var Buffer, size: IVec2) =
  if size.x != buffer.x or size.y != buffer.y:
    if buffer.hdc != 0:
      DeleteDC buffer.hdc
      DeleteObject buffer.bitmap
    
    buffer.x = size.x
    buffer.y = size.y
  
    var bmi = BitmapInfo(
      bmiHeader: BitmapInfoHeader(
        biSize: BitmapInfoHeader.sizeof.int32, biWidth: size.x.Long, biHeight: -size.y.Long,
        biPlanes: 1, biBitCount: 32, biCompression: Bi_rgb
      )
    )
    buffer.bitmap = CreateDibSection(0, bmi.addr, Dib_rgb_colors, cast[ptr pointer](buffer.pixels.addr), 0, 0)
    buffer.hdc = CreateCompatibleDC(0)
    buffer.hdc.SelectObject buffer.bitmap


method pixelBuffer*(window: WindowWinapiSoftwareRendering): PixelBuffer =
  result = PixelBuffer(
    data: window.buffer.pixels,
    size: ivec2(window.buffer.x.int32, window.buffer.y.int32),
    format: (if window.transparent: PixelBufferFormat.bgrx_32bit else: PixelBufferFormat.bgru_32bit)
  )


proc releaseAllKeys(window: WindowWinapi) =
  for key in window.keyboard.pressed:
    window.keyboard.pressed.excl key
    window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: key, pressed: false, repeated: false, generated: true)

  for button in window.mouse.pressed:
    window.mouse.pressed.excl button
    window.eventsHandler.pushEvent onMouseButton, MouseButtonEvent(window: window, button: button, pressed: false, generated: true)


method `maximized=`*(window: WindowWinapi, v: bool) =
  if window.m_maximized == v: return
  if window.m_frameless:
    if v:
      window.restoreSize = window.size
      window.restorePos = window.pos
      var workArea: Rect
      discard SystemParametersInfo(SpiGetWorkArea, 0, workArea.addr, 0)
      window.size = ivec2(workArea.right - workArea.left, workArea.bottom - workArea.top)
      window.pos = ivec2(workArea.left, workArea.top)
    else:
      window.size = window.restoreSize
      window.pos = window.restorePos
  else:
    discard ShowWindow(window.handle, if v: SwMaximize else: SwNormal)
  window.m_maximized = v
  window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
    window: window, kind: StateBoolChangedEventKind.maximized, value: window.m_maximized
  )


method `minimized=`*(window: WindowWinapi, v: bool) =
  window.releaseAllKeys()
  window.m_minimized = v
  discard ShowWindow(window.handle, if v: SwShowMinNoActive  else: SwNormal)


method `visible=`*(window: WindowWinapi, v: bool) =
  window.m_visible = v
  discard ShowWindow(window.handle, if v: SwShow else: SwHide)


method `resizable=`*(window: WindowWinapi, v: bool) =
  if not window.m_frameless:
    let style = GetWindowLongW(window.handle, GwlStyle)
    discard SetWindowLongW(window.handle, GwlStyle, if v: style or WsThickframe else: style and not WsThickframe)
  window.m_minSize = ivec2()
  window.m_maxSize = ivec2()


method `minSize=`*(window: WindowWinapi, v: IVec2) =
  window.m_minSize = v
  if not window.m_frameless:
    let style = GetWindowLongW(window.handle, GwlStyle)
    discard SetWindowLongW(window.handle, GwlStyle, style or WsThickframe)

method `maxSize=`*(window: WindowWinapi, v: IVec2) =
  window.m_maxSize = v
  if not window.m_frameless:
    let style = GetWindowLongW(window.handle, GwlStyle)
    discard SetWindowLongW(window.handle, GwlStyle, style or WsThickframe)


method startInteractiveMove*(window: WindowWinapi, pos: Option[Vec2]) =
  window.releaseAllKeys()
  ReleaseCapture()

  window.handle.PostMessage(WmSysCommand, 0xF012, 0)
  # todo: press all keys and mouse buttons that are pressed after move

method startInteractiveResize*(window: WindowWinapi, edge: Edge, pos: Option[Vec2]) =
  window.releaseAllKeys()
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


method showWindowMenu*(window: WindowWinapi, pos: Option[Vec2]) =
  discard


method content*(clipboard: ClipboardWinapi, kind: ClipboardContentKind, mimeType: string): ClipboardContent =
  discard OpenClipboard(0)

  let hcpb = GetClipboardData(CfUnicodeText)
  if hcpb == 0:
    CloseClipboard()
    return
  
  result = ClipboardContent(kind: ClipboardContentKind.text, text: $cast[PWChar](GlobalLock hcpb))  # todo: other types
  GlobalUnlock hcpb
  discard CloseClipboard()


method `content=`*(clipboard: ClipboardWinapi, content: ClipboardConvertableContent) =
  var conv: ClipboardContentConverter
  for cv in content.converters:
    case cv.kind
    of ClipboardContentKind.text:
      conv = cv
    else:
      ## todo

  if conv.f == nil: return

  let content = conv.f(content.data, conv.kind, conv.mimeType)
  if content.kind != ClipboardContentKind.text: return

  let s = content.text

  discard OpenClipboard(0)
  discard EmptyClipboard()
  
  let ws = +$s
  let ts = (ws.len + 1) * WChar.sizeof
  let hstr = GlobalAlloc(GMemMoveable, ts)
  if hstr == 0:
    CloseClipboard()
    raise OSError.newException("failed to alloc string")

  copyMem(GlobalLock hstr, ws.winstrConverterWStringToLPWstr, ts)
  GlobalUnlock hstr
  SetClipboardData(CfUnicodeText, hstr)
  CloseClipboard()


method displayImpl(window: WindowWinapi) {.base.} =
  var ps: PaintStruct
  window.handle.BeginPaint(ps.addr)
  
  window.eventsHandler.pushEvent onRender, RenderEvent(window: window)
  
  if window of WindowWinapiSoftwareRendering:
    BitBlt(
      window.hdc, 0, 0, window.m_size.x, window.m_size.y,
      window.WindowWinapiSoftwareRendering.buffer.hdc, 0, 0, SrcCopy
    )
  
  window.handle.EndPaint(ps.addr)


method firstStep*(window: WindowWinapi, makeVisible = true) =
  if makeVisible:
    window.visible = true
  
  if window of WindowWinapiSoftwareRendering:
    resizeBufferIfNeeded window.WindowWinapiSoftwareRendering.buffer, window.m_size

  window.eventsHandler.pushEvent onResize, ResizeEvent(window: window, size: window.m_size, initial: true)

  window.handle.UpdateWindow()

  window.lastTickTime = getTime()


proc updateWindowState(window: WindowWinapi) =
  if not window.m_frameless and IsZoomed(window.handle).bool != window.m_maximized:
    window.m_maximized = not window.m_maximized
    window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
      window: window, kind: StateBoolChangedEventKind.maximized, value: window.m_maximized
    )
  
  window.m_minimized = IsIconic(window.handle) != 0
  window.m_visible = IsWindowVisible(window.handle) != 0
  window.m_resizable = (GetWindowLongW(window.handle, GwlStyle) and WsThickframe) != 0
  
  var p: WindowPlacement
  p.length = sizeof(WindowPlacement).int32
  GetWindowPlacement(window.handle, p.addr)
  window.m_pos = ivec2(p.rcNormalPosition.left, p.rcNormalPosition.top)


method step*(window: WindowWinapi) =
  var msg: Msg
  var catched = false

  while PeekMessage(msg.addr, 0, 0, 0, PmRemove).bool:
    TranslateMessage(msg.addr)
    DispatchMessage(msg.addr)

    # force make tick if windows decided to spam events to us
    if (getTime() - window.lastTickTime) > initDuration(milliseconds=10):
      break

    if window.m_closed: return

  if not catched: sleep(1)

  let nows = getTime()
  window.eventsHandler.pushEvent onTick, TickEvent(window: window, deltaTime: nows - window.lastTickTime)
  window.lastTickTime = nows


proc poolEvent(window: WindowWinapi, message: Uint, wParam: WParam, lParam: LParam): LResult =
  updateWindowState(window)

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
    window.redrawRequested = false
    let rect = window.handle.clientRect
    if rect.right != window.m_size.x or rect.bottom != window.m_size.y:
      window.m_size = ivec2(rect.right, rect.bottom)
  
      if window of WindowWinapiSoftwareRendering:
        resizeBufferIfNeeded window.WindowWinapiSoftwareRendering.buffer, window.m_size

      window.eventsHandler.pushEvent onResize, ResizeEvent(window: window, size: window.m_size, initial: false)

    if window.m_size.x * window.m_size.y > 0:
      window.displayImpl()

  of WmDestroy:
    window.m_closed = true
    window.eventsHandler.pushEvent onClose, CloseEvent(window: window)
    PostQuitMessage(0)

  of WmMouseMove:
    window.mouse.pos = vec2(lParam.GetX_LParam.float32, lParam.GetY_LParam.float32)
    window.clicking = {}
    window.eventsHandler.pushEvent onMouseMove, MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.move)

  of WmMouseLeave:
    window.mouse.pos = vec2(lParam.GetX_LParam.float32, lParam.GetY_LParam.float32)
    window.clicking = {}
    window.eventsHandler.pushEvent onMouseMove, MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.leave)
    window.handle.trackMouseEvent(TmeHover)

  of WmMouseHover:
    window.mouse.pos = vec2(lParam.GetX_LParam.float32, lParam.GetY_LParam.float32)
    window.clicking = {}
    window.eventsHandler.pushEvent onMouseMove, MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.enter)
    window.handle.trackMouseEvent(TmeLeave)

  of WmMouseWheel:
    let delta = if wParam.GetWheelDeltaWParam > 0: -1.0 else: 1.0
    window.eventsHandler.pushEvent onScroll, ScrollEvent(window: window, delta: delta)

  of WmSetFocus:
    window.m_focused = true
    window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
      window: window, kind: StateBoolChangedEventKind.focus, value: true
    )

    let keys = getKeyboardState().mapit(wkeyToKey(it))
    for k in keys: # press pressed in system keys
      if k == Key.unknown: continue
      window.keyboard.pressed.incl k
      window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: k, pressed: false, repeated: false)

  of WmKillFocus:
    window.m_focused = false
    window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
      window: window, kind: StateBoolChangedEventKind.focus, value: false
    )
    let pressed = window.keyboard.pressed
    for key in pressed: # release all keys
      window.keyboard.pressed.excl key
      window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: key, pressed: false, repeated: false)

  of WmLButtonDown, WmRButtonDown, WmMButtonDown, WmXButtonDown:
    window.handle.SetCapture()
    window.mouse.pressed.incl button
    window.clicking.incl button
    window.eventsHandler.pushEvent onMouseButton, MouseButtonEvent(window: window, button: button, pressed: true)

  of WmLButtonDblclk, WmRButtonDblclk, WmMButtonDblclk, WmXButtonDblclk:
    window.handle.SetCapture()
    window.mouse.pressed.incl button
    window.eventsHandler.pushEvent onMouseButton, MouseButtonEvent(window: window, button: button, pressed: true)
    window.eventsHandler.pushEvent onClick, ClickEvent(window: window, button: button, pos: window.mouse.pos, double: true)

  of WmLButtonUp, WmRButtonUp, WmMButtonUp, WmXButtonUp:
    ReleaseCapture()
    window.mouse.pressed.excl button
    if button in window.clicking:
      window.eventsHandler.pushEvent onClick, ClickEvent(window: window, button: button, pos: window.mouse.pos, double: false)
      window.clicking.excl button
    window.eventsHandler.pushEvent onMouseButton, MouseButtonEvent(window: window, button: button, pressed: false)

  of WmKeyDown, WmSysKeyDown:
    let key = wkeyToKey(wParam, lParam)
    if key != Key.unknown:
      let repeated = key in window.keyboard.pressed
      window.keyboard.pressed.incl key
      window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: key, pressed: true, repeated: repeated)

  of WmKeyUp, WmSysKeyUp:
    let key = wkeyToKey(wParam, lParam)
    if key != Key.unknown:
      let repeated = key notin window.keyboard.pressed
      window.keyboard.pressed.excl key
      window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: key, pressed: false, repeated: repeated)

  of WmChar, WmSyschar, WmUnichar:
    if window.eventsHandler.onTextInput == nil: return 1  # no need to handle
    if (window.keyboard.pressed * {lcontrol, rcontrol, lalt, ralt}).len == 0:
      let s = %$[wParam.WChar]
      if s.len > 0 and s notin ["\u001B"]:
        window.eventsHandler.pushEvent onTextInput, TextInputEvent(window: window, text: s)

  of WmSetCursor:
    if lParam.LoWord == HtClient:
      SetCursor window.wcursor
      return 1
    return window.handle.DefWindowProc(message, wParam, lParam)
  
  of WmGetMinMaxInfo:
    let info = cast[LpMinMaxInfo](lParam)
    if window.m_minSize != ivec2():
      info[].ptMinTrackSize.x = window.m_minSize.x
      info[].ptMinTrackSize.y = window.m_minSize.y
    if window.m_maxSize != ivec2():
      info[].ptMaxTrackSize.x = window.m_maxSize.x
      info[].ptMaxTrackSize.y = window.m_maxSize.y

  of WmNcHitTest:
    if window.titleRegion.isNone and window.borderWidth.isNone: return window.handle.DefWindowProc(message, wParam, lParam)

    var pos = Point(x: lParam.GetX_LParam.LONG, y: lParam.GetY_LParam.LONG)
    ScreenToClient(window.handle, pos.addr)
    let pos_f32 = vec2(pos.x.float32, pos.y.float32)

    case window.windowPartAt(pos_f32)
    of WindowPart.title: return HtCaption
    of WindowPart.client: return HtClient
    of WindowPart.border_top_left: return HtTopLeft
    of WindowPart.border_top_right: return HtTopRight
    of WindowPart.border_bottom_left: return HtBottomLeft
    of WindowPart.border_bottom_right: return HtBottomRight
    of WindowPart.border_top: return HtTop
    of WindowPart.border_bottom: return HtBottom
    of WindowPart.border_left: return HtLeft
    of WindowPart.border_right: return HtRight
    of WindowPart.none: return HtTransparent
  
  of WmDwmCompositionChanged:
    if window.transparent:
      window.enableTransparency()

  else: return window.handle.DefWindowProc(message, wParam, lParam)


proc newSoftwareRenderingWindowWinapi*(
  size = ivec2(1280, 720),
  title = "",
  screen = defaultScreenWinapi(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
): WindowWinapiSoftwareRendering =
  new result
  result.initWindow(size, screen, fullscreen, frameless, transparent)
  result.title = title
  if not resizable: result.resizable = false
