import std/[importutils]
import pkg/[vmath]
import ../../[siwindefs]
import ../any/window {.all.}
import ./[libwayland, globals, vkWayland]
import window {.all.}

privateAccess Window
privateAccess WindowWayland

type
  Surface = object
    instance: pointer
    raw: pointer

  WindowWaylandVulkan* = ref WindowWaylandVulkanObj
  WindowWaylandVulkanObj* = object of WindowWayland
    vulkan_surface: Surface


proc `=trace`(x: var WindowWaylandVulkanObj, env: pointer) =
  #? for some reason, without this, nim produces invalid C code for =trace implementation
  `=trace`(cast[ptr WindowWaylandObj](x.addr)[], env)


proc `=destroy`*(window: WindowWaylandVulkanObj) {.siwin_destructor.} =
  release cast[WindowWaylandVulkan](window.addr)

  for x in window.fields:
    when compiles(`=destroy`(x)):
      `=destroy`(x)

method release(window: WindowWaylandVulkan) =
  ## destroy wayland part of window
  if window.vulkan_surface.instance != nil and window.vulkan_surface.raw != nil:
    # vkDestroySurfaceKHR(surface.instance, surface.raw, nil)  #? causes crash
    discard

  procCall window.WindowWayland.release()


method vulkanSurface*(window: WindowWaylandVulkan): pointer =
  window.vulkan_surface.raw


proc initVulkanWindow(
  window: WindowWaylandVulkan, vkInstance: pointer,
  size: IVec2, screen: ScreenWayland,
  fullscreen, frameless, transparent: bool, class: string
) =
  globals.init()

  window.basicInitWindow size, screen
  
  window.setupWindow fullscreen, frameless, transparent, size, class

  # window.eglContext = newOpenglContext(window.surface.proxy.raw, size.x, size.y)
  # makeCurrent window.eglContext

  # commit window.surface

  window.vulkan_surface.instance = vkInstance
  var info = VkWaylandSurfaceCreateInfoKHR(
    sType: VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR,
    pNext: nil,
    flags: 0.uint32,
    display: display,
    surface: window.surface,
  )
  let res = vkCreateWaylandSurfaceKHR(vkInstance, info.addr, nil, window.vulkan_surface.raw.addr)
  if res != VK_SUCCESS:
    raise OSError.newException("Failed to create Vulkan surface, error: " & $res)


proc newVulkanWindowWayland*(
  vkInstance: pointer,
  size = ivec2(1280, 720),
  title = "",
  screen = defaultScreenWayland(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,

  class = "", # window class (used in x11), equals to title if not specified
): WindowWaylandVulkan =
  new result
  result.initVulkanWindow(vkInstance, size, screen, fullscreen, frameless, transparent, (if class == "": title else: class))
  result.title = title
  if not resizable: result.resizable = false
