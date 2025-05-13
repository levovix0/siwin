import vmath
import window

when defined(android):
  import ./platforms/android/window as androidWindow

elif defined(linux):
  import ./platforms
  
  import ./platforms/x11/siwinGlobals as x11SiwinGlobals
  import ./platforms/x11/window as x11Window
  import ./platforms/x11/windowOpengl as x11WindowOpengl
  
  import ./platforms/wayland/siwinGlobals as waylandSiwinGlobals
  import ./platforms/wayland/window as waylandWindow
  import ./platforms/wayland/windowOpengl as waylandWindowOpengl

elif defined(windows):
  import ./platforms/winapi/windowOpengl as winapiWindowOpengl

elif defined(macosx):
  import ./platforms/cocoa/window as cocoaWindow


proc newOpenglWindow*(
  globals: SiwinGlobals,
  size = ivec2(1280, 720),
  title = "",
  screen = -1.Screen,
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
  vsync = true,

  class = "", # window class (used in x11), equals to title if not specified
): Window =
  when defined(android):
    newOpenglWindowAndroid(
      size, title,
      # screen,
      resizable, fullscreen, frameless, transparent, vsync
    )

  elif defined(linux):
    case globals.platform
    of Platform.x11:
      result = globals.SiwinGlobalsX11.newOpenglWindowX11(
        size, title, screen,
        resizable, fullscreen, frameless, transparent, vsync,
        (if class == "": title else: class)
      )
    of Platform.wayland:
      result = globals.SiwinGlobalsWayland.newOpenglWindowWayland(
        size, title, screen,
        resizable, fullscreen, frameless, transparent, vsync
      )
    else:
      raise SiwinPlatformSupportDefect.newException("Unsupported platform")

  elif defined(windows):
    globals.newOpenglWindowWinapi(
      size, title, screen,
      resizable, fullscreen, frameless, transparent, vsync
    )

  elif defined(macosx):
    newOpenglWindowCocoa(
      size, title, screen,
      resizable, fullscreen, frameless, transparent, vsync
    )
