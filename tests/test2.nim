import siwin
import unittest

test "window":
  var win = newWindow(title="Окошко")
  
  var a = false
  win.onClose = proc(e: CloseEvent) =
    a = true
  
  win.cursor = Cursor.arrowUp
  # win.fullscreen = true

  win.onRender = proc(e: RenderEvent) =
    var r = render win
    r.clear color "202020"
    r.fillRect (100, 50), (400, 200), color "40FF40"
  
  win.onDoubleClick = proc(e: ClickEvent) =
    close win
  
  var icon = newImage(32, 32)
  let r = render icon
  r.clear color 0
  r.fillRect (8, 8), (24, 24), color "40FF40"
  win.icon = icon
  
  run win
  check a == true
