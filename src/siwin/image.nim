import parseutils

type
  Color* = tuple
    b, g, r, a: uint8
  Image* = object
    width*, height*: int
    data*: seq[Color]


func color*(r, g, b: SomeInteger, a: SomeInteger = 255): Color =
  (b: b.uint8, g: g.uint8, r: r.uint8, a: a.uint8)
func color*(r, g, b: float, a: float = 1.0): Color =
  color (r * 255).uint8, (g * 255).uint8, (b * 255).uint8, (a * 255).uint8

func toUint32*(c: Color): uint32 =
  cast[uint32](c)
func color*(a: uint32): Color =
  (b: (a and 0xFF).uint8, g: (a shr 8 and 0xFF).uint8, r: (a shr 16 and 0xFF).uint8, a: (a shr 24 and 0xFF).uint8)

func color*(hex: string): Color {.compileTime.} =
  if hex.len == 3:
    var s = ""
    for c in hex:
      s.add c
      s.add c
    return color s
  elif hex.len == 6:
    var c: uint32
    discard parseHex(hex, c)
    c += 0xFF000000'u32
    return color c
  elif hex.len == 8:
    var c: uint32
    discard parseHex(hex, c)
    return color c
  else: raise ValueError.newException "parse #" & hex & ": incorrect number of digits"


func w*(a: Image): auto {.inline.} = a.width
  ## width of image
func h*(a: Image): auto {.inline.} = a.height
  ## height of image


func `[]`*(a: Image; x, y: int): Color = a.data[y * a.w + x]
func `[]`*(a: var Image; x, y: int): var Color = a.data[y * a.w + x]
func `[]=`*(a: var Image; x, y: int, c: Color) = a.data[y * a.w + x] = c


iterator items*(a: Image): Color =
  for c in a.data:
    yield c

iterator mitems*(a: var Image): var Color =
  for c in a.data.mitems:
    yield c

iterator pairs*(a: Image): (int, Color) =
  for i, c in a.data:
    yield (i, c)

iterator mpairs*(a: var Image): (int, var Color) =
  for i, c in a.data.mpairs:
    yield (i, c)


func newImage*(w, h: int): Image =
  Image(width: w, height: h, data: newSeq[Color](w * h))


func sizeInBytes*(a: Image): int = a.w * a.h * Color.sizeof
