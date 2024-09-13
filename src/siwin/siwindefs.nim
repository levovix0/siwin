import std/[macros]
import ./[dynutils]

const siwin_use_pure_enums* {.booldefine.} = off

const siwin_dynlib_name* =
  when defined(windows): "siwin.dll"
  elif defined(maxosx): "libsiwin.dylib"
  else: "libsiwin.so"


const siwin_use_dynlib* = defined(siwin_use_dynlib)
const siwin_build_dynlib* = defined(siwin_build_dynlib)


macro siwin_importExport*(body) =
  newCall(
    bindSym("importExport"),
    newLit(siwin_use_dynlib),
    newLit(siwin_build_dynlib),
    newLit(siwin_dynlib_name),
    newLit("siwin_" & $body.name),
    body,
  )
