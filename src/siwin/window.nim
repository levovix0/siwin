import vmath
import ./platforms/any/window
import ./platforms
export window
when defined(linux):
  import ./platforms/x11/window as x11Window
elif defined(windows):
  import ./platforms/winapi/window as winapiWindow

proc newSoftwareRenderingWindow*(
  size = ivec2(1280, 720),
  title = "",
  fullscreen = false,
  frameless = false,
  transparent = false,
  preferedPlatform = defaultPreferedPlatform,

  class = "", # window class (used in x11), equals to title if not specified
): Window =
  when defined(linux):
    newSoftwareRenderingWindowX11(
      size, title,
      defaultScreenX11(),
      fullscreen, frameless, transparent,
      (if class == "": title else: class)
    )
  elif defined(windows):
    newSoftwareRenderingWindowWinapi(
      size, title,
      defaultScreenWinapi(),
      fullscreen, frameless, transparent
    )


proc newOpenglWindow*(
  size = ivec2(1280, 720),
  title = "",
  fullscreen = false,
  frameless = false,
  transparent = false,
  vsync = true,
  preferedPlatform = defaultPreferedPlatform,

  class = "", # window class (used in x11), equals to title if not specified
): Window =
  when defined(linux):
    newOpenglWindowX11(
      size, title,
      defaultScreenX11(),
      fullscreen, frameless, transparent, vsync,
      (if class == "": title else: class)
    )
  elif defined(windows):
    newOpenglWindowWinapi(
      size, title,
      defaultScreenWinapi(),
      fullscreen, frameless, transparent, vsync
    )
