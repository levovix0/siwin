import ./platforms
import ./platforms/any/clipboards
export clipboards
when defined(linux):
  import ./platforms/x11/clipboards as x11Clipboard
when defined(windows):
  import ./platforms/winapi/clipboards as winapiClipboard

# todo: selectionClipboard
# todo: image support

proc clipboard*(preferedBackend = defaultPreferedPlatform, kind: ClipboardKind = user): Clipboard =
  when defined(linux):
    clipboardX11(kind)
  elif defined(windows):
    clipboardWinapi(kind)
