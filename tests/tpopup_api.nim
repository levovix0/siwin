import unittest
import std/math
import std/[os, osproc, strutils]
import std/strtabs
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

proc scalePlacementToPoints(placement: PopupPlacement, scale: float32): PopupPlacement =
  PopupPlacement(
    anchorRectPos: placement.anchorRectPos.toPoints(scale),
    anchorRectSize: placement.anchorRectSize.toPoints(scale),
    size: placement.size.toPoints(scale),
    anchor: placement.anchor,
    gravity: placement.gravity,
    offset: placement.offset.toPoints(scale),
    constraintAdjustment: placement.constraintAdjustment,
    reactive: placement.reactive,
  )

proc stepUntil(window: Window, predicate: proc(): bool, maxSteps = 32) =
  for _ in 0 ..< maxSteps:
    if predicate():
      break
    window.step()

type PopupProbeResult = object
  platform: string
  relPos: IVec2
  logicalSize: IVec2
  uiScale: float32

proc parseIvec2(value: string): IVec2 =
  let parts = value.split(',')
  if parts.len != 2:
    raise newException(ValueError, "invalid ivec2: " & value)
  ivec2(parseInt(parts[0]).int32, parseInt(parts[1]).int32)

proc parsePopupProbeResult(output: string): PopupProbeResult =
  for line in output.splitLines():
    if not line.startsWith("POPUP_RESULT "):
      continue

    for field in line["POPUP_RESULT ".len .. ^1].splitWhitespace():
      let kv = field.split('=', maxsplit = 1)
      if kv.len != 2:
        continue
      case kv[0]
      of "platform":
        result.platform = kv[1]
      of "relPos":
        result.relPos = parseIvec2(kv[1])
      of "logicalSize":
        result.logicalSize = parseIvec2(kv[1])
      of "uiScale":
        result.uiScale = parseFloat(kv[1]).float32
      else:
        discard

    if result.platform.len != 0:
      return

  raise newException(ValueError, "missing POPUP_RESULT line")

proc popupProbePlacement(): PopupPlacement =
  PopupPlacement(
    anchorRectPos: ivec2(40, 100),
    anchorRectSize: ivec2(120, 34),
    size: ivec2(520, 420),
    anchor: bottomLeft,
    gravity: topLeft,
    offset: ivec2(0, 14),
    constraintAdjustment: {},
    reactive: false,
  )

proc runPopupProbe(platform: Platform) =
  let globals = newSiwinGlobals(platform)
  let parent = globals.newSoftwareRenderingWindow(
    size = ivec2(780, 630),
    title = "popup probe parent",
  )
  parent.firstStep(makeVisible = true)

  var
    lastParentPos = ivec2(low(int32), low(int32))
    parentStableSteps = 0

  for _ in 0 ..< 120:
    parent.step()
    if parent.pos == lastParentPos:
      inc parentStableSteps
    else:
      parentStableSteps = 0
      lastParentPos = parent.pos
    if parentStableSteps >= 8:
      break

  let placement = popupProbePlacement()
  let popup = globals.newPopupWindow(parent, placement, grab = true)
  popup.firstStep(makeVisible = true)

  var
    lastRelPos = ivec2(low(int32), low(int32))
    lastLogicalSize = ivec2(low(int32), low(int32))
    stableSteps = 0

  for _ in 0 ..< 180:
    parent.step()
    popup.step()

    let relPos = popup.pos - parent.pos
    let logicalSize = popup.size.toPoints(popup.uiScale)
    if relPos == lastRelPos and logicalSize == lastLogicalSize:
      inc stableSteps
    else:
      stableSteps = 0
      lastRelPos = relPos
      lastLogicalSize = logicalSize

    if stableSteps >= 8:
      break

  echo "POPUP_RESULT platform=", $platform, " relPos=", lastRelPos.x, ",", lastRelPos.y,
    " logicalSize=", lastLogicalSize.x, ",", lastLogicalSize.y,
    " uiScale=", popup.uiScale

  close popup
  close parent
  quit(0)

proc runPopupProbeSubprocess(platform: Platform; waylandDebug = false): tuple[output: string, exitCode: int] =
  var env = newStringTable()
  for key, value in envPairs():
    env[key] = value
  env["SIWIN_POPUP_TEST_HELPER"] = $platform
  if waylandDebug:
    env["WAYLAND_DEBUG"] = "1"
  execCmdEx(getAppFilename().quoteShell & " --popup-runtime-helper", env = env)

when defined(linux) or defined(bsd):
  if getEnv("SIWIN_POPUP_TEST_HELPER").len != 0 and paramCount() > 0 and paramStr(1) == "--popup-runtime-helper":
    runPopupProbe(parseEnum[Platform](getEnv("SIWIN_POPUP_TEST_HELPER")))

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

  when defined(linux) or defined(bsd):
    test "wayland and x11 popup final geometry match for popup probe":
      if Platform.wayland notin availablePlatforms() or Platform.x11 notin availablePlatforms():
        skip()

      let wayland = runPopupProbeSubprocess(Platform.wayland, waylandDebug = true)
      require wayland.exitCode == 0
      check "xdg_popup" in wayland.output
      check "configure(" in wayland.output

      let x11 = runPopupProbeSubprocess(Platform.x11)
      require x11.exitCode == 0

      let waylandResult = parsePopupProbeResult(wayland.output)
      let x11Result = parsePopupProbeResult(x11.output)
      check waylandResult.relPos == x11Result.relPos
      check waylandResult.logicalSize == x11Result.logicalSize

    test "x11 popup window position matches relative placement in unconstrained case":
      if Platform.x11 notin availablePlatforms():
        skip()

      let globals = newSiwinGlobals(Platform.x11)
      let parent = globals.newSoftwareRenderingWindow(
        size = ivec2(300, 200),
        title = "popup parent",
      )
      parent.firstStep(makeVisible = false)
      parent.step()

      let placement = PopupPlacement(
        anchorRectPos: ivec2(40, 48),
        anchorRectSize: ivec2(96, 32),
        size: ivec2(140, 110),
        anchor: bottomLeft,
        gravity: topLeft,
        offset: ivec2(0, 14),
      )
      let popup = globals.newPopupWindow(parent, placement, grab = true)
      popup.firstStep(makeVisible = false)
      popup.stepUntil(proc(): bool = popup.pos == parent.pos + placement.popupRelativePos() and popup.size == placement.popupSize())

      check popup.pos == parent.pos + placement.popupRelativePos()
      check popup.size == placement.popupSize()

      let updatedPlacement = PopupPlacement(
        anchorRectPos: ivec2(120, 76),
        anchorRectSize: ivec2(84, 28),
        size: ivec2(120, 96),
        anchor: topRight,
        gravity: bottomRight,
        offset: ivec2(-6, -8),
      )
      popup.reposition(updatedPlacement)
      popup.stepUntil(
        proc(): bool =
          popup.pos == parent.pos + updatedPlacement.popupRelativePos() and
          popup.size == updatedPlacement.popupSize()
      )

      check popup.pos == parent.pos + updatedPlacement.popupRelativePos()
      check popup.size == updatedPlacement.popupSize()

      close popup
      close parent
