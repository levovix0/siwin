import sequtils, algorithm, strutils, strformat, sugar, unicode
export sequtils, algorithm, strutils, strformat, sugar, unicode
import macros, unicode

func dataAddr*[T: string|seq|array|openarray|cstring](a: T): auto =
  ## same as C++ `data` that works with std::string, std::vector etc
  ## Note: safe to use when a.len == 0 but whether the result is nil or not is implementation defined
  when T is string|seq|openarray:
    if a.len == 0: nil
    else: (a[0].unsafeAddr)
  elif T is array:
    when a.len > 0: a.unsafeAddr
    else: nil
  elif T is cstring:
    cast[pointer](a)
  else: {.error.}

func del*[T](a: var seq[T], item: T) =
  let i = a.find(item)
  if i != -1: a.del i
func delete*[T](a: var seq[T], item: T) =
  let i = a.find(item)
  if i != -1: a.delete i

proc findBy*[T](a: openarray[T], f: proc(a: T): bool): int =
  result = -1
  for i, b in a:
    if f(b): return i

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

proc flattenInfix*(a: NimNode, infix: string): seq[NimNode] =
  var a = a
  while a.kind == nnkInfix and $a[0] == infix:
    result &= a[2]
    a = a[1]
  result &= a
  reverse result

proc expandInfix*(a: seq[NimNode], infix: NimNode): NimNode =
  result = a[0]
  for b in a[1..^1]:
    result = nnkInfix.newTree(infix, result, b)
