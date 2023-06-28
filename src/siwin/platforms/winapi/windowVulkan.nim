import std/importutils
import vmath
import ../any/window as anyWindow
import window {.all.}, winapi, vkWin32

privateAccess Window
privateAccess WindowWinapi

type
  Surface = object
    instance: pointer
    raw: pointer

  WindowWinapiVulkan* = ref object of WindowWinapi
    surface: Surface

proc `=destroy`*(surface: var Surface) =
  if surface.instance != nil and surface.raw != nil:
    let vkDestroySurfaceKHR = cast[VkDestroySurfaceKHR](surface.instance.vkGetInstanceProcAddr("vkDestroySurfaceKHR"))
    vkDestroySurfaceKHR(surface.instance, surface.raw, nil)
    surface = Surface()


method vulkanSurface*(window: WindowWinapiVulkan): pointer =
  window.surface.raw


proc initWindowWinapiVulkan(window: WindowWinapiVulkan; vkInstance: pointer, size: IVec2; screen: ScreenWinapi, fullscreen, frameless, transparent: bool) =
  window.initWindow size, screen, fullscreen, frameless, transparent, woClassName
  
  var pfd = PixelFormatDescriptor(
    nSize: Word PixelFormatDescriptor.sizeof,
    nVersion: 1,
    dwFlags: Pfd_draw_to_window or Pfd_support_opengl or Pfd_double_buffer,
    iPixelType: Pfd_type_rgba,
    cColorBits: 32,
    cDepthBits: 24,
    cStencilBits: 8,
    iLayerType: Pfd_main_plane,
  )
  window.hdc.SetPixelFormat(window.hdc.ChoosePixelFormat(pfd.addr), pfd.addr)


  window.surface.instance = vkInstance
  var info = VkWin32SurfaceCreateInfoKHR(
    sType: VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR,
    pNext: nil,
    flags: 0.uint32,
    hInstance: GetModuleHandle(nil),
    window: window.handle,
  )
  let vkCreateWin32SurfaceKHR = cast[VkCreateWin32SurfaceKHR](vkInstance.vkGetInstanceProcAddr("vkCreateWin32SurfaceKHR"))
  let res = vkCreateWin32SurfaceKHR(vkInstance, info.addr, nil, window.surface.raw.addr)
  if res != VK_SUCCESS:
    raise OSError.newException("Failed to create Vulkan surface, error: " & $res)


method displayImpl(window: WindowWinapiVulkan) =
  window.eventsHandler.pushEvent onRender, RenderEvent(window: window)
  window.hdc.SwapBuffers


proc newVulkanWindowWinapi*(
  vkInstance: pointer,
  size = ivec2(1280, 720),
  title = "",
  screen = defaultScreenWinapi(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
): WindowWinapiVulkan =
  new result
  result.initWindowWinapiVulkan(vkInstance, size, screen, fullscreen, frameless, transparent)
  result.title = title
  if not resizable: result.resizable = false
