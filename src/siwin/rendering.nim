import color, geometry, image

type Renderer* = object
  data*: Picture
  area*: Rect2i

proc render*(a: Picture): Renderer =
  ## создаёт отрисовщик для изображения
  result.data = a
  result.area = rect(0.vec2, size= a.size - 1)

proc size*(a: Renderer): Vec2i = a.data.size

proc `[]`*(a: Renderer; x, y: int): var Color = a.data[x, y]
proc `[]=`*(a: Renderer; x, y: int, c: Color) = a.data[x, y] = c

proc `[]`*(a: Renderer, i: Vec2i): var Color = a[i.x, i.y]
proc `[]=`*(a: Renderer, i: Vec2i, v: Color) = a[i.x, i.y] = v

proc pixel*(a: Renderer, x, y: int; c: Color) =
  ## рисует один пиксель. неэффективна для рисования нескольких пикселей
  if (x, y) notin a.area: return
  if c.a == 255:
    a[x, y] = c
  else:
    a[x, y].blend = c

proc justFillRect*(a: Renderer; r: Rect2i; c: Color) =
  ## заливает прямоугольник без обработки входных параметров
  if c.a == 255:
    for p in r:
      a[p] = c
  else:
    for p in r:
      a[p].blend = c

proc fillRect*(a: Renderer, p: Rect2i, c: Color) =
  a.justFillRect(p & a.area, c)
  
proc fillRect*(a: Renderer; p1, p2: Vec2i; c: Color) =
  a.fillRect(rect(p1, b= p2), c)

proc clear*(a: Renderer, c: Color) =
  ## очищает всю область рисования, может устанавливать прозрачный цвет
  if a.area == rect(0, 0, a.size.x - 1, a.size.y - 1):
    for v in a.data:
      v = c
  else:
    for p in a.area:
      a[p] = c

proc fill*(a: Renderer, c: Color) =
  ## заливает всю область рисования
  if c.a == 255: a.clear c
  else:
    for (x, y) in a.area:
      a[x, y].blend = c

proc image*(a: Renderer, b: Picture, r: Rect2i, srcp: Vec2i = (0, 0), transparent: bool = false) =
  ## рисует изображение
  ##* не масштабирует
  var (r, srcp) = (r, srcp)

  let z = r.a &: 0
  r.b += z
  srcp -= z
  
  let srcz = srcp &: 0
  r.b += srcz
  r.a -= srcz
  srcp :&= 0
  
  if r.b !> a.area.b: return
  if srcp !>= b.size: return
  r = r & a.area &: (r.a + b.size - 1 - srcp)
  
  if transparent:
    for p in 0.vec2..r.size:
      a[r.a + p].blend = b[srcp + p]
  else:
    for p in 0.vec2..r.size:
      a[r.a + p] = b[srcp + p]

proc image*(a: Renderer, b: Picture, pos: Vec2i, srcp: Vec2i = (0, 0), transparent: bool = false) =
  a.image(b, pos..<(pos + b.size), srcp, transparent)
