import winapi

const vkDLL =
  when defined(windows): "vulkan-1.dll"
  elif defined(macosx): "libMoltenVK.dylib"
  else: "libvulkan.so.1"

type
  VkStructureType* {.size: int32.sizeof.} = enum
    VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR = 1000009000
  
  VkResult* {.size: int32.sizeof.} = enum
    VK_ERROR_FRAGMENTED_POOL = -12
    VK_ERROR_FORMAT_NOT_SUPPORTED = -11
    VK_ERROR_TOO_MANY_OBJECTS = -10
    VK_ERROR_INCOMPATIBLE_DRIVER = -9
    VK_ERROR_FEATURE_NOT_PRESENT = -8
    VK_ERROR_EXTENSION_NOT_PRESENT = -7
    VK_ERROR_LAYER_NOT_PRESENT = -6
    VK_ERROR_MEMORY_MAP_FAILED = -5
    VK_ERROR_DEVICE_LOST = -4
    VK_ERROR_INITIALIZATION_FAILED = -3
    VK_ERROR_OUT_OF_DEVICE_MEMORY = -2
    VK_ERROR_OUT_OF_HOST_MEMORY = -1
    VK_SUCCESS = 0
    VK_NOT_READY = 1
    VK_TIMEOUT = 2
    VK_EVENT_SET = 3
    VK_EVENT_RESET = 4
    VK_INCOMPLETE = 5
  
  VkWin32SurfaceCreateInfoKHR* = object
    sType*: VkStructureType
    pNext*: pointer
    flags*: uint32
    hInstance*: HInstance
    window*: Hwnd
  
  VkCreateWin32SurfaceKHR* = proc(
    instance: pointer,
    pCreateInfo: ptr VkWin32SurfaceCreateInfoKHR,
    pAllocator: pointer,
    pSurface: ptr pointer
  ): VkResult {.cdecl, stdcall, raises: [].}

  VkDestroySurfaceKHR* = proc(
    instance: pointer,
    surface: pointer,
    pAllocator: pointer
  ) {.cdecl, stdcall, raises: [].}


{.push, cdecl, stdcall, dynlib: vkDLL, importc.}

proc vkGetInstanceProcAddr*(instance: pointer, procName: cstring): pointer

{.pop.}
