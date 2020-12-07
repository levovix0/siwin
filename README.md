# siwin
Nim Simple Window Maker

# Features
* window creation and management
* `run` event loop creation macro
* (indirect) access to window pixels
* clipboard
* OS Linux support (using X11)
* OS Windows support

simple window:
```nim
run newWindow():
  render as r:
    r.clear color"202020"
  keyup escape:
    close window
```

pixel access:
```nim
run newWindow(w=screen().size.x, title="render example"):
  render as r:
    r.clear color"202020"
    for i in r.area.a.x..r.area.b.x:
      r[i, i mod window.size.y] = color"ffffff"
```

manage window:
```nim
var win = newWindow()
win.title = "manage example"
win.size = (800, 600)
win.fullscreen = true
win.onKeyup = proc(e: KeyEvent) =
  if e.key == Key.f1:
    win.fullscreen = not win.fullscreen
    win.position = (screen().size.x div 2, screen().size.y div 2)
win.onRender = proc(e: RenderEvent) =
  let r = render win
  r.clear color"202020"
run win  
```

clipboard:
```nim
run newWindow():
  keyup control+c: clipboard.text = "coppied from siwin window!"
  keyup control+v: echo clipboard.text
  keyup shift+c: clipboard $= "other text coppied from siwin window!"
  keyup shift+v: echo $clipboard
```
