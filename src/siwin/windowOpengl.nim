import vmath
import window
import ./platforms
when defined(linux):
  import ./platforms/x11/window as x11Window
  import ./platforms/x11/windowOpengl as x11WindowOpengl
elif defined(windows):
  import ./platforms/winapi/window as winapiWindow
  import ./platforms/winapi/windowOpengl as winapiWindowOpengl


proc newOpenglWindow*(
  size = ivec2(1280, 720),
  title = "",
  screen: int32 = -1,
  resizable = true,
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
      (if screen == -1: defaultScreenX11() else: screenX11(screen)),
      resizable, fullscreen, frameless, transparent, vsync,
      (if class == "": title else: class)
    )
  elif defined(windows):
    newOpenglWindowWinapi(
      size, title,
      (if screen == -1: defaultScreenWinapi() else: screenWinapi(screen)),
      resizable, fullscreen, frameless, transparent, vsync
    )
