# Siwin

Simple window creation library.
Can be used as an alternative to GLFW/GLUT  
![Language](https://img.shields.io/badge/language-Nim-orange.svg?style=flat-square) ![Code size](https://img.shields.io/github/languages/code-size/levovix0/siwin?style=flat-square) ![Total Lines](https://img.shields.io/tokei/lines/github/levovix0/siwin?color=purple&style=flat-square)


# Features
* `run` event loop generation macro
* clipboard
* drawing image without any graphical api's
* OpenGL
* Linux support (using X11)
* Windows support

# Examples

#### simple window
```nim
run newWindow(renderEngine=picture):
  render:
    for c in e.image[].mitems: c = color"202020"
  keyup esc:
    close window
```

#### opengl
```nim
import nimgl/opengl

run newWindow():
  init:
    doassert glInit()
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

#### draw pixels
```nim
run newWindow(w=screen().size.x, title="render example", renderEngine=picture):
  render:
    for c in e.image[].mitems: c = color"202020"
    for i in 0..<e.image[].w:
      e.image[][i, i mod e.image[].h] = color"ffffff"
  keyup esc:
    close window
```

#### clipboard
```nim
run newWindow():
  keydown control+c:    clipboard.text = "some text"
  keydown control+v:    echo clipboard.text
  keydown ctrl+shift+c: clipboard $= "other text"
  keydown ctrl+shift+v: echo $clipboard
```

# TODO
* Wayland support
