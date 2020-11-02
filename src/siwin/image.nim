import color, geometry

type
  ArrayPtr*[T] = distinct ptr T
  SomeConstImage* = concept a
    a.size is Vec2i
    a[] is ArrayPtr[Color]
    a[int, int] is Color
    a[Vec2i] is Color #! временно
  SomeImage* = concept a, var v
    a is SomeConstImage
    v[int, int] = Color
    v[Vec2i] = Color #! временно
  Image* = object
    ## реальная картинка
    size*: Vec2i
    data*: seq[Color]
  Picture* = object
    ## ссылка на неизменяемое изображение
    size*: Vec2i
    data*: ArrayPtr[Color]
  RenderObject* = object
    ## ссылка на изменяемое изображение
    size*: Vec2i
    data*: ArrayPtr[Color]

proc `[]`*[T](a: ArrayPtr[T], i: int): var T =
  cast[ptr Color](cast[int](a) + i * T.sizeof)[]
proc `[]=`*[T](a: ArrayPtr[T], i: int, v: T) =
  cast[ptr Color](cast[int](a) + i * T.sizeof)[] = v

iterator items*[T](a: ArrayPtr[T], len: int): var T =
  for i in 0..<len:
    yield a[i]

iterator items*(a: SomeConstImage): Color =
  for i in 0.vec2..<a.size:
    yield a[i]
iterator items*(a: var SomeImage): var Color =
  for i in 0.vec2..<a.size:
    yield a[i]

#------------------------------------------------------------------------------

proc newImage*(x, y: int): Image =
  Image(size: (x: x, y: y), data: newSeq[Color](x * y))
proc newImage*(xy: Vec2i): Image = newImage(xy.x, xy.y)

proc `[]`*(a: Image): ArrayPtr[Color] =
  ArrayPtr[Color](a.data[0].unsafeAddr)
proc `[]`*(a: Image; x, y: int): Color =
  a.data[y * a.size.x + x]
proc `[]=`*(a: var Image; x, y: int, c: Color) =
  a.data[y * a.size.x + x] = c

#! возникают прблеммы с компиляцией, если использовать концепт. надеюсь поправят, а пока так
proc `[]`*(a: Image, i: Vec2i): Color = a[i.x, i.y]
proc `[]=`*(a: var Image, i: Vec2i, v: Color) = a[i.x, i.y] = v

#------------------------------------------------------------------------------

proc picture*(a: Image): Picture =
  #! возникают прблеммы с компиляцией, если использовать только концепт. надеюсь поправят, а пока так
  Picture(size: a.size, data: a[])
proc picture*(a: SomeConstImage): Picture =
  Picture(size: a.size, data: a[])

proc `[]`*(a: Picture): ArrayPtr[Color] =
  a.data
proc `[]`*(a: Picture; x, y: int): Color =
  a.data[y * a.size.x + x]

#! возникают прблеммы с компиляцией, если использовать концепт. надеюсь поправят, а пока так
proc `[]`*(a: Picture, i: Vec2i): Color = a[i.x, i.y]

#------------------------------------------------------------------------------

proc renderObject*(a: var Image): RenderObject =
  #! возникают прблеммы с компиляцией, если использовать только концепт. надеюсь поправят, а пока так
  RenderObject(size: a.size, data: a[])
# proc renderObject*(a: var SomeImage): RenderObject =
#   RenderObject(size: a.size, data: a[])
proc renderObject*[T](a: var T): RenderObject =
  RenderObject(size: a.size, data: a[])

proc `[]`*(a: RenderObject): ArrayPtr[Color] =
  a.data
proc `[]`*(a: RenderObject; x, y: int): var Color =
  a.data[y * a.size.x + x]
proc `[]=`*(a: RenderObject; x, y: int, c: Color) =
  a.data[y * a.size.x + x] = c

iterator items*(a: RenderObject): var Color =
  for i in 0..<a.size.S:
    yield a.data[i]

#! возникают прблеммы с компиляцией, если использовать концепт. надеюсь поправят, а пока так
proc `[]`*(a: RenderObject, i: Vec2i): Color = a[i.x, i.y]
proc `[]=`*(a: RenderObject, i: Vec2i, v: Color) = a[i.x, i.y] = v
