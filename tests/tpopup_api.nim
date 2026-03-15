import unittest
import std/math
import pkg/vmath
import siwin/[window, platforms]

when defined(macosx):
  import siwin/platforms/cocoa/window

proc toPoints(distance: int32, scale: float32): int32 =
  if scale <= 0'f32:
    return distance
  round(distance.float64 / scale.float64).int32

proc toPoints(size: IVec2, scale: float32): IVec2 =
  ivec2(toPoints(size.x, scale), toPoints(size.y, scale))

suite "siwin popup api":
  test "popup placement resolves size and relative position":
    let placement = PopupPlacement(
      anchorRectPos: ivec2(20, 30),
      anchorRectSize: ivec2(80, 24),
      size: ivec2(120, 200),
      anchor: bottomLeft,
      gravity: topLeft,
      offset: ivec2(3, 4),
      constraintAdjustment:
        {PopupConstraintAdjustment.pcaSlideX, PopupConstraintAdjustment.pcaFlipY},
      reactive: true,
    )

    check placement.popupSize() == ivec2(120, 200)
    check placement.popupRelativePos() == ivec2(23, 58)

  test "popup placement falls back to anchor rect size":
    let placement = PopupPlacement(
      anchorRectPos: ivec2(10, 12),
      anchorRectSize: ivec2(40, 18),
      anchor: topRight,
      gravity: bottomRight,
      offset: ivec2(-2, -3),
    )

    check placement.popupSize() == ivec2(40, 18)
    check placement.popupRelativePos() == ivec2(8, -9)

  when defined(macosx):
    test "cocoa firstStep syncs initial window position":
      let globals = newSiwinGlobals(Platform.cocoa)
      let parent = globals.newSoftwareRenderingWindow(
        size = ivec2(300, 200),
        title = "popup parent initial pos",
      )
      parent.firstStep(makeVisible = true)
      parent.step()

      check parent.pos == parent.WindowCocoa.framePos()

      close parent

    test "cocoa popup placement uses parent content position":
      let globals = newSiwinGlobals(Platform.cocoa)
      let parent = globals.newSoftwareRenderingWindow(
        size = ivec2(300, 200),
        title = "popup parent",
      )
      parent.pos = ivec2(140, 160)
      parent.firstStep(makeVisible = false)
      parent.step()

      let scale = parent.uiScale
      let initialPlacement = PopupPlacement(
        anchorRectPos: ivec2(parent.size.x div 3, parent.size.y div 4),
        anchorRectSize: ivec2(parent.size.x div 5, 48),
        size: ivec2(240, 180),
        anchor: bottomRight,
        gravity: topLeft,
        offset: ivec2(0, 14),
      )
      let popup = globals.newPopupWindow(parent, initialPlacement, grab = true)
      popup.firstStep(makeVisible = false)
      popup.step()

      check popup.pos == parent.WindowCocoa.contentPos() + initialPlacement.popupRelativePos().toPoints(scale)
      check popup.size == initialPlacement.popupSize()

      let updatedPlacement = PopupPlacement(
        anchorRectPos: ivec2(parent.size.x div 2, parent.size.y div 3),
        anchorRectSize: ivec2(96, 56),
        size: ivec2(140, 110),
        anchor: bottomRight,
        gravity: topRight,
        offset: ivec2(-8, 10),
      )
      popup.reposition(updatedPlacement)
      popup.step()

      check popup.pos == parent.WindowCocoa.contentPos() + updatedPlacement.popupRelativePos().toPoints(scale)
      check popup.size == updatedPlacement.popupSize()

      close popup
      close parent
