import sequtils, algorithm, strutils, strformat, sugar, unicode
export sequtils, algorithm, strutils, strformat, sugar, unicode

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
