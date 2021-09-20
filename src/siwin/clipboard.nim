when defined(linux):
  import utils
  import libx11 as x
when defined(windows):
  import libwinapi

#TODO: selectionClipboard
#TODO: image support

type Clipboard = object
  when defined(linux):
    xwin: Window
    content: string

when defined(linux):
  proc `=destroy`(this: var Clipboard) =
    clipboardProcessEvents = nil
    
    if display.XGetSelectionOwner(atom"CLIPBOARD") == this.xwin:
      discard display.XSetSelectionOwner(atom"CLIPBOARD", None, CurrentTime)
    destroy this.xwin

var clipboard* = Clipboard()


when defined(linux):
  proc processEvents(a: var Clipboard, responsed: var bool): string = with a:
    var ev: XEvent
    proc checkEvent(_: PDisplay, event: PXEvent, userData: XPointer): XBool {.cdecl.} =
      if event.xany.window == (x.Window)(cast[int](userData)): 1 else: 0
    while display.XCheckIfEvent(ev.addr, checkEvent, cast[XPointer](xwin)) == 1:
      case ev.theType
      of SelectionNotify: # получен ответ на запрос содержимого буфера обмена
        template e: untyped = ev.xselection
        
        if e.property == None or e.selection != atom"CLIPBOARD":
          continue
        
        result = xwin.property(atom"siwin_clipboardTargetProperty", string).data
        discard display.XDeleteProperty(xwin, atom"siwin_clipboardTargetProperty")

        responsed = true
      
      of SelectionRequest: # получен запрос содержимого буфера обмена
        template e: untyped = ev.xselectionRequest

        var resp: XSelectionEvent
        resp.theType   = SelectionNotify
        resp.requestor = e.requestor
        resp.selection = e.selection
        resp.property  = e.property
        resp.time      = e.time

        if e.selection == atom"CLIPBOARD":
          if e.target == atom"TARGETS":
            # запрос запросов, которые мы можем обработать
            var targets = @[atom"TARGETS", atom"TEXT", XaString, atom"UTF8_STRING"]
            discard display.XChangeProperty(e.requestor, e.property, XaAtom, 32, PropModeReplace, cast[PCUChar](targets[0].addr), targets.len.cint)
            resp.target = atom"TARGETS"
            (Window e.requestor).send(cast[XEvent](resp), propagate=true)
            continue

          elif e.target in {XaString, atom"TEXT", atom"UTF8_STRING"}:
            # запрос строки буфера обмена
            resp.target = if e.target == atom"UTF8_STRING": atom"UTF8_STRING" else: XaString
            discard display.XChangeProperty(
              e.requestor, e.property, resp.target,
              8, PropModeReplace, cast[PCUChar](if content.len > 0: content[0].addr else: nil), content.len.cint
            )
            (Window e.requestor).send(cast[XEvent](resp), propagate=true)
            continue
        
        # рассказать, что нам не удалось обработать запрос
        resp.target = e.target
        resp.property = None
        (Window e.requestor).send(cast[XEvent](resp), propagate=true)

      else: discard


  clipboard.xwin = newSimpleWindow(defaultRootWindow(), 0, 0, 1, 1, 0, 0, 0) ## невидимое окно. костыли!
  clipboard.xwin.input = [SelectionNotify, SelectionRequest, SelectionClear]
  clipboardProcessEvents = proc() =
    var rsp: bool
    discard clipboard.processEvents(rsp)


  proc text*(this: var Clipboard): string =
    if display.XGetSelectionOwner(atom"CLIPBOARD") == None:
      return ""
    
    discard display.XConvertSelection(
      atom"CLIPBOARD", if atom"UTF8_STRING" != 0: atom"UTF8_STRING" else: XaString,
      atom"siwin_clipboardTargetProperty", this.xwin, CurrentTime
    )
    
    var respond: bool
    while not respond:
      result = this.processEvents(respond)

  proc `text=`*(this: var Clipboard, s: string) =
    this.content = s
    discard display.XSetSelectionOwner(atom"CLIPBOARD", this.xwin, CurrentTime)

elif defined(windows):
  proc text*(a: var Clipboard): string =
    assert OpenClipboard(0)

    let hcpb = GetClipboardData(CfUnicodeText)
    if hcpb == 0:
      CloseClipboard()
      return
    
    result = $cast[PWChar](GlobalLock hcpb)
    GlobalUnlock hcpb
    discard CloseClipboard()

  proc `text=`*(a: var Clipboard, s: string) =
    assert OpenClipboard(0)
    assert EmptyClipboard()
    
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

template `$`*(a: var Clipboard): string = a.text
template `$=`*(a: var Clipboard, s: string) = a.text = s
