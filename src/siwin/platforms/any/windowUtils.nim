import std/[options, importutils]
import pkg/[vmath]
import ./[window {.all.}, clipboards {.all.}]
import ../../[siwindefs]


when siwin_use_pure_enums:
  {.pragma: siwin_enum, pure.}
else:
  {.pragma: siwin_enum.}


privateAccess Window


type
  WindowPart* {.siwin_enum.} = enum
    none
    client
    title
    border_left
    border_right
    border_top
    border_bottom
    border_top_left
    border_top_right
    border_bottom_left
    border_bottom_right



proc windowPartAt*(window: Window, mousePos: Vec2): WindowPart =
  if window.titleRegion.isNone and window.borderWidth.isNone: return WindowPart.client
  
  let tr = window.titleRegion.get((vec2(), vec2(-1, -1)))
  let (w, ow, dw) = window.borderWidth.get((0'f32, 0'f32, 0'f32))
  let ir = window.inputRegion.get((vec2(), window.m_size.vec2))

  if (
    (
      mousePos.x in (ir.pos.x - ow)..(ir.pos.x + dw - 1) and
      mousePos.y in (ir.pos.y - ow)..(ir.pos.y + w - 1)
    ) or (
      mousePos.x in (tr.pos.x - ow)..(tr.pos.x + w - 1) and
      mousePos.y in (tr.pos.y - ow)..(tr.pos.y + dw - 1)
    )
  ):
    return WindowPart.border_top_left
  
  elif (
    (
      mousePos.x in (ir.pos.x + ir.size.x - dw)..(ir.pos.x + ir.size.x + ow) and
      mousePos.y in (ir.pos.y - ow)..(ir.pos.y + w - 1)
    ) or (
      mousePos.x in (tr.pos.x + tr.size.x - w)..(tr.pos.x + tr.size.x + ow) and
      mousePos.y in (tr.pos.y - ow)..(tr.pos.y + dw - 1)
    )
  ):
    return WindowPart.border_top_right
  
  elif (
    (
      mousePos.x in (ir.pos.x - ow)..(ir.pos.x + dw - 1) and
      mousePos.y in (ir.pos.y + ir.size.y - w)..(ir.pos.y + ir.size.y + ow)
    ) or (
      mousePos.x in (tr.pos.x - ow)..(tr.pos.x + w - 1) and
      mousePos.y in (tr.pos.y + tr.size.y - dw)..(tr.pos.y + tr.size.y + ow)
    )
  ):
    return WindowPart.border_bottom_left

  elif (
    (
      mousePos.x in (ir.pos.x + ir.size.x - dw)..(ir.pos.x + ir.size.x + ow) and
      mousePos.y in (ir.pos.y + ir.size.y - w)..(ir.pos.y + ir.size.y + ow)
    ) or (
      mousePos.x in (tr.pos.x + tr.size.x - w)..(tr.pos.x + tr.size.x + ow) and
      mousePos.y in (tr.pos.y + tr.size.y - dw)..(tr.pos.y + tr.size.y + ow)
    )
  ):
    return WindowPart.border_bottom_right
  
  elif (
    mousePos.x in (ir.pos.x - ow)..(ir.pos.x + ir.size.x + ow - 1) and
    mousePos.y in (ir.pos.y - ow)..(ir.pos.y + w + 2 - 1)
  ):
    return WindowPart.border_top

  elif (
    mousePos.x in (ir.pos.x - ow)..(ir.pos.x + ir.size.x + ow - 1) and
    mousePos.y in (ir.pos.y + ir.size.y - w)..(ir.pos.y + ir.size.y + ow + 2)
  ):
    return WindowPart.border_bottom
  
  elif (
    mousePos.x in (ir.pos.x - ow)..(ir.pos.x + w + 2 - 1) and
    mousePos.y in (ir.pos.y - ow)..(ir.pos.y + ir.size.y + ow - 1)
  ):
    return WindowPart.border_left

  elif (
    mousePos.x in (ir.pos.x + ir.size.x - w)..(ir.pos.x + ir.size.x + ow + 2) and
    mousePos.y in (ir.pos.y - ow)..(ir.pos.y + ir.size.y + ow - 1)
  ):
    return WindowPart.border_right

  elif (
    mousePos.x in tr.pos.x..(tr.pos.x + tr.size.x) and
    mousePos.y in tr.pos.y..(tr.pos.y + tr.size.y)
  ):
    return WindowPart.title
  
  elif (
    mousePos.x in ir.pos.x..(ir.pos.x + ir.size.x - 1) and
    mousePos.y in ir.pos.y..(ir.pos.y + ir.size.y - 1)
  ):
    return WindowPart.client
  
  else:
    return WindowPart.none


template makeWindowVtable*(baseProcName, extendedProcName: untyped): WindowVtable =
  WindowVtable(
    close: cast[proc(window: Window) {.cdecl.}](`baseProcName close`),
    redraw: cast[proc(window: Window) {.cdecl.}](`baseProcName redraw`),

    destroy: cast[proc(window: Window) {.cdecl.}](`extendedProcName destroy`),
    displayImpl: cast[proc(window: Window) {.cdecl.}](`extendedProcName displayImpl`),

    set_frameless: cast[proc(window: Window, v: bool) {.cdecl.}](`baseProcName set_frameless`),
    set_cursor: cast[proc(window: Window, v: Cursor) {.cdecl.}](`baseProcName set_cursor`),
    set_separateTouch: cast[proc(window: Window, v: bool) {.cdecl.}](`baseProcName set_separateTouch`),
    
    set_size: cast[proc(window: Window, v: IVec2) {.cdecl.}](`baseProcName set_size`),
    set_pos: cast[proc(window: Window, v: IVec2) {.cdecl.}](`baseProcName set_pos`),
    set_title: cast[proc(window: Window, v: string) {.cdecl.}](`baseProcName set_title`),
    
    set_fullscreen: cast[proc(window: Window, v: bool) {.cdecl.}](`baseProcName set_fullscreen`),
    set_maximized: cast[proc(window: Window, v: bool) {.cdecl.}](`baseProcName set_maximized`),
    set_minimized: cast[proc(window: Window, v: bool) {.cdecl.}](`baseProcName set_minimized`),
    set_visible: cast[proc(window: Window, v: bool) {.cdecl.}](`baseProcName set_visible`),
    
    set_resizable: cast[proc(window: Window, v: bool) {.cdecl.}](`baseProcName set_resizable`),
    set_minSize: cast[proc(window: Window, v: IVec2) {.cdecl.}](`baseProcName set_minSize`),
    set_maxSize: cast[proc(window: Window, v: IVec2) {.cdecl.}](`baseProcName set_maxSize`),
    
    set_icon: cast[proc(window: Window, v: PixelBuffer) {.cdecl.}](`baseProcName set_icon`),
    clear_icon: cast[proc(window: Window) {.cdecl.}](`baseProcName clear_icon`),
    
    startInteractiveMove: cast[proc(window: Window, pos: Option[Vec2] = none Vec2) {.cdecl.}](`baseProcName startInteractiveMove`),
    startInteractiveResize: cast[proc(window: Window, edge: Edge, pos: Option[Vec2] = none Vec2) {.cdecl.}](`baseProcName startInteractiveResize`),
    
    showWindowMenu: cast[proc(window: Window, pos: Option[Vec2] = none Vec2) {.cdecl.}](`baseProcName showWindowMenu`),
    setInputRegion: cast[proc(window: Window, pos, size: Vec2) {.cdecl.}](`baseProcName setInputRegion`),
    setTitleRegion: cast[proc(window: Window, pos, size: Vec2) {.cdecl.}](`baseProcName setTitleRegion`),
    setBorderWidth: cast[proc(window: Window, innerWidth, outerWidth: float32, diagonalSize: float32) {.cdecl.}](`baseProcName setBorderWidth`),
    
    set_dragStatus: cast[proc(window: Window, v: DragStatus) {.cdecl.}](`baseProcName set_dragStatus`),
    
    pixelBuffer: cast[proc(window: Window): PixelBuffer {.cdecl.}](`extendedProcName pixelBuffer`),
    
    makeCurrent: cast[proc(window: Window) {.cdecl.}](`extendedProcName makeCurrent`),
    set_vsync: cast[proc(window: Window, v: bool, silent = false) {.cdecl.}](`extendedProcName set_vsync`),
    
    vulkanSurface: cast[proc(window: Window): pointer {.cdecl.}](`extendedProcName vulkanSurface`),
    
    firstStep: cast[proc(window: Window, makeVisible = true) {.cdecl.}](`baseProcName firstStep`),
    step: cast[proc(window: Window): bool {.cdecl.}](`baseProcName step`),
  )


template makeSiwinGlobalsVtable*(baseProcName: untyped): SiwinGlobalsVtable =
  SiwinGlobalsVtable(
    screenCount: cast[proc(globals: SiwinGlobals): int {.cdecl.}](`baseProcName screenCount`),
    defaultScreen: cast[proc(globals: SiwinGlobals): Screen {.cdecl.}](`baseProcName defaultScreen`),
    screenSize: cast[proc(globals: SiwinGlobals, n: Screen): IVec2 {.cdecl, raises: [ValueError].}](`baseProcName screenSize`),
  )


template makeClipboardVtable*(baseProcName: untyped): ClipboardVtable =
  ClipboardVtable(
    content: cast[proc(
      clipboard: Clipboard, kind: ClipboardContentKind, mimeType: string = "text/plain"
    ): ClipboardContent {.cdecl.}](`baseProcName content`),
    
    set_content: cast[proc(
      clipboard: Clipboard, content: ClipboardConvertableContent
    ) {.cdecl.}](`baseProcName set_content`),
  )

