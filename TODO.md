# TODO

## DPI / Coordinate Consistency
- [x] Cocoa: convert mouse move/click coordinates from points to backing pixels and expose `window.uiScale`.
- [ ] Winapi: apply per-window DPI scaling to mouse move/click coordinates so `MouseMoveEvent`/`ClickEvent` stay in physical pixel space (`window.size`/pixel buffer space).
- [ ] Wayland: apply surface/output scale (including fractional scale support when available) to mouse move/click coordinates so input coordinates match physical pixel size.
- [ ] X11: define and implement DPI-scaling policy for mouse move/click coordinates (for example using `Xft.dpi`) so coordinates are consistent with the physical-pixel model.

## Wayland
- [ ] Use current xkb state for key mapping so `KeyEvent` respects active layout/group, not only unmodified symbols.
- [ ] Improve scroll handling by consuming `axis_source`, `axis_discrete`, and `axis_value120` events instead of relying on a fixed divisor.
- [ ] Revisit scroll normalization to avoid hardcoded `kde_default_mousewheel_scroll_length = 15`.
- [ ] Add Wayland text-input protocol support (`zwp_text_input_v3`) for robust IME behavior.
- [ ] Expose IME preedit/composition updates (composition string, cursor/candidate position) to app callbacks.

## X11
- [ ] Improve wheel handling beyond fixed button 4/5/6/7 `-1/+1` deltas.
- [ ] Investigate support for user scroll preferences (direction/speed) where available.
- [ ] Improve XIM text-input path to handle multi-stage IME composition updates more explicitly.

## Cocoa (macOS)
- [x] Implement missing core window methods on Cocoa: `close`, `size=`, `pos=`, `fullscreen=`, `maximized=`, `minimized=`, `resizable=`, `minSize=`, `maxSize=`, `vsync=`, `icon=`.
- [x] Fix selector typo for `otherMouseUp:` so extra mouse button release events are dispatched correctly.
- [x] Implement real screen handling on Cocoa (`screenCount`, `screen`, `defaultScreen`, `width`, `height`) and remove Winapi naming leftovers.
- [x] Keep Cocoa window state fields in sync with setters/getters (for example `m_visible` in `visible=`).
- [x] Remove closed windows from the global Cocoa window registry to avoid stale entries/leaks.
- [x] On focus loss, release all pressed keys/buttons and emit generated release events to prevent stuck input state.
- [x] Rework Cocoa event loop mode handling (default vs tracking/live-resize) and remove fixed `sleep 1` polling.
- [x] Handle key repeat correctly (`KeyEvent.repeated`) instead of always emitting non-repeated events.
- [x] Implement Cocoa clipboard and drag-and-drop backends beyond text-only stubs.
- [ ] Implement custom image cursor support on Cocoa.
- [x] Replace deprecated activation calls (`activateIgnoringOtherApps`) with the current AppKit approach.
- [x] Revisit `WindowCocoaMetal` implementation so it uses a true Metal-backed view/path instead of `NSOpenGLView`.
- [ ] Add macOS branches in top-level window/screen wrappers where missing (for example `screenCount`/`screen`/`defaultScreen` in `src/siwin/window.nim`).

## IME / Text Input
- [ ] Add a cross-platform API for enabling/disabling text input mode (similar to `runeInputEnabled` semantics).
- [ ] Define consistent text input callbacks for commit text vs preedit text across backends.
