import vmath
import window
import ./platforms
when defined(linux):
  import ./platforms/x11/window as x11Window
  import ./platforms/x11/windowVulkan as x11WindowVulkan
elif defined(windows):
  import ./platforms/winapi/window as winapiWindow
  import ./platforms/winapi/windowVulkan as winapiWindowVulkan


proc newVulkanWindow*(
  vkInstance: pointer,
  size = ivec2(1280, 720),
  title = "",
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
  platform = defaultPreferedPlatform,  ## note that this is foced platform, not prefered

  class = "", # window class (used in x11), equals to title if not specified
): Window =
  when defined(linux):
    case platform
    of x11:
      newVulkanWindowX11(
        vkInstance,
        size, title,
        defaultScreenX11(),
        resizable, fullscreen, frameless, transparent,
        (if class == "": title else: class)
      )
    else:
      raise PlatformSupportDefect.newException("Unsupported platform: " & $platform)

  elif defined(windows):
    case platform
    of winapi:
      newVulkanWindowWinapi(
        vkInstance,
        size, title,
        defaultScreenWinapi(),
        resizable, fullscreen, frameless, transparent
      )
    else:
      raise PlatformSupportDefect.newException("Unsupported platform: " & $platform)
