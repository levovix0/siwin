import std/[os, strutils, unicode, times]
import pixie
import siwin

const PasteMaxChars = 64

when defined(macosx):
  const CopyPasteHint = "Cmd+C/Cmd+V"
else:
  const CopyPasteHint = "Ctrl+C/Ctrl+V"

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
    modifiers: set[ModifierKey]
    mousePos: Vec2
    mouseInside: bool
    lastClickPos: Vec2
    hasLastClickPos: bool

proc removeLastRune(s: var string) =
  if s.len == 0:
    return

  var i = s.high
  while i > 0 and (s[i].uint8 and 0b1100_0000'u8) == 0b1000_0000'u8:
    dec i
  s.setLen(i)

proc truncateRunes(s: string, maxRunes: int): string =
  if maxRunes <= 0:
    return ""

  var count = 0
  for r in s.runes:
    if count >= maxRunes:
      result.add "..."
      return
    result.add $r
    inc count

proc takeFirstRunes(s: string, maxRunes: int): string =
  if maxRunes <= 0:
    return ""

  var count = 0
  for r in s.runes:
    if count >= maxRunes:
      return
    result.add $r
    inc count

proc hasCtrlMod(modifiers: set[ModifierKey]): bool =
  ModifierKey.control in modifiers

proc hasAltMod(modifiers: set[ModifierKey]): bool =
  ModifierKey.alt in modifiers

proc hasGuiMod(modifiers: set[ModifierKey]): bool =
  ModifierKey.system in modifiers

proc hasShiftMod(modifiers: set[ModifierKey]): bool =
  ModifierKey.shift in modifiers

proc formatSignedSpeed(v: float32): string =
  if v > 0.05:
    return "+" & formatFloat(v, ffDecimal, 1)
  if v < -0.05:
    return "-" & formatFloat(-v, ffDecimal, 1)
  "0.0"

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
  pressed.join(" + ")

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

when defined(macosx):
  proc isCopyShortcut(key: Key, modifiers: set[ModifierKey]): bool =
    key == Key.c and hasGuiMod(modifiers)

  proc isPasteShortcut(key: Key, modifiers: set[ModifierKey]): bool =
    key == Key.v and hasGuiMod(modifiers)
else:
  proc isCopyShortcut(key: Key, modifiers: set[ModifierKey]): bool =
    key == Key.c and hasCtrlMod(modifiers)

  proc isPasteShortcut(key: Key, modifiers: set[ModifierKey]): bool =
    key == Key.v and hasCtrlMod(modifiers)

proc isModifierKey(key: Key): bool =
  key in [Key.lcontrol, Key.rcontrol, Key.lalt, Key.ralt, Key.lsystem, Key.rsystem, Key.lshift, Key.rshift]

proc keyLabel(key: Key): string =
  case key
  of Key.up:
    return "↑"
  of Key.down:
    return "↓"
  of Key.left:
    return "←"
  of Key.right:
    return "→"
  else:
    discard

  let name = $key
  if name.len == 1:
    return name.toUpperAscii()
  if name.len == 2 and name[0] == 'n' and name[1] in {'0'..'9'}:
    return $name[1]
  name

proc arrowToken(key: Key): string =
  case key
  of Key.up:
    "↑"
  of Key.down:
    "↓"
  of Key.left:
    "←"
  of Key.right:
    "→"
  else:
    ""

proc shortcutToken(key: Key, modifiers: set[ModifierKey]): string =
  let
    ctrl = hasCtrlMod(modifiers)
    alt = hasAltMod(modifiers)
    gui = hasGuiMod(modifiers)
    shift = hasShiftMod(modifiers)
  if not (ctrl or alt or gui):
    return ""
  if isModifierKey(key):
    return ""

  var parts: seq[string]
  if ctrl:
    parts.add("Ctrl")
  if alt:
    parts.add("Alt")
  if gui:
    parts.add(if defined(macosx): "Cmd" else: "Meta")
  if shift:
    parts.add("Shift")
  parts.add(keyLabel(key))
  "<" & parts.join("+") & ">"

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
  state.image.fill(rgba(245, 248, 252, 255))

  let ctx = state.image.newContext
  ctx.fillStyle = rgba(26, 34, 47, 255)
  ctx.fillRect(16, 16, state.image.width.float32 - 32, state.image.height.float32 - 32)
  ctx.fillStyle = rgba(252, 253, 255, 255)
  ctx.fillRect(28, 28, state.image.width.float32 - 56, state.image.height.float32 - 56)

  if state.fontPath.len != 0:
    ctx.font = state.fontPath
    ctx.fillStyle = rgba(31, 43, 59, 255)

    ctx.fontSize = 18
    ctx.fillText("Type here. Enter submits, Backspace deletes, Esc closes.", 40, 58)
    ctx.fillText(CopyPasteHint & " copy/paste. Modifier shortcuts and arrow keys are inserted as text.", 40, 84)
    ctx.fillText(
      "Scroll speed (steps/s): X:" & formatSignedSpeed(state.scrollSpeedX) &
      "  Y:" & formatSignedSpeed(state.scrollSpeedY),
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
    ctx.fillStyle = rgba(77, 129, 240, 255)
    ctx.fillRect(40, 90, width, 24)

proc present(state: var TextInputDemoState, window: Window) =
  state.drawUi()
  let pixelBuffer = window.pixelBuffer
  if pixelBuffer.data == nil:
    return

  let bytes = pixelBuffer.size.x * pixelBuffer.size.y * Color32bit.sizeof
  copyMem(pixelBuffer.data, state.image.data[0].addr, bytes)
  convertPixelsInplace(pixelBuffer.data, pixelBuffer.size, PixelBufferFormat.rgbx_32bit, pixelBuffer.format)

proc main() =
  let globals = newSiwinGlobals(
    preferedPlatform = (when defined(linux): x11 else: defaultPreferedPlatform())
  )
  let window = globals.newSoftwareRenderingWindow(
    size = ivec2(960, 540),
    title = "siwin text input demo"
  )

  var demo = TextInputDemoState(
    fontPath: pickFontPath(),
    uiScale: window.uiScale,
    cursorVisible: true,
  )
  if demo.fontPath.len == 0:
    echo "No system font found. Set SIWIN_TEXT_INPUT_FONT=/path/to/font.ttf to draw text in the window."

  updateWindowTitle(window, demo.currentText)

  run window, WindowEventsHandler(
    onResize: proc(e: ResizeEvent) =
      demo.ensureImage(e.size.x, e.size.y)
      demo.uiScale = e.window.uiScale
      redraw e.window
    ,
    onRender: proc(e: RenderEvent) =
      demo.ensureImage(e.window.size.x, e.window.size.y)
      demo.uiScale = e.window.uiScale
      demo.present(e.window)
    ,
    onTextInput: proc(e: TextInputEvent) =
      for r in e.text.runes:
        if r.int >= 32:
          demo.currentText.add $r
      updateWindowTitle(e.window, demo.currentText)
      redraw e.window
    ,
    onScroll: proc(e: ScrollEvent) =
      demo.scrollSpeedX = e.deltaX.float32 * 60'f32
      demo.scrollSpeedY = e.delta.float32 * 60'f32
      redraw e.window
    ,
    onMouseMove: proc(e: MouseMoveEvent) =
      demo.mousePos = e.pos
      demo.mouseInside = e.kind != MouseMoveKind.leave
      redraw e.window
    ,
    onClick: proc(e: ClickEvent) =
      demo.lastClickPos = e.pos
      demo.hasLastClickPos = true
      redraw e.window
    ,
    onKey: proc(e: KeyEvent) =
      demo.modifiers = e.modifiers
      if not e.pressed:
        redraw e.window
        return

      var handledKey = false
      case e.key
      of Key.escape:
        close e.window
        handledKey = true
      of Key.backspace, Key.del:
        demo.currentText.removeLastRune()
        updateWindowTitle(e.window, demo.currentText)
        handledKey = true
      of Key.c, Key.v:
        if isCopyShortcut(e.key, e.modifiers):
          handledKey = true
          if not e.repeated and not e.generated:
            e.window.clipboard.text = demo.currentText
        elif isPasteShortcut(e.key, e.modifiers):
          handledKey = true
          if not e.repeated and not e.generated:
            let clipped = takeFirstRunes(e.window.clipboard.text, PasteMaxChars)
            for r in clipped.runes:
              if r.int >= 32:
                demo.currentText.add $r
            updateWindowTitle(e.window, demo.currentText)
      of Key.enter:
        demo.submitted.add(demo.currentText)
        echo "submitted: ", demo.currentText
        demo.currentText.setLen(0)
        updateWindowTitle(e.window, demo.currentText)
        handledKey = true
      else:
        discard

      if not handledKey and not e.repeated and not e.generated:
        var token = arrowToken(e.key)
        if token.len == 0:
          token = shortcutToken(e.key, e.modifiers)
        if token.len > 0:
          if demo.currentText.len > 0:
            demo.currentText.add(" ")
          demo.currentText.add(token)
          updateWindowTitle(e.window, demo.currentText)

      redraw e.window
    ,
    onTick: proc(e: TickEvent) =
      demo.uiScale = e.window.uiScale
      var dtMs = e.deltaTime.inMilliseconds.float32
      if dtMs <= 0:
        dtMs = 16

      let decay = max(0'f32, 1'f32 - (dtMs / 1000'f32) * 8'f32)
      demo.scrollSpeedX *= decay
      demo.scrollSpeedY *= decay
      if abs(demo.scrollSpeedX) < 0.05:
        demo.scrollSpeedX = 0
      if abs(demo.scrollSpeedY) < 0.05:
        demo.scrollSpeedY = 0

      demo.cursorElapsedMs += dtMs
      if demo.cursorElapsedMs >= 500:
        demo.cursorElapsedMs = 0
        demo.cursorVisible = not demo.cursorVisible

      redraw e.window
  )

main()
