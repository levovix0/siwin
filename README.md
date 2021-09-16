# Siwin

Simple window creation library.
Can be used as an alternative to GLFW/GLUT  
![Language](https://img.shields.io/badge/language-Nim-orange.svg?style=flat-square) ![Code size](https://img.shields.io/github/languages/code-size/levovix0/siwin?style=flat-square) ![Total Lines](https://img.shields.io/tokei/lines/github/levovix0/siwin?color=purple&style=flat-square)


# Features
* `run` event loop generation macro
* clipboard
* drawing image without any graphical api's
* OpenGL support
* Linux support (using X11)
* Windows support

# Examples

#### simple window
```nim
import siwin, chroma

run newWindow():
  render:
    var image = newSeq[ColorRGBX](window.size.x * window.size.y)
    for c in image.mitems: c = parseHex("202020").rgbx
    window.drawImage(image)
  keyup esc:
    close window
```

#### OpenGL
![](https://ia.wampi.ru/2021/09/07/31.png)
```nim
import siwin, nimgl/opengl

run newOpenglWindow(title="OpenGL example"):
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

#### pixie
![](https://ia.wampi.ru/2021/09/07/32.png)
```nim
import siwin, pixie

var image: Image
run newWindow(title="pixie example"):
  resize as (w, h):
    image = newImage(w, h)
  render:
    image.fill(rgba(255, 255, 255, 255))

    let ctx = image.newContext
    ctx.fillStyle = rgba(0, 255, 0, 255)

    let
      wh = vec2(250, 250)
      pos = vec2(image.width.float, image.height.float) / 2 - wh / 2
    
    ctx.fillRoundedRect(rect(pos, wh), 25.0)
    
    window.drawImage(image.data)
  keyup esc:
    close window
```

#### clipboard
```nim
import siwin

run newWindow():
  keydown control+c:    clipboard.text = "some text"
  keydown control+v:    echo clipboard.text
  keydown ctrl+shift+c: clipboard $= "other text"
  keydown ctrl+shift+v: echo $clipboard
```

# TODO
* Wayland support
