import macros, strformat, strutils, unicode, tables
import window

proc high(a: NimNode): int = a.len - 1

proc runImpl(w: NimNode, a: NimNode): NimNode =
  # TODO: `render(siwingl) as r:` -> `init: initSiwinglRender(window); render: let r = siwinglRender(window.toPicture());`
  # TODO: `render as r:`, `render(user) as r:` -> `render: let r = render(window);`
  a.expectKind nnkStmtList
  result = nnkStmtList.newTree()

  var res: Table[string, NimNode]
  proc resadd(e: string, body: NimNode) =
    if e notin res: res[e] = nnkStmtList.newTree()
    res[e].add quote do:
      block: `body`

  for b in a:
    b.expectKind {nnkCall, nnkCommand, nnkPrefix, nnkInfix}
    
    var eventName = ""
    var pars: seq[NimNode]
    var asNode: NimNode
    template resaddastu(ename: string; a, tu, arr, body: untyped) =
      if asNode == nil:
        ename.resadd quote do:
          body
      else:
        case asNode.kind
        of nnkIdent:
          ename.resadd quote do:
            let `asNode` {.inject.} = a
            body
        of nnkPar:
          var r = nnkVarTuple.newTree
          for c in asNode:
            r.add nnkPragmaExpr.newTree(c, nnkPragma.newTree(ident"inject"))
          r.add nnkEmpty.newNimNode
          r.add quote do: tu
          ename.resadd nnkStmtList.newTree(nnkLetSection.newTree(r), quote do: body)
        of nnkBracketExpr:
          asNode = asNode[0]
          asNode.expectKind nnkIdent
          asNode.expectLen 1
          ename.resadd quote do:
            let `asNode` {.inject.} = arr
            body
        else: error(&"got {asNode.kind}, but expected ident, ident[] or tuple", asNode)
    template resaddas(ename: string; a, arr, body: untyped) = ename.resaddastu a, a, arr, body
    template resaddastu(ename: string; a, tu, body: untyped) =
      if asNode == nil:
        ename.resadd quote do:
          body
      else:
        case asNode.kind
        of nnkIdent:
          ename.resadd quote do:
            let `asNode` {.inject.} = a
            body
        of nnkPar:
          var r = nnkVarTuple.newTree
          for c in asNode:
            r.add nnkPragmaExpr.newTree(c, nnkPragma.newTree(ident"inject"))
          r.add nnkEmpty.newNimNode
          r.add quote do: tu
          ename.resadd nnkStmtList.newTree(nnkLetSection.newTree(r), quote do: body)
        else: error(&"got {asNode.kind}, but expected ident or tuple", asNode)
    template resaddas(ename: string; a, body: untyped) = ename.resaddastu a, a, body
    template resaddasdo(ename: string, noas: untyped, a: untyped, arr: untyped) =
      if asNode == nil:
        ename.resadd quote do:
          noas
      else:
        case asNode.kind
        of nnkIdent:
          ename.resadd quote do:
            a
        of nnkPar:
          var r = nnkVarTuple.newTree
          for c in asNode:
            r.add nnkPragmaExpr.newTree(c, nnkPragma.newTree(ident"inject"))
          r.add nnkEmpty.newNimNode
          r.add quote do: a
          ename.resadd nnkStmtList.newTree(nnkLetSection.newTree(r), quote do: body)
        of nnkBracketExpr:
          asNode = asNode[0]
          asNode.expectKind nnkIdent
          ename.resadd quote do:
            arr
        else: error(&"got {asNode.kind}, but expected ident, ident[] or tuple", asNode)

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
        var tmp = if b[1].kind == nnkIdent: nnkCall.newTree(b[1]) else: b[1]
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
        "onTick".resaddas `k`:
          if e.keyboard.pressed[`k`]:
            `body`
      elif pars.len > 1:
        var kk = nnkBracket.newTree()
        for v in pars:
          var k = v
          if k.kind == nnkIdent: k = quote do: Key.`k`
          kk.add k
        "onTick".resaddasdo do:
          var prs = false
          for k in `kk`:
            if e.keyboard.pressed[k]: prs = true; break
          if prs:
            `body`
        do:
          var `asNode` {.inject.} = Key.unknown
          for k in `kk`:
            if e.keyboard.pressed[k]: `asNode` = k; break
          if `asNode` != Key.unknown:
            `body`
        do:
          var `asNode` {.inject.}: seq[Key]
          for k in `kk`:
            if e.keyboard.pressed[k]: `asNode`.add k
          if `asNode`.len > 0:
            `body`
      else:
        "onTick".resaddasdo do:
          if true in e.keyboard.pressed:
            `body`
        do:
          var `asNode` {.inject.} = Key.unknown
          for k, v in e.keyboard.pressed:
            if v: `asNode` = k; break
          if `asNode` != Key.unknown:
            `body`
        do:
          var `asNode` {.inject.}: seq[Key]
          for k, v in e.keyboard.pressed:
            if v: `asNode`.add k
          if `asNode`.len > 0:
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
            if e.keyboard.pressed[k]: prs = true
          if not prs:
            `body`
      else:
        "onTick".resadd quote do:
          if false in e.keyboard.pressed:
            `body`

    of "click":
      if pars.len == 1 and pars[0] != ident"any":
        var k = pars[0]
        if k.kind == nnkIdent: k = quote do: MouseButton.`k`
        eventName.resaddas e.position:
          if e.button == `k`:
            `body`
      if pars.len > 1:
        var kk = nnkBracket.newTree()
        for v in pars:
          var k = v
          if k.kind == nnkIdent: k = quote do: MouseButton.`k`
          kk.add k
        eventName.resaddas e.position:
          if e.button in `kk`:
            `body`
      else:
        eventName.resaddastu e.button, (btn: e.button, pos: e.position): `body`

    of "textenter":
      eventName.resaddas e.text, e.text.toRunes: `body`
    of "render":
      eventName.resaddas `w`.render: `body`
    of "focus":
      eventName.resaddas e.focused: `body`

    of "scroll":
      eventName.resaddas e.delta: `body`
    of "mousemove", "mouseleave", "mouseenter", "windowmove":
      eventName.resaddastu e.position, (old: e.oldPosition, cur: e.position): `body`
    of "resize":
      eventName.resaddastu e.size, (old: e.oldSize, cur: e.size): `body`
    # TODO: render(renderEngine)

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
