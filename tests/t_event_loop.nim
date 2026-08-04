const eventLoopIntegrationSupported =
  # Add platforms here as their global event-loop backends are implemented.
  when defined(macosx) or defined(windows) or defined(linux) or defined(bsd): true
  else: false

const delayedWakeMilliseconds = 500
const serviceWindowNeedsVisibleSurface =
  when defined(linux) or defined(bsd): true
  else: false

when eventLoopIntegrationSupported:
  import std/[assertions, atomics, monotimes, os, times]

  import pkg/vmath

  import siwin

  when defined(windows):
    import siwin/platforms/winapi/winapi

    # Nim's `cpuTime` uses Microsoft's wall-clock `clock()`. Query actual
    # thread execution time so this assertion can distinguish waiting from spin.
    func fileTimeTicks(value: FileTime): uint64 =
      value.dwLowDateTime.uint64 or (value.dwHighDateTime.uint64 shl 32)

    proc threadCpuTime(): float64 =
      var creationTime, exitTime, kernelTime, userTime: FileTime
      doAssert GetThreadTimes(
        GetCurrentThread(),
        creationTime.addr,
        exitTime.addr,
        kernelTime.addr,
        userTime.addr,
      ).bool
      (kernelTime.fileTimeTicks + userTime.fileTimeTicks).float64 / 10_000_000.0
  else:
    proc threadCpuTime(): float64 = cpuTime()

  proc wakeFromWorker(waker: EventLoopWaker) {.thread.} =
    waker.wake()

  type DelayedWakeRequest = object
    waker: EventLoopWaker
    signaled: ptr Atomic[bool]

  proc wakeAfterDelay(request: DelayedWakeRequest) {.thread.} =
    sleep(delayedWakeMilliseconds)
    request.signaled[].store(true)
    request.waker.wake()

  let globals = newSiwinGlobals()

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

  block idle_wait_blocks_without_busy_spinning:
    discard globals.pollEvents()

    var signaled: Atomic[bool]
    signaled.store(false)

    var worker: Thread[DelayedWakeRequest]
    let
      wallStarted = getMonoTime()
      cpuStarted = threadCpuTime()
    createThread(
      worker,
      wakeAfterDelay,
      DelayedWakeRequest(
        waker: globals.eventLoopWaker(),
        signaled: signaled.addr,
      ),
    )

    var waitResult = eventTimeout
    while not signaled.load():
      waitResult = globals.waitEvents(initDuration(seconds = 3))
      if waitResult == eventTimeout:
        doAssert signaled.load(), "event wait timed out before the worker wake"

    joinThread(worker)
    discard globals.pollEvents()

    let
      wallSeconds = (getMonoTime() - wallStarted).inNanoseconds.float64 /
        1_000_000_000.0
      cpuSeconds = threadCpuTime() - cpuStarted

    doAssert waitResult == eventActivity,
      "the delayed worker wake should interrupt the native wait"
    doAssert wallSeconds >= delayedWakeMilliseconds.float64 / 1_000.0 * 0.8,
      "the event loop returned before the delayed wake: " & $wallSeconds & "s"
    doAssert cpuSeconds < 0.2,
      "the idle wait may be polling: " & $cpuSeconds & " CPU seconds over " &
        $wallSeconds & " wall seconds"

  block copied_waker_is_harmless_after_shutdown:
    var temporaryGlobals = newSiwinGlobals()
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
    window.firstStep(makeVisible = serviceWindowNeedsVisibleSurface)
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
