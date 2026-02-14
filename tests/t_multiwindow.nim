import unittest
import opengl, pixie
import siwin

{.experimental: "overloadableEnums".}

proc testGlobals(): SiwinGlobals =
  when defined(linux) or defined(bsd):
    try:
      newSiwinGlobals(Platform.x11)
    except CatchableError:
      newSiwinGlobals()
  else:
    newSiwinGlobals()

let globals = testGlobals()

proc runCloseDirection(closeLeftFirst: bool): tuple[
    otherTicksAfterFirstClose: int, firstObservedClosed: bool
] =
  let win1 = globals.newOpenglWindow(title="1", transparent=true, class="siwin example")
  let win2 = globals.newOpenglWindow(title="2", size=ivec2(800, 600), class="siwin example")
  loadExtensions()

  var
    ticks1 = 0
    ticks2 = 0
    closeIssued = false
    firstObservedClosed = false
    otherTicksAfterFirstClose = 0

  proc forceCloseBoth() =
    if win1.opened:
      close(win1)
    if win2.opened:
      close(win2)

  let win1eh = WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      makeCurrent e.window
      glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    ,
    onRender: proc(e: RenderEvent) =
      makeCurrent e.window
      glClearColor 0.3, 0.3, 0.3, 0.7
      glClear GlColorBufferBit or GlDepthBufferBit
    ,
    onKey: proc(e: KeyEvent) =
      if e.pressed and not e.generated and e.key == Key.escape:
        forceCloseBoth()
    ,
    onTick: proc(e: TickEvent) =
      inc ticks1
      if closeLeftFirst:
        if not closeIssued and ticks1 >= 60:
          closeIssued = true
          close(win1)
      else:
        if not win2.opened:
          firstObservedClosed = true
          inc otherTicksAfterFirstClose
          if otherTicksAfterFirstClose >= 40 and win1.opened:
            close(win1)
      if ticks1 + ticks2 > 1200:
        forceCloseBoth()
  )

  let win2eh = WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      makeCurrent e.window
      glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    ,
    onRender: proc(e: RenderEvent) =
      makeCurrent e.window
      glClearColor 0.7, 0.7, 0.7, 1
      glClear GlColorBufferBit or GlDepthBufferBit
    ,
    onKey: proc(e: KeyEvent) =
      if e.pressed and not e.generated and e.key == Key.escape:
        forceCloseBoth()
    ,
    onTick: proc(e: TickEvent) =
      inc ticks2
      if not closeLeftFirst:
        if not closeIssued and ticks2 >= 60:
          closeIssued = true
          close(win2)
      else:
        if not win1.opened:
          firstObservedClosed = true
          inc otherTicksAfterFirstClose
          if otherTicksAfterFirstClose >= 40 and win2.opened:
            close(win2)
      if ticks1 + ticks2 > 1200:
        forceCloseBoth()
  )

  runMultiple(
    (win1, win1eh, true),
    (win2, win2eh, true),
  )

  result = (
    otherTicksAfterFirstClose: otherTicksAfterFirstClose,
    firstObservedClosed: firstObservedClosed,
  )


test "2 windows at once":
  let win1 = globals.newOpenglWindow(title="1", transparent=true, class="siwin example")
  let win2 = globals.newOpenglWindow(title="2", size=ivec2(800, 600), class="siwin example")
  loadExtensions()
  var ticks = 0

  let win1eh = WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      makeCurrent e.window
      glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    ,
    onRender: proc(e: RenderEvent) =
      makeCurrent e.window
      glClearColor 0.3, 0.3, 0.3, 0.7
      glClear GlColorBufferBit or GlDepthBufferBit
    ,
    onClick: proc(e: ClickEvent) =
      if e.double:
        close (if win2.opened: win2 else: e.window)
    ,
    onKey: proc(e: KeyEvent) =
      if e.pressed and not e.generated:
        case e.key
        of Key.escape:
          close win1
          close win2
        else: discard
    ,
    onTick: proc(e: TickEvent) =
      inc ticks
      if ticks > 180:
        close win1
        close win2
  )
  var win2eh = win1eh
  
  win2eh.onRender = proc(e: RenderEvent) =
    makeCurrent e.window
    glClearColor 0.7, 0.7, 0.7, 1
    glClear GlColorBufferBit or GlDepthBufferBit
  
  win2eh.onClick = proc(e: ClickEvent) =
    if e.double:
      close (if win1.opened: win1 else: e.window)

  runMultiple(
    (win1, win1eh, true),
    (win2, win2eh, true),
  )

test "close left then keep right alive":
  block runCloseLeft:
    var stats: tuple[otherTicksAfterFirstClose: int, firstObservedClosed: bool]
    try:
      stats = runCloseDirection(closeLeftFirst = true)
    except CatchableError:
      skip()
      break runCloseLeft
    check stats.firstObservedClosed
    check stats.otherTicksAfterFirstClose >= 20

test "close right then keep left alive":
  block runCloseRight:
    var stats: tuple[otherTicksAfterFirstClose: int, firstObservedClosed: bool]
    try:
      stats = runCloseDirection(closeLeftFirst = false)
    except CatchableError:
      skip()
      break runCloseRight
    check stats.firstObservedClosed
    check stats.otherTicksAfterFirstClose >= 20
