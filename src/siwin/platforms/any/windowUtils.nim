import std/[options, importutils]
import pkg/[vmath]
import ./[window]
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
  let ir = window.inputRegion.get((vec2(), window.size.vec2))

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


func popupAnchorOffset(anchor: Edge, size: IVec2): IVec2 =
  case anchor
  of Edge.topLeft: ivec2(0, 0)
  of Edge.top: ivec2(size.x div 2, 0)
  of Edge.topRight: ivec2(size.x, 0)
  of Edge.left: ivec2(0, size.y div 2)
  of Edge.right: ivec2(size.x, size.y div 2)
  of Edge.bottomLeft: ivec2(0, size.y)
  of Edge.bottom: ivec2(size.x div 2, size.y)
  of Edge.bottomRight: ivec2(size.x, size.y)

func popupRelativePos*(placement: PopupPlacement): IVec2 =
  let anchorPoint = placement.anchorRectPos + placement.anchor.popupAnchorOffset(placement.anchorRectSize)
  anchorPoint - placement.gravity.popupAnchorOffset(placement.popupSize()) + placement.offset

proc flipPopupEdgeX*(edge: Edge): Edge =
  case edge
  of Edge.topLeft: Edge.topRight
  of Edge.topRight: Edge.topLeft
  of Edge.left: Edge.right
  of Edge.right: Edge.left
  of Edge.bottomLeft: Edge.bottomRight
  of Edge.bottomRight: Edge.bottomLeft
  else: edge

proc flipPopupEdgeY*(edge: Edge): Edge =
  case edge
  of Edge.topLeft: Edge.bottomLeft
  of Edge.top: Edge.bottom
  of Edge.topRight: Edge.bottomRight
  of Edge.bottomLeft: Edge.topLeft
  of Edge.bottom: Edge.top
  of Edge.bottomRight: Edge.topRight
  else: edge

proc popupOverflowX(posX, width, boundsWidth: int32): int32 {.inline.} =
  max(0'i32, -posX) + max(0'i32, posX + width - boundsWidth)

proc popupOverflowY(posY, height, boundsHeight: int32): int32 {.inline.} =
  max(0'i32, -posY) + max(0'i32, posY + height - boundsHeight)

proc resolvePopupRect*(parentPos, boundsPos, boundsSize: IVec2, placement: PopupPlacement): tuple[pos, size: IVec2] =
  proc popupRectFor(parentPos: IVec2, placement: PopupPlacement): tuple[pos, size: IVec2] {.nimcall.} =
    (parentPos + placement.popupRelativePos(), placement.popupSize())

  var resolvedPlacement = placement
  result = popupRectFor(parentPos, resolvedPlacement)

  if PopupConstraintAdjustment.pcaFlipX in placement.constraintAdjustment:
    var flipped = resolvedPlacement
    flipped.anchor = flipped.anchor.flipPopupEdgeX()
    flipped.gravity = flipped.gravity.flipPopupEdgeX()
    let flippedRect = popupRectFor(parentPos, flipped)
    if popupOverflowX(flippedRect.pos.x - boundsPos.x, flippedRect.size.x, boundsSize.x) <
        popupOverflowX(result.pos.x - boundsPos.x, result.size.x, boundsSize.x):
      resolvedPlacement = flipped
      result = flippedRect

  if PopupConstraintAdjustment.pcaFlipY in placement.constraintAdjustment:
    var flipped = resolvedPlacement
    flipped.anchor = flipped.anchor.flipPopupEdgeY()
    flipped.gravity = flipped.gravity.flipPopupEdgeY()
    let flippedRect = popupRectFor(parentPos, flipped)
    if popupOverflowY(flippedRect.pos.y - boundsPos.y, flippedRect.size.y, boundsSize.y) <
        popupOverflowY(result.pos.y - boundsPos.y, result.size.y, boundsSize.y):
      resolvedPlacement = flipped
      result = flippedRect

  if PopupConstraintAdjustment.pcaSlideX in placement.constraintAdjustment:
    result.pos.x = clamp(result.pos.x, boundsPos.x, max(boundsPos.x, boundsPos.x + boundsSize.x - result.size.x))

  if PopupConstraintAdjustment.pcaSlideY in placement.constraintAdjustment:
    result.pos.y = clamp(result.pos.y, boundsPos.y, max(boundsPos.y, boundsPos.y + boundsSize.y - result.size.y))

  if PopupConstraintAdjustment.pcaResizeX in placement.constraintAdjustment:
    if result.pos.x < boundsPos.x:
      result.size.x -= boundsPos.x - result.pos.x
      result.pos.x = boundsPos.x
    if result.pos.x + result.size.x > boundsPos.x + boundsSize.x:
      result.size.x = max(1'i32, boundsPos.x + boundsSize.x - result.pos.x)
    result.size.x = max(1'i32, result.size.x)

  if PopupConstraintAdjustment.pcaResizeY in placement.constraintAdjustment:
    if result.pos.y < boundsPos.y:
      result.size.y -= boundsPos.y - result.pos.y
      result.pos.y = boundsPos.y
    if result.pos.y + result.size.y > boundsPos.y + boundsSize.y:
      result.size.y = max(1'i32, boundsPos.y + boundsSize.y - result.pos.y)
    result.size.y = max(1'i32, result.size.y)


