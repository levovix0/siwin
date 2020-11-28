# siwin
Nim Simple Window Maker

```nim
run newWindow():
  render as r:
    r.clear color"202020"
  keyup escape:
    close window
```

# Release notes:
## 0.2
* run macro
* OS Windows support
## 0.1
* basic window
* OS Linux support (using X11)

# TODO
* multitheading support
