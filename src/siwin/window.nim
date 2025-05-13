import vmath
import ./platforms/any/window as anyWindow

export anyWindow

when defined(android):
  import ./platforms/android/window as androidWindow

elif defined(linux):
  import ./platforms
  
  import ./platforms/x11/siwinGlobals as x11SiwinGlobals
  import ./platforms/x11/window as x11Window
  import ./platforms/wayland/siwinGlobals as waylandSiwinGlobals
  import ./platforms/wayland/window as waylandWindow

elif defined(windows):
  import ./platforms/winapi/window as winapiWindow

elif defined(macosx):
  import ./platforms/cocoa/window as cocoaWindow


proc newSoftwareRenderingWindow*(
  globals: SiwinGlobals,
  size = ivec2(1280, 720),
  title = "",
  screen = -1.Screen,
  fullscreen = false,
  resizable = true,
  frameless = false,
  transparent = false,

  class = "", # window class (used in x11), equals to title if not specified
): Window =
  when defined(android):
    newSoftwareRenderingWindowAndroid(
      size, title,
      # screen,
      resizable, fullscreen, frameless, transparent
    )

  elif defined(linux):
    case globals.platform
    of Platform.x11:
      result = cast[SiwinGlobalsX11](globals).newSoftwareRenderingWindowX11(
        size, title, screen,
        resizable, fullscreen, frameless, transparent,
        (if class == "": title else: class)
      )
    of Platform.wayland:
      result = cast[SiwinGlobalsWayland](globals).newSoftwareRenderingWindowWayland(
        size, title, screen,
        resizable, fullscreen, frameless, transparent
      )
    else:
      raise SiwinPlatformSupportDefect.newException("Unsupported platform")

  elif defined(windows):
    globals.newSoftwareRenderingWindowWinapi(
      size, title, screen,
      resizable, fullscreen, frameless, transparent
    )
  
  elif defined(macosx):
    newSoftwareRenderingWindowCocoa(
      size, title, screen,
      resizable, fullscreen, frameless, transparent
    )


when defined(android):
  proc loadExtensions*() =
    discard
