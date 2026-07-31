
import std/[unittest]
import siwin

when defined(linux) or defined(bsd):
  import opengl, vmath
  import siwin/platforms/wayland/[siwinGlobals, window, windowOpengl]

  static:
    doAssert compiles(
      block:
        var globals: SiwinGlobals
        let config = default(LayerSurfaceConfig)
        discard globals.newSoftwareRenderingLayerSurfaceWindow(config = config)
        discard globals.newOpenglLayerSurfaceWindow(config = config)
        discard globals.newVulkanLayerSurfaceWindow(
          vkInstance = nil,
          config = config,
        )
    )

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
        let config = LayerSurfaceConfig(
          layer: LayerSurfaceLayer.lslOverlay,
          anchors: {
            LayerSurfaceAnchor.lsaTop,
            LayerSurfaceAnchor.lsaBottom,
            LayerSurfaceAnchor.lsaLeft,
          },
          exclusiveZone: 1,
          keyboardMode: LayerSurfaceKeyboardMode.lskOnDemand,
          namespace: "siwin-layer-shell-test",
        )
        let window = globals.newOpenglLayerSurfaceWindowWayland(
          size = ivec2(1000, 1000),
          screen = globals.defaultScreenWayland,
          config = config,
        )
        loadExtensions()

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
