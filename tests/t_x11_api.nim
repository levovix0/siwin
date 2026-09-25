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

          var attributes: XWindowAttributes
          require XGetWindowAttributes(
            display, XRootWindow(display, 0), attributes.addr
          ) != 0

          var
            visual = XVisualInfo(visualid: XVisualIDFromVisual(attributes.visual))
            count: cint
          let visuals =
            XGetVisualInfo(display, VisualIDMask.clong, visual.addr, count.addr)
          require visuals != nil
          defer:
            discard XFree(visuals)
          check count > 0
