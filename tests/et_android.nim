import opengl, vmath
import siwin
import ./gl

when defined(android):
  import siwin/platforms/android/android


let window = newOpenglWindow(title="Siwin on android", frameless=true)
loadExtensions()


var ctx: DrawContext

var i = 0

run window, WindowEventsHandler(
  onResize: proc(e: ResizeEvent) =
    glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
  ,
  onRender: proc(e: RenderEvent) =
    if ctx == nil: ctx = newDrawContext()

    when defined(android):
      logE i
    else:
      echo i

    glClearColor(32/255, 32/255, 32/255, 1)
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
    redraw window
    inc i
)

