when defined(linux) or defined(bsd):
  import unittest

  import pkg/vmath
  import x11/xutil
  import siwin/platforms/x11/window

  suite "X11 window size hints":
    test "positive minimum size sets only the minimum constraint":
      var hints: XSizeHints
      hints.flags = PSize

      hints.applyMinSizeHint(ivec2(320, 180))

      check (hints.flags and PSize) != 0
      check (hints.flags and PMinSize) != 0
      check (hints.flags and PMaxSize) == 0
      check hints.minWidth == 320
      check hints.minHeight == 180

    test "unbounded minimum size clears the minimum constraint":
      var hints: XSizeHints
      hints.flags = PSize or PMinSize
      hints.minWidth = 320
      hints.minHeight = 180

      hints.applyMinSizeHint(ivec2(320, 0))

      check (hints.flags and PSize) != 0
      check (hints.flags and PMinSize) == 0
      check hints.minWidth == 320
      check hints.minHeight == 180

    test "positive maximum size sets only the maximum constraint":
      var hints: XSizeHints
      hints.flags = PSize

      hints.applyMaxSizeHint(ivec2(1920, 1080))

      check (hints.flags and PSize) != 0
      check (hints.flags and PMinSize) == 0
      check (hints.flags and PMaxSize) != 0
      check hints.maxWidth == 1920
      check hints.maxHeight == 1080

    test "unbounded maximum size clears the maximum constraint":
      var hints: XSizeHints
      hints.flags = PSize or PMaxSize
      hints.maxWidth = 1920
      hints.maxHeight = 1080

      hints.applyMaxSizeHint(ivec2(0, 1080))

      check (hints.flags and PSize) != 0
      check (hints.flags and PMaxSize) == 0
      check hints.maxWidth == 1920
      check hints.maxHeight == 1080
