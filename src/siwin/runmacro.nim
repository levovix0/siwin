import macros, strformat, strutils, unicode
import window

proc runImpl(w: NimNode, a: NimNode): NimNode =
  a.expectKind nnkStmtList
  result = nnkStmtList.newTree()
  for b in a:
    b.expectKind {nnkCall, nnkCommand}
    
    var eventName = ""
    case b[0].kind
    of nnkIdent: eventName = b[0].strVal
    of nnkDotExpr:
      b[0][1].expectKind nnkIdent
      eventName = b[0][1].strVal
    else: error(&"got {b[0].kind}, but expected ident or dotExpr", b[0])
    if not eventName.startsWith("on"): eventName = "on" & eventName.capitalize
    
    let eventNameIdent = ident eventName
    let body = b[b.len - 1]

    case eventName
    of "onClose":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: CloseEvent) =
          `body`
    of "onRender":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: RenderEvent) =
          `body`
    of "onFocus":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: FocusEvent) =
          `body`
    of "onTick":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: TickEvent) =
          `body`
    of "onResize":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: ResizeEvent) =
          `body`
    of "onWindowMove":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: WindowMoveEvent) =
          `body`

    of "onMouseMove", "onMouseLeave", "onMouseEnter":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: MouseMoveEvent) =
          `body`
    of "onMouseDown", "onMouseUp":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: MouseButtonEvent) =
          `body`
    of "onClick", "onDoubleClick":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: ClickEvent) =
          `body`
    of "onScroll":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: ScrollEvent) =
          `body`

    of "onKeydown", "onKeyup":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: KeyEvent) =
          `body`
    of "onTextEnter":
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: TextEnterEvent) =
          `body`

    of "onCreate":
      result.add quote do:
        `body`
    else: error(&"unknown event: {eventName}", b[0])

  result.add quote do:
    run `w`

macro run*(w: var Window, a: untyped) =
  runImpl w, a

template run*(w: Window, a: untyped) =
  var window {.inject, used.} = w
  run window, a
