import std/[importutils, tables, times, os, unicode, uri, sequtils, strutils]
import pkg/[vmath]
from pkg/darwin/quartz_core/calayer import CALayer
from pkg/darwin/quartz_core/cametal_layer import CAMetalLayer
from pkg/darwin/objc/runtime import ObjcClass, ID, SEL, alloc, new, addClass, selector, callSuper
import ../../[siwindefs]
import ../../[colorutils]
import ../any/[window {.all.}, clipboards]
import ./[modifierstate, extras]

{.passL: "-framework Cocoa".}

privateAccess Window

template autoreleasepool(body: untyped) =
  let pool = NSAutoreleasePool.alloc().init()
  try:
    body
  finally:
    pool.release()

type
  ScreenCocoa* = ref object of Screen
    id: int32
    handle: NSScreen

  WindowCocoa* = ref WindowCocoaObj
  WindowCocoaObj* = object of Window
    handle: NsWindow
    trackingArea: NSTrackingArea
    markedText: NSString
    lastClickTime: array[MouseButton, Time]
    lastDragStatus: DragStatus
  
  WindowCocoaSoftwareRendering* = ref object of WindowCocoa

  WindowCocoaOpengl* = ref object of WindowCocoa
    openglView: NSOpenGLView

  WindowCocoaMetal* = ref object of WindowCocoa
    metalView: NSView

  ClipboardCocoa* = ref object of Clipboard

  ClipboardCocoaDnd* = ref object of Clipboard
    activePasteboard: NSPasteboard


var
  initialized: bool
  appDelegateClass, windowClass, openglViewClass, metalViewClass: ObjcClass
  windows: seq[WindowCocoa]
proc init


proc `=destroy`(window: WindowCocoaObj) {.siwin_destructor.} =
  if window.addr[].m_closed:
    return

  window.addr[].m_closed = true

  let handle = window.handle
  window.addr[].handle = nil

  if windows.len > 0:
    var i = 0
    while i < windows.len:
      let w = windows[i]
      if w == nil or w.handle == nil or cast[ID](w.handle) == cast[ID](handle):
        windows.del i
      else:
        inc i

  if handle != nil:
    try:
      close handle
    except:
      discard


proc findWindow(windows: seq[WindowCocoa], window: Id): WindowCocoa =
  for w in windows:
    if w != nil and w.handle != nil and cast[ID](w.handle) == window:
      return w


proc keycodeToKey(code: uint16): Key =
  case code
  of 0x1d: Key.n0
  of 0x12: Key.n1
  of 0x13: Key.n2
  of 0x14: Key.n3
  of 0x15: Key.n4
  of 0x17: Key.n5
  of 0x16: Key.n6
  of 0x1a: Key.n7
  of 0x1c: Key.n8
  of 0x19: Key.n9
  of 0x00: Key.a
  of 0x0b: Key.b
  of 0x08: Key.c
  of 0x02: Key.d
  of 0x0e: Key.e
  of 0x03: Key.f
  of 0x05: Key.g
  of 0x04: Key.h
  of 0x22: Key.i
  of 0x26: Key.j
  of 0x28: Key.k
  of 0x25: Key.l
  of 0x2e: Key.m
  of 0x2d: Key.n
  of 0x1f: Key.o
  of 0x23: Key.p
  of 0x0c: Key.q
  of 0x0f: Key.r
  of 0x01: Key.s
  of 0x11: Key.t
  of 0x20: Key.u
  of 0x09: Key.v
  of 0x0d: Key.w
  of 0x07: Key.x
  of 0x10: Key.y
  of 0x06: Key.z
  of 0x32: Key.tilde
  of 0x1b: Key.minus
  of 0x18: Key.equal
  of 0x33: Key.backspace
  of 0x30: Key.tab
  of 0x21: Key.lbracket
  of 0x1e: Key.rbracket
  of 0x2a: Key.backslash
  of 0x39: Key.capsLock
  of 0x29: Key.semicolon
  of 0x27: Key.quote
  of 0x24: Key.enter
  of 0x38: Key.lshift
  of 0x2b: Key.comma
  of 0x2f: Key.dot
  of 0x2c: Key.slash
  of 0x3c: Key.rshift
  of 0x3b: Key.lcontrol
  of 0x37: Key.lsystem
  of 0x3a: Key.lalt
  of 0x31: Key.space
  of 0x3d: Key.ralt
  of 0x36: Key.rsystem
  of 0x6e: Key.menu
  of 0x3e: Key.rcontrol
  of 0x75: Key.del
  of 0x73: Key.home
  of 0x77: Key.End
  of 0x72: Key.insert
  of 0x74: Key.pageUp
  of 0x79: Key.pageDown
  of 0x35: Key.escape
  of 0x7e: Key.up
  of 0x7d: Key.down
  of 0x7b: Key.left
  of 0x7c: Key.right
  of 0x7a: Key.f1
  of 0x78: Key.f2
  of 0x63: Key.f3
  of 0x76: Key.f4
  of 0x60: Key.f5
  of 0x61: Key.f6
  of 0x62: Key.f7
  of 0x64: Key.f8
  of 0x65: Key.f9
  of 0x6d: Key.f10
  of 0x67: Key.f11
  of 0x6f: Key.f12
  of 0x47: Key.numLock
  of 0x52: Key.npad0
  of 0x53: Key.npad1
  of 0x54: Key.npad2
  of 0x55: Key.npad3
  of 0x56: Key.npad4
  of 0x57: Key.npad5
  of 0x58: Key.npad6
  of 0x59: Key.npad7
  of 0x5b: Key.npad8
  of 0x5c: Key.npad9
  of 0x41: Key.npadDot
  of 0x4c: Key.enter
  of 0x45: Key.add
  of 0x4e: Key.subtract
  of 0x43: Key.multiply
  of 0x4b: Key.divide
  of 0x51: Key.equal
  else: Key.unknown

proc modifierSet(flags: NSEventModifierFlags): set[ModifierKey] =
  let bitset = cast[uint64](flags)
  if (bitset and cast[uint64](NSEventModifierFlagShift)) != 0:
    result.incl ModifierKey.shift
  if (bitset and cast[uint64](NSEventModifierFlagControl)) != 0:
    result.incl ModifierKey.control
  if (bitset and cast[uint64](NSEventModifierFlagOption)) != 0:
    result.incl ModifierKey.alt
  if (bitset and cast[uint64](NSEventModifierFlagCommand)) != 0:
    result.incl ModifierKey.system
  if (bitset and cast[uint64](NSEventModifierFlagCapsLock)) != 0:
    result.incl ModifierKey.capsLock
  if (bitset and cast[uint64](NSEventModifierFlagNumericPad)) != 0:
    result.incl ModifierKey.numLock

proc updateModifiers(window: WindowCocoa, event: NSEvent): set[ModifierKey] =
  let eventModifiers = modifierSet(event.modifierFlags)
  if tryCurrentModifierState(result):
    # CGEvent flags are more reliable for modifier keys while key chords are active.
    if ModifierKey.capsLock in eventModifiers:
      result.incl ModifierKey.capsLock
    if ModifierKey.numLock in eventModifiers:
      result.incl ModifierKey.numLock
  else:
    result = eventModifiers
  window.keyboard.modifiers = result

proc refreshModifiers(window: WindowCocoa) =
  if not window.m_focused:
    return
  var modifiers: set[ModifierKey]
  if tryCurrentModifierState(modifiers):
    if ModifierKey.capsLock in window.keyboard.modifiers:
      modifiers.incl ModifierKey.capsLock
    if ModifierKey.numLock in window.keyboard.modifiers:
      modifiers.incl ModifierKey.numLock
    window.keyboard.modifiers = modifiers

proc releaseAllInput(window: WindowCocoa) =
  for key in window.keyboard.pressed:
    window.keyboard.pressed.excl key
    if window.eventsHandler.onKey != nil:
      window.eventsHandler.onKey(KeyEvent(
        window: window,
        key: key,
        pressed: false,
        repeated: false,
        generated: true,
        modifiers: window.keyboard.modifiers,
      ))

  for button in window.mouse.pressed:
    window.mouse.pressed.excl button
    window.clicking.excl button
    if window.eventsHandler.onMouseButton != nil:
      window.eventsHandler.onMouseButton(MouseButtonEvent(
        window: window,
        button: button,
        pressed: false,
        generated: true,
      ))

const
  CocoaMimeTextUriList = "text/uri-list"
  CocoaMimePublicFileUrl = "public.file-url"
  CocoaMimeLegacyFileNames = "NSFilenamesPboardType"

proc pushUnique(values: var seq[string], value: string) =
  if value.len > 0 and value notin values:
    values.add value

proc nsDataToString(data: NSData): string =
  if data == nil:
    return ""

  let n = data.len
  if n <= 0:
    return ""

  result = newString(n)
  data.getBytes(result[0].addr, n)

proc stringToNSData(data: string): NSData =
  if data.len <= 0:
    return NSData.emptyData()

  var bytes = newSeq[byte](data.len)
  copyMem(bytes[0].addr, data[0].unsafeAddr, data.len)
  NSData.withBytes(bytes)

proc emptyClipboardContent(kind: ClipboardContentKind, mimeType: string): ClipboardContent =
  if kind == ClipboardContentKind.other:
    ClipboardContent(kind: ClipboardContentKind.other, mimeType: mimeType)
  else:
    ClipboardContent(kind: kind)

proc constructClipboardContent(
  data: sink string, kind: ClipboardContentKind, mimeType: string
): ClipboardContent =
  case kind
  of ClipboardContentKind.text:
    ClipboardContent(kind: ClipboardContentKind.text, text: data)

  of ClipboardContentKind.files:
    let uris = data.splitLines
    var files: seq[string]
    for uri in uris:
      let uri = uri.strip()
      if uri.len == 0 or uri.startsWith("#"):
        continue

      let parsed = parseUri(uri)
      if parsed.scheme == "file":
        files.add parsed.path.decodeUrl
      elif parsed.scheme.len == 0 and parsed.path.len > 0:
        files.add parsed.path

    ClipboardContent(kind: ClipboardContentKind.files, files: files)

  of ClipboardContentKind.other:
    ClipboardContent(kind: ClipboardContentKind.other, mimeType: mimeType, data: data)

proc pasteboardMimeTypes(pasteboard: NSPasteboard): seq[string] =
  if pasteboard == nil:
    return

  let items = pasteboard.pasteboardItems()
  if items == nil:
    return

  for item in items:
    if item == nil:
      continue
    let types = item.types()
    if types == nil:
      continue
    for mimeType in types:
      result.pushUnique($mimeType)

proc inferAvailableKinds(mimeTypes: openArray[string]): set[ClipboardContentKind] =
  if mimeTypes.len > 0:
    result.incl ClipboardContentKind.other

  for mimeType in mimeTypes:
    if mimeType in [
      "public.utf8-plain-text",
      "public.plain-text",
      "text/plain",
      "text/plain;charset=utf-8",
      "STRING",
      "TEXT",
      "NSStringPboardType",
    ]:
      result.incl ClipboardContentKind.text

    if mimeType in [CocoaMimeTextUriList, CocoaMimePublicFileUrl, CocoaMimeLegacyFileNames]:
      result.incl ClipboardContentKind.files

  if NSPasteboardTypeString != nil and $NSPasteboardTypeString in mimeTypes:
    result.incl ClipboardContentKind.text

proc refreshClipboardAvailability(clipboard: Clipboard, pasteboard: NSPasteboard) =
  if clipboard == nil:
    return

  clipboard.availableMimeTypes = pasteboard.pasteboardMimeTypes()
  clipboard.availableKinds = inferAvailableKinds(clipboard.availableMimeTypes)

proc dataStringsForMimeType(pasteboard: NSPasteboard, mimeType: string): seq[string] =
  if pasteboard == nil or mimeType.len == 0:
    return

  let mimeTypeNs = @mimeType
  let items = pasteboard.pasteboardItems()
  if items != nil:
    for item in items:
      if item == nil:
        continue
      let data = item.dataForType(mimeTypeNs)
      if data != nil:
        result.add nsDataToString(data)

  if result.len == 0:
    let data = pasteboard.dataForType(mimeTypeNs)
    if data != nil:
      result.add nsDataToString(data)

proc bestMimeType(
  availableMimeTypes: openArray[string], kind: ClipboardContentKind, mimeType: string
): string =
  case kind
  of ClipboardContentKind.text:
    let nativeType =
      if NSPasteboardTypeString != nil: $NSPasteboardTypeString
      else: "public.utf8-plain-text"
    for candidate in [
      nativeType,
      "public.utf8-plain-text",
      "public.plain-text",
      "text/plain;charset=utf-8",
      "text/plain",
      "STRING",
      "TEXT",
      "NSStringPboardType",
    ]:
      if candidate in availableMimeTypes:
        return candidate

  of ClipboardContentKind.files:
    for candidate in [CocoaMimeTextUriList, CocoaMimePublicFileUrl, CocoaMimeLegacyFileNames]:
      if candidate in availableMimeTypes:
        return candidate

  of ClipboardContentKind.other:
    if mimeType in availableMimeTypes:
      return mimeType

proc updateDragClipboard(clipboard: ClipboardCocoaDnd, pasteboard: NSPasteboard): bool =
  let
    prevKinds = clipboard.availableKinds
    prevMimeTypes = clipboard.availableMimeTypes

  clipboard.activePasteboard = pasteboard
  clipboard.refreshClipboardAvailability(pasteboard)
  clipboard.availableKinds != prevKinds or clipboard.availableMimeTypes != prevMimeTypes

proc clearDragClipboard(clipboard: ClipboardCocoaDnd): bool =
  result = clipboard.availableKinds != {} or clipboard.availableMimeTypes.len > 0
  clipboard.activePasteboard = nil
  clipboard.availableKinds = {}
  clipboard.availableMimeTypes = @[]

proc notifyDragClipboardChanged(window: WindowCocoa) =
  let clipboard = window.m_dragndropClipboard
  if clipboard.onContentChanged != nil:
    clipboard.onContentChanged(ClipboardContentChangedEvent(
      clipboard: clipboard,
      availableKinds: clipboard.availableKinds,
      availableMimeTypes: clipboard.availableMimeTypes,
    ))

proc updateDragClipboard(window: WindowCocoa, pasteboard: NSPasteboard) =
  let clipboard = window.m_dragndropClipboard.ClipboardCocoaDnd
  if clipboard.updateDragClipboard(pasteboard):
    window.notifyDragClipboardChanged()

proc clearDragClipboard(window: WindowCocoa) =
  let clipboard = window.m_dragndropClipboard.ClipboardCocoaDnd
  if clipboard.clearDragClipboard():
    window.notifyDragClipboardChanged()

proc dragOperation(status: DragStatus): NSDragOperation =
  if status == DragStatus.accepted:
    NSDragOperationCopy
  else:
    NSDragOperationNone


proc screenCountCocoa*(): int32 =
  let screens = NSScreen.screens()
  if screens == nil:
    return 0
  screens.len.int32

proc defaultScreenCocoa*(): ScreenCocoa =
  let
    screens = NSScreen.screens()
    mainScreen = mainScreen()

  if screens != nil and screens.len > 0:
    new result
    if mainScreen != nil:
      for i in 0..<screens.len:
        let screen = screens[i]
        if screen == mainScreen:
          result.id = i.int32
          result.handle = screen
          return
      result.id = 0
      result.handle = mainScreen
      return
    result.id = 0
    result.handle = screens[0]
    return

  new result
  result.id = 0
  result.handle = mainScreen

proc screenCocoa*(number: int32): ScreenCocoa =
  let screens = NSScreen.screens()
  if screens == nil or screens.len == 0:
    return defaultScreenCocoa()

  if number in 0..<screens.len.int32:
    new result
    result.id = number
    result.handle = screens[number.int]
    return

  defaultScreenCocoa()

method number*(screen: ScreenCocoa): int32 = screen.id

method width*(screen: ScreenCocoa): int32 =
  if screen == nil or screen.handle == nil:
    return 0
  let frame = screen.handle.frame
  (frame.size.width * screen.handle.scaleFactor).int32

method height*(screen: ScreenCocoa): int32 =
  if screen == nil or screen.handle == nil:
    return 0
  let frame = screen.handle.frame
  (frame.size.height * screen.handle.scaleFactor).int32

method destruct(window: WindowCocoa) {.base.} =
  `=destroy` window[]


template pushEvent(eventsHandler: WindowEventsHandler, event, args) =
  if eventsHandler.event != nil:
    eventsHandler.event(args)


proc initWindowCocoa(
  window: WindowCocoa,
  size: IVec2, screen: ScreenCocoa,
  fullscreen, frameless, transparent: bool
) =
  init()

  window.m_size = size
  window.m_frameless = frameless

  var x = 0.0
  var y = 0.0
  if screen != nil and screen.handle != nil:
    let frame = screen.handle.frame
    x = frame.origin.x + (frame.size.width - size.x.float64) / 2
    y = frame.origin.y + (frame.size.height - size.y.float64) / 2

  window.handle = cast[NSWindow](windowClass.alloc()).initWithContentRect(
    NsMakeRect(x, y, size.x.float64, size.y.float64),
    (
      if frameless: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskResizable or NSWindowStyleMaskBorderless
      else: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskResizable or NSWindowStyleMaskTitled or NSWindowStyleMaskClosable
    ),
    NsBackingStoreBuffered,
    false
  )
  windows.add window

  window.m_clipboard = ClipboardCocoa(
    availableKinds: {ClipboardContentKind.text},
    availableMimeTypes: @[]
  )
  window.m_selectionClipboard = window.m_clipboard
  window.m_dragndropClipboard = ClipboardCocoaDnd(availableKinds: {}, availableMimeTypes: @[])


proc initWindowCocoaOpengl*(
  window: WindowCocoaOpengl,
  size: IVec2, screen: ScreenCocoa,
  fullscreen, frameless, transparent: bool,
  vsync: bool, msaa: int32,
) =
  initWindowCocoa(window, size, screen, fullscreen, frameless, transparent)
  let
    pixelFormatAttribs = [
      NSOpenGLPFADoubleBuffer,
      NSOpenGLPFASampleBuffers, if msaa != 0: 1 else: 0,
      NSOpenGLPFASamples, msaa.uint32,
      NSOpenGLPFAAccelerated,
      NSOpenGLPFADoubleBuffer,
      NSOpenGLPFAColorSize, 32,
      NSOpenGLPFAAlphaSize, 8,
      NSOpenGLPFADepthSize, 24,
      NSOpenGLPFAStencilSize, 8,
      NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion4_1Core,
      0
    ]
    pixelFormat = NSOpenGLPixelFormat.alloc().initWithAttributes(
      pixelFormatAttribs[0].unsafeAddr
    )

  window.openglView = cast[NSOpenGLView](openglViewClass.alloc()).initWithFrame(
    window.handle.contentView.frame,
    pixelFormat
  )
  window.openglView.setWantsBestResolutionOpenGLSurface(true)

  window.openglView.openGLContext.makeCurrentContext()

  var swapInterval: int32 = if vsync: 1 else: 0
  window.openglView.openGLContext.setValues(
    swapInterval.addr,
    NSOpenGLContextParameterSwapInterval
  )

  var opaque: int32 = if transparent: 0 else: 1
  window.openglView.openGLContext.setValues(
    opaque.addr,
    NSOpenGLContextParameterSurfaceOpacity
  )

  window.handle.setDelegate(cast[NSObject](window.handle))
  window.handle.setContentView(cast[NSView](window.openglView))
  discard window.handle.makeFirstResponder(cast[NSView](window.openglView))
  discard cast[NSView](window.openglView).registerForDraggedTypes(
    arrayWithObjects[NSString](NSPasteboardTypeString, @"text/uri-list", @"public.file-url")
  )
  window.handle.setRestorable(false)

proc initWindowCocoaMetal*(
  window: WindowCocoaMetal,
  size: IVec2, screen: ScreenCocoa,
  fullscreen, frameless, transparent: bool,
) =
  initWindowCocoa(window, size, screen, fullscreen, frameless, transparent)
  window.metalView = cast[NSView](metalViewClass.alloc()).initWithFrame(
    window.handle.contentView.frame
  )
  window.metalView.setWantsLayer(true)
  let metalLayer = CAMetalLayer.alloc().init()
  window.metalView.setLayer(cast[CALayer](metalLayer))
  metalLayer.release()

  window.handle.setDelegate(cast[NSObject](window.handle))
  window.handle.setContentView(window.metalView)
  discard window.handle.makeFirstResponder(window.metalView)
  discard window.metalView.registerForDraggedTypes(
    arrayWithObjects[NSString](NSPasteboardTypeString, @"text/uri-list", @"public.file-url")
  )
  window.handle.setRestorable(false)


method `frameless=`*(window: WindowCocoa, v: bool) =
  if window.m_frameless == v: return
  window.m_frameless = v
  window.handle.setStyleMask(
    if v:
      if window.m_resizable: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskResizable or NSWindowStyleMaskBorderless
      else: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskBorderless
    else:
      if window.m_resizable: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskResizable or NSWindowStyleMaskTitled or NSWindowStyleMaskClosable
      else: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskTitled or NSWindowStyleMaskClosable
  )


method `title=`*(window: WindowCocoa, title: string) =
  autoreleasepool:
    window.handle.setTitle(@title)


method `cursor=`*(window: WindowCocoa, cursor: Cursor) =
  if window.m_cursor.kind == builtin and cursor.kind == builtin and window.m_cursor.builtin == cursor.builtin: return
  window.m_cursor = cursor


method `visible=`*(window: WindowCocoa, v: bool) =
  if window.m_visible == v:
    return
  window.m_visible = v
  autoreleasepool:
    if v:
      window.handle.orderFront(cast[ID](nil))
    else:
      window.handle.orderOut(cast[ID](nil))

method close*(window: WindowCocoa) =
  if window.m_closed:
    return
  `=destroy` window[]

method `size=`*(window: WindowCocoa, v: IVec2) =
  if v.x <= 0 or v.y <= 0:
    raise RangeDefect.newException("size must be > 0")

  if window.fullscreen:
    window.fullscreen = false

  let frame = window.handle.frame
  let contentRect = window.handle.contentRectForFrameRect(frame)
  let borderW = frame.size.width - contentRect.size.width
  let borderH = frame.size.height - contentRect.size.height
  window.handle.setFrame(
    NSMakeRect(
      frame.origin.x,
      frame.origin.y,
      v.x.float64 + borderW,
      v.y.float64 + borderH
    ),
    true
  )

method `pos=`*(window: WindowCocoa, v: IVec2) =
  if window.m_pos == v:
    return
  window.m_pos = v
  if window.fullscreen:
    return

  let frame = window.handle.frame
  var y = frame.origin.y
  let screen = window.handle.screen
  if screen != nil:
    let screenFrame = screen.frame
    y = screenFrame.size.height - v.y.float64 - frame.size.height - 1

  window.handle.setFrame(
    NSMakeRect(v.x.float64, y, frame.size.width, frame.size.height),
    true
  )

method `fullscreen=`*(window: WindowCocoa, v: bool) =
  if window.m_fullscreen == v:
    return
  window.m_fullscreen = v

  if v and window.m_maximized:
    window.m_maximized = false
    window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
      window: window, kind: StateBoolChangedEventKind.maximized, value: false
    )

  window.handle.toggleFullScreen(cast[ID](nil))
  window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
    window: window, kind: StateBoolChangedEventKind.fullscreen, value: v
  )

method `maximized=`*(window: WindowCocoa, v: bool) =
  if window.m_maximized == v:
    return
  if window.fullscreen:
    window.fullscreen = false
  window.m_maximized = v

  if window.handle.isZoomed().bool != v:
    window.handle.zoom(cast[ID](nil))

  window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
    window: window, kind: StateBoolChangedEventKind.maximized, value: v
  )

method `minimized=`*(window: WindowCocoa, v: bool) =
  if window.m_minimized == v:
    return
  window.m_minimized = v
  if v:
    window.releaseAllInput()
    window.handle.miniaturize(cast[ID](nil))
  else:
    window.handle.deminiaturize(cast[ID](nil))

method `resizable=`*(window: WindowCocoa, v: bool) =
  if window.m_resizable == v:
    return
  window.m_resizable = v
  window.handle.setStyleMask(
    if window.m_frameless:
      if v: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskResizable or NSWindowStyleMaskBorderless
      else: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskBorderless
    else:
      if v: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskResizable or NSWindowStyleMaskTitled or NSWindowStyleMaskClosable
      else: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskTitled or NSWindowStyleMaskClosable
  )

method `minSize=`*(window: WindowCocoa, v: IVec2) =
  if v.x <= 0 or v.y <= 0:
    window.m_minSize = ivec2()
    window.handle.setMinSize(NSMakeSize(0, 0))
  else:
    window.m_minSize = v
    window.handle.setMinSize(NSMakeSize(v.x.float64, v.y.float64))

method `maxSize=`*(window: WindowCocoa, v: IVec2) =
  if v.x <= 0 or v.y <= 0:
    window.m_maxSize = ivec2()
    window.handle.setMaxSize(NSMakeSize(1_000_000, 1_000_000))
  else:
    window.m_maxSize = v
    window.handle.setMaxSize(NSMakeSize(v.x.float64, v.y.float64))

method `icon=`*(window: WindowCocoa, _: nil.typeof) =
  NSApplication.setApplicationIconImage(nil)

method `icon=`*(window: WindowCocoa, v: PixelBuffer) =
  if v.size.x * v.size.y == 0:
    window.icon = nil
    return

  let sourceFormat = v.format
  var buffer = v
  convertPixelsInplace(buffer.data, buffer.size, sourceFormat, PixelBufferFormat.rgba_32bit)

  let rep = NSBitmapImageRep.alloc().initWithBitmapDataPlanes(
    nil,
    buffer.size.x.int,
    buffer.size.y.int,
    8,
    4,
    true,
    false,
    @"NSCalibratedRGBColorSpace",
    0,
    (buffer.size.x * 4).int,
    32
  )
  if rep != nil:
    copyMem(rep.bitmapData, buffer.data, buffer.size.x * buffer.size.y * 4)
    let img = NSImage.alloc().initWithSize(NSMakeSize(buffer.size.x.float64, buffer.size.y.float64))
    img.addRepresentation(cast[NSImageRep](rep))
    NSApplication.setApplicationIconImage(img)
    rep.release()
    img.release()

  convertPixelsInplace(buffer.data, buffer.size, PixelBufferFormat.rgba_32bit, sourceFormat)

method content*(
  clipboard: ClipboardCocoa, kind: ClipboardContentKind, mimeType: string
): ClipboardContent =
  autoreleasepool:
    let pasteboard = NSPasteboard.withName(NSPasteboardNameGeneral)
    clipboard.refreshClipboardAvailability(pasteboard)
    let targetType = bestMimeType(clipboard.availableMimeTypes, kind, mimeType)
    if targetType.len == 0:
      return emptyClipboardContent(kind, mimeType)

    let payloads = pasteboard.dataStringsForMimeType(targetType)
    if payloads.len == 0:
      return emptyClipboardContent(kind, targetType)

    case kind
    of ClipboardContentKind.text:
      return ClipboardContent(kind: ClipboardContentKind.text, text: payloads[0])
    of ClipboardContentKind.files:
      return constructClipboardContent(payloads.join("\n"), ClipboardContentKind.files, targetType)
    of ClipboardContentKind.other:
      return ClipboardContent(kind: ClipboardContentKind.other, mimeType: targetType, data: payloads[0])

method `content=`*(clipboard: ClipboardCocoa, content: ClipboardConvertableContent) =
  autoreleasepool:
    let pasteboard = NSPasteboard.withName(NSPasteboardNameGeneral)
    if pasteboard == nil:
      return

    let item = NSPasteboardItem.alloc().init()
    var
      availableKinds: set[ClipboardContentKind]
      availableMimeTypes: seq[string]

    for cv in content.converters:
      let converted = cv.f(content.data, cv.kind, cv.mimeType)
      var targetType = ""
      var serialized = ""

      case converted.kind
      of ClipboardContentKind.text:
        targetType =
          if NSPasteboardTypeString != nil: $NSPasteboardTypeString
          else: "public.utf8-plain-text"
        serialized = converted.text
      of ClipboardContentKind.files:
        targetType = CocoaMimeTextUriList
        serialized = converted.files.mapIt($Uri(scheme: "file", path: it.encodeUrl(usePlus = false))).join("\n")
      of ClipboardContentKind.other:
        targetType = converted.mimeType
        serialized = converted.data

      if targetType.len == 0:
        continue

      let data = stringToNSData(serialized)
      discard item.setDataForType(data, @targetType)
      availableKinds.incl converted.kind
      if converted.kind != ClipboardContentKind.other:
        availableKinds.incl ClipboardContentKind.other
      availableMimeTypes.pushUnique(targetType)

    if availableMimeTypes.len == 0:
      return

    pasteboard.clearContents()
    pasteboard.writeObjects(arrayWithObjects[NSPasteboardItem](item))
    clipboard.availableKinds = availableKinds
    clipboard.availableMimeTypes = availableMimeTypes

method content*(
  clipboard: ClipboardCocoaDnd, kind: ClipboardContentKind, mimeType: string
): ClipboardContent =
  let pasteboard = clipboard.activePasteboard
  if pasteboard == nil:
    return emptyClipboardContent(kind, mimeType)

  clipboard.refreshClipboardAvailability(pasteboard)
  let targetType = bestMimeType(clipboard.availableMimeTypes, kind, mimeType)
  if targetType.len == 0:
    return emptyClipboardContent(kind, mimeType)

  let payloads = pasteboard.dataStringsForMimeType(targetType)
  if payloads.len == 0:
    return emptyClipboardContent(kind, targetType)

  case kind
  of ClipboardContentKind.text:
    result = ClipboardContent(kind: ClipboardContentKind.text, text: payloads[0])
  of ClipboardContentKind.files:
    result = constructClipboardContent(payloads.join("\n"), ClipboardContentKind.files, targetType)
  of ClipboardContentKind.other:
    result = ClipboardContent(kind: ClipboardContentKind.other, mimeType: targetType, data: payloads[0])

method `dragStatus=`*(window: WindowCocoa, v: DragStatus) =
  window.lastDragStatus = v

method makeCurrent*(window: WindowCocoaOpengl) =
  window.openglView.openGLContext.makeCurrentContext()

method swapBuffers*(window: WindowCocoaOpengl) =
  window.openglView.openGLContext.flushBuffer()

method `vsync=`*(window: WindowCocoaOpengl, v: bool, silent = false) =
  var swapInterval: int32 = if v: 1 else: 0
  window.openglView.openGLContext.setValues(
    swapInterval.addr,
    NSOpenGLContextParameterSwapInterval
  )

proc nativeWindowHandle*(window: WindowCocoa): pointer =
  cast[pointer](window.handle)

proc nativeViewHandle*(window: WindowCocoa): pointer =
  cast[pointer](window.handle.contentView)

proc setContentViewLayer*(window: WindowCocoa, layerPtr: pointer) =
  let contentView = window.handle.contentView
  contentView.setWantsLayer(true)
  contentView.setLayer(cast[CALayer](layerPtr))


proc init =
  if initialized: return
  defer: initialized = true

  template getWindow(this: untyped) =
    let window {.inject.} = windows.findWindow(this)
    if window == nil: return
  
  proc updateSize(window: WindowCocoa) =
    let
      contentView = window.handle.contentView
      frame = contentView.frame
      backing = contentView.convertRectToBacking(frame)
      size = ivec2(backing.size.width.int32, backing.size.height.int32)
    if window.m_size != size:
      window.m_size = size
      window.eventsHandler.pushEvent onResize, ResizeEvent(window: window, size: window.m_size)
      window.redrawRequested = true
  

  proc updateMousePos(window: WindowCocoa, location: NsPoint, kind: MouseMoveKind) =
    window.mouse.pos = vec2(location.x.float32, (window.handle.contentView.bounds.size.height - location.y).float32)
    window.eventsHandler.pushEvent onMouseMove, MouseMoveEvent(window: window, pos: window.mouse.pos, kind: kind)

  proc handleMouseButton(window: WindowCocoa, button: MouseButton, pressed: bool) =
    if pressed:
      window.mouse.pressed.incl button
      window.clicking.incl button
    else:
      let nows = getTime()

      window.mouse.pressed.excl button
      if button in window.clicking:
        window.eventsHandler.pushEvent onClick, ClickEvent(
          window: window, button: button, pos: window.mouse.pos,
          double: (nows - window.lastClickTime[button]).inMilliseconds < 200
        )
        window.clicking.excl button
      
      window.lastClickTime[button] = nows

    window.eventsHandler.pushEvent onMouseButton, MouseButtonEvent(window: window, button: button, pressed: pressed)

  autoreleasepool:
    discard NSApplication.sharedApplication()

    addClass "SiwinAppDelegate", "NSObject", appDelegateClass:
      addMethod "applicationWillFinishLaunching:", proc(self: Id, cmd: Sel, notification: NsNotification): Id {.cdecl.} =
        let
          menuBar = NSMenu.alloc().init()
          appMenuItem = NSMenuItem.alloc().init()
        menuBar.addItem(appMenuItem)
        NSApp.setMainMenu(menuBar)

        let
          appMenu = NSMenu.alloc().init()
          processName = NSProcessInfo.processinfo.processName
          quitTitle = @("Quit " & $processName)
          quitMenuitem = NsMenuItem.alloc().initWithTitle(
            quitTitle,
            selector"terminate:",
            @"q"
          )
        appMenu.addItem(quitMenuItem)
        appMenuItem.setSubmenu(appMenu)

      addMethod "applicationDidFinishLaunching:", proc(self: Id, cmd: Sel, notification: NsNotification): Id {.cdecl.} =
        NSApp.setPresentationOptions(NSApplicationPresentationDefault)
        NSApp.setActivationPolicy(NSApplicationActivationPolicyRegular)
        NSApp.activate()


    addClass "SiwinWindow", "NSWindow", windowClass:
      addMethod "windowDidResize:", proc(self: Id, cmd: Sel, notification: NsNotification): Id {.cdecl.} =
        getWindow(self)
        updateSize window

      addMethod "windowDidMove:", proc(self: Id, cmd: Sel, notification: NsNotification): Id {.cdecl.} =
        getWindow(self)
        autoreleasepool:
          let
            windowFrame = window.handle.frame
            screenFrame = window.handle.screen.frame
          window.m_pos = vec2(
            windowFrame.origin.x,
            screenFrame.size.height - windowFrame.origin.y - windowFrame.size.height - 1
          ).ivec2
        window.eventsHandler.pushEvent onWindowMove, WindowMoveEvent(window: window, pos: window.m_pos)

      addMethod "canBecomeKeyWindow:", proc(self: Id, cmd: Sel, notification: NsNotification): bool {.cdecl.} =
        true

      addMethod "windowDidBecomeKey:", proc(self: Id, cmd: Sel, notification: NsNotification): Id {.cdecl.} =
        getWindow(self)
        window.m_focused = true
        window.refreshModifiers()
        window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
          window: window, value: true, kind: StateBoolChangedEventKind.focus
        )
        updateMousePos window, window.handle.mouseLocationOutsideOfEventStream, MouseMoveKind.enter

      addMethod "windowDidResignKey:", proc(self: Id, cmd: Sel, notification: NsNotification): Id {.cdecl.} =
        getWindow(self)
        updateMousePos window, window.handle.mouseLocationOutsideOfEventStream, MouseMoveKind.leave
        window.releaseAllInput()
        window.m_focused = false
        window.keyboard.modifiers = {}
        window.eventsHandler.pushEvent onStateBoolChanged, StateBoolChangedEvent(
          window: window, value: false, kind: StateBoolChangedEventKind.focus
        )

      addMethod "windowShouldClose:", proc(self: Id, cmd: Sel, notification: NsNotification): bool {.cdecl.} =
        getWindow(self)
        window.eventsHandler.pushEvent onClose, CloseEvent(window: window)
        destruct window
        true


    template addSiwinViewClass(className, superName: string, viewClassRef: untyped) =
      addClass className, superName, viewClassRef:
        addProtocol "NSTextInputClient"
        
        addMethod "acceptsFirstResponder", proc(self: Id, cmd: Sel): bool {.cdecl.} =
          true
        
        addMethod "canBecomeKeyView", proc(self: Id, cmd: Sel): bool {.cdecl.} =
          true
        
        addMethod "acceptsFirstMouse:", proc(self: Id, cmd: Sel, event: NsEvent): bool {.cdecl.} =
          true
        
        addMethod "viewDidChangeBackingProperties", proc(self: Id, cmd: Sel): Id {.cdecl.} =
          discard callSuper(cast[NSObject](self), cmd)
          getWindow(self)
          updateSize window
  
        addMethod "updateTrackingAreas", proc(self: Id, cmd: Sel): Id {.cdecl.} =
          getWindow(self)
  
          if window.trackingArea != nil:
            cast[NSView](self).removeTrackingArea(window.trackingArea)
            window.trackingArea.release()
            window.trackingArea = nil
  
          window.trackingArea = NSTrackingArea.alloc().initWithRect(
            NSMakeRect(0, 0, 0, 0),
            NSTrackingMouseEnteredAndExited or NSTrackingMouseMoved or NSTrackingActiveInKeyWindow or
            NSTrackingCursorUpdate or NSTrackingInVisibleRect or NSTrackingAssumeInside,
            self, cast[ID](nil)
          )
  
          cast[NSView](self).addTrackingArea(window.trackingArea)
  
          callSuper(cast[NSObject](self), cmd)
  
        addMethod "draggingEntered:", proc(
          self: Id, cmd: Sel, sender: NSDraggingInfo
        ): NSDragOperation {.cdecl.} =
          getWindow(self)
          if sender == nil:
            return NSDragOperationNone
  
          window.lastDragStatus = DragStatus.rejected
          window.updateDragClipboard(sender.draggingPasteboard)
          updateMousePos(window, sender.draggingLocation, MouseMoveKind.moveWhileDragging)
          dragOperation(window.lastDragStatus)
  
        addMethod "draggingUpdated:", proc(
          self: Id, cmd: Sel, sender: NSDraggingInfo
        ): NSDragOperation {.cdecl.} =
          getWindow(self)
          if sender == nil:
            return NSDragOperationNone
  
          window.updateDragClipboard(sender.draggingPasteboard)
          updateMousePos(window, sender.draggingLocation, MouseMoveKind.moveWhileDragging)
          dragOperation(window.lastDragStatus)
  
        addMethod "draggingExited:", proc(
          self: Id, cmd: Sel, sender: NSDraggingInfo
        ): Id {.cdecl.} =
          getWindow(self)
          window.clearDragClipboard()
          window.lastDragStatus = DragStatus.rejected
  
        addMethod "performDragOperation:", proc(
          self: Id, cmd: Sel, sender: NSDraggingInfo
        ): bool {.cdecl.} =
          getWindow(self)
          if sender != nil:
            window.updateDragClipboard(sender.draggingPasteboard)
          if window.eventsHandler.onDrop != nil:
            window.eventsHandler.onDrop(DropEvent(window: window))
          let accepted = window.lastDragStatus == DragStatus.accepted
          window.clearDragClipboard()
          window.lastDragStatus = DragStatus.rejected
          accepted
  
        addMethod "mouseMoved:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          getWindow(self)
          updateMousePos window, event.locationInWindow, MouseMoveKind.move
  
        addMethod "mouseDragged:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          getWindow(self)
          updateMousePos window, event.locationInWindow, MouseMoveKind.move
        
        addMethod "rightMouseDragged:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          getWindow(self)
          updateMousePos window, event.locationInWindow, MouseMoveKind.move
        
        addMethod "otherMouseDragged:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          getWindow(self)
          updateMousePos window, event.locationInWindow, MouseMoveKind.move
        
        addMethod "scrollWheel:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          getWindow(self)
          var
            deltaX = event.scrollingDeltaX
            deltaY = event.scrollingDeltaY
  
          if event.hasPreciseScrollingDeltas:
            deltaX *= 0.1
            deltaY *= 0.1
  
          if abs(deltaX) > 0 or abs(deltaY) > 0:
            window.eventsHandler.pushEvent onScroll, ScrollEvent(window: window, delta: deltaY, deltaX: deltaX)
  
        addMethod "mouseDown:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          getWindow(self)
          window.handleMouseButton(MouseButton.left, true)
  
        addMethod "mouseUp:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          getWindow(self)
          window.handleMouseButton(MouseButton.left, false)
  
        addMethod "rightMouseDown:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          getWindow(self)
          window.handleMouseButton(MouseButton.right, true)
  
        addMethod "rightMouseUp:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          getWindow(self)
          window.handleMouseButton(MouseButton.right, false)
  
        addMethod "otherMouseDown:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          getWindow(self)
          case event.buttonNumber
          of 2: window.handleMouseButton(MouseButton.middle, true)
          of 3: window.handleMouseButton(MouseButton.forward, true)
          of 4: window.handleMouseButton(MouseButton.backward, true)
          else: discard
          
        addMethod "otherMouseUp:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          getWindow(self)
          case event.buttonNumber
          of 2: window.handleMouseButton(MouseButton.middle, false)
          of 3: window.handleMouseButton(MouseButton.forward, false)
          of 4: window.handleMouseButton(MouseButton.backward, false)
          else: discard
  
        addMethod "keyDown:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          getWindow(self)
          let key = event.keyCode.keycodeToKey
          let modifiers = window.updateModifiers(event)
          if key != Key.unknown:
            window.keyboard.pressed.incl key
            window.eventsHandler.pushEvent onKey, KeyEvent(
              window: window,
              key: key,
              pressed: true,
              repeated: event.isARepeat.bool,
              modifiers: modifiers,
            )
            if window.eventsHandler.onTextInput != nil:
              discard cast[NSView](self).inputContext.handleEvent(event)
  
        addMethod "keyUp:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          getWindow(self)
          let key = event.keyCode.keycodeToKey
          let modifiers = window.updateModifiers(event)
          if key != Key.unknown:
            window.keyboard.pressed.excl key
            window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: key, pressed: false, repeated: false, modifiers: modifiers)  # todo: handle repeated
  
        addMethod "flagsChanged:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
          #? wtf is this?!?
          getWindow(self)
          let key = event.keyCode.keycodeToKey
          let modifiers = window.updateModifiers(event)
          if key != Key.unknown:
            if key in window.keyboard.pressed:
              window.keyboard.pressed.excl key
              window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: key, pressed: false, repeated: false, modifiers: modifiers)  # todo: handle repeated
            else:
              window.keyboard.pressed.incl key
              window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: key, pressed: true, repeated: false, modifiers: modifiers)  # todo: handle repeated
  
        addMethod "hasMarkedText", proc(self: Id, cmd: Sel): bool {.cdecl.} =
          getWindow(self)
          window.markedText != nil
        
        addMethod "markedRange", proc(self: Id, cmd: Sel): NsRange {.cdecl.} =
          getWindow(self)
          if window.markedText != nil:
            NSMakeRange(0, window.markedText.length)
          else:
            NSRangeEmpty
  
        addMethod "selectedRange", proc(self: Id, cmd: Sel): NsRange {.cdecl.} =
          getWindow(self)
          NSMakeRange(0, 0)
  
        addMethod "setMarkedText:selectedRange:replacementRange:", proc(
          self: Id, cmd: Sel, obj: Id, selectedRange: NsRange, replacementRange: NsRange
        ): Id {.cdecl.} =
          getWindow(self)
          var characters: NSString
          if cast[NSObject](obj).isKindOfClass(NSAttributedString):
            characters = $(cast[NSAttributedString](obj).toNSString())
          else:
            characters = cast[NSString](obj)
  
          if window.markedText != nil:
            window.markedText.release()
  
          window.markedText = NSString.stringWithString(characters).retain()
  
        addMethod "unmarkText", proc(self: Id, cmd: Sel): Id {.cdecl.} =
          discard
  
        addMethod "validAttributesForMarkedText", proc(self: Id, cmd: Sel): NSArrayAbstract {.cdecl.} =
          cast[NSArrayAbstract](nil)
  
        addMethod "attributedSubstringForProposedRange:actualRange:", proc(
          self: Id, cmd: Sel, range: NsRange, actualRange: NsRangePointer
        ): ID =
          discard
        
        addMethod "insertText:replacementRange:", proc(
          self: Id, cmd: Sel, obj: Id, replacementRange: NsRange
        ): Id {.cdecl.} =
          getWindow(self)
          var characters: NSString
          if cast[NSObject](obj).isKindOfClass(NSAttributedString):
            characters = $cast[NSAttributedString](obj).toNSString()
          else:
            characters = cast[NSString](obj)
  
          var range = NSMakeRange(0, characters.length.uint)
          while range.length > 0:
            var
              codepoint: uint32
              usedLength: uint
            discard characters.getBytes(
              codepoint.addr,
              sizeof(codepoint).uint,
              usedLength.addr,
              NSUTF32StringEncoding,
              0.NSStringEncodingConversionOptions,
              range,
              range.addr
            )
            if codepoint >= 0xf700 and codepoint <= 0xf7ff:
              continue
            window.eventsHandler.pushEvent onTextInput, TextInputEvent(window: window, text: $Rune(codepoint))
  
          if window.markedText != nil:
            window.markedText.release()
            window.markedText = nil
  
        addMethod "characterIndexForPoint:", proc(self: Id, cmd: Sel, point: NsPoint): uint {.cdecl.} =
          NSNotFound.uint
  
        addMethod "firstRectForCharacterRange:actualRange:", proc(
          self: Id, cmd: Sel, range: NsRange, actualRange: NsRangePointer
        ): NsRect {.cdecl.} =
          getWindow(self)
          let contentRect = window.handle.contentRectForFrameRect(window.handle.frame)
          NSMakeRect(
            contentRect.origin.x + 0,
            contentRect.origin.y + contentRect.size.height - 1 - 0,
            0,
            0
          )
  
        addMethod "doCommandBySelector:", proc(self: Id, cmd: Sel, selector: Sel): Id {.cdecl.} =
          discard
        
        addMethod "resetCursorRects", proc(self: Id, cmd: Sel): Id {.cdecl.} =
          getWindow(self)
          autoreleasepool:
            case window.m_cursor.kind:
            of builtin:
              discard
            else:
              ## todo
              # let
              #   encodedPng = cursor.image.encodePng()
              #   image = NSImage.alloc().initWithData(NSData.dataWithBytes(
              #     encodedPng[0].unsafeAddr,
              #     encodedPng.len
              #   ))
              #   hotspot = NSMakePoint(
              #     window.state.cursor.hotspot.x.float,
              #     window.state.cursor.hotspot.y.float
              #   )
              #   cursor = NSCursor.alloc().initWithImage(image, hotspot)
              # self.NSView.addCursorRect(self.NSView.bounds, cursor)

    addSiwinViewClass("SiwinViewOpenGL", "NSOpenGLView", openglViewClass)
    addSiwinViewClass("SiwinViewMetal", "NSView", metalViewClass)

    NSApp.setDelegate(cast[NSObject](appDelegateClass.new))
    NSApp.finishLaunching()


method firstStep*(window: WindowCocoa, makeVisible = true) =
  if makeVisible:
    window.visible = true


method step*(window: WindowCocoa) =
  proc pumpEvents(mode: NSRunLoopMode, firstUntilDate: NSDate): bool =
    var first = true
    while true:
      let event = NSApp.nextEventMatchingMask(
        NSEventMaskAny,
        (if first: firstUntilDate else: NSDate.distantPast),
        mode,
        true
      )
      if event == nil:
        break
      first = false
      result = true
      NSApp.sendEvent(event)

  let
    defaultMode = NSDefaultRunLoopMode
    trackingMode = cast[NSRunLoopMode](@"NSEventTrackingRunLoopMode")
    modalMode = cast[NSRunLoopMode](@"NSModalPanelRunLoopMode")

  autoreleasepool:
    # Wait briefly for regular events, then drain all immediate events including
    # tracking/live-resize and modal-panel modes.
    discard pumpEvents(defaultMode, NSDate.withTimeIntervalSinceNow(0.001))
    discard pumpEvents(defaultMode, NSDate.distantPast)
    discard pumpEvents(trackingMode, NSDate.distantPast)
    discard pumpEvents(modalMode, NSDate.distantPast)

  window.refreshModifiers()

  window.eventsHandler.pushEvent onTick, TickEvent(window: window)  # todo: lastTickTime
  
  if window.redrawRequested:
    window.redrawRequested = false
    window.eventsHandler.pushEvent onRender, RenderEvent(window: window)
    
    if window of WindowCocoaOpengl:
      window.WindowCocoaOpengl.swapBuffers()


proc newSoftwareRenderingWindowCocoa*(
  size = ivec2(1280, 720),
  title = "",
  screen = defaultScreenCocoa(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
): WindowCocoaSoftwareRendering =
  new result
  result.initWindowCocoa(size, screen, fullscreen, frameless, transparent)
  result.title = title
  if not resizable: result.resizable = false


proc newOpenglWindowCocoa*(
  size = ivec2(1280, 720),
  title = "",
  screen = defaultScreenCocoa(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
  vsync = false,
  msaa = 0'i32,
): WindowCocoaOpengl =
  new result
  result.initWindowCocoaOpengl(size, screen, fullscreen, frameless, transparent, vsync, msaa)
  result.title = title
  if not resizable: result.resizable = false

proc newMetalWindowCocoa*(
  size = ivec2(1280, 720),
  title = "",
  screen = defaultScreenCocoa(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
): WindowCocoaMetal =
  new result
  result.initWindowCocoaMetal(size, screen, fullscreen, frameless, transparent)
  result.title = title
  if not resizable: result.resizable = false
