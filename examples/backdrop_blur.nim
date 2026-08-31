import std/strformat

import vmath
import siwin

const
  WindowSize = ivec2(980, 620)
  Materials = [
    wbmDefault,
    wbmLight,
    wbmDark,
    wbmTitlebar,
    wbmSidebar,
    wbmHud,
    wbmPopover,
  ]

type
  BlurMode = enum
    wholeWindow
    regions

  DemoState = object
    rgbaBuffer: seq[Color32bit]
    mode: BlurMode
    material: WindowBackdropMaterial
    useMaterial: bool

proc rgba(r, g, b, a: byte): Color32bit =
  [r, g, b, a]

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
    cardW = max(1'i32, size.x - sidebarW - margin * 3)
    cardH = max(1'i32, (size.y - headerH - margin * 3) div 2)

  @[
    WindowVisualRegion(
      pos: ivec2(margin, margin),
      size: ivec2(sidebarW, max(1'i32, size.y - margin * 2)),
    ),
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

proc ensureBuffer(state: var DemoState, size: IVec2) =
  let pixelCount = max(1, (size.x * size.y).int)
  if state.rgbaBuffer.len != pixelCount:
    state.rgbaBuffer.setLen(pixelCount)

proc fill(state: var DemoState, size: IVec2, color: Color32bit) =
  for i in 0 ..< size.x * size.y:
    state.rgbaBuffer[i] = color

proc fillRect(
    state: var DemoState,
    size: IVec2,
    region: WindowVisualRegion,
    color: Color32bit,
) =
  let
    x0 = max(0'i32, region.pos.x)
    y0 = max(0'i32, region.pos.y)
    x1 = min(size.x, region.pos.x + region.size.x)
    y1 = min(size.y, region.pos.y + region.size.y)
  if x0 >= x1 or y0 >= y1:
    return

  for y in y0 ..< y1:
    let row = y * size.x
    for x in x0 ..< x1:
      state.rgbaBuffer[row + x] = color

proc drawFrame(state: var DemoState, size: IVec2) =
  state.ensureBuffer(size)
  state.fill(size, rgba(18, 22, 30, 48))

  for i, region in size.backdropRegions():
    let color =
      if i mod 2 == 0: rgba(38, 48, 66, 142)
      else: rgba(50, 42, 64, 142)
    state.fillRect(size, region, color)

proc nextMaterial(material: WindowBackdropMaterial): WindowBackdropMaterial =
  for i, item in Materials:
    if item == material:
      return Materials[(i + 1) mod Materials.len]
  wbmDefault

proc applyBackdrop(window: Window, state: DemoState) =
  let effectRegions =
    case state.mode
    of wholeWindow: @[]
    of regions: window.size.backdropRegions()

  let config =
    if state.useMaterial:
      initWindowBackdrop(state.material, effectRegions)
    else:
      initWindowBackdrop(effectRegions)

  if window.trySetBackdrop(config):
    let effect =
      if state.useMaterial: state.material.materialName
      else: "blur"
    echo fmt"[backdrop-blur-demo] mode={state.mode.modeName} effect={effect}"
  else:
    echo "[backdrop-blur-demo] the requested backdrop is unavailable"

let globals = newSiwinGlobals()
let window = globals.newSoftwareRenderingWindow(
  size = WindowSize,
  title = "siwin backdrop blur demo",
  transparent = true,
)

var state = DemoState(mode: wholeWindow, material: wbmDefault)

echo "[backdrop-blur-demo] Controls:"
echo "  1: whole-window blur"
echo "  2: region blur (macOS and supported Linux compositors)"
echo "  M: cycle material (macOS)"
echo "  B: use ordinary blur"
echo "  C: clear backdrop"
echo "  ESC: quit"
echo fmt"[backdrop-blur-demo] capabilities={window.visualCapabilities}"

if window.supports(wvcBackdropBlur):
  window.applyBackdrop(state)
else:
  echo "[backdrop-blur-demo] backdrop blur is not supported by this window"

window.run(
  WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      if e.window.backdrop.kind != wbkNone:
        e.window.applyBackdrop(state)
      e.window.redraw()
    ,
    onRender: proc(e: RenderEvent) =
      let pixelBuffer = e.window.pixelBuffer
      state.drawFrame(pixelBuffer.size)
      copyMem(
        pixelBuffer.data,
        state.rgbaBuffer[0].addr,
        pixelBuffer.size.x * pixelBuffer.size.y * Color32bit.sizeof,
      )
      convertPixelsInplace(
        pixelBuffer.data,
        pixelBuffer.size,
        PixelBufferFormat.rgba_32bit,
        pixelBuffer.format,
      )
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
        e.window.redraw()
      of Key.n2:
        if e.window.supports(wvcBackdropBlurRegion):
          state.mode = regions
          e.window.applyBackdrop(state)
          e.window.redraw()
        else:
          echo "[backdrop-blur-demo] region blur is unavailable"
      of Key.m:
        if e.window.supports(wvcBackdropMaterial):
          state.useMaterial = true
          state.material = state.material.nextMaterial()
          e.window.applyBackdrop(state)
        else:
          echo "[backdrop-blur-demo] backdrop materials are unavailable"
      of Key.b:
        state.useMaterial = false
        e.window.applyBackdrop(state)
      of Key.c:
        e.window.clearBackdrop()
        echo "[backdrop-blur-demo] backdrop cleared"
      else:
        discard
  )
)
