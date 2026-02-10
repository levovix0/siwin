import vmath
import ./[siwindefs]
import window
import ./platforms

when not siwin_use_lib:
  when defined(macosx):
    import ./platforms/cocoa/window as cocoaWindow

when not siwin_use_lib:
  proc newMetalWindow*(
    globals: SiwinGlobals,
    size = ivec2(1280, 720),
    title = "",
    screen: int32 = -1,
    fullscreen = false,
    resizable = true,
    frameless = false,
    transparent = false,
  ): Window =
    when defined(macosx):
      newMetalWindowCocoa(
        size, title,
        (if screen == -1: defaultScreenCocoa() else: screenCocoa(screen)),
        resizable, fullscreen, frameless, transparent
      )
    else:
      raise SiwinPlatformSupportDefect.newException("Metal windows are supported only on macOS")

proc siwin_new_metal_window(
  globals: SiwinGlobals,
  size_x: cint, size_y: cint, title: cstring, screen: cint,
  fullscreen: cchar, resizable: cchar, frameless: cchar, transparent: cchar,
): Window {.siwin_import_export.} =
  newMetalWindow(
    globals,
    ivec2(size_x.int32, size_y.int32), $title, screen.int32,
    fullscreen.bool, resizable.bool, frameless.bool, transparent.bool
  )

proc newMetalWindow*(
  globals: SiwinGlobals,
  size = ivec2(1280, 720),
  title = "",
  screen: int32 = -1,
  fullscreen = false,
  resizable = true,
  frameless = false,
  transparent = false,
): Window {.siwin_export_import.} =
  result = siwin_new_metal_window(
    globals,
    size.x, size.y, title.cstring, screen.cint,
    fullscreen.cchar, resizable.cchar, frameless.cchar, transparent.cchar,
  )
  GC_ref(result)

proc newMetalWindow*(
  size = ivec2(1280, 720),
  title = "",
  screen: int32 = -1,
  fullscreen = false,
  resizable = true,
  frameless = false,
  transparent = false,
  preferedPlatform: Platform = defaultPreferedPlatform(),
): Window =
  newMetalWindow(newSiwinGlobals(preferedPlatform), size, title, screen, fullscreen, resizable, frameless, transparent)
