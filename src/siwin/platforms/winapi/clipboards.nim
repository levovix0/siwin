import ../any/clipboards
import winapi

type
  ClipboardWinapi* = ref object of Clipboard


proc clipboardWinapi*(kind: ClipboardKind = user): ClipboardWinapi =
  ClipboardWinapi()


method text*(a: ClipboardWinapi): string =
  discard OpenClipboard(0)

  let hcpb = GetClipboardData(CfUnicodeText)
  if hcpb == 0:
    CloseClipboard()
    return
  
  result = $cast[PWChar](GlobalLock hcpb)
  GlobalUnlock hcpb
  discard CloseClipboard()

method `text=`*(a: ClipboardWinapi, s: string) =
  discard OpenClipboard(0)
  discard EmptyClipboard()
  
  let ws = +$s
  let ts = (ws.len + 1) * WChar.sizeof
  let hstr = GlobalAlloc(GMemMoveable, ts)
  if hstr == 0:
    CloseClipboard()
    raise OSError.newException("failed to alloc string")

  copyMem(GlobalLock hstr, ws.winstrConverterWStringToLPWstr, ts)
  GlobalUnlock hstr
  SetClipboardData(CfUnicodeText, hstr)
  CloseClipboard()
