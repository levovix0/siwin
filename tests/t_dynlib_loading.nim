import std/[dynlib, unittest]
import siwin/siwindefs

let missingLibrary = loadLib("siwin-test-library-that-does-not-exist")
siwin_loadDynlibIfExists missingLibrary:
  proc missingFunction*(): cint

let libc = loadLib(
  when defined(windows):
    "msvcrt.dll"
  elif defined(macosx):
    "libSystem.B.dylib"
  elif defined(freebsd):
    "libc.so.7"
  elif defined(openbsd):
    "libc.so"
  elif defined(netbsd):
    "libc.so.12"
  else:
    "libc.so.6"
)
siwin_loadDynlibIfExists libc:
  proc strlen*(text: cstring): csize_t {.raises: [].}
  proc stringLength(text: cstring): csize_t {.importc: "strlen", raises: [].}
  proc formatString(
    buffer: cstring, format: cstring
  ): cint {.importc: "sprintf", varargs.}

  proc siwin_symbol_that_does_not_exist(): cint {.importc.}
  proc missingAlias(): cint {.importc: "siwin_another_missing_symbol".}

suite "optional dynamic library declarations":
  test "missing libraries and symbols leave nil pointers":
    check missingLibrary == nil
    check missingFunction == nil
    check libc != nil
    check siwin_symbol_that_does_not_exist == nil
    check missingAlias == nil

  test "original and aliased declarations resolve the same symbol":
    check strlen != nil
    check stringLength == strlen
    check stringLength("siwin") == 5
    let noRaiseCall: proc(text: cstring): csize_t {.cdecl, raises: [].} = stringLength
    check noRaiseCall("") == 0

  test "aliased declarations preserve varargs":
    check formatString != nil
    var buffer: array[32, char]
    check formatString(cast[cstring](buffer.addr), "%s %d", "siwin".cstring, 7.cint) == 7
    check $cast[cstring](buffer.addr) == "siwin 7"

when defined(linux) or defined(bsd):
  import x11/[xlib, xutil]
  import siwin/platforms/x11/[siwinGlobals, window, glx]
  import siwin/platforms/wayland/egl {.all.}
  import siwin/platforms/wayland/libwayland
  import siwin/platforms/any/window as anyWindow
  import siwin/platforms/wayland/vkWayland
  import siwin/platforms/x11/vkXlib
  import siwin/platforms/x11/x11api as nativeX11
  import vmath

  # Older projects can pass the original package types to Siwin's public API.
  static:
    doAssert anyWindow.VulkanSurface is uint64
    doAssert vkWayland.VkSurfaceHandle is uint64
    doAssert vkXlib.VkSurfaceHandle is uint64
    doAssert compiles(
      block:
        var globals: SiwinGlobalsX11
        var display: PDisplay = globals.display
        discard glxChooseVisual(display, 0, [0'i32])
        var hints: XSizeHints
        hints.applyMinSizeHint(ivec2(1, 1))
        if glxSwapIntervalMesa != nil:
          glxSwapIntervalMesa(1)
        if glxSwapIntervalSgi != nil:
          glxSwapIntervalSgi(1)
    )
    doAssert compiles(
      block:
        var display: EglDisplay = eglGetDisplay(nil)
        var config: EglConfig
        var context: EglContext
        var surface: EglSurface
        var ok: bool = eglInitialize(display)
        var error: EglError = eglGetError()
        ok = eglChooseConfig(display, nil, nil, 0, nil)
        context = eglCreateContext(display, config)
        surface = eglCreatePbufferSurface(display, config)
        surface = eglCreateWindowSurface(display, config, nil)
        surface = eglCreatePlatformWindowSurface(display, config, nil)
        ok = eglMakeCurrent(display, surface, surface, context)
        context = eglGetCurrentContext()
        ok = eglSwapBuffers(display, surface)
        ok = eglDestroyContext(display, context)
        ok = eglDestroySurface(display, surface)
        ok = eglTerminate(display)
        var window: EglWindow = wl_egl_window_create(nil, 1, 1)
        wl_egl_window_resize(window, 2, 2, 0, 0)
        wl_egl_window_get_attached_size(window, nil, nil)
        wl_egl_window_destroy(window)
    )
    doAssert compiles(
      block:
        var display: pointer = wl_display_connect(nil)
        let fd: FileHandle = wl_display_get_fd(display)
        var connected: pointer = wl_display_connect_to_fd(fd)
        var status: int32 = wl_display_flush(display)
        status = wl_display_prepare_read(display)
        status = wl_display_read_events(display)
        wl_display_cancel_read(display)
        status = wl_display_roundtrip(display)
        status = wl_display_dispatch_pending(display)
        wl_display_disconnect(display)
    )

  suite "EGL boolean conversion":
    test "public bool preserves the full native unsigned-int result":
      let original = eglInitializeRaw
      defer:
        eglInitializeRaw = original
      var nativeResult {.global.}: cuint
      eglInitializeRaw = proc(d: EglDisplay, major, minor: ptr int32): cuint {.cdecl.} =
        nativeResult
      nativeResult = 0
      check not eglInitialize(nil)
      nativeResult = 1
      check eglInitialize(nil)
      # A nonzero high byte detects narrowing the result before conversion.
      nativeResult = 0x100
      check eglInitialize(nil)

    test "native entry point has the EGLBoolean ABI":
      let nativeCall: proc(d: EglDisplay, major, minor: ptr int32): cuint {.cdecl.} =
        eglInitializeRaw
      check (nativeCall == nil) == (libeglHandle == nil)

    test "native EGL reports failures and completes a context lifecycle":
      if libeglHandle == nil or not nativeX11.x11Available():
        skip()
      else:
        check not eglInitialize(nil)
        check not eglTerminate(nil)
        let display = nativeX11.XOpenDisplay(nil)
        if display == nil:
          skip()
        else:
          defer:
            discard nativeX11.XCloseDisplay(display)
          initEgl(display)
          defer:
            terminateEgl()
          let context = egl.newOpenglContext()
          defer:
            context.destroy()
          context.makeCurrent()
          check eglGetCurrentContext() == context.ctx
