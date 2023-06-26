
type
  Platform* {.pure.} = enum
    x11
    # wayland
    winapi
  
  PlatformSupportDefect* = object of Defect
  PlatformMatchError* = object of CatchableError
    ## raised if tried to force run wayland window on x11 compositor, or if tried to run window without any compositor at all

const defaultPreferedPlatform* =
  when defined(windows): Platform.winapi
  else: Platform.x11


proc getRequiredVulkanExtensions*(platform = defaultPreferedPlatform): seq[string] =
  case platform
  of x11:
    @["VK_KHR_surface", "VK_KHR_xlib_surface"]
  of winapi:
    @["VK_KHR_surface", "VK_KHR_win32_surface"]


proc availablePlatforms*: seq[Platform] =
  when defined(windows):
    @[Platform.winapi]
  elif defined(linux):
    @[Platform.x11]  # todo: detect if x11 is really available
  else:
    @[]
