import ../../[siwindefs]


when siwin_use_pure_enums:
  {.pragma: siwinPureEnum, pure.}
else:
  {.pragma: siwinPureEnum.}


type
  Clipboard* = ref object of RootObj
  ClipboardKind* {.siwinPureEnum.} = enum
    user  ## ctrl+c, ctrl+v
    # selection


method text*(clipboard: Clipboard): string {.base.} = discard
method `text=`*(clipboard: Clipboard, v: string) {.base.} = discard


proc `$`*(a: var Clipboard): string = a.text
proc `$=`*(a: var Clipboard, s: string) = a.text = s
