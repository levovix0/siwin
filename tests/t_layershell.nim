when not defined(linux):
  {.error: "wlr-layer-shell only works on Wayland (Linux)".}

import std/[unittest]
import siwin, opengl, vmath
import siwin/platforms/wayland/[window, windowOpengl, siwinGlobals]

let globals = newWaylandGlobals()

test "wlr-layer-shell":
  let window = globals.newOpenglWindowWayland(
    size = ivec2(1000, 1000),
    kind = WindowWaylandKind.LayerSurface,
    screen = globals.defaultScreenWayland(),
    layer = Layer.Overlay,
  )
  loadExtensions()

  window.setAnchor(@[LayerEdge.Top, LayerEdge.Bottom, LayerEdge.Left])
  window.setKeyboardInteractivity(LayerInteractivityMode.OnDemand)
  window.setExclusiveZone(1)
  window.run(
    WindowEventsHandler(
      onResize: proc(e: ResizeEvent) =
        echo "resize"
      ,
      onRender: proc(e: RenderEvent) =
        echo "render"
        glClearColor 0.1, 0.1, 0.1, 1.0
        glClear GlColorBufferBit or GlDepthBufferBit
      ,
      onKey: proc(e: KeyEvent) =
        echo e.key
    )
  )

destroy globals
