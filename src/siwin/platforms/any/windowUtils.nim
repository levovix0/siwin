import std/[options, importutils]
import pkg/[vmath]
import ./[window]
import ../../[siwindefs]


when siwin_use_pure_enums:
  {.pragma: siwinPureEnum, pure.}
else:
  {.pragma: siwinPureEnum.}


privateAccess Window


type
  WindowPart* {.siwinPureEnum.} = enum
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
  if window.titleRegion.isNone and window.borderWidth.isNone: return
  
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

