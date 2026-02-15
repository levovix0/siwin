import unittest, strutils
import opengl, vmath
import siwin

let globals = newSiwinGlobals()

proc hasGlProc(name: string): bool =
  when defined(windows):
    proc isInvalidWglProc(p: pointer): bool {.inline.} =
      p == nil or cast[int](p) in [1, 2, 3, -1]
  else:
    proc isInvalidWglProc(p: pointer): bool {.inline.} =
      p == nil

  var symbol: pointer
  try:
    symbol = glGetProc(name.cstring)
  except CatchableError:
    return false
  not isInvalidWglProc(symbol)

proc hasRequiredShaderApi(): bool =
  const required = [
    "glCreateShader",
    "glShaderSource",
    "glCompileShader",
    "glGetShaderiv",
    "glGetShaderInfoLog",
    "glCreateProgram",
    "glAttachShader",
    "glLinkProgram",
    "glGetProgramiv",
    "glGetProgramInfoLog",
    "glGenBuffers",
    "glBindBuffer",
    "glBufferData",
  ]

  for name in required:
    if not hasGlProc(name):
      return false
  true

test "OpenGL":
  block runOpenGl:
    var g = 1.0'f32
    var ticks = 0

    let vertSrcCore = """
#version 330 core
in vec2 aPos;
out vec2 vPos;
void main() {
  vPos = aPos;
  gl_Position = vec4(aPos, 0.0, 1.0);
}
"""

    let fragSrcCore = """
#version 330 core
in vec2 vPos;
uniform float uG;
out vec4 outColor;
void main() {
  vec3 col = vec3((vPos.x + 1.0) * 0.5 * uG, (vPos.y + 1.0) * 0.5, 1.0 - uG * 0.5);
  outColor = vec4(col, 1.0);
}
"""

    let vertSrcLegacy = """
#ifdef GL_ES
precision mediump float;
#endif
attribute vec2 aPos;
varying vec2 vPos;
void main() {
  vPos = aPos;
  gl_Position = vec4(aPos, 0.0, 1.0);
}
"""

    let fragSrcLegacy = """
#ifdef GL_ES
precision mediump float;
#endif
varying vec2 vPos;
uniform float uG;
void main() {
  vec3 col = vec3((vPos.x + 1.0) * 0.5 * uG, (vPos.y + 1.0) * 0.5, 1.0 - uG * 0.5);
  gl_FragColor = vec4(col, 1.0);
}
"""

    proc compileShader(kind: GlEnum, src: string): GlUint =
      result = glCreateShader(kind)
      var csrc = src.cstring
      glShaderSource(result, 1, cast[cstringArray](csrc.addr), nil)
      glCompileShader(result)
      var ok: GlInt
      glGetShaderiv(result, GlCompileStatus, ok.addr)
      if ok != GlTrue.GlInt:
        var buffer: array[512, char]
        glGetShaderInfoLog(result, buffer.len.Glsizei, nil, cast[cstring](buffer.addr))
        let msg = $cast[cstring](buffer.addr)
        glDeleteShader(result)
        result = 0
        raise CatchableError.newException("shader compile failed: " & msg)

    proc linkProgram(vs, fs: GlUint): GlUint =
      result = glCreateProgram()
      glAttachShader(result, vs)
      glAttachShader(result, fs)
      glLinkProgram(result)
      var ok: GlInt
      glGetProgramiv(result, GlLinkStatus, ok.addr)
      if ok != GlTrue.GlInt:
        var buffer: array[512, char]
        glGetProgramInfoLog(result, buffer.len.Glsizei, nil, cast[cstring](buffer.addr))
        raise CatchableError.newException("shader link failed: " & $cast[cstring](buffer.addr))
    
    let window = globals.newOpenglWindow(title="OpenGL test", transparent=true)
    makeCurrent(window)
    if not hasRequiredShaderApi():
      echo "[SKIPPED] OpenGL shader API unavailable on this backend"
      skip()
      break runOpenGl
    loadExtensions()

    var program: GlUint
    var shaderBuildErrors: seq[string] = @[]
    let shaderVariants = [
      (name: "core", vertSrc: vertSrcCore, fragSrc: fragSrcCore),
      (name: "legacy", vertSrc: vertSrcLegacy, fragSrc: fragSrcLegacy)
    ]

    for variant in shaderVariants:
      try:
        let
          vs = compileShader(GlVertexShader, variant.vertSrc)
          fs = compileShader(GlFragmentShader, variant.fragSrc)
        program = linkProgram(vs, fs)
        glDeleteShader(vs)
        glDeleteShader(fs)
        break
      except CatchableError as e:
        shaderBuildErrors.add(variant.name & ": " & e.msg)

    if program == 0:
      raise CatchableError.newException("failed to build shader program; " & shaderBuildErrors.join("; "))

    let
      aPos = glGetAttribLocation(program, "aPos")
      uG = glGetUniformLocation(program, "uG")
    if aPos < 0:
      raise CatchableError.newException("shader attribute aPos not found")

    let triangle: array[6, GlFloat] = [
      -0.8, -0.8,
       0.8, -0.8,
       0.0,  0.8,
    ]
    let hasVaoApi = hasGlProc("glGenVertexArrays") and hasGlProc("glBindVertexArray")
    var
      vbo: GlUint
      vao: GlUint

    glGenBuffers(1, vbo.addr)
    if vbo == 0:
      raise CatchableError.newException("failed to create vertex buffer")
    glBindBuffer(GlArrayBuffer, vbo)
    glBufferData(GlArrayBuffer, triangle.len * GlFloat.sizeof, triangle[0].unsafeAddr, GlStaticDraw)

    if hasVaoApi:
      glGenVertexArrays(1, vao.addr)
      if vao == 0:
        raise CatchableError.newException("failed to create vertex array")
      glBindVertexArray(vao)
      glEnableVertexAttribArray(aPos.GlUint)
      glVertexAttribPointer(aPos.GlUint, 2, cGlFloat, GlFalse, 0, cast[pointer](0))
      glBindVertexArray(0)
    else:
      glBindBuffer(GlArrayBuffer, 0)

    defer:
      if hasVaoApi and vao != 0:
        glDeleteVertexArrays(1, vao.addr)
      if vbo != 0:
        glDeleteBuffers(1, vbo.addr)
      if program != 0:
        glDeleteProgram(program)
    
    run window, WindowEventsHandler(
      onResize: proc(e: ResizeEvent) =
        glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
      ,
      onRender: proc(e: RenderEvent) =
        glClearColor 0.1, 0.1, 0.1, 1.0
        glClear GlColorBufferBit or GlDepthBufferBit
        glUseProgram(program)
        glUniform1f(uG, g)
        if hasVaoApi:
          glBindVertexArray(vao)
        else:
          glBindBuffer(GlArrayBuffer, vbo)
          glEnableVertexAttribArray(aPos.GlUint)
          glVertexAttribPointer(aPos.GlUint, 2, cGlFloat, GlFalse, 0, cast[pointer](0))
        glDrawArrays(GlTriangles, 0, 3)
        if hasVaoApi:
          glBindVertexArray(0)
        else:
          glDisableVertexAttribArray(aPos.GlUint)
          glBindBuffer(GlArrayBuffer, 0)
      ,
      onKey: proc(e: KeyEvent) =
        if e.pressed:
          case e.key
          of Key.escape:
            close e.window
          of Key.f1:
            e.window.fullscreen = not window.fullscreen
          of Key.f2:
            e.window.maximized = not window.maximized
          of Key.f3:
            e.window.minimized = not window.minimized
          of Key.f4:
            e.window.size = ivec2(300, 300)
          else: discard
      ,
      onClick: proc(e: ClickEvent) =
        if e.double:
          close e.window
        else:
          case e.button
          of MouseButton.left, MouseButton.right:
            g = (e.pos.x / e.window.size.x.float32 * 2).min(2).max(0)
            redraw e.window
          of MouseButton.middle:
            e.window.maxSize = ivec2(600, 600)
            e.window.minSize = ivec2(300, 300)
          else: discard
      ,
      onMouseMove: proc(e: MouseMoveEvent) =
        if e.kind == leave: echo "leave: ", e.pos
        if e.kind == MouseMoveKind.enter: echo "enter: ", e.pos
        if MouseButton.left in e.window.mouse.pressed:
          g = (e.pos.x / e.window.size.x.float32 * 2).min(2).max(0)
          redraw e.window
      ,
      onStateBoolChanged: proc(e: StateBoolChangedEvent) =
        echo e.kind, ": ", e.value
      ,
      onTick: proc(e: TickEvent) =
        inc ticks
        if ticks > 180:
          close e.window
    )
