
import std/[unittest]
import siwin, opengl, vmath
import siwin/platforms/wayland/[siwinGlobals, window, windowOpengl]

test "wlr-layer-shell":
  when not defined(linux) and not defined(bsd):
    skip()
  else:
    let globals = newWaylandGlobals()
    roundtrip(globals)
    let window = globals.newOpenglWindowWayland(
      size = ivec2(1000, 1000),
      kind = WindowWaylandKind.LayerSurface,
      layer = Layer.Overlay,
      screen = globals.defaultScreenWayland,
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
