import siwin
import unittest, strformat
import opengl, pixie


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
  
  let window = newOpenglWindow(title="OpenGL test", transparent=true)
  loadExtensions()

  window.resizable = false

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
    of Key.f4:
      window.size = ivec2(300, 300)
    else: discard
  
  window.onClick = proc(e: ClickEvent) =
    if e.doubleClick:
      close window
    else:
      case e.button
      of MouseButton.left, MouseButton.right:
        g = (e.pos.x / window.size.x * 2).min(2).max(0)
        redraw window
      of MouseButton.middle:
        window.maxSize = ivec2(600, 600)
        window.minSize = ivec2(300, 300)
      else: discard
  
  window.onMouseMove = proc(e: MouseMoveEvent) =
    if MouseButton.left in window.mouse.pressed:
      g = (e.pos.x / window.size.x * 2).min(2).max(0)
      redraw window
  
  run window


test "pixie":
  var
    image: Image
    # shadowImage: Image
    window = newWindow(title="pixie test", frameless=true, transparent=true)
  
  window.cursor = block:
    var image = newImage(32, 32)
    image.fill(rgba(0, 0, 0, 0))
    let ctx = image.newContext
    ctx.fillStyle = rgba(100, 100, 255, 100)
    ctx.fillPolygon(vec2(16, 16), 16, 5)
    (image.data.toBgrx.toOpenarray(0, image.data.high), ivec2(image.width.int32, image.height.int32), ivec2(16, 16))

  window.onResize = proc(e: ResizeEvent) =
    image = newImage(e.size.x, e.size.y)

    let ctx = image.newContext
    ctx.fillStyle = rgba(255, 255, 255, 255)
    ctx.fillRoundedRect(rect(vec2(10, 10), vec2(float image.width - 20, float image.height - 20)), 15.0)

  window.onRender = proc(e: RenderEvent) =
    image.fill(rgba(255, 255, 255, 0))

    let ctx = image.newContext

    ctx.fillStyle = rgba(255, 255, 255, 255)
    ctx.fillRoundedRect(rect(vec2(10, 10), vec2(float image.width - 20, float image.height - 20)), 15.0)

    let
      wh = vec2(250, 250)
      pos = vec2(image.width.float, image.height.float) / 2 - wh / 2

    ctx.fillStyle = rgba(50, 50, 255, 255)
    ctx.fillRoundedRect(rect(pos, wh), 25.0)
    
    window.drawImage image.data.toBgrx, ivec2(image.width.int32, image.height.int32)

  window.onKeyup = proc(e: KeyEvent) =
    case e.key
    of Key.escape:
      close window
    else: discard
  
  window.onClick = proc(e: ClickEvent) =
    if e.doubleClick:
      close window
  
  run window


test "bgrx image":
  var
    image: seq[ColorBgrx]
    window = newWindow(title="bgrx image test", frameless=true, transparent=true)

  window.onResize = proc(e: ResizeEvent) =
    image.setLen(e.size.x * e.size.y)

  window.onRender = proc(e: RenderEvent) =
    for y in 0..<window.size.y:
      let a = round(y / window.size.y * 255).byte
      let c = ColorBgrx(b: a, g: a, r: a, a: a)
      for x in 0..<window.size.x:
        image[y * window.size.x + x] = c
    
    window.drawImage image, window.size

  window.onKeyup = proc(e: KeyEvent) =
    case e.key
    of Key.escape:
      close window
    else: discard
  
  window.onClick = proc(e: ClickEvent) =
    if e.doubleClick:
      close window
  
  window.onMouseMove = proc(e: MouseMoveEvent) =
    if e.pos.x in 10..(window.size.x - 10) and e.pos.y in 10..(window.size.y - 10):
      window.cursor = Cursor.sizeAll
    elif e.pos.x in 0..10 and e.pos.y in 0..10:
      window.cursor = Cursor.sizeTopLeft
    elif e.pos.x in 0..10 and e.pos.y in (window.size.y - 10)..window.size.y:
      window.cursor = Cursor.sizeBottomLeft
    elif e.pos.x in (window.size.x - 10)..window.size.x and e.pos.y in 0..10:
      window.cursor = Cursor.sizeTopRight
    elif e.pos.x in (window.size.x - 10)..window.size.x and e.pos.y in (window.size.y - 10)..window.size.y:
      window.cursor = Cursor.sizeBottomRight
    elif e.pos.x in 0..10:
      window.cursor = Cursor.sizeHorisontal
    elif e.pos.x in (window.size.x - 10)..window.size.x:
      window.cursor = Cursor.sizeHorisontal
    elif e.pos.y in 0..10:
      window.cursor = Cursor.sizeVertical
    elif e.pos.y in (window.size.y - 10)..window.size.y:
      window.cursor = Cursor.sizeVertical

    if MouseButton.left in window.mouse.pressed:
      if e.pos.x in 10..(window.size.x - 10) and e.pos.y in 10..(window.size.y - 10):
        window.startInteractiveMove
      elif e.pos.x in 0..10 and e.pos.y in 0..10:
        window.startInteractiveResize(Edge.topLeft)
      elif e.pos.x in 0..10 and e.pos.y in (window.size.y - 10)..window.size.y:
        window.startInteractiveResize(Edge.bottomLeft)
      elif e.pos.x in (window.size.x - 10)..window.size.x and e.pos.y in 0..10:
        window.startInteractiveResize(Edge.topRight)
      elif e.pos.x in (window.size.x - 10)..window.size.x and e.pos.y in (window.size.y - 10)..window.size.y:
        window.startInteractiveResize(Edge.bottomRight)
      elif e.pos.x in 0..10:
        window.startInteractiveResize(Edge.left)
      elif e.pos.x in (window.size.x - 10)..window.size.x:
        window.startInteractiveResize(Edge.right)
      elif e.pos.y in 0..10:
        window.startInteractiveResize(Edge.top)
      elif e.pos.y in (window.size.y - 10)..window.size.y:
        window.startInteractiveResize(Edge.bottom)
  
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
