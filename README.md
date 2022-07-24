# Siwin

Simple window creation library.  
Can be used as an alternative to GLFW/GLUT/windy  
![Language](https://img.shields.io/badge/language-Nim-orange.svg?style=flat-square) ![Code size](https://img.shields.io/github/languages/code-size/levovix0/siwin?style=flat-square) ![Total Lines](https://img.shields.io/tokei/lines/github/levovix0/siwin?color=purple&style=flat-square)


# Features
* OpenGL and software rendering support
* Linux(X11) and Windows support
* clipboard

# Examples

#### simple window
```nim
import siwin, siwin/image

const color = ColorBgrx(r: 32, g: 32, b: 32, a: 255)

var window = newWindow()

window.onRender = proc(e: RenderEvent) =
  var image = newSeq[ColorBgrx](window.size.x * window.size.y)
  for c in image.mitems:
    c = color
  window.drawImage image, window.size

window.onKeyup = proc(e: KeyEvent) =
  if e.key == Key.escape:
    close window

run window
```

#### OpenGL
![](https://ia.wampi.ru/2021/09/07/31.png)
```nim
import siwin, opengl

var window = newOpenglWindow(title="OpenGL example")
loadExtensions()

window.onResize = proc(e: ResizeEvent) =
  glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
  glMatrixMode GlProjection
  glLoadIdentity()
  glOrtho -30, 30, -30, 30, -30, 30
  glMatrixMode GlModelView

window.onRender = proc(e: RenderEvent) =
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

run window
```

#### pixie
![](https://ia.wampi.ru/2021/09/07/32.png)
```nim
import siwin, pixie

var image: Image
var window = newWindow(title="pixie example")

window.onResize = proc(e: ResizeEvent) =
  image = newImage(e.size.x, e.size.y)

window.onRender = proc(e: RenderEvent) =
  image.fill(rgba(255, 255, 255, 255))

  let ctx = image.newContext
  ctx.fillStyle = rgba(0, 255, 0, 255)

  let
    wh = vec2(250, 250)
    pos = vec2(image.width.float, image.height.float) / 2 - wh / 2
  
  ctx.fillRoundedRect(rect(pos, wh), 25.0)
  
  window.drawImage image.data.toBgrx, ivec2(image.width.int32, image.height.int32)

window.onKeyup = proc(e: KeyEvent) =
  if e.key == Key.escape:
    close window

run window
```

#### clipboard
```nim
import siwin

var window = newWindow()
window.onKeydown = proc(e: KeyEvent) =
  if e.key == Key.c:
    clipboard.text = "some text"
  elif e.key == Key.v:
    echo clipboard.text

  # clipboard $= "text" and $clipboard also works

run window
```

#### offscreen rendering
note: this will create invisible window. `ctx` mustn't be discarded as its destructor will close the window.  
If you have multiple contexts, use `makeCurrent` to select.
```nim
import siwin/offscreen, opengl

let ctx {.used.} = newOpenglContext()
loadExtensions()

# do any opengl computing
```

# TODO
* Wayland support
* copy/paste images
