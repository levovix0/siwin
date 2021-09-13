import siwin
import siwin/image except Image, newImage
import unittest, strformat
import nimgl/opengl, pixie


test "screen":
  if screenCount == 1:
    let size = screen().size
    echo &"screen().size: {size.x}x{size.y}"
  else:
    for i in 0..<screenCount:
      let size = screen(i).size
      echo &"screen({i}).size: {size.x}x{size.y}"


test "macro":
  var a = false
  var g = 32
  var x = 0
  var t = true

  run newWindow(title="Окошко"):
    init:
      var icon = image.newImage(32, 32)
      for c in icon.mitems: c = parseHex("FFFF20").rgbx
      window.icon = icon

      window.cursor = Cursor.arrowUp

    mouseMove as pos:
      if e.mouse.pressed[MouseButton.left]:
        g = (pos.x / window.size.x * 255).int.min(255).max(0)
        redraw window

    render:
      var image = newSeq[ColorRGBX](window.size.x * window.size.y)
      for c in image.mitems: c = rgbx(g.uint8, g.uint8, g.uint8, 255)
      window.drawImage(image)

    doubleClick:     close window
    tick:            inc x; check t
    close:           a = true
    keyup escape:    close window; t = false            #= `keyup: if e.key == escape:`
    keyup f1, f2:    window.fullscreen = not window.fullscreen #= `keyup(f1)|keyup(f2):`
    space.pressing:  g = min(g + 5, 255); redraw window #= `pressing space:`
    pressing:        g = min(g + 1, 255); redraw window #= `tick: if anyKeyIsPressed():`
    # pressing as x: ...                                #= `pressing {.forEachKey.}: let x = magicGetPressedKey();`
    pressing as x[]: echo x                             #= `pressing: let x = magicGetAllPressedKeys();`
    notPressing g:   g = max(g - 1, 0); redraw window
    input:           echo e.text

    keydown ctrl+c:  clipboard $= "coppied from siwin"  #= `keydown c: if e.keyboard.pressed[control] and magicOtherKeysIsNotPressed():`
    keydown ctrl-v:  echo $clipboard                    #= `keyup ctrl+v:`

    keydown _+w:     echo "no, press ctrl+w to close window" #= keydown w: if magicOtherKeysIsNotPressed():
    keydown ctrl+w:  close window

    fullscreen on:   g = 255; redraw window
    fullscreen off:  g = 0; redraw window

    click(left, right) as (x, _):
      g = (x / window.size.x * 255).int.min(255).max(0)
      redraw window
      
    keyup(i) or keydown(j): discard
    keyup(a)|keydown(b): discard

    group:
      keyup x: echo "closed using x"
      keyup y: echo "closed using y"
    do:
      close window

    #[
      A as b or B as b: ...
      A|B as b: ...
      # are same
    ]#

    #TODO
    #[
      keyup {.noRepeat.}: ... # исключено повторение клавиш
      {.noRepeat.} # повторение клавиш исключено глобально
      resize {.noInitial.}: ...
    ]#
  
  echo x
  check a == true


test "OpenGL":
  var g = 1.0
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
      glColor3f 1 * g, g - 1, g - 1
      glVertex2f 0, 0
      glColor3f g - 1, 1 * g, g - 1
      glVertex2f 30, 0
      glColor3f g - 1, g - 1, 1 * g
      glVertex2f 0, 30
      glEnd()
    keyup esc:
      close window
    keyup esc: close window
    keyup f1:  window.fullscreen = not window.fullscreen
    mouseMove as pos:
      if e.mouse.pressed[MouseButton.left]:
        g = (pos.x / window.size.x * 2).min(2).max(0)
        redraw window
    click(left, right) as (x, _):
      g = (x / window.size.x * 2).min(2).max(0)
      redraw window


test "pixie":
  var image: Image
  run newWindow(title="pixie example"):
    resize as (w, h):
      image = newImage(w, h)
    render:
      image.fill(rgba(255, 255, 255, 255))

      let ctx = image.newContext
      ctx.fillStyle = rgba(50, 50, 255, 255)

      let
        wh = vec2(250, 250)
        pos = vec2(image.width.float, image.height.float) / 2 - wh / 2
      
      ctx.fillRoundedRect(rect(pos, wh), 25.0)
      
      window.drawImage(image.data)
    keyup esc:
      close window
