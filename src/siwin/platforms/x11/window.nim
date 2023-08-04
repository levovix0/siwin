import std/[times, importutils, strformat, sequtils, os, options, tables]
import pkg/[vmath, chroma]
import pkg/x11/xlib except Screen
import pkg/x11/x except Window, Cursor, Time
import pkg/x11/[xutil, xatom, cursorfont, keysym]
import ../../utils, ../../bgrx
import ../any/window {.all.}
import globalDisplay

{.experimental: "overloadableEnums".}

privateAccess Window

type
  GraphicsContext = object
    gc: GC
    gcv: XGCValues

  XSyncValue = object
    hi: int32
    lo: uint32
  
  XSyncCounter* = distinct XID

  SyncState = enum
    none
    syncRecieved
    syncAndConfigureRecieved


  ColorArgb = object
    a, r, g, b: byte

  CursorImage = object
    ver: uint32
    normalSize: uint32
    size: IVec2
    origin: IVec2
    delay: uint32
    pixels: ptr ColorArgb
  

  ScreenX11* = ref object of Screen
    id: cint
    handle: PScreen


  WindowX11* = ref WindowX11Obj
  WindowX11Obj* = object of Window
    handle: x.Window
    screen: cint
    xIcon: Pixmap
    xIconMask: Pixmap
    xInContext: XIC
    xInMethod: XIM
    xCursor: x.Cursor
    xSyncCounter: XSyncCounter
    syncState: SyncState
    lastSync: XSyncValue

    lastClickTime: Time
    doubleClickHandled: bool
  
  WindowX11SoftwareRendering* = ref object of WindowX11
    gc: GraphicsContext


const libXExt* =
  when defined(macosx):
    "libXext.dylib"
  else:
    "libXext.so(|.6)"

{.push, cdecl, dynlib: libXExt, importc.}

proc XSyncQueryExtension(d: ptr Display, vEv, vEr: ptr cint): bool
proc XSyncInitialize(d: ptr Display, verMaj, verMin: ptr cint)

proc XSyncCreateCounter(d: ptr Display, v: XSyncValue): XSyncCounter
proc XSyncDestroyCounter(d: ptr Display, c: XSyncCounter)

proc XSyncSetCounter(d: ptr Display, c: XSyncCounter; v: XSyncValue)

{.pop.}


const libXCursor* = "libXcursor.so(|.1)"

{.push, cdecl, dynlib: libXCursor, importc.}

proc XcursorImageLoadCursor(d: ptr Display, image: ptr CursorImage): x.Cursor

{.pop.}


proc `=destroy`(gc: GraphicsContext) =
  if gc.gc != nil:
    discard display.XFreeGC(gc.gc)


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


proc newClientMessage[T](window: x.Window, messageKind: Atom, data: openarray[T], serial: int = 0, sendEvent: bool = false): XEvent =
  result.theType = ClientMessage
  result.xclient.messageType = messageKind
  if data.len * T.sizeof > XClientMessageData.sizeof:
    raise ValueError.newException(&"to much data in client message (>{XClientMessageData.sizeof} bytes)")
  copyMem(result.xclient.data.addr, data.dataAddr, data.len * T.sizeof)
  result.xclient.format = case T.sizeof
    of 1: 8
    of 2: 16
    of 4: 32
    of 8: 32
    else: 8
  result.xclient.window = window
  result.xclient.display = display
  result.xclient.serial = serial.culong
  result.xclient.sendEvent = sendEvent.XBool

proc geometry(a: x.Window): tuple[root: x.Window; pos: IVec2; size: IVec2; borderW: int, depth: int] =
  var
    root: x.Window
    x, y: cint
    w, h: cuint
    borderW: cuint
    depth: cuint
  discard display.XGetGeometry(a, root.addr, x.addr, y.addr, w.addr, h.addr, borderW.addr, depth.addr)
  (root, ivec2(x.int32, y.int32), ivec2(w.int32, h.int32), borderW.int, depth.int)

proc asXImage(data: openarray[ColorBgrx], size: IVec2, transparent = false): XImage = XImage(
  width: cint size.x,
  height: cint size.y,
  depth: if transparent: 32 else: 24,
  bitsPerPixel: 32,
  format: ZPixmap,
  data: cast[cstring](data.dataAddr),
  byteOrder: LSBFirst,
  bitmapUnit: display.BitmapUnit,
  bitmapBitOrder: LSBFirst,
  bitmapPad: 32,
  bytesPerLine: cint size.x * ColorBgrx.sizeof
)

proc cursor: tuple[pos: IVec2; root, child: x.Window; winX, winY: int; mask: uint; exists: bool] =
  ## find cursor and return where it is
  var
    root, child: x.Window
    x, y: cint
    winX, winY: cint
    mask: cuint
  for i in 0..display.ScreenCount:
    if display.XQueryPointer(display.XRootWindow(i), root.addr, child.addr, x.addr, y.addr, winX.addr, winY.addr, mask.addr) != 0:
      return (ivec2(x.int32, y.int32), root, child, winX.int, winY.int, mask.uint, true)


method beginSwapBuffers(window: WindowX11) {.base.} = discard
method endSwapBuffers(window: WindowX11) {.base.} = discard


proc screenCountX11*: int32 =
  globalDisplay.init()
  display.ScreenCount.int32

proc screenX11*(number: int32): ScreenX11 =
  new result
  globalDisplay.init()
  if number notin 0..<screenCountX11(): raise IndexDefect.newException(&"screen {number} doesn't exist")
  result.id = number.cint
  result.handle = display.ScreenOfDisplay(result.id)

proc defaultScreenX11*: ScreenX11 =
  globalDisplay.init()
  screenX11(display.DefaultScreen.int32)

method number*(screen: ScreenX11): int32 = screen.id

method width*(screen: ScreenX11): int32 = screen.handle.width.int32
method height*(screen: ScreenX11): int32 = screen.handle.height.int32


proc `=destroy`(window: WindowX11Obj) =
  template destroy(x, f) =
    if x != typeof(x).default:
      f

  destroy window.xInContext: XDestroyIC window.xInContext
  destroy window.xInMethod:  discard XCloseIM window.xInMethod
  destroy window.xCursor:    discard display.XFreeCursor window.xCursor
  destroy window.xIcon:      discard display.XFreePixmap window.xIcon
  destroy window.xIconMask:  discard display.XFreePixmap window.xIconMask
  destroy window.handle:     discard display.XDestroyWindow window.handle
  
  if window.xSyncCounter.int != 0:
    display.XSyncDestroyCounter(window.xSyncCounter)


template pushEvent(eventsHandler: WindowEventsHandler, event, args) =
  if eventsHandler.event != nil:
    eventsHandler.event(args)


proc basicInitWindow(window: WindowX11; size: IVec2; screen: ScreenX11) =
  window.screen = screen.id
  window.m_size = size

  window.m_focused = true

proc setupWindow(window: WindowX11, fullscreen, frameless: bool, class: string) =
  discard display.XSelectInput(
    window.handle,
    ExposureMask or KeyPressMask or KeyReleaseMask or PointerMotionMask or ButtonPressMask or
    ButtonReleaseMask or StructureNotifyMask or EnterWindowMask or LeaveWindowMask or FocusChangeMask
  )

  window.m_fullscreen = fullscreen
  if fullscreen:
    var state = [atoms.netWmStateFullscreen]
    discard display.XChangeProperty(window.handle, atoms.netWmState, XaAtom, 32, PropModeReplace, cast[PCUchar](state[0].addr), state.len.cint)
    window.m_size = window.screen.screenX11.size

  var protocols = [atoms.wmDeleteWindow, atoms.netWmSyncRequest]
  discard display.XSetWMProtocols(window.handle, protocols[0].addr, protocols.len.cint)

  window.xinMethod = display.XOpenIM(nil, nil, nil)
  if window.xinMethod != nil:
    window.xinContext = window.xinMethod.XCreateIC(
      XNClientWindow, window.handle, XNFocusWindow, window.handle, XnInputStyle, XimPreeditNothing or XimStatusNothing, nil
    )
  
  window.frameless = frameless

  # init sync counter
  block xsync:
    var vEv, vEr: cint
    if display.XSyncQueryExtension(vEv.addr, vEr.addr):
      var vMaj, vMin: cint
      display.XSyncInitialize(vMaj.addr, vMin.addr)
      window.xSyncCounter = display.XSyncCreateCounter(XSyncValue())
      discard display.XChangeProperty(
        window.handle,
        atoms.netWmSyncRequestCounter,
        XaCardinal,
        32,
        0,
        cast[PCUchar](window.xSyncCounter.addr), 1
      )
  
  # set window VM class (can be used by window managers)
  block vmHint:
    var hint: XClassHint
    let name = getAppFilename()
    hint.res_name = name.cstring    # use filename as application name
    hint.res_class = class.cstring  # use class (same as title by default) as window class
    discard display.XSetClassHint(window.handle, hint.addr)


proc initSoftwareRenderingWindow(
  window: WindowX11SoftwareRendering,
  size: IVec2, screen: ScreenX11,
  fullscreen, frameless, transparent: bool, class: string
) =
  globalDisplay.init()
  window.basicInitWindow size, screen
  
  if transparent:
    window.m_transparent = true
    let root = display.DefaultRootWindow

    var vi: XVisualInfo
    discard display.XMatchVisualInfo(window.screen, if transparent: 32 else: 24, TrueColor, vi.addr)

    let cmap = display.XCreateColormap(root, vi.visual, AllocNone)
    var swa = XSetWindowAttributes(colormap: cmap)

    window.handle = display.XCreateWindow(
      root, 0, 0, size.x.cuint, size.y.cuint, 0, vi.depth, InputOutput, vi.visual,
      CwColormap or CwEventMask or CwBorderPixel or CwBackPixel, swa.addr
    )
  else:
    window.handle = display.XCreateSimpleWindow(
      display.DefaultRootWindow, 0, 0, size.x.cuint, size.y.cuint, 0, 0, display.BlackPixel(window.screen)
    )

  window.setupWindow fullscreen, frameless, class

  window.gc.gc = display.XCreateGC(window.handle, GCForeground or GCBackground, window.gc.gcv.addr)


method `title=`*(window: WindowX11, v: string) =
  discard display.XChangeProperty(
    window.handle, atoms.netWmName, atoms.utf8String, 8,
    PropModeReplace, cast[PCUchar](v.dataAddr), v.len.cint
  )
  discard display.XChangeProperty(
    window.handle, atoms.netWmIconName, atoms.utf8String, 8,
    PropModeReplace, cast[PCUchar](v.dataAddr), v.len.cint
  )
  display.Xutf8SetWMProperties(window.handle, v, v, nil, 0, nil, nil, nil)


method `fullscreen=`*(window: WindowX11, v: bool) =
  if window.m_fullscreen == v: return

  var event = window.handle.newClientMessage(atoms.netWmState, [Atom 2, atoms.netWmStateFullscreen])
  discard display.XSendEvent(
    window.handle, 0, SubstructureNotifyMask or SubstructureRedirectMask, event.addr
  )

  discard XFlush display


method `frameless=`*(window: WindowX11, v: bool) =
  if window.m_frameless == v: return
  defer: window.m_frameless = v
  
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
      window.handle, atoms.frameless, atoms.frameless, 32, PropModeReplace,
      cast[cstring](hints.addr), MWMHints.sizeof div 4
    )

  of WmForFramelessKind.kwm, WmForFramelessKind.other:
    var hints: clong = if v: 0 else: 1
    discard display.XChangeProperty(
      window.handle, atoms.frameless, atoms.frameless, 32, PropModeReplace,
      cast[cstring](hints.addr), clong.sizeof div 4
    )

  else: discard display.XSetTransientForHint(window.handle, display.RootWindow(window.screen))


method `size=`*(window: WindowX11, v: IVec2) =
  if window.fullscreen:
    window.fullscreen = false
  
  discard display.XResizeWindow(window.handle, v.x.cuint, v.y.cuint)

method `pos=`*(window: WindowX11, v: IVec2) =
  if window.m_fullscreen: return
  discard display.XMoveWindow(window.handle, v.x.cint, v.y.cint)


method `cursor=`*(window: WindowX11, v: Cursor) =
  if v.kind == builtin and window.cursor.kind == builtin and v.builtin == window.cursor.builtin: return
  if window.xCursor != 0:
    discard display.XFreeCursor(window.xCursor)
    window.xCursor = 0
  
  case v.kind
  of builtin:
    case v.builtin
    of BuiltinCursor.arrow:           window.xcursor = display.XCreateFontCursor(XcLeftPtr)
    of BuiltinCursor.arrowUp:         window.xcursor = display.XCreateFontCursor(XcCenterPtr)
    of BuiltinCursor.arrowRight:      window.xcursor = display.XCreateFontCursor(XcRightPtr)
    of BuiltinCursor.wait:            window.xcursor = display.XCreateFontCursor(XcWatch)
    of BuiltinCursor.arrowWait:       window.xcursor = display.XCreateFontCursor(XcWatch) #! no needed cursor
    of BuiltinCursor.pointingHand:    window.xcursor = display.XCreateFontCursor(XcHand1)
    of BuiltinCursor.grab:            window.xcursor = display.XCreateFontCursor(XcHand2)
    of BuiltinCursor.text:            window.xcursor = display.XCreateFontCursor(XcXterm)
    of BuiltinCursor.cross:           window.xcursor = display.XCreateFontCursor(XcTCross)
    of BuiltinCursor.sizeAll:         window.xcursor = display.XCreateFontCursor(XcFleur)
    of BuiltinCursor.sizeVertical:    window.xcursor = display.XCreateFontCursor(XcSb_v_doubleArrow)
    of BuiltinCursor.sizeHorisontal:  window.xcursor = display.XCreateFontCursor(XcSb_h_doubleArrow)
    of BuiltinCursor.sizeTopLeft:     window.xcursor = display.XCreateFontCursor(XC_ul_angle)
    of BuiltinCursor.sizeTopRight:    window.xcursor = display.XCreateFontCursor(XC_ur_angle)
    of BuiltinCursor.sizeBottomLeft:  window.xcursor = display.XCreateFontCursor(XC_ll_angle)
    of BuiltinCursor.sizeBottomRight: window.xcursor = display.XCreateFontCursor(XC_lr_angle)
    of BuiltinCursor.hided:
      var data: array[1, char]
      let blank = display.XCreateBitmapFromData(display.DefaultRootWindow, cast[cstring](data[0].addr), 1, 1)
      var pass: XColor
      window.xcursor = x.Cursor display.XCreatePixmapCursor(blank, blank, pass.addr, pass.addr, 0, 0)
      discard display.XFreePixmap blank

  of image:
    proc toArgb(x: openarray[ColorBgrx]): seq[ColorArgb] =
      result = newSeq[ColorArgb](x.len)
      for i, v in result.mpairs:
        v = ColorArgb(b: x[i].b, g: x[i].g, r: x[i].r, a: x[i].a)

    if v.image.size.x * v.image.size.y == 0:
      window.cursor = Cursor(kind: builtin, builtin: hided)
      return
    
    assert v.image.data.len >= v.image.size.x * v.image.size.y, "not enougth pixels"
    var pixels = v.image.data.toArgb
    var ci = CursorImage(
      ver: 1,
      normalSize: (if v.image.size.x > v.image.size.y: v.image.size.x.uint32 else: v.image.size.y.uint32),
      size: v.image.size,
      origin: v.image.origin,
      pixels: pixels[0].addr
    )
    window.xCursor = display.XcursorImageLoadCursor(ci.addr)

  discard display.XDefineCursor(window.handle, window.xCursor)
  discard display.XSync(0)
  window.m_cursor = v


proc newPixmap(source: tuple[pixels: openarray[ColorBgrx], size: IVec2], window: WindowX11): Pixmap =
  result = display.XCreatePixmap(window.handle, source.size.x.cuint, source.size.y.cuint, cuint display.DefaultDepth(window.screen))
  var image = asXImage(source.pixels, ivec2(source.size.x, source.size.y))
  var gc: GraphicsContext
  gc.gc = display.XCreateGC(result, GCForeground or GCBackground, gc.gcv.addr)
  discard display.XPutImage(result, gc.gc, image.addr, 0, 0, 0, 0, source.size.x.cuint, source.size.y.cuint)

method `icon=`*(window: WindowX11, v: nil.typeof) =
  if window.xicon != 0: discard display.XFreePixmap(window.xicon)
  if window.xiconMask != 0: discard display.XFreePixmap(window.xiconMask)
  window.xicon = 0.Pixmap
  window.xiconMask = 0.Pixmap
  var hints = XWmHints(flags: IconPixmapHint or IconMaskHint, iconPixmap: window.xicon, iconMask: window.xiconMask)
  discard display.XSetWMHints(window.handle, hints.addr)

method `icon=`*(window: WindowX11, v: tuple[pixels: openarray[ColorBgrx], size: IVec2]) =
  if v.size.x * v.size.y == 0: window.icon = nil
  assert v.pixels.len >= v.size.x * v.size.y, "not enougth pixels"
  if window.xicon != 0: discard display.XFreePixmap(window.xicon)
  if window.xiconMask != 0: discard display.XFreePixmap(window.xiconMask)

  window.xicon = newPixmap(v, window)

  # convert alpha channel to bit mask (semi-transparency is not supported)
  var mask =  newSeq[ColorBgrx](v.size.x * v.size.y)
  for i in 0..<(v.size.x * v.size.y):
    mask[i] = if v.pixels[i].a > 127: ColorBgrx(b: 0, g: 0, r: 0, a: 255) else: ColorBgrx(b: 255, g: 255, r: 255, a: 255)
  window.xiconMask = newPixmap((mask.toOpenarray(0, mask.high), v.size), window)

  var hints = XWmHints(flags: IconPixmapHint or IconMaskHint, iconPixmap: window.xicon, iconMask: window.xiconMask)
  discard display.XSetWMHints(window.handle, hints.addr)


method drawImage*(window: WindowX11SoftwareRendering, pixels: openarray[ColorBgrx], size: IVec2, pos: IVec2 = ivec2(), srcPos: IVec2 = ivec2()) =
  assert pixels.len >= size.x * size.y, "not enougth pixels"
  var ximg = asXImage(pixels, size, window.transparent)
  discard display.XPutImage(
    window.handle, window.gc.gc, ximg.addr, pos.x.cint, pos.y.cint, srcPos.x.cint, srcPos.y.cint, size.x.cuint, size.y.cuint
  )


method `maximized=`*(window: WindowX11, v: bool) =
  window.m_maximized = v
  if window.fullscreen:
    window.fullscreen = false
  var event = window.handle.newClientMessage(atoms.netWmState, [Atom v, atoms.netWmStateMaximizedHorz])
  discard display.XSendEvent(
    display.DefaultRootWindow, 0, SubstructureNotifyMask or SubstructureRedirectMask, event.addr
  )
  event.xclient.data.l[1] = atoms.netWmStateMaximizedVert.int
  discard display.XSendEvent(
    display.DefaultRootWindow, 0, SubstructureNotifyMask or SubstructureRedirectMask, event.addr
  )


proc releaseAllKeys(window: WindowX11) =
  ## release all pressed keys
  ## needed when window loses focus
  for k in window.keyboard.pressed.items:
    window.keyboard.pressed.excl k
    window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: k, pressed: false, repeated: false)

  for b in window.mouse.pressed:
    window.mouse.pressed.excl b
    window.eventsHandler.pushEvent onMouseButton, MouseButtonEvent(window: window, button: b, pressed: false)


method `minimized=`*(window: WindowX11, v: bool) =
  window.m_minimized = v
  if not v:
    discard display.XRaiseWindow(window.handle)
  else:
    window.releaseAllKeys()
    discard display.XIconifyWindow(window.handle, display.DefaultScreen)


method `visible=`*(window: WindowX11, v: bool) =
  if v == window.m_visible: return
  window.m_visible = v
  if v:
    discard display.XMapRaised(window.handle)
  else:
    discard display.XUnmapWindow(window.handle)


method `resizable=`*(window: WindowX11, v: bool) =
  window.m_resizable = v
  let size = window.size

  var hints: XSizeHints
  discard display.XGetNormalHints(window.handle, hints.addr)
  if v: hints.flags = hints.flags and not 0b110000
  else: hints.flags = hints.flags or 0b110000
  hints.minWidth = size.x
  hints.minHeight = size.y
  hints.maxWidth = size.x
  hints.maxHeight = size.y
  discard display.XSetNormalHints(window.handle, hints.addr)


method `minSize=`*(window: WindowX11, v: IVec2) =
  window.m_minSize = v
  var hints: XSizeHints
  discard display.XGetNormalHints(window.handle, hints.addr)
  hints.flags = hints.flags or 0b010000
  hints.minWidth = v.x
  hints.minHeight = v.y
  discard display.XSetNormalHints(window.handle, hints.addr)


method `maxSize=`*(window: WindowX11, v: IVec2) =
  window.m_maxSize = v
  var hints: XSizeHints
  discard display.XGetNormalHints(window.handle, hints.addr)
  hints.flags = hints.flags or 0b100000
  hints.maxWidth = v.x
  hints.maxHeight = v.y
  discard display.XSetNormalHints(window.handle, hints.addr)


method startInteractiveMove*(window: WindowX11, pos: Option[IVec2]) =
  window.releaseAllKeys()
  let pos = pos.get(cursor().pos)
  discard display.XUngrabPointer(0)
  discard XFlush display

  var event = window.handle.newClientMessage(
    atoms.netWmMoveResize,
    [pos.x.int64, pos.y.int64, 8, 1, 0] #? int32 is working strange, but int64 is ok
  )
  discard display.XSendEvent(
    display.DefaultRootWindow, 0, SubstructureNotifyMask or SubstructureRedirectMask, event.addr
  )
  # todo: press all keys and mouse buttons that are pressed after move

method startInteractiveResize*(window: WindowX11, edge: Edge, pos: Option[IVec2]) =
  window.releaseAllKeys()
  let pos = pos.get(cursor().pos)
  discard display.XUngrabPointer(0)
  discard XFlush display

  var event = window.handle.newClientMessage(
    atoms.netWmMoveResize,
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
  )
  discard display.XSendEvent(
    display.DefaultRootWindow, 0, SubstructureNotifyMask or SubstructureRedirectMask, event.addr
  )
  # todo: press all keys and mouse buttons that are pressed after resize


method firstStep*(window: WindowX11, makeVisible = true) =
  if makeVisible:
    window.visible = true

  window.m_pos = window.handle.geometry.pos
  window.mouse.pos = cursor().pos - window.m_pos
  
  window.eventsHandler.pushEvent onResize, ResizeEvent(window: window, size: window.m_size, initial: true)
  window.lastTickTime = getTime()


method step*(window: WindowX11) =
  ## make window main loop step
  ## ! don't forget to call firstStep()
  template button: MouseButton =
    case ev.xbutton.button
    of 1: MouseButton.left
    of 2: MouseButton.middle
    of 3: MouseButton.right
    of 8: MouseButton.backward
    of 9: MouseButton.forward
    else: MouseButton.left

  template isScroll: bool = ev.xbutton.button.int in 4..7

  template scrollDeltaY: float =
    case ev.xbutton.button
    of 4: -1
    of 5: 1
    else: 0

  template scrollDeltaX: float =
    case ev.xbutton.button
    of 6: -1
    of 7: 1
    else: 0
  
  proc extractKey(xkey: XKeyEvent): Key =
    var i = 0
    while i < 4 and result == Key.unknown:
      result = xkeyToKey(XLookupKeysym(xkey.unsafeaddr, i.cint))
      inc i

  proc pressAllKeys(window: WindowX11) =
    ## press pressed in system keys and mouse buttons
    ## needed when window gets focus
    proc queryKeyboardState: set[0..255] =
      var r: array[32, char]
      discard display.XQueryKeymap(r)
      result = cast[ptr set[0..255]](r.addr)[]

    let keys = queryKeyboardState().mapit(xkeyToKey display.XKeycodeToKeysym(it.char, 0))
    for k in keys: # press pressed in system keys
      if k == Key.unknown: continue
      window.keyboard.pressed.incl k
      window.eventsHandler.pushEvent onKey, KeyEvent(window: window, pressed: false, repeated: false)
    
    # todo: press pressed in system mouse buttons


  var prevEventIsKeyUpRepeated = false
  proc handleEvent(ev: var XEvent, nextEv: var XEvent, hasNextEvent: bool) =
    prevEventIsKeyUpRepeated = false

    case ev.theType
    of Expose:
      ##
    
    of ClientMessage:
      if ev.xclient.data.l[0] == atoms.wmDeleteWindow.clong:
        close window

      elif ev.xclient.data.l[0] == atoms.netWmSyncRequest.clong:
        window.lastSync = XSyncValue(
          lo: cast[uint32](ev.xclient.data.l[2]),
          hi: cast[int32](ev.xclient.data.l[3])
        )
        window.syncState = SyncState.syncRecieved
        window.redrawRequested = false  # hold on, wait for ConfigureNotify

    of ConfigureNotify:
      if ev.xconfigure.width != window.m_size.x or ev.xconfigure.height != window.m_size.y:
        window.m_size = ivec2(ev.xconfigure.width.int32, ev.xconfigure.height.int32)
        window.eventsHandler.pushEvent onResize, ResizeEvent(window: window, size: window.m_size, initial: false)
      if ev.xconfigure.x.int != window.m_pos.x or ev.xconfigure.y.int != window.m_pos.y:
        window.m_pos = ivec2(ev.xconfigure.x.int32, ev.xconfigure.y.int32)
        window.mouse.pos = cursor().pos - window.m_pos
        window.eventsHandler.pushEvent onWindowMove, WindowMoveEvent(window: window, pos: window.m_pos)

      let state = (let (kind, data) = window.handle.property(atoms.netWmState, Atom); if kind == XaAtom: data else: @[])
      if atoms.netWmStateFullscreen in state != window.m_fullscreen:
        window.m_fullscreen = not window.m_fullscreen
        window.eventsHandler.pushEvent onFullscreenChanged, FullscreenChangedEvent(window: window, fullscreen: window.m_fullscreen)
      
      if window.syncState == SyncState.syncRecieved:
        window.syncState = SyncState.syncAndConfigureRecieved

      window.redrawRequested = true

    of MotionNotify:
      window.mouse.pos = ivec2(ev.xmotion.x.int32, ev.xmotion.y.int32)
      window.clicking = {}
      window.eventsHandler.pushEvent onMouseMove, MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.move)

    of ButtonPress:
      if not isScroll:
        let nows = getTime()
        window.mouse.pressed.incl button
        window.clicking.incl button

        if (nows - window.lastClickTime).inMilliseconds < 200:
          window.eventsHandler.pushEvent onClick, ClickEvent(
            window: window, button: button, pos: window.mouse.pos, double: true
          )
          window.doubleClickHandled = true
        else:
          window.doubleClickHandled = false
        
        window.eventsHandler.pushEvent onMouseButton, MouseButtonEvent(window: window, button: button, pressed: true)
      elif scrollDeltaX != 0 or scrollDeltaY != 0:
        window.eventsHandler.pushEvent onScroll, ScrollEvent(window: window, delta: scrollDeltaY, deltaX: scrollDeltaX)

    of ButtonRelease:
      if not isScroll:
        let nows = getTime()
        window.mouse.pressed.excl button

        if button in window.clicking:
          if not window.doubleClickHandled:
            window.eventsHandler.pushEvent onClick, ClickEvent(
              window: window, button: button, pos: window.mouse.pos, double: false
            )
            window.lastClickTime = nows
          window.clicking.excl button

        window.eventsHandler.pushEvent onMouseButton, MouseButtonEvent(window: window, button: button, pressed: false)

    of LeaveNotify:
      window.clicking = {}
      window.eventsHandler.pushEvent onMouseMove, MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.leave)
    of EnterNotify:
      window.clicking = {}
      window.eventsHandler.pushEvent onMouseMove, MouseMoveEvent(window: window, pos: window.mouse.pos, kind: MouseMoveKind.enter)

    of FocusIn:
      window.m_focused = true
      if window.xinContext != nil: XSetICFocus window.xinContext
      window.eventsHandler.pushEvent onFocusChanged, FocusChangedEvent(window: window, focus: true)
      window.pressAllKeys()

    of FocusOut:
      window.m_focused = false
      if window.xinContext != nil: XUnsetICFocus window.xinContext
      window.eventsHandler.pushEvent onFocusChanged, FocusChangedEvent(window: window, focus: false)
      window.releaseAllKeys()

    of KeyPress:
      var key = ev.xkey.extractKey
      if key != Key.unknown:
        window.keyboard.pressed.incl key
        window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: key, pressed: true, repeated: prevEventIsKeyUpRepeated)

      if window.eventsHandler.onTextInput != nil and window.xinContext != nil and (window.keyboard.pressed * {lcontrol, rcontrol, lalt, ralt}).len == 0:
        var status: Status
        var buffer: array[16, char]
        let length = window.xinContext.Xutf8LookupString(ev.xkey.addr, cast[cstring](buffer.addr), buffer.sizeof.cint, nil, status.addr)

        proc toString(str: openArray[char]): string =
          result = newStringOfCap(len(str))
          for ch in str:
            result.add ch

        if length > 0:
          let s = buffer[0..<length].toString()
          if s notin ["\u001B"]:
            window.eventsHandler.onTextInput TextInputEvent(window: window, text: s)

    of KeyRelease:
      var key = ev.xkey.extractKey
      if key != Key.unknown:
        let repeated = hasNextEvent and nextEv.theType == KeyPress and nextEv.xkey.extractKey == key
        if repeated: prevEventIsKeyUpRepeated = true

        window.keyboard.pressed.excl key
        window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: key, pressed: false, repeated: repeated)

    else: discard


  block nextEvent:
    template closeAndExit =
      window.eventsHandler.pushEvent onClose, CloseEvent(window: window)
      return
    
    var
      ev: XEvent
      nextEv: XEvent
      catched = false

    proc checkEvent(_: PDisplay, event: PXEvent, userData: XPointer): XBool {.cdecl.} =
      if cast[int](event.xany.window) == cast[int](userData): 1 else: 0
    
    while display.XCheckIfEvent(nextEv.addr, checkEvent, cast[XPointer](window.handle)) == 1:
      if not catched:
        ev = nextEv
        catched = true
        continue
      
      handleEvent(ev, nextEv, true)
      ev = nextEv
    
      if window.closed: closeAndExit()

      # force make tick if server decided to spam events to us
      if (getTime() - window.lastTickTime) > initDuration(milliseconds=10):
        break

      discard XFlush display

    if catched:
      handleEvent(ev, nextEv, false)

    if window.closed: closeAndExit()
    if not catched: sleep(1)


  let nows = getTime()
  window.eventsHandler.pushEvent onTick, TickEvent(window: window, deltaTime: nows - window.lastTickTime)
  window.lastTickTime = nows

  if window.redrawRequested:
    window.redrawRequested = false
    window.eventsHandler.pushEvent onRender, RenderEvent(window: window)

    window.beginSwapBuffers()

    if window.syncState == SyncState.syncAndConfigureRecieved:
      display.XSyncSetCounter(window.xSyncCounter, window.lastSync)
      window.syncState = SyncState.none

    window.endSwapBuffers()

    discard XFlush display

  for _, f in clipboardProcessEvents: f()


proc newSoftwareRenderingWindowX11*(
  size = ivec2(1280, 720),
  title = "",
  screen = defaultScreenX11(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,

  class = "", # window class (used in x11), equals to title if not specified
): WindowX11SoftwareRendering =
  new result
  result.initSoftwareRenderingWindow(size, screen, fullscreen, frameless, transparent, (if class == "": title else: class))
  result.title = title
  if not resizable: result.resizable = false
