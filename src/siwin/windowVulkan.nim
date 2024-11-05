import vmath
import window
import ./platforms

when defined(nimcheck) or defined(nimsuggest):
  discard
elif defined(android):
  import ./platforms/android/window as androidWindow
elif defined(linux):
  import ./platforms/x11/window as x11Window
  import ./platforms/x11/windowVulkan as x11WindowVulkan
  import ./platforms/wayland/window as waylandWindow
  import ./platforms/wayland/windowVulkan as waylandWindowVulkan
elif defined(windows):
  import ./platforms/winapi/window as winapiWindow
  import ./platforms/winapi/windowVulkan as winapiWindowVulkan


proc newVulkanWindow*(
  vkInstance: pointer,
  size = ivec2(1280, 720),
  title = "",
  screen: int32 = -1,
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
  platform = defaultPreferedPlatform(),  ## note that this is foced platform, not prefered

  class = "", # window class (used in x11), equals to title if not specified
): Window =
  when defined(nimcheck) or defined(nimsuggest):
    discard

  elif defined(android):
    # todo
    newOpenglWindowAndroid(
      size, title,
      # (if screen == -1: defaultScreenAndroid() else: screenAndroid(screen)),
      resizable, fullscreen, frameless, transparent, true
    )

  elif defined(linux):
    case platform
    of x11:
      newVulkanWindowX11(
        vkInstance,
        size, title,
        (if screen == -1: defaultScreenX11() else: screenX11(screen)),
        resizable, fullscreen, frameless, transparent,
        (if class == "": title else: class)
      )
    
    of wayland:
      newVulkanWindowWayland(
        vkInstance,
        size, title,
        (if screen == -1: defaultScreenWayland() else: screenWayland(screen)),
        resizable, fullscreen, frameless, transparent
      )

    else:
      raise PlatformSupportDefect.newException("Unsupported platform: " & $platform)

  elif defined(windows):
    case platform
    of winapi:
      newVulkanWindowWinapi(
        vkInstance,
        size, title,
        (if screen == -1: defaultScreenWinapi() else: screenWinapi(screen)),
        resizable, fullscreen, frameless, transparent
      )
    else:
      raise PlatformSupportDefect.newException("Unsupported platform: " & $platform)
