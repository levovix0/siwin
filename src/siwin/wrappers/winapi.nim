import winim
export winim

type
  WglContext* = HGlRc

var hInstance* = GetModuleHandle(nil)

var wglSwapIntervalEXT*: proc(interval: int32): Bool {.stdcall.}

proc trackMouseEvent*(handle: HWnd, e: DWord) =
  var ev = TTrackMouseEvent(cbSize: TTrackMouseEvent.sizeof.DWord, dwFlags: e, hwndTrack: handle, dwHoverTime: 0)
  TrackMouseEvent(ev.addr)
proc clientRect*(handle: HWnd): Rect = discard handle.GetClientRect(&result)
proc windowRect*(handle: HWnd): Rect = discard handle.GetWindowRect(&result)

proc getKeyboardState*(): set[0..255] =
  var r: array[256, Byte]
  GetKeyboardState(r[0].addr)
  for i, k in r:
    if HIWord(k) != 0:
      result.incl i
  type r256 = range[0..255]
  result = result - {Vk_control.r256, Vk_lcontrol.r256, Vk_rcontrol.r256, Vk_menu.r256, Vk_lmenu.r256, Vk_rmenu.r256, Vk_shift.r256, Vk_lshift.r256, Vk_rshift.r256}
  template mk(vk): bool = HIWord(GetKeyState(vk)) != 0
  if mk(Vk_lcontrol): result.incl Vk_lcontrol
  if mk(Vk_rcontrol): result.incl Vk_rcontrol
  if mk(Vk_lmenu): result.incl Vk_lmenu
  if mk(Vk_rmenu): result.incl Vk_rmenu
  if mk(Vk_lshift): result.incl Vk_lshift
  if mk(Vk_rshift): result.incl Vk_rshift
