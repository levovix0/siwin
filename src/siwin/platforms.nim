
type
  Platform* = enum
    x11
    # wayland
    winapi

const defaultPreferedPlatform* =
  when defined(windows): Platform.winapi
  else: Platform.x11
