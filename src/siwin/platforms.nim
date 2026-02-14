import ./[siwindefs]
import ./platforms/any/window


when not siwin_use_lib:
  when defined(android):
    ##
  when defined(linux) or defined(bsd) and not defined(android):
    import ./platforms/wayland/siwinGlobals as waylandGlobals
    import ./platforms/x11/siwinGlobals as x11Globals
  when defined(windows):
    ##
  when defined(macosx):
    ##

const siwin_use_wayland* {.booldefine: "siwin.wayland".} = defined(linux) or defined(bsd)
const siwin_use_x11* {.booldefine: "siwin.x11".} = defined(linux) or defined(bsd)

when siwin_use_pure_enums:
  {.pragma: siwin_enum, pure.}
else:
  {.pragma: siwin_enum.}


type
  Platform* {.siwin_enum.} = enum
    x11 = 0
    wayland
    winapi
    cocoa
    android
  
  SiwinPlatformSupportDefect* = object of Defect
  SiwinPlatformMatchError* = object of CatchableError
    ## raised if tried to force run wayland window on x11 compositor, or if tried to run window without any compositor at all


when not siwin_use_lib:
  proc availablePlatforms*: seq[Platform] =
    when defined(windows):
      @[Platform.winapi]

    elif defined(android):
      @[Platform.android]
    
    elif defined(linux) or defined(bsd):
      when siwin_use_wayland:
        if isWaylandAvailable():
          # prefer wayland if available
          result.add Platform.wayland
      when siwin_use_x11:
        # x11 is available on wayland compositors through XWayland
        result.add Platform.x11
    
    elif defined(macosx):
      @[Platform.cocoa]

    else:
      @[]


  proc defaultPreferedPlatform*: Platform =
    let platforms = availablePlatforms()
    if platforms.len() == 0:
      raise newException(Defect, "No display platform available!")
    else:
      platforms[0]


proc siwin_default_platform(): Platform {.siwin_import_export.} = defaultPreferedPlatform()
proc defaultPreferedPlatform*(): Platform {.siwin_export_import.} = siwin_default_platform()


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
  elif available.len != 0:
    return available[0]
  else:
    raise SiwinPlatformSupportDefect.newException("No platforms available to open a window")


when not siwin_use_lib:
  proc newSiwinGlobals*(preferedPlatform: Platform = defaultPreferedPlatform()): SiwinGlobals =
    when defined(android):
      result = SiwinGlobals()

    elif defined(linux) or defined(bsd):
      case availablePlatforms().platformToUse(preferedPlatform)
      of x11:
        echo "X11"
        return newX11Globals()
      of wayland:
        result = newWaylandGlobals()
        result.SiwinGlobalsWayland.roundtrip()
      else:
        raise SiwinPlatformSupportDefect.newException("Unsupported platform")
    
    elif defined(windows):
      result = SiwinGlobals()
    
    elif defined(macosx):
      result = SiwinGlobals()
    
    else:
      {.error.}


proc siwin_new_globals(platform: Platform): SiwinGlobals {.siwin_import_export.} =
  newSiwinGlobals(platform)

proc newSiwinGlobals*(preferedPlatform: Platform = defaultPreferedPlatform()): SiwinGlobals {.siwin_export_import.} =
  siwin_new_globals(preferedPlatform)


when siwin_build_lib:
  {.push, exportc, cdecl, dynlib.}
  proc siwin_destroy_globals(globals: SiwinGlobals) {.nodestroy.} = GC_unref(globals)
  {.pop.}
