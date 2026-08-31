import opengl, vmath
import siwin


type GlDemoState = object
  initialized: bool
  circleShader: GlUint
  vao: GlUint
  circles: seq[tuple[x, y, r: float32]]
  cursorPos: Vec2

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
uniform float uX;
uniform float uY;
uniform float uW;
uniform float uH;
#define PI 3.1415926535897932384626433832795

void main() {
  if (gl_VertexID == 0) {
    gl_Position = vec4(uX, uY, 0.0, 1.0);
  }
  else {
    float angle = float(gl_VertexID) / 32.0 * PI * 2;
    mat2 rot = mat2(
      cos(angle), -sin(angle),
      sin(angle),  cos(angle)
    );
    gl_Position = vec4(vec2(uX, uY) + vec2(uW, uH) * (rot * vec2(1, 0)), 0.0, 1.0);
  }
}
"""

  let fragmentSource = """
#version 330 core
uniform vec3 uColor;
out vec4 outColor;

void main() {
  outColor = vec4(uColor, 1.0);
}
"""

  let vertexShader = compileShader(GlVertexShader, vertexSource)
  let fragmentShader = compileShader(GlFragmentShader, fragmentSource)
  defer:
    glDeleteShader(vertexShader)
    glDeleteShader(fragmentShader)

  state.circleShader = linkProgram(vertexShader, fragmentShader)

  glGenVertexArrays(1, state.vao.addr)
  glBindVertexArray(state.vao)
  glBindVertexArray(0)

  state.initialized = true

let globals = newSiwinGlobals()

let window = globals.newOpenglWindow(
  size = ivec2(960, 540),
  title = "siwin OpenGL paint (graphics table example)"
)

loadExtensions()
redraw window

var demo: GlDemoState

window.cursor = Cursor(kind: CursorKind.builtin, builtin: BuiltinCursor.hided)

proc onTouchChanged(window: Window, touch: Touch) =
  if touch.pressed:
    demo.circles.add (
      x: (touch.pos.x / window.size.x.float32 * 2 - 1).float32,
      y: -(touch.pos.y / window.size.y.float32 * 2 - 1).float32,
      r: touch.pressure.float32 * 20'f32
    )
  redraw window


run window, WindowEventsHandler(
  onResize: proc(e: ResizeEvent) =
    glViewport(0, 0, e.size.x.GLsizei, e.size.y.GLsizei)
  ,
  onRender: proc(e: RenderEvent) =
    if not demo.initialized:
      initGl(demo)

    glClearColor(0.08, 0.09, 0.12, 1.0)
    glClear(GlColorBufferBit or GlDepthBufferBit)

    glUseProgram(demo.circleShader)
    let uW = glGetUniformLocation(demo.circleShader, "uW")
    let uH = glGetUniformLocation(demo.circleShader, "uH")
    let uX = glGetUniformLocation(demo.circleShader, "uX")
    let uY = glGetUniformLocation(demo.circleShader, "uY")
    let uColor = glGetUniformLocation(demo.circleShader, "uColor")

    glBindVertexArray(demo.vao)
    for circle in demo.circles:
      if uW >= 0: glUniform1f(uW, circle.r / e.window.size.x.float32 * 2)
      if uH >= 0: glUniform1f(uH, circle.r / e.window.size.y.float32 * 2)
      if uX >= 0: glUniform1f(uX, circle.x)
      if uY >= 0: glUniform1f(uY, circle.y)
      if uColor >= 0: glUniform3f(uColor, 1, 1, 1)

      glDrawArrays(GlTriangleFan, 0, 34)

    if uW >= 0: glUniform1f(uW, 5 / e.window.size.x.float32 * 2)
    if uH >= 0: glUniform1f(uH, 5 / e.window.size.y.float32 * 2)
    if uX >= 0: glUniform1f(uX,   demo.cursorPos.x / e.window.size.x.float32 * 2 - 1)
    if uY >= 0: glUniform1f(uY, -(demo.cursorPos.y / e.window.size.y.float32 * 2 - 1))
    if uColor >= 0: glUniform3f(uColor, 0.96, 0.58, 0.33)

    glDrawArrays(GlTriangleFan, 0, 34)

    glBindVertexArray(0)
  ,
  onMouseMove: proc(e: MouseMoveEvent) =
    demo.cursorPos = e.pos
    if e.window.mouse.pressed.len != 0:
      demo.circles.add (
        x: (e.pos.x / e.window.size.x.float32 * 2 - 1).float32,
        y: -(e.pos.y / e.window.size.y.float32 * 2 - 1).float32,
        r: 5'f32
      )
    redraw e.window
  ,
  onMouseButton: proc(e: MouseButtonEvent) =
    demo.circles.add (
      x: (e.window.mouse.pos.x / e.window.size.x.float32 * 2 - 1).float32,
      y: -(e.window.mouse.pos.y / e.window.size.y.float32 * 2 - 1).float32,
      r: 5'f32
    )
    redraw e.window
  ,
  onTouch: proc(e: TouchEvent) =
    onTouchChanged(e.window, e.touch)
  ,
  onTouchMove: proc(e: TouchMoveEvent) =
    demo.cursorPos = e.pos
    onTouchChanged(e.window, e.touch)
  ,
  onTouchPressureChanged: proc(e: TouchPressureChangedEvent) =
    onTouchChanged(e.window, e.touch)
  ,
  onKey: proc(e: KeyEvent) =
    if e.pressed and e.key == Key.escape:
      close e.window

    if e.pressed and e.key == Key.space:
      demo.circles = @[]
      redraw window
)

