when defined(windows):
  import winim
  export winim

  type WinapiError* = object of OSError

  template winassert*(a: bool) =
    try: doassert a
    except AssertionDefect: raise WinapiError.newException getCurrentExceptionMsg()

  var hInstance* = GetModuleHandle(nil)
  
  proc trackMouseEvent*(handle: HWnd, e: DWord) =
    var ev = TTrackMouseEvent(cbSize: TTrackMouseEvent.sizeof.DWord, dwFlags: e, hwndTrack: handle, dwHoverTime: 0)
    TrackMouseEvent(ev.addr)
  proc clientRect*(handle: HWnd): RECT = discard handle.GetClientRect(&result)
  proc windowRect*(handle: HWnd): RECT = discard handle.GetWindowRect(&result)
