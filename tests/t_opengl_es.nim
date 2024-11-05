import unittest
import opengl, pixie
import siwin
import ./gl

test "OpenGL ES":
  var g = 1.0
  
  let window = newOpenglWindow(title="OpenGL ES test", transparent=true, frameless=true)
  loadExtensions()

  window.setBorderWidth(10, 10, 10)

  window.dragndropClipboard.onContentChanged = proc(e: ClipboardContentChangedEvent) =
    echo "drag available kinds: ", e.availableKinds
    echo "drag available mime types: ", e.availableMimeTypes

    if ClipboardContentKind.files in e.availableKinds:
      echo "got files: ", e.clipboard.files
      window.dragStatus = DragStatus.accepted
    
    if e.availableKinds == {}:
      echo "drop content set to none;"
  
  run window, WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      window.setTitleRegion(vec2(0, 0), vec2(e.size.x.float32, 80))
      if e.size.x > 20 and e.size.y > 20:
        window.setInputRegion(vec2(10, 10), vec2(e.size.x.float32 - 20, e.size.y.float32 - 20))
      
      glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    ,
    onRender: proc(e: RenderEvent) =
      let ctx = newDrawContext()

      glClearColor(127/255/2, 127/255/2, 127/255/2, 1/2)
      # glClearColor(32/255, 32/255, 32/255, 1)
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
            # glCol = vec4(pos.x, pos.y, 0, pos.x * pos.y)
            glCol = vec4(pos.x, pos.y, 0, 1)
        
        # glEnable(GlBlend)
        # glBlendFuncSeparate(GlOne, GlOneMinusSrcAlpha, GlOne, GlOne)
        use shader.shader
        draw ctx.rect
        # glDisable(GlBlend)

      block titleBar:
        let shader = ctx.makeShader:
          {.version: "320 es".}
          proc vert(
            gl_Position: var Vec4,
            pos: var Vec2,
            h: Uniform[float],
            in_pos: Vec2,
          ) =
            gl_Position = vec4(in_pos.x * 2 - 1, -(in_pos.y * h) * 2 + 1, 0, 1)
            pos = in_pos

          proc frag(
            glCol: var Vec4,
            pos: Vec2,
          ) =
            glCol = vec4(0.2, 0.2, 0.2, 1)
        
        use shader.shader
        shader.h.uniform = 80 / e.window.size.y
        draw ctx.rect

      block border:
        let shader = ctx.makeShader:
          {.version: "320 es".}
          proc vert(
            gl_Position: var Vec4,
            pos: var Vec2,
            in_pos: Vec2,
          ) =
            gl_Position = vec4(in_pos.x * 2 - 1, in_pos.y * 2 - 1, 0, 1)
            pos = in_pos

          proc frag(
            glCol: var Vec4,
            pos: Vec2,
            w: Uniform[float],
            h: Uniform[float],
          ) =
            if (pos.x > w*2 and pos.x < 1 - w*2) and (pos.y > h*2 and pos.y < 1 - h*2):
              glCol = vec4(0, 0, 0, 0)
            elif (pos.x > w and pos.x < 1 - w) and (pos.y > h and pos.y < 1 - h):
              glCol = vec4(0.4, 0.4, 0.4, 0.4)
            else:
              glCol = vec4(0, 0, 0, 0.4)
        
        glEnable(GlBlend)
        glBlendFuncSeparate(GlOne, GlOneMinusSrcAlpha, GlOne, GlOne)
        use shader.shader
        shader.w.uniform = 10 / e.window.size.x
        shader.h.uniform = 10 / e.window.size.y
        draw ctx.rect
        glDisable(GlBlend)
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
      if e.kind == MouseMoveKind.moveWhileDragging: echo "draging: ", e.pos
      if MouseButton.left in e.window.mouse.pressed:
        g = (e.pos.x / e.window.size.x.float32 * 2).min(2).max(0)
        redraw e.window
    ,
    onStateBoolChanged: proc(e: StateBoolChangedEvent) =
      echo e.kind, ": ", e.value
    ,
    onScroll: proc(e: ScrollEvent) =
      echo "scroll: ", vec2(e.delta, e.deltaX)
    ,
    onDrop: proc(e: DropEvent) =
      echo "drop;"
  )
