import strformat
import image

type Renderer* = object
  data*: Picture
  area*: tuple[a, b: tuple[x, y: int]]

proc render*(a: Picture): Renderer =
  ## creates a render for the picture
  result.data = a
  result.area = ((0, 0), (a.size.x - 1, a.size.y - 1))

proc size*(a: Renderer): tuple[x, y: int] = a.data.size

proc `[]`*(a: Renderer; x, y: int): var Color =
  when not defined(release): # bound check
    if x notin a.area.a.x..a.area.b.x or y notin a.area.a.y..a.area.b.y:
      raise IndexDefect.newException(&"index is out of bounds, (x: {x}, y: {y}) notin {a.area}")
  a.data[x, y]
proc `[]=`*(a: Renderer; x, y: int, c: Color) =
  when not defined(release): # bound check
    if x notin a.area.a.x..a.area.b.x or y notin a.area.a.y..a.area.b.y:
      raise IndexDefect.newException(&"index is out of bounds, (x: {x}, y: {y}) notin {a.area}")
  a.data[x, y] = c

proc clear*(a: Renderer, c: Color) =
  for v in a.data:
    v = c
