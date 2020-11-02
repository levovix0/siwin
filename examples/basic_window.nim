import siwim

var win = newWindow(1280, 720, "basic window")

win.onKeyup = proc(e: KeyEvent) =
  if e.key == Key.escape:
    close win

win.onRender = proc(e: RenderEvent) =
  let r = win.renderer
  r.clear color(32, 32, 32)
  r.rectangle 100, 50, 300, 200, color(64, 255, 64)

run win
