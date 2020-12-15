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
  
  type AtomKind* {.pure.} = enum
    WM_DELETE_WINDOW
    WM_PROTOCOLS
    UTF8_STRING
    CLIPBOARD
    TARGETS
    TEXT
    INCR
    NET_WM_STATE_FULLSCREEN
    NET_WM_STATE
    NET_WM_NAME
    NET_WM_ICON_NAME
  
  var atoms: Table[AtomKind, Atom]
  var satoms: Table[string, Atom]

  proc connect*(): PDisplay {.discardable.} =
    ## connect to X11 server
    if display_rc == 0:
      display = XOpenDisplay(getEnv("DISPLAY").cstring)
      if display == nil: raise X11Error.newException("failed to open X11 display\nmake sure the DISPLAY environment variable is set correctly")
      
      #! if display.XShmQueryExtension() == 0: raise X11Error.newException("can't load shm extention")
    
    inc display_rc
    return display

  template connected*(body) =
    connect()
    body
    disconnect()

  proc isConnected*: bool = display_rc != 0
  proc disconnect*() =
    ## disconnect from X11 server
    dec display_rc
    if display_rc < 0: raise LibraryError.newException("display wasn't open before close")
    if display_rc == 0:
      discard XCloseDisplay display
      clear atoms


  proc atomImpl(a: AtomKind, onlyIfExist: bool): Atom =
    doassert isConnected()
    let s = if ($a).startsWith("NET_"): &"_{$a}" else: $a
    result = display.XInternAtom(s, if onlyIfExist: 1 else: 0)
  proc atomImpl(a: string, onlyIfExist: bool): Atom =
    doassert isConnected()
    result = display.XInternAtom(a, if onlyIfExist: 1 else: 0)

  proc atom*(a: AtomKind, onlyIfExist: bool = false): Atom =
    ## get X11 atom
    if atoms.hasKey(a): return atoms[a]
    result = atomImpl(a, onlyIfExist)
    atoms[a] = result
  proc patom*(a: AtomKind, onlyIfExist: bool = false): PAtom =
    ## get pointer to X11 atom
    if atoms.hasKey(a): return atoms[a].addr
    atoms[a] = atomImpl(a, onlyIfExist)
    result = atoms[a].addr
  
  proc atom*(a: string, onlyIfExist: bool = false): Atom =
    ## get pointer to custom X11 atom
    if satoms.hasKey(a): return satoms[a]
    result = atomImpl(a, onlyIfExist)
    satoms[a] = result
  proc patom*(a: string, onlyIfExist: bool = false): PAtom =
    ## get pointer to custom X11 atom
    if satoms.hasKey(a): return satoms[a].addr
    satoms[a] = atomImpl(a, onlyIfExist)
    result = satoms[a].addr
  
  proc geometry*(a: Window): tuple[root: Window; x, y: cint; w, h: cuint, borderW: cuint, depth: cuint] = with result:
    ## get X11 window geometry
    xcheck display.XGetGeometry(a, root.addr, x.addr, y.addr, w.addr, h.addr, borderW.addr, depth.addr)

  proc property*[T](a: Window, name: Atom, t: typedesc[T]): T =
    ## get X11 window property
    var
      kind: Atom
      format: cint
      n: culong
      remainingBytes: culong
    when T is seq[Atom]:
      var dataPtr: ArrayPtr[Atom]
      template ckind: bool = kind == XaAtom
    elif T is string:
      var dataPtr: cstring
      template ckind: bool = kind != atom(INCR)
    
    if display.XGetWindowProperty(
      a, name, 0, clong.high, 0, AnyPropertyType,
      kind.addr, format.addr, n.addr, remainingBytes.addr, cast[PPCUchar](dataPtr.addr)
    ) == Success and ckind:
      when T is seq[Atom]:
        for i in 0..<n.int:
          result.add dataPtr[i]
      elif T is string:
        return $dataPtr
  
  template property*(a: Window, atm: static[AtomKind]): auto =
    when atm == NetWmState: a.property(atom AtomKind.NetWmState, seq[Atom])
    else: {.error: "unknown property".}

  var clipboardProcessEvents*: proc() = proc() = discard
