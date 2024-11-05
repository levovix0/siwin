import ./[siwindefs]
when defined(nimcheck) or defined(nimsuggest):
  discard
elif defined(linux) and not defined(android):
  import ./platforms/wayland/globals as waylandGlobals


when siwin_use_pure_enums:
  {.pragma: siwinPureEnum, pure.}
else:
  {.pragma: siwinPureEnum.}


type
  Platform* {.siwinPureEnum.} = enum
    x11
    wayland
    winapi
    cocoa
    android
  
  PlatformSupportDefect* = object of Defect
  PlatformMatchError* = object of CatchableError
    ## raised if tried to force run wayland window on x11 compositor, or if tried to run window without any compositor at all


proc availablePlatforms*: seq[Platform] =
  when defined(nimcheck) or defined(nimsuggest):
    discard

  elif defined(windows):
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

  raise PlatformSupportDefect.newException("Platform " & $prefered & " is not supported")
