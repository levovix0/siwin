when defined(macosx):
  import std/[assertions, times]

  import pkg/vmath

  import siwin

  proc wakeFromWorker(waker: EventLoopWaker) {.thread.} =
    waker.wake()

  let globals = newSiwinGlobals(Platform.cocoa)

  block poll_is_nonblocking:
    discard globals.pollEvents()

  block zero_timeout_reports_timeout:
    discard globals.pollEvents()
    doAssert globals.waitEvents(initDuration()) == eventTimeout

  block queued_wake_returns_activity:
    let waker = globals.eventLoopWaker()
    waker.wake()
    doAssert globals.waitEvents(initDuration(milliseconds = 50)) == eventActivity

  block repeated_wakes_are_coalesced:
    let waker = globals.eventLoopWaker()
    waker.wake()
    waker.wake()
    doAssert globals.waitEvents(initDuration(milliseconds = 50)) == eventActivity

  block copied_waker_can_wake_from_a_worker:
    var worker: Thread[EventLoopWaker]
    createThread(worker, wakeFromWorker, globals.eventLoopWaker())
    doAssert globals.waitEvents(initDuration(milliseconds = 50)) == eventActivity
    joinThread(worker)

  block copied_waker_is_harmless_after_shutdown:
    var temporaryGlobals = newSiwinGlobals(Platform.cocoa)
    let survivingWaker = temporaryGlobals.eventLoopWaker()
    temporaryGlobals = nil
    GC_fullCollect()
    survivingWaker.wake()

  block service_window_is_nonblocking:
    var ticks, renders: int
    let window = globals.newSoftwareRenderingWindow(
      size = ivec2(32, 32),
      title = "Siwin event loop test",
    )
    defer:
      if window.opened:
        window.close()

    window.eventsHandler = WindowEventsHandler(
      onTick: proc(event: TickEvent) =
        discard event
        inc ticks
      ,
      onRender: proc(event: RenderEvent) =
        discard event
        inc renders
      ,
    )
    window.firstStep(makeVisible = false)
    window.redraw()
    window.serviceWindow()

    doAssert ticks == 1
    doAssert renders == 1

    ticks = 0
    renders = 0
    window.redraw()
    window.step()

    doAssert ticks == 1
    doAssert renders == 1
