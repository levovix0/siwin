import std/times

func inTimeoutMilliseconds*[T: SomeInteger](
    timeout: Duration, infinite, maxFinite: T
): T =
  ## Converts `timeout` to a native whole-millisecond timeout.
  ##
  ## Infinite waits map to `infinite`, nonpositive waits map to zero, positive
  ## fractional milliseconds round up to avoid early timeouts, and oversized
  ## finite waits clamp to `maxFinite`.
  if timeout == Duration.high:
    return infinite
  if timeout <= DurationZero:
    return 0
  if timeout >= initDuration(milliseconds = maxFinite.int64):
    return maxFinite

  let nanoseconds = timeout.inNanoseconds
  result = T(nanoseconds div 1_000_000'i64 + int64(nanoseconds mod 1_000_000'i64 != 0))
