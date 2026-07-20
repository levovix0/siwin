import std/assertions

when defined(macosx):
  import pkg/vmath
  import pkg/darwin/app_kit/nsview
  import pkg/darwin/objc/runtime

  import siwin
  import siwin/platforms/cocoa/window

  proc nativePreservesContentDuringLiveResize(
    view: NSView
  ): bool {.objc: "preservesContentDuringLiveResize".}

  block macosOpenGlLiveResizePreservation:
    let testWindow = newOpenglWindowCocoa(
      size = ivec2(320, 240),
      title = "siwin live resize preservation test",
      vsync = false,
    )
    defer:
      if testWindow.opened:
        testWindow.close()

    let view = cast[NSView](testWindow.nativeViewHandle())

    doAssert not testWindow.preservesContentDuringLiveResize
    doAssert not view.nativePreservesContentDuringLiveResize()

    testWindow.preservesContentDuringLiveResize = true
    doAssert testWindow.preservesContentDuringLiveResize
    doAssert view.nativePreservesContentDuringLiveResize()

    testWindow.preservesContentDuringLiveResize = false
    doAssert not testWindow.preservesContentDuringLiveResize
    doAssert not view.nativePreservesContentDuringLiveResize()
