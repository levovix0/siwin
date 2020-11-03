when defined(linux):
  import os, strutils, strformat, tables, macros
  import x11/[xlib, x, xutil, xatom, xshm, cursorfont]
  import with
  import image, color, geometry
  export xlib, x, xutil, xatom, xshm, cursorfont

  type X11Error* = object of OSError

  var display*: PDisplay
  var display_rc = 0

  template d: PDisplay = display

  template xcheckStatusImpl(a: untyped, s: string) =
    let r = a
    let rs = case r
    of 1: "BadRequest"
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
    if display_rc == 0:
      display = XOpenDisplay(getEnv("DISPLAY").cstring)
      if display == nil: raise X11Error.newException("failed to open X11 display\nmake sure the DISPLAY environment variable is set correctly")
      
      if display.XShmQueryExtension() == 0: raise X11Error.newException("can't load shm extention")
    
    inc display_rc
    return display

  proc disconnect*() =
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
    if atoms.hasKey(a.int): return atoms[a.int]
    result = atomImpl(a, onlyIfExist)
    atoms[a.int] = result
  proc patom*(a: AtomKind, onlyIfExist: bool = false): PAtom =
    if atoms.hasKey(a.int): return atoms[a.int].addr
    let a = atomImpl(a, onlyIfExist)
    atoms[a.int] = a
    result = atoms[a.int].addr

  # TODO
  type ShmImage* = object
    ## shared memory картинка. использовать для получания пикселей с Drawable объекта
    shminfo: XShmSegmentInfo
    ximage: PXImage
    m_data: ArrayPtr[Color]
  type ShmPixmap* = object
    ## shared memory pixmap. место, где могут рисовать и siwin и x11
    shminfo: XShmSegmentInfo
    pixmap*: Pixmap
    data*: ArrayPtr[Color]
    size*: Vec2i

  proc shmdt(shmaddr: pointer): cint {.importc, header: "sys/shm.h".}
  proc shmget(key: cint, size: culong, flag: cint): cint {.importc, header: "sys/shm.h".}
  proc shmat(shmid: cint, shmaddr: pointer, flag: cint): cstring {.importc, header: "sys/shm.h".}
  proc shmctl(shmid: cint, cmd: cint, buff: pointer): cint {.importc, header: "sys/shm.h".}
  
  proc newShmImage*(w, h: int): ShmImage = with result:
    connect()
    
    shminfo.shmid = shmget(0, w.culong * h.culong * 4, 01000 or 0600)
    doassert shminfo.shmid != -1

    shminfo.shmaddr = shmat(shminfo.shmid, nil, 0)
    doassert shminfo.shmaddr != nil

    shminfo.readOnly = 1
    m_data = ArrayPtr[Color](cast[ptr Color](shminfo.shmaddr))

    #?
    xcheckStatus shmctl(shminfo.shmid, 0, nil)

    ximage = d.XShmCreateImage(
      d.XDefaultVisual(d.XDefaultScreen), d.XDefaultDepth(d.XDefaultScreen).cuint,
      2,  nil, shminfo.addr, 0, 0)
    doassert ximage != nil

    ximage.data = shminfo.shmaddr
    ximage.width = w.cint
    ximage.height = h.cint

    xcheck d.XShmAttach(shminfo.addr)
    xcheck d.XSync(0)

  proc `=destroy`*(a: var ShmImage) =
    xcheckStatus d.XShmDetach(a.shminfo.addr)
    xcheck XDestroyImage(a.ximage)
    xcheck shmdt(a.shminfo.shmaddr)
    disconnect()

  proc size*(a: ShmImage): Vec2i = vec2 a.ximage.width.int, a.ximage.height.int
  
  converter toPicture*(a: ShmImage): Picture = Picture(data: a.m_data, size: a.size)

  proc data*(a: ShmImage): ArrayPtr[Color] = a.m_data
  proc `data=`*(a: ShmImage, b: Drawable) =
    xcheckStatus d.XShmGetImage(b, a.ximage, 0, 0, 0)

  proc newShmPixmap*(w, h: int): ShmPixmap = with result:
    connect()
    size = (w, h)
    shminfo.shmid = shmget(0, w.culong * h.culong * 4, 01000 or 0777)
    doassert shminfo.shmid != -1

    shminfo.readOnly = 0
    shminfo.shmaddr  = shmat(shminfo.shmid, nil, 0)
    doassert shminfo.shmaddr != nil

    xcheckStatus d.XShmAttach(shminfo.addr)
    xcheck d.XSync(0)
    xcheck shmctl(shminfo.shmid, 0, nil)

    data = ArrayPtr[Color](cast[ptr Color](shminfo.shmaddr))
    pixmap = d.XShmCreatePixmap(
      d.XRootWindow(d.XDefaultScreen), shminfo.shmaddr,
      shminfo.addr, w.cuint, h.cuint, d.DefaultDepth(d.XDefaultScreen).cuint)
    doassert pixmap != 0
  
  converter toPicture*(a: ShmPixmap): Picture = Picture(data: a.data, size: a.size)

  proc `=destroy`*(a: var ShmPixmap) =
    xcheckStatus d.XShmDetach(a.shminfo.addr)
    xcheck shmdt(a.shminfo.shmaddr)
    xcheck d.XFreePixmap(a.pixmap)
    disconnect()
  
  proc getGeometry*(a: Window): tuple[root: Window; x, y: cint; w, h: cuint, borderW: cuint, depth: cuint] = with result:
    xcheck d.XGetGeometry(a, root.addr, x.addr, y.addr, w.addr, h.addr, borderW.addr, depth.addr)
