from imageman as imgm import nil
import color, geometry

type
  ArrayPtr*[T] = distinct ptr T
  Picture* = object of RootObj
    ## изображение
    size*: Vec2i
    data*: ArrayPtr[Color]
  Image* = object
    picture*: Picture

proc `[]`*[T](a: ArrayPtr[T], i: int): var T =
  cast[ptr Color](cast[int](a) + i * T.sizeof)[]
proc `[]=`*[T](a: ArrayPtr[T], i: int, v: T) =
  cast[ptr Color](cast[int](a) + i * T.sizeof)[] = v

iterator items*[T](a: ArrayPtr[T], len: int): var T =
  for i in 0..<len:
    yield a[i]

proc allocArray*[T](len: int): ArrayPtr[T] = ArrayPtr[T](cast[ptr T](alloc(len * T.sizeof)))

#------------------------------------------------------------------------------

proc `[]`*(a: Picture): ArrayPtr[Color] = a.data
proc `[]`*(a: Picture; x, y: int): var Color = a.data[y * a.size.x + x]
proc `[]=`*(a: Picture; x, y: int, c: Color) = a.data[y * a.size.x + x] = c

proc `[]`*(a: Picture, i: Vec2i): Color = a[i.x, i.y]
proc `[]=`*(a: Picture, i: Vec2i, v: Color) = a[i.x, i.y] = v

iterator items*(a: Picture): var Color =
  for v in a.data.items(a.size.S):
    yield v

proc w*(a: Picture): auto = a.size.x
proc h*(a: Picture): auto = a.size.y

#------------------------------------------------------------------------------

converter toPicture*(a: Image): Picture = a.picture

proc `=destroy`*(a: var Image) =
  dealloc(cast[pointer](a.picture.data))
proc newImage*(x, y: int): Image =
  Image(picture: Picture(size: (x: x, y: y), data: allocArray[Color](x * y)))
proc newImage*(xy: Vec2i): Image = newImage(xy.x, xy.y)

proc size*(a: Image): auto = a.picture.size
proc data*(a: Image): auto = a.picture.data

converter toColor*(a: imgm.ColorRGBAU): Color =
  color imgm.r(a), imgm.g(a), imgm.b(a), imgm.a(a)
converter toColorRGBAU*(a: Color): imgm.ColorRGBAU =
  imgm.ColorRGBAU [a.r, a.g, a.b, a.a]

proc toImage*(a: imgm.Image[imgm.ColorRGBAU]): Image =
  result = newImage(a.width, a.height)
  for i in 0..result.size.S:
    result.data[i] = a.data[i].toColor

proc toImagemanImage*(a: Image): imgm.Image[imgm.ColorRGBAU] =
  result = imgm.initImage[imgm.ColorRGBAU](a.w, a.h)
  for i in 0..a.size.S:
    result.data[i] = a.data[i].toColorRGBAU
