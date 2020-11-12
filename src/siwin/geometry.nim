import math

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

  Triangle*[T] = (Vec2[T], Vec2[T], Vec2[T])
  Trianglei* = Triangle[int]
  Trianglef* = Triangle[float]

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
proc `>`*[T](a, b: Vec2[T]): bool  = a.x > b.x and a.y > b.y
proc `<=`*[T](a, b: Vec2[T]): bool  = a.x <= b.x and a.y <= b.y
proc `>=`*[T](a, b: Vec2[T]): bool  = a.x >= b.x and a.y >= b.y

# не больше|меньше (или равно)
proc `!<`*[T](a, b: Vec2[T]): bool = a.x > b.x or a.y > b.y
proc `!>`*[T](a, b: Vec2[T]): bool = a.x < b.x or a.y < b.y
proc `!<=`*[T](a, b: Vec2[T]): bool = a.x >= b.x or a.y >= b.y
proc `!>=`*[T](a, b: Vec2[T]): bool = a.x <= b.x or a.y <= b.y

proc S*[T](a: Vec2[T]): auto = a.x * a.y
proc P*[T](a: Vec2[T]): auto = (a.x + a.y) * 2
proc L*[T](a: Vec2[T]): auto = sqrt(a.x ^ 2, a.y ^ 2)

proc min*[T](a, b: Vec2[T]): Vec2[T] = (x: min(a.x, b.x), y: min(a.y, b.y))
proc max*[T](a, b: Vec2[T]): Vec2[T] = (x: max(a.x, b.x), y: max(a.y, b.y))

iterator items*[T](interval: Interval[T]): T =
  for v in interval.a..interval.b:
    yield v

proc rect*[T](a, b: Vec2[T]): Rect2[T] = (a: a, b: b)
proc rect*[T](a, size: Vec2[T]): Rect2[T] = (a: a, b: a + size)
proc rect*[T](x1, y1, x2, y2: T): Rect2[T] = (a: (x: x1, y: y1), b: (x: x2, y: y2))
proc rect2i*[T](a: Rect2[T]): Rect2i = (a: a.a.vec2i, b: a.b.vec2i)
proc rect2f*[T](a: Rect2[T]): Rect2f = (a: a.a.vec2f, b: a.b.vec2f)

proc interval*[T](a, b: T): Interval[T] = (a: a, b: b)
proc `~~`*[T](a, b: T): Interval[T] = (a: a, b: b)
proc `~~<`*[T: SomeNumber](a, b: T): Interval[T] = (a: a, b: b - 1)
proc `>~~`*[T: SomeNumber](a, b: T): Interval[T] = (a: a + 1, b: b)

proc size*[T](a: Interval[T]): auto = a.b - a.a
proc position*[T](a: Rect2[T]): auto = a.a
proc x*[T](a: Rect2[T]): T = a.a.x
proc y*[T](a: Rect2[T]): T = a.a.y
proc `x=`*[T](a: var Rect2[T], v: T) = a.a.x = v
proc `y=`*[T](a: var Rect2[T], v: T) = a.a.y = v
proc w*[T](a: Rect2[T]): T = a.b.x - a.a.x
proc h*[T](a: Rect2[T]): T = a.b.y - a.a.y
proc `w=`*[T](a: var Rect2[T], v: T) = a.b.x = a.a.x + v
proc `h=`*[T](a: var Rect2[T], v: T) = a.b.y = a.a.y + v

proc X*[T](a: Rect2[T]): Interval[T] = (a: a.a.x, b: a.b.x)
proc Y*[T](a: Rect2[T]): Interval[T] = (a: a.a.y, b: a.b.y)
proc `X=`*[T](a: var Rect2[T], v: Interval[T]) = a.a.x = v.a; a.b.x = v.b
proc `Y=`*[T](a: var Rect2[T], v: Interval[T]) = a.a.y = v.a; a.b.y = v.b

proc `..`*[T](a, b: Vec2[T]): Rect2[T] = (a: a, b: b)
proc `~~<`*[T: SomeNumber](a, b: Vec2[T]): Rect2[T] = (a: a, b: b - 1)
proc `>~~`*[T: SomeNumber](a, b: Vec2[T]): Rect2[T] = (a: a + 1, b: b)
proc `..<`*[T: SomeNumber](a, b: Vec2[T]): Rect2[T] = a~~<b
proc `>..`*[T: SomeNumber](a, b: Vec2[T]): Rect2[T] = a>~~b

proc min*[T](a: Interval[T]): T = min(a.a, a.b)
proc max*[T](a: Interval[T]): T = max(a.a, a.b)

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

proc contains*[T](b: Interval[T], a: T): bool =
  a in b.a..b.b
proc contains*[T](b: Rect2[T], a: Vec2[T]): bool =
  (a.x in b.a.x..b.b.x) and (a.y in b.a.y..b.b.y)
proc contains*[T](b: Rect2[T], a: Rect2[T]): bool =
  a.a in b and a.b in b


proc P*[T](a: Rect2[T]): T = (a.b - a.a).P
  ## периметр прямоугольника

proc S*[T](a: Rect2[T]): T = (a.b - a.a).S
  ## площадь прямоугольника


proc cutLine*[T](l: Rect2[T], a: Rect2[T]): Rect2[T] =
  result = l
  if result.w < 0: swap result.a, result.b
  let dx = l.w / l.h # x = y * dx
  let dy = l.h / l.w # y = x * dy
  if result.x < a.x:
    result.y = result.y + ((a.x - result.x).float * dy).round.int
    result.x = a.x
  if result.y < a.y:
    result.x = result.x + ((a.y - result.y).float * dx).round.int
    result.y = a.y
  if result.b.x > a.b.x:
    result.b.y = result.b.y + ((a.b.x - result.b.x).float * dy).round.int
    result.b.x = a.b.x
  if result.b.y > a.b.y:
    result.b.x = result.b.x + ((a.b.y - result.b.y).float * dx).round.int
    result.b.y = a.b.y
  if result.b.y < a.y:
    result.b.x = result.b.x + ((a.y - result.b.y).float * dx).round.int
    result.b.y = a.y

iterator linePixels*[T](a: Rect2[T]): Vec2[T] =
  let dx = a.w / a.h # x = y * dx
  let dy = a.h / a.w # y = x * dy
  if abs(dx) >= abs(dy):
    for i in 0..a.w:
      yield (a.x + i, a.y + (i.float * dy).round.int)
  else:
    var a = a
    if a.h < 0: swap a.a, a.b
    for i in 0..a.h:
      yield (a.x + (i.float * dx).round.int, a.y + i)

proc P*[T](a: Triangle[T]): T = a[0] + a[1] + a[2]
  ## периметр треугольника

proc S*[T](a: Triangle[T]): T =
  ## площадь треугольника
  abs((vec2(a[1].x, a[2].y) - a[0]).S - (vec2(a[2].x, a[1].y) - a[0]).S)

proc rect*[T](a: Triangle[T]): Rect2[T] =
  ## габариты треугольника
  (a: min(a[0], min(a[1], a[2])), b: max(a[0], max(a[1], a[2])))

# proc contains*(b: Trianglef, a: Vec2f): bool =
#   proc s(a: Trianglef): float =
#     (vec2(a[1].x, a[2].y) - a[0]).S - (vec2(a[2].x, a[1].y) - a[0]).S
#   let d1 = (a, b[0], b[1]).s
#   let d2 = (a, b[1], b[2]).s
#   let d3 = (a, b[2], b[0]).s

#   return not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0))

proc contains*[T](x: Triangle[T], s: Vec2[T]): bool =
  ## находится ли точка внутри треугольника
  template a: auto = x[0]
  template b: auto = x[1]
  template c: auto = x[2]

  let sa = s - a

  let s_ab = (b.x-a.x)*sa.y - (b.y-a.y)*sa.x > 0

  if (c.x-a.x)*sa.y - (c.y-a.y)*sa.x > 0 == s_ab: false
  else: (c.x-b.x)*(s.y-b.y) - (c.y-b.y)*(s.x-b.x) > 0 == s_ab

iterator items*[T](a: Triangle[T]): Vec2[T] =
  for i in rect a:
    if i in a:
      yield i
