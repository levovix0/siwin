import siwin, siwin/image, siwin/opengl
import unittest, strformat

test "no render window":
  var a = false

  run newWindow(title="Окошко", renderEngine=none):
    init:      window.cursor = Cursor.hand
    close:     a = true
    keyup esc: close window
    keyup f1:  window.fullscreen = not window.fullscreen
  
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
      g = min(max(int(e.position.x / win.size.x * 255), 0), 255)
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
  
  win.onTextEnter = proc(e: TextEnterEvent) =
    echo e.text
  
  var icon = newImage(32, 32)
  let r = render icon
  r.clear color"FFFF20"
  win.icon = icon
  
  run win
  echo x
  check a == true

test "opengl window":
  run newWindow(title="OpenGL"):
    keyup esc: close window
    keyup f1:  window.fullscreen = not window.fullscreen
    resize as (w, h):
      glViewport(0, 0, w.GLsizei, h.GLsizei)
      glMatrixMode GlProjection
      glLoadIdentity()
      glOrtho(-30.0, 30.0, -30.0, 30.0, -30.0, 30.0)
      glMatrixMode GlModelView
    render:
      clear 0.3, 0.3, 0.3, 0, BufferBit.color, BufferBit.depth
    
      shade smooth
    
      loadIdentity()
      translate -15, -15, 0
    
      draw triangles:
        color 1, 0, 0
        vertex 0, 0
        color 0, 1, 0
        vertex 30, 0
        color 0, 0, 1
        vertex 0, 30

test "macro":
  var a = false
  var g = 32
  var x = 0
  let k = [Key.x, Key.y]
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
        g = min(max(int(pos.x / window.size.x * 255), 0), 255)
        redraw window

    render as r:
      r.clear color(g, g, g)

    doubleClick:     close window
    tick:            inc x; check t
    close:           a = true
    keyup escape:    close window; t = false            #= `keyup: if e.key == escape:`
    keyup f1, f2:    window.fullscreen = not window.fullscreen #= `keyup [f1, f2]:`
    space.pressing:  g = min(g + 5, 255); redraw window #= `pressing space:`
    pressing any:    g = min(g + 1, 255); redraw window #= `pressing:`
    # pressing as x: ...                                #= `pressing {.forEachKey.}: let x = magicGetPressedKey();`
    pressing as x[]: echo x                             #= `pressing: let x = magicGetAllPressedKeys();`
    not pressing g:  g = max(g - 1, 0); redraw window   #= `notPressing g:`
    keyup (k):       close window                       #= `keyup: if e.key in k:`
    textEnter:       echo e.text

    keydown ctrl+c:  clipboard $= "coppied from siwin"  #= `keydown c: if e.keyboard.pressed[control] and magicOtherKeysIsNotPressed():`
    keydown ctrl+v:  echo $clipboard

    keydown _+w:     echo "no, press ctrl+w to close window" #= keydown w: if magicOtherKeysIsNotPressed():
    keydown ctrl+w:  close window

    fullscreen true:  g = 255; redraw window
    fullscreen false: g = 0; redraw window

    click(left, right) as (x, _): g = min(max(int(x / window.size.x * 255), 0), 255); redraw window

    #TODO
    #[
      group:
        keydown j
        keyup:
          echo "keyup pre-executed"
          defer: echo "keyup post-executed"
      do:
        ... # выполняется при любом из событий в первом блоке. для некоторых событий могут быть указаны дополнительные действия.
      
      group keyup, keydown(j): ...
      keyup or keydown(j): ...
      keyup|keydown(j): ...

      A as b or B as b: ...
      A|B as b: ...
      # are same

      keyup ctrl-c: ... #= keyup ctrl+c

      keyup {.nodup.}: ... # исключено залипание клавиш
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


test "readme render example":
  run newWindow(w=screen().size.x, title="render example", renderEngine=picture):
    render as r:
      r.clear color"202020"
      for i in r.area.a.x..r.area.b.x:
        r[i, i mod window.size.y] = color"ffffff"
    keyup esc:
      close window


test "readme manage window example":
  var win = newWindow(w=800, h=600, title="manage example", fullscreen=true, renderEngine=picture)
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

test "clipboard":
  echo $clipboard   #= `clipboard.text`
