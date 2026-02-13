import sets, strutils, sequtils, bitops, unittest
import vmath
import siwin

const UseVulkan = defined(linux) or defined(bsd) or defined(feature.siwin.vulkan)

when UseVulkan:
  import ./vulkan_setup

test "Vulkan":
  when not UseVulkan:
    skip()
  else:
    if not isVulkanAvailable():
      skip()

    var ticks = 0
    let exts = getRequiredVulkanExtensions()
    let cexts = exts.mapit(cstring(it))
    instance = createInstance(cexts)

    let globals = newSiwinGlobals()

    let window = globals.newVulkanWindow(
      cast[pointer](instance), title="Vulkan test", size = ivec2(WIDTH.int32, HEIGHT.int32), resizable=false
    )
    surface = cast[typeof(surface)](window.vulkanSurface)
    
    init()
    run window, WindowEventsHandler(
      onRender: proc(e: RenderEvent) =
        tick()
      ,
      onKey: proc(e: KeyEvent) =
        if e.pressed and e.key == Key.escape:
          close e.window
      ,
      onTick: proc(e: TickEvent) =
        inc ticks
        if ticks > 180:
          close e.window
    )
    deinit()
