import strformat, sequtils, typetraits, macros

type
  ArrayPtr*[T] = distinct ptr T



template lazy* {.pragma.}
macro publicInterface*(a) = discard


proc dataAddr*[T: string|seq|array|openarray|cstring|ArrayPtr](a: T): auto =
  ## same as C++ `data` that works with std::string, std::vector etc
  ## Note: safe to use when a.len == 0 but whether the result is nil or not is implementation defined
  when T is string|seq|openarray:
    if a.len == 0: nil
    else: (a[0].unsafeAddr)
  elif T is array:
    when a.len > 0: a.unsafeAddr
    else: nil
  elif T is ArrayPtr:
    (T.distinctBase) a
  elif T is cstring:
    cast[pointer](a)
  else: {.error.}

proc `[]`*[T](a: ArrayPtr[T], i: int): var T =
  cast[ptr T](cast[int](a) + i * T.sizeof)[]
proc `[]=`*[T](a: ArrayPtr[T], i: int, v: T) =
  cast[ptr T](cast[int](a) + i * T.sizeof)[] = v

iterator items*[T](a: ArrayPtr[T], len: int): var T =
  for i in 0..<len:
    yield a[i]

proc allocArray*[T](len: int): ArrayPtr[T] =
  ArrayPtr[T](cast[ptr T](alloc(len * T.sizeof)))

proc toSeq*[T](a: ArrayPtr[T], n: Natural): seq[T] =
  result = newSeqOfCap[T](n)
  for v in a.items(n):
    result.add v

converter toPointer*(a: ArrayPtr): pointer = a.pointer



proc fieldName(a: NimNode): string =
  a.expectKind nnkIdentDefs
  if a[0].kind == nnkPostfix:
    a[0][1].strVal
  else:
    a[0].strVal

proc newLit[T](a: openarray[T]): NimNode =
  result = nnkBracket.newTree
  for v in a: result.add newLit(v)

proc genFieldBind(a: NimNode, x: NimNode): NimNode =
  a.expectKind nnkIdentDefs
  let name = ident a.fieldName
  if a[1].kind == nnkProcTy:
    return quote do:
      template `name`(args: varargs[untyped]): untyped {.used.} =
        `x`.`name`(args)
  else:
    return quote do:
      template `name`: untyped {.used.} =
        `x`.`name`

proc getAllIdentDefs(x: NimNode): seq[NimNode]

proc getWhenIdentDefs(x: NimNode): seq[NimNode] =
  x.expectKind nnkRecWhen
  for branch in x:
    result &= getAllIdentDefs(branch[1])

proc getAllIdentDefs(x: NimNode): seq[NimNode] =
  for n in x:
    if n.kind == nnkIdentDefs:
      result &= n
    elif n.kind == nnkRecWhen:
      result &= getWhenIdentDefs(n)
    elif n.kind in {nnkRecCase, nnkRecList, nnkOfBranch, nnkElse}:
      result &= getAllIdentDefs(n)

proc fields(a: NimNode): seq[NimNode] =
  a.expectKind {nnkObjectTy, nnkTupleTy}
  if a.kind == nnkObjectTy:
    if a[1].kind == nnkOfInherit:
      for b in a[1]:
        result &= b.getImpl[2].fields
    result &= a[2].getAllIdentDefs.deduplicate
  else:
    result &= a.getAllIdentDefs.deduplicate

proc createInner(x: NimNode, excl: openarray[string] = @[]): seq[NimNode] =
  var t = getTypeImpl(x)
  while t.kind == nnkRefTy:
    t = getTypeImpl(t[0])
  t.expectKind {nnkObjectTy, nnkTupleTy}
  for field in t.fields:
    if field.fieldName notin excl:
      result &= genFieldBind(field, x)

proc withImpl(x: NimNode, body: NimNode, excl: openarray[string] = @[]): NimNode =
  result = newStmtList()
  if x.kind == nnkTupleConstr:
    for y in x:
      result &= createInner(y, excl)
  else:
    result &= createInner(x, excl)
  result &= body

macro withExcl*(x: typed, excl: static[openarray[string]], body: untyped): untyped =
  nnkBlockStmt.newTree(newEmptyNode(), withImpl(x, body, excl))

macro with*(x: untyped, body: untyped): untyped =
  ## allows you to put all the fields of an object or tuple into the
  ## scope of the block that is passed in. This is useful in instances where you
  ## take in an object to a procedure that only does work on this object, for
  ## example an initialiser or what would normally be seen as a method in a
  ## object oriented approach.
  ## 
  ## can be called using pragma or block syntax
  runnableExamples:
    type
      A = object of RootObj
        a: int
      B = object of A
        b: float
    
    proc f(): B {.with: result.} =
      a = 10
      b = 1.0
    
    let v = f()
    with v:
      echo a, ", ", b
  
  if body.kind in {nnkProcDef, nnkFuncDef, nnkTemplateDef}:
    var excl: seq[string]
    if body[0].kind in {nnkIdent, nnkSym}:
      excl &= body[0].strVal
    for b in body[3][1..<body[3].len]:
      b.expectKind nnkIdentDefs
      excl &= b[0].strVal
    let exclLit = excl.newLit
    
    let r = body.last
    result = body.kind.newTree()
    result &= body[0..<(body.len-1)]
    result &= (quote do: withExcl `x`, `exclLit`, `r`)
  else:
    return quote do:
      withExcl `x`, [], `body`

macro with*(body: untyped): untyped =
  ## with that captures first proc argument
  runnableExamples:
    type A = object
      a: int

    proc f(v: var A) {.with.} =
      a = 10
  
  body.expectKind {nnkProcDef, nnkFuncDef, nnkTemplateDef}
  if body[3].len < 2:
    let prc = case body.kind
      of nnkFuncDef: "func"
      of nnkTemplateDef: "template"
      else: "proc"
    let hint =
      if body[3][0].kind != nnkEmpty: "\ndid you mean `with: result`?"
      else: ""
    error(&"at least one {prc} argument is required{hint}", body[3])
  let x = body[3][1][0]
  return quote do:
    with `x`, `body`
