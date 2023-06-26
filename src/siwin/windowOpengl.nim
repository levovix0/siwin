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
      defaultScreenX11(),
      resizable, fullscreen, frameless, transparent, vsync,
      (if class == "": title else: class)
    )
  elif defined(windows):
    newOpenglWindowWinapi(
      size, title,
      defaultScreenWinapi(),
      resizable, fullscreen, frameless, transparent, vsync
    )
