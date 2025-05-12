import std/importutils
import vmath
import ../../[colorutils, siwindefs]
import ../any/[window {.all.} as anyWindow, windowUtils]
import window {.all.}, winapi, vkWin32

privateAccess Window
privateAccess WindowWinapi
privateAccess SiwinGlobalsObj


type
  Surface = object
    instance: pointer
    raw: pointer

  WindowWinapiVulkan* = ptr WindowWinapiVulkanObj
  WindowWinapiVulkanObj* = object of WindowWinapi
    surface: Surface


proc `=destroy`*(surface: Surface) {.siwin_destructor.} =
  if surface.instance != nil and surface.raw != nil:
    discard
    # let vkDestroySurfaceKHR = cast[VkDestroySurfaceKHR](surface.instance.vkGetInstanceProcAddr("vkDestroySurfaceKHR"))
    # vkDestroySurfaceKHR(surface.instance, surface.raw, nil)  #? causes crash



proc winapi_vulkan_pixelBuffer(window: WindowWinapiVulkan): PixelBuffer = discard

proc winapi_vulkan_makeCurrent(window: WindowWinapiVulkan) = discard
proc winapi_vulkan_set_vsync(window: WindowWinapiVulkan, v: bool, silent = false) = discard

proc winapi_vulkan_vulkanSurface(window: WindowWinapiVulkan): pointer =
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



proc winapi_vulkan_displayImpl(window: WindowWinapiVulkan) =
  window.eventsHandler.pushEvent onRender, RenderEvent(window: window)
  window.hdc.SwapBuffers


proc winapi_vulkan_destroy(window: WindowWinapiVulkan) =
  `=destroy`(window.surface)
  `=destroy`(cast[WindowWinapi](window)[])



proc winapiVulkanWindowVtalbe: WindowVtable =
  makeWindowVtable(winapi, winapi_vulkan)


proc newVulkanWindowWinapi*(
  globals: SiwinGlobals,
  vkInstance: pointer,
  size = ivec2(1280, 720),
  title = "",
  screen = defaultScreenWinapi(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
): WindowWinapiVulkan =
  if globals.vulkanVtable.close == nil:
    globals.vulkanVtable = winapiVulkanWindowVtalbe()

  result = create(WindowWinapiVulkanObj)
  result.globals = globals
  result.vtable = globals.vulkanVtable.addr
  result.initWindowWinapiVulkan(vkInstance, size, screen, fullscreen, frameless, transparent)
  result.title = title
  if not resizable: result.resizable = false
