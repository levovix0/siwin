import std/[strformat]
import vmath
import siwin
import siwin/colorutils

const
  TitleBarHeight = 52'i32
  CloseButtonSize = 40'i32
  CloseButtonMargin = 12'i32
  ResizeBorderWidth = 8'f32
  ResizeCornerWidth = 18'f32

  PopupSize = ivec2(520, 420)
  ButtonSize = ivec2(220, 68)

type
  MainDemoState = object
    rgbaBuffer: seq[Color32bit]
    hoverButton: bool

  PopupDemoState = object
    rgbaBuffer: seq[Color32bit]
    hoverClose: bool

proc rgba(r, g, b: byte, a: byte = 255): Color32bit =
  [r, g, b, a]

proc insideRect(pos: Vec2, x, y, w, h: int32): bool =
  pos.x >= x.float32 and pos.x < (x + w).float32 and pos.y >= y.float32 and
    pos.y < (y + h).float32

proc ensureBuffer[T](rgbaBuffer: var seq[T], size: IVec2) =
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

proc popupButtonRect(size: IVec2): tuple[x, y, w, h: int32] =
  (
    x: max(28, (size.x - ButtonSize.x) div 2),
    y: max(32, (size.y - ButtonSize.y) div 2),
    w: ButtonSize.x,
    h: ButtonSize.y,
  )

proc closeButtonRect(size: IVec2): tuple[x, y, w, h: int32] =
  (
    x: size.x - CloseButtonSize - CloseButtonMargin,
    y: (TitleBarHeight - CloseButtonSize) div 2,
    w: CloseButtonSize,
    h: CloseButtonSize,
  )

proc sizeToString(size: IVec2): string =
  fmt"({size.x}, {size.y})"

proc posToString(pos: Vec2): string =
  fmt"({pos.x:.1f}, {pos.y:.1f})"

proc rectToString(rect: tuple[x, y, w, h: int32]): string =
  fmt"(x={rect.x}, y={rect.y}, w={rect.w}, h={rect.h})"

proc logPopupCloseButton(window: Window, reason: string) =
  let size = window.size
  let closeRect = closeButtonRect(size)
  echo fmt"[popup_demo] {reason}: popupSize={sizeToString(size)} closeButton={rectToString(closeRect)}"

proc logPopupPointer(
    kind: string,
    window: Window,
    pos: Vec2,
    button: MouseButton,
    pressed = false,
    double = false,
) =
  let closeRect = closeButtonRect(window.size)
  let insideClose =
    insideRect(pos, closeRect.x, closeRect.y, closeRect.w, closeRect.h)
  echo fmt"[popup_demo] {kind}: button={$button} pressed={pressed} double={double} pos={posToString(pos)} closeButton={rectToString(closeRect)} insideClose={insideClose}"

proc popupPlacement(size: IVec2): PopupPlacement =
  let buttonRect = popupButtonRect(size)
  PopupPlacement(
    anchorRectPos: ivec2(buttonRect.x, buttonRect.y),
    anchorRectSize: ivec2(buttonRect.w, buttonRect.h),
    size: PopupSize,
    anchor: Edge.bottomLeft,
    gravity: Edge.topLeft,
    offset: ivec2(0, 14),
    constraintAdjustment: {
      PopupConstraintAdjustment.pcaSlideX, PopupConstraintAdjustment.pcaFlipY,
      PopupConstraintAdjustment.pcaResizeY,
    },
    reactive: true,
  )

proc applyPopupDragRegions(window: Window) =
  let size = window.size
  let titleWidth = max(1'i32, size.x - CloseButtonSize - CloseButtonMargin * 2)
  window.setTitleRegion(vec2(0, 0), vec2(titleWidth.float32, TitleBarHeight.float32))
  window.setBorderWidth(ResizeBorderWidth, 0, ResizeCornerWidth)
  window.logPopupCloseButton("applyPopupDragRegions")

proc drawMainWindow(state: var MainDemoState, size: IVec2, popupOpen: bool) =
  state.rgbaBuffer.ensureBuffer(size)
  state.rgbaBuffer.fill(size, rgba(245, 247, 250))

  state.rgbaBuffer.fillRect(size, 48, 52, size.x - 96, 84, rgba(225, 231, 239))
  state.rgbaBuffer.fillRect(size, 48, 164, size.x - 96, 132, rgba(255, 255, 255))
  state.rgbaBuffer.fillRect(
    size, 48, size.y - 132, size.x - 96, 72, rgba(225, 231, 239)
  )

  let buttonRect = popupButtonRect(size)
  let buttonColor =
    if popupOpen:
      rgba(48, 103, 214)
    elif state.hoverButton:
      rgba(71, 125, 232)
    else:
      rgba(37, 88, 196)
  state.rgbaBuffer.fillRect(
    size, buttonRect.x, buttonRect.y, buttonRect.w, buttonRect.h, buttonColor
  )
  state.rgbaBuffer.fillRect(
    size,
    buttonRect.x + 6,
    buttonRect.y + 6,
    buttonRect.w - 12,
    buttonRect.h - 12,
    rgba(243, 247, 255),
  )
  state.rgbaBuffer.fillRect(
    size,
    buttonRect.x + 18,
    buttonRect.y + 18,
    buttonRect.w - 36,
    buttonRect.h - 36,
    buttonColor,
  )

proc drawCloseGlyph(
    rgbaBuffer: var seq[Color32bit], size: IVec2, rect: tuple[x, y, w, h: int32]
) =
  let glyphInset = 12
  for i in 0 ..< (rect.w - glyphInset * 2):
    let x1 = rect.x + glyphInset + i
    let y1 = rect.y + glyphInset + i
    let x2 = rect.x + rect.w - glyphInset - 1 - i
    let y2 = rect.y + glyphInset + i
    if x1 >= 0 and x1 < size.x and y1 >= 0 and y1 < size.y:
      rgbaBuffer[y1 * size.x + x1] = rgba(245, 247, 250)
    if x2 >= 0 and x2 < size.x and y2 >= 0 and y2 < size.y:
      rgbaBuffer[y2 * size.x + x2] = rgba(245, 247, 250)

proc drawPopupWindow(state: var PopupDemoState, size: IVec2) =
  state.rgbaBuffer.ensureBuffer(size)
  state.rgbaBuffer.fill(size, rgba(238, 241, 245))

  state.rgbaBuffer.fillRect(size, 0, 0, size.x, TitleBarHeight, rgba(23, 34, 46))
  state.rgbaBuffer.fillRect(
    size, 18, 82, size.x - 36, size.y - 100, rgba(255, 255, 255)
  )
  state.rgbaBuffer.fillRect(size, 42, 118, size.x - 84, 92, rgba(226, 232, 240))
  state.rgbaBuffer.fillRect(size, 42, 232, size.x - 84, 92, rgba(212, 226, 255))
  state.rgbaBuffer.fillRect(size, 42, 346, (size.x - 96) div 2, 42, rgba(255, 224, 201))
  state.rgbaBuffer.fillRect(
    size, size.x div 2 + 8, 346, (size.x - 96) div 2, 42, rgba(208, 244, 226)
  )

  let closeRect = closeButtonRect(size)
  state.rgbaBuffer.fillRect(
    size,
    closeRect.x,
    closeRect.y,
    closeRect.w,
    closeRect.h,
    (if state.hoverClose: rgba(206, 62, 68) else: rgba(153, 33, 40)),
  )
  state.rgbaBuffer.drawCloseGlyph(size, closeRect)

let globals = newSiwinGlobals()
let window =
  globals.newSoftwareRenderingWindow(size = ivec2(300, 200), title = "siwin popup demo")

var
  mainState: MainDemoState
  popupState: PopupDemoState
  popup: PopupWindow

proc popupIsOpen(): bool =
  popup != nil

proc updatePopupPlacement() =
  if popup != nil and popup.opened:
    popup.reposition(window.size.popupPlacement())

proc closePopup() =
  if popup != nil and popup.opened:
    popup.close()

proc installPopupHandlers() =
  popup.eventsHandler = WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      e.window.applyPopupDragRegions()
      redraw e.window
    ,
    onRender: proc(e: RenderEvent) =
      let pixelBuffer = e.window.pixelBuffer
      popupState.drawPopupWindow(pixelBuffer.size)
      copyMem(
        pixelBuffer.data,
        popupState.rgbaBuffer[0].addr,
        popupState.rgbaBuffer.len * sizeof(Color32bit),
      )
      convertPixelsInplace(
        pixelBuffer.data, pixelBuffer.size, PixelBufferFormat.rgba_32bit,
        pixelBuffer.format,
      ),
    onMouseMove: proc(e: MouseMoveEvent) =
      let closeRect = closeButtonRect(e.window.size)
      let newHover =
        insideRect(e.pos, closeRect.x, closeRect.y, closeRect.w, closeRect.h)
      if popupState.hoverClose != newHover:
        popupState.hoverClose = newHover
        redraw e.window
    ,
    onMouseButton: proc(e: MouseButtonEvent) =
      if e.button == MouseButton.left:
        logPopupPointer(
          "onMouseButton",
          e.window,
          e.window.mouse.pos,
          e.button,
          pressed = e.pressed,
        )
      if e.button == MouseButton.left and e.pressed:
        let closeRect = closeButtonRect(e.window.size)
        if insideRect(
          e.window.mouse.pos,
          closeRect.x,
          closeRect.y,
          closeRect.w,
          closeRect.h,
        ):
          e.window.close()
    ,
    onClick: proc(e: ClickEvent) =
      if e.button == MouseButton.left:
        logPopupPointer(
          "onClick",
          e.window,
          e.pos,
          e.button,
          double = e.double,
        )
      let closeRect = closeButtonRect(e.window.size)
      if e.button == MouseButton.left and
          insideRect(e.pos, closeRect.x, closeRect.y, closeRect.w, closeRect.h):
        e.window.close()
    ,
    onKey: proc(e: KeyEvent) =
      if e.pressed and not e.generated and e.key == Key.escape:
        e.window.close()
    ,
    onClose: proc(e: CloseEvent) =
      popup = nil
      popupState.hoverClose = false
      redraw window
    ,
  )

proc openPopup() =
  if popup != nil:
    return

  popup = globals.newPopupWindow(window, window.size.popupPlacement(), grab = true)
  popupState.hoverClose = false
  popup.applyPopupDragRegions()
  installPopupHandlers()
  popup.logPopupCloseButton("openPopup")
  popup.firstStep(makeVisible = true)
  redraw popup
  redraw window

window.eventsHandler = WindowEventsHandler(
  onResize: proc(e: ResizeEvent) =
    updatePopupPlacement()
    redraw e.window
  ,
  onWindowMove: proc(e: WindowMoveEvent) =
    updatePopupPlacement(),
  onRender: proc(e: RenderEvent) =
    let pixelBuffer = e.window.pixelBuffer
    mainState.drawMainWindow(pixelBuffer.size, popupIsOpen())
    copyMem(
      pixelBuffer.data,
      mainState.rgbaBuffer[0].addr,
      mainState.rgbaBuffer.len * sizeof(Color32bit),
    )
    convertPixelsInplace(
      pixelBuffer.data, pixelBuffer.size, PixelBufferFormat.rgba_32bit,
      pixelBuffer.format,
    ),
  onMouseMove: proc(e: MouseMoveEvent) =
    let buttonRect = popupButtonRect(e.window.size)
    let newHover =
      insideRect(e.pos, buttonRect.x, buttonRect.y, buttonRect.w, buttonRect.h)
    if mainState.hoverButton != newHover:
      mainState.hoverButton = newHover
      redraw e.window
  ,
  onClick: proc(e: ClickEvent) =
    let buttonRect = popupButtonRect(e.window.size)
    if e.button == MouseButton.left and
        insideRect(e.pos, buttonRect.x, buttonRect.y, buttonRect.w, buttonRect.h):
      if popupIsOpen():
        closePopup()
      else:
        openPopup()
  ,
  onClose: proc(e: CloseEvent) =
    closePopup(),
  onTick: proc(e: TickEvent) =
    redraw e.window
    if popup != nil and popup.opened:
      redraw popup
  ,
  onKey: proc(e: KeyEvent) =
    if e.pressed and not e.generated and e.key == Key.escape:
      if popup != nil:
        closePopup()
      else:
        close e.window
  ,
)

window.firstStep(makeVisible = true)
while window.opened or popup != nil:
  if window.opened:
    window.step()
  if popup != nil:
    popup.step()
