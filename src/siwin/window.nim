import vmath
import ./[siwindefs]
import ./platforms/any/[window as anyWindow]

export anyWindow

when not siwin_use_lib:
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


when not siwin_use_lib:
  proc screenCount*(globals: SiwinGlobals): int32 =
    when defined(android):
      1

    elif defined(linux):
      if globals of SiwinGlobalsX11:
        result = globals.SiwinGlobalsX11.screenCountX11()
      elif globals of SiwinGlobalsWayland:
        result = globals.SiwinGlobalsWayland.screenCountWayland()
      else:
        raise SiwinPlatformSupportDefect.newException("Unsupported platform")
    
    elif defined(windows): screenCountWinapi()

  proc screen*(globals: SiwinGlobals, number: int32): Screen =
    when defined(android):
      Screen()

    elif defined(linux):
      if globals of SiwinGlobalsX11:
        result = globals.SiwinGlobalsX11.screenX11(number)
      elif globals of SiwinGlobalsWayland:
        result = globals.SiwinGlobalsWayland.screenWayland(number)
      else:
        raise SiwinPlatformSupportDefect.newException("Unsupported platform")
    
    elif defined(windows): screenWinapi(number)

  proc defaultScreen*(globals: SiwinGlobals): Screen =
    when defined(android):
      Screen()

    elif defined(linux):
      if globals of SiwinGlobalsX11:
        result = globals.SiwinGlobalsX11.defaultScreenX11()
      elif globals of SiwinGlobalsWayland:
        result = globals.SiwinGlobalsWayland.defaultScreenWayland()
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
      if globals of SiwinGlobalsX11:
        result = globals.SiwinGlobalsX11.newSoftwareRenderingWindowX11(
          size, title,
          (if screen == -1: globals.SiwinGlobalsX11.defaultScreenX11() else: globals.SiwinGlobalsX11.screenX11(screen)),
          resizable, fullscreen, frameless, transparent,
          (if class == "": title else: class)
        )
      elif globals of SiwinGlobalsWayland:
        result = globals.SiwinGlobalsWayland.newSoftwareRenderingWindowWayland(
          size, title,
          (if screen == -1: globals.SiwinGlobalsWayland.defaultScreenWayland() else: globals.SiwinGlobalsWayland.screenWayland(screen)),
          resizable, fullscreen, frameless, transparent
        )
      else:
        raise SiwinPlatformSupportDefect.newException("Unsupported platform")

    elif defined(windows):
      newSoftwareRenderingWindowWinapi(
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



proc siwin_screen_count(globals: SiwinGlobals): cint {.siwin_import_export.} = screenCount(globals)
proc siwin_get_screen(globals: SiwinGlobals, n: cint): Screen {.siwin_import_export.} = screen(globals, n.int32)
proc siwin_default_screen(globals: SiwinGlobals): Screen {.siwin_import_export.} = defaultScreen(globals)


proc siwin_new_software_rendering_window(
  globals: SiwinGlobals,
  size_x: cint, size_y: cint, title: cstring, screen: cint,
  fullscreen: cchar, resizable: cchar, frameless: cchar, transparent: cchar,
  winclass: cstring
): Window {.siwin_import_export.} =
  newSoftwareRenderingWindow(
    globals,
    ivec2(size_x.int32, size_y.int32), $title, screen.int32,
    fullscreen.bool, resizable.bool, frameless.bool, transparent.bool,
    $winclass
  )



proc screenCount*(globals: SiwinGlobals): int32 {.siwin_export_import.} =
  siwin_screen_count(globals).int32
  

proc screen*(globals: SiwinGlobals, number: int32): Screen {.siwin_export_import.} =
  siwin_get_screen(globals, n.cint)

proc defaultScreen*(globals: SiwinGlobals): Screen {.siwin_export_import.} =
  siwin_default_screen(globals)


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
): Window {.siwin_export_import.} =
  result = siwin_new_software_rendering_window(
    globals,
    size.x, size.y, title.cstring, screen.cint,
    fullscreen.cchar, resizable.cchar, frameless.cchar, transparent.cchar,
    class.cstring,
  )
  GC_ref(result)


proc newSoftwareRenderingWindow*(
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
  newSoftwareRenderingWindow(newSiwinGlobals(preferedPlatform), size, title, screen, fullscreen, resizable, frameless, transparent, class)


when siwin_build_lib:
  import std/options
  import ./colorutils
  import ./platforms/any/[clipboards]

  {.push, exportc, cdecl, dynlib.}

  proc siwin_destroy_window(window: Window) = GC_unref(window)

  proc siwin_screen_number(screen: Screen): cint = screen.number.cint
  proc siwin_sreen_width(screen: Screen): cint = screen.width.cint
  proc siwin_sreen_height(screen: Screen): cint = screen.height.cint

  proc siwin_window_closed(window: Window): cchar = window.closed.cchar
  proc siwin_window_opened(window: Window): cchar = window.opened.cchar
  proc siwin_window_close(window: Window) = close(window)
  proc siwin_window_transparent(window: Window): cchar = window.transparent.cchar
  proc siwin_window_frameless(window: Window): cchar = window.frameless.cchar
  proc siwin_window_cursor(window: Window, out_cursor: ptr Cursor) = out_cursor[] = window.cursor
  proc siwin_window_separateTouch(window: Window): cchar = window.separateTouch.cchar
  
  proc siwin_window_size(window: Window, out_size_x, out_size_y: ptr cint) =
    let size = window.size
    out_size_x[] = size.x.cint
    out_size_y[] = size.y.cint
  
  proc siwin_window_pos(window: Window, out_pos_x, out_pos_y: ptr cint) =
    let pos = window.pos
    out_pos_x[] = pos.x.cint
    out_pos_y[] = pos.y.cint
  
  proc siwin_window_fullscreen(window: Window): cchar = window.fullscreen.cchar
  proc siwin_window_maximized(window: Window): cchar = window.maximized.cchar
  proc siwin_window_minimized(window: Window): cchar = window.minimized.cchar
  proc siwin_window_visible(window: Window): cchar = window.visible.cchar
  proc siwin_window_resizable(window: Window): cchar = window.resizable.cchar
  
  proc siwin_window_minSize(window: Window, out_minSize_x, out_minSize_y: ptr cint) =
    let minSize = window.minSize
    out_minSize_x[] = minSize.x.cint
    out_minSize_y[] = minSize.y.cint
  
  proc siwin_window_maxSize(window: Window, out_maxSize_x, out_maxSize_y: ptr cint) =
    let maxSize = window.maxSize
    out_maxSize_x[] = maxSize.x.cint
    out_maxSize_y[] = maxSize.y.cint
  
  proc siwin_window_focused(window: Window): cchar = window.focused.cchar
  proc siwin_window_redraw(window: Window) = window.redraw()
  proc siwin_window_set_frameless(window: Window, v: cchar) = window.frameless = v.bool
  proc siwin_window_set_cursor(window: Window, v: ptr Cursor) = window.cursor = v[]
  proc siwin_window_set_separate_touch(window: Window, v: cchar) = window.separateTouch = v.bool
  proc siwin_window_set_size(window: Window, size_x, size_y: cint) = window.size = ivec2(size_x.int32, size_y.int32)
  proc siwin_window_set_pos(window: Window, pos_x, pos_y: cint) = window.pos = ivec2(pos_x.int32, pos_y.int32)
  proc siwin_window_set_title(window: Window, v: cstring) = window.title = $v
  proc siwin_window_set_fullscreen(window: Window, v: cchar) = window.fullscreen = v.bool
  proc siwin_window_set_maximized(window: Window, v: cchar) = window.maximized = v.bool
  proc siwin_window_set_minimized(window: Window, v: cchar) = window.minimized = v.bool
  proc siwin_window_set_visible(window: Window, v: cchar) = window.visible = v.bool
  proc siwin_window_set_resizable(window: Window, v: cchar) = window.resizable = v.bool
  proc siwin_window_set_min_size(window: Window, v_x, v_y: cint) = window.minSize = ivec2(v_x.int32, v_y.int32)
  proc siwin_window_set_max_size(window: Window, v_x, v_y: cint) = window.maxSize = ivec2(v_x.int32, v_y.int32)
  proc siwin_window_clear_icon(window: Window) = window.icon = nil
  proc siwin_window_set_icon(window: Window, v: ptr PixelBuffer) = window.icon = v[]

  proc siwin_window_start_interactive_move(window: Window, has_pos: cchar, pos_x, pos_y: cfloat) =
    window.startInteractiveMove(if has_pos.bool: some vec2(pos_x.float32, pos_y.float32) else: none Vec2)
  
  proc siwin_window_start_interactive_resize(window: Window, edge: Edge, has_pos: cchar, pos_x, pos_y: cfloat) =
    window.startInteractiveResize(edge, if has_pos.bool: some vec2(pos_x.float32, pos_y.float32) else: none Vec2)
  
  proc siwin_window_show_window_menu(window: Window, has_pos: cchar, pos_x, pos_y: cfloat) =
    window.showWindowMenu(if has_pos.bool: some vec2(pos_x.float32, pos_y.float32) else: none Vec2)

  proc siwin_window_set_input_region(window: Window, pos_x, pos_y, size_x, size_y: cfloat) =
    window.setInputRegion(vec2(pos_x.float32, pos_y.float32), vec2(size_x.float32, size_y.float32))

  proc siwin_window_set_title_region(window: Window, pos_x, pos_y, size_x, size_y: cfloat) =
    window.setTitleRegion(vec2(pos_x.float32, pos_y.float32), vec2(size_x.float32, size_y.float32))

  proc siwin_window_set_border_width(window: Window, innerWidth, outerWidth: cfloat, diagonalSize: cfloat) =
    window.setBorderWidth(innerWidth.float32, outerWidth.float32, diagonalSize.float32)

  proc siwin_window_pixel_buffer(window: Window, out_buffer: ptr PixelBuffer) = out_buffer[] = window.pixelBuffer
  proc siwin_window_make_current(window: Window) = window.makeCurrent()
  
  proc siwin_window_set_vsync(window: Window, v: cchar): cchar =
    try: window.`vsync=`(v.bool, false)
    except: return 1.cchar

  proc siwin_window_vulkan_surface(window: Window): pointer = window.vulkanSurface
  proc siwin_window_clipboard(window: Window): Clipboard = window.clipboard
  proc siwin_window_selection_clipboard(window: Window): Clipboard = window.selectionClipboard
  proc siwin_window_dragndrop_clipboard(window: Window): Clipboard = window.dragndropClipboard
  proc siwin_window_set_drag_status(window: Window, v: DragStatus) = window.dragStatus = v
  proc siwin_window_first_step(window: Window, makeVisible: cchar) = window.firstStep(makeVisible.bool)
  proc siwin_window_step(window: Window) = window.step()
  proc siwin_window_run(window: Window, makeVisible: cchar) = window.run(makeVisible.bool)

  proc siwin_window_set_event_handler(window: Window, eventHandler: ptr WindowEventsHandler) = window.eventsHandler = eventHandler[]

  {.pop.}

