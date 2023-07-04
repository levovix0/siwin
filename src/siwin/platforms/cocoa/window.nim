import std/[importutils, tables, times, os]
import pkg/[vmath]
import ../../utils, ../../bgrx
import ../any/window {.all.}, cocoa

{.experimental: "overloadableEnums".}

privateAccess Window

type
  ScreenCocoa* = object

  WindowCocoa* = ref WindowCocoaObj
  WindowCocoaObj* = object of Window
    handle: NsWindow
    trackingArea: NSTrackingArea
    markedText: NSString
    lastClickTime: array[MouseButton, Time]
  
  WindowCocoaSoftwareRendering* = ref object of WindowCocoa
  WindowCocoaOpengl* = ref object of WindowCocoa


var
  initialized: bool
  appDelegateClass, windowClass, viewClass: Class
  windows: seq[WindowCocoa]
proc init

proc findWindow(windows: seq[WindowCocoa], window: Id): WindowCocoa =
  for w in windows:
    if w.handle.int == window.int:
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


# todo: multiscreen support
proc getScreenCountWinapi*(): int = 1

proc screenCocoa*(number: int32): ScreenCocoa = discard
proc defaultScreenCocoa*(): ScreenCocoa = screenCocoa(0)
proc number*(screen: ScreenCocoa): int = 0

proc width*(window: ScreenCocoa): int =
  ## todo
proc height*(window: ScreenCocoa): int =
  ## todo


proc `=destroy`(window: var WindowCocoaObj) =
  if window.handle.int != 0:
    close window.handle
    window.handle = 0.NsWindow
  
  window.m_closed = true
  
  block eraseClosedWindows:
    var i = 0
    while i < windows.len:
      if windows[i].m_closed:
        windows.del(i)
      else:
        inc i

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

  window.handle = windowClass.alloc.NsWindow.initWithContentRect(
    NsMakeRect(0, 0, 400, 400),
    (
      if frameless: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskResizable or NSWindowStyleMaskBorderless
      else: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskResizable or NSWindowStyleMaskTitled or NSWindowStyleMaskClosable
    ),
    NsBackingStoreBuffered,
    false
  )
  windows.add window


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
      NSOpenGLContextParameterSurfaceOpacity, transparent.uint32,
      0
    ]
    pixelFormat = NSOpenGLPixelFormat.alloc().initWithAttributes(
      pixelFormatAttribs[0].unsafeAddr
    )

  let openglView = viewClass.alloc().NSOpenGLView.initWithFrame(
    window.handle.contentView.frame,
    pixelFormat
  )
  openglView.setWantsBestResolutionOpenGLSurface(true)

  openglView.openGLContext.makeCurrentContext()

  var swapInterval: int32 = if vsync: 1 else: 0
  openglView.openGLContext.setValues(
    swapInterval.addr,
    NSOpenGLContextParameterSwapInterval
  )

  window.handle.setDelegate(window.handle.ID)
  window.handle.setContentView(openglView.NSView)
  discard window.handle.makeFirstResponder(openglView.NSView)
  window.handle.setRestorable(false)


method `frameless=`*(window: WindowCocoaOpengl, v: bool) =
  if window.m_frameless == v: return
  window.m_frameless = v
  window.handle.setStyleMask(
    if v: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskResizable or NSWindowStyleMaskBorderless
    else: NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskResizable or NSWindowStyleMaskTitled or NSWindowStyleMaskClosable
  )


method `title=`*(window: WindowCocoaOpengl, title: string) =
  autoreleasepool:
    window.handle.setTitle(@title)


method `cursor=`*(window: WindowCocoaOpengl, cursor: Cursor) {.locks: "unknown".} =
  if window.m_cursor.kind == builtin and cursor.kind == builtin and window.m_cursor.builtin == cursor.builtin: return
  window.m_cursor = cursor


proc init =
  if initialized: return
  defer: initialized = true

  template getWindow =
    let window {.inject.} = windows.findWindow(self)
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
    window.mouse.pos = ivec2(round(location.x).int32, round(window.handle.contentView.bounds.size.height - location.y).int32)
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

    addClass "WindyAppDelegate", "NSObject", appDelegateClass:
      addMethod "applicationWillFinishLaunching:", proc(self: Id, cmd: Sel, notification: NsNotification): Id {.cdecl.} =
        let
          menuBar = NsMenu.new
          appMenuItem = NsMenuItem.new
        menuBar.addItem(appMenuItem)
        NsApp.setMainMenu(menuBar)

        let
          appMenu = NsMenu.new()
          processName = NsProcessInfo.processinfo.processName
          quitTitle = @("Quit " & $processName)
          quitMenuitem = NsMenuItem.alloc().initWithTitle(
            quitTitle,
            s"terminate:",
            @"q"
          )
        appMenu.addItem(quitMenuItem)
        appMenuItem.setSubmenu(appMenu)

      addMethod "applicationDidFinishLaunching:", proc(self: Id, cmd: Sel, notification: NsNotification): Id {.cdecl.} =
        NSApp.setPresentationOptions(NSApplicationPresentationDefault)
        NSApp.setActivationPolicy(NSApplicationActivationPolicyRegular)
        NSApp.activateIgnoringOtherApps(true)


    addClass "WindyWindow", "NSWindow", windowClass:
      addMethod "windowDidResize:", proc(self: Id, cmd: Sel, notification: NsNotification): Id {.cdecl.} =
        getWindow()
        updateSize window

      addMethod "windowDidMove:", proc(self: Id, cmd: Sel, notification: NsNotification): Id {.cdecl.} =
        getWindow()
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
        getWindow()
        window.m_focused = true
        window.eventsHandler.pushEvent onFocusChanged, FocusChangedEvent(window: window, focus: true)
        updateMousePos window, window.handle.mouseLocationOutsideOfEventStream, MouseMoveKind.enter

      addMethod "windowDidResignKey:", proc(self: Id, cmd: Sel, notification: NsNotification): Id {.cdecl.} =
        getWindow()
        updateMousePos window, window.handle.mouseLocationOutsideOfEventStream, MouseMoveKind.leave
        window.m_focused = false
        window.eventsHandler.pushEvent onFocusChanged, FocusChangedEvent(window: window, focus: false)

      addMethod "windowShouldClose:", proc(self: Id, cmd: Sel, notification: NsNotification): bool {.cdecl.} =
        getWindow()
        window.eventsHandler.pushEvent onClose, CloseEvent(window: window)
        destruct window
        true


    addClass "WindyView", "NSOpenGLView", viewClass:
      addProtocol "NSTextInputClient"
      
      addMethod "acceptsFirstResponder", proc(self: Id, cmd: Sel): bool {.cdecl.} =
        true
      
      addMethod "canBecomeKeyView", proc(self: Id, cmd: Sel): bool {.cdecl.} =
        true
      
      addMethod "acceptsFirstMouse:", proc(self: Id, cmd: Sel, event: NsEvent): bool {.cdecl.} =
        true
      
      addMethod "viewDidChangeBackingProperties", proc(self: Id, cmd: Sel): Id {.cdecl.} =
        callSuper(self, cmd)
        getWindow()
        updateSize window

      addMethod "updateTrackingAreas", proc(self: Id, cmd: Sel): Id {.cdecl.} =
        getWindow()

        if window.trackingArea.int != 0:
          self.NSView.removeTrackingArea(window.trackingArea)
          window.trackingArea.ID.release()
          window.trackingArea = 0.NSTrackingArea

        window.trackingArea = NSTrackingArea.alloc().initWithRect(
          NSMakeRect(0, 0, 0, 0),
          NSTrackingMouseEnteredAndExited or NSTrackingMouseMoved or NSTrackingActiveInKeyWindow or
          NSTrackingCursorUpdate or NSTrackingInVisibleRect or NSTrackingAssumeInside,
          self, 0.ID
        )

        self.NSView.addTrackingArea(window.trackingArea)

        callSuper(self, cmd)

      addMethod "mouseMoved:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        getWindow()
        updateMousePos window, event.locationInWindow, MouseMoveKind.move

      addMethod "mouseDragged:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        getWindow()
        updateMousePos window, event.locationInWindow, MouseMoveKind.move
      
      addMethod "rightMouseDragged:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        getWindow()
        updateMousePos window, event.locationInWindow, MouseMoveKind.move
      
      addMethod "otherMouseDragged:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        getWindow()
        updateMousePos window, event.locationInWindow, MouseMoveKind.move
      
      addMethod "scrollWheel:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        getWindow()
        var
          deltaX = event.scrollingDeltaX
          deltaY = event.scrollingDeltaY

        if event.hasPreciseScrollingDeltas:
          deltaX *= 0.1
          deltaY *= 0.1

        if abs(deltaX) > 0 or abs(deltaY) > 0:
          window.eventsHandler.pushEvent onScroll, ScrollEvent(window: window, delta: deltaY, deltaX: deltaX)

      addMethod "mouseDown:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        getWindow()
        window.handleMouseButton(MouseButton.left, true)

      addMethod "mouseUp:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        getWindow()
        window.handleMouseButton(MouseButton.left, false)

      addMethod "rightMouseDown:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        getWindow()
        window.handleMouseButton(MouseButton.right, true)

      addMethod "rightMouseUp:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        getWindow()
        window.handleMouseButton(MouseButton.right, false)

      addMethod "otherMouseDown:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        getWindow()
        case event.buttonNumber
        of 2: window.handleMouseButton(MouseButton.middle, true)
        of 3: window.handleMouseButton(MouseButton.forward, true)
        of 4: window.handleMouseButton(MouseButton.backward, true)
        else: discard
        
      addMethod "otherMouseUp", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        getWindow()
        case event.buttonNumber
        of 2: window.handleMouseButton(MouseButton.middle, false)
        of 3: window.handleMouseButton(MouseButton.forward, false)
        of 4: window.handleMouseButton(MouseButton.backward, false)
        else: discard

      addMethod "keyDown:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        getWindow()
        let key = event.keyCode.keycodeToKey
        if key != Key.unknown:
          window.keyboard.pressed.incl key
          window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: key, pressed: true, repeated: false)  # todo: handle repeated
          if window.eventsHandler.onTextInput != nil:
            discard self.NSView.inputContext.handleEvent(event)

      addMethod "keyUp:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        getWindow()
        let key = event.keyCode.keycodeToKey
        if key != Key.unknown:
          window.keyboard.pressed.excl key
          window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: key, pressed: false, repeated: false)  # todo: handle repeated

      addMethod "flagsChanged:", proc(self: Id, cmd: Sel, event: NsEvent): Id {.cdecl.} =
        #? wtf is this?!?
        getWindow()
        let key = event.keyCode.keycodeToKey
        if key != Key.unknown:
          if key in window.keyboard.pressed:
            window.keyboard.pressed.excl key
            window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: key, pressed: false, repeated: false)  # todo: handle repeated
          else:
            window.keyboard.pressed.incl key
            window.eventsHandler.pushEvent onKey, KeyEvent(window: window, key: key, pressed: true, repeated: false)  # todo: handle repeated

      addMethod "hasMarkedText", proc(self: Id, cmd: Sel): bool {.cdecl.} =
        getWindow()
        window.markedText.int != 0
      
      addMethod "markedRange", proc(self: Id, cmd: Sel): NsRange {.cdecl.} =
        getWindow()
        if window.markedText.int != 0:
          NSMakeRange(0, window.markedText.length)
        else:
          kEmptyRange

      addMethod "selectedRange", proc(self: Id, cmd: Sel): NsRange {.cdecl.} =
        getWindow()
        NSMakeRange(0, 0)

      addMethod "setMarkedText:selectedRange:replacementRange:", proc(
        self: Id, cmd: Sel, obj: Id, selectedRange: NsRange, replacementRange: NsRange
      ): Id {.cdecl.} =
        getWindow()
        var characters: NSString
        if obj.NSObject.isKindOfClass(NSAttributedString.getClass()):
          characters = obj.NSAttributedString.string()
        else:
          characters = obj.NSString

        if window.markedText.int != 0:
          window.markedText.ID.release()

        window.markedText = NSString.stringWithString(characters)
        window.markedText.ID.retain()

      addMethod "unmarkText", proc(self: Id, cmd: Sel): Id {.cdecl.} =
        discard

      addMethod "validAttributesForMarkedText", proc(self: Id, cmd: Sel): NsArray {.cdecl.} =
        NSArray.array

      addMethod "attributedSubstringForProposedRange:actualRange:", proc(
        self: Id, cmd: Sel, range: NsRange, actualRange: NsRangePointer
      ): NSAttributedString =
        discard
      
      addMethod "insertText:replacementRange:", proc(
        self: Id, cmd: Sel, obj: Id, replacementRange: NsRange
      ): Id {.cdecl.} =
        getWindow()
        var characters: NSString
        if obj.NSObject.isKindOfClass(NSAttributedString.getClass()):
          characters = obj.NSAttributedString.string()
        else:
          characters = obj.NSString

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

        if window.markedText.int != 0:
          window.markedText.ID.release()
          window.markedText = 0.NSString

      addMethod "characterIndexForPoint:", proc(self: Id, cmd: Sel, point: NsPoint): uint {.cdecl.} =
        NSNotFound.uint

      addMethod "firstRectForCharacterRange:actualRange:", proc(
        self: Id, cmd: Sel, range: NsRange, actualRange: NsRangePointer
      ): NsRect {.cdecl.} =
        getWindow()
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
        getWindow()
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

    NSApp.setDelegate(appDelegateClass.new)
    NSApp.finishLaunching()


method step*(window: WindowCocoa) =
  var catched = false
  autoreleasepool:
    while true:
      let event = NSApp.nextEventMatchingMask(
        NSEventMaskAny,
        NSDate.distantPast,
        NSDefaultRunLoopMode,
        true
      )
      if event.int == 0:
        break
      catched = true
      NSApp.sendEvent(event)

  if not catched: sleep 1
  
  if window.redrawRequested:
    window.redrawRequested = false
    window.eventsHandler.pushEvent onRender, RenderEvent(window: window)


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
