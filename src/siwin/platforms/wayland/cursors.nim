import std/[times, importutils, strformat, options, tables, os]
import pkg/[vmath]
import ../../siwindefs, ../../colorutils
import ../any/window {.all.}
import ./[libwayland, protocol, siwinGlobals, sharedBuffer, bitfields, xkb]


type
  CursorImage = object
    size: IVec2
    hotspot: IVec2
    delay: uint32  # in milliseconds
    pixels: seq[uint32]  # argb

  CursorWayland* = object
    hotspot*: IVec2
    surface*: Wl_surface
    animated*: bool

    cursorImages: seq[CursorImage]
    time: int
  
  XCursorParseError = object of ValueError


proc parseXCursor*(data: string, filename: string): seq[CursorImage] =
  if data[0..3] != "Xcur":
    raise XCursorParseError.newException(filename & " is not an XCursor")
  
  proc readUint32(s: string, i: int): uint32 =
    copyMem(result.addr, s[i].addr, uint32.sizeof)

  let nEntries = data.readUint32(12).int
  for entryI in 0..<nEntries:
    let typ = data.readUint32(16 + entryI * 12)
    if typ != 0xfffd0002'u32: continue  # look inly for only images
    let i = data.readUint32(16 + entryI * 12 + 8).int

    let w = data.readUint32(i + 16)
    let h = data.readUint32(i + 20)
    let xhot = data.readUint32(i + 24)
    let yhot = data.readUint32(i + 28)
    let delay = data.readUint32(i + 32)

    result.add CursorImage(
      size: ivec2(w.int32, h.int32),
      hotspot: ivec2(xhot.int32, yhot.int32),
      delay: delay,
    )
    result[^1].pixels.setLen w.int * h.int
    copyMem(result[^1].pixels[0].addr, data[i + 36].addr, w.int * h.int)


proc findCurrentCursorThemeDirectory*(): string =
  result = ""

  let themeName = getEnv("XCURSOR_THEME", "Adwaita")
  
  if dirExists("/usr/share/icons/" & themeName & "/cursors"):
    return "/usr/share/icons/" & themeName
  
  if dirExists(getHomeDir() / (".local/share/icons/" & themeName & "/cursors")):
    return getHomeDir() / (".local/share/icons/" & themeName & "/cursors")


proc loadBuiltinCursor*(globals: SiwinGlobalsWayland, kind: BuiltinCursor): CursorWayland =
  if kind == BuiltinCursor.hided:
    result.surface = globals.compositor.create_surface()
    return
  
  else:
    let cursorDir = findCurrentCursorThemeDirectory()
    
    proc cursorName(kind: BuiltinCursor): tuple[name: string, fallback: BuiltinCursor] =
      result.fallback = BuiltinCursor.arrow
      result.name = case kind
        of BuiltinCursor.arrow: "arrow"
        of BuiltinCursor.arrowUp: "center_ptr"
        of BuiltinCursor.arrowRight: "right_ptr"
        of BuiltinCursor.wait: "wait"
        of BuiltinCursor.arrowWait: (result.fallback = BuiltinCursor.wait; "progress")
        of BuiltinCursor.pointingHand: "pointer"
        of BuiltinCursor.grab: (result.fallback = BuiltinCursor.pointingHand; "grab")
        of BuiltinCursor.text: "text"
        of BuiltinCursor.cross: "cross"
        of BuiltinCursor.sizeAll: "size_all"
        of BuiltinCursor.sizeHorizontal: "sb_h_double_arrow"
        of BuiltinCursor.sizeVertical: "sb_v_double_arrow"
        of BuiltinCursor.sizeTopLeft: "top_left_corner"
        of BuiltinCursor.sizeTopRight: "top_right_corner"
        of BuiltinCursor.sizeBottomLeft: "bottom_left_corner"
        of BuiltinCursor.sizeBottomRight: "bottom_right_corner"
        of BuiltinCursor.hided: "default"
    
    var (name, fallback) = cursorName(kind)
    var cursorPath = cursorDir / name & ".png"
    
    while not fileExists(cursorPath) and fallback != BuiltinCursor.arrow:
      (name, fallback) = cursorName(fallback)
      cursorPath = cursorDir / name & ".png"
    
    if not fileExists(cursorPath):
      return globals.loadBuiltinCursor(BuiltinCursor.hided)

    result.surface = globals.compositor.create_surface()
