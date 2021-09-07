import chroma

type Image* = object
  width*, height*: int
  data*: seq[ColorRGBX]

func w*(a: Image): auto {.inline.} = a.width
func h*(a: Image): auto {.inline.} = a.height

func `[]`*(a: Image; x, y: int): ColorRGBX = a.data[y * a.w + x]
func `[]`*(a: var Image; x, y: int): var ColorRGBX = a.data[y * a.w + x]
func `[]=`*(a: var Image; x, y: int, c: ColorRGBX) = a.data[y * a.w + x] = c

iterator items*(a: Image): ColorRGBX =
  for c in a.data:
    yield c

iterator mitems*(a: var Image): var ColorRGBX =
  for c in a.data.mitems:
    yield c

iterator pairs*(a: Image): (int, ColorRGBX) =
  for i, c in a.data:
    yield (i, c)

iterator mpairs*(a: var Image): (int, var ColorRGBX) =
  for i, c in a.data.mpairs:
    yield (i, c)

func newImage*(w, h: int): Image =
  Image(width: w, height: h, data: newSeq[ColorRGBX](w * h))
