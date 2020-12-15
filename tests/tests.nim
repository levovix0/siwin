import siwin
import unittest, strformat

test "window":
  var win = newWindow(title="Окошко")
  win.initRender()
  
  var a = false
  win.onClose = proc(e: CloseEvent) =
    a = true
  
  win.cursor = Cursor.arrowUp

  var g = 32

  win.onMouseMove = proc(e: MouseMoveEvent) =
    if e.mouse.pressed[MouseButton.left]:
      g = min(max(int(e.position.x / win.size.x * 255), 0), 255)
      redraw win

  win.onRender = proc(e: RenderEvent) =
    let r = render win
    r.clear color(g, g, g)
  
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


test "macro":
  var a = false
  var g = 32
  var x = 0
  let k = [Key.x, Key.y]
  var t = true

  run newWindow(title="Окошко"):
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
    # pressing as x: ...                                #= `pressing: let x = magicGetPressedKey();`
    pressing as x[]: echo x                             #= `pressing: let x = magicGetAllPressedKeys();`
    # render(opengl) as x: ...
    not pressing g:  g = max(g - 1, 0); redraw window   #= `notPressing g:`
    keyup (k):       close window                       #= `keyup: if e.key in k:`
    textEnter:       echo e.text

    keydown ctrl+c:  clipboard $= "coppied from siwin"  #= `keydown c: if e.keyboard.pressed[control] and magicOtherKeysIsNotPressed():`
    keydown ctrl+v:  echo $clipboard

    keydown _+w:     echo "no, press ctrl+w to close window" #= keydown w: if magicOtherKeysIsNotPressed():
    keydown ctrl+w:  close window

    fullscreen true:  g = 255
    fullscreen false: g = 0

    click(left, right) as (x, _): g = min(max(int(x / window.size.x * 255), 0), 255); redraw window
  
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
  run newWindow(w=screen().size.x, title="render example"):
    render as r:
      r.clear color"202020"
      for i in r.area.a.x..r.area.b.x:
        r[i, i mod window.size.y] = color"ffffff"
    keyup escape:
      close window

test "readme manage window example":
  var win = newWindow(w=800, h=600, title="manage example", fullscreen=true)
  win.initRender()
  win.onKeyup = proc(e: KeyEvent) =
    if e.key == Key.f1:
      win.fullscreen = not win.fullscreen
    elif e.key == Key.f2:
      win.size = (1280, 720)
    elif e.key == Key.escape:
      close win
  win.onRender = proc(e: RenderEvent) =
    let r = render win
    r.clear color"202020"
  win.onFullscreenChanged = proc(e: StateChangedEvent) =
    win.position = (screen().size.x div 2 - win.size.x div 2, screen().size.y div 2 - win.size.y div 2)
  run win

test "clipboard":
  echo $clipboard   #= `clipboard.text`
