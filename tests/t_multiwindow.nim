import unittest
import opengl, pixie
import siwin

when defined(linux) or defined(bsd):
  import std/importutils
  import x11/xlib
  import x11/x except Window
  import siwin/platforms/any/window as anyWindow
  import siwin/platforms/wayland/protocol
  import siwin/platforms/wayland/window as waylandWindow
  import siwin/platforms/x11/window as x11Window

  privateAccess anyWindow.Window
  privateAccess waylandWindow.WindowWaylandObj

proc testGlobals(): SiwinGlobals =
  newSiwinGlobals()

let globals = testGlobals()

type CloseMode = enum
  manualClose
  compositorTitlebarClose

proc safeClose(window: Window) =
  close(window)

proc requestCompositorClose(window: Window): bool =
  when defined(linux) or defined(bsd):
    if window of x11Window.WindowX11:
      let
        x11win = x11Window.WindowX11(window)
        display = cast[ptr Display](x11Window.nativeDisplayHandle(x11win))
      if display == nil:
        return false

      let
        handle = x11Window.nativeWindowHandle(x11win).culong
        wmProtocols = display.XInternAtom("WM_PROTOCOLS", 0)
        wmDeleteWindow = display.XInternAtom("WM_DELETE_WINDOW", 0)
      if wmDeleteWindow == 0:
        return false

      var event: XEvent
      event.theType = ClientMessage
      event.xclient.messageType = wmProtocols
      event.xclient.window = handle
      event.xclient.display = display
      event.xclient.format = 32
      event.xclient.data.l[0] = wmDeleteWindow.clong

      result = display.XSendEvent(handle, 0, 0, event.addr) != 0
      discard XFlush display
      return
    if window of waylandWindow.WindowWayland:
      let waylandWin = waylandWindow.WindowWayland(window)
      if waylandWin.xdgToplevel.proxy.raw == nil:
        return false
      let callbacks =
        cast[ptr `Xdg_toplevel / Callbacks`](waylandWin.xdgToplevel.proxy.raw.impl)
      if callbacks == nil or callbacks.close == nil:
        return false
      callbacks.close()
      return true
  false

proc nativeResourcesReleased(window: Window): bool =
  when defined(linux) or defined(bsd):
    if window of x11Window.WindowX11:
      return x11Window.nativeWindowHandle(x11Window.WindowX11(window)) == 0
    if window of waylandWindow.WindowWayland:
      return waylandWindow.WindowWayland(window).surface.proxy.raw == nil
  true

proc runCloseDirection(
    closeLeftFirst: bool, closeMode = CloseMode.manualClose
): tuple[otherTicksAfterFirstClose: int, firstObservedClosed: bool] =
  let win1 =
    globals.newOpenglWindow(title = "1", transparent = true, class = "siwin example")
  let win2 = globals.newOpenglWindow(
    title = "2", size = ivec2(800, 600), class = "siwin example"
  )
  loadExtensions()

  var
    ticks1 = 0
    ticks2 = 0
    closeIssued = false
    firstObservedClosed = false
    otherTicksAfterFirstClose = 0
    closeEvents1 = 0
    closeEvents2 = 0

  proc forceCloseBoth() =
    if win1.opened:
      safeClose(win1)
    if win2.opened:
      safeClose(win2)

  proc closeRequestedWindow(window: Window) =
    case closeMode
    of CloseMode.manualClose:
      safeClose(window)
    of CloseMode.compositorTitlebarClose:
      if not requestCompositorClose(window):
        raise CatchableError.newException(
          "Compositor/titlebar close simulation unsupported"
        )

  let win1eh = WindowEventsHandler(
    onClose: proc(e: CloseEvent) =
      inc closeEvents1
    ,
    onResize: proc(e: ResizeEvent) =
      makeCurrent e.window
      glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    ,
    onRender: proc(e: RenderEvent) =
      makeCurrent e.window
      glClearColor 0.3, 0.3, 0.3, 0.7
      glClear GlColorBufferBit or GlDepthBufferBit
    ,
    onKey: proc(e: KeyEvent) =
      if e.pressed and not e.generated and e.key == Key.escape:
        forceCloseBoth()
    ,
    onTick: proc(e: TickEvent) =
      inc ticks1
      if not closeLeftFirst:
        if not closeIssued and ticks1 >= 60:
          closeIssued = true
          closeRequestedWindow(win2)
        if not win2.opened:
          check nativeResourcesReleased(win2)
          firstObservedClosed = true
          inc otherTicksAfterFirstClose
          if otherTicksAfterFirstClose >= 40 and win1.opened:
            safeClose(win1)
      if ticks1 + ticks2 > 1200:
        forceCloseBoth()
    ,
  )

  let win2eh = WindowEventsHandler(
    onClose: proc(e: CloseEvent) =
      inc closeEvents2
    ,
    onResize: proc(e: ResizeEvent) =
      makeCurrent e.window
      glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    ,
    onRender: proc(e: RenderEvent) =
      makeCurrent e.window
      glClearColor 0.7, 0.7, 0.7, 1
      glClear GlColorBufferBit or GlDepthBufferBit
    ,
    onKey: proc(e: KeyEvent) =
      if e.pressed and not e.generated and e.key == Key.escape:
        forceCloseBoth()
    ,
    onTick: proc(e: TickEvent) =
      inc ticks2
      if closeLeftFirst:
        if not closeIssued and ticks2 >= 60:
          closeIssued = true
          closeRequestedWindow(win1)
        if not win1.opened:
          check nativeResourcesReleased(win1)
          firstObservedClosed = true
          inc otherTicksAfterFirstClose
          if otherTicksAfterFirstClose >= 40 and win2.opened:
            safeClose(win2)
      if ticks1 + ticks2 > 1200:
        forceCloseBoth()
    ,
  )

  runMultiple((win1, win1eh, true), (win2, win2eh, true))

  check closeEvents1 == 1
  check closeEvents2 == 1

  result = (
    otherTicksAfterFirstClose: otherTicksAfterFirstClose,
    firstObservedClosed: firstObservedClosed,
  )

proc runCloseLeftKeepsRightAlive(
    closeMode: CloseMode
): tuple[otherTicksAfterFirstClose: int, firstObservedClosed: bool] =
  runCloseDirection(closeLeftFirst = true, closeMode = closeMode)

test "manual close left then keep right alive":
  block runManualCloseLeft:
    var stats: tuple[otherTicksAfterFirstClose: int, firstObservedClosed: bool]
    try:
      stats = runCloseLeftKeepsRightAlive(CloseMode.manualClose)
    except CatchableError:
      skip()
      break runManualCloseLeft
    check stats.firstObservedClosed
    check stats.otherTicksAfterFirstClose >= 20

test "close right then keep left alive":
  block runCloseRight:
    var stats: tuple[otherTicksAfterFirstClose: int, firstObservedClosed: bool]
    try:
      stats = runCloseDirection(closeLeftFirst = false)
    except CatchableError:
      skip()
      break runCloseRight
    check stats.firstObservedClosed
    check stats.otherTicksAfterFirstClose >= 20

test "compositor/titlebar close left then keep right alive":
  block runCompositorCloseLeft:
    var stats: tuple[otherTicksAfterFirstClose: int, firstObservedClosed: bool]
    try:
      stats = runCloseLeftKeepsRightAlive(CloseMode.compositorTitlebarClose)
    except CatchableError:
      skip()
      break runCompositorCloseLeft
    check stats.firstObservedClosed
    check stats.otherTicksAfterFirstClose >= 20

test "compositor/titlebar close right then keep left alive":
  block runCompositorCloseRight:
    var stats: tuple[otherTicksAfterFirstClose: int, firstObservedClosed: bool]
    try:
      stats = runCloseDirection(
        closeLeftFirst = false, closeMode = CloseMode.compositorTitlebarClose
      )
    except CatchableError:
      skip()
      break runCompositorCloseRight
    check stats.firstObservedClosed
    check stats.otherTicksAfterFirstClose >= 20

test "2 windows at once":
  let win1 =
    globals.newOpenglWindow(title = "1", transparent = true, class = "siwin example")
  let win2 = globals.newOpenglWindow(
    title = "2", size = ivec2(800, 600), class = "siwin example"
  )
  loadExtensions()
  var ticks = 0

  let win1eh = WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      makeCurrent e.window
      glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    ,
    onRender: proc(e: RenderEvent) =
      makeCurrent e.window
      glClearColor 0.3, 0.3, 0.3, 0.7
      glClear GlColorBufferBit or GlDepthBufferBit
    ,
    onClick: proc(e: ClickEvent) =
      if e.double:
        close (if win2.opened: win2 else: e.window)
    ,
    onKey: proc(e: KeyEvent) =
      if e.pressed and not e.generated:
        case e.key
        of Key.escape:
          close win1
          close win2
        else:
          discard
    ,
    onTick: proc(e: TickEvent) =
      inc ticks
      if ticks > 180:
        close win1
        close win2
    ,
  )
  var win2eh = win1eh

  win2eh.onRender = proc(e: RenderEvent) =
    makeCurrent e.window
    glClearColor 0.7, 0.7, 0.7, 1
    glClear GlColorBufferBit or GlDepthBufferBit

  win2eh.onClick = proc(e: ClickEvent) =
    if e.double:
      close (if win1.opened: win1 else: e.window)

  runMultiple((win1, win1eh, true), (win2, win2eh, true))
