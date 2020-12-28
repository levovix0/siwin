
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
    a.distinctBase
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
