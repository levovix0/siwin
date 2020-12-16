when defined(linux):
  import times
  import with
  import libx11 as x
when defined(windows):
  import libwinapi

type Clipboard = object
  when defined(linux):
    xwin: Window
    content: string
    inited: bool

when defined(linux):
  proc close*(a: var Clipboard) = with a:
    if inited:
      inited = false
      content = ""
      
      if display.XGetSelectionOwner(atom(AtomKind.Clipboard)) == xwin:
        discard display.XSetSelectionOwner(atom(AtomKind.Clipboard), None, CurrentTime)
      xcheck display.XDestroyWindow(xwin)
      discard XFlush display
      
      disconnect()
      clipboardProcessEvents = proc() = discard

  proc `=destroy`(a: var Clipboard) =
    close a

elif defined(windows):
  proc close*(a: var Clipboard) = discard

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
        
        if e.property == None or e.selection != atom(AtomKind.Clipboard):
          continue

        var
          kind: Atom
          format: cint
          items: culong
          remainingBytes: culong
          data: cstring
        
        if display.XGetWindowProperty(
          xwin, atom"SIWIN_CLIPBOARD_TARGET_PROPERTY", 0, 0x7fffffff, 0, AnyPropertyType,
          kind.addr, format.addr, items.addr, remainingBytes.addr, cast[PPCUchar](data.addr)
        ) == Success:
          if kind != atom(INCR):
            result = $data

          xcheck XFree data
          xcheck display.XDeleteProperty(xwin, atom"SIWIN_CLIPBOARD_TARGET_PROPERTY")

        responsed = true
      
      of SelectionRequest: # получен запрос содержимого буфера обмена
        template e: untyped = ev.xselectionRequest

        var resp: XSelectionEvent
        resp.theType   = SelectionNotify
        resp.requestor = e.requestor
        resp.selection = e.selection
        resp.property  = e.property
        resp.time      = e.time

        if e.selection == atom AtomKind.Clipboard:
          if e.target == atom Targets:
            # запрос запросов, которые мы можем обработать
            var targets = @[atom Targets, atom Text, XaString]
            if atom(Utf8String) != None: targets.add atom(Utf8String)
            discard display.XChangeProperty(e.requestor, e.property, XaAtom, 32, PropModeReplace, cast[PCUChar](targets[0].addr), targets.len.cint)
            resp.target = atom Targets
            xcheck display.XSendEvent(e.requestor, 1, NoEventMask, cast[PXEvent](resp.addr))
            continue

          elif e.target in [XaString, atom(Text)] or (atom(Utf8String) != None and e.target == atom(Utf8String)):
            # запрос строки буфера обмена
            resp.target = if e.target == atom(Utf8String): atom(Utf8String) else: XaString
            discard display.XChangeProperty(
              e.requestor, e.property, resp.target,
              8, PropModeReplace, cast[PCUChar](if content.len > 0: content[0].addr else: nil), content.len.cint
            )
            xcheck display.XSendEvent(e.requestor, 1, NoEventMask, cast[PXEvent](resp.addr))
            continue
        
        # рассказать, что нам не удалось обработать запрос
        resp.target = e.target
        resp.property = None
        xcheck display.XSendEvent(e.requestor, 1, NoEventMask, cast[PXEvent](resp.addr))

      else: discard

  proc initClipboard() = with clipboard:
    if not inited:
      connect()
      xwin = XCreateSimpleWindow(display, display.DefaultRootWindow, 0, 0, 1, 1, 0, 0, 0) ## невидимое окно. костыли!
      xcheck display.XSelectInput(xwin, SelectionNotify or SelectionRequest or SelectionClear)
      inited = true
      clipboardProcessEvents = proc() =
        var rsp: bool
        discard clipboard.processEvents(rsp)

  proc text*(a: var Clipboard): string = with a:
    initClipboard()
    if display.XGetSelectionOwner(atom(AtomKind.Clipboard)) == None:
      content = ""
      return ""
    var rsp: bool
    discard a.processEvents(rsp)
    
    discard display.XConvertSelection(
      atom(AtomKind.Clipboard), if atom(Utf8String) != 0: atom(Utf8String) else: XaString,
      atom"SIWIN_CLIPBOARD_TARGET_PROPERTY", xwin, CurrentTime
    )

    let beginTime = getTime()

    # ждать ответа не более секунды
    while not rsp and getTime() - beginTime < initDuration(seconds=1):
      result = a.processEvents(rsp)

  proc `text=`*(a: var Clipboard, s: string) = with a:
    initClipboard()
    
    content = s
    discard display.XSetSelectionOwner(atom(AtomKind.Clipboard), xwin, CurrentTime)

    if display.XGetSelectionOwner(atom(AtomKind.Clipboard)) != xwin:
      raise X11Error.newException("failed to set selection owner")

elif defined(windows):
  proc text*(a: var Clipboard): string =
    winassert OpenClipboard(0)

    let hcpb = GetClipboardData(CfUnicodeText)
    if hcpb == 0:
      CloseClipboard()
      raise WinapiError.newException("failed to get handle of clipboard")
    
    result = $cast[PWChar](GlobalLock hcpb)
    GlobalUnlock hcpb
    discard CloseClipboard()

  proc `text=`*(a: var Clipboard, s: string) =
    winassert OpenClipboard(0)
    winassert EmptyClipboard()
    
    let ws = +$s
    let ts = (ws.len + 1) * WChar.sizeof
    let hstr = GlobalAlloc(GMemMoveable, ts)
    if hstr == 0:
      CloseClipboard()
      raise WinapiError.newException("failed to alloc string")

    copyMem(GlobalLock hstr, ws.winstrConverterWStringToLPWstr, ts)
    GlobalUnlock hstr
    SetClipboardData(CfUnicodeText, hstr)
    CloseClipboard()

template `$`*(a: var Clipboard): string = a.text
template `$=`*(a: var Clipboard, s: string) = a.text = s
