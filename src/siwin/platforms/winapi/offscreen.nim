import winapi
import ../any/window

type
  InvisibleOpenglWindowWinapi* = ref InvisibleOpenglWindowWinapiObj
  InvisibleOpenglWindowWinapiObj = object of Window
    handle: HWnd
    hdc: Hdc
    ctx: WglContext


proc `=destroy`(windows: var InvisibleOpenglWindowWinapiObj) =
  if windows.hdc != 0:
    DeleteDC windows.hdc
  if windows.handle != 0:
    DestroyWindow(windows.handle)
  
  wasMoved windows

proc newOpenglContextWinapi*: InvisibleOpenglWindowWinapi =
  new result
  proc registerWindowClass(
    class: string,
    wndProc: proc(handle: HWnd, message: Uint, wParam: WParam, lParam: LParam): LResult {.stdcall.}
  ) =
    var wcex = WndClassEx(
      cbSize:        WndClassEx.sizeof.int32,
      style:         CsHRedraw or CsVRedraw,
      hInstance:     hInstance,
      hCursor:       LoadCursor(0, IdcArrow),
      lpfnWndProc:   wndProc,
      lpszClassName: class,
    )
    if RegisterClassEx(wcex.addr) == 0:
      raise OSError.newException("RegisterClassEx failed")

  proc createWindow(class: string): HWnd =
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
  result.hdc.SetPixelFormat(result.hdc.ChoosePixelFormat(pfd.addr), pfd.addr)
  result.ctx.raw = wglCreateContext(result.hdc)
  discard result.hdc.wglMakeCurrent(result.ctx.raw)

method makeCurrent*(windows: InvisibleOpenglWindowWinapi) =
  windows.hdc.wglMakeCurrent(windows.ctx.raw)
