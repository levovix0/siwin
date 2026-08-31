import opengl, vmath, siwin

let globals = newSiwinGlobals(
  preferedPlatform = (when defined(linux): x11 else: defaultPreferedPlatform())
)

let win1 = globals.newOpenglWindow(
  size = ivec2(640, 420),
  title = "siwin multiwindow: window 1",
)
let win2 = globals.newOpenglWindow(
  size = ivec2(640, 420),
  title = "siwin multiwindow: window 2",
)

# Avoid total overlap so both windows are obvious at startup.
win1.pos = ivec2(80, 80)
win2.pos = ivec2(430, 160)

loadExtensions() # opengl

proc closeBoth() =
  if win1.opened:
    close win1
  if win2.opened:
    close win2

proc makeEventsHandler(
  clearR, clearG, clearB: GlFloat
): WindowEventsHandler =
  WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      makeCurrent e.window
      glViewport(0, 0, e.size.x.GLsizei, e.size.y.GLsizei)
    ,
    onRender: proc(e: RenderEvent) =
      makeCurrent e.window
      glClearColor(clearR, clearG, clearB, 1.0)
      glClear(GlColorBufferBit or GlDepthBufferBit)
    ,
    onTick: proc(e: TickEvent) =
      redraw e.window
    ,
    onKey: proc(e: KeyEvent) =
      if e.pressed and not e.generated and e.key == Key.escape:
        closeBoth()
  )

runMultiple(
  (window: win1, eventsHandler: makeEventsHandler(0.18, 0.33, 0.82), makeVisible: true),
  (window: win2, eventsHandler: makeEventsHandler(0.82, 0.29, 0.20), makeVisible: true),
)
