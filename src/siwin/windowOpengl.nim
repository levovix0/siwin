import vmath
import window
import ./platforms

when defined(nimcheck) or defined(nimsuggest):
  discard
elif defined(android):
  import ./platforms/android/window as androidWindow
elif defined(linux):
  import ./platforms/x11/window as x11Window
  import ./platforms/x11/windowOpengl as x11WindowOpengl
  import ./platforms/wayland/window as waylandWindow
  import ./platforms/wayland/windowOpengl as waylandWindowOpengl
elif defined(windows):
  import ./platforms/winapi/window as winapiWindow
  import ./platforms/winapi/windowOpengl as winapiWindowOpengl
elif defined(macosx):
  import ./platforms/cocoa/window as cocoaWindow


proc newOpenglWindow*(
  size = ivec2(1280, 720),
  title = "",
  screen: int32 = -1,
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
  vsync = true,
  preferedPlatform = defaultPreferedPlatform(),

  class = "", # window class (used in x11), equals to title if not specified
): Window =
  when defined(nimcheck) or defined(nimsuggest):
    discard

  elif defined(android):
    newOpenglWindowAndroid(
      size, title,
      # (if screen == -1: defaultScreenAndroid() else: screenAndroid(screen)),
      resizable, fullscreen, frameless, transparent, vsync
    )

  elif defined(linux):
    case availablePlatforms().platformToUse(preferedPlatform)
    of x11:
      result = newOpenglWindowX11(
        size, title,
        (if screen == -1: defaultScreenX11() else: screenX11(screen)),
        resizable, fullscreen, frameless, transparent, vsync,
        (if class == "": title else: class)
      )
    
    of wayland:
      result = newOpenglWindowWayland(
        size, title,
        (if screen == -1: defaultScreenWayland() else: screenWayland(screen)),
        resizable, fullscreen, frameless, transparent, vsync
      )
    
    else: discard

  elif defined(windows):
    newOpenglWindowWinapi(
      size, title,
      (if screen == -1: defaultScreenWinapi() else: screenWinapi(screen)),
      resizable, fullscreen, frameless, transparent, vsync
    )

  elif defined(macosx):
    newOpenglWindowCocoa(
      size, title,
      (if screen == -1: defaultScreenCocoa() else: screenCocoa(screen)),
      resizable, fullscreen, frameless, transparent, vsync
    )
