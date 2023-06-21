import sequtils, algorithm, strutils, strformat, sugar, unicode
export sequtils, algorithm, strutils, strformat, sugar, unicode

func dataAddr*[T: string|seq|array|openarray|cstring](a: T): pointer =
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
