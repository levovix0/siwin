import std/[macros]
import pkg/[vmath]
import ./[siwindefs]


when siwin_use_pure_enums:
  {.pragma: siwin_enum, pure.}
else:
  {.pragma: siwin_enum.}


type
  PixelBufferFormat* {.siwin_enum.} = enum
    bgra_32bit
      ## byte array of [blue, green, red, alpha],
      ## where alpha in 0..255, and blue, green, red in 0..255

    bgrx_32bit
      ## byte array of [blue, green, red, alpha],
      ## where alpha in 0..255, and blue, green, red in 0..alpha (pre-multiplied)

    bgru_32bit
      ## byte array of [blue, green, red, unused 8 bits],
      ## where blue, green, red in 0..255
    

    xrgb_32bit
      ## byte array of [alpha, red, green, blue],
      ## where alpha in 0..255, and red, green, blue in 0..alpha (pre-multiplied)

    urgb_32bit
      ## byte array of [unused 8 bits, red, green, blue],
      ## where red, green, blue in 0..255
    

    rgba_32bit
      ## byte array of [red, green, blue, alpha],
      ## where alpha in 0..255, and red, green, blue in 0..255
    
    rgbx_32bit
      ## byte array of [red, green, blue, alpha],
      ## where alpha in 0..255, and red, green, blue in 0..alpha (pre-multiplied)
    
    rgbu_32bit
      ## byte array of [red, green, blue, unused 8 bits],
      ## where alpha in 0..255, and red, green, blue in 0..alpha (pre-multiplied)


  PixelBuffer* = object
    ## pointer to window's buffer of pixels with some metadata
    ## only valid while inside onRender event handler
    ## only for software rendered windows
    ## to get pixel at (x, y), use `cast[ptr UncheckedArray[ColorBgrx]](pixelBuffer.data)[(y * pixelBuffer.size.x + x)]`
    data*: pointer
    size*: IVec2
    format*: PixelBufferFormat
  

  Color32bit* = array[4, byte]


proc at(x: pointer, i: int): var Color32bit {.inline.} =
  cast[ptr UncheckedArray[Color32bit]](x)[i]

proc fromPremultiplied(c: byte, a: byte): byte {.inline.} =
  (c.float / a.float * 255).byte

proc toPremultiplied(c: byte, a: byte): byte {.inline.} =
  (c.float / 255 * a.float).byte


proc convertPixelsInplace*(data: pointer, size: IVec2, sourceFormat, targetFormat: PixelBufferFormat) =
  ## convert pixels to proper format
  let size = size.x * size.y

  macro convertImpl(c0, c1, c2, c3) =
    proc genc(c: NimNode): NimNode =
      if c.kind == nnkInfix:
        if c[0].strVal == "/":
          result = newCall(
            bindSym("toPremultiplied"),
            genc(c[1]),
            genc(c[2]),
          )
        elif c[0].strVal == "*":
          result = newCall(
            bindSym("fromPremultiplied"),
            genc(c[1]),
            genc(c[2]),
          )
        else: error("unexpected syntax", c)
      
      elif c.kind == nnkIntLit:
        if c.intVal in 0..3:
          result = nnkBracketExpr.newTree(
            ident("c"),
            c,
          )
        elif c.intVal == 255:
          result = newLit(255'u8)
        else: error("unexpected syntax", c)
      
      else: error("unexpected syntax", c)
  
    let newColor = nnkBracket.newTree(genc(c0), genc(c1), genc(c2), genc(c3))
    result = nnkForStmt.newTree(
      ident("i"),
      nnkInfix.newTree(
        ident("..<"),
        newLit(0),
        ident("size")
      ),
      nnkStmtList.newTree(
        nnkLetSection.newTree(
          nnkIdentDefs.newTree(
            ident("c"),
            newEmptyNode(),
            nnkCall.newTree(
              nnkDotExpr.newTree(
                ident("data"),
                ident("at")
              ),
              ident("i")
            )
          )
        ),
        nnkAsgn.newTree(
          nnkCall.newTree(
            nnkDotExpr.newTree(
              ident("data"),
              ident("at")
            ),
            ident("i")
          ),
          newColor
        )
      )
    )


  case sourceFormat
  of PixelBufferFormat.bgra_32bit:
    case targetFormat
    of PixelBufferFormat.bgra_32bit:  discard
    of PixelBufferFormat.bgrx_32bit:  convertImpl 0/3, 1/3, 2/3, 3
    of PixelBufferFormat.bgru_32bit:  convertImpl 0,   1,   2,   255
    of PixelBufferFormat.xrgb_32bit:  convertImpl 3,   2/3, 1/3, 0/3
    of PixelBufferFormat.urgb_32bit:  convertImpl 255, 2,   1,   0
    of PixelBufferFormat.rgba_32bit:  convertImpl 2,   1,   0,   3
    of PixelBufferFormat.rgbx_32bit:  convertImpl 2/3, 1/3, 0/3, 3
    of PixelBufferFormat.rgbu_32bit:  convertImpl 2,   1,   0,   255

  of PixelBufferFormat.bgrx_32bit:
    case targetFormat
    of PixelBufferFormat.bgra_32bit:  convertImpl 0*3, 1*3, 2*3, 3
    of PixelBufferFormat.bgrx_32bit:  discard
    of PixelBufferFormat.bgru_32bit:  convertImpl 0,   1,   2,   255
    of PixelBufferFormat.xrgb_32bit:  convertImpl 3,   2,   1,   0
    of PixelBufferFormat.urgb_32bit:  convertImpl 255, 2,   1,   0
    of PixelBufferFormat.rgba_32bit:  convertImpl 2*3, 1*3, 0*3, 3
    of PixelBufferFormat.rgbx_32bit:  convertImpl 2,   1,   0,   3
    of PixelBufferFormat.rgbu_32bit:  convertImpl 2,   1,   0,   255

  of PixelBufferFormat.bgru_32bit:
    case targetFormat
    of PixelBufferFormat.bgra_32bit,
       PixelBufferFormat.bgrx_32bit:  convertImpl 0,   1,   2,   255
    of PixelBufferFormat.bgru_32bit:  discard
    of PixelBufferFormat.xrgb_32bit,
       PixelBufferFormat.urgb_32bit:  convertImpl 255, 2,   1,   0
    of PixelBufferFormat.rgba_32bit,
       PixelBufferFormat.rgbx_32bit,
       PixelBufferFormat.rgbu_32bit:  convertImpl 2,   1,   0,   255


  of PixelBufferFormat.xrgb_32bit:
    case targetFormat
    of PixelBufferFormat.bgra_32bit:  convertImpl 3*0, 2*0, 1*0, 0
    of PixelBufferFormat.bgrx_32bit:  convertImpl 3,   2,   1,   0
    of PixelBufferFormat.bgru_32bit:  convertImpl 255, 2,   1,   0
    of PixelBufferFormat.xrgb_32bit:  discard
    of PixelBufferFormat.urgb_32bit:  convertImpl 255, 1,   2,   3
    of PixelBufferFormat.rgba_32bit:  convertImpl 1*0, 2*0, 3*0, 0
    of PixelBufferFormat.rgbx_32bit:  convertImpl 1,   2,   3,   0
    of PixelBufferFormat.rgbu_32bit:  convertImpl 1,   2,   3,   255
  
  of PixelBufferFormat.urgb_32bit:
    case targetFormat
    of PixelBufferFormat.bgra_32bit,
       PixelBufferFormat.bgrx_32bit,
       PixelBufferFormat.bgru_32bit:  convertImpl 3,   2,   1,   255
    of PixelBufferFormat.xrgb_32bit:  convertImpl 255, 1,   2,   3
    of PixelBufferFormat.urgb_32bit:  discard
    of PixelBufferFormat.rgba_32bit,
       PixelBufferFormat.rgbx_32bit,
       PixelBufferFormat.rgbu_32bit:  convertImpl 1,   2,   3,   255
  

  of PixelBufferFormat.rgba_32bit:
    case targetFormat
    of PixelBufferFormat.bgra_32bit:  convertImpl 2,   1,   0,   3
    of PixelBufferFormat.bgrx_32bit:  convertImpl 2/3, 1/3, 0/3, 3
    of PixelBufferFormat.bgru_32bit:  convertImpl 2,   1,   0,   255
    of PixelBufferFormat.xrgb_32bit:  convertImpl 3,   0/3, 1/3, 2/3
    of PixelBufferFormat.urgb_32bit:  convertImpl 255, 0,   1,   2
    of PixelBufferFormat.rgba_32bit:  discard
    of PixelBufferFormat.rgbx_32bit:  convertImpl 0/3, 1/3, 2/3, 3
    of PixelBufferFormat.rgbu_32bit:  convertImpl 0,   1,   2,   255
  
  of PixelBufferFormat.rgbx_32bit:
    case targetFormat
    of PixelBufferFormat.bgra_32bit:  convertImpl 2*3, 1*3, 0*3, 3
    of PixelBufferFormat.bgrx_32bit:  convertImpl 2,   1,   0,   3
    of PixelBufferFormat.bgru_32bit:  convertImpl 2,   1,   0,   255
    of PixelBufferFormat.xrgb_32bit:  convertImpl 3,   0,   1,   2
    of PixelBufferFormat.urgb_32bit:  convertImpl 255, 0,   1,   2
    of PixelBufferFormat.rgba_32bit:  convertImpl 0*3, 1*3, 2*3, 3
    of PixelBufferFormat.rgbx_32bit:  discard
    of PixelBufferFormat.rgbu_32bit:  convertImpl 0,   1,   2,   255
  

  of PixelBufferFormat.rgbu_32bit:
    case targetFormat
    of PixelBufferFormat.bgra_32bit,
       PixelBufferFormat.bgrx_32bit,
       PixelBufferFormat.bgru_32bit:  convertImpl 2,   1,   0,   255
    of PixelBufferFormat.xrgb_32bit,
       PixelBufferFormat.urgb_32bit:  convertImpl 255, 0,   1,   2
    of PixelBufferFormat.rgba_32bit,
       PixelBufferFormat.rgbx_32bit:  convertImpl 0,   1,   2,   255
    of PixelBufferFormat.rgbu_32bit:  discard
