import vmath
import ./platforms/any/[window]
import ./platforms
export window
when defined(linux):
  import ./platforms/x11/window as x11Window
  import ./platforms/wayland/window as waylandWindow
elif defined(windows):
  import ./platforms/winapi/window as winapiWindow
elif defined(macosx):
  import ./platforms/cocoa/window as cocoaWindow


proc screenCount*(preferedPlatform = defaultPreferedPlatform()): int32 =
  when defined(linux):
    case availablePlatforms().platformToUse(preferedPlatform)
    of x11:
      result = screenCountX11()
    of wayland:
      result = screenCountWayland()
    else: discard
  
  elif defined(windows): screenCountWinapi()

proc screen*(number: int32, preferedPlatform = defaultPreferedPlatform()): Screen =
  when defined(linux):
    case availablePlatforms().platformToUse(preferedPlatform)
    of x11:
      result = screenX11(number)
    of wayland:
      result = screenWayland(number)
    else: discard
  
  elif defined(windows): screenWinapi(number)

proc defaultScreen*(preferedPlatform = defaultPreferedPlatform()): Screen =
  when defined(linux):
    case availablePlatforms().platformToUse(preferedPlatform)
    of x11:
      result = defaultScreenX11()
    of wayland:
      result = defaultScreenWayland()
    else: discard
  
  elif defined(windows): defaultScreenWinapi()


proc newSoftwareRenderingWindow*(
  size = ivec2(1280, 720),
  title = "",
  screen: int32 = -1,
  fullscreen = false,
  resizable = true,
  frameless = false,
  transparent = false,
  preferedPlatform = defaultPreferedPlatform(),

  class = "", # window class (used in x11), equals to title if not specified
): Window =
  when defined(linux):
    case availablePlatforms().platformToUse(preferedPlatform)
    of x11:
      result = newSoftwareRenderingWindowX11(
        size, title,
        (if screen == -1: defaultScreenX11() else: screenX11(screen)),
        resizable, fullscreen, frameless, transparent,
        (if class == "": title else: class)
      )
    
    of wayland:
      result = newSoftwareRenderingWindowWayland(
        size, title,
        (if screen == -1: defaultScreenWayland() else: screenWayland(screen)),
        resizable, fullscreen, frameless, transparent
      )
    
    else: discard

  elif defined(windows):
    newSoftwareRenderingWindowWinapi(
      size, title,
      (if screen == -1: defaultScreenWinapi() else: screenWinapi(screen)),
      resizable, fullscreen, frameless, transparent
    )
  
  elif defined(macosx):
    newSoftwareRenderingWindowCocoa(
      size, title,
      (if screen == -1: defaultScreenCocoa() else: screenCocoa(screen)),
      resizable, fullscreen, frameless, transparent
    )
