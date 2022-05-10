
type
  ColorBgrx* = object
    ## pre-multiplied bgra color (to draw on window using software rendering)
    ## b, g and r is 0..a
    ## a is 0..255
    b*, g*, r*, a*: byte

  Image* = object
    w*, h*: int
    data*: seq[ColorBgrx]


func `[]`*(a: Image; x, y: int): ColorBgrx = a.data[y * a.w + x]
func `[]`*(a: var Image; x, y: int): var ColorBgrx = a.data[y * a.w + x]
func `[]=`*(a: var Image; x, y: int, c: ColorBgrx) = a.data[y * a.w + x] = c

iterator items*(a: Image): ColorBgrx =
  for c in a.data:
    yield c

iterator mitems*(a: var Image): var ColorBgrx =
  for c in a.data.mitems:
    yield c

iterator pairs*(a: Image): (int, ColorBgrx) =
  for i, c in a.data:
    yield (i, c)

iterator mpairs*(a: var Image): (int, var ColorBgrx) =
  for i, c in a.data.mpairs:
    yield (i, c)

func newImage*(w, h: int): Image =
  Image(w: w, h: h, data: newSeq[ColorBgrx](w * h))
