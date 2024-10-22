when not defined(linux):
  {.error: "wlr-layer-shell only works on Wayland (Linux)".}

import std/[unittest]
import siwin, opengl
import siwin/platforms/wayland/[window, windowOpengl]

test "wlr-layer-shell":
  let window = newOpenglWindowWayland(
    kind = WindowWaylandKind.LayerSurface, 
    layer = Layer.Overlay 
  )
  loadExtensions()

  window.setAnchor(LayerEdge.Left, 4)
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
