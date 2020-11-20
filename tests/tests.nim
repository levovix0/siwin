import siwin
import unittest

test "window":
  var win = newWindow(title="Окошко")
  
  var a = false
  win.onClose = proc(e: CloseEvent) =
    a = true
  
  win.cursor = Cursor.arrowUp
  # win.fullscreen = true

  var g = 32

  win.onMouseMove = proc(e: MouseMoveEvent) =
    if e.mouse.pressed[MouseButton.left]:
      g = min(max(int(e.position.x / win.size.x * 255), 0), 255)
      display win

  win.onRender = proc(e: RenderEvent) =
    let r = render win
    r.clear color(g, g, g)
  
  win.onDoubleClick = proc(e: ClickEvent) =
    close win
  
  var x = 0
  win.onTick = proc(e: TickEvent) =
    inc x
  
  win.onKeyup = proc(e: KeyEvent) =
    if e.key == escape:
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

  run newWindow(title="Окошко"):
    create:
      var icon = newImage(32, 32)
      let r = render icon
      r.clear color"FFFF20"
      window.icon = icon

      window.cursor = Cursor.arrowUp
      # window.fullscreen = true
    close: a = true
    mouseMove:
      if e.mouse.pressed[MouseButton.left]:
        g = min(max(int(e.position.x / window.size.x * 255), 0), 255)
        display window
    render:
      let r = render window
      r.clear color(g, g, g)
    doubleClick: close window
    tick: inc x
    keyup:
      if e.key == escape:
        close window
      if e.key == f1:
        window.fullscreen = not window.fullscreen
    textEnter: echo e.text
  
  echo x
  check a == true

