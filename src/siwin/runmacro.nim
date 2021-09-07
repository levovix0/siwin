import macros, strformat, strutils, unicode, tables, sequtils, algorithm, utils, sugar, sinim
import window

type
  SomeWindow = Window|PictureWindow|OpenglWindow

  KeyBinding* = distinct set[Key]


proc kindStrings(a: typedesc): seq[string] {.compileTime.} =
  let b = a.getTypeImpl
  b.expectKind nnkEnumTy
  for c in b:
    if c.kind == nnkSym: result.add c.strVal.toNimUniversal

# for compilation speed
const keyKindStrings = Key.kindStrings
const mouseButtonKindStrings = MouseButton.kindStrings

proc ofEnum(a: NimNode, b: typedesc): NimNode =
  ## converts node to explicit enum element if it exists
  template possible: seq[string] =
    when b is typedesc[Key]: keyKindStrings
    elif b is typedesc[MouseButton]: mouseButtonKindStrings
    else: b.kindStrings

  if a.kind == nnkIdent and a.strVal.toNimUniversal in possible:
    nnkDotExpr.newTree(quote do: `b`, a)
  else:
    a


proc keys*(e: KeyEvent): set[Key] = e.keyboard.pressed + {e.key}
template keys*(e: TickEvent): set[Key] = e.keyboard.pressed


var keyBindings* {.compileTime.}: Table[string, KeyBinding]

proc contains*(a: set[Key], v: set[Key]): bool =
  (a * v).len != 0
proc contains*(a: set[Key], v: KeyBinding): bool =
  set[Key](v) in a

static:
  template `==>`(a: untyped, b: set[Key]) =
    keyBindings[astToStr(a)] = KeyBinding b
  template `==>`(a: untyped, b: string) =
    keyBindings[astToStr(a)] = keyBindings[b]

  control ==> {lcontrol, rcontrol}
  ctrl    ==> "control"

  shift   ==> {lshift, rshift}

  alt     ==> {lalt, ralt}

  system  ==> {lsystem, rsystem}
  meta    ==> "system"
  super   ==> "system"
  windows ==> "system"
  win     ==> "system"

  esc     ==> {Key.escape}


proc ofKeysImpl(a: openarray[NimNode]): seq[NimNode] =
  for a in a:
    if a.kind == nnkIdent and keyBindings.hasKey $a:
      result.add ((set[Key])keyBindings[$a]).toSeq.map(newLit)
    else:
      result.add a.ofEnum(Key)
proc ofKeys(a: openarray[NimNode]): NimNode =
  nnkCurly.newTree a.ofKeysImpl
proc ofKeys(a: NimNode): NimNode =
  nnkCurly.newTree [a].ofKeysImpl


type
  EventHeader = tuple
    name: string
    args: seq[NimNode]
    nameNode: NimNode
  AsPair = tuple
    head: EventHeader
    res: NimNode
  Event = tuple
    head: AsPair
    body: NimNode
  
  RunParser = object
    windowNode: NimNode
    renderEngine: RenderEngine
  EventOutput = tuple
    name: string
    body: NimNode


template nameNode(a: Event): auto = a.head.head.nameNode
template name(a: Event): auto = a.head.head.name
template args(a: Event): auto = a.head.head.args
template res(a: Event): auto = a.head.res
proc toFlatTuple(a: Event): tuple[name: string, body: NimNode, args: seq[NimNode], res: NimNode] =
  (a.name, a.body, a.args, a.res)


proc `parse header`(a: NimNode): EventHeader =
  a.expectKind {nnkIdent, nnkCall, nnkCommand}
  case a.kind
  of nnkIdent:
    result.nameNode = a
  of nnkCall, nnkCommand:
    if a[0].kind == nnkDotExpr:
      result.nameNode = a[0][1]
      result.args &= a[0][0]
    else:
      result.nameNode = a[0]
    for b in a[1..^1]:
      if b.kind == nnkStmtList:
        result.args &= b[0..^1]
      else:
        result.args &= b
  else: discard
  result.name = result.nameNode.`$`.replace("_", "").toLower

proc `parse |`(a: NimNode): seq[EventHeader] =
  a.flattenInfix("|").map(`parse header`)

proc `parse as`(a: NimNode): seq[AsPair] =
  if a.kind == nnkInfix and $a[0] == "as":
    for b in a[1].`parse |`:
      result &= (b, a[2])
  else:
    result = a.`parse |`.mapit((it, nil.NimNode))

proc `parse or`(a: NimNode): seq[AsPair] =
  for b in a.flattenInfix("or"):
    result &= b.`parse as`

proc `parse event`(a: NimNode): seq[Event] =
  if a.kind == nnkIdent:
    @[((a.`parse header`, nil.NimNode), nil.NimNode)]
  elif a.last.kind == nnkStmtList:
    a.kind.newTree(a[0..^2]).`parse or`.mapit((it, a[^1]))
  else:
    a.`parse or`.mapit((it, nil.NimNode))


proc translateKeyCombination(a: NimNode): NimNode =
  var keys = flattenInfix a

  let needEx = ident"_" in keys or keys.len > 1
  keys.delete ident"_"

  if needEx:
    let ex = keys.ofKeys
    result = quote do: (e.keys - `ex`).len == 0
    for c in keys:
      let kx = c.ofKeys
      result = quote do: (e.keys * `kx`).len > 0 and `result`
  else:
    let kx = keys.ofKeys
    result = quote do: (e.keys * `kx`).len > 0


proc translateEvent(rp: RunParser, a: Event): seq[EventOutput] =
  template add(e: string, body: NimNode) =
    result.add (e, nnkBlockStmt.newTree(newEmptyNode(), body))
  var (name, body, args, res) = a.toFlatTuple

  var genAs: proc(v: NimNode): NimNode = proc(v: NimNode): NimNode = discard
  var asKind = nnkEmpty
  if res != nil:
    asKind = res.kind
    
    case asKind
    of nnkIdent: discard
    of nnkPar:
      var r = nnkVarTuple.newTree
      for c in res:
        r &= nnkPragmaExpr.newTree(c, nnkPragma.newTree(ident"inject"))
      r &= nnkEmpty.newNimNode
      res = r
    of nnkBracketExpr:
      res.expectLen 1
      res = res[0]
      res.expectKind nnkIdent
    else: error(&"got {res.kind}, but expected ident, ident[] or tuple", res)

    case asKind
    of nnkIdent, nnkBracketExpr:
      genAs = proc(v: NimNode): NimNode = quote do:
        let `res` {.inject.} = `v`
    of nnkPar:
      genAs = proc(v: NimNode): NimNode =
        var r = res
        r.add v
        return nnkLetSection.newTree(r)
    else: discard

  proc sellectAs(a: NimNode, arr: NimNode): NimNode =
    if asKind == nnkBracketExpr: genAs(arr)
    else: genAs(a)
  proc sellectAs(a: NimNode): NimNode =
    if asKind == nnkBracketExpr: error(&"can't get event res as array", res)
    else: return genAs(a)


  let e = ident"e"
  
  template addas(ename: string; a, arr, body: untyped) =
    let asl = sellectAs(quote do: a, quote do: arr)
    let b = quote do: body
    if asl != nil: ename.add newStmtList(asl, b)
    else:          ename.add b

  template addas(ename: string; a, body: untyped) =
    let asl = sellectAs(quote do: a)
    let b = quote do: body
    if asl != nil: ename.add newStmtList(asl, b)
    else:          ename.add b

  case name
  of "group": # meta-event
    for c in args.map(`parse event`).concat:
      var c = c
      c.body =
        if c.body == nil: body
        else: newStmtList(c.body, body)
      result.add rp.translateEvent c
  
  of "render":
    case rp.renderEngine
    of RenderEngine.picture, RenderEngine.opengl:
      "render".add body
    else:
      error "can't render on window (no render engine)", a.nameNode
  
  of "input", "textinput", "textenter":
    "textinput".addas `e`.text, `e`.text.toRunes: `body`
  of "focus":
    "focus".addas `e`.focused: `body`
  
  of "fullscreenchanged", "fullscreen":
    if args.len > 1: error(&"got {args.len} parametrs, but expected one of (), (state)", args[1])
    elif args.len == 1:
      let c = args[0]
      "fullscreenchanged".addas `e`.state:
        if `e`.state == `c`:
          `body`
    else:
      "fullscreenchanged".addas `e`.state: `body`

  of "scroll":
    case args.len
    of 0:
      "scroll".addas `e`.delta: `body`
    of 1:
      if args[0] == ident"down": "scroll".addas `e`.delta:
        if `e`.delta > 0: `body`
      elif args[0] == ident"up": "scroll".addas (-`e`.delta):
        if `e`.delta < 0: `body`
      else: error(&"unknown direction {args[0]}, expected down|up", args[0])
    else: error(&"got {args.len} parametrs, but expected one of (), (direction)", args[1])

  of "mousemove", "mouseleave", "mouseenter", "windowmove":
    name.addas `e`.position: `body`
  of "resize":
    name.addas `e`.size: `body`
  
  of "keydown", "keyup":
    case args.len
    of 0:
      name.addas `e`.key, `e`.keys: `body`
    of 1:
      var c = args[0].translateKeyCombination
      name.add quote do:
        if `c`: `body`
    else:
      var c = args.map(translateKeyCombination).expandInfix(ident"or")
      name.add quote do:
        if `c`: `body`

  of "mousedown", "mouseup":
    case args.len
    of 0:
      name.addas `e`.button: `body`
    of 1:
      let k = args[0].ofEnum(MouseButton)
      name.add quote do:
        if check(e.button, `k`):
          `body`
    else:
      let kk = nnkBracket.newTree args.mapit(it.ofEnum MouseButton)
      name.add quote do:
        if e.button in `kk`:
          `body`

  of "pressingkey", "keypressing", "pressing":
    let kk =
      if args.len < 1: bindSym"AllKeys"
      else: args.ofKeys
    case asKind
    of nnkEmpty:
      "tick".add quote do:
        if (`e`.keys * `kk`).len > 0:
          `body`
    of nnkIdent:
      "tick".add quote do:
        for k in `e`.keys * `kk`:
          let `res` {.inject.} = k
          `body`
    of nnkBracketExpr:
      "tick".add quote do:
        var `res` {.inject.} = `e`.keys * `kk`
        if `res`.len > 0:
          `body`
    else: error(&"got {res.kind}, but expected ident or ident[]", res)
  
  of "notpressingkey", "notkeypressing", "notpressing":
    var kk = args.ofKeys
    "tick".add quote do:
      if (`e`.keys * `kk`).len == 0:
        `body`
  
  of "click":
    case args.len
    of 0:
      name.addas `e`.position: `body`
    of 1:
      var k = args[0].ofEnum(MouseButton)
      name.addas `e`.position:
        if `e`.button == `k`:
          `body`
    else:
      var kk = nnkCurly.newTree args.mapit(it.ofEnum(MouseButton))
      name.addas `e`.position:
        if `e`.button in `kk`:
          `body`

  else: name.add body

proc translateEvent(rp: RunParser, a: NimNode): seq[EventOutput] =
  a.`parse event`.mapit(rp.translateEvent it).concat


proc runImpl(win, a: NimNode, re: RenderEngine): NimNode =
  result = newStmtList()

  var rp: RunParser
  rp.renderEngine = re
  rp.windowNode = win

  a.expectKind nnkStmtList

  var outp: Table[string, NimNode]
  for (name, body) in a.mapit(rp.translateEvent it).concat:
    if name notin outp: outp[name] = newStmtList()
    outp[name] &= body

  for name, body in outp:
    let wev = nnkDotExpr.newTree(win, ident("on" & name))
    proc eproct(t: typedesc): NimNode =
      ## window.onX = proc(e: XEvent) = body
      nnkStmtList.newTree(
        nnkAsgn.newTree(
          wev,
          nnkLambda.newTree(
            newEmptyNode(),
            newEmptyNode(),
            newEmptyNode(),            
            nnkFormalParams.newTree(
              newEmptyNode(),
              nnkIdentDefs.newTree(
                nnkPragmaExpr.newTree(
                  ident "e",
                  nnkPragma.newTree(
                    ident "inject"
                  )
                ),
                ident $t,
                newEmptyNode()
              )
            ),
            newEmptyNode(),
            newEmptyNode(),
            body
          )
        )
      )
    template eproc(t): untyped =
      result.add eproct t
    
    case name
    of "close": eproc CloseEvent
    of "render":
      if re == RenderEngine.picture:
        eproc PictureRenderEvent
      elif re == RenderEngine.opengl:
        eproc OpenglRenderEvent
    of "tick": eproc TickEvent
    of "resize": eproc ResizeEvent
    of "windowmove": eproc WindowMoveEvent
    
    of "focus": eproc FocusEvent
    of "fullscreenchanged": eproc StateChangedEvent
    
    of "mousemove", "mouseleave", "mouseenter": eproc MouseMoveEvent
    of "mousedown", "mouseup": eproc MouseButtonEvent
    of "click", "doubleclick": eproc ClickEvent
    of "scroll": eproc ScrollEvent

    of "keydown", "keyup": eproc KeyEvent
    of "textinput": eproc TextInputEvent

    of "init": result.add body
    else: error(&"unknown event: {name}")

  result.add quote do:
    run `win`

macro run*(w: var Window, a: untyped) =
  runImpl w, a, RenderEngine.none
macro run*(w: var PictureWindow, a: untyped) =
  runImpl w, a, RenderEngine.picture
macro run*(w: var OpenglWindow, a: untyped) =
  runImpl w, a, RenderEngine.opengl

template run*(w: SomeWindow, a: untyped) =
  var window {.inject, used.} = w
  run window, a
