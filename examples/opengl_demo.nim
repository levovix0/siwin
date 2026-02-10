import opengl, vmath
import siwin

type GlDemoState = object
  program: GlUint
  vao: GlUint
  vbo: GlUint
  initialized: bool
  angle: GlFloat

proc compileShader(kind: GlEnum, source: string): GlUint =
  result = glCreateShader(kind)

  var csource = source.cstring
  glShaderSource(result, 1, cast[cstringArray](csource.addr), nil)
  glCompileShader(result)

  var success: GlInt
  glGetShaderiv(result, GlCompileStatus, success.addr)
  if success == GlTrue.GlInt:
    return

  var log: array[1024, char]
  glGetShaderInfoLog(result, log.len.GlSizei, nil, cast[cstring](log.addr))

  let stage =
    if kind == GlVertexShader: "vertex"
    elif kind == GlFragmentShader: "fragment"
    else: "unknown"

  glDeleteShader(result)
  raise newException(CatchableError, "failed to compile " & stage & " shader: " & $cast[cstring](log.addr))

proc linkProgram(vertexShader, fragmentShader: GlUint): GlUint =
  result = glCreateProgram()
  glAttachShader(result, vertexShader)
  glAttachShader(result, fragmentShader)
  glLinkProgram(result)

  var success: GlInt
  glGetProgramiv(result, GlLinkStatus, success.addr)
  if success == GlTrue.GlInt:
    return

  var log: array[1024, char]
  glGetProgramInfoLog(result, log.len.GlSizei, nil, cast[cstring](log.addr))
  glDeleteProgram(result)
  raise newException(CatchableError, "failed to link shader program: " & $cast[cstring](log.addr))

proc initGl(state: var GlDemoState) =
  if state.initialized:
    return

  let vertexSource = """
#version 330 core
layout (location = 0) in vec2 inPos;
layout (location = 1) in vec3 inColor;
uniform float uAngle;
out vec3 fragColor;

void main() {
  mat2 rot = mat2(cos(uAngle), -sin(uAngle),
                  sin(uAngle),  cos(uAngle));
  gl_Position = vec4(rot * inPos, 0.0, 1.0);
  fragColor = inColor;
}
"""

  let fragmentSource = """
#version 330 core
in vec3 fragColor;
out vec4 outColor;

void main() {
  outColor = vec4(fragColor, 1.0);
}
"""

  let vertexShader = compileShader(GlVertexShader, vertexSource)
  let fragmentShader = compileShader(GlFragmentShader, fragmentSource)
  defer:
    glDeleteShader(vertexShader)
    glDeleteShader(fragmentShader)

  state.program = linkProgram(vertexShader, fragmentShader)

  let vertices: array[15, GlFloat] = [
    0.0, 0.6, 1.0, 0.2, 0.2,
    -0.6, -0.45, 0.2, 1.0, 0.2,
    0.6, -0.45, 0.2, 0.4, 1.0,
  ]

  glGenVertexArrays(1, state.vao.addr)
  glGenBuffers(1, state.vbo.addr)

  glBindVertexArray(state.vao)
  glBindBuffer(GlArrayBuffer, state.vbo)
  glBufferData(GlArrayBuffer, vertices.sizeof, vertices[0].unsafeAddr, GlStaticDraw)

  const stride = (5 * GlFloat.sizeof).GlSizei
  glVertexAttribPointer(0, 2, cGlFloat, GlFalse, stride, nil)
  glEnableVertexAttribArray(0)

  glVertexAttribPointer(1, 3, cGlFloat, GlFalse, stride, cast[pointer](2 * GlFloat.sizeof))
  glEnableVertexAttribArray(1)

  glBindBuffer(GlArrayBuffer, 0)
  glBindVertexArray(0)

  state.initialized = true

let globals = newSiwinGlobals(
  preferedPlatform = (when defined(linux): x11 else: defaultPreferedPlatform())
)

let window = globals.newOpenglWindow(
  size = ivec2(960, 540),
  title = "siwin OpenGL triangle"
)

loadExtensions()
redraw window

var demo: GlDemoState

run window, WindowEventsHandler(
  onResize: proc(e: ResizeEvent) =
    glViewport(0, 0, e.size.x.GLsizei, e.size.y.GLsizei)
  ,
  onRender: proc(e: RenderEvent) =
    if not demo.initialized:
      initGl(demo)

    glClearColor(0.08, 0.09, 0.12, 1.0)
    glClear(GlColorBufferBit or GlDepthBufferBit)

    glUseProgram(demo.program)
    let angleUniform = glGetUniformLocation(demo.program, "uAngle")
    if angleUniform >= 0:
      glUniform1f(angleUniform, demo.angle)

    glBindVertexArray(demo.vao)
    glDrawArrays(GlTriangles, 0, 3)
    glBindVertexArray(0)
  ,
  onTick: proc(e: TickEvent) =
    demo.angle += 0.01
    redraw e.window
  ,
  onKey: proc(e: KeyEvent) =
    if e.pressed and e.key == Key.escape:
      close e.window
)
