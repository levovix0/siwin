import siwin
from siwin/image as sim import nil
import unittest, strformat
import nimgl/opengl, pixie


test "screen":
  if screenCount == 1:
    let size = screen().size
    echo &"screen().size: {size.x}x{size.y}"
  else:
    for i in 0..<screenCount:
      let size = screen(i).size
      echo &"screen({i}).size: {size.x}x{size.y}"


test "OpenGL":
  var g = 1.0
  var window = newOpenglWindow(title="OpenGL test", transparent=true)
  doassert glInit()

  window.onResize = proc(e: ResizeEvent) =
    glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    glMatrixMode GlProjection
    glLoadIdentity()
    glOrtho -30, 30, -30, 30, -30, 30
    glMatrixMode GlModelView
  
  window.onRender = proc(e: RenderEvent) =
    glClearColor 0.3, 0.3, 0.3, 0
    glClear GlColorBufferBit or GlDepthBufferBit
  
    glShadeModel GlSmooth
  
    glLoadIdentity()
    glTranslatef -15, -15, 0
  
    glBegin GlTriangles
    glColor3f 1 * g, g - 1, g - 1
    glVertex2f 0, 0
    glColor3f g - 1, 1 * g, g - 1
    glVertex2f 30, 0
    glColor3f g - 1, g - 1, 1 * g
    glVertex2f 0, 30
    glEnd()
  
  window.onKeyup = proc(e: KeyEvent) =
    case e.key
    of Key.escape:
      close window
    of Key.f1:
      window.fullscreen = not window.fullscreen
    of Key.f2:
      window.maximized = not window.maximized
    of Key.f3:
      window.minimized = not window.minimized
    else: discard
  
  window.onDoubleClick = proc(e: ClickEvent) =
    close window
  
  window.onMouseMove = proc(e: MouseMoveEvent) =
    if e.mouse.pressed[MouseButton.left]:
      g = (e.pos.x / window.size.x * 2).min(2).max(0)
      redraw window
  
  window.onClick = proc(e: ClickEvent) =
    case e.button
    of MouseButton.left, MouseButton.right:
      g = (e.pos.x / window.size.x * 2).min(2).max(0)
      redraw window
    else: discard
  
  run window


test "pixie":
  var
    image: Image
    shadowImage: Image
    window = newWindow(title="pixie test", frameless=true, transparent=true)

  window.onResize = proc(e: ResizeEvent) =
    image = newImage(e.size.x, e.size.y)

    let ctx = image.newContext
    ctx.fillStyle = rgba(255, 255, 255, 255)
    ctx.fillRoundedRect(rect(vec2(10, 10), vec2(float image.width - 20, float image.height - 20)), 15.0)
    shadowImage = image.shadow(
      offset = vec2(0, 0),
      spread = 2,
      blur = 10,
      color = rgba(0, 0, 0, 128)
    )
    # note: pixie's shadow is slow
    # todo: use a faster shadow

  window.onRender = proc(e: RenderEvent) =
    image.fill(rgba(255, 255, 255, 0))

    image.draw shadowImage

    let ctx = image.newContext

    ctx.fillStyle = rgba(255, 255, 255, 255)
    ctx.fillRoundedRect(rect(vec2(10, 10), vec2(float image.width - 20, float image.height - 20)), 15.0)

    let
      wh = vec2(250, 250)
      pos = vec2(image.width.float, image.height.float) / 2 - wh / 2

    ctx.fillStyle = rgba(50, 50, 255, 255)
    ctx.fillRoundedRect(rect(pos, wh), 25.0)
    
    window.drawImage image.data

  window.onKeyup = proc(e: KeyEvent) =
    case e.key
    of Key.escape:
      close window
    else: discard
  
  window.onDoubleClick = proc(e: ClickEvent) =
    close window
  
  run window


test "bgrx image":
  var
    image: sim.Image
    window = newWindow(title="bgrx image test", frameless=true, transparent=true)

  window.onResize = proc(e: ResizeEvent) =
    image = sim.newImage(e.size.x, e.size.y)

  window.onRender = proc(e: RenderEvent) =
    for y in 0..<image.h:
      let a = round(y / image.h * 255).byte
      let c = ColorBgrx(b: a, g: a, r: a, a: a)
      for x in 0..<image.w:
        sim.`[]=`(image, x, y, c)
    
    window.drawImage image.data

  window.onKeyup = proc(e: KeyEvent) =
    case e.key
    of Key.escape:
      close window
    else: discard
  
  window.onDoubleClick = proc(e: ClickEvent) =
    close window
  
  run window

when defined(wayland):
  import wayland/client

  var
    compositor: Compositor
    shell: Shell

    srf: Surface
    shsrf: ShellSurface

  test "wayland":
    let display = displayConnect()
    if display == nil:
      raise Exception.newException "Can't connect to display"
    
    let reg = display.getRegistry
    var rl = RegistryListener(
      global: proc(data: pointer, registry: Registry, name: uint32, iface: cstring, version: uint32) {.cdecl.} =
        template i(v, f): untyped = v = cast[type(v)](registry.bindRegistry(name, f.addr, 1))
        echo $iface
        case $iface
        of "wl_compositor": i(compositor, wl_compositor_interface)
        of "wl_shell": i(shell, wl_shell_interface)
      ,
      globalRemove: proc(data: pointer, registry: Registry, name: uint32) {.cdecl.} = discard
        # who cares?
    )
    reg.addListener rl.addr

    dispatch display
    roundtrip display

    srf = compositor.createSurface
    shsrf = shell.getShellSurface(srf)
    setTopLevel shsrf

    disconnect display
