<h2 align="center">Siwin</h2>
<img alt="siwin" width="100%" src="http://levovix.ru:8000/docs/siwin/banner.png">
<p align="center">
  Cross-platform window creation and event handling library.
</p>

Can be used as an alternative to GLFW/GLUT/windy

![Language](https://img.shields.io/badge/language-Nim-orange.svg?style=flat-square) ![Code size](https://img.shields.io/github/languages/code-size/levovix0/siwin?style=flat-square) ![Latest version](https://img.shields.io/github/v/tag/levovix0/siwin?label=Latest%20version&color=purple&style=flat-square)



<h2 align="center">Features</h2>

* works with: OpenGL, Vulkan, Metal (on MacOS), software rendering
* works on: Linux(X11 and Wayland), Windows, MacOS
* handles events from: mouse, keyboard
* and also supports: clipboard, offscreen rendering, interactive move/resize, multithreading, etc.

<h2 align="center">Examples</h2>

## simple window

Create a window with continous event polling:

```nim
import siwin, opengl

let window = newOpenglWindow()
opengl.loadExtensions()  # load opengl functions

window.eventsHandler.onRender = proc(e: RenderEvent) =
  glClearColor(0.1, 0.1, 0.1, 1)
  glClear(GlColorBufferBit or GlDepthBufferBit)

run window
```

## event loop window

Run an application with a more efficient blocking event loop:

```nim
import siwin, opengl

let globals = newSiwinGlobals()
let window = globals.newOpenglWindow()
opengl.loadExtensions()  # load opengl functions

window.eventsHandler.onRender = proc(e: RenderEvent) =
  glClearColor(0.1, 0.1, 0.1, 1)
  glClear(GlColorBufferBit or GlDepthBufferBit)

globals.runEventDriven(window)
```

This approach handles many windows with a shared event loop.

## software-rendering window
```nim
import siwin, vmath

const color = [32'u8, 32, 32, 255]

run newSoftwareRenderingWindow(), WindowEventsHandler(
  onRender: proc(e: RenderEvent) =
    let pixelBuffer = e.window.pixelBuffer
    
    for y in 0..<pixelBuffer.size.y:
      for x in 0..<pixelBuffer.size.x:
        cast[ptr UncheckedArray[array[4, uint8]]](pixelBuffer.data)[y * pixelBuffer.size.x + x] = color

    convertPixelsInplace(pixelBuffer.data, pixelBuffer.size, PixelBufferFormat.bgrx_32bit, pixelBuffer.format)
  ,
  onKey: proc(e: KeyEvent) =
    if (not e.pressed) and e.key == Key.escape:
      close e.window
)
```

## OpenGL
![](http://levovix.ru:8000/docs/siwin/example-opengl.png)
```nim
import siwin, opengl, vmath

let siwinGlobals = newSiwinGlobals(
  preferedPlatform = (when defined(linux): x11 else: defaultPreferedPlatform)
  # note: glBegin and other non- OpenGL ES functions don't work on Wayland,
  #       so we should set preferedPlatform to x11 on linux when using regular OpenGL.
  #       see tests/t_opengl_es.nim for more complex, wayland-compatible opengl example
)

var window = siwinGlobals.newOpenglWindow(
  title="OpenGL example",
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
    glClearColor 0.3, 0.3, 0.3, 1
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
```

## pixie
![](http://levovix.ru:8000/docs/siwin/example-pixie.png)

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
```

<h2 align="center">popup windows</h2>

This api adds popup windows. On Wayland these are required to do popups, but on other platforms these will just be frameless windows.

```nim
import siwin, vmath

let globals = newSiwinGlobals()
let parent = globals.newSoftwareRenderingWindow()

let placement = PopupPlacement(
  anchorRectPos: ivec2(100, 100),
  anchorRectSize: ivec2(120, 40),
  size: ivec2(320, 220),
  anchor: Edge.bottomLeft,
  gravity: Edge.topLeft,
  offset: ivec2(0, 8),
  constraintAdjustment: {PopupConstraintAdjustment.pcaSlideX, PopupConstraintAdjustment.pcaFlipY},
  reactive: true,
)

let popup = globals.newPopupWindow(parent, placement)
```

<h2 align="center">clipboard</h2>

```nim
let clipboard = window.clipboard

echo clipboard.text
clipboard.text = "some text"
```

<h2 align="center">offscreen rendering</h2>

note: this will create invisible window. `ctx` mustn't be discarded as its destructor will close the window.  
If you have multiple contexts, use `makeCurrent` to select.
```nim
import siwin/offscreen, opengl

let siwinGlobals = newSiwinGlobals()

let ctx {.used.} = siwinGlobals.newOpenglContext()
loadExtensions()

# do any opengl computing
```

<h2 align="center">manual main cycle</h2>

```nim
import std/times
import siwin, opengl

let globals = newSiwinGlobals()
let window = globals.newOpenglWindow()
opengl.loadExtensions()

var elapsed = initDuration()
window.eventsHandler = WindowEventsHandler(
  onTick: proc(event: TickEvent) =
    elapsed += event.deltaTime
    event.window.redraw()
  ,
  onRender: proc(event: RenderEvent) =
    let brightness = (elapsed.inMilliseconds mod 1000).float32 / 1000
    glClearColor(brightness, brightness, brightness, 1)
    glClear(GlColorBufferBit or GlDepthBufferBit)
)

window.firstStep(makeVisible = true)
while window.opened:
  window.step()
```

<h2 align="center">manual event loop cycle</h2>

The blocking event loop approach is recommended when apps don't need continuous `onTick` events. Wake events can be added for short lived animations or other needs. This can significantly reduce CPU usage over the polling approach.

Switch applications from `run` to `runEvenDrive` which waits once for native input or an explicit wake event and then services every window. This means `onTick` callbacks and others will only be called on wake events or when there's new events.

```nim
import siwin

let globals = newSiwinGlobals()
let window = globals.newSoftwareRenderingWindow(title = "Siwin event loop")

window.eventsHandler = WindowEventsHandler(
  onKey: proc(event: KeyEvent) =
    if not event.pressed and event.key == Key.escape:
      event.window.close()
)

globals.runEventDriven(window)
```

`runEventDriven` is a convenience runner built from lower-level event-loop APIs. Use them directly when integrating Siwin with another event loop, scheduler, or application queue:

* `globals.pollEvents()` dispatches available native events and returns immediately.
* `globals.waitEvents()` waits for native input or an explicit application wakeup.
* `globals.waitEvents(timeout)` also accepts a deadline and returns `eventActivity`
  or `eventTimeout`.
* `window.serviceWindow()` performs one nonblocking tick, render, and presentation
  pass after the application has handled the dispatched work.

Applications that need to drain another event loop or queue can own the wait directly. Install one copied `EventLoopWaker` on each application-thread destination queue instead of sharing all of `SiwinGlobals`. Every producer must enqueue its message before waking the application thread:

The queue names below are illustrative; use the queue owned by your runtime:

```nim
let waker = globals.eventLoopWaker()

# On a producer thread:
destinationQueue.send(message)
waker.wake()

# On the application thread, after waitEvents returns:
destinationQueue.drain()
```

Wakeups carry no data and may be coalesced, so the destination queue remains the source of truth. Drain every relevant queue after each `waitEvents` return, then call `serviceWindow` for every open window. A copied waker is safe to retain and becomes harmless after its event loop shuts down.

The C ABI provides the same lifetime model through the independently retained opaque `SiwinEventLoopWaker` handle. Create it with `siwin_event_loop_waker`, wake it from a producer with `siwin_event_loop_waker_wake`, and release it with `siwin_destroy_event_loop_waker`; the handle does not require the producer to retain `SiwinGlobals`.

For animation, pass the next real deadline instead of scheduling an unconditional 16 ms wake:

```nim
discard globals.waitEvents(timeUntilNextAnimation)
window.serviceWindow()
```

See [text_input.nim](examples/text_input.nim) for a complete loop that combines native input, cursor blinking, and scroll-decay deadlines.

<h2 align="center">running multiple windows</h2>

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

Use `runMultipleEventDriven` instead when the application doesn't need continous `onTick` events and can use the more efficient blocking call:

```nim
siwinGlobals.runMultipleEventDriven(
  (window: win1, eventsHandler: win1_eventsHandler, makeVisible: true),
  (window: win2, eventsHandler: win2_eventsHandler, makeVisible: true),
)
```

<h2 align="center">client-side decorations</h2>

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

<h2 align="center">transparent backdrop blur</h2>

Backdrop blur uses the same API on macOS, Windows, Wayland, and X11. It is available on macOS,
Windows 11 build 22621 or newer, and KDE compositors that advertise the KWin blur extension.
Create the window with an alpha-capable surface so the effect can show through transparent pixels.

```nim
import siwin

let window = newSoftwareRenderingWindow(transparent = true, frameless = true)

if window.supports(wvcBackdropBlur):
  discard window.trySetBackdrop(initWindowBackdrop()) # whole-window blur

# Empty regions mean the whole window. Non-empty regions use Siwin window coordinates.
# Regional blur is currently available on macOS and KDE only.
# discard window.trySetBackdrop(initWindowBackdrop(regions))

window.clearBackdrop()
```

macOS also supports system materials such as `wbmSidebar` and `wbmHud`:

```nim
if window.supports(wvcBackdropMaterial):
  window.setBackdrop(initWindowBackdrop(wbmSidebar))
```

See [backdrop_blur.nim](examples/backdrop_blur.nim) for a runnable cross-platform example.

<h2 align="center">all methods and events</h2>

see [siwin/platforms/any/window](https://github.com/levovix0/siwin/blob/master/src/siwin/platforms/any/window.nim)


<h2 align="center">I want to get system handle of window and do some magic, but it is private?</h2>

```nim
import std/importutils
import siwin/platforms/x11/window
privateAccess WindowX11Obj
# ...
window.handle
```

<h2 align="center">Contributions</h2>

If you want to support this project, here is some tasks to do:
* See [issues](https://github.com/levovix0/siwin/issues)
* Any bugfixes is always accepted, just describe somewhere what you fixed
* Refactoring (my code is bad, i know it)
  * if you doing very big refactoring, first create issue to ask is all your changes needed, and if it is, refactor
* Documentation
* Optimization
* Android/IOS support
* Web support
* copy/paste images
* Make cool site that adverts siwin

Just fork levovix0/siwin to your account, make changes and submit a pull request.  
*Or if it requires new repository to be created, create it and add an "change dependency" issue.*
