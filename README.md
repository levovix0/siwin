# Siwin
<img alt="siwin" width="100%" src="http://levovix.ru:8000/docs/siwin/banner.png">
<p align="center">
  Cross-platform window creation and event handling library.
</p>

Can be used as an alternative to GLFW/GLUT/windy  

![Language](https://img.shields.io/badge/language-Nim-orange.svg?style=flat-square) ![Code size](https://img.shields.io/github/languages/code-size/levovix0/siwin?style=flat-square) ![Total Lines](https://img.shields.io/tokei/lines/github/levovix0/siwin?color=purple&style=flat-square)


# Features
* works with: OpenGL, Vulkan, software rendering
* works on: Linux(X11), Windows
* handles events from: mouse, keyboard
* and also supports: clipboard, offscreen rendering, interactive move/resize, etc.

# Examples

## simple window
```nim
import siwin, vmath

run newSoftwareRenderingWindow(), WindowEventsHandler(
  onRender: proc(e: RenderEvent) =
    const color = ColorBgrx(r: 32, g: 32, b: 32, a: 255)
    var image = newSeq[ColorBgrx](e.window.size.x * e.window.size.y)
    for c in image.mitems:
      c = color
    e.window.drawImage(image, e.window.size)
  ,
  onKey: proc(e: KeyEvent) =
    if (not e.pressed) and e.key == Key.escape:
      close e.window
)
```

## OpenGL
![](https://ia.wampi.ru/2021/09/07/31.png)
```nim
import siwin, opengl, vmath

var window = newOpenglWindow(title="OpenGL example")
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
```
note: call redraw(window) every time you want window.render to be called. siwin will automatically call window.render only when window resizes.

## Vulkan
see [t_vulkan.nim](https://github.com/levovix0/siwin/blob/master/tests/t_vulkan.nim)
```nim
import siwin, nimgl/vulkan, sequtils

doassert vkInit()

let exts = getRequiredVulkanExtensions()
var cexts = exts.mapit(it[0].unsafeaddr)

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

let window = newVulkanWindow(cast[pointer](instance), title="Vulkan example")
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
```

## pixie
![](https://ia.wampi.ru/2021/09/07/32.png)

note: very slow, but better than render frames to opengl image if you realy want to use only pixie

```nim
import siwin, pixie

var image: Image

run newSoftwareRenderingWindow(title="pixie example"), WindowEventsHandler(
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
    
    e.window.drawImage(image.data.toBgrx, ivec2(image.width.int32, image.height.int32))
  ,
  onKey: proc(e: KeyEvent) =
    if (not e.pressed) and e.key == Key.escape:
      close e.window
)
```

## clipboard
```nim
import siwin

let clipboard = clipboard()

echo clipboard.text
clipboard.text = "some text"
```
note: on x11 setting cliboard text requires creating window

## offscreen rendering
note: this will create invisible window. `ctx` mustn't be discarded as its destructor will close the window.  
If you have multiple contexts, use `makeCurrent` to select.
```nim
import siwin/offscreen, opengl

let ctx {.used.} = newOpenglContext()
loadExtensions()

# do any opengl computing
```

## manual main cycle
```nim
import siwin

let window = newOenglWindow()
loadExtensions()

let eventsHandler = WindowEventsHandler(
  # ...
)

window.firstStep(eventsHandler, makeVisible=true)
while window.opened:
  window.step(eventsHandler)

```

## running multiple windows
```nim
import siwin

let win1 = newOpenglWindow()
let win2 = newOpenglWindow()
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

let window = newOpenglWindow(transparent=true, frameless=true)
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

# Contributions
If you want to support this project, here is some tasks to do:
* See [issues](https://github.com/levovix0/siwin/issues)
* Any bugfixes is always accepted, just describe somewhere what you fixed
* Refactoring (my code is bad, i know it)
  * if you doing very big refactoring, first create issue to ask is all your changes needed, and if it is, refactor
* Documentation
* Optimization
* Wayland support
* MacOS support
* Android/IOS support
* Web support
* copy/paste images
* Make cool site that adverts siwin

Just fork levovix0/siwin to your account, make changes and submit a pull request.  
*Or if it requires new repository to be created, create it and add an "change dependency" issue.*
