type
  Vec2*[T] = tuple
    x, y: T
  Vec2i* = Vec2[int]
  Vec2f* = Vec2[float]

  Interval*[T] = tuple
    a, b: T

  Rect2*[T] = Interval[Vec2[T]]
  Rect2i* = Rect2[int]
  Rect2f* = Rect2[float]

proc vec2*[T](x: T, y: T): Vec2[T] = (x: x, y: y)
proc vec2*[T: SomeNumber](xy: T): Vec2[T] = (x: xy, y: xy)
proc vec2*[A, B](b: Vec2[B]): Vec2[A] = vec2 b.x.A, b.y.A

template vec2i*[B](b: Vec2[B]): Vec2i = vec2[int] b
template vec2f*[B](b: Vec2[B]): Vec2f = vec2[float] b

proc `+`*[T](a, b: Vec2[T]): auto = vec2(a.x + b.x, a.y + b.y)
proc `-`*[T](a, b: Vec2[T]): auto = vec2(a.x - b.x, a.y - b.y)
proc `*`*[T](a, b: Vec2[T]): auto = vec2(a.x * b.x, a.y * b.y)
proc `/`*[T](a, b: Vec2[T]): auto = vec2(a.x / b.x, a.y / b.y)
proc `div`*[T: SomeInteger, B: SomeNumber](a: Vec2[T], b: Vec2[B]): auto =
  vec2(a.x div b.x, a.y div b.y)
proc `+`*[T](a: Vec2[T], b: T): auto = vec2(a.x + b, a.y + b)
proc `-`*[T](a: Vec2[T], b: T): auto = vec2(a.x - b, a.y - b)
proc `*`*[T](a: Vec2[T], b: T): auto = vec2(a.x * b, a.y * b)
proc `/`*[T](a: Vec2[T], b: T): auto = vec2(a.x / b, a.y / b)
proc `div`*[T: SomeInteger, B: SomeNumber](a: Vec2[T], b: B): auto =
  vec2(a.x div b, a.y div b)
proc `+`*[T](a: T, b: Vec2[T]): auto = vec2(a + b.x, a + b.y)
proc `-`*[T](a: T, b: Vec2[T]): auto = vec2(a - b.x, a - b.y)
proc `*`*[T](a: T, b: Vec2[T]): auto = vec2(a * b.x, a * b.y)
proc `/`*[T](a: T, b: Vec2[T]): auto = vec2(a / b.x, a / b.y)
proc `div`*[T: SomeInteger, B: SomeNumber](a: T, b: Vec2[B]): auto =
  vec2(a div b.x, a div b.y)

template `//`*(a, b): auto = a div b

proc `+=`*[T](a: var Vec2[T], b: Vec2[T]) = a = a + b
proc `-=`*[T](a: var Vec2[T], b: Vec2[T]) = a = a - b
proc `*=`*[T](a: var Vec2[T], b: Vec2[T]) = a = a * b
proc `/=`*[T: SomeFloat](a: var Vec2[T], b: Vec2[T]) = a = a / b
proc `//=`*[T: SomeInteger, B: SomeNumber](a: var Vec2[T], b: Vec2[B]) =
  a = a // b

proc `<`*[T](a, b: Vec2[T]): bool  = a.x < b.x and a.y < b.y
proc `!<`*[T](a, b: Vec2[T]): bool = a.x < b.x or  a.y < b.y
proc `>`*[T](a, b: Vec2[T]): bool  = a.x > b.x and a.y > b.y
proc `!>`*[T](a, b: Vec2[T]): bool = a.x > b.x or  a.y > b.y
proc `<=`*[T](a, b: Vec2[T]): bool  = a.x <= b.x and a.y <= b.y
proc `!<=`*[T](a, b: Vec2[T]): bool = a.x <= b.x or  a.y <= b.y
proc `>=`*[T](a, b: Vec2[T]): bool  = a.x >= b.x and a.y >= b.y
proc `!>=`*[T](a, b: Vec2[T]): bool = a.x >= b.x or  a.y >= b.y

proc S*[T](a: Vec2[T]): auto = a.x * a.y

proc min*[T](a, b: Vec2[T]): Vec2[T] = (x: min(a.x, b.x), y: min(a.y, b.y))
proc max*[T](a, b: Vec2[T]): Vec2[T] = (x: max(a.x, b.x), y: max(a.y, b.y))

iterator items*[T](interval: Interval[T]): T =
  for v in interval.a..interval.b:
    yield v

proc rect*[T](a, b: Vec2[T]): Rect2[T] = (a: a, b: b)
proc rect*[T](a, size: Vec2[T]): Rect2[T] = (a: a, b: a + size)
proc rect*[T](x1, y1, x2, y2: T): Rect2[T] = (a: (x: x1, y: y1), b: (x: x2, y: y2))

proc interval*[T](a, b: T): Interval[T] = (a: a, b: b)
proc `~~`*[T](a, b: T): Interval[T] = (a: a, b: b)
proc `~~<`*[T: SomeNumber](a, b: T): Interval[T] = (a: a, b: b - 1)
proc `>~~`*[T: SomeNumber](a, b: T): Interval[T] = (a: a + 1, b: b)

proc size*[T](a: Interval[T]): auto = a.b - a.a
proc position*[T](a: Rect2[T]): auto = a.a
proc x*[T](a: Rect2[T]): auto = a.a.x
proc y*[T](a: Rect2[T]): auto = a.a.y
proc `x=`*[T](a: var Rect2[T], v: T): auto = a.a.x = v
proc `y=`*[T](a: var Rect2[T], v: T): auto = a.a.y = v
proc w*[T](a: Rect2[T]): auto = a.b.x - a.a.x
proc h*[T](a: Rect2[T]): auto = a.b.y - a.a.y
proc `w=`*[T](a: var Rect2[T], v: T): auto = a.b.x = a.a.x + v
proc `h=`*[T](a: var Rect2[T], v: T): auto = a.b.y = a.a.y + v

proc `..`*[T](a, b: Vec2[T]): Rect2[T] = (a: a, b: b)
proc `~~<`*[T: SomeNumber](a, b: Vec2[T]): Rect2[T] = (a: a, b: b - 1)
proc `>~~`*[T: SomeNumber](a, b: Vec2[T]): Rect2[T] = (a: a + 1, b: b)
proc `..<`*[T: SomeNumber](a, b: Vec2[T]): Rect2[T] = a~~<b
proc `>..`*[T: SomeNumber](a, b: Vec2[T]): Rect2[T] = a>~~b

iterator `..`*[T](a, b: Vec2[T]): Vec2[T] =
  for v in (a~~b):
    yield v
iterator `..<`*[T](a, b: Vec2[T]): Vec2[T] =
  for v in (a~~<b):
    yield v

iterator items*[T](rect: Rect2[T]): Vec2[T] =
  for y in rect.a.y..rect.b.y:
    for x in rect.a.x..rect.b.x:
      yield (x, y)

proc sort*[T](a, b: var T) =
  if a > b: swap a, b
proc sort*[T](a, b: var Vec2[T]) =
  sort a.x, b.x
  sort a.y, b.y
proc sort*[T](x: Interval[T]) =
  sort x.a, x.b

proc sorted*[T](a, b: T): (T, T) =
  if a > b: (b, a)
  else: (a, b)
proc sorted*[T](a, b: Vec2[T]): (Vec2[T], Vec2[T]) =
  let (x, y) = (sorted(a.x, b.x), sorted(a.y, b.y))
  ((x[0], y[0]), (x[1], y[1]))
proc sorted*[T](x: Interval[T]): Interval[T] =
  sorted(x.a, x.b)

proc `&:`*[T](a, b: Vec2[T]): Vec2[T] = (x: min(a.x, b.x), y: min(a.y, b.y))
proc `:&`*[T](a, b: Vec2[T]): Vec2[T] = (x: max(a.x, b.x), y: max(a.y, b.y))
proc `&:`*[T](a: Vec2[T], b: T): Vec2[T] = (x: min(a.x, b), y: min(a.y, b))
proc `:&`*[T](a: Vec2[T], b: T): Vec2[T] = (x: max(a.x, b), y: max(a.y, b))
proc `&:`*[T](a: T, b: Vec2[T]): Vec2[T] = (x: min(a, b.x), y: min(a, b.y))
proc `:&`*[T](a: T, b: Vec2[T]): Vec2[T] = (x: max(a, b.x), y: max(a, b.y))
proc `&`*[T](a, b: Interval[T]): Interval[T] =
  result.a = max(a.a, b.a)
  result.b = min(a.b, b.b)
proc `&`*[T](a, b: Rect2[T]): Rect2[T] =
  result.a.x = max(a.a.x, b.a.x)
  result.a.y = max(a.a.y, b.a.y)
  result.b.x = min(a.b.x, b.b.x)
  result.b.y = min(a.b.y, b.b.y)
proc `&:`*[T](a: Rect2[T], b: Vec2[T]): Rect2[T] =
  result = a
  result.b.x = min(a.b.x, b.x)
  result.b.y = min(a.b.y, b.y)
proc `:&`*[T](a: Rect2[T], b: Vec2[T]): Rect2[T] =
  result = a
  result.a.x = max(a.a.x, b.x)
  result.a.y = max(a.a.y, b.y)

template `&=`*[T](a: var Interval[T], b: Interval[T]) = a = a & b
template `&:=`*(a, b: typed) = a = a &: b
template `:&=`*(a, b: typed) = a = a :& b

proc contains*[T](b: Rect2[T], a: Vec2[T]): bool =
  (a.x in b.a.x..b.b.x) and (a.y in b.a.y..b.b.y)
