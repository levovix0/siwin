when defined(windows):
  import winim
  export winim

  type WinapiError* = object of OSError

  template winassert*(a: bool) =
    try: doassert a
    except AssertionDefect: raise WinapiError.newException getCurrentExceptionMsg()

  var hInstance* = GetModuleHandle(nil)
