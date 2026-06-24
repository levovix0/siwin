import std/[strformat]

import vmath
import siwin

const
  WindowSize = ivec2(980, 620)

type
  BlurMode = enum
    wholeWindow
    regions

  DemoState = object
    mode: BlurMode
    material: WindowBackdropMaterial

const Materials = [
  wbmDefault,
  wbmLight,
  wbmDark,
  wbmTitlebar,
  wbmSidebar,
  wbmHud,
  wbmPopover,
]

proc materialName(material: WindowBackdropMaterial): string =
  case material
  of wbmDefault: "default"
  of wbmLight: "light"
  of wbmDark: "dark"
  of wbmTitlebar: "titlebar"
  of wbmSidebar: "sidebar"
  of wbmHud: "hud"
  of wbmPopover: "popover"

proc modeName(mode: BlurMode): string =
  case mode
  of wholeWindow: "whole window"
  of regions: "regions"

proc backdropRegions(size: IVec2): seq[WindowVisualRegion] =
  let
    margin = 42'i32
    sidebarW = min(260'i32, max(120'i32, size.x div 3))
    headerH = min(130'i32, max(80'i32, size.y div 5))
    cardW = max(180'i32, size.x - sidebarW - margin * 3)
    cardH = max(120'i32, (size.y - headerH - margin * 3) div 2)

  @[
    WindowVisualRegion(pos: ivec2(margin, margin), size: ivec2(sidebarW, size.y - margin * 2)),
    WindowVisualRegion(
      pos: ivec2(sidebarW + margin * 2, margin),
      size: ivec2(cardW, headerH),
    ),
    WindowVisualRegion(
      pos: ivec2(sidebarW + margin * 2, headerH + margin * 2),
      size: ivec2(cardW, cardH),
    ),
    WindowVisualRegion(
      pos: ivec2(sidebarW + margin * 2, headerH + cardH + margin * 3),
      size: ivec2(cardW, cardH),
    ),
  ]

proc applyBackdrop(window: Window, state: DemoState) =
  let config =
    case state.mode
    of wholeWindow:
      WindowBackdropConfig(kind: wbkMaterial, material: state.material)
    of regions:
      WindowBackdropConfig(
        kind: wbkMaterial,
        material: state.material,
        regions: window.size.backdropRegions(),
      )

  if window.trySetBackdrop(config):
    echo fmt"[metal-blur-demo] mode={state.mode.modeName} material={state.material.materialName}"
  else:
    echo "[metal-blur-demo] backdrop blur is not supported by this window"

proc nextMaterial(material: WindowBackdropMaterial): WindowBackdropMaterial =
  for i, item in Materials:
    if item == material:
      return Materials[(i + 1) mod Materials.len]
  wbmDefault

when not defined(macosx):
  echo "metal_blur_demo requires macOS because Siwin Metal windows are macOS-only."
else:
  let globals = newSiwinGlobals()
  let window = globals.newMetalWindow(
    size = WindowSize,
    title = "siwin Metal blur demo",
    transparent = true,
  )

  var state = DemoState(mode: regions, material: wbmDefault)

  echo "[metal-blur-demo] Controls:"
  echo "  1: whole-window blur"
  echo "  2: region blur"
  echo "  M: cycle material"
  echo "  C: clear backdrop"
  echo "  ESC: quit"
  echo fmt"[metal-blur-demo] capabilities={window.visualCapabilities}"

  if wvcBackdropBlur in window.visualCapabilities:
    window.applyBackdrop(state)
  else:
    echo "[metal-blur-demo] this macOS window did not report backdrop blur support"

  window.run(
    WindowEventsHandler(
      onResize: proc(e: ResizeEvent) =
        if e.window.backdrop.kind != wbkNone:
          e.window.applyBackdrop(state)
      ,
      onKey: proc(e: KeyEvent) =
        if not e.pressed or e.generated:
          return

        case e.key
        of Key.escape:
          e.window.close()
        of Key.n1:
          state.mode = wholeWindow
          e.window.applyBackdrop(state)
        of Key.n2:
          state.mode = regions
          e.window.applyBackdrop(state)
        of Key.m:
          state.material = state.material.nextMaterial()
          e.window.applyBackdrop(state)
        of Key.c:
          e.window.clearBackdrop()
          echo "[metal-blur-demo] backdrop cleared"
        else:
          discard
    )
  )
