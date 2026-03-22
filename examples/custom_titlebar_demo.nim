import std/[strformat]

import vmath
import siwin

const
  WindowSize = ivec2(1040, 680)
  TitleBarHeight = 54'i32
  TitleBarPaddingX = 16'i32
  LeadingChromeOffsetX = 44'i32
  MacNativeControlsReserve = 96'i32
  TabsGapAfterControls = 24'i32
  TabHeight = 44'i32
  TabWidth = 190'i32
  TabGap = 10'i32
  ResizeBorderWidth = 8'f32
  ResizeCornerWidth = 18'f32

when not defined(macosx):
  const
    TitleButtonSize = 12'i32
    TitleButtonGap = 8'i32

type
  DemoState = object
    rgbaBuffer: seq[Color32bit]
    activeTab: int
    hoverTab: int
    supportsCustomTitlebar: bool
    customTitlebarEnabled: bool

  RectI = tuple[x, y, w, h: int32]

proc rgba(r, g, b: byte, a: byte = 255): Color32bit =
  [r, g, b, a]

proc ensureBuffer(rgbaBuffer: var seq[Color32bit], size: IVec2) =
  let pixelCount = max(1, (size.x * size.y).int)
  if rgbaBuffer.len != pixelCount:
    rgbaBuffer.setLen(pixelCount)

proc fill(rgbaBuffer: var seq[Color32bit], size: IVec2, color: Color32bit) =
  for i in 0 ..< size.x * size.y:
    rgbaBuffer[i] = color

proc fillRect(
    rgbaBuffer: var seq[Color32bit], size: IVec2, x, y, w, h: int32, color: Color32bit
) =
  let
    x0 = max(0, x)
    y0 = max(0, y)
    x1 = min(size.x, x + w)
    y1 = min(size.y, y + h)
  if x0 >= x1 or y0 >= y1:
    return

  for py in y0 ..< y1:
    let row = py * size.x
    for px in x0 ..< x1:
      rgbaBuffer[row + px] = color

proc inRect(pos: Vec2, r: RectI): bool =
  pos.x >= r.x.float32 and pos.x < (r.x + r.w).float32 and pos.y >= r.y.float32 and
    pos.y < (r.y + r.h).float32

proc tabRect(idx: int): RectI =
  let chromeStartX = TitleBarPaddingX + LeadingChromeOffsetX
  let controlsRight =
    when defined(macosx):
      # Reserve space for native traffic-light controls.
      chromeStartX + MacNativeControlsReserve
    else:
      chromeStartX + (3 * TitleButtonSize) + (2 * TitleButtonGap)
  let tabsStartX = controlsRight + TabsGapAfterControls
  let x = tabsStartX + idx.int32 * (TabWidth + TabGap)
  (x: x, y: 6, w: TabWidth, h: TabHeight)

proc tabAtPos(pos: Vec2): int =
  for idx in 0 .. 2:
    if inRect(pos, tabRect(idx)):
      return idx
  -1

proc applyDragResizeRegions(window: Window) =
  let size = window.size
  window.setTitleRegion(vec2(0, 0), vec2(size.x.float32, TitleBarHeight.float32))
  window.setBorderWidth(ResizeBorderWidth, 0, ResizeCornerWidth)

proc applyCustomTitlebar(window: Window, state: var DemoState) =
  window.customTitlebar = state.customTitlebarEnabled
  applyDragResizeRegions(window)
  window.redraw()
  echo fmt"[custom-titlebar-demo] enabled={state.customTitlebarEnabled} supported={state.supportsCustomTitlebar}"

proc drawTopChrome(state: DemoState, size: IVec2, rgbaBuffer: var seq[Color32bit]) =
  rgbaBuffer.fillRect(size, 0, 0, size.x, TitleBarHeight, rgba(34, 38, 44))
  rgbaBuffer.fillRect(size, 0, TitleBarHeight, size.x, 1, rgba(58, 64, 72))

  when not defined(macosx):
    # Left traffic-light placeholders for non-macOS backends.
    let chromeStartX = TitleBarPaddingX + LeadingChromeOffsetX
    for i in 0 .. 2:
      let x = chromeStartX + i.int32 * (TitleButtonSize + TitleButtonGap)
      rgbaBuffer.fillRect(
        size,
        x,
        (TitleBarHeight - TitleButtonSize) div 2,
        TitleButtonSize,
        TitleButtonSize,
        (if i == 0: rgba(214, 88, 88) elif i == 1: rgba(218, 177, 69) else: rgba(98, 188, 118)),
      )

  # Tab strip.
  for idx in 0 .. 2:
    let rect = tabRect(idx)
    let fillColor =
      if idx == state.activeTab:
        rgba(78, 123, 194)
      elif idx == state.hoverTab:
        rgba(70, 78, 90)
      else:
        rgba(52, 58, 66)
    rgbaBuffer.fillRect(size, rect.x, rect.y, rect.w, rect.h, fillColor)
    rgbaBuffer.fillRect(size, rect.x + 8, rect.y + 8, 16, 16, rgba(221, 230, 244))
    rgbaBuffer.fillRect(size, rect.x + 34, rect.y + 13, rect.w - 44, 8, rgba(199, 212, 235))

proc drawBody(state: DemoState, size: IVec2, rgbaBuffer: var seq[Color32bit]) =
  rgbaBuffer.fillRect(size, 0, TitleBarHeight + 1, size.x, size.y - (TitleBarHeight + 1), rgba(24, 27, 31))
  rgbaBuffer.fillRect(size, 26, 84, size.x - 52, size.y - 118, rgba(32, 36, 42))
  rgbaBuffer.fillRect(size, 46, 106, size.x - 92, 86, rgba(40, 46, 54))
  rgbaBuffer.fillRect(size, 46, 214, size.x - 92, 52, rgba(39, 45, 52))
  rgbaBuffer.fillRect(size, 46, 286, size.x - 92, 52, rgba(39, 45, 52))
  rgbaBuffer.fillRect(size, 46, 358, size.x - 92, 52, rgba(39, 45, 52))
  rgbaBuffer.fillRect(size, 46, 430, size.x - 92, 52, rgba(39, 45, 52))
  rgbaBuffer.fillRect(size, 46, size.y - 96, size.x - 92, 36, rgba(43, 49, 58))

  # Status indicators (since this software demo has no text renderer).
  let supportColor = if state.supportsCustomTitlebar: rgba(98, 188, 118) else: rgba(196, 82, 82)
  let enabledColor = if state.customTitlebarEnabled: rgba(88, 164, 255) else: rgba(112, 118, 126)
  rgbaBuffer.fillRect(size, 64, 124, 18, 18, supportColor)
  rgbaBuffer.fillRect(size, 64, 154, 18, 18, enabledColor)
  rgbaBuffer.fillRect(size, 92, 130, 220, 6, rgba(198, 206, 220))
  rgbaBuffer.fillRect(size, 92, 160, 320, 6, rgba(198, 206, 220))

proc drawFrame(state: var DemoState, size: IVec2) =
  state.rgbaBuffer.ensureBuffer(size)
  state.rgbaBuffer.fill(size, rgba(20, 22, 26))
  state.drawTopChrome(size, state.rgbaBuffer)
  state.drawBody(size, state.rgbaBuffer)

let globals = newSiwinGlobals()
let window = globals.newSoftwareRenderingWindow(
  size = WindowSize,
  title = "siwin custom titlebar demo",
  fullscreen = false,
  frameless = false,
  transparent = false,
)

var state = DemoState(
  activeTab: 0,
  hoverTab: -1,
  supportsCustomTitlebar: window.supportsCustomTitlebar(),
  customTitlebarEnabled: window.supportsCustomTitlebar(),
)
applyCustomTitlebar(window, state)

echo "[custom-titlebar-demo] Controls:"
echo "  C: toggle custom titlebar"
echo "  1/2/3: switch active tab"
echo "  ESC: quit"

window.run(
  WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      applyDragResizeRegions(e.window)
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
        pixelBuffer.data, pixelBuffer.size, PixelBufferFormat.rgba_32bit, pixelBuffer.format
      )
    ,
    onMouseMove: proc(e: MouseMoveEvent) =
      let tab = tabAtPos(e.pos)
      if tab != state.hoverTab:
        state.hoverTab = tab
        e.window.redraw()
    ,
    onClick: proc(e: ClickEvent) =
      if e.button != MouseButton.left:
        return
      let tab = tabAtPos(e.pos)
      if tab >= 0 and tab != state.activeTab:
        state.activeTab = tab
        e.window.redraw()
    ,
    onKey: proc(e: KeyEvent) =
      if not e.pressed or e.generated:
        return
      case e.key
      of Key.escape:
        e.window.close()
      of Key.c:
        state.customTitlebarEnabled = not state.customTitlebarEnabled
        applyCustomTitlebar(e.window, state)
      of Key.n1:
        state.activeTab = 0
        e.window.redraw()
      of Key.n2:
        state.activeTab = 1
        e.window.redraw()
      of Key.n3:
        state.activeTab = 2
        e.window.redraw()
      else:
        discard
  )
)
