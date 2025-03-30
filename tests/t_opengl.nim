import unittest
import opengl, vmath
import siwin

let globals = newSiwinGlobals(
  preferedPlatform = (when defined(linux): x11 else: defaultPreferedPlatform())
)

test "OpenGL":
  var g = 1.0
  
  let window = globals.newOpenglWindow(title="OpenGL test", transparent=true)
  loadExtensions()
  
  run window, WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
      glMatrixMode GlProjection
      glLoadIdentity()
      glOrtho -30, 30, -30, 30, -30, 30
      glMatrixMode GlModelView
    ,
    onRender: proc(e: RenderEvent) =
      glClearColor 0.1, 0.1, 0.1, 0.3
      glClear GlColorBufferBit or GlDepthBufferBit
    
      glShadeModel GlSmooth
    
      glLoadIdentity()
      glTranslatef -15, -15, 0
    
      glBegin GlTriangles
      glColor3f 1 * g, g - 1, g - 1
      glVertex2f 0, 0
      glColor3f g - 1, 1 * g, g - 1
      glVertex2f 30, 0
      glColor3f g - 1, g - 1, 1 * g
      glVertex2f 0, 30
      glEnd()
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
  )
