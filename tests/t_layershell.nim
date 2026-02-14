
import std/[unittest]
import siwin, opengl, vmath
import siwin/platforms/wayland/[siwinGlobals, window, windowOpengl]

test "wlr-layer-shell":
  when not defined(linux) and not defined(bsd):
    skip()
  else:
    block runLayerShell:
      var
        ticks = 0
        rendered = false
      try:
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
            onRender: proc(e: RenderEvent) =
              rendered = true
              glClearColor 0.1, 0.1, 0.1, 1.0
              glClear GlColorBufferBit or GlDepthBufferBit
            ,
            onKey: proc(e: KeyEvent) =
              if e.pressed and not e.generated and e.key == Key.escape:
                close e.window
            ,
            onTick: proc(e: TickEvent) =
              inc ticks
              if ticks >= 120:
                close e.window
          )
        )
      except CatchableError:
        skip()
        break runLayerShell
      check rendered
