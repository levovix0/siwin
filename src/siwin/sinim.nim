import algorithm, macros, unicode



proc high*(a: NimNode): int = a.len - 1

proc newArrayLit*[T](a: openarray[T]): NimNode =
  result = nnkBracket.newTree
  for v in a: result.add newLit(v)

proc toNimUniversal*(a: string): string =
  let r = a.toRunes
  if r.len < 1: return
  $r[0] & toLower $r[1..^1]


proc flattenInfix*(a: NimNode): seq[NimNode] =
  var a = a
  while a.kind == nnkInfix:
    result &= a[2]
    a = a[1]
  result &= a
  reverse result

proc expandInfix*(a: seq[NimNode], infix: NimNode): NimNode =
  result = a[0]
  for b in a[1..^1]:
    result = nnkInfix.newTree(infix, result, b)



type
  NimRoutine* = distinct NimNode
    ## routine definition
  NimTypeDef* = distinct NimNode
    ## type definition
  NimArg* = object
    nameNode*: NimNode
    typeNode: NimNode
    pragmaNode: NimNode
  # NimField* = object #TODO



proc asRoutine*(a: NimNode): NimRoutine =
  a.expectKind {
    nnkProcDef, nnkFuncDef, nnkMethodDef, nnkDo, nnkLambda,
    nnkIteratorDef, nnkTemplateDef, nnkConverterDef, nnkMacroDef
  }
  a.NimRoutine


proc toIdentDefs*(a: NimArg): NimNode =
  nnkIdentDefs.newTree(a.nameNode, a.typeNode, a.pragmaNode)


proc kind*(a: NimRoutine): NimNodeKind =
  a.NimNode.kind

proc hasName*(a: NimRoutine): bool =
  a.NimNode[0].kind != nnkEmpty
proc name*(a: NimRoutine): string =
  $a.NimNode.name
proc `name=`*(a: NimRoutine, v: string) =
  a.NimNode.name = ident v

proc args*(a: NimRoutine): seq[NimArg] =
  for def in a.NimNode[3][1..^1]:
    for idn in def[0..^3]:
      result &= NimArg(nameNode: idn, typeNode: def[^2], pragmaNode: def[^1])

proc returnType*(a: NimRoutine): NimNode =
  a.NimNode[3][0]

proc pragma*(a: NimRoutine): NimNode =
  a.NimNode[4]

proc impl*(a: NimRoutine): NimNode =
  a.NimNode[6]
proc `impl=`*(a: var NimRoutine, v: NimNode) =
  a.NimNode[6] = v


proc name*(a: NimArg): string =
  $a.nameNode
proc `name=`*(a: var NimArg, v: string) =
  a.nameNode = ident v

proc argType*(a: NimArg): NimNode =
  a.typeNode
proc `argType=`*(a: var NimArg, v: NimNode) =
  a.typeNode = v

proc pragma*(a: NimArg): NimNode =
  a.pragmaNode
proc `pragma=`*(a: var NimArg, v: NimNode) =
  a.pragmaNode = v
