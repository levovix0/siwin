import vmath
import ./[siwindefs]
import ./platforms
import window

when not siwin_use_lib:
  when defined(android):
    import ./platforms/android/window as androidWindow

  elif defined(linux) or defined(bsd):
    import ./platforms/x11/siwinGlobals as x11SiwinGlobals
    import ./platforms/x11/window as x11Window
    import ./platforms/x11/windowVulkan as x11WindowVulkan

    import ./platforms/wayland/siwinGlobals as waylandSiwinGlobals
    import ./platforms/wayland/window as waylandWindow
    import ./platforms/wayland/windowVulkan as waylandWindowVulkan

  elif defined(windows):
    import ./platforms/winapi/window as winapiWindow
    import ./platforms/winapi/windowVulkan as winapiWindowVulkan



when not siwin_use_lib:
  proc newVulkanWindow*(
    globals: SiwinGlobals,
    vkInstance: pointer,
    size = ivec2(1280, 720),
    title = "",
    screen: int32 = -1,
    resizable = true,
    fullscreen = false,
    frameless = false,
    transparent = false,

    class = "", # window class (used in x11), equals to title if not specified
  ): Window =
    when defined(android):
      # todo
      newOpenglWindowAndroid(
        size, title,
        # (if screen == -1: defaultScreenAndroid() else: screenAndroid(screen)),
        resizable, fullscreen, frameless, transparent, true
      )

    elif defined(linux) or defined(bsd):
      if globals of SiwinGlobalsX11:
        globals.SiwinGlobalsX11.newVulkanWindowX11(
          vkInstance,
          size, title,
          (if screen == -1: globals.SiwinGlobalsX11.defaultScreenX11() else: globals.SiwinGlobalsX11.screenX11(screen)),
          resizable, fullscreen, frameless, transparent,
          (if class == "": title else: class)
        )
      elif globals of SiwinGlobalsWayland:
        globals.SiwinGlobalsWayland.newVulkanWindowWayland(
          vkInstance,
          size, title,
          (if screen == -1: globals.SiwinGlobalsWayland.defaultScreenWayland() else: globals.SiwinGlobalsWayland.screenWayland(screen)),
          resizable, fullscreen, frameless, transparent
        )
      else:
        raise SiwinPlatformSupportDefect.newException("Unsupported platform")

    elif defined(windows):
      newVulkanWindowWinapi(
        vkInstance,
        size, title,
        (if screen == -1: defaultScreenWinapi() else: screenWinapi(screen)),
        resizable, fullscreen, frameless, transparent
      )



proc siwin_new_vulkan_window(
  globals: SiwinGlobals, vkInstance: pointer,
  size_x: cint, size_y: cint, title: cstring, screen: cint,
  fullscreen: cchar, resizable: cchar, frameless: cchar, transparent: cchar,
  winclass: cstring
): Window {.siwin_import_export.} =
  newVulkanWindow(
    globals, vkInstance,
    ivec2(size_x.int32, size_y.int32), $title, screen.int32,
    fullscreen.bool, resizable.bool, frameless.bool, transparent.bool,
    $winclass
  )



proc newVulkanWindow*(
  globals: SiwinGlobals,
  vkInstance: pointer,
  size = ivec2(1280, 720),
  title = "",
  screen: int32 = -1,
  fullscreen = false,
  resizable = true,
  frameless = false,
  transparent = false,

  class = "", # window class (used in x11), equals to title if not specified
): Window {.siwin_export_import.} =
  result = siwin_new_vulkan_window(
    globals, vkInstance,
    size.x, size.y, title.cstring, screen.cint,
    fullscreen.cchar, resizable.cchar, frameless.cchar, transparent.cchar,
    class.cstring,
  )
  GC_ref(result)


proc newVulkanWindow*(
  vkInstance: pointer,
  size = ivec2(1280, 720),
  title = "",
  screen: int32 = -1,
  fullscreen = false,
  resizable = true,
  frameless = false,
  transparent = false,

  class = "", # window class (used in x11), equals to title if not specified
  
  preferedPlatform: Platform = defaultPreferedPlatform(),
): Window =
  newVulkanWindow(newSiwinGlobals(preferedPlatform), vkInstance, size, title, screen, fullscreen, resizable, frameless, transparent, class)
