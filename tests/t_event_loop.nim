import std/[assertions, times]

import siwin/platforms/any/eventLoop


const
  signedInfiniteTimeout = -1'i32
  signedMaxFiniteTimeout = int32.high


block timeout_milliseconds_round_up:
  doAssert initDuration(nanoseconds = -1).inTimeoutMilliseconds(
    signedInfiniteTimeout, signedMaxFiniteTimeout,
  ) == 0
  doAssert initDuration().inTimeoutMilliseconds(
    signedInfiniteTimeout, signedMaxFiniteTimeout,
  ) == 0
  doAssert initDuration(nanoseconds = 1).inTimeoutMilliseconds(
    signedInfiniteTimeout, signedMaxFiniteTimeout,
  ) == 1
  doAssert initDuration(milliseconds = 1).inTimeoutMilliseconds(
    signedInfiniteTimeout, signedMaxFiniteTimeout,
  ) == 1
  doAssert initDuration(
    milliseconds = 1,
    nanoseconds = 1,
  ).inTimeoutMilliseconds(signedInfiniteTimeout, signedMaxFiniteTimeout) == 2

block timeout_milliseconds_handle_native_bounds:
  doAssert Duration.high.inTimeoutMilliseconds(
    signedInfiniteTimeout, signedMaxFiniteTimeout,
  ) == signedInfiniteTimeout
  doAssert initDuration(seconds = int64.high - 1).inTimeoutMilliseconds(
    signedInfiniteTimeout,
    signedMaxFiniteTimeout,
  ) == signedMaxFiniteTimeout
  doAssert Duration.high.inTimeoutMilliseconds(uint32.high, uint32.high - 1) ==
    uint32.high


const eventLoopIntegrationSupported =
  # Add platforms here as their global event-loop backends are implemented.
  when defined(macosx) or defined(windows) or defined(linux) or defined(bsd): true
  else: false

const delayedWakeMilliseconds = 500
const shortWakeMilliseconds = 100
const wakeRaceIterations = 200
const serviceWindowNeedsVisibleSurface =
  when defined(linux) or defined(bsd): true
  else: false

when eventLoopIntegrationSupported:
  import std/[atomics, monotimes, os]

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
    delayMilliseconds: int

  proc wakeAfterDelay(request: DelayedWakeRequest) {.thread.} =
    sleep(request.delayMilliseconds)
    request.signaled[].store(true)
    request.waker.wake()

  type WakeRaceRequest = object
    waker: EventLoopWaker
    produced: ptr Atomic[int]
    consumed: ptr Atomic[int]

  proc produceWakeRace(request: WakeRaceRequest) {.thread.} =
    for sequence in 1..wakeRaceIterations:
      while request.consumed[].load() != sequence - 1:
        sleep(0)
      request.produced[].store(sequence)
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

  block finite_wait_uses_a_monotonic_deadline:
    discard globals.pollEvents()
    let
      started = getMonoTime()
      target = initDuration(milliseconds = 100)

    while true:
      let remaining = target - (getMonoTime() - started)
      let result = globals.waitEvents(
        if remaining.inNanoseconds > 0: remaining else: initDuration()
      )
      if result == eventTimeout:
        break

    let elapsed = getMonoTime() - started
    doAssert elapsed >= initDuration(milliseconds = 80),
      "the finite event wait returned before its monotonic deadline"
    doAssert elapsed < initDuration(seconds = 2),
      "the finite event wait did not return near its deadline"

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
        delayMilliseconds: delayedWakeMilliseconds,
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

  block repeated_queue_before_wake_races_lose_no_wakeups:
    discard globals.pollEvents()

    var produced, consumed: Atomic[int]
    produced.store(0)
    consumed.store(0)

    var worker: Thread[WakeRaceRequest]
    let raceWaker = globals.eventLoopWaker()
    createThread(
      worker,
      produceWakeRace,
      WakeRaceRequest(
        waker: raceWaker,
        produced: produced.addr,
        consumed: consumed.addr,
      ),
    )

    while consumed.load() < wakeRaceIterations:
      while produced.load() <= consumed.load():
        doAssert globals.waitEvents(initDuration(seconds = 2)) == eventActivity,
          "an enqueued producer wake was lost (produced=" & $produced.load() &
            ", consumed=" & $consumed.load() & ")"

      # This atomic counter stands in for draining an application queue. The
      # producer publishes it before waking and waits for the drain before the
      # next iteration, repeatedly exercising the wait boundary race.
      consumed.store(produced.load())

    joinThread(worker)

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

    block worker_wake_schedules_redraw:
      ticks = 0
      renders = 0

      var redrawQueued: Atomic[bool]
      redrawQueued.store(false)
      var worker: Thread[DelayedWakeRequest]
      createThread(
        worker,
        wakeAfterDelay,
        DelayedWakeRequest(
          waker: globals.eventLoopWaker(),
          signaled: redrawQueued.addr,
          delayMilliseconds: shortWakeMilliseconds,
        ),
      )

      while not redrawQueued.load():
        doAssert globals.waitEvents(initDuration(seconds = 2)) == eventActivity,
          "the redraw request did not wake the application loop"

      # Drain the simulated destination queue before servicing the window.
      redrawQueued.store(false)
      window.redraw()
      window.serviceWindow()
      joinThread(worker)

      doAssert ticks == 1
      doAssert renders == 1

    ticks = 0
    renders = 0
    window.redraw()
    window.step()

    doAssert ticks == 1
    doAssert renders == 1

  block event_driven_runner_services_every_window_after_one_wait:
    var wakeQueued: Atomic[bool]
    wakeQueued.store(false)
    var worker: Thread[DelayedWakeRequest]
    createThread(
      worker,
      wakeAfterDelay,
      DelayedWakeRequest(
        waker: globals.eventLoopWaker(),
        signaled: wakeQueued.addr,
        delayMilliseconds: shortWakeMilliseconds,
      ),
    )

    var ticks = [0, 0]
    var rendersAfterWake = [0, 0]
    let
      firstWindow = globals.newSoftwareRenderingWindow(
        size = ivec2(32, 32),
        title = "Siwin event loop multi-window test 1",
      )
      secondWindow = globals.newSoftwareRenderingWindow(
        size = ivec2(32, 32),
        title = "Siwin event loop multi-window test 2",
      )

    proc handler(index: int): WindowEventsHandler =
      WindowEventsHandler(
        onTick: proc(event: TickEvent) =
          inc ticks[index]
          if wakeQueued.load():
            event.window.redraw()
        ,
        onRender: proc(event: RenderEvent) =
          if wakeQueued.load():
            inc rendersAfterWake[index]
            event.window.close()
        ,
      )

    globals.runMultipleEventDriven(
      (
        window: firstWindow,
        eventsHandler: handler(0),
        makeVisible: serviceWindowNeedsVisibleSurface,
      ),
      (
        window: secondWindow,
        eventsHandler: handler(1),
        makeVisible: serviceWindowNeedsVisibleSurface,
      ),
    )
    joinThread(worker)

    doAssert ticks[0] >= 2
    doAssert ticks[1] >= 2
    doAssert rendersAfterWake == [1, 1]
