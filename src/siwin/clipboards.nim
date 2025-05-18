import ./[siwindefs]
import ./platforms/any/clipboards
export clipboards


when siwin_build_lib:
  {.push, exportc, cdecl, dynlib.}
  proc siwin_destroy_clipboard*(clipboard: Clipboard): Clipboard = GC_unref(clipboard)


  proc siwin_clipboard_content*(clipboard: Clipboard, kind: ClipboardContentKind, mimeType: cstring, out_content: ptr ClipboardContent) =
    out_content[] = clipboard.content(kind, $mimeType)
  
  proc siwin_clipboard_set_content*(clipboard: Clipboard, content: ptr ClipboardConvertableContent) =
    clipboard.content = content[]


  proc siwin_clipboard_text*(clipboard: Clipboard, out_text: ptr char, maxLen: cint): cint =
    let text = clipboard.text()
    if text.len == 0: return 0
    copyMem(out_text, addr(text[0]), min(maxLen, text.len))
    return text.len.cint

  proc siwin_clipboard_set_text*(clipboard: Clipboard, text: cstring) =
    clipboard.text = $text


  {.pop.}
