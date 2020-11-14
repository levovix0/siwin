import siwin
import unittest

test "window":
  when defined(boundChecks):
    echo "xxxxx"
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
  r.clear color(32, 32, 32)
  win.icon = icon
  
  run win
  echo x
  check a == true
