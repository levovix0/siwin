import unittest
import pkg/vmath
import siwin/window

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
