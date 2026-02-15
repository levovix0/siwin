import pkg/darwin/[app_kit, foundation]
import pkg/darwin/objc/runtime

export app_kit, foundation, runtime

when not declared(activateIgnoringOtherApps):
  proc activateIgnoringOtherApps*(self: NSApplication, x: bool) {.objc: "activateIgnoringOtherApps:".}

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
