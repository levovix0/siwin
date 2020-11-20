import macros, strformat, strutils, unicode, tables
import window

proc high(a: NimNode): int = a.len - 1

proc runImpl(w: NimNode, a: NimNode): NimNode =
  a.expectKind nnkStmtList
  result = nnkStmtList.newTree()

  var res: Table[string, NimNode]
  proc resadd(e: string, body: NimNode) =
    if e notin res: res[e] = nnkStmtList.newTree()
    res[e].add body

  for b in a:
    b.expectKind {nnkCall, nnkCommand}
    
    var eventName = ""
    var pars: seq[NimNode]

    case b[0].kind
    of nnkIdent: eventName = b[0].strVal
    of nnkDotExpr:
      b[0][1].expectKind nnkIdent
      eventName = b[0][1].strVal
      pars.add b[0][0]
    else: error(&"got {b[0].kind}, but expected ident or dotExpr", b[0])
    
    eventName = "on" & eventName
    
    pars.add b[1..<b.high]
    let body = b[b.high]

    case eventName[2..eventName.high].toLower
    of "keydown", "keyup":
      if pars.len == 1:
        var k = pars[0]
        if k.kind == nnkIdent: k = quote do: Key.`k`
        eventName.resadd quote do:
          if e.key == `k`:
            `body`
      else: eventName.resadd body
    else: eventName.resadd body

  for eventName, body in res:
    let eventNameIdent = ident eventName

    case eventName[2..eventName.high].toLower
    of "close":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: CloseEvent) =
          `body`
    of "render":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: RenderEvent) =
          `body`
    of "focus":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: FocusEvent) =
          `body`
    of "tick":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: TickEvent) =
          `body`
    of "resize":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: ResizeEvent) =
          `body`
    of "windowmove":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: WindowMoveEvent) =
          `body`

    of "mousemove", "mouseleave", "mouseenter":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: MouseMoveEvent) =
          `body`
    of "mousedown", "mouseup":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: MouseButtonEvent) =
          `body`
    of "click", "doubleclick":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: ClickEvent) =
          `body`
    of "scroll":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: ScrollEvent) =
          `body`

    of "keydown", "keyup":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: KeyEvent) =
          `body`
    of "textenter":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: TextEnterEvent) =
          `body`

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
