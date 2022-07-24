when defined(windows):
  import wrappers/winapi
elif defined(linux):
  import vmath
  import wrappers/x, wrappers/glx

type
  InvisibleOpenglWindow* = object
    when defined(windows):
      handle: HWnd
      hdc: Hdc
      ctx: WglContext
    elif defined(linux):
      handle: Window
      ctx: GlxContext


when defined(linux):
  proc `=destroy`(w: var InvisibleOpenglWindow) =
    if w.ctx != nil:
      if glxCurrentContext() == w.ctx:
        0.makeCurrent nil.GlxContext
      destroy w.ctx

    if w.handle != 0:
      destroy w.handle

    wasMoved w
  
  proc newOpenglContext*: InvisibleOpenglWindow =
    x.init()
    let root = defaultRootWindow()

    var vi: XVisualInfo
    discard display.XMatchVisualInfo(display.DefaultScreen, 24, TrueColor, vi.addr)
    let cmap = display.XCreateColormap(root, vi.visual, AllocNone)
    var swa = XSetWindowAttributes(colormap: cmap)
    result.handle = x.newWindow(root, ivec2(), ivec2(1, 1), 0, vi.depth, InputOutput, vi.visual, CwColormap or CwEventMask or CwBorderPixel or CwBackPixel, swa)

    result.ctx = newGlxContext(vi.addr)
    result.handle.makeCurrent result.ctx
  
  proc makeCurrent*(w: InvisibleOpenglWindow) =
    w.handle.makeCurrent w.ctx


elif defined(windows):
  proc `=destroy`(w: var InvisibleOpenglWindow) =
    if w.ctx != 0:
      if wglGetCurrentContext() == w.ctx:
        wglMakeCurrent(0, 0)
      wglDeleteContext w.ctx
    
    if w.hdc != 0:
      DeleteDC w.hdc
    if w.handle != 0:
      DestroyWindow(w.handle)
    
    wasMoved w

  proc newOpenglContext*: InvisibleOpenglWindow =
    proc registerWindowClass(
      class: string,
      wndProc: proc(handle: HWnd, message: Uint, wParam: WParam, lParam: LParam): LResult {.stdcall.}
    ) =
      # todo: move to wrappers/winapi
      var wcex = WndClassEx(
        cbSize:        WndClassEx.sizeof.int32,
        style:         CsHRedraw or CsVRedraw,
        hInstance:     hInstance,
        hCursor:       LoadCursor(0, IdcArrow),
        lpfnWndProc:   wndProc,
        lpszClassName: class,
      )
      if RegisterClassEx(&wcex) == 0:
        raise OSError.newException("RegisterClassEx failed")
  
    proc createWindow(class: string): HWnd =
      # todo: move to wrappers/winapi
      result = CreateWindow(
        class,
        "",
        WsOverlappedWindow,
        CwUseDefault, CwUseDefault,
        CwUseDefault, CwUseDefault,
        0, 0,
        GetModuleHandleW(nil),
        nil
      )
      if result == 0:
        raise OSError.newException("Creating window failed")
    
    var windowClassName = "iow"
    registerWindowClass(windowClassName, DefWindowProcW)
    result.handle = createWindow(windowClassName)

    result.hdc = result.handle.GetDC
    var pfd = PixelFormatDescriptor(
      nSize: Word PixelFormatDescriptor.sizeof,
      nVersion: 1,
      dwFlags: Pfd_draw_to_window or Pfd_support_opengl or Pfd_double_buffer,
      iPixelType: Pfd_type_rgba,
      cColorBits: 32,
      cDepthBits: 24,
      cStencilBits: 8,
      iLayerType: Pfd_main_plane,
    )
    result.hdc.SetPixelFormat(result.hdc.ChoosePixelFormat(&pfd), &pfd)
    result.ctx = wglCreateContext(result.hdc)
    discard result.hdc.wglMakeCurrent(result.ctx)
  
  proc makeCurrent*(w: InvisibleOpenglWindow) =
    w.hdc.wglMakeCurrent(w.ctx)


else:
  {.error: "unsupported platform".}
