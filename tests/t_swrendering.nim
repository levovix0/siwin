import unittest, strformat
import pixie
import siwin/[platforms, window, colorutils, clipboards]

{.experimental: "overloadableEnums".}

let globals = newSiwinGlobals()

test "screen":
  if globals.screenCount() == 1:
    let size = globals.defaultScreen().size
    echo &"screen().size: {size.x}x{size.y}"
  else:
    for i in 0..<globals.screenCount():
      let size = globals.screen(i).size
      echo &"screen({i}).size: {size.x}x{size.y}"


test "clipboard":
  let window = globals.newSoftwareRenderingWindow()
  window.firstStep(makeVisible = false)
  
  echo "clipboard text: ", window.clipboard.text
  echo "selection clipboard text: ", window.selectionClipboard.text
  
  window.clipboard.text = "hello"

  check window.clipboard.text == "hello"

  for i in 0..<100:
    window.step()

  check window.clipboard.text == "hello"

  close window


test "pixie":
  var
    image: Image
    window = globals.newSoftwareRenderingWindow(title="pixie test", frameless=true, transparent=true)
    cursorImage = newImage(32, 32)
  
  window.cursor = block:
    cursorImage.fill(rgba(0, 0, 0, 0))
    let ctx = cursorImage.newContext
    ctx.fillStyle = rgba(100, 100, 255, 100)
    ctx.fillPolygon(vec2(16, 16), 16, 5)

    var pixelBuffer = PixelBuffer(
      data: cursorImage.data[0].addr,
      size: ivec2(cursorImage.width.int32, cursorImage.height.int32),
      format: PixelBufferFormat.rgba_32bit,
    )

    Cursor(kind: CursorKind.image, image: ImageCursor(
      pixels: pixelBuffer,
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
      
      let pixelBuffer = e.window.pixelBuffer
      copyMem(pixelBuffer.data, image.data[0].addr, pixelBuffer.size.x * pixelBuffer.size.y * Color32bit.sizeof)
      convertPixelsInplace(pixelBuffer.data, pixelBuffer.size, PixelBufferFormat.rgbx_32bit, pixelBuffer.format)
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
    window = globals.newSoftwareRenderingWindow(title="bgrx image test", frameless=true, transparent=true)
  
  window.setBorderWidth(10, 0, 10)

  run window, WindowEventsHandler(
    onRender: proc(e: RenderEvent) =
      let pixelBuffer = e.window.pixelBuffer
      
      for y in 0..<pixelBuffer.size.y:
        let a = round(y / pixelBuffer.size.y * 255).byte
        let c = [a, a, a, a]
        
        for x in 0..<pixelBuffer.size.x:
          cast[ptr UncheckedArray[Color32bit]](pixelBuffer.data)[y * pixelBuffer.size.x + x] = c
      
      convertPixelsInplace(pixelBuffer.data, pixelBuffer.size, PixelBufferFormat.bgrx_32bit, pixelBuffer.format)
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
        of Key.space:
          redraw e.window
        else: discard
    ,
    onClick: proc(e: ClickEvent) =
      if e.double:
        close e.window
    ,
  )

destroy globals

