import unittest, strformat
import opengl, pixie
import siwin

{.experimental: "overloadableEnums".}

let globals = newSiwinGlobals()


test "2 windows at once":
  let win1 = globals.newOpenglWindow(title="1", transparent=true, class="siwin example")
  let win2 = globals.newOpenglWindow(title="2", size=ivec2(800, 600), class="siwin example")
  loadExtensions()

  let win1eh = WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      makeCurrent e.window
      glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    ,
    onRender: proc(e: RenderEvent) =
      makeCurrent e.window
      glClearColor 0.3, 0.3, 0.3, 0.7
      glClear GlColorBufferBit or GlDepthBufferBit
    ,
    onClick: proc(e: ClickEvent) =
      if e.double:
        close (if win2.opened: win2 else: e.window)
    ,
    onKey: proc(e: KeyEvent) =
      if e.pressed and not e.generated:
        case e.key
        of Key.escape:
          close win1
          close win2
        else: discard
  )
  var win2eh = win1eh
  
  win2eh.onRender = proc(e: RenderEvent) =
    makeCurrent e.window
    glClearColor 0.7, 0.7, 0.7, 1
    glClear GlColorBufferBit or GlDepthBufferBit
  
  win2eh.onClick = proc(e: ClickEvent) =
    if e.double:
      close (if win1.opened: win1 else: e.window)

  runMultiple(
    (win1, win1eh, true),
    (win2, win2eh, true),
  )

