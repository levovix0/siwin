import siwin, vmath

const color = [32'u8, 32, 32, 255]

let siwinGlobals = newSiwinGlobals()

run siwinGlobals.newSoftwareRenderingWindow(), WindowEventsHandler(
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
