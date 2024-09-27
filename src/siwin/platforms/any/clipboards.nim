import ../../[siwindefs]


when siwin_use_pure_enums:
  {.pragma: siwinPureEnum, pure.}
else:
  {.pragma: siwinPureEnum.}


type
  ClipboardContentKind* {.siwinPureEnum.} = enum
    text
    files
    other
  

  ClipboardContent* = object
    case kind*: ClipboardContentKind
    of text:
      text*: string
    
    of files:
      files*: seq[string]
    
    of other:
      mimeType*: string
      data*: string
  

  ClipboardContentConverter* = object
    kind*: ClipboardContentKind
    mimeType*: string
    f*: proc(
      data: ref RootObj, kind: ClipboardContentKind, mimeType: string
    ): ClipboardContent


  ClipboardConvertableContent* = object
    data*: ref RootObj
    converters*: seq[ClipboardContentConverter]


  GotClipboardContentEvent* = object
    clipboard*: Clipboard
    content*: ClipboardContent


  ClipboardContentChangedEvent* = object
    clipboard*: Clipboard
    availableKinds*: set[ClipboardContentKind]
    availableMimeTypes*: seq[string]


  Clipboard* = ref object of RootObj
    onContentChanged*: proc(e: ClipboardContentChangedEvent)

    availableKinds*: set[ClipboardContentKind]
    availableMimeTypes*: seq[string]


method content*(
  clipboard: Clipboard, kind: ClipboardContentKind, mimeType: string = "text/plain"
): ClipboardContent {.base.} = discard
  ## requests source to convert content to specified format, waits for it, and returns it
  ## this method is synchronous (blocks)
  ## note: on some platforms, some window events may happen while waiting for content
  ## returns empty content if content is not available in requested format


method `content=`*(clipboard: Clipboard, content: ClipboardConvertableContent) {.base.} = discard
  ## sets content of clipboard
  ## note: setting content on dragndropClipboard is not yet implemented


proc text*(clipboard: Clipboard): string =
  clipboard.content(ClipboardContentKind.text).text


proc `text=`*(clipboard: Clipboard, v: string) =
  type RefString = ref object of RootObj
    s: string

  var cc: ClipboardConvertableContent
  cc.data = RefString(s: v)
  cc.converters.add ClipboardContentConverter(
    kind: ClipboardContentKind.text,
    f: proc(
      data: ref RootObj, kind: ClipboardContentKind, mimeType: string
    ): ClipboardContent =
      let s = data.RefString.s
      result = ClipboardContent(kind: ClipboardContentKind.text, text: s)
  )

  clipboard.content = cc


proc files*(clipboard: Clipboard): seq[string] =
  clipboard.content(ClipboardContentKind.files).files


proc `files=`*(clipboard: Clipboard, v: seq[string]) =
  type RefFiles = ref object of RootObj
    files: seq[string]

  var cc: ClipboardConvertableContent
  cc.data = RefFiles(files: v)
  cc.converters.add ClipboardContentConverter(
    kind: ClipboardContentKind.files,
    f: proc(
      data: ref RootObj, kind: ClipboardContentKind, mimeType: string
    ): ClipboardContent =
      let files = data.RefFiles.files
      result = ClipboardContent(kind: ClipboardContentKind.files, files: files)
  )

  clipboard.content = cc


proc `[]`*(clipboard: Clipboard, mimeType: string): string =
  clipboard.content(ClipboardContentKind.other, mimeType).data


proc `[]=`*(clipboard: Clipboard, mimeType: string, v: string) =
  type RefData = ref object of RootObj
    data: string

  var cc: ClipboardConvertableContent
  cc.data = RefData(data: v)
  cc.converters.add ClipboardContentConverter(
    kind: ClipboardContentKind.other,
    mimeType: mimeType,
    f: proc(
      data: ref RootObj, kind: ClipboardContentKind, mimeType: string
    ): ClipboardContent =
      let files = data.RefData.data
      result = ClipboardContent(kind: ClipboardContentKind.other, mimeType: mimeType, data: files)
  )

  clipboard.content = cc


proc `$`*(a: var Clipboard): string {.deprecated: "use .text instead".} = a.text
proc `$=`*(a: var Clipboard, s: string) {.deprecated: "use .text= instead".} = a.text = s

proc clipboard*(): Clipboard {.deprecated: "user window.clipboard instead".} = discard
