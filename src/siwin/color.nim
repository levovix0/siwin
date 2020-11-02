import strutils

type Color* = tuple
  b, g, r, a: uint8

proc toUint32*(c: Color): uint32 =
  cast[uint32](c)

proc color*(a: uint32): Color =
  cast[Color](a)

proc color*(r, g, b: SomeInteger, a: SomeInteger = 255): Color =
  (b: b.uint8, g: g.uint8, r: r.uint8, a: a.uint8)
proc color*(r, g, b: float, a: float = 1.0): Color =
  color (r * 255).uint8, (g * 255).uint8, (b * 255).uint8, (a * 255).uint8

proc color*(hex: string): Color =
  ## Переводит строку вида "#FF00FF" или "c4f" в цвет
  var hex = hex
  if hex.startsWith "#": hex.delete 0, 0
  if hex.len == 3:
    var s = ""
    for c in hex:
      s.add c
      s.add c
    return color s
  elif hex.len == 6:
    var c = parseHexInt(hex).uint32
    c += 0xFF000000'u32
    return color c
  elif hex.len == 8:
    return color parseHexInt(hex).uint32
  else: raise ValueError.newException "incorrect number of digits"

proc hex*(c: Color): string = c.toUint32.toHex

proc with*(c: Color, r: uint8): Color = color r, c.g, c.b, c.a
proc with*(c: Color, g: uint8): Color = color c.r, g, c.b, c.a
proc with*(c: Color, b: uint8): Color = color c.r, c.g, b, c.a
proc with*(c: Color, a: uint8): Color = color c.r, c.g, c.b, a

proc sub_a*(c: Color, k: uint8): Color = color c.r, c.g, c.b, ((c.a.int * k.int) shr 8).uint8
proc sub_a*(c: Color, k: float): Color = color c.r, c.g, c.b, (c.a.float * k).uint8

proc blend*(a: Color, b: Color): Color =
  let kk = 256 - b.a

  result.b = uint8 (b.b.uint * b.a + a.b * kk) shr 8
  result.g = uint8 (b.g.uint * b.a + a.g * kk) shr 8
  result.r = uint8 (b.r.uint * b.a + a.r * kk) shr 8

type RGBCache* = object
  r, g, b, k: int
proc begin_blend*(a: Color): RGBCache =
  result.k = 256 - a.a.int

  result.r = a.r.int * a.a.int
  result.g = a.g.int * a.a.int
  result.b = a.b.int * a.a.int

proc blend*(a: Color, b: RGBCache): Color =
  result.b = uint8 (a.b.int * b.k + b.b) shr 8
  result.g = uint8 (a.g.int * b.k + b.g) shr 8
  result.r = uint8 (a.r.int * b.k + b.r) shr 8


proc blend_rgba*(a: Color, b: Color): Color =
  let k = int 255 - b.a;
  let k2 = 256 - k;
  let b2 = b.b.int * k2 * 255;
  let g2 = b.g.int * k2 * 255;
  let r2 = b.r.int * k2 * 255;

  let k3 = int 255 - a.a;
  let k4 = (256 - k3) * k;
  let znam = 65536 - k * k3;
  result.b = uint8 (a.b.int * k4 + b2) div znam;
  result.g = uint8 (a.g.int * k4 + g2) div znam;
  result.r = uint8 (a.r.int * k4 + r2) div znam;
  result.a = uint8 255 - ((k3 * k) shr 8);

type RGBACache* = object
  r, g, b, k: int
proc begin_blend_rgba*(a: Color): RGBACache =
  result.k = int 255 - a.a
  let k2 = (256 - result.k) * 255

  result.r = a.r.int * k2
  result.g = a.g.int * k2
  result.b = a.b.int * k2

proc blend*(a: Color, b: RGBACache): Color =
  let k = int 255 - a.a;
  let k2 = (256 - k) * b.k;
  let znam = 65536 - b.k * k;
  result.b = uint8 (a.b.int * k2 + b.b) / znam;
  result.g = uint8 (a.g.int * k2 + b.g) / znam;
  result.r = uint8 (a.r.int * k2 + b.r) / znam;
  result.a = uint8 255 - ((k * b.k) shr 8);

template `blend=`*(a: var Color, b: Color|RGBCache|RGBACache) =
  a = a.blend(b)
template `blend_rgba=`*(a: var Color, b: Color) =
  a = a.blend_rgba(b)
