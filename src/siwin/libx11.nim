when defined(linux):
  import os, strutils, strformat, tables, macros
  import x11/[xlib, x, xutil, xatom, xshm, cursorfont, keysym]
  import with
  import image
  export xlib, x, xutil, xatom, xshm, cursorfont, keysym

  type X11Error* = object of OSError

  var display*: PDisplay
  var display_rc = 0

  template xcheckStatusImpl(a: untyped, s: string) =
    let r = a
    let rs = case r
    of 1: "BadRequest"
    of 2: "BadValue"
    of 3: "BadWindow"
    of 4: "BadPixmap"
    of 5: "BadAtom"
    of 6: "BadCursor"
    of 7: "BadFont"
    of 8: "BadMatch"
    of 9: "BadDrawable"
    of 10: "BadAccess"
    of 11: "BadAlloc"
    of 12: "BadColor"
    of 13: "BadGC"
    of 14: "BadIDChoice"
    of 15: "BadName"
    of 16: "BadLength"
    of 17: "BadImplementation"
    else: "?"

    if r != Success: raise X11Error.newException(s & " errors with code " & $r & " (" & rs & ")")
  template xcheckImpl(a: untyped, s: string) =
    let r = a.bool
    if r == false: raise X11Error.newException("error after " & s)
  template xcheckStatus*(a: Status) =
    let s = astToStr(a)
    xcheckStatusImpl(a, s)
  template xcheck*(a: cint) =
    let s = astToStr(a)
    xcheckImpl(a, s)

  proc connect*(): PDisplay {.discardable.} =
    ## connect to X11 server
    if display_rc == 0:
      display = XOpenDisplay(getEnv("DISPLAY").cstring)
      if display == nil: raise X11Error.newException("failed to open X11 display\nmake sure the DISPLAY environment variable is set correctly")
      
      if display.XShmQueryExtension() == 0: raise X11Error.newException("can't load shm extention")
    
    inc display_rc
    return display

  proc disconnect*() =
    ## disconnect from X11 server
    dec display_rc
    if display_rc < 0: raise LibraryError.newException("display wasn't open before close")
    if display_rc == 0: discard XCloseDisplay display
  
  type AtomKind* = enum
    WM_DELETE_WINDOW
    WM_PROTOCOLS
    UTF8_STRING
    NET_WM_STATE_FULLSCREEN
    NET_WM_STATE
    NET_WM_NAME
    NET_WM_ICON_NAME
  
  var atoms: Table[int, Atom]

  proc atomImpl(a: AtomKind, onlyIfExist: bool): Atom =
    let s = if ($a).startsWith("NET_"): &"_{$a}" else: $a
    connect()
    result = display.XInternAtom(s, if onlyIfExist: 1 else: 0)
    disconnect()

  proc atom*(a: AtomKind, onlyIfExist: bool = false): Atom =
    ## get X11 atom
    if atoms.hasKey(a.int): return atoms[a.int]
    result = atomImpl(a, onlyIfExist)
    atoms[a.int] = result
  proc patom*(a: AtomKind, onlyIfExist: bool = false): PAtom =
    ## get pointer to X11 atom
    if atoms.hasKey(a.int): return atoms[a.int].addr
    let a = atomImpl(a, onlyIfExist)
    atoms[a.int] = a
    result = atoms[a.int].addr
  
  proc getGeometry*(a: Window): tuple[root: Window; x, y: cint; w, h: cuint, borderW: cuint, depth: cuint] = with result:
    ## get X11 window geometry
    xcheck display.XGetGeometry(a, root.addr, x.addr, y.addr, w.addr, h.addr, borderW.addr, depth.addr)
