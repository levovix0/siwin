import std/assertions

import siwin

block close_request_without_handler:
  var window: Window
  new window
  doAssert window.closeRequestAccepted()

block close_request_handler_decides:
  var window: Window
  new window
  var queries = 0
  window.eventsHandler.onCloseRequest = proc(e: CloseRequestEvent): bool =
    inc queries
    doAssert e.window == window
    false
  doAssert queries == 0
  doAssert not window.closeRequestAccepted()
  doAssert queries == 1
  window.eventsHandler.onCloseRequest = proc(e: CloseRequestEvent): bool =
    true
  doAssert window.closeRequestAccepted()
  doAssert queries == 1

block close_request_is_distinct_from_closed:
  var window: Window
  new window
  window.eventsHandler.onCloseRequest = proc(e: CloseRequestEvent): bool =
    false
  doAssert window.opened
  doAssert not window.closeRequestAccepted()
  doAssert window.opened, "a vetoed request must not close the window"
