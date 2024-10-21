## note: Copy-pasted from windy and slightly changed

import objc
export objc

{.passL: "-framework Cocoa".}

type
  CGPoint* {.pure, bycopy.} = object
    x*, y*: float64

  CGSize* {.pure, bycopy.} = object
    width*, height*: float64

  CGRect* {.pure, bycopy.} = object
    origin*: CGPoint
    size*: CGSize

  NSRange* {.pure, bycopy.} = object
    location*, length*: uint

  NSRangePointer* = ptr NSRange

type
  NSEventMask* = uint64
  NSWindowStyleMask* = uint
  NSBackingStoreType* = uint
  NSApplicationActivationPolicy* = int
  NSApplicationPresentationOptions* = uint
  NSOpenGLPixelFormatAttribute* = uint32
  NSOpenGLContextParameter* = int
  NSTrackingAreaOptions* = uint
  NSStringEncoding* = uint
  NSStringEncodingConversionOptions* = uint
  NSBitmapImageFileType* = uint
  NSWindowLevel* = int

  NSRect* = CGRect
  NSPoint* = CGPoint
  NSSize* = CGSize

  NSObject* = distinct int
  NSAutoreleasePool* = distinct NSObject
  NSAttributedString* = distinct NSObject
  NSData* = distinct NSObject
  NSArray* = distinct NSObject
  NSScreen* = distinct NSObject
  NSPasteboard* = distinct NSObject
  NSPasteboardType* = distinct NSString
  NSApplication* = distinct NSObject
  NSNotification* = distinct NSObject
  NSEvent* = distinct NSObject
  NSDate* = distinct NSObject
  NSRunLoopMode* = distinct NSString
  NSMenu* = distinct NSObject
  NSMenuItem* = distinct NSObject
  NSProcessInfo* = distinct NSObject
  NSWindow* = distinct NSObject
  NSView* = distinct NSObject
  NSOpenGLView* = distinct NSObject
  NSOpenGLPixelFormat* = distinct NSObject
  NSOpenGLContext* = distinct NSObject
  NSTrackingArea* = distinct NSObject
  NSImage* = distinct NSObject
  NSCursor* = distinct NSObject
  NSTextInputContext* = distinct NSObject
  NSTextInputClient* = distinct int
  NSBitmapImageRep* = distinct NSObject
  NSDictionary* = distinct NSObject

const
  NSNotFound* = int.high
  kEmptyRange* = NSRange(location: cast[uint](NSNotFound), length: 0)
  NSEventMaskAny* = uint64.high.NSEventMask
  NSWindowStyleMaskBorderless* = 0.NSWindowStyleMask
  NSWindowStyleMaskTitled* = (1 shl 0).NSWindowStyleMask
  NSWindowStyleMaskClosable* = (1 shl 1).NSWindowStyleMask
  NSWindowStyleMaskMiniaturizable* = (1 shl 2).NSWindowStyleMask
  NSWindowStyleMaskResizable* = (1 shl 3).NSWindowStyleMask
  NSWindowStyleMaskFullScreen* = (1 shl 14).NSWindowStyleMask
  NSBackingStoreBuffered* = 2.NSBackingStoreType
  NSApplicationActivationPolicyRegular* = 0.NSApplicationActivationPolicy
  NSApplicationPresentationDefault* = 0.NSApplicationPresentationOptions
  NSOpenGLPFAMultisample* = 59.NSOpenGLPixelFormatAttribute
  NSOpenGLPFASampleBuffers* = 55.NSOpenGLPixelFormatAttribute
  NSOpenGLPFASamples* = 56.NSOpenGLPixelFormatAttribute
  NSOpenGLPFAAccelerated* = 73.NSOpenGLPixelFormatAttribute
  NSOpenGLPFADoubleBuffer* = 5.NSOpenGLPixelFormatAttribute
  NSOpenGLPFAColorSize* = 8.NSOpenGLPixelFormatAttribute
  NSOpenGLPFAAlphaSize* = 11.NSOpenGLPixelFormatAttribute
  NSOpenGLPFADepthSize* = 12.NSOpenGLPixelFormatAttribute
  NSOpenGLPFAStencilSize* = 13.NSOpenGLPixelFormatAttribute
  NSOpenGLPFAOpenGLProfile* = 99.NSOpenGLPixelFormatAttribute
  NSOpenGLProfileVersionLegacy* = 0x1000
  NSOpenGLProfileVersion3_2Core* = 0x3200
  NSOpenGLProfileVersion4_1Core* = 0x4100
  NSOpenGLContextParameterSwapInterval* = 222
  NSOpenGLContextParameterSurfaceOpacity* = 236
  NSTrackingMouseEnteredAndExited* = 0x01.NSTrackingAreaOptions
  NSTrackingMouseMoved* = 0x02.NSTrackingAreaOptions
  NSTrackingCursorUpdate* = 0x04.NSTrackingAreaOptions
  NSTrackingActiveWhenFirstResponder* = 0x10.NSTrackingAreaOptions
  NSTrackingActiveInKeyWindow* = 0x20.NSTrackingAreaOptions
  NSTrackingActiveInActiveApp* = 0x40.NSTrackingAreaOptions
  NSTrackingActiveAlways* = 0x80.NSTrackingAreaOptions
  NSTrackingAssumeInside* = 0x100.NSTrackingAreaOptions
  NSTrackingInVisibleRect* = 0x200.NSTrackingAreaOptions
  NSTrackingEnabledDuringMouseDrag* = 0x400.NSTrackingAreaOptions
  NSUTF32StringEncoding* = 0x8c000100.NSStringEncoding
  NSBitmapImageFileTypePNG* = 4.NSBitmapImageFileType
  NSNormalWindowLevel* = 0.NSWindowLevel
  NSFloatingWindowLevel* = 3.NSWindowLevel

var
  NSApp* {.importc.}: NSApplication
  NSPasteboardTypeString* {.importc.}: NSPasteboardType
  NSPasteboardTypeTIFF* {.importc.}: NSPasteboardType
  NSDefaultRunLoopMode* {.importc.}: NSRunLoopMode

objc:
  proc isKindOfClass*(self: NSObject, arg2: Class): bool
  proc superclass*(self: NSObject): Class
  proc retain*(self: ID)
  proc release*(self: ID)
  proc stringWithString*(class: typedesc[NSString], arg2: NSString): NSString
  proc getBytes*(
    self: NSString,
    arg2: pointer,
    maxLength: uint,
    usedLength: ptr uint,
    encoding: NSStringEncoding,
    options: NSStringEncodingConversionOptions,
    range: NSRange,
    remainingRange: NSRangePointer
  ): bool
  proc string*(self: NSAttributedString): NSString
  proc doubleClickInterval*(class: typedesc[NSEvent]): float64
  proc scrollingDeltaX*(self: NSEvent): float64
  proc scrollingDeltaY*(self: NSEvent): float64
  proc hasPreciseScrollingDeltas*(self: NSEvent): bool
  proc locationInWindow*(self: NSEvent): NSPoint
  proc buttonNumber*(self: NSEvent): int
  proc keyCode*(self: NSEvent): uint16
  proc dataWithBytes*(class: typedesc[NSData], arg2: pointer, length: int): NSData
  proc length*(self: NSData): uint
  proc bytes*(self: NSData): pointer
  proc length*(self: NSString): uint
  proc array*(class: typedesc[NSArray]): NSArray
  proc count*(self: NSArray): uint
  proc objectAtIndex*(self: NSArray, arg2: uint): ID
  proc containsObject*(self: NSArray, arg2: ID): bool
  proc screens*(class: typedesc[NSScreen]): NSArray
  proc frame*(self: NSScreen): NSRect
  proc frame*(self: NSWindow): NSRect
  proc frame*(self: NSView): NSRect
  proc generalPasteboard*(class: typedesc[NSPasteboard]): NSPasteboard
  proc types*(self: NSPasteboard): NSArray
  proc stringForType*(self: NSPasteboard, arg2: NSPasteboardType): NSString
  proc dataForType*(self: NSPasteboard, arg2: NSPasteboardType): NSData
  proc clearContents*(self: NSPasteboard)
  proc setString*(self: NSPasteboard, arg2: NSString, forType: NSPasteboardType)
  proc processInfo*(class: typedesc[NSProcessInfo]): NSProcessInfo
  proc processName*(self: NSProcessInfo): NSString
  proc sharedApplication*(class: typedesc[NSApplication]): NSApplication
  proc setActivationPolicy*(
    self: NSApplication,
    arg2: NSApplicationActivationPolicy
  )
  proc setPresentationOptions*(
    self: NSApplication,
    arg2: NSApplicationPresentationOptions
  )
  proc activateIgnoringOtherApps*(self: NSApplication, arg2: bool)
  proc setDelegate*(self: NSApplication, arg2: ID)
  proc setDelegate*(self: NSWindow, arg2: ID)
  proc setMainMenu*(self: NSApplication, arg2: NSMenu)
  proc finishLaunching*(self: NSApplication)
  proc nextEventMatchingMask*(
    self: NSApplication,
    arg2: NSEventMask,
    untilDate: NSDate,
    inMode: NSRunLoopMode,
    dequeue: bool
  ): NSEvent
  proc sendEvent*(self: NSApplication, arg2: NSEvent)
  proc distantPast*(class: typedesc[NSDate]): NSDate
  proc addItem*(self: NSMenu, arg2: NSMenuItem)
  proc initWithTitle*(
    self: NSMenuItem,
    arg2: NSString,
    action: SEL,
    keyEquivalent: NSString
  ): NSMenuItem
  proc setSubmenu*(self: NSMenuItem, arg2: NSMenu)
  proc initWithContentRect*(
    self: NSWindow,
    arg2: NSRect,
    styleMask: NSWindowStyleMask,
    backing: NSBackingStoreType,
    defer_mangle: bool
  ): NSWindow
  proc orderFront*(self: NSWindow, arg2: ID)
  proc orderOut*(self: NSWindow, arg2: ID)
  proc setTitle*(self: NSWindow, arg2: NSString)
  proc close*(self: NSWindow)
  proc isVisible*(self: NSWindow): bool
  proc miniaturize*(self: NSWindow, arg2: ID)
  proc deminiaturize*(self: NSWindow, arg2: ID)
  proc isMiniaturized*(self: NSWindow): bool
  proc zoom*(self: NSWindow, arg2: ID)
  proc isZoomed*(self: NSWindow): bool
  proc isKeyWindow*(self: NSWindow): bool
  proc contentView*(self: NSWindow): NSView
  proc contentRectForFrameRect*(self: NSWindow, arg2: NSRect): NSRect
  proc frameRectForContentRect*(self: NSWindow, arg2: NSRect): NSRect
  proc setFrame*(self: NSWindow, arg2: NSRect, display: bool)
  proc screen*(self: NSWindow): NSScreen
  proc setFrameOrigin*(self: NSWindow, arg2: NSPoint)
  proc setRestorable*(self: NSWindow, arg2: bool)
  proc setContentView*(self: NSWindow, arg2: NSView)
  proc makeFirstResponder*(self: NSWindow, arg2: NSView): bool
  proc styleMask*(self: NSWindow): NSWindowStyleMask
  proc setStyleMask*(self: NSWindow, arg2: NSWindowStyleMask)
  proc toggleFullscreen*(self: NSWindow, arg2: ID)
  proc invalidateCursorRectsForView*(self: NSWindow, arg2: NSView)
  proc mouseLocationOutsideOfEventStream*(self: NSWindow): NSPoint
  proc level*(self: NSWindow): NSWindowLevel
  proc setLevel*(self: NSWindow, arg2: NSWindowLevel)
  proc convertRectToBacking*(self: NSView, arg2: NSRect): NSRect
  proc window*(self: NSView): NSWindow
  proc bounds*(self: NSView): NSRect
  proc removeTrackingArea*(self: NSView, arg2: NSTrackingArea)
  proc addTrackingArea*(self: NSView, arg2: NSTrackingArea)
  proc addCursorRect*(self: NSview, arg2: NSRect, cursor: NSCursor)
  proc inputContext*(self: NSView): NSTextInputContext
  proc initWithAttributes*(
    self: NSOpenGLPixelFormat,
    arg2: ptr NSOpenGLPixelFormatAttribute
  ): NSOpenGLPixelFormat
  proc initWithFrame*(
    self: NSOpenGLView,
    arg2: NSRect,
    pixelFormat: NSOpenGLPixelFormat
  ): NSOpenGLView
  proc setWantsBestResolutionOpenGLSurface*(
    self: NSOpenGLView,
    arg2: bool
  )
  proc openGLContext*(self: NSOpenGLView): NSOpenGLContext
  proc makeCurrentContext*(self: NSOpenGLContext)
  proc setValues*(
    self: NSOpenGLContext,
    arg2: ptr int32,
    forParameter: NSOpenGLContextParameter
  )
  proc getValues*(
    self: NSOpenGLContext,
    arg2: ptr int32,
    forParameter: NSOpenGLContextParameter
  )
  proc flushBuffer*(self: NSOpenGLContext)
  proc initWithRect*(
    self: NSTrackingArea,
    arg2: NSRect,
    options: NSTrackingAreaOptions,
    owner: ID,
    userInfo: ID
  ): NSTrackingArea
  proc initWithData*(self: NSImage, arg2: NSData): NSImage
  proc initWithImage*(self: NSCursor, arg2: NSImage, hotSpot: NSPoint): NSCursor
  proc discardMarkedText*(self: NSTextInputContext)
  proc handleEvent*(self: NSTextInputContext, arg2: NSEvent): bool
  proc deactivate*(self: NSTextInputContext)
  proc activate*(self: NSTextInputContext)
  proc insertText*(self: NSTextInputClient, arg2: ID, replacementRange: NSRange)
  proc initWithData*(self: NSBitmapImageRep, arg2: NSData): NSBitmapImageRep
  proc representationUsingType*(
    self: NSBitmapImageRep,
    arg2: NSBitmapImageFileType,
    properties: NSDictionary
  ): NSData

{.push inline.}

proc NSMakeRect*(x, y, w, h: float64): NSRect =
  CGRect(
    origin: CGPoint(x: x, y: y),
    size: CGSIze(width: w, height: h)
  )

proc NSMakeSize*(w, h: float64): NSSize =
  CGSize(width: w, height: h)

proc NSMakeRange*(loc, len: uint): NSRange =
  NSRange(location: loc, length: len)

proc NSMakePoint*(x, y: float): NSPoint =
  NSPoint(x: x, y: y)

proc `[]`*(arr: NSArray, index: int): ID =
  arr.objectAtIndex(index.uint)

proc callSuper*(sender: ID, cmd: SEL) =
  var super = objc_super(
    receiver: sender,
    super_class: sender.NSObject.superclass
  )
  let cvf = cast[proc(super: ptr objc_super, cmd: SEL) {.cdecl.}](objc_msgSendSuper)
  cvf(
    super.addr,
    cmd
  )

{.pop.}
