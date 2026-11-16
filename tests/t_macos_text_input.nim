import std/assertions

when defined(macosx):
  import pkg/vmath
  import pkg/darwin/app_kit/[nsevent, nsview]
  import pkg/darwin/foundation/[nsgeometry, nsrange, nsstring]
  import pkg/darwin/objc/runtime
  import siwin
  import siwin/platforms/cocoa/window

  proc hasMarkedText(view: NSView): bool {.objc: "hasMarkedText".}
  proc unmarkText(view: NSView) {.objc: "unmarkText".}
  proc setMarkedText(
    view: NSView, text: NSString, selected, replacement: NSRange
  ) {.objc: "setMarkedText:selectedRange:replacementRange:".}

  proc keyDown(view: NSView, event: NSEvent) {.objc: "keyDown:".}
  proc makeKeyEvent(
    eventClass: typedesc[NSEvent],
    kind: NSInteger,
    point: NSPoint,
    modifiers: NSUInteger,
    timestamp: float64,
    windowNumber: NSInteger,
    context: ID,
    characters, ignoringModifiers: NSString,
    repeated: BOOL,
    keyCode: uint16,
  ): NSEvent {.
    objc:
      "keyEventWithType:location:modifierFlags:timestamp:windowNumber:context:characters:charactersIgnoringModifiers:isARepeat:keyCode:"
  .}

  block absent_marked_text_does_not_intercept_keys:
    let window = newSoftwareRenderingWindowCocoa(size = ivec2(320, 240))
    defer:
      window.close()
    var keys: seq[Key]
    window.eventsHandler.onKey = proc(event: KeyEvent) =
      if event.pressed:
        keys.add event.key
    let view = cast[NSView](window.nativeViewHandle())
    doAssert not view.hasMarkedText()
    window.eventsHandler.onTextInputState = proc(
        event: AnyWindowEvent
    ): TextInputState =
      TextInputState()
    doAssert not view.hasMarkedText()
    for (characters, code) in [("\r", 0x24'u16), ("\uf702", 0x7b'u16)]:
      let event = NSEvent.makeKeyEvent(
        10,
        NSMakePoint(0, 0),
        0,
        0,
        0,
        nil,
        characters.toNSString,
        characters.toNSString,
        false,
        code,
      )
      doAssert event != nil
      view.keyDown(event)
    doAssert keys == @[Key.enter, Key.left]

  block marked_text_still_uses_legacy_fallback:
    let window = newSoftwareRenderingWindowCocoa(size = ivec2(320, 240))
    defer:
      window.close()
    let view = cast[NSView](window.nativeViewHandle())
    view.setMarkedText("x".toNSString, NSMakeRange(1, 0), NSRangeEmpty)
    doAssert view.hasMarkedText()
    window.eventsHandler.onTextInputState = proc(
        event: AnyWindowEvent
    ): TextInputState =
      TextInputState()
    doAssert view.hasMarkedText()
    window.eventsHandler.onTextInputState = proc(
        event: AnyWindowEvent
    ): TextInputState =
      TextInputState(valid: true, markedStart: -1)
    doAssert not view.hasMarkedText()
    view.unmarkText()
    window.eventsHandler.onTextInputState = nil
    doAssert not view.hasMarkedText()
