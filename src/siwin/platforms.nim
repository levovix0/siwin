import ./[siwindefs]
import ./platforms/any/window
when defined(android):
  ##
when defined(linux) and not defined(android):
  import ./platforms/wayland/siwinGlobals as waylandGlobals
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
  SiwinPlatformSupportDefect* = object of Defect
  SiwinPlatformMatchError* = object of CatchableError
    ## raised if tried to force run wayland window on x11 compositor, or if tried to run window without any compositor at all


proc availablePlatforms*: seq[Platform] =
  when defined(windows):
    @[Platform.winapi]

  elif defined(android):
    @[Platform.android]
  
  elif defined(linux):
    if isWaylandAvailable():
      @[Platform.wayland, Platform.x11]
      # x11 is available on wayland compositors through XWayland
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
    result = create(SiwinGlobalsObj)
    result.platform = Platform.android

  elif defined(linux):
    case availablePlatforms().platformToUse(preferedPlatform)
    of x11:
      return newX11Globals()
    of wayland:
      result = newWaylandGlobals()
      cast[SiwinGlobalsWayland](result).roundtrip()
    else:
      raise SiwinPlatformSupportDefect.newException("Unsupported platform")
  
  elif defined(windows):
    result = create(SiwinGlobalsObj)
    result.platform = Platform.winapi
  
  elif defined(macosx):
    result = create(SiwinGlobalsObj)
    result.platform = Platform.cocoa
  
  else:
    {.error.}


proc destroy*(globals: SiwinGlobals) =
  when defined(android):
    dealloc globals

  elif defined(linux):
    case globals.platform
    of Platform.x11:
      x11Globals.`=destroy`(cast[SiwinGlobalsX11](globals)[])
    of Platform.wayland:
      waylandGlobals.`=destroy`(cast[SiwinGlobalsWayland](globals)[])
    else: discard
    dealloc globals
  
  elif defined(windows):
    dealloc globals
  
  elif defined(macosx):
    dealloc globals
  
  else:
    {.error.}
