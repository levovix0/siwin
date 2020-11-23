import siwin
import unittest

test "window":
  var win = newWindow(title="Окошко")
  
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
  let k = [Key.x, Key.y]

  run newWindow(title="Окошко"):
    init:
      var icon = newImage(32, 32)
      let r = render icon
      r.clear color"FFFF20"
      window.icon = icon

      window.cursor = Cursor.arrowUp

    mouseMove:
      if e.mouse.pressed[MouseButton.left]:
        g = min(max(int(e.position.x / window.size.x * 255), 0), 255)
        redraw window

    render:
      let r = render window
      r.clear color(g, g, g)

    doubleClick:    close window
    tick:           inc x
    close:          a = true
    keyup escape:   close window # equivalent `keyup: if e.key == escape:`
    keyup f1, f2:   window.fullscreen = not window.fullscreen # equivalent `keyup [f1, f2]:`
    pressing space: g = min(g + 5, 255); redraw window # equivalent `space.pressing:`
    pressing any:   g = min(g + 1, 255); redraw window # equivalent `pressing:`
    not pressing g: g = max(g - 1, 0); redraw window # equivalent `notPressing g:`
    keyup (k):      close window # equivalent `keyup: if e.key in k:`
    textEnter:      echo e.text
  
  echo x
  check a == true

