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
    import ./platforms/x11/windowOpengl as x11WindowOpengl
    
    import ./platforms/wayland/siwinGlobals as waylandSiwinGlobals
    import ./platforms/wayland/window as waylandWindow
    import ./platforms/wayland/windowOpengl as waylandWindowOpengl

  elif defined(windows):
    import ./platforms/winapi/window as winapiWindow
    import ./platforms/winapi/windowOpengl as winapiWindowOpengl

  elif defined(macosx):
    import ./platforms/cocoa/window as cocoaWindow



when not siwin_use_lib:
  proc newOpenglWindow*(
    globals: SiwinGlobals,
    size = ivec2(1280, 720),
    title = "",
    screen: int32 = -1,
    fullscreen = false,
    resizable = true,
    frameless = false,
    transparent = false,
    vsync = true,

    class = "", # X11 window class / Wayland app ID; defaults to title
  ): Window =
    when defined(android):
      newOpenglWindowAndroid(
        size, title,
        # (if screen == -1: defaultScreenAndroid() else: screenAndroid(screen)),
        resizable, fullscreen, frameless, transparent, vsync
      )

    elif defined(linux) or defined(bsd):
      if globals of SiwinGlobalsX11:
        result = globals.SiwinGlobalsX11.newOpenglWindowX11(
          size, title,
          (if screen == -1: globals.SiwinGlobalsX11.defaultScreenX11() else: globals.SiwinGlobalsX11.screenX11(screen)),
          resizable, fullscreen, frameless, transparent, vsync,
          (if class == "": title else: class)
        )
      elif globals of SiwinGlobalsWayland:
        result = globals.SiwinGlobalsWayland.newOpenglWindowWayland(
          size, title,
          (if screen == -1: globals.SiwinGlobalsWayland.defaultScreenWayland() else: globals.SiwinGlobalsWayland.screenWayland(screen)),
          resizable, fullscreen, frameless, transparent, vsync,
          class = class
        )
      else:
        raise SiwinPlatformSupportDefect.newException("Unsupported platform")

    elif defined(windows):
      if not (globals of SiwinGlobalsWinapi):
        raise SiwinPlatformSupportDefect.newException("Unsupported platform")
      result = newOpenglWindowWinapi(
        size, title,
        (if screen == -1: defaultScreenWinapi() else: screenWinapi(screen)),
        resizable, fullscreen, frameless, transparent, vsync,
        globals = globals.SiwinGlobalsWinapi,
      )

    elif defined(macosx):
      newOpenglWindowCocoa(
        size, title,
        (if screen == -1: defaultScreenCocoa() else: screenCocoa(screen)),
        resizable, fullscreen, frameless, transparent, vsync
      )

  when defined(linux) or defined(bsd):
    proc newOpenglLayerSurfaceWindow*(
      globals: SiwinGlobals,
      size = ivec2(1280, 32),
      title = "",
      screen: int32 = -1,
      config: waylandWindow.LayerSurfaceConfig,
      transparent = false,
      vsync = true,
    ): Window =
      ## Creates an OpenGL window backed by a Wayland layer-shell surface.
      ##
      ## `config` controls the layer, anchors, margins, exclusive zone, keyboard
      ## interactivity, and namespace. A `screen` value of `-1` selects the
      ## default Wayland output.
      ##
      ## Raises `SiwinPlatformSupportDefect` when `globals` uses the X11 backend.
      if globals of SiwinGlobalsWayland:
        let waylandGlobals = globals.SiwinGlobalsWayland
        result = waylandGlobals.newOpenglLayerSurfaceWindowWayland(
          size = size,
          title = title,
          screen =
            if screen == -1:
              waylandGlobals.defaultScreenWayland()
            else:
              waylandGlobals.screenWayland(screen),
          config = config,
          transparent = transparent,
          vsync = vsync,
        )
      else:
        raise SiwinPlatformSupportDefect.newException(
          "Layer-shell surfaces require the Wayland platform"
        )



proc siwin_new_opengl_window(
  globals: SiwinGlobals,
  size_x: cint, size_y: cint, title: cstring, screen: cint,
  fullscreen: cchar, resizable: cchar, frameless: cchar, transparent: cchar, vsync: cchar,
  winclass: cstring
): Window {.siwin_import_export.} =
  newOpenglWindow(
    globals,
    ivec2(size_x.int32, size_y.int32), $title, screen.int32,
    fullscreen.bool, resizable.bool, frameless.bool, transparent.bool, vsync.bool,
    $winclass
  )



proc newOpenglWindow*(
  globals: SiwinGlobals,
  size = ivec2(1280, 720),
  title = "",
  screen: int32 = -1,
  fullscreen = false,
  resizable = true,
  frameless = false,
  transparent = false,
  vsync = true,

  class = "", # X11 window class / Wayland app ID; defaults to title
): Window {.siwin_export_import.} =
  result = siwin_new_opengl_window(
    globals,
    size.x, size.y, title.cstring, screen.cint,
    fullscreen.cchar, resizable.cchar, frameless.cchar, transparent.cchar, vsync.cchar,
    class.cstring,
  )
  GC_ref(result)


proc newOpenglWindow*(
  size = ivec2(1280, 720),
  title = "",
  screen: int32 = -1,
  fullscreen = false,
  resizable = true,
  frameless = false,
  transparent = false,
  vsync = true,

  class = "", # X11 window class / Wayland app ID; defaults to title
  
  preferedPlatform: Platform = defaultPreferedPlatform(),
): Window =
  newOpenglWindow(newSiwinGlobals(preferedPlatform), size, title, screen, fullscreen, resizable, frameless, transparent, vsync, class)
