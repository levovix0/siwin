when defined(linux) or defined(bsd):
  import std/unittest

  import siwin/platforms/x11/x11api

  suite "X11 visual query entry points":
    test "required symbols load when libX11 is installed":
      if libX11Handle == nil:
        skip()
      else:
        check XGetWindowAttributes != nil
        check XGetVisualInfo != nil
        check XVisualIDFromVisual != nil

    test "visual helper reports unavailable entry points":
      let original = XGetWindowAttributes
      defer:
        XGetWindowAttributes = original
      XGetWindowAttributes = nil
      expect OSError:
        discard getWindowVisualInfo(nil, Drawable(0))

    test "visual helper copies and releases Xlib query results":
      let
        originalAttributes = XGetWindowAttributes
        originalVisualId = XVisualIDFromVisual
        originalVisualInfo = XGetVisualInfo
        originalFree = XFree
      defer:
        XGetWindowAttributes = originalAttributes
        XVisualIDFromVisual = originalVisualId
        XGetVisualInfo = originalVisualInfo
        XFree = originalFree

      var
        queriedVisual {.global.}: XVisualInfo
        queryCount {.global.}: cint
        freeCount {.global.}: int
      queriedVisual = XVisualInfo(depth: 24)
      queryCount = 1
      freeCount = 0
      XGetWindowAttributes = proc(
          display: PDisplay, window: Drawable, attributes: PXWindowAttributes
      ): cint {.cdecl, raises: [].} =
        1
      XVisualIDFromVisual = proc(visual: PVisual): culong {.cdecl, raises: [].} =
        1
      XGetVisualInfo = proc(
          display: PDisplay, mask: clong, visual: PXVisualInfo, count: ptr cint
      ): PXVisualInfo {.cdecl, raises: [].} =
        count[] = queryCount
        queriedVisual.addr
      XFree = proc(data: pointer): cint {.cdecl, raises: [].} =
        inc freeCount
        queriedVisual.depth = 0

      let visual = getWindowVisualInfo(nil, Drawable(0))
      check visual.depth == 24
      check freeCount == 1

      queryCount = 0
      expect OSError:
        discard getWindowVisualInfo(nil, Drawable(0))
      check freeCount == 2

    test "query the root window visual":
      if not x11Available():
        skip()
      else:
        let display = XOpenDisplay(nil)
        if display == nil:
          skip()
        else:
          defer:
            discard XCloseDisplay(display)

          let drawable: x11api.Drawable = XRootWindow(display, 0)
          var attributes: XWindowAttributes
          require XGetWindowAttributes(display, drawable, attributes.addr) != 0

          var
            visual = XVisualInfo(visualid: XVisualIDFromVisual(attributes.visual))
            count: cint
          let visuals =
            XGetVisualInfo(display, VisualIDMask.clong, visual.addr, count.addr)
          require visuals != nil
          defer:
            discard XFree(visuals)
          check count > 0

          let windowVisual = getWindowVisualInfo(display, drawable)
          check windowVisual.visual == attributes.visual
          check windowVisual.visualid == visuals.visualid
          check windowVisual.depth == attributes.depth

  suite "optional X11-XCB bridge":
    test "loads independently of core X11":
      check x11XcbAvailable() == (XGetXCBConnection != nil)
      if libX11XcbHandle == nil:
        check XGetXCBConnection == nil

    test "a missing bridge or display returns nil":
      check x11XcbConnection(nil) == nil
      let original = XGetXCBConnection
      defer:
        XGetXCBConnection = original
      XGetXCBConnection = nil
      check x11XcbConnection(cast[PDisplay](1)) == nil

    test "gets the XCB connection for an X11 display":
      if not x11Available() or not x11XcbAvailable():
        skip()
      else:
        let display = XOpenDisplay(nil)
        if display == nil:
          skip()
        else:
          defer:
            discard XCloseDisplay(display)
          check x11XcbConnection(display) != nil
          check x11XcbConnection(display) == XGetXCBConnection(display)
