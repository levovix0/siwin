import parseutils

type
  Color* = tuple
    b, g, r, a: uint8
  ArrayPtr*[T] = distinct ptr T
  Picture* = object
    size*: tuple[x, y: int]
    data*: ArrayPtr[Color]
  Image* = object
    picture*: Picture



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



proc `[]`*[T](a: ArrayPtr[T], i: int): var T =
  cast[ptr T](cast[int](a) + i * T.sizeof)[]
proc `[]=`*[T](a: ArrayPtr[T], i: int, v: T) =
  cast[ptr T](cast[int](a) + i * T.sizeof)[] = v

iterator items*[T](a: ArrayPtr[T], len: int): var T =
  for i in 0..<len:
    yield a[i]

proc allocArray*[T](len: int): ArrayPtr[T] = ArrayPtr[T](cast[ptr T](alloc(len * T.sizeof)))



func `[]`*(a: Picture; x, y: int): var Color = a.data[y * a.size.x + x]
func `[]=`*(a: Picture; x, y: int, c: Color) = a.data[y * a.size.x + x] = c

iterator items*(a: Picture): var Color =
  for v in a.data.items(a.size.x * a.size.y):
    yield v

func w*(a: Picture): auto = a.size.x
  ## width of picture
func h*(a: Picture): auto = a.size.y
  ## height of picture



converter toPicture*(a: Image): Picture = a.picture

proc `=destroy`*(a: var Image) =
  dealloc(cast[pointer](a.picture.data))
proc newImage*(w, h: int): Image =
  Image(picture: Picture(size: (x: w, y: h), data: allocArray[Color](w * h)))

func size*(a: Image): auto = a.picture.size
func data*(a: Image): auto = a.picture.data
func `size=`*(a: var Image, v: tuple[x, y: int]) = a.picture.size = v
func `data=`*(a: var Image, v: ArrayPtr[Color]) = a.picture.data = v
