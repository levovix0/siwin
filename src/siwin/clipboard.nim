import with

when defined(linux):
  import libx11 as x
  import times
when defined(windows):
  import libwinapi

type Clipboard = object
  when defined(linux):
    xwin: Window
    content: string
    inited: bool

when defined(linux):
  proc `=destroy`(a: var Clipboard) = with a:
    if inited:
      if xwin != 0:
        xcheck display.XDestroyWindow(xwin)
        discard XFlush display
      disconnect()

var clipboard* = Clipboard()

when defined(linux):
  proc initClipboard(a: var Clipboard) = with a:
    if not inited:
      connect()
      xwin = XCreateSimpleWindow(display, display.DefaultRootWindow, 0, 0, 1, 1, 0, 0, 0) ## невидимое окно. костыли!
      xcheck display.XSelectInput(xwin, SelectionNotify or SelectionRequest or SelectionClear)
      inited = true

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
        discard

      else: discard

  proc text*(a: var Clipboard): string = with a:
    initClipboard a
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
      content = a.processEvents(rsp)
    
    return content

  proc `text=`*(a: var Clipboard, s: string) = with a:
    initClipboard a
    discard

template `$`*(a: var Clipboard): string = a.text
template `$=`*(a: var Clipboard, s: string): string = a.text = s
