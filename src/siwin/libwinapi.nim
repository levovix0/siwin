when defined(windows):
  import winim, strformat
  export winim

  type WinapiError* = object of OSError

  template winassert*(a: bool) =
    try: doassert a
    except AssertionDefect:
      let s = astToStr(a)
      raise WinapiError.newException fmt"assertion failed: `{s}`"

  var hInstance* = GetModuleHandle(nil)
  
  proc trackMouseEvent*(handle: HWnd, e: DWord) =
    var ev = TTrackMouseEvent(cbSize: TTrackMouseEvent.sizeof.DWord, dwFlags: e, hwndTrack: handle, dwHoverTime: 0)
    TrackMouseEvent(ev.addr)
  proc clientRect*(handle: HWnd): Rect = discard handle.GetClientRect(&result)
  proc windowRect*(handle: HWnd): Rect = discard handle.GetWindowRect(&result)
