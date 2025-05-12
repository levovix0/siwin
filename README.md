# Siwin
<img alt="siwin" width="100%" src="http://levovix.ru:8000/docs/siwin/banner.png">
<p align="center">
  Cross-platform window creation and event handling library.
</p>

Can be used as an alternative to GLFW/GLUT/windy  

![Language](https://img.shields.io/badge/language-Nim-orange.svg?style=flat-square) ![Code size](https://img.shields.io/github/languages/code-size/levovix0/siwin?style=flat-square) ![Latest version](https://img.shields.io/github/v/tag/levovix0/siwin?label=Latest%20version&color=purple&style=flat-square)



# Features
* works with: OpenGL, Vulkan, software rendering
* works on: Linux(X11 and Wayland), Windows
* handles events from: mouse, keyboard
* and also supports: clipboard, offscreen rendering, interactive move/resize, etc.

# Examples

## simple window
```nim
import siwin, vmath

const color = [32'u8, 32, 32, 255]

let siwinGlobals = newSiwinGlobals()

run siwinGlobals.newSoftwareRenderingWindow(), WindowEventsHandler(
  onRender: proc(e: RenderEvent) =
    let pixelBuffer = e.window.pixelBuffer
    
    for y in 0..<pixelBuffer.size.y:
      for x in 0..<pixelBuffer.size.x:
        cast[ptr UncheckedArray[array[4, uint8]]](pixelBuffer.pixels)[y * pixelBuffer.size.x + x] = color

    convertPixelsInplace(pixelBuffer.data, pixelBuffer.size, PixelBufferFormat.bgrx_32bit, pixelBuffer.format)
  ,
  onKey: proc(e: KeyEvent) =
    if (not e.pressed) and e.key == Key.escape:
      close e.window
)

destroy siwinGlobals
```

## OpenGL
![](https://ia.wampi.ru/2021/09/07/31.png)
```nim
import siwin, opengl, vmath

let siwinGlobals = newSiwinGlobals()

var window = siwinGlobals.newOpenglWindow(
  title="OpenGL example",
  preferedPlatform = (when defined(linux): x11 else: defaultPreferedPlatform)
  # note: glBegin and other non- OpenGL ES functions don't work on Wayland
  # see tests/t_opengl_es.nim for more complex, wayland-compatible opengl example
)
loadExtensions()  # init opengl

run window, WindowEventsHandler(
  onResize: proc(e: ResizeEvent) =
    glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    glMatrixMode GlProjection
    glLoadIdentity()
    glOrtho -30, 30, -30, 30, -30, 30
    glMatrixMode(GlModelView)
  ,
  onRender: proc(e: RenderEvent) =
    glClearColor 0.3, 0.3, 0.3, 0
    glClear GlColorBufferBit or GlDepthBufferBit

    glShadeModel GlSmooth

    glLoadIdentity()
    glTranslatef -15, -15, 0

    glBegin GlTriangles
    glColor3f 1, 0, 0
    glVertex2f 0, 0
    glColor3f 0, 1, 0
    glVertex2f 30, 0
    glColor3f 0, 0, 1
    glVertex2f 0, 30
    glEnd()
)

destroy siwinGlobals
```
note: call redraw(window) every time you want window.render to be called. siwin will automatically call window.render only when window resizes.  
note: opengl 1.x and 2.x functions (like `glBegin`), is not supported on Wayland, due to Wayland only beeng able to initialize with EGL

## Vulkan
see [t_vulkan.nim](https://github.com/levovix0/siwin/blob/master/tests/t_vulkan.nim)
```nim
import siwin, nimgl/vulkan, sequtils

doassert vkInit()

let exts = getRequiredVulkanExtensions()
var cexts = exts.mapit(it[0].addr)

var appInfo = newVkApplicationInfo(
  pApplicationName = "siwin Vulkan example",
  applicationVersion = vkMakeVersion(1, 0, 0),
  pEngineName = "No Engine",
  engineVersion = vkMakeVersion(1, 0, 0),
  apiVersion = vkApiVersion1_1
)

var instanceCreateInfo = newVkInstanceCreateInfo(
  pApplicationInfo = appInfo.addr,
  enabledExtensionCount = exts.len,
  ppEnabledExtensionNames = cast[cstringArray](cexts[0].addr),
  enabledLayerCount = 0,
  ppEnabledLayerNames = nil,
)

var instance: VkInstance
doassert vkCreateInstance(instanceCreateInfo.addr, nil, result.addr) == VKSuccess

let siwinGlobals = newSiwinGlobals()

let window = siwinGlobals.newVulkanWindow(cast[pointer](instance), title="Vulkan example")
let surface = cast[VkSurfaceKHR](window.vulkanSurface)

# do other initialization using instance and surface...

run window, WindowEventsHandler(
  onRender: proc(e: RenderEvent) =
    ## do rendering...
  ,
  onClose: proc(e: CloseEvent) =
    ## uninitialize before surface destruction
)

# surface already destroyed, continue uninitializing...

destroy siwinGlobals
```

## pixie
![](https://ia.wampi.ru/2021/09/07/32.png)

note: very slow, but useful if opengl not needed and if window is used to just display one single image

```nim
import siwin, pixie

var image: Image

let siwinGlobals = newSiwinGlobals()

run siwinGlobals.newSoftwareRenderingWindow(title="pixie example"), WindowEventsHandler(
  onResize: proc(e: ResizeEvent) =
    if e.size.x * e.size.y <= 0: return
    image = newImage(e.size.x, e.size.y)
  ,
  onRender: proc(e: RenderEvent) =
    if e.window.size.x * e.window.size.y <= 0: return
    image.fill(rgba(255, 255, 255, 255))

    let ctx = image.newContext
    ctx.fillStyle = rgba(0, 255, 0, 255)

    let
      wh = vec2(250, 250)
      pos = vec2(image.width.float, image.height.float) / 2 - wh / 2
    
    ctx.fillRoundedRect(rect(pos, wh), 25.0)

    let pixelBuffer = e.window.pixelBuffer
    copyMem(pixelBuffer.data, image.data[0].addr, pixelBuffer.size.x * pixelBuffer.size.y * Color32bit.sizeof)
    convertPixelsInplace(pixelBuffer.data, pixelBuffer.size, PixelBufferFormat.rgbx_32bit, pixelBuffer.format)
  ,
  onKey: proc(e: KeyEvent) =
    if (not e.pressed) and e.key == Key.escape:
      close e.window
)

destroy siwinGlobals
```

## clipboard
```nim
let clipboard = window.clipboard

echo clipboard.text
clipboard.text = "some text"
```

## offscreen rendering
note: this will create invisible window. `ctx` mustn't be discarded as its destructor will close the window.  
If you have multiple contexts, use `makeCurrent` to select.
```nim
import siwin/offscreen, opengl

let siwinGlobals = newSiwinGlobals()

let ctx {.used.} = siwinGlobals.newOpenglContext()
loadExtensions()

# do any opengl computing

destroy siwinGlobals
```

## manual main cycle
```nim
import siwin

let siwinGlobals = newSiwinGlobals()
let window = siwinGlobals.newOenglWindow()
loadExtensions()

let eventsHandler = WindowEventsHandler(
  # ...
)

window.firstStep(eventsHandler, makeVisible=true)
while true:
  if window.step(eventsHandler):
    break

destroy siwinGlobals
```

## running multiple windows
```nim
import siwin

let siwinGlobals = newSiwinGlobals()

let win1 = siwinGlobals.newOpenglWindow()
let win2 = siwinGlobals.newOpenglWindow()
loadExtensions()

let win1_eventsHandler = WindowEventsHandler(
  onResize: proc(e: ResizeEvent) =
    makeCurrent e.window
    #...
  ,
  onRender: proc(e: RenderEvent) =
    makeCurrent e.window
    #...
)
let win2_eventsHandler = WindowEventsHandler(
  onResize: proc(e: ResizeEvent) =
    makeCurrent e.window
    #...
  ,
  onRender: proc(e: RenderEvent) =
    makeCurrent e.window
    #...
)

runMultiple(
  (window: win1, eventsHandler: win1_eventsHandler, makeVisible: true),
  (window: win2, eventsHandler: win2_eventsHandler, makeVisible: true),
)
```

## client-side decorations
```nim
import siwin

let siwinGlobals = newSiwinGlobals()

let window = siwinGlobals.newOpenglWindow(transparent=true, frameless=true)
loadExtensions()

run window, WindowEventsHandler(
  onMouseMove: proc(e: MouseMoveEvent) =
    if MouseButton.left in e.window.mouse.pressed:
      window.startInteractiveMove()
      # see also: startInteractiveResize
)
```

## all methods and events
see [siwin/platforms/any/window](https://github.com/levovix0/siwin/blob/master/src/siwin/platforms/any/window.nim)


## I want to get system handle of window and do some magic, but it is private?
```nim
import std/importutils
import siwin/platforms/x11/window
privateAccess WindowX11Obj
# ...
window.handle
```

## Memory management in siwin
Siwin should work fine with --mm:none, --mm:arc and --mm:refc as it uses raw pointers and (on linux) manually made vtables.  

SiwinGlobals is a ptr object, object data starts with a platform kind.  
SiwinGlobals must be created once (using newSiwinGlobals()) and deleted mannaly via destroy(siwinGlobals) call.  
If your programm uses siwin for it's entiery (eg. any gui application or game) you may not care about destroying SiwinGlobals at all. OS will free it automatically.  
After SiwinGlobals is destroyed it is valid to create a new one.  
If you are using siwin for an application, which uses plugins (as a .dll or .so), and plugins also depend on siwin, make sure only one instance of SiwinGlobals exist across all loaded shared objects.  
If you creating only one window using siwin, it is valid to not assign SiwinGlobals to a variable. Window will keep the pointer to SiwinGlobals in itself.  
SiwinGlobals must not be destroyed if any window is still open.  
On linux, it is valid to create two separate SiwinGlobals for X11 and Wayland using newSiwinGlobals(preferedPlatform=x11) and newSiwinGlobals(preferedPlatform=wayland). But I don't know a reason to do this.

Window is a ptr object, object data starts with a (pointer to) SiwinGlobals and a pointer to vtable.  
Window is destroyed automatically when it is closed. Accessing Window after it is closed will (probably) result in a SIGSEGV.  
Before closing and destroying, window will send onClose event. It is valid to access Window in onClose handler.


# Contributions
If you want to support this project, here is some tasks to do:
* See [issues](https://github.com/levovix0/siwin/issues)
* Any bugfixes is always accepted, just describe somewhere what you fixed
* Refactoring (my code is bad, i know it)
  * if you doing very big refactoring, first create issue to ask is all your changes needed, and if it is, refactor
* Documentation
* Optimization
* MacOS support
* Android/IOS support
* Web support
* copy/paste images
* Make cool site that adverts siwin

Just fork levovix0/siwin to your account, make changes and submit a pull request.  
*Or if it requires new repository to be created, create it and add an "change dependency" issue.*
