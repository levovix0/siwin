import chroma

type
  ColorBgrx* = object
    ## pre-multiplied bgra color (to draw on window using software rendering)
    ## b, g and r is 0..a
    ## a is 0..255
    b*, g*, r*, a*: byte


proc toBgrx*(x: openarray[ColorRgbx]): seq[ColorBgrx] =
  result = newSeq[ColorBgrx](x.len)
  for i, v in result.mpairs:
    v = ColorBgrx(b: x[i].b, g: x[i].g, r: x[i].r, a: x[i].a)
