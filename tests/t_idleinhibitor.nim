when not defined(linux):
  {.error: "zwp_idle_inhibitor_v1 only works on Wayland (Linux)".}

import std/[unittest]
import siwin, opengl
import siwin/platforms/wayland/[siwinGlobals, window, windowOpengl]

test "zwp_idle_inhibitor_v1":
  let globals = newWaylandGlobals()
  roundtrip(globals)
  let window = globals.newOpenglWindowWayland(
    kind = WindowWaylandKind.XdgSurface,
    screen = globals.defaultScreenWayland,
  )
  loadExtensions()

  var idleInhibit = true
  
  window.setIdleInhibit(idleInhibit)
  window.title = "Zwp_idle_inhibitor_v1 example"
  window.run(
    WindowEventsHandler(
      onRender: proc(e: RenderEvent) =
        echo "render"
        glClearColor 0.1, 0.1, 0.1, 1.0
        glClear GlColorBufferBit or GlDepthBufferBit
      ,
      onKey: proc(e: KeyEvent) =
        if e.key == Key.i and e.pressed:
          idleInhibit = not idleInhibit
          window.setIdleInhibit(idleInhibit)
          if idleInhibit:
            echo "idle inhibitor is now enabled"
          else:
            echo "idle inhibitor is now disabled - your compositor can now go to sleep"
    )
  )
