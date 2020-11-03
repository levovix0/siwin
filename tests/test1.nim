import siwin
import unittest

test "vec2":
  var v = vec2(10, 20)
  v += (20, 10)
  check v == (30, 30)
  check v / (20, 40) == (1.5, 0.75)

test "picture":
  var v = newImage(5, 5)
  let c = v[]
  c[0] = color 1
  check v[0, 0] == color 1
  v[1, 1] = color 2
  check v[1, 1] == color 2

test "render":
  var img1 = newImage(100, 100)
  var img2 = newImage(50, 50)
  img2.render.clear(color 2)
  let r = render img1

  r.clear(color 1)
  r.image(img2, rect(-10, -10, 60, 60), (10, 10))
  check img1[0, 0] == color 2
  check img1[31, 31] == color 1
  check img1[49, 49] == color 1

  r.clear(color 1)
  r.image(img2, rect(10, 10, 40, 40))
  check img1[0, 0] == color 1
  check img1[10, 10] == color 2
  check img1[40, 40] == color 2
  check img1[41, 41] == color 1
  check img1[49, 49] == color 1
  