import siwin, siwin/image
import unittest, strformat
import nimgl/opengl

test "no render window":
  var a = false

  run newWindow(title="Окошко", renderEngine=none):
    init:      window.cursor = Cursor.hided
    close:     a = true
    keyup esc: close window
    keyup f1:  window.fullscreen = not window.fullscreen
    keydown as k:
      if e.repeated: break
      echo "down ", k
    keyup as k:
      if e.repeated: break
      echo "up ", k
  
  check a == true


test "picture window":
  var win = newWindow(title="Окошко", renderEngine=picture)
  
  var a = false
  win.onClose = proc(e: CloseEvent) =
    a = true
  
  win.cursor = Cursor.arrowUp

  var g = 32

  win.onMouseMove = proc(e: MouseMoveEvent) =
    if e.mouse.pressed[MouseButton.left]:
      g = (e.position.x / win.size.x * 255).int.min(255).max(0)
      redraw win

  win.onRender = proc(e: PictureRenderEvent) =
    let r = render win
    r.clear color(g, g, g)
    for i in r.area.a.x..r.area.b.x:
      r[i, i mod win.size.y] = color"ffffff"
  
  win.onDoubleClick = proc(e: ClickEvent) =
    close win
  
  var x = 0
  win.onTick = proc(e: TickEvent) =
    inc x
  
  win.onKeyup = proc(e: KeyEvent) =
    if e.key == Key.escape:
      close win
    if e.key == f1:
      win.fullscreen = not win.fullscreen
  
  win.onTextInput = proc(e: TextInputEvent) =
    echo e.text
  
  var icon = newImage(32, 32)
  let r = render icon
  r.clear color"FFFF20"
  win.icon = icon
  
  run win
  echo x
  check a == true

test "opengl window":
  var g = 1.0
  run newWindow(title="OpenGL"):
    keyup esc: close window
    keyup f1:  window.fullscreen = not window.fullscreen
    resize as (w, h):
      glViewport 0, 0, w.GLsizei, h.GLsizei
      glMatrixMode GlProjection
      glLoadIdentity()
      glOrtho -30, 30, -30, 30, -30, 30
      glMatrixMode GlModelView
    render:
      glClearColor 0.3, 0.3, 0.3, 0
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
    mouseMove as pos:
      if e.mouse.pressed[MouseButton.left]:
        g = (pos.x / window.size.x * 2).min(2).max(0)
        redraw window
    click(left, right) as (x, _):
      g = (x / window.size.x * 2).min(2).max(0)
      redraw window

test "macro":
  var a = false
  var g = 32
  var x = 0
  var t = true

  run newWindow(title="Окошко", renderEngine=picture):
    init:
      var icon = newImage(32, 32)
      let r = render icon
      r.clear color"FFFF20"
      window.icon = icon

      window.cursor = Cursor.arrowUp

    mouseMove as pos:
      if e.mouse.pressed[MouseButton.left]:
        g = (pos.x / window.size.x * 255).int.min(255).max(0)
        redraw window

    render as r:
      r.clear color(g, g, g)

    doubleClick:     close window
    tick:            inc x; check t
    close:           a = true
    keyup escape:    close window; t = false            #= `keyup: if e.key == escape:`
    keyup f1, f2:    window.fullscreen = not window.fullscreen #= `keyup(f1)|keyup(f2):`
    space.pressing:  g = min(g + 5, 255); redraw window #= `pressing space:`
    pressing:        g = min(g + 1, 255); redraw window #= `tick: if anyKeyIsPressed():`
    # pressing as x: ...                                #= `pressing {.forEachKey.}: let x = magicGetPressedKey();`
    pressing as x[]: echo x                             #= `pressing: let x = magicGetAllPressedKeys();`
    notPressing g:   g = max(g - 1, 0); redraw window   #= `notPressing g:`
    input:           echo e.text

    keydown ctrl+c:  clipboard $= "coppied from siwin"  #= `keydown c: if e.keyboard.pressed[control] and magicOtherKeysIsNotPressed():`
    keydown ctrl-v:  echo $clipboard                    #= `keyup ctrl+v:`

    keydown _+w:     echo "no, press ctrl+w to close window" #= keydown w: if magicOtherKeysIsNotPressed():
    keydown ctrl+w:  close window

    fullscreen on:   g = 255; redraw window
    fullscreen off:  g = 0; redraw window

    click(left, right) as (x, _):
      g = (x / window.size.x * 255).int.min(255).max(0)
      redraw window
      
    keyup(i) or keydown(j): discard
    keyup(a)|keydown(b): discard

    group:
      keyup x: echo "closed with x"
      keyup y: echo "closed with y"
    do:
      close window

    #[
      A as b or B as b: ...
      A|B as b: ...
      # are same
    ]#

    #TODO
    #[
      keyup {.noRepeat.}: ... # исключено повторение клавиш
      {.noRepeat.} # повторение клавиш исключено глобально
      resize {.noInitial.}: ...
    ]#
  
  echo x
  check a == true


test "screen":
  if screenCount == 1:
    let size = screen().size
    echo &"screen().size: {size.x}x{size.y}"
  else:
    for i in 0..<screenCount:
      let size = screen(i).size
      echo &"screen({i}).size: {size.x}x{size.y}"


test "clipboard":
  echo $clipboard   #= `clipboard.text`


suite "readme":
  test "render example":
    run newWindow(w=screen().size.x, title="render example", renderEngine=picture):
      render as r:
        r.clear color"202020"
        for i in r.area.a.x..r.area.b.x:
          r[i, i mod window.size.y] = color"ffffff"
      keyup esc:
        close window


  test "moving and resizing window example":
    var win = newWindow(w=800, h=600, title="moving and resizing example", fullscreen=true, renderEngine=picture)
    win.onKeyup = proc(e: KeyEvent) =
      if e.key == Key.f1:
        win.fullscreen = not win.fullscreen
      elif e.key == Key.f2:
        win.size = (1280, 720)
      elif e.key == Key.escape:
        close win
    win.onRender = proc(e: PictureRenderEvent) =
      let r = render win
      r.clear color"202020"
    win.onFullscreenChanged = proc(e: StateChangedEvent) =
      win.position = (screen().size.x div 2 - win.size.x div 2, screen().size.y div 2 - win.size.y div 2)
    run win
