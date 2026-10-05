import std/[dynlib, unittest]
import siwin/siwindefs

let missingLibrary = loadLib("siwin-test-library-that-does-not-exist")
siwin_loadDynlibIfExists missingLibrary:
  proc missingFunction*(): cint

let libc = loadLib(
  when defined(windows): "msvcrt.dll"
  elif defined(macosx): "libSystem.B.dylib"
  elif defined(freebsd): "libc.so.7"
  elif defined(openbsd): "libc.so"
  elif defined(netbsd): "libc.so.12"
  else: "libc.so.6"
)
siwin_loadDynlibIfExists libc:
  proc strlen*(text: cstring): csize_t {.raises: [].}
  proc stringLength(text: cstring): csize_t {.importc: "strlen", raises: [].}
  proc formatString(buffer: cstring, format: cstring): cint {.importc: "sprintf", varargs.}
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
  import siwin/platforms/wayland/egl
  import siwin/platforms/wayland/libwayland
  import vmath

  # Older projects can pass the original package types to Siwin's public API.
  static:
    doAssert compiles(block:
      var globals: SiwinGlobalsX11
      var display: PDisplay = globals.display
      discard glxChooseVisual(display, 0, [0'i32])
      var hints: XSizeHints
      hints.applyMinSizeHint(ivec2(1, 1))
      if glxSwapIntervalMesa != nil: glxSwapIntervalMesa(1)
      if glxSwapIntervalSgi != nil: glxSwapIntervalSgi(1)
    )
    doAssert compiles(block:
      var display: EglDisplay
      var context: EglContext
      var surface: EglSurface
      var ok: bool = eglInitialize(display)
      ok = eglChooseConfig(display, nil, nil, 0, nil)
      ok = eglMakeCurrent(display, surface, surface, context)
      ok = eglSwapBuffers(display, surface)
      ok = eglDestroyContext(display, context)
      ok = eglDestroySurface(display, surface)
      eglTerminate(display)
    )
    doAssert compiles(block:
      let initialize: proc(d: EglDisplay; major, minor: ptr int32): bool {.cdecl.} = eglInitialize
      let connect: proc(name: cstring): Wl_display {.cdecl.} = wl_display_connect
      if initialize != nil: discard initialize(nil, nil, nil)
      if connect != nil: discard connect(nil)
    )
