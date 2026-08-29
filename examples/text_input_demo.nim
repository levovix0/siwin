import std/[os, strutils, unicode, times]
import pixie
import siwin

type
  TextInputDemoState = object
    image: Image
    fontPath: string
    uiScale: float32
    currentText: string
    submitted: seq[string]
    cursorVisible: bool
    cursorElapsedMs: float32
    scrollSpeedX: float32
    scrollSpeedY: float32
    scrollElapsedMs: float32
    scrollUpdated: bool
    modifiers: set[ModifierKey]
    mousePos: Vec2
    mouseInside: bool
    lastClickPos: Vec2
    hasLastClickPos: bool


const
  CursorBlinkMilliseconds = 5_000
  PasteMaxChars = 64
  ScrollIdleMilliseconds = 150
  BgColor = parseHtmlColor("#FAFBFC")
  FgColor = parseHtmlColor("#1A1B1C")

when defined(macosx):
  const CopyPasteHint = "Cmd+C/Cmd+V"
else:
  const CopyPasteHint = "Ctrl+C/Ctrl+V"


proc removeLastRune(s: var string) =
  if s.len == 0: return
  var i = s.high
  while i > 0 and (s[i].uint8 and 0b1100_0000'u8) == 0b1000_0000'u8:
    dec i
  s.setLen(i)

proc takeFirstRunes(s: string, maxRunes: int): string =
  let runes = s.toRunes
  $runes[0..min(runes.high, maxRunes-1)]

proc truncateRunes(s: string, maxRunes: int): string =
  result = s.takeFirstRunes(maxRunes)
  if result.len < s.len: result.add "..."


proc formatModifiers(modifiers: set[ModifierKey]): string =
  var pressed: seq[string]
  if ModifierKey.shift in modifiers:
    pressed.add("Shift")
  if ModifierKey.control in modifiers:
    pressed.add("Ctrl")
  if ModifierKey.alt in modifiers:
    pressed.add("Alt")
  if ModifierKey.system in modifiers:
    pressed.add(if defined(macosx): "Cmd" else: "Meta")
  if ModifierKey.capsLock in modifiers:
    pressed.add("CapsLock")
  if ModifierKey.numLock in modifiers:
    pressed.add("NumLock")
  if pressed.len == 0:
    return "none"
  pressed.join(", ")

proc formatMousePos(pos: Vec2, inside: bool): string =
  if not inside:
    return "<outside>"
  "x=" & formatFloat(pos.x, ffDecimal, 1) & " y=" & formatFloat(pos.y, ffDecimal, 1)

proc formatClickPos(pos: Vec2, hasPos: bool): string =
  if not hasPos:
    return "<none>"
  "x=" & formatFloat(pos.x, ffDecimal, 1) & " y=" & formatFloat(pos.y, ffDecimal, 1)

proc formatUiScale(scale: float32): string =
  formatFloat(scale, ffDecimal, 2)


proc nextAnimationWait(state: TextInputDemoState): Duration =
  let cursorWaitMs = max(1, CursorBlinkMilliseconds - state.cursorElapsedMs.int)
  let waitMs =
    if abs(state.scrollSpeedX) >= 0.05 or abs(state.scrollSpeedY) >= 0.05:
      min(cursorWaitMs, max(1, ScrollIdleMilliseconds - state.scrollElapsedMs.int))
    else:
      cursorWaitMs
  initDuration(milliseconds = waitMs)


when defined(macosx):
  proc isCopyShortcut(key: Key, modifiers: set[ModifierKey]): bool =
    key == Key.c and ModifierKey.system in modifiers

  proc isPasteShortcut(key: Key, modifiers: set[ModifierKey]): bool =
    key == Key.v and ModifierKey.system in modifiers

else:
  proc isCopyShortcut(key: Key, modifiers: set[ModifierKey]): bool =
    key == Key.c and ModifierKey.control in modifiers

  proc isPasteShortcut(key: Key, modifiers: set[ModifierKey]): bool =
    key == Key.v and ModifierKey.control in modifiers


proc formatKey(key: Key, modifiers: set[ModifierKey]): string =
  let
    ctrl = ModifierKey.control in modifiers
    alt = ModifierKey.alt in modifiers
    system = ModifierKey.system in modifiers
    shift = ModifierKey.shift in modifiers
  
  if not (ctrl or alt or system or key in {Key.up, Key.down, Key.left, Key.right}):
    return ""
  if key in {Key.lcontrol, Key.rcontrol, Key.lalt, Key.ralt, Key.lsystem, Key.rsystem, Key.lshift, Key.rshift}:
    return ""

  var parts: seq[string]
  if ctrl:   parts.add("Ctrl")
  if alt:    parts.add("Alt")
  if system: parts.add(if defined(macosx): "Cmd" else: "Meta")
  if shift:  parts.add("Shift")
  
  parts.add case key
    of Key.up:    "↑"
    of Key.down:  "↓"
    of Key.left:  "←"
    of Key.right: "→"
    else: $key

  if parts.len != 1:
    "<" & parts.join("+") & ">"
  else:
    parts[0]

proc pickFontPath(): string =
  let envPath = getEnv("SIWIN_TEXT_INPUT_FONT")
  if envPath.len != 0 and fileExists(envPath):
    return envPath

  let candidates =
    when defined(windows):
      let winDir = getEnv("WINDIR", r"C:\Windows")
      @[
        winDir / "Fonts" / "segoeui.ttf",
        winDir / "Fonts" / "arial.ttf",
      ]
    elif defined(macosx):
      @[
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial.ttf",
      ]
    else:
      @[
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/TTF/DejaVuSans.ttf",
        "/usr/share/fonts/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        "/usr/share/fonts/opentype/noto/NotoSans-Regular.ttf",
        "/usr/local/share/fonts/dejavu/DejaVuSans.ttf"
      ]

  for path in candidates:
    if fileExists(path):
      return path

proc updateWindowTitle(window: Window, currentText: string) =
  let preview =
    if currentText.len == 0:
      "<empty>"
    else:
      currentText.truncateRunes(48)
  window.title = "siwin text input: " & preview

proc ensureImage(state: var TextInputDemoState, width, height: int32) =
  let
    w = max(1, width.int)
    h = max(1, height.int)
  if state.image.isNil or state.image.width != w or state.image.height != h:
    state.image = newImage(w, h)

proc drawUi(state: var TextInputDemoState) =
  state.image.fill(BgColor)

  let ctx = state.image.newContext
  ctx.fillStyle = FgColor
  ctx.fillRect(16, 16, state.image.width.float32 - 32, state.image.height.float32 - 32)
  ctx.fillStyle = BgColor
  ctx.fillRect(28, 28, state.image.width.float32 - 56, state.image.height.float32 - 56)

  if state.fontPath.len != 0:
    ctx.font = state.fontPath
    ctx.fillStyle = FgColor

    ctx.fontSize = 18
    ctx.fillText("Type here. Enter submits, Backspace deletes, Esc closes.", 40, 58)
    ctx.fillText(CopyPasteHint & " copy/paste. Modifier shortcuts and arrow keys are inserted as text.", 40, 84)
    ctx.fillText(
      "Scroll speed (steps/s): X:" & $state.scrollSpeedX &
      "  Y:" & $state.scrollSpeedY,
      40,
      110
    )
    ctx.fillText("UI scale: " & formatUiScale(state.uiScale), 40, 136)
    ctx.fillText("Modifiers: " & formatModifiers(state.modifiers), 40, 162)
    ctx.fillText(
      "Mouse: " & formatMousePos(state.mousePos, state.mouseInside) &
      "  Click: " & formatClickPos(state.lastClickPos, state.hasLastClickPos),
      40,
      188
    )

    ctx.fontSize = 24
    let cursor = if state.cursorVisible: "|" else: ""
    ctx.fillText("Current: " & state.currentText & cursor, 40, 222)

    ctx.fontSize = 18
    ctx.fillText("Last submitted lines:", 40, 266)

    var y = 296'f32
    let start = max(0, state.submitted.len - 8)
    for i in start ..< state.submitted.len:
      ctx.fillText("- " & state.submitted[i], 52, y)
      y += 28
  else:
    let width = min(1.0'f32, state.currentText.runeLen.float32 / 40'f32) * (state.image.width.float32 - 80)
    ctx.fillStyle = FgColor
    ctx.fillRect(40, 90, width, 24)

proc present(state: var TextInputDemoState, window: Window) =
  state.drawUi()
  let pixelBuffer = window.pixelBuffer
  if pixelBuffer.data == nil:
    return

  copyMem(pixelBuffer.data, state.image.data[0].addr, pixelBuffer.size.x * pixelBuffer.size.y * Color32bit.sizeof)
  convertPixelsInplace(pixelBuffer.data, pixelBuffer.size, PixelBufferFormat.rgbx_32bit, pixelBuffer.format)


when isMainModule:
  let globals = newSiwinGlobals()
  let window = globals.newSoftwareRenderingWindow(
    size = ivec2(960, 540),
    title = "siwin text input demo",
  )

  var state = TextInputDemoState(
    fontPath: pickFontPath(),
    uiScale: window.uiScale,
    cursorVisible: true,
  )
  if state.fontPath.len == 0:
    echo "No system font found. Set SIWIN_TEXT_INPUT_FONT=/path/to/font.ttf to draw text in the window."

  updateWindowTitle(window, state.currentText)

  window.eventsHandler = WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      state.ensureImage(e.size.x, e.size.y)
      state.uiScale = e.window.uiScale
      redraw e.window
    ,
    onRender: proc(e: RenderEvent) =
      state.ensureImage(e.window.size.x, e.window.size.y)
      state.uiScale = e.window.uiScale
      state.present(e.window)
    ,
    onTextInput: proc(e: TextInputEvent) =
      for r in e.text.runes:
        if r.int >= 32:
          state.currentText.add $r
      updateWindowTitle(e.window, state.currentText)
      redraw e.window
    ,
    onScroll: proc(e: ScrollEvent) =
      state.scrollSpeedX = e.deltaX.float32
      state.scrollSpeedY = e.delta.float32
      state.scrollElapsedMs = 0
      state.scrollUpdated = true
      redraw e.window
    ,
    onMouseMove: proc(e: MouseMoveEvent) =
      state.mousePos = e.pos
      state.mouseInside = e.kind != MouseMoveKind.leave
      redraw e.window
    ,
    onClick: proc(e: ClickEvent) =
      state.lastClickPos = e.pos
      state.hasLastClickPos = true
      redraw e.window
    ,
    onKey: proc(e: KeyEvent) =
      state.modifiers = e.modifiers
      if not e.pressed:
        redraw e.window
        return

      if e.key == Key.escape:
        close e.window
      
      elif e.key in {Key.backspace, Key.del}:
        state.currentText.removeLastRune()
        updateWindowTitle(e.window, state.currentText)
      
      elif isCopyShortcut(e.key, e.modifiers):
        if not e.repeated and not e.generated:
          e.window.clipboard.text = state.currentText
      
      elif isPasteShortcut(e.key, e.modifiers):
        if not e.repeated and not e.generated:
          let clipped = takeFirstRunes(e.window.clipboard.text, PasteMaxChars)
          for r in clipped.runes:
            if r.int >= 32:
              state.currentText.add $r
          updateWindowTitle(e.window, state.currentText)
      
      elif e.key == Key.enter:
        state.submitted.add(state.currentText)
        echo "submitted: ", state.currentText
        state.currentText.setLen(0)
        updateWindowTitle(e.window, state.currentText)
      
      elif not e.repeated and not e.generated:
        let sequence = formatKey(e.key, e.modifiers)
        if sequence != "":
          if state.currentText.len > 0:
            state.currentText.add(" ")
          state.currentText.add(sequence)
          updateWindowTitle(e.window, state.currentText)

      redraw e.window
    ,
    onTick: proc(e: TickEvent) =
      state.uiScale = e.window.uiScale
      let dtMs = max(0'f32, e.deltaTime.inNanoseconds.float32 / 1_000_000'f32)

      var animationChanged = false
      if state.scrollUpdated:
        state.scrollUpdated = false
      elif abs(state.scrollSpeedX) >= 0.05 or abs(state.scrollSpeedY) >= 0.05:
        state.scrollElapsedMs += dtMs
        if state.scrollElapsedMs >= ScrollIdleMilliseconds.float32:
          state.scrollSpeedX = 0
          state.scrollSpeedY = 0
          state.scrollElapsedMs = 0
          animationChanged = true

      state.cursorElapsedMs += dtMs
      if state.cursorElapsedMs >= CursorBlinkMilliseconds.float32:
        state.cursorElapsedMs = 0
        state.cursorVisible = not state.cursorVisible
        animationChanged = true

      if animationChanged:
        redraw e.window
  )

  window.firstStep()
  window.serviceWindow()
  while window.opened:
    discard globals.waitEvents(state.nextAnimationWait())
    if window.opened:
      window.serviceWindow()

