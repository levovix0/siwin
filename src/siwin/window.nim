import vmath
import ./platforms/any/[window]

export window

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


proc screenCount*(globals: SiwinGlobals): int32 =
  when defined(android):
    1

  elif defined(linux):
    case globals.platform
    of Platform.x11:
      result = cast[SiwinGlobalsX11](globals).screenCountX11()
    of Platform.wayland:
      result = cast[SiwinGlobalsWayland](globals).screenCountWayland()
    else:
      raise SiwinPlatformSupportDefect.newException("Unsupported platform")
  
  elif defined(windows): screenCountWinapi()

proc screen*(globals: SiwinGlobals, number: int32): Screen =
  when defined(android):
    Screen()

  elif defined(linux):
    case globals.platform
    of Platform.x11:
      result = cast[SiwinGlobalsX11](globals).screenX11(number)
    of Platform.wayland:
      result = cast[SiwinGlobalsWayland](globals).screenWayland(number)
    else:
      raise SiwinPlatformSupportDefect.newException("Unsupported platform")
  
  elif defined(windows): screenWinapi(number)

proc defaultScreen*(globals: SiwinGlobals): Screen =
  when defined(android):
    Screen()

  elif defined(linux):
    case globals.platform
    of Platform.x11:
      result = cast[SiwinGlobalsX11](globals).defaultScreenX11()
    of Platform.wayland:
      result = cast[SiwinGlobalsWayland](globals).defaultScreenWayland()
    else:
      raise SiwinPlatformSupportDefect.newException("Unsupported platform")
  
  elif defined(windows): defaultScreenWinapi()


proc newSoftwareRenderingWindow*(
  globals: SiwinGlobals,
  size = ivec2(1280, 720),
  title = "",
  screen: int32 = -1,
  fullscreen = false,
  resizable = true,
  frameless = false,
  transparent = false,

  class = "", # window class (used in x11), equals to title if not specified
): Window =
  when defined(android):
    newSoftwareRenderingWindowAndroid(
      size, title,
      # (if screen == -1: defaultScreenAndroid() else: screenAndroid(screen)),
      resizable, fullscreen, frameless, transparent
    )

  elif defined(linux):
    case globals.platform
    of Platform.x11:
      result = cast[SiwinGlobalsX11](globals).newSoftwareRenderingWindowX11(
        size, title,
        (
          if screen == -1: cast[SiwinGlobalsX11](globals).defaultScreenX11()
          else: cast[SiwinGlobalsX11](globals).screenX11(screen)
        ),
        resizable, fullscreen, frameless, transparent,
        (if class == "": title else: class)
      )
    of Platform.wayland:
      result = cast[SiwinGlobalsWayland](globals).newSoftwareRenderingWindowWayland(
        size, title,
        (
          if screen == -1: cast[SiwinGlobalsWayland](globals).defaultScreenWayland()
          else: cast[SiwinGlobalsWayland](globals).screenWayland(screen)
        ),
        resizable, fullscreen, frameless, transparent
      )
    else:
      raise SiwinPlatformSupportDefect.newException("Unsupported platform")

  elif defined(windows):
    globals.newSoftwareRenderingWindowWinapi(
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


when defined(android):
  proc loadExtensions*() =
    discard
