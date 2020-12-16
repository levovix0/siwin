when defined(windows):
  import winim
  export winim

  type WinapiError* = object of OSError

  template winassertImpl*(a: untyped, s: string) =
    try: doassert a
    except AssertionDefect:
      raise WinapiError.newException "assertion failed: `" & s & "`"
  template winassert*(a: bool) =
    winassertImpl(a, astToStr(a))

  var hInstance* = GetModuleHandle(nil)
  
  proc trackMouseEvent*(handle: HWnd, e: DWord) =
    var ev = TTrackMouseEvent(cbSize: TTrackMouseEvent.sizeof.DWord, dwFlags: e, hwndTrack: handle, dwHoverTime: 0)
    TrackMouseEvent(ev.addr)
  proc clientRect*(handle: HWnd): Rect = discard handle.GetClientRect(&result)
  proc windowRect*(handle: HWnd): Rect = discard handle.GetWindowRect(&result)
