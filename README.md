# siwin
Nim Simple Window Maker

```nim
var win = newWindow()

win.onKeyup = proc(e: KeyEvent) =
  if e.key == escape:
    close win

win.onRender = proc(e: RenderEvent) =
  let r = render win
  r.clear color"202020"

run win
```

just a base to create your own pixel-based graphics

# TODO
* OS Windows suppurt
* multitheading support
