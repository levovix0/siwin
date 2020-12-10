import imageman
import siwin/image

converter toImagemanColor*(a: image.Color): imageman.ColorRGBAU =
  [a.r, a.g, a.b, a.a].ColorRGBAU

converter toSiwinColor*(a: imageman.ColorRGBAU): image.Color =
  (b: a.b, g: a.g, r: a.r, a: a.a)

converter toImagemanImage*(a: Picture): imageman.Image[ColorRGBAU] =
  result.width = a.w
  result.height = a.h
  result.data = newSeqOfCap[ColorRGBAU](a.w * a.h)
  for v in a:
    result.data.add v

converter toSiwinImage*(a: imageman.Image[ColorRGBAU]): image.Image =
  result = newImage(a.w, a.h)
  for i, v in a.data:
    result.data[i] = v
