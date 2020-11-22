# siwin
Nim Simple Window Maker

```nim
run newWindow():
  render:
    let r = render win
    r.clear color"202020"
  keyup escape: close window
```

just a base to create your own pixel-based graphics

# TODO
* OS Windows suppurt
* multitheading support
