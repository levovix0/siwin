type
  Color* = tuple
    b, g, r, a: uint8
  ArrayPtr*[T] = distinct ptr T
  Picture* = object
    size*: tuple[x, y: int]
    data*: ArrayPtr[Color]
  Image* = object
    picture*: Picture

proc toUint32*(c: Color): uint32 =
  cast[uint32](c)
proc color*(a: uint32): Color =
  cast[Color](a)

proc color*(r, g, b: SomeInteger, a: SomeInteger = 255): Color =
  (b: b.uint8, g: g.uint8, r: r.uint8, a: a.uint8)
proc color*(r, g, b: float, a: float = 1.0): Color =
  color (r * 255).uint8, (g * 255).uint8, (b * 255).uint8, (a * 255).uint8

proc `[]`*[T](a: ArrayPtr[T], i: int): var T =
  cast[ptr Color](cast[int](a) + i * T.sizeof)[]
proc `[]=`*[T](a: ArrayPtr[T], i: int, v: T) =
  cast[ptr Color](cast[int](a) + i * T.sizeof)[] = v

iterator items*[T](a: ArrayPtr[T], len: int): var T =
  for i in 0..<len:
    yield a[i]

proc allocArray*[T](len: int): ArrayPtr[T] = ArrayPtr[T](cast[ptr T](alloc(len * T.sizeof)))

#------------------------------------------------------------------------------

proc `[]`*(a: Picture; x, y: int): var Color = a.data[y * a.size.x + x]
proc `[]=`*(a: Picture; x, y: int, c: Color) = a.data[y * a.size.x + x] = c

iterator items*(a: Picture): var Color =
  for v in a.data.items(a.size.x * a.size.y):
    yield v

proc w*(a: Picture): auto = a.size.x
  ## width of picture
proc h*(a: Picture): auto = a.size.y
  ## height of picture

#------------------------------------------------------------------------------

converter toPicture*(a: Image): Picture = a.picture

proc `=destroy`*(a: var Image) =
  dealloc(cast[pointer](a.picture.data))
proc newImage*(x, y: int): Image =
  Image(picture: Picture(size: (x: x, y: y), data: allocArray[Color](x * y)))

proc size*(a: Image): auto = a.picture.size
proc data*(a: Image): auto = a.picture.data
