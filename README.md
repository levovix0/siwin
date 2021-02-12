# Siwin

Simple window creation library.
Can be used as an alternative to GLFW/GLUT
![Language](https://img.shields.io/badge/language-Nim-orange.svg?style=flat-square) ![Code size](https://img.shields.io/github/languages/code-size/levovix0/siwin?style=flat-square) ![Total Lines](https://img.shields.io/tokei/lines/github/levovix0/siwin?color=purple&style=flat-square)


# Features
* window creation and simple management
* `run` event loop generation macro
* clipboard
* OpenGl support
* render in window using picture (access pixels)
* OS Linux support (using X11)
* OS Windows support

# Examples

#### simple window
```nim
run newWindow(renderEngine=picture):
  render as r:
    r.clear color"202020"
  keyup esc:
    close window
```

#### opengl
```nim
import nimgl/opengl

run newWindow(): # opengl is render engine by default
  resize as (w, h):
    glViewport 0, 0, w.GLsizei, h.GLsizei
    glMatrixMode GlProjection
    glLoadIdentity()
    glOrtho -30, 30, -30, 30, -30, 30
    glMatrixMode GlModelView
  render:
    glClearColor 0.3, 0.3, 0.3, 0
    glClear GlColorBufferBit or GlDepthBufferBit
  
    glShadeModel GlSmooth
  
    glLoadIdentity()
    glTranslatef -15, -15, 0
  
    glBegin GlTriangles
    glColor3f 1, 0, 0
    glVertex2f 0, 0
    glColor3f 0, 1, 0
    glVertex2f 30, 0
    glColor3f 0, 0, 1
    glVertex2f 0, 30
    glEnd()
```

#### pixel access
```nim
run newWindow(w=screen().size.x, title="render example", renderEngine=picture):
  render as r:
    r.clear color"202020"
    for i in r.area.a.x..r.area.b.x:
      r[i, i mod window.size.y] = color"ffffff"
```

#### clipboard
```nim
run newWindow():
  keydown control+c:    clipboard.text = "some text"
  keydown control+v:    echo clipboard.text
  keydown ctrl+shift+c: clipboard $= "other text"
  keydown ctrl+shift+v: echo $clipboard
```

#### moving and resizing window
```nim
var win = newWindow(w=800, h=600, title="moving and resizing example", fullscreen=true, renderEngine=picture)
win.onKeyup = proc(e: KeyEvent) =
  if e.key == Key.f1:
    win.fullscreen = not win.fullscreen
  elif e.key == Key.f2:
    win.size = (1280, 720)
  elif e.key == Key.escape:
    close win
win.onRender = proc(e: RenderEvent) =
  let r = render win
  r.clear color"202020"
win.onFullscreenChanged = proc(e: StateChangedEvent) =
  win.position = (screen().size.x div 2 - win.size.x div 2, screen().size.y div 2 - win.size.y div 2)
run win
```

# TODO
* Wayland support
* Vulkan support
* web support
* Android support
* joystick support
