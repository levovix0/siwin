import ./platforms/wayland/globals as waylandGlobals

type
  Platform* {.pure.} = enum
    x11
    wayland
    winapi
    # cocoa
  
  PlatformSupportDefect* = object of Defect
  PlatformMatchError* = object of CatchableError
    ## raised if tried to force run wayland window on x11 compositor, or if tried to run window without any compositor at all

const defaultPreferedPlatform* =
  when defined(windows): Platform.winapi
  else: Platform.wayland


proc getRequiredVulkanExtensions*(platform = defaultPreferedPlatform): seq[string] =
  case platform
  of x11:
    @["VK_KHR_surface", "VK_KHR_xlib_surface"]
  of wayland:
    @["VK_KHR_surface", "VK_KHR_wayland_surface"]
  of winapi:
    @["VK_KHR_surface", "VK_KHR_win32_surface"]


proc availablePlatforms*: seq[Platform] =
  when defined(windows):
    @[Platform.winapi]
  
  elif defined(linux):
    waylandGlobals.init()
    # todo: detect if x11 is really available
    
    if waylandGlobals.waylandAvailable:
      @[Platform.wayland, Platform.x11]
    else:
      @[Platform.x11]

  else:
    @[]


proc platformToUse*(available: seq[Platform], prefered: Platform): Platform =
  if prefered in available:
      return prefered

  if prefered == Platform.wayland and Platform.x11 in available:
    return Platform.x11

  raise PlatformSupportDefect.newException("Platform " & $prefered & " is not supported")
