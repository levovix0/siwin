import vmath
import ./platforms/any/window
import ./platforms
export window
when defined(linux):
  import ./platforms/x11/window as x11Window
elif defined(windows):
  import ./platforms/winapi/window as winapiWindow


proc screenCount*(preferedPlatform = defaultPreferedPlatform): int32 =
  when defined(linux): screenCountX11()
  elif defined(windows): screenCountWinapi()

proc screen*(number: int32, preferedPlatform = defaultPreferedPlatform): Screen =
  when defined(linux): screenX11(number)
  elif defined(windows): screenWinapi(number)

proc defaultScreen*(preferedPlatform = defaultPreferedPlatform): Screen =
  when defined(linux): defaultScreenX11()
  elif defined(windows): defaultScreenWinapi()


proc newSoftwareRenderingWindow*(
  size = ivec2(1280, 720),
  title = "",
  screen: int32 = -1,
  fullscreen = false,
  resizable = true,
  frameless = false,
  transparent = false,
  preferedPlatform = defaultPreferedPlatform,

  class = "", # window class (used in x11), equals to title if not specified
): Window =
  when defined(linux):
    newSoftwareRenderingWindowX11(
      size, title,
      (if screen == -1: defaultScreenX11() else: screenX11(screen)),
      resizable, fullscreen, frameless, transparent,
      (if class == "": title else: class)
    )
  elif defined(windows):
    newSoftwareRenderingWindowWinapi(
      size, title,
      (if screen == -1: defaultScreenWinapi() else: screenWinapi(screen)),
      resizable, fullscreen, frameless, transparent
    )
