import unittest
import opengl, pixie
import siwin
import ./gl

test "OpenGL ES":
  var g = 1.0
  
  let window = newOpenglWindow(title="OpenGL ES test", transparent=true)
  loadExtensions()
  
  run window, WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    ,
    onRender: proc(e: RenderEvent) =
      let ctx = newDrawContext()

      glClearColor(32/255/2, 32/255/2, 32/255/2, 1/2)
      # glClearColor(32/255, 32/255, 32/255, 1)
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

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
          # glCol = vec4(pos.x, pos.y, 0, pos.x * pos.y)
          glCol = vec4(pos.x, pos.y, 0, 1)
      
      # glEnable(GlBlend)
      # glBlendFuncSeparate(GlOne, GlOneMinusSrcAlpha, GlOne, GlOne)
      use shader.shader
      draw ctx.rect
      # glDisable(GlBlend)
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
        of Key.f5:
          e.window.pos = e.window.size
        of Key.f6:
          e.window.cursor = Cursor(kind: builtin, builtin: cross)
        else: discard
    ,
    onClick: proc(e: ClickEvent) =
      if e.double:
        close e.window
      else:
        case e.button
        of MouseButton.left, MouseButton.right:
          g = (e.pos.x / e.window.size.x * 2).min(2).max(0)
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
        g = (e.pos.x / e.window.size.x * 2).min(2).max(0)
        redraw e.window
    ,
    onStateBoolChanged: proc(e: StateBoolChangedEvent) =
      echo e.kind, ": ", e.value
    ,
    onScroll: proc(e: ScrollEvent) =
      echo "scroll: ", vec2(e.delta, e.deltaX)
  )
