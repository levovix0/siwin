#TODO
import nimgl/opengl
export opengl

type
  BufferBit* {.pure, size: GlBitfield.sizeof.} = enum
    depth = GlDepthBufferBit
    accum = GlAccumBufferBit
    stencil = GlStencilBufferBit
    color = GlColorBufferBit
  ShadeModel* {.pure, size: GlEnum.sizeof.} = enum
    flat = GlFlat
    smooth = GlSmooth
  PrimitiveKind* {.pure, size: GlEnum.sizeof.} = enum
    points = GlPoints
    lines = GlLines
    triangles = GlTriangles
    triangleStrip = GlTriangleStrip
    triangleFan = GlTriangleFan
    quads = GlQuads

converter toGlBitField*(a: BufferBit): GlBitfield = a.GlBitfield
converter toGlEnum*(a: ShadeModel): GlEnum = a.GlEnum
converter toGlEnum*(a: PrimitiveKind): GlEnum = a.GlEnum

template includeGlProcs: untyped =
  proc clear(r, g, b, a: float, o: varargs[GlBitfield]) {.used.} =
    glClearColor r, g, b, a
    if o.len < 1: return
    let bbit = block:
      var a = o[0]
      for b in o[1..^1]:
        a = a or b
      a
    glClear bbit
  
  proc shade(a: ShadeModel) {.used.} =
    glShadeModel a
  
  template draw(a: PrimitiveKind, body) {.used.} =
    block:
      glBegin a
      body
      glEnd()
  
  proc loadIdentity() {.used.} =
    glLoadIdentity()

  proc color(r, g, b: float) {.used.} =
    glColor3f r, g, b
  proc color(r, g, b: int{lit}) {.used.} =
    glColor3f r.float, g.float, b.float
  proc vertex(x, y: float) {.used.} =
    glVertex2f(x, y)
  proc vertex(x, y, z: float) {.used.} =
    glVertex3f(x, y, z)

  proc translate(x, y, z: float) {.used.} =
    glTranslatef(x, y, z)


template withOpengl*(body: untyped): untyped =
  block:
    includeGlProcs
    body


block:
  includeGlProcs
