import macros, strformat, strutils, unicode, tables
import window

proc high(a: NimNode): int = a.len - 1

proc runImpl(w: NimNode, a: NimNode): NimNode =
  # TODO: `pressingKey as k:` -> `pressingKey: let k = e.keyboard.pressedKey`
  # TODO: `pressingKey as k[]:` -> `pressingKey: let k = e.keyboard.pressedKeys`
  a.expectKind nnkStmtList
  result = nnkStmtList.newTree()

  var res: Table[string, NimNode]
  proc resadd(e: string, body: NimNode) =
    if e notin res: res[e] = nnkStmtList.newTree()
    res[e].add body

  for b in a:
    b.expectKind {nnkCall, nnkCommand, nnkPrefix, nnkInfix}
    
    var eventName = ""
    var pars: seq[NimNode]
    var asNode: NimNode # TODO

    if b.kind == nnkPrefix:
      let b = b[1]
      case b[0].kind
      of nnkIdent: eventName = "not" & b[0].strVal
      of nnkDotExpr:
        b[0][1].expectKind nnkIdent
        eventName = "not" & b[0][1].strVal
        pars.add b[0][0]
      else: error(&"got {b[0].kind}, but expected ident or dotExpr", b[0])
      pars.add b[1..b.high]
    else:
      var b = b

      if b.kind == nnkInfix:
        if b[0] != ident"as": error(&"got {b[0].treeRepr}, but expected `as`, try to place brackets", b[0])
        asNode = b[2]
        var tmp = nnkCall.newTree(b[1])
        for a in b[3..b.high]: tmp.add a
        b = tmp

      case b[0].kind
      of nnkIdent: eventName = b[0].strVal
      of nnkDotExpr:
        b[0][1].expectKind nnkIdent
        eventName = b[0][1].strVal
        pars.add b[0][0]
      else: error(&"got {b[0].kind}, but expected ident or dotExpr", b[0])
      pars.add b[1..<b.high]
    
    if eventName.startsWith("on"): eventName = "on" & eventName[2..eventName.high].capitalize
    else: eventName = "on" & eventName.capitalize
    
    let body = b[b.high]

    case eventName[2..eventName.high].toLower
    of "keydown", "keyup":
      if pars.len == 1 and pars[0] != ident"any":
        var k = pars[0]
        if k.kind == nnkIdent: k = quote do: Key.`k`
        eventName.resadd quote do:
          when compiles(e.key == `k`):
            if e.key == `k`:
              `body`
          elif compiles(e.key in `k`):
            if e.key in `k`:
              `body`
          else:
            if `k`(e.key):
              `body`
      elif pars.len > 1:
        var kk = nnkBracket.newTree()
        for v in pars:
          var k = v
          if k.kind == nnkIdent: k = quote do: Key.`k`
          kk.add k
        eventName.resadd quote do:
          if e.key in `kk`:
            `body`
      else: eventName.resadd body

    of "mousedown", "mouseup":
      if pars.len == 1 and pars[0] != ident"any":
        var k = pars[0]
        if k.kind == nnkIdent: k = quote do: MouseButton.`k`
        eventName.resadd quote do:
          when compiles(e.button == `k`):
            if e.button == `k`:
              `body`
          elif compiles(e.button in `k`):
            if e.key in `k`:
              `body`
          else:
            if `k`(e.button):
              `body`
      elif pars.len > 1:
        var kk = nnkBracket.newTree()
        for v in pars:
          var k = v
          if k.kind == nnkIdent: k = quote do: MouseButton.`k`
          kk.add k
        eventName.resadd quote do:
          if e.button in `kk`:
            `body`
      else: eventName.resadd body

    of "pressingkey", "keypressing", "pressing":
      if pars.len == 1 and pars[0] != ident"any":
        var k = pars[0]
        if k.kind == nnkIdent: k = quote do: Key.`k`
        "onTick".resadd quote do:
          if e.keyboard.pressed[`k`]:
            `body`
      elif pars.len > 1:
        var kk = nnkBracket.newTree()
        for v in pars:
          var k = v
          if k.kind == nnkIdent: k = quote do: Key.`k`
          kk.add k
        "onTick".resadd quote do:
          var prs = false
          for k in `kk`:
            if e.keyboard.pressed[`k`]: prs = true
          if prs:
            `body`
      else:
        "onTick".resadd quote do:
          if true in e.keyboard.pressed:
            `body`

    of "notpressingkey", "notkeypressing", "notpressing":
      if pars.len == 1 and pars[0] != ident"any":
        var k = pars[0]
        if k.kind == nnkIdent: k = quote do: Key.`k`
        "onTick".resadd quote do:
          if not e.keyboard.pressed[`k`]:
            `body`
      elif pars.len > 1:
        var kk = nnkBracket.newTree()
        for v in pars:
          var k = v
          if k.kind == nnkIdent: k = quote do: Key.`k`
          kk.add k
        "onTick".resadd quote do:
          var prs = false
          for k in `kk`:
            if e.keyboard.pressed[`k`]: prs = true
          if not prs:
            `body`
      else:
        "onTick".resadd quote do:
          if false in e.keyboard.pressed:
            `body`

    else: eventName.resadd body

  for eventName, body in res:
    let eventNameIdent = ident eventName

    template eproc(t: typedesc) {.dirty.} =
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: t) =
          `body`

    case eventName[2..eventName.high].toLower
    of "close":  eproc CloseEvent
    of "render": eproc RenderEvent
    of "focus":  eproc FocusEvent
    of "tick":   eproc TickEvent
    of "resize": eproc ResizeEvent
    of "windowmove": eproc WindowMoveEvent
    
    of "mousemove", "mouseleave", "mouseenter": eproc MouseMoveEvent
    of "mousedown", "mouseup": eproc MouseButtonEvent
    of "click", "doubleclick": eproc ClickEvent
    of "scroll": eproc ScrollEvent

    of "keydown", "keyup": eproc KeyEvent
    of "textenter": eproc TextEnterEvent

    of "init":
      result.add quote do:
        `body`
    else: error(&"unknown event: {eventName[2..eventName.high]}")

  result.add quote do:
    run `w`

macro run*(w: var Window, a: untyped) =
  runImpl w, a

template run*(w: Window, a: untyped) =
  var window {.inject, used.} = w
  run window, a
