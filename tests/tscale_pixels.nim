import unittest
import pkg/vmath
import siwin/window

when defined(linux) or defined(bsd):
  import std/importutils
  import siwin/platforms/any/window as anyWindow
  import siwin/platforms/wayland/window as waylandWindow
  import siwin/platforms/x11/window as x11Window

  privateAccess anyWindow.Window
  privateAccess waylandWindow.WindowWaylandObj

suite "platform size reporting":
  when defined(linux) or defined(bsd):
    test "X11 reports native window pixels":
      var window: x11Window.WindowX11
      new window
      window.m_size = ivec2(320, 180)

      check window.uiScale == 1'f32
      check window.size == ivec2(320, 180)

    test "Wayland reports buffer pixels at compositor scale":
      var window: waylandWindow.WindowWayland
      new window
      window.m_size = ivec2(320, 180)
      window.bufferScaleFactor = 2

      check window.uiScale == 2'f32
      check window.size == ivec2(640, 360)

    test "Wayland reports logical pixels when compositor scale is one":
      var window: waylandWindow.WindowWayland
      new window
      window.m_size = ivec2(320, 180)
      window.bufferScaleFactor = 1

      check window.uiScale == 1'f32
      check window.size == ivec2(320, 180)
  else:
    test "platform size reporting is covered by platform-specific backends":
      skip()
