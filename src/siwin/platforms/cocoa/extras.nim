import pkg/darwin/[app_kit, foundation]
import pkg/darwin/objc/runtime

export app_kit, foundation, runtime

when not declared(activateIgnoringOtherApps):
  proc activateIgnoringOtherApps*(self: NSApplication, x: bool) {.objc: "activateIgnoringOtherApps:".}

when not declared(applicationEventWithType):
  proc applicationEventWithType*(
    self: typedesc[NSEvent], eventType: NSEventKind, location: NSPoint,
    modifierFlags: NSUInteger, timestamp: NSTimeInterval, windowNumber: NSInteger,
    context: ID, subtype: int16, data1, data2: NSInteger,
  ): NSEvent {.objc: "otherEventWithType:location:modifierFlags:timestamp:windowNumber:context:subtype:data1:data2:".}

when not declared(data1):
  proc data1*(self: NSEvent): NSInteger {.objc: "data1".}

when not declared(subtype):
  proc subtype*(self: NSEvent): int16 {.objc: "subtype".}

when not declared(distantFuture):
  proc distantFuture*(t: typedesc[NSDate]): NSDate {.objc.}

when not compiles(screens(NSScreen)):
  proc screens*(n: typedesc[NSScreen]): NSArray[NSScreen] {.objc: "screens".}
  proc registerForDraggedTypes*(self: NSView, types: NSArray[NSString]): NSArray[NSString] {.objc: "registerForDraggedTypes:".}
  proc draggingPasteboard*(self: NSDraggingInfo): NSPasteboard {.objc: "draggingPasteboard".}
  proc draggingLocation*(self: NSDraggingInfo): NSPoint {.objc: "draggingLocation".}
  proc toggleFullScreen*(s: NSWindow, sender: ID) {.objc: "toggleFullScreen:".}
  proc zoom*(s: NSWindow, sender: ID) {.objc: "zoom:".}
  proc isZoomed*(s: NSWindow): BOOL {.objc: "isZoomed".}
  proc miniaturize*(s: NSWindow, sender: ID) {.objc: "miniaturize:".}
  proc deminiaturize*(s: NSWindow, sender: ID) {.objc: "deminiaturize:".}
  proc setMinSize*(s: NSWindow, size: NSSize) {.objc: "setMinSize:".}
  proc setMaxSize*(s: NSWindow, size: NSSize) {.objc: "setMaxSize:".}
  proc initWithSize*(self: NSImage, size: NSSize): NSImage {.objc: "initWithSize:".}
  proc addRepresentation*(self: NSImage, imageRep: NSImageRep) {.objc: "addRepresentation:".}
  proc bitmapData*(self: NSBitmapImageRep): pointer {.objc.}
  proc initWithBitmapDataPlanes*(
    self: NSBitmapImageRep,
    planes: pointer,
    pixelsWide, pixelsHigh: NSInteger,
    bitsPerSample, samplesPerPixel: NSInteger,
    hasAlpha, isPlanar: BOOL,
    colorSpaceName: NSString,
    bitmapFormat: NSUInteger,
    bytesPerRow, bitsPerPixel: NSInteger,
  ): NSBitmapImageRep {.objc: "initWithBitmapDataPlanes:pixelsWide:pixelsHigh:bitsPerSample:samplesPerPixel:hasAlpha:isPlanar:colorSpaceName:bitmapFormat:bytesPerRow:bitsPerPixel:".}
