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
    let exts = getRequiredVulkanExtensions()
    var cexts = exts.mapit(it[0].unsafeaddr)

    instance = createInstance(cast[cstringArray](cexts[0].addr), exts.len.uint32)

    let globals = newSiwinGlobals()

    let window = globals.newVulkanWindow(
      cast[pointer](instance), title="Vulkan test", size = ivec2(WIDTH.int32, HEIGHT.int32), resizable=false
    )
    surface = cast[VkSurfaceKHR](window.vulkanSurface)
    
    init()
    run window, WindowEventsHandler(
      onRender: proc(e: RenderEvent) =
        tick()
      ,
      onKey: proc(e: KeyEvent) =
        if e.pressed and e.key == Key.escape:
          close e.window
    )
    deinit()
