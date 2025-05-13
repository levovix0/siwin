import std/[importutils]
import winapi
import ../any/[window {.all.} as anyWindow]


privateAccess Window


type
  InvisibleOpenglWindowWinapi* = ptr InvisibleOpenglWindowWinapiObj
  InvisibleOpenglWindowWinapiObj = object of Window
    handle: HWnd
    hdc: Hdc
    ctx: WglContext


proc winapi_invisible_close(window: InvisibleOpenglWindowWinapi) =
  if window.hdc != 0:
    DeleteDC window.hdc
  if window.handle != 0:
    DestroyWindow(window.handle)
  dealloc window.vtable
  dealloc window


proc winapi_invisible_makeCurrent(window: InvisibleOpenglWindowWinapi) =
  window.hdc.wglMakeCurrent(window.ctx.raw)


proc newOpenglContextWinapi*: InvisibleOpenglWindowWinapi =
  result = create(InvisibleOpenglWindowWinapiObj)
  result.vtable = create(WindowVtable)
  result.vtable.close = cast[proc(window: Window) {.cdecl.}](winapi_invisible_close)
  result.vtable.makeCurrent = cast[proc(window: Window) {.cdecl.}](winapi_invisible_makeCurrent)

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
