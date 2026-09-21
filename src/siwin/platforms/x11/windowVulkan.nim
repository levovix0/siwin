import std/[importutils, tables]
import vmath
import x11/x except Window
import ../../[siwindefs]
import ../any/window as anyWindow
import ./[window {.all.}, vkXlib, siwinGlobals, x11api]

privateAccess Window
privateAccess WindowX11

type
  Surface = object
    instance: pointer
    raw: VkSurfaceHandle

  WindowX11Vulkan* = ref WindowX11VulkanObj
  WindowX11VulkanObj* = object of WindowX11
    surface: Surface

proc `=destroy`*(surface: Surface) {.siwin_destructor.} =
  if surface.instance != nil and cast[uint64](surface.raw) != 0:
    # vkDestroySurfaceKHR(surface.instance, surface.raw, nil)  #? causes crash
    discard

when NimMajor < 2 or NimMinor < 2:
  proc `=trace`(x: var WindowX11VulkanObj, env: pointer) =
    #? for some reason, without this, nim produces invalid C code for =trace implementation
    `=trace`(cast[ptr WindowX11Obj](x.addr)[], env)

  proc `=destroy`(x: WindowX11VulkanObj) {.siwin_destructor.} =
    #? for some reason, without this, nim produces invalid C code for =trace implementation
    `=destroy`(cast[ptr WindowX11Obj](x.addr)[])
    `=destroy`(x.surface)

method vulkanSurface*(window: WindowX11Vulkan): anyWindow.VulkanSurface =
  cast[anyWindow.VulkanSurface](window.surface.raw)

proc initVulkanWindow(
    window: WindowX11Vulkan,
    vkInstance: pointer,
    size: IVec2,
    screen: ScreenX11,
    fullscreen, frameless, transparent: bool,
    class: string,
) =
  requireVulkanXlib()
  window.basicInitWindow size, screen

  let root = window.globals.display.DefaultRootWindow
  var vi: XVisualInfo
  discard window.globals.display.XMatchVisualInfo(
    window.screen, if transparent: 32 else: 24, TrueColor, vi.addr
  )
  let cmap = window.globals.display.XCreateColormap(root, vi.visual, AllocNone)
  var swa = XSetWindowAttributes(colormap: cmap, overrideRedirect: true.XBool)
  window.handle = window.globals.display.XCreateWindow(
    root,
    0,
    0,
    size.x.cuint,
    size.y.cuint,
    0,
    vi.depth,
    InputOutput,
    vi.visual,
    CwColormap or CwEventMask or CwBorderPixel or CwBackPixel,
    swa.addr,
  )

  window.setupWindow fullscreen, frameless, class

  window.surface.instance = vkInstance
  var info = VkXlibSurfaceCreateInfoKHR(
    sType: VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR,
    pNext: nil,
    flags: 0.uint32,
    dpy: window.globals.display,
    window: window.handle,
  )
  let res = vkCreateXlibSurfaceKHR(vkInstance, info.addr, nil, window.surface.raw.addr)
  if res != VK_SUCCESS:
    raise OSError.newException("Failed to create Vulkan surface, error: " & $res)

proc newVulkanWindowX11*(
    globals: SiwinGlobalsX11,
    vkInstance: pointer,
    size = ivec2(1280, 720),
    title = "",
    screen = globals.defaultScreenX11(),
    resizable = true,
    fullscreen = false,
    frameless = false,
    transparent = false,
    class = "", # window class (used in x11), equals to title if not specified
): WindowX11Vulkan =
  new result
  result.globals = globals
  try:
    result.initVulkanWindow(
      vkInstance,
      size,
      screen,
      fullscreen,
      frameless,
      transparent,
      (if class == "": title else: class),
    )
    result.title = title
    if not resizable:
      result.resizable = false
  except:
    if result.handle != 0:
      result.globals.windows.del(result.handle.uint)
    raise
