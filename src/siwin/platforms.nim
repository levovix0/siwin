import ./[siwindefs]
import ./platforms/any/window
when defined(android):
  ##
when defined(linux) and not defined(android):
  import ./platforms/wayland/globals as waylandGlobals
  import ./platforms/x11/siwinGlobals as x11Globals
when defined(windows):
  ##
when defined(macosx):
  ##


when siwin_use_pure_enums:
  {.pragma: siwin_enum, pure.}
else:
  {.pragma: siwin_enum.}


type
  Platform* {.siwin_enum.} = enum
    x11
    wayland
    winapi
    cocoa
    android
  
  SiwinPlatformSupportDefect* = object of Defect
  SiwinPlatformMatchError* = object of CatchableError
    ## raised if tried to force run wayland window on x11 compositor, or if tried to run window without any compositor at all


proc availablePlatforms*: seq[Platform] =
  when defined(windows):
    @[Platform.winapi]

  elif defined(android):
    @[Platform.android]
  
  elif defined(linux):
    waylandGlobals.init()
    # todo: detect if x11 is really available

    if waylandGlobals.waylandAvailable:
      @[Platform.wayland, Platform.x11]
    else:
      @[Platform.x11]
  
  elif defined(macosx):
    @[Platform.cocoa]

  else:
    @[]


proc defaultPreferedPlatform*: Platform =
  availablePlatforms()[0]


proc getRequiredVulkanExtensions*(platform = defaultPreferedPlatform()): seq[string] =
  case platform
  of x11:
    @["VK_KHR_surface", "VK_KHR_xlib_surface"]
  of wayland:
    @["VK_KHR_surface", "VK_KHR_wayland_surface"]
  of winapi:
    @["VK_KHR_surface", "VK_KHR_win32_surface"]
  of cocoa:
    @[]  # todo
  of android:
    @[]  # todo


proc platformToUse*(available: seq[Platform], prefered: Platform): Platform =
  if prefered in available:
    return prefered

  if prefered == Platform.wayland and Platform.x11 in available:
    return Platform.x11
  
  if available.len != 0:
    return available[0]
  else:
    raise SiwinPlatformSupportDefect.newException("No platforms available to open a window")


proc newSiwinGlobals*(preferedPlatform: Platform = defaultPreferedPlatform()): SiwinGlobals =
  when defined(android):
    ##

  elif defined(linux):
    case availablePlatforms().platformToUse(preferedPlatform)
    of x11:
      return x11Globals.newX11Globals()
    # of wayland:
    #   waylandGlobals.newSiwinGlobalsWayland()
    else:
      raise SiwinPlatformSupportDefect.newException("Unsupported platform")

