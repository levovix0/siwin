# TODO

## DPI / Coordinate Consistency
- [x] Cocoa: convert mouse move/click coordinates from points to backing pixels and expose `window.uiScale`.
- [ ] Winapi: apply per-window DPI scaling to mouse move/click coordinates so `MouseMoveEvent`/`ClickEvent` stay in physical pixel space (`window.size`/pixel buffer space).
- [ ] Wayland: apply surface/output scale (including fractional scale support when available) to mouse move/click coordinates so input coordinates match physical pixel size.
- [ ] X11: define and implement DPI-scaling policy for mouse move/click coordinates (for example using `Xft.dpi`) so coordinates are consistent with the physical-pixel model.

## Event-Driven Application Loop

Move native event waiting out of per-window `step()` implementations so an application can block once for all windows and be awakened efficiently by native input or cross-thread work such as Sigils messages and renderer completions.

Proposed Nim API (exact names are still subject to review):

```nim
type
  EventWaitResult* = enum
    eventActivity
    eventTimeout

  EventLoopWaker* = object
    ## Opaque, copyable capability containing only the state needed to wake
    ## its owning event loop safely from another thread.

proc pollEvents*(globals: SiwinGlobals): bool
proc waitEvents*(globals: SiwinGlobals)
proc waitEvents*(globals: SiwinGlobals, timeout: Duration): EventWaitResult

proc eventLoopWaker*(globals: SiwinGlobals): EventLoopWaker
proc wake*(waker: EventLoopWaker) {.gcsafe, raises: [].}
proc wakeEventLoop*(globals: SiwinGlobals) {.gcsafe, raises: [].} =
  globals.eventLoopWaker().wake()

method serviceWindow*(window: Window)
```

- [ ] Define `pollEvents` and `waitEvents` as application-thread-only operations that synchronously dispatch pending native callbacks for every window owned by the `SiwinGlobals` instance.
- [ ] Define `EventLoopWaker` as a narrow, opaque, copyable capability so worker threads do not need to retain or access the complete `SiwinGlobals` object.
- [ ] Define `EventLoopWaker.wake` as thread-safe, data-free notification: producers must enqueue their work first and then wake the loop; wakeups may be coalesced.
- [ ] Keep `wakeEventLoop(globals)` as a convenience wrapper around `globals.eventLoopWaker().wake()` for callers already on or otherwise holding the globals owner.
- [ ] Define waker lifetime and shutdown semantics explicitly, including what happens when a copied waker outlives its `SiwinGlobals`; waking a stopped/destroyed loop must be harmless and must not access a closed OS handle.
- [ ] Document the integration pattern for Sigils and similar queues: install one waker on the application-thread destination queue, enqueue each message before calling `wake`, then drain that queue after `waitEvents` returns.
- [ ] Support animation scheduling either by having a timer/Sigils producer enqueue a tick and wake the loop, or by passing the next animation deadline to timed `waitEvents`; individual animations do not register with Siwin.
- [ ] Keep arbitrary external FD/source registration outside this initial API; enqueue-plus-wake is sufficient for Sigils, renderer completions, image loading, and animation schedulers.
- [ ] Make `serviceWindow` nonblocking and responsible only for per-window tick, redraw/render, buffer swap, and presentation work.
- [ ] Preserve the existing source and C ABI: keep no-argument `Window.step()` and `siwin_window_step` behavior available as compatibility wrappers while embedders opt into `pollEvents`/`waitEvents` plus `serviceWindow`.
- [ ] Do not add a wake callback to `WindowEventsHandler`, because wakeup is application-loop control rather than a window event and changing the handler layout could break ABI consumers.
- [ ] Add corresponding additive C ABI functions: `siwin_poll_events`, `siwin_wait_events`, `siwin_wake_event_loop`, and `siwin_window_service`; decide whether non-Nim consumers also need an independently retained opaque waker handle.
- [ ] Update `run`/`runMultiple` or add event-driven variants that wait once and then service every window, while preserving the existing observable `onTick` behavior for compatibility.
- [ ] Support an infinite idle wait, a monotonic timeout for scheduled work, and an immediate/nonblocking path when redraw or queued work remains.
- [ ] Add tests for idle blocking, timeouts, copied cross-thread wakers, waker shutdown/lifetime safety, wakeup coalescing/no lost wakes, multiple windows, redraw after wake, and existing `step()` compatibility.

### Cocoa (macOS)

- [ ] Move the application-global `NSApp` event draining out of `WindowCocoa.step`; currently each window independently pumps the same queue and waits for up to 1 ms.
- [ ] Implement `pollEvents` by draining immediately available events in default, event-tracking/live-resize, and modal-panel run-loop modes.
- [ ] Implement `waitEvents` with `nextEventMatchingMask`, using `distantFuture` for an infinite wait or a deadline for the timed overload, then drain immediately available events before returning.
- [ ] Implement `wakeEventLoop` by posting a coalesced application-defined `NSEvent`, which AppKit permits from a secondary thread.
- [ ] Recognize and consume the Siwin wake sentinel without forwarding it to a window or invoking a `WindowEventsHandler` callback; clear the coalescing flag before the application drains its work queues.
- [ ] Keep all AppKit dispatch and window callbacks on the application thread.

### X11

- [ ] Wait with `poll()`/`ppoll()` on both `ConnectionNumber(display)` and an `eventfd` or self-pipe owned by `SiwinGlobalsX11`.
- [ ] Implement `wakeEventLoop` by signaling only the wake FD; do not call Xlib from the producer thread or require `XInitThreads`.
- [ ] Add a window registry to `SiwinGlobalsX11` mapping X11 window IDs to `WindowX11` objects.
- [ ] Replace the current per-window `XCheckIfEvent` loops with global `XPending`/`XNextEvent` dispatch that routes each event through the registry while preserving key-repeat lookahead, clipboard, drag-and-drop, and sync-request behavior.
- [ ] Drain/reset the wake FD without losing a wake that races with event dispatch.
- [ ] Flush X11 output at the appropriate global/per-window boundaries without introducing a blocking `XNextEvent` call after the readiness check.

### Wayland

- [ ] Wait with `poll()`/`ppoll()` on `wl_display_get_fd()` and an `eventfd` or self-pipe owned by `SiwinGlobalsWayland`.
- [ ] Add bindings for `wl_display_prepare_read`, `wl_display_read_events`, and `wl_display_cancel_read`.
- [ ] Implement the required race-free sequence: dispatch pending events until `prepare_read` succeeds, flush, poll, call `read_events` when the display is readable or `cancel_read` when another source wakes the loop, then dispatch pending events.
- [ ] Replace the per-window `wl_display_roundtrip()` in `WindowWayland.step` with the application-global event pump; retain roundtrips only where synchronous initialization/configuration genuinely requires them.
- [ ] Continue routing callbacks through the existing `SiwinGlobalsWayland.associatedWindows` and Wayland proxy state.
- [ ] Include keyboard-repeat deadlines in the next wait timeout so held keys continue repeating without idle polling.
- [ ] Verify that libdecor dispatch and flushing are integrated with the same display wait without adding a second polling loop.

### Windows (Winapi)

- [ ] Store the application thread/event-loop state in a Winapi-specific `SiwinGlobals`, including an auto-reset Win32 event used for cross-thread wakeups.
- [ ] Implement `waitEvents` with `MsgWaitForMultipleObjectsEx`, monitoring both the wake handle and the thread message queue with `QS_ALLINPUT` and `MWMO_INPUTAVAILABLE`.
- [ ] Implement `wakeEventLoop` with `SetEvent`; signaling before the wait must remain observable and repeated signals may be coalesced.
- [ ] Move the global `PeekMessage`/`TranslateMessage`/`DispatchMessage` loop out of `WindowWinapi.step` and remove its idle `sleep(1)` path.
- [ ] Let normal Win32 dispatch continue routing messages to the correct `HWND` window procedure, while `serviceWindow` handles only per-window tick/render/presentation work.
- [ ] Map finite `Duration` values safely to the millisecond timeout accepted by `MsgWaitForMultipleObjectsEx`, including zero and infinite waits.

## Wayland
- [x] Make `KeyEvent.modifiers` reflect effective xkb modifier state (including remaps like Caps-as-Ctrl), not only raw pressed key symbols.
- [x] Fix keyboard repeat handling in `text_input_demo`/Wayland path (robust hold/repeat behavior with sane fallback repeat settings).
- [ ] Use current xkb state for key mapping so `KeyEvent` respects active layout/group, not only unmodified symbols.
- [ ] Improve scroll handling by consuming `axis_source`, `axis_discrete`, and `axis_value120` events instead of relying on a fixed divisor.
- [ ] Revisit scroll normalization to avoid hardcoded `kde_default_mousewheel_scroll_length = 15`.
- [ ] Add Wayland text-input protocol support (`zwp_text_input_v3`) for robust IME behavior.
- [ ] Expose IME preedit/composition updates (composition string, cursor/candidate position) to app callbacks.

## X11
- [x] Make `KeyEvent.modifiers` include live X11 modifier-mask state so remapped modifiers (for example Caps-as-Ctrl) are reflected correctly.
- [ ] Improve wheel handling beyond fixed button 4/5/6/7 `-1/+1` deltas.
- [ ] Investigate support for user scroll preferences (direction/speed) where available.
- [ ] Improve XIM text-input path to handle multi-stage IME composition updates more explicitly.

## Testing
- [x] Skip `tests/t_opengl.nim` and `tests/t_opengl_es.nim` when targeting macOS in Nimble test runners.

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
