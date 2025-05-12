import opengl, vmath
import siwin
import ./gl

when defined(android):
  import siwin/platforms/android/android

let globals = newSiwinGlobals()

let window = globals.newOpenglWindow(title="Siwin on android", frameless=true)
loadExtensions()


proc p_echo(args: varargs[string, `$`]) =
  when defined(android):
    logE args
  else:
    echo args



var ctx: DrawContext

var
  i = 0
  x = 32/255
  y = 32/255

run window, WindowEventsHandler(
  onResize: proc(e: ResizeEvent) =
    glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
  ,
  onRender: proc(e: RenderEvent) =
    if ctx == nil: ctx = newDrawContext()

    p_echo "redraw on tick: ", i

    glClearColor(x, y, 32/255, 1)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    block rainbowRect:
      let shader = ctx.makeShader:
        {.version: "320 es".}
        proc vert(
          gl_Position: var Vec4,
          pos: var Vec2,
          in_pos: Vec2,
        ) =
          gl_Position = vec4(in_pos.x - 0.5, in_pos.y - 0.5, 0, 1)
          pos = in_pos

        proc frag(
          glCol: var Vec4,
          pos: Vec2,
        ) =
          glCol = vec4(pos.x, pos.y, 0, 1)
      
      use shader.shader
      draw ctx.rect
  ,
  onTick: proc(e: TickEvent) =
    inc i
  ,
  onTouch: proc(e: TouchEvent) =
    # p_echo "touch: id=", e.touchId, " pressed=", e.pressed, " pos=", e.pos
    if e.touchId == 0:
      x = e.pos.x / e.window.size.x.float32
      y = e.pos.y / e.window.size.y.float32
    redraw e.window
  ,
  onTouchMove: proc(e: TouchMoveEvent) =
    # p_echo "touch move: id=", e.touchId, " pos=", e.pos
    if e.touchId == 0:
      x = e.pos.x / e.window.size.x.float32
      y = e.pos.y / e.window.size.y.float32
    redraw e.window
)

destroy globals

