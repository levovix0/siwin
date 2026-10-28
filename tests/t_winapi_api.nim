when defined(windows):
  import std/unittest

  import vmath
  import siwin/platforms/winapi/window
  import siwin/platforms/winapi/windowOpengl
  import siwin/platforms/winapi/winapi

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

    test "OpenGL fallback uses the existing software window":
      let window = newSoftwareRenderingWindowWinapi(size = ivec2(64, 64))
      defer:
        window.close()
      let handle = window.nativeWindowHandle()
      block:
        let fallback = newWinapiOpenGlFallback(window)
        fallback.makeCurrent()
        let firstContext = wglGetCurrentContext()
        check firstContext != 0
        check window.nativeWindowHandle() == handle
        fallback.swapBuffers()
        block:
          let second = newWinapiOpenGlFallback(window)
          second.makeCurrent()
          check wglGetCurrentContext() != firstContext
          fallback.makeCurrent()
          check wglGetCurrentContext() == firstContext
      when defined(gcDestructors):
        check wglGetCurrentContext() == 0

    test "missing fallback windows fail safely":
      expect ValueError:
        discard newWinapiOpenGlFallback(nil)
      let window = newSoftwareRenderingWindowWinapi(size = ivec2(64, 64))
      window.close()
      expect ValueError:
        discard newWinapiOpenGlFallback(window)

    test "closed fallback windows fail safely":
      let window = newSoftwareRenderingWindowWinapi(size = ivec2(64, 64))
      let fallback = newWinapiOpenGlFallback(window)
      window.close()
      expect OSError:
        fallback.makeCurrent()
      expect OSError:
        fallback.swapBuffers()
