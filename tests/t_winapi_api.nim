when defined(windows):
  import std/unittest

  import vmath
  import siwin/platforms/winapi/window

  suite "Win32 native window access":
    test "software windows expose native handles":
      let window = newSoftwareRenderingWindowWinapi(size = ivec2(64, 64))
      defer:
        window.close()
      check window.nativeWindowHandle() != nil
      check window.nativeInstanceHandle() != nil

    test "software present can be disabled for external presenters":
      let window = newSoftwareRenderingWindowWinapi(size = ivec2(64, 64))
      defer:
        window.close()
      check window.softwarePresentEnabled
      window.setSoftwarePresentEnabled(false)
      check not window.softwarePresentEnabled
