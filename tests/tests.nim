import unittest, strformat
import opengl, pixie
import siwin

{.experimental: "overloadableEnums".}

test "screen":
  if screenCount() == 1:
    let size = defaultScreen().size
    echo &"screen().size: {size.x}x{size.y}"
  else:
    for i in 0..<screenCount():
      let size = screen(i).size
      echo &"screen({i}).size: {size.x}x{size.y}"


test "pixie":
  var
    image: Image
    window = newSoftwareRenderingWindow(title="pixie test", frameless=true, transparent=true)
  
  window.cursor = block:
    var image = newImage(32, 32)
    image.fill(rgba(0, 0, 0, 0))
    let ctx = image.newContext
    ctx.fillStyle = rgba(100, 100, 255, 100)
    ctx.fillPolygon(vec2(16, 16), 16, 5)
    Cursor(kind: CursorKind.image, image: ImageCursor(
      data: image.data.toBgrx,
      size: ivec2(image.width.int32, image.height.int32),
      origin: ivec2(16, 16)
    ))

  run window, WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      image = newImage(e.size.x, e.size.y)
    ,
    onRender: proc(e: RenderEvent) =
      image.fill(rgba(255, 255, 255, 0))

      let ctx = image.newContext

      ctx.fillStyle = rgba(255, 255, 255, 255)
      ctx.fillRoundedRect(rect(vec2(10, 10), vec2(float image.width - 20, float image.height - 20)), 15.0)

      let
        wh = vec2(250, 250)
        pos = vec2(image.width.float, image.height.float) / 2 - wh / 2

      ctx.fillStyle = rgba(50, 50, 255, 255)
      ctx.fillRoundedRect(rect(pos, wh), 25.0)
      
      e.window.drawImage(image.data.toBgrx, ivec2(image.width.int32, image.height.int32))
    ,
    onKey: proc(e: KeyEvent) =
      if e.pressed and not e.generated:
        case e.key
        of Key.escape:
          close e.window
        else: discard
    ,
    onClick: proc(e: ClickEvent) =
      if e.double:
        close e.window
  )


test "bgrx image":
  var
    image: seq[ColorBgrx]
    window = newSoftwareRenderingWindow(title="bgrx image test", frameless=true, transparent=true)
  
  run window, WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      image.setLen(e.size.x * e.size.y)
    ,

    onRender: proc(e: RenderEvent) =
      for y in 0..<e.window.size.y:
        let a = round(y / e.window.size.y * 255).byte
        let c = ColorBgrx(b: a, g: a, r: a, a: a)
        for x in 0..<e.window.size.x:
          image[y * e.window.size.x + x] = c
      
      e.window.drawImage(image, e.window.size)
    ,
    onKey: proc(e: KeyEvent) =
      if e.pressed and not e.generated:
        case e.key
        of Key.escape:
          close e.window
        of Key.f1:
          e.window.fullscreen = not window.fullscreen
        of Key.f2:
          e.window.maximized = not window.maximized
        of Key.f3:
          e.window.minimized = not window.minimized
        of Key.f4:
          e.window.size = ivec2(300, 300)
        of Key.f5:
          e.window.frameless = not window.frameless
        else: discard
    ,
    onClick: proc(e: ClickEvent) =
      if e.double:
        close e.window
    ,
    onMouseMove: proc(e: MouseMoveEvent) =
      if e.pos.x in 10..(e.window.size.x - 10) and e.pos.y in 10..(e.window.size.y - 10):
        e.window.cursor = Cursor(kind: builtin, builtin: sizeAll)
      elif e.pos.x in 0..10 and e.pos.y in 0..10:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeTopLeft)
      elif e.pos.x in 0..10 and e.pos.y in (e.window.size.y - 10)..e.window.size.y:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeBottomLeft)
      elif e.pos.x in (e.window.size.x - 10)..e.window.size.x and e.pos.y in 0..10:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeTopRight)
      elif e.pos.x in (e.window.size.x - 10)..e.window.size.x and e.pos.y in (e.window.size.y - 10)..e.window.size.y:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeBottomRight)
      elif e.pos.x in 0..10:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeHorisontal)
      elif e.pos.x in (e.window.size.x - 10)..e.window.size.x:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeHorisontal)
      elif e.pos.y in 0..10:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeVertical)
      elif e.pos.y in (e.window.size.y - 10)..e.window.size.y:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeVertical)

      if MouseButton.left in e.window.mouse.pressed:
        if e.pos.x in 10..(e.window.size.x - 10) and e.pos.y in 10..(e.window.size.y - 10):
          e.window.startInteractiveMove
        elif e.pos.x in 0..10 and e.pos.y in 0..10:
          e.window.startInteractiveResize(Edge.topLeft)
        elif e.pos.x in 0..10 and e.pos.y in (e.window.size.y - 10)..e.window.size.y:
          e.window.startInteractiveResize(Edge.bottomLeft)
        elif e.pos.x in (e.window.size.x - 10)..e.window.size.x and e.pos.y in 0..10:
          e.window.startInteractiveResize(Edge.topRight)
        elif e.pos.x in (e.window.size.x - 10)..e.window.size.x and e.pos.y in (e.window.size.y - 10)..e.window.size.y:
          e.window.startInteractiveResize(Edge.bottomRight)
        elif e.pos.x in 0..10:
          e.window.startInteractiveResize(Edge.left)
        elif e.pos.x in (e.window.size.x - 10)..e.window.size.x:
          e.window.startInteractiveResize(Edge.right)
        elif e.pos.y in 0..10:
          e.window.startInteractiveResize(Edge.top)
        elif e.pos.y in (e.window.size.y - 10)..e.window.size.y:
          e.window.startInteractiveResize(Edge.bottom)
    ,
  )


test "2 windows at once":
  let win1 = newOpenglWindow(title="1", transparent=true, class="siwin example")
  let win2 = newOpenglWindow(title="2", size=ivec2(800, 600), class="siwin example")
  loadExtensions()

  let win1eh = WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      makeCurrent e.window
      glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    ,
    onRender: proc(e: RenderEvent) =
      makeCurrent e.window
      glClearColor 0.3, 0.3, 0.3, 0.7
      glClear GlColorBufferBit or GlDepthBufferBit
    ,
    onClick: proc(e: ClickEvent) =
      if e.double:
        close (if win2.opened: win2 else: e.window)
    ,
    onKey: proc(e: KeyEvent) =
      if e.pressed and not e.generated:
        case e.key
        of Key.escape:
          close win1
          close win2
        else: discard
  )
  var win2eh = win1eh
  
  win2eh.onRender = proc(e: RenderEvent) =
    makeCurrent e.window
    glClearColor 0.7, 0.7, 0.7, 1
    glClear GlColorBufferBit or GlDepthBufferBit
  
  win2eh.onClick = proc(e: ClickEvent) =
    if e.double:
      close (if win1.opened: win1 else: e.window)

  runMultiple(
    (win1, win1eh, true),
    (win2, win2eh, true),
  )


test "clipboard":
  let clipboard = clipboard()
  echo clipboard.text
  clipboard.text = "hello"
  check clipboard.text == "hello"

