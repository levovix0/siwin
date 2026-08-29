import ../any/window

type
  CGEventRef = pointer
  CGEventFlags = uint64

proc CGEventCreate(source: pointer): CGEventRef {.
  importc, header: "<CoreGraphics/CoreGraphics.h>".}
proc CGEventGetFlags(event: CGEventRef): CGEventFlags {.
  importc, header: "<CoreGraphics/CoreGraphics.h>".}
proc CGEventSourceKeyState(stateId: int32, keyCode: uint16): bool {.
  importc, header: "<CoreGraphics/CoreGraphics.h>".}
proc CFRelease(cf: pointer) {.importc, header: "<CoreFoundation/CoreFoundation.h>".}

const
  CgCombinedSessionState = 0'i32
  CgShiftMask = 0x00020000'u64
  CgCtrlMask = 0x00040000'u64
  CgAltMask = 0x00080000'u64
  CgCmdMask = 0x00100000'u64

proc modifierStateFromCgFlags*(flags: CGEventFlags): set[ModifierKey] =
  if (flags and CgCtrlMask) != 0:
    result.incl ModifierKey.control
  if (flags and CgShiftMask) != 0:
    result.incl ModifierKey.shift
  if (flags and CgAltMask) != 0:
    result.incl ModifierKey.alt
  if (flags and CgCmdMask) != 0:
    result.incl ModifierKey.system

proc tryCurrentModifierState*(state: var set[ModifierKey]): bool =
  let ev = CGEventCreate(nil)
  if ev == nil:
    return false
  let flags = CGEventGetFlags(ev)
  CFRelease(ev)
  state = modifierStateFromCgFlags(flags)
  true

proc currentKeyPressed*(keyCode: uint16): bool =
  CGEventSourceKeyState(CgCombinedSessionState, keyCode)
