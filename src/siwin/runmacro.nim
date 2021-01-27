import macros, strformat, strutils, unicode, tables, sequtils, algorithm, utils, sugar, sinim
import window

type
  SomeWindow = Window|PictureWindow

  KeyBinding* = distinct set[Key]

proc `+=`[T](a: var set[T], v: T) =
  a.incl v
proc `-=`[T](a: var set[T], v: T) =
  a.excl v

proc toSet[T](a: openarray[T]): set[T] =
  for b in a:
    result += b


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


proc keys*(e: KeyEvent): set[Key] =
  #TODO: преобразовать массив e.keyboard.pressed в set
  for k, state in e.keyboard.pressed:
    if state:
      result += k
  if e.key notin result:
    result += e.key


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


proc nameToKeys(a: string): set[Key] {.compileTime.} =
  let a = a.toNimUniversal
  if keyBindings.hasKey a: set[Key] keyBindings[a]
  else: {parseEnum[Key](a)}


proc ofKey(a: NimNode): NimNode =
  result = a.ofEnum(Key)
  if a.kind == nnkIdent and keyBindings.hasKey $a:
    return newLit set[Key] keyBindings[$a]

#[ 
proc kindStrings(a: typedesc): seq[string] {.compileTime.} =
  let b = a.getTypeImpl
  b.expectKind nnkEnumTy
  for c in b:
    if c.kind == nnkSym: result.add c.strVal.toNimUniversal

const keyKindStrings = Key.kindStrings
const mouseButtonKindStrings = MouseButton.kindStrings

proc ofEnum(a: NimNode, b: typedesc): NimNode =
  template possible: seq[string] =
    when b is typedesc[Key]: keyKindStrings
    elif b is typedesc[MouseButton]: mouseButtonKindStrings
    else: b.kindStrings

  if a.kind == nnkIdent and a.strVal.toNimUniversal in possible:
    nnkDotExpr.newTree(quote do: `b`, a)
  else:
    a


proc check*(a, b: Key): bool = a == b
proc check*(a: Key, b: openarray[Key]): bool = a in b
proc check*(a: Key, b: proc(a: Key): bool): bool = b(a)
proc check*(a, b: MouseButton): bool = a == b
proc check*(a: MouseButton, b: openarray[MouseButton]): bool = a in b
proc check*(a: MouseButton, b: proc(a: MouseButton): bool): bool = b(a)


var keyNameBindings* {.compileTime.}: Table[string, seq[Key]]

macro makeKeyNameBinding*(name: untyped, match: static[openarray[Key]]): untyped =
  name.expectKind nnkIdent
  let matchLit = newArrayLit match
  keyNameBindings[name.strVal.toNimUniversal] = match.toSeq

  result = quote do:
    proc `name`*(a: Key): bool = a in `matchLit`
    proc `name`*(a: array[Key.a..Key.pause, bool]): bool =
      for k in `matchLit`:
        result = result or a[k]

makeKeyNameBinding control, [lcontrol, rcontrol]
makeKeyNameBinding ctrl,    [lcontrol, rcontrol]

makeKeyNameBinding shift,   [lshift, rshift]

makeKeyNameBinding alt,     [lalt, ralt]

makeKeyNameBinding system,  [lsystem, rsystem]
makeKeyNameBinding meta,    [lsystem, rsystem]
makeKeyNameBinding super,   [lsystem, rsystem]
makeKeyNameBinding windows, [lsystem, rsystem]
makeKeyNameBinding win,     [lsystem, rsystem]

makeKeyNameBinding esc,     [Key.escape]

proc genPressedKeyCheck(a: NimNode): NimNode = quote do:
  when compiles(`a`(e.keyboard.pressed)) and `a`(e.keyboard.pressed) is bool:
    `a`(e.keyboard.pressed)
  else:
    e.keyboard.pressed[`a`]

proc contains*(a: array[Key.a..Key.pause, bool], b: openArray[Key]): bool =
  for k in b:
    if a[k]:
      result = true
      return

proc nameToKeys(a: string): seq[Key] {.compileTime.} =
  let a = a.toNimUniversal
  if keyNameBindings.hasKey a: keyNameBindings[a]
  else: @[parseEnum[Key](a)]

proc genExPressedKeySeq(a: seq[NimNode]): seq[Key] {.compileTime.} =
  for k in Key.a..Key.pause:
    result.add k
  var r: seq[Key]
  for b in a:
    b.expectKind nnkIdent
    r.add nameToKeys(b.strVal)
  sort r
  r = r.deduplicate(true)
  for v in r.reversed:
    result.delete v.ord

# TODO: тип события: название, параметры, тело

proc runImpl(w: NimNode, a: NimNode, wt: static[RenderEngine]): NimNode =
  a.expectKind nnkStmtList
  result = nnkStmtList.newTree()

  var runRes: Table[string, NimNode]
  proc resadd(e: string, body: NimNode) =
    if e notin runRes: runRes[e] = nnkStmtList.newTree()
    runRes[e].add quote do:
      block: `body`

  type
    EventHeader = tuple
      name: string
      args: seq[NimNode]
    AsPair = tuple
      head: EventHeader
      res: NimNode
    Event = tuple
      head: AsPair
      body: NimNode


  template name(a: Event): auto = a.head.head.name
  template args(a: Event): auto = a.head.head.args
  template res(a: Event): auto = a.head.res

  proc add(a: Event, v: NimNode) =
    a.name.resadd v


  proc `parse header`(a: NimNode): EventHeader =
    a.expectKind {nnkIdent, nnkCall, nnkCommand}
    case a.kind
    of nnkIdent: result.name = $a
    of nnkCall, nnkCommand:
      if a[0].kind == nnkDotExpr:
        result.name = $a[0][1]
        result.args &= a[0][0]
      else:
        result.name = $a[0]
      for b in a[1..^1]:
        if b.kind == nnkStmtList:
          result.args &= b[0..^1]
        else:
          result.args &= b
    else: discard
    result.name = result.name.toLower

  proc `parse |`(a: NimNode): seq[EventHeader] =
    a.flattenInfix("|").map(`parse header`)
  
  proc `parse as`(a: NimNode): seq[AsPair] =
    if a.kind == nnkInfix and $a[0] == "as":
      for b in a[1].`parse |`:
        result &= (b, a[2])
    else:
      result = a.`parse |`.map(a => (a, nil.NimNode))
  
  proc `parse or`(a: NimNode): seq[AsPair] =
    for b in a.flattenInfix("or"):
      result &= b.`parse as`
  
  proc `parse event`(a: NimNode): seq[Event] =
    if a.kind == nnkIdent:
      @[((a.`parse header`, nil.NimNode), nil.NimNode)]
    elif a.last.kind == nnkStmtList:
      a.kind.newTree(a[0..^2]).`parse or`.map(b => (b, a[^1]))
    else:
      a.`parse or`.map(b => (b, nil.NimNode))


  for b in a:
    for event in b.`parse event`:
      let pars = event.args
      let body = event.body
      var asNode = event.res
      

      var genAs: proc(v: NimNode): NimNode = proc(v: NimNode): NimNode = discard
      var asKind = nnkEmpty
      if asNode != nil:
        asKind = asNode.kind
        
        case asKind
        of nnkIdent: discard
        of nnkPar:
          var r = nnkVarTuple.newTree
          for c in asNode:
            r &= nnkPragmaExpr.newTree(c, nnkPragma.newTree(ident"inject"))
          r &= nnkEmpty.newNimNode
          asNode = r
        of nnkBracketExpr:
          asNode.expectLen 1
          asNode = asNode[0]
          asNode.expectKind nnkIdent
        else: error(&"got {asNode.kind}, but expected ident, ident[] or tuple", asNode)

        case asKind
        of nnkIdent, nnkBracketExpr:
          genAs = proc(v: NimNode): NimNode = quote do:
            let `asNode` {.inject.} = `v`
        of nnkPar:
          genAs = proc(v: NimNode): NimNode =
            var r = asNode
            r.add v
            return nnkLetSection.newTree(r)
        else: discard

      proc sellectAs(a: NimNode, arr: NimNode): NimNode =
        if asKind == nnkBracketExpr: genAs(arr)
        else: genAs(a)
      proc sellectAs(a: NimNode): NimNode =
        if asKind == nnkBracketExpr: error(&"can't get event val as array", asNode)
        else: return genAs(a)


      let e = ident"e"
      
      template resaddas(ename: string; a, arr, body: untyped) =
        let asl {.inject.} = sellectAs(quote do: a, quote do: arr)
        if asl != nil:
          ename.resadd quote do:
            `asl`
            body
        else:
          ename.resadd quote do:
            body

      template resaddas(ename: string; a, body: untyped) =
        let asl {.inject.} = sellectAs(quote do: a)
        if asl != nil:
          ename.resadd quote do:
            `asl`
            body
        else:
          ename.resadd quote do:
            body
      
      proc parseKeyCombination(a: NimNode): tuple[key: NimNode, cond: NimNode] = withExcl result, []:
        var keys = flattenInfix a
        key = keys[^1].ofEnum(Key)

        let needEx = ident"_" in keys or keys.len > 1
        keys.delete ident"_"

        if needEx:
          let ex = genExPressedKeySeq(keys).newLit
          cond = quote do: `ex` notin `e`.keyboard.pressed
          for c in keys[0..^2].mapit(it.ofEnum(Key).genPressedKeyCheck):
            cond = quote do: `c` and `cond`
        else:
          cond = newLit true

      case event.name
      of "keydown", "keyup":
        if pars.len == 1 and pars[0] != ident"any":
          var (k, c) = pars[0].parseKeyCombination
          event.add quote do:
            if check(`e`.key, `k`) and `c`:
              `body`
        elif pars.len > 1:
          var cond = newLit false
          for (k, c) in pars.map(parseKeyCombination):
            cond = quote do: `cond` or (`c` and check(`e`.key, `k`))
          event.add quote do:
            if `cond`:
              `body`
        else: event.name.resaddas `e`.key: `body`

      of "mousedown", "mouseup":
        if pars.len == 1 and pars[0] != ident"any":
          var k = pars[0].ofEnum(MouseButton)
          event.add quote do:
            if check(e.button, `k`):
              `body`
        elif pars.len > 1:
          var kk = nnkBracket.newTree()
          for v in pars:
            kk.add v.ofEnum(MouseButton)
          event.add quote do:
            if e.button in `kk`:
              `body`
        else: event.name.resaddas `e`.button: `body`

      of "pressingkey", "keypressing", "pressing":
        if pars.len == 1 and pars[0] != ident"any":
          var k = pars[0].ofEnum(Key)
          "tick".resaddas `k`:
            if `e`.keyboard.pressed[`k`]:
              `body`
        else:
          let kk =
            if pars.len < 2: bindSym"AllKeys"
            else: nnkBracket.newTree: mapit pars:
              it.ofEnum(Key)
          case asKind
          of nnkEmpty:
            "tick".resadd quote do:
              var prs = false
              for k in `kk`:
                if `e`.keyboard.pressed[k]: prs = true; break
              if prs:
                `body`
          of nnkIdent:
            "tick".resadd quote do:
              for k in `kk`:
                if `e`.keyboard.pressed[k]:
                  let `asNode` {.inject.} = k
                  `body`
          of nnkBracketExpr:
            "tick".resadd quote do:
              var `asNode` {.inject.}: seq[Key]
              for k in `kk`:
                if `e`.keyboard.pressed[k]: `asNode`.add k
              if `asNode`.len > 0:
                `body`
          else: error(&"got {asNode.kind}, but expected ident or ident[]", asNode)

      of "notpressingkey", "notkeypressing", "notpressing":
        if pars.len == 1 and pars[0] != ident"any":
          var k = pars[0].ofEnum(Key)
          "tick".resadd quote do:
            if not `e`.keyboard.pressed[`k`]:
              `body`
        elif pars.len > 1:
          var kk = nnkBracket.newTree()
          for v in pars:
            kk.add v.ofEnum(Key)
          "tick".resadd quote do:
            var prs = false
            for k in `kk`:
              if `e`.keyboard.pressed[k]: prs = true
            if not prs:
              `body`
        else:
          "tick".resadd quote do:
            if true notin `e`.keyboard.pressed:
              `body`

      of "click":
        if pars.len == 1 and pars[0] != ident"any":
          var k = pars[0].ofEnum(MouseButton)
          event.name.resaddas `e`.position:
            if `e`.button == `k`:
              `body`
        if pars.len > 1:
          var kk = nnkBracket.newTree()
          for v in pars:
            kk.add v.ofEnum(MouseButton)
          event.name.resaddas `e`.position:
            if `e`.button in `kk`:
              `body`
        else:
          event.name.resaddas `e`.position: `body`

      of "textenter":
        event.name.resaddas `e`.text, `e`.text.toRunes: `body`
      of "render":
        when wt == RenderEngine.picture:
          event.name.resaddas `w`.render: `body`
        elif wt == RenderEngine.opengl:
          event.add body
        else:
          error "can't render on window (no render engine)", b
      of "focus":
        event.name.resaddas `e`.focused: `body`
      of "fullscreen", "fullscreenchanged":
        if pars.len == 1:
          let c = pars[0]
          "fullscreenchanged".resaddas `e`.state:
            if `e`.state == `c`:
              `body`
        elif pars.len > 1:
          error(&"got {pars.len} parametrs, but expected one of (), (state)", pars[1])
        else:
          "fullscreenchanged".resaddas `e`.state: `body`

      of "scroll":
        event.name.resaddas `e`.delta: `body`
      of "mousemove", "mouseleave", "mouseenter", "windowmove":
        event.name.resaddas `e`.position: `body`
      of "resize":
        event.name.resaddas `e`.size: `body`

      else: event.add body

  for eventName, body in runRes:
    let eventNameIdent = ident("on" & eventName)

    template eproc(t: typedesc) {.dirty.} =
      result.add quote do:
        `w`.`eventNameIdent` = proc(e {.inject.}: t) =
          `body`

    case eventName
    of "close":  eproc CloseEvent
    of "render":
      when wt == RenderEngine.picture:
        eproc PictureRenderEvent
      when wt == RenderEngine.opengl:
        eproc OpenglRenderEvent
    of "tick":   eproc TickEvent
    of "resize": eproc ResizeEvent
    of "windowmove": eproc WindowMoveEvent
    
    of "focus":  eproc FocusEvent
    of "fullscreenchanged": eproc StateChangedEvent
    
    of "mousemove", "mouseleave", "mouseenter": eproc MouseMoveEvent
    of "mousedown", "mouseup": eproc MouseButtonEvent
    of "click", "doubleclick": eproc ClickEvent
    of "scroll": eproc ScrollEvent

    of "keydown", "keyup": eproc KeyEvent
    of "textenter": eproc TextEnterEvent

    of "init":
      result.add quote do:
        `body`
    else: error(&"unknown event: {eventName}")

  result.add quote do:
    run `w`
 ]#


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
    let ex = keys.mapit(nameToKeys $it).concatSet
    result = quote do: (`e`.keys - `ex`).len == 0
    let kx = keys[^1].ofKey
    result = quote do: (`kx` in `e`.keys) and `result` 
    for c in keys[0..^2].mapit(nameToKeys $it):
      result = quote do: (`c` in `e`.keys) and `result`
  else:
    let kx = keys[^1].ofKey
    result = quote do: `kx` in `e`.keys


proc translateEvent(rp: RunParser, a: Event): seq[EventOutput] =
  template add(e: string, body: NimNode) =
    result.add (e, nnkBlockStmt.newTree(body))
  template w: auto = rp.windowNode
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
    for c in args.map(`parse event`).concatSeq:
      var c = c
      c.body =
        if c.body == nil: body
        else: newStmtList(c.body, body)
      result.add rp.translateEvent c
  
  of "render":
    case rp.renderEngine
    of RenderEngine.picture:
      "render".addas `w`.render: `body`
    of RenderEngine.opengl:
      "render".add body
    else:
      error "can't render on window (no render engine)", a.nameNode
  
  of "textenter", "input":
    "textenter".addas `e`.text, `e`.text.toRunes: `body`
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

  of "mousemove", "mouseleave", "mouseenter", "windowmove":
    name.addas `e`.position: `body`
  of "resize":
    name.addas `e`.size: `body`
  else: name.add body

proc translateEvent(rp: RunParser, a: NimNode): seq[EventOutput] =
  a.`parse event`.mapit(rp.translateEvent it).concatSeq


proc runImpl(win, a: NimNode, re: RenderEngine): NimNode =
  result = newStmtList()

  var rp: RunParser
  rp.renderEngine = re
  rp.windowNode = win

  a.expectKind nnkStmtList

  var outp: Table[string, NimNode]
  for (name, body) in a.mapit(rp.translateEvent it).concatSeq:
    if name notin outp: outp[name] = newStmtList()
    outp[name] &= body

  for name, body in outp:
    let wev = nnkDotExpr.newTree(win, ident("on" & name))
    proc eproct(t: typedesc): NimNode =
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
    of "textenter": eproc TextEnterEvent

    of "init": result.add body
    else: error(&"unknown event: {name}")

  result.add quote do:
    run `w`

macro run*(w: var Window, a: untyped) =
  runImpl w, a, RenderEngine.none
macro run*(w: var PictureWindow, a: untyped) =
  runImpl w, a, RenderEngine.picture
macro run*(w: var OpenglWindow, a: untyped) =
  runImpl w, a, RenderEngine.opengl

template run*(w: SomeWindow, a: untyped) =
  var window {.inject, used.} = w
  run window, a
