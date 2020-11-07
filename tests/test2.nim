import siwin
import unittest

template `:=`(name, value) =
  var name {.inject.} = value

test "window":
  win := newWindow(title="Окошко")
  
  a := false
  win.onClose = proc(e: CloseEvent) =
    a = true
  
  win.cursor = Cursor.arrowUp
  # win.fullscreen = true

  pos := vec2(100, 200)

  win.onMouseMove = proc(e: MouseMoveEvent) =
    if e.mouse.pressed[left]:
      pos = e.position
      display win

  win.onRender = proc(e: RenderEvent) =
    var r = render win
    r.clear color "202020"
    r.rect (200, 100), (300, 250), color "FF4040"
    r.fillRect (100, 50), (400, 200), color "cc40FF40"
    r.linef (10, 10), (pos.x, pos.y), color "4040FF"
  
  win.onDoubleClick = proc(e: ClickEvent) =
    close win
  
  x := 0
  win.onTick = proc(e: TickEvent) =
    inc x
  
  win.onKeyup = proc(e: KeyEvent) =
    if e.key == Key.escape:
      close win
    if e.key == Key.f1:
      win.fullscreen = not win.fullscreen
  
  win.onTextEnter = proc(e: TextEnterEvent) =
    echo e.text
  
  icon := newImage(32, 32)
  r := render icon
  r.clear color 0
  r.rect (8, 8), (24, 24), color "40FF40"
  win.icon = icon
  
  run win
  echo x
  check a == true
