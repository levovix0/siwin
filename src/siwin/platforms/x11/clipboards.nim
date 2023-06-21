import std/[tables]
import ../../utils
import x11/[xlib, x, xatom]
import globalDisplay
import ../any/clipboards

type
  ClipboardX11* = ref object of Clipboard
    handle: Window
    content: string


proc processEvents(clipboard: ClipboardX11, responded: var bool): string =
  var ev: XEvent
  proc checkEvent(_: PDisplay, event: PXEvent, userData: XPointer): XBool {.cdecl.} =
    if event.xany.window == (x.Window)(cast[int](userData)): 1 else: 0
  while display.XCheckIfEvent(ev.addr, checkEvent, cast[XPointer](clipboard.handle)) == 1:
    case ev.theType
    of SelectionNotify: # got clipboard data
      template e: untyped = ev.xselection
      
      if e.property == None or e.selection != atoms.clipboard:
        continue
      
      result = clipboard.handle.property(atoms.siwin_clipboardTargetProperty, string).data
      discard display.XDeleteProperty(clipboard.handle, atoms.siwin_clipboardTargetProperty)

      responded = true
    
    of SelectionRequest: # got request from other application
      template e: untyped = ev.xselectionRequest

      var resp: XSelectionEvent
      resp.theType   = SelectionNotify
      resp.requestor = e.requestor
      resp.selection = e.selection
      resp.property  = e.property
      resp.time      = e.time

      if e.selection == atoms.clipboard:
        if e.target == atoms.targets:
          # requests we can handle request
          var targets = @[atoms.targets, atoms.text, XaString, atoms.utf8String]
          discard display.XChangeProperty(e.requestor, e.property, XaAtom, 32, PropModeReplace, cast[PCUChar](targets[0].addr), targets.len.cint)
          resp.target = atoms.targets
          discard display.XSendEvent(
            e.requestor, 1, NoEventMask, cast[ptr XEvent](resp.addr)
          )
          continue

        elif e.target in {XaString, atoms.text, atoms.utf8String}:
          # clipboard data request
          resp.target = if e.target == atoms.utf8String: atoms.utf8String else: XaString
          discard display.XChangeProperty(
            e.requestor, e.property, resp.target,
            8, PropModeReplace, cast[PCUChar](clipboard.content.dataAddr), clipboard.content.len.cint
          )
          discard display.XSendEvent(
            e.requestor, 1, NoEventMask, cast[ptr XEvent](resp.addr)
          )
          continue
      
      # notify that we can't handle request
      resp.target = e.target
      resp.property = None
      discard display.XSendEvent(
        e.requestor, 1, NoEventMask, cast[ptr XEvent](resp.addr)
      )

    else: discard


proc clipboardX11*(kind: ClipboardKind = user): ClipboardX11 =
  new result, proc(clipboard: ClipboardX11) =
    clipboardProcessEvents.del cast[int](clipboard)
    
    if display.XGetSelectionOwner(atoms.clipboard) == clipboard.handle:
      discard display.XSetSelectionOwner(atoms.clipboard, None, CurrentTime)
    discard display.XDestroyWindow(clipboard.handle)

  globalDisplay.init()
  result.handle = XCreateSimpleWindow(display, display.DefaultRootWindow, 0, 0, 1, 1, 0, 0, 0) # invisible window!
  discard XSelectInput(display, result.handle, SelectionNotify or SelectionRequest or SelectionClear)
  
  let clipboard = result
  clipboardProcessEvents[cast[int](result)] = (proc() =
    var rsp: bool
    discard clipboard.processEvents(rsp)
  )


method text*(clipboard: ClipboardX11): string =
  init()
  if display.XGetSelectionOwner(atoms.clipboard) == None:
    return ""
  
  discard display.XConvertSelection(
    atoms.clipboard, if atoms.utf8String != 0: atoms.utf8String else: XaString,
    atoms.siwin_clipboardTargetProperty, clipboard.handle, CurrentTime
  )
  
  var respond: bool
  while not respond:
    result = clipboard.processEvents(respond)

method `text=`*(clipboard: ClipboardX11, s: string) =
  init()
  clipboard.content = s
  discard display.XSetSelectionOwner(atoms.clipboard, clipboard.handle, CurrentTime)
  discard XFlush display
