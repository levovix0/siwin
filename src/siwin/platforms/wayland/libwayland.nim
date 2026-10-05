import std/[dynlib]
import ../../[siwindefs]

type
  Wl_display* = object
    raw*: pointer

  Wl_object* = object
    iface*: ptr Wl_interface
    impl*: pointer
    id*: uint32

  Wl_proxy* = object
    ## note: Wl_proxy here is like wl_proxy* in c
    ## wrapping pointer to an object is needed to attach destructor
    raw*: ptr Wl_object
  
  Wl_interface* = object
    name*: cstring
    version*: int32
    methodsLen*: int32
    methods*: ptr UncheckedArray[WlMessage]
    eventsLen*: int32
    events*: ptr UncheckedArray[WlMessage]

  Layer* {.pure.} = enum
    Background = 0
    Bottom = 1
    Top = 2
    Overlay = 3

  LayerInteractivityMode* {.pure.} = enum
    None
    Exclusive
    OnDemand

  LayerEdge* {.pure.} = enum
    Top = 1
    Bottom = 2
    Left = 4
    Right = 8

  WlMessage* = object
    name*: cstring
    signature*: cstring
      ## Symbols:
      ## * `i`: int
      ## * `u`: uint
      ## * `f`: fixed
      ## * `s`: string
      ## * `o`: object
      ## * `n`: new_id
      ## * `a`: array
      ## * `h`: fd
      ## * `?`: following argument (`o` or `s`) is nullable
    types*: ptr UncheckedArray[ptr Wl_interface]
  
  WaylandProtocolError* = object of CatchableError

  RoundtripFailed* = object of WaylandProtocolError

  Wl_dispatcher_proc* = proc(
      impl: pointer, obj: pointer, opcode: uint32, msg: ptr WlMessage, args: pointer
    ): int32 {.cdecl.}
  
  Wl_array* = ptr object
    size*: int
    alloc*: int
    data*: pointer
  
  WlProxyTyped* = concept x
    x.proxy is Wl_proxy
  
  Wl_argument* = int


let
  proxyNimTag: cstring = "nim-side proxy (userdata is ref RootObj and it requires destruction)"

var
  libwaylandclientHandle = loadLib("libwayland-client.so")

if libwaylandclientHandle == nil:
  libwaylandclientHandle = loadLib("libwayland-client.so.0")


siwin_loadDynlibIfExists libwaylandclientHandle:
  proc wl_display_disconnect_c(this: pointer) {.importc: "wl_display_disconnect".}
  proc wl_display_connect_c(name: cstring): pointer {.importc: "wl_display_connect".}
  proc wl_display_connect_to_fd_c(fd: FileHandle): pointer {.importc: "wl_display_connect_to_fd".}
  proc wl_display_get_fd_c(this: pointer): FileHandle {.importc: "wl_display_get_fd".}
  proc wl_display_flush_c(this: pointer): int32 {.importc: "wl_display_flush".}
  proc wl_display_prepare_read_c(this: pointer): int32 {.importc: "wl_display_prepare_read".}
  proc wl_display_read_events_c(this: pointer): int32 {.importc: "wl_display_read_events".}
  proc wl_display_cancel_read_c(this: pointer) {.importc: "wl_display_cancel_read".}
  proc wl_display_roundtrip_c(this: pointer): int32 {.importc: "wl_display_roundtrip".}
  proc wl_proxy_set_user_data_c(this: pointer, v: pointer) {.importc: "wl_proxy_set_user_data".}
  proc wl_proxy_get_user_data_c(this: pointer): pointer {.importc: "wl_proxy_get_user_data".}
  proc wl_proxy_set_tag_c(this: pointer, v: ptr cstring) {.importc: "wl_proxy_set_tag".}
  proc wl_proxy_get_tag_c(this: pointer): ptr cstring {.importc: "wl_proxy_get_tag".}
  proc wl_proxy_destroy_c(this: pointer) {.importc: "wl_proxy_destroy".}
  proc wl_proxy_get_version_c(this: pointer): uint32 {.importc: "wl_proxy_get_version".}
  proc wl_proxy_get_id_c(this: pointer): uint32 {.importc: "wl_proxy_get_id".}
  proc wl_proxy_marshal_array_flags*(
    proxy: pointer, opcode: uint32, iface: ptr Wl_interface, version: uint32, flags: uint32, args: pointer
  ): pointer
  proc wl_proxy_marshal_flags*(
    proxy: pointer, opcode: uint32, iface: ptr Wl_interface, version: uint32, flags: uint32
  ): pointer {.varargs.}
  proc wl_display_dispatch_pending_c(this: pointer): int32 {.importc: "wl_display_dispatch_pending".}
  proc wl_proxy_add_dispatcher_c(
    proxy: pointer, callback: Wl_dispatcher_proc, impl: pointer, proxyUserdata: pointer
  ): int32 {.importc: "wl_proxy_add_dispatcher".}

proc wl_display_disconnect*(this: Wl_display) {.cdecl.} =
  if this.raw != nil and wl_display_disconnect_c != nil:
    wl_display_disconnect_c(this.raw)

var wl_display_connect* =
  if wl_display_connect_c == nil: nil
  else:
    proc(name: cstring): Wl_display {.cdecl.} =
      if wl_display_connect_c != nil:
        result.raw = wl_display_connect_c(name)

var wl_display_connect_to_fd* =
  if wl_display_connect_to_fd_c == nil: nil
  else:
    proc(fd: FileHandle): Wl_display {.cdecl.} =
      if wl_display_connect_to_fd_c != nil:
        result.raw = wl_display_connect_to_fd_c(fd)

var wl_display_get_fd* =
  if wl_display_get_fd_c == nil: nil
  else:
    proc(this: Wl_display): FileHandle {.cdecl.} =
      wl_display_get_fd_c(this.raw)

var wl_display_flush* =
  if wl_display_flush_c == nil: nil
  else:
    proc(this: Wl_display): int32 {.cdecl.} =
      wl_display_flush_c(this.raw)

var wl_display_prepare_read* =
  if wl_display_prepare_read_c == nil: nil
  else:
    proc(this: Wl_display): int32 {.cdecl.} =
      wl_display_prepare_read_c(this.raw)

var wl_display_read_events* =
  if wl_display_read_events_c == nil: nil
  else:
    proc(this: Wl_display): int32 {.cdecl.} =
      wl_display_read_events_c(this.raw)

var wl_display_cancel_read* =
  if wl_display_cancel_read_c == nil: nil
  else:
    proc(this: Wl_display) {.cdecl.} =
      wl_display_cancel_read_c(this.raw)

var wl_display_roundtrip* =
  if wl_display_roundtrip_c == nil: nil
  else:
    proc(this: Wl_display): int32 {.cdecl.} =
      wl_display_roundtrip_c(this.raw)

var wl_proxy_set_user_data* =
  if wl_proxy_set_user_data_c == nil: nil
  else:
    proc(this: Wl_proxy, v: pointer) {.cdecl.} =
      wl_proxy_set_user_data_c(cast[pointer](this.raw), v)

var wl_proxy_get_user_data* =
  if wl_proxy_get_user_data_c == nil: nil
  else:
    proc(this: Wl_proxy): pointer {.cdecl.} =
      wl_proxy_get_user_data_c(cast[pointer](this.raw))

var wl_proxy_set_tag* =
  if wl_proxy_set_tag_c == nil: nil
  else:
    proc(this: Wl_proxy, v: ptr cstring) {.cdecl.} =
      wl_proxy_set_tag_c(cast[pointer](this.raw), v)

var wl_proxy_get_tag* =
  if wl_proxy_get_tag_c == nil: nil
  else:
    proc(this: Wl_proxy): ptr cstring {.cdecl.} =
      wl_proxy_get_tag_c(cast[pointer](this.raw))

var wl_proxy_destroy* =
  if wl_proxy_destroy_c == nil: nil
  else:
    proc(this: Wl_proxy) {.cdecl.} =
      wl_proxy_destroy_c(cast[pointer](this.raw))

var wl_proxy_get_version* =
  if wl_proxy_get_version_c == nil: nil
  else:
    proc(this: Wl_proxy): uint32 {.cdecl.} =
      wl_proxy_get_version_c(cast[pointer](this.raw))

var wl_proxy_get_id* =
  if wl_proxy_get_id_c == nil: nil
  else:
    proc(this: Wl_proxy): uint32 {.cdecl.} =
      wl_proxy_get_id_c(cast[pointer](this.raw))

var wl_display_dispatch_pending* =
  if wl_display_dispatch_pending_c == nil: nil
  else:
    proc(this: Wl_display): int32 {.cdecl.} =
      wl_display_dispatch_pending_c(this.raw)

var wl_proxy_add_dispatcher* =
  if wl_proxy_add_dispatcher_c == nil: nil
  else:
    proc(
      proxy: Wl_proxy, callback: Wl_dispatcher_proc, impl: pointer, proxyUserdata: pointer
    ): int32 {.cdecl.} =
      wl_proxy_add_dispatcher_c(cast[pointer](proxy.raw), callback, impl, proxyUserdata)

proc `=destroy`*(this: Wl_display) {.siwin_destructor.} =
  if this.raw != nil and wl_display_disconnect_c != nil:
    try:
      wl_display_disconnect this
    except:
      discard

proc destroyCallbacks*(this: Wl_proxy) =
  if this.raw == nil: return
  if this.wl_proxy_get_tag == proxyNimTag.addr:
    cast[ptr tuple[a: pointer, f: proc(cb: pointer) {.cdecl, raises: [].}]](this.raw.impl)[].f(this.raw.impl)
    this.wl_proxy_set_tag nil

proc destroy*(this: Wl_proxy) =
  if this.raw == nil: return
  destroyCallbacks this
  wl_proxy_destroy this

# proc `=destroy`*(this: Wl_proxy) =
#   destroy(this)

# proc `=copy`*(this: var Wl_proxy, v: Wl_proxy) {.error.}
# proc `=sink`*(this: var Wl_proxy, v: Wl_proxy) =
#   this.raw = v.raw

proc dispatchPending*(this: Wl_display): int32 =
  if wl_display_dispatch_pending_c == nil:
    raise OSError.newException("Wayland client library is not available")
  result = wl_display_dispatch_pending(this)
  if result == -1:
    raise WaylandProtocolError.newException("failed to dispatch events")

proc waylandClientAvailable*(): bool =
  libwaylandclientHandle != nil and wl_display_disconnect_c != nil and
    wl_display_connect_c != nil and wl_display_connect_to_fd_c != nil and
    wl_display_get_fd_c != nil and wl_display_flush_c != nil and
    wl_display_prepare_read_c != nil and wl_display_read_events_c != nil and
    wl_display_cancel_read_c != nil and wl_display_roundtrip_c != nil and
    wl_display_dispatch_pending_c != nil and wl_proxy_set_user_data_c != nil and
    wl_proxy_get_user_data_c != nil and wl_proxy_set_tag_c != nil and
    wl_proxy_get_tag_c != nil and wl_proxy_destroy_c != nil and
    wl_proxy_get_version_c != nil and wl_proxy_get_id_c != nil and
    wl_proxy_marshal_array_flags != nil and wl_proxy_marshal_flags != nil and
    wl_proxy_add_dispatcher_c != nil

proc dispatch*(this: Wl_display): int32 {.deprecated: "Use dispatchPending".} =
  ## Compatibility alias for the original public wrapper name.
  this.dispatchPending()

proc newWlMessage*(name: cstring, signature: cstring, types: openarray[ptr Wl_interface]): WlMessage =
  result.name = name
  result.signature = signature
  result.types = cast[ptr UncheckedArray[ptr Wl_interface]](alloc0(types.len * sizeof(pointer)))
  for i, x in types:
    result.types[i] = x

proc newWl_interface*(
  name: cstring, version: int32,
  methods: openarray[WlMessage],
  events: openarray[WlMessage],
): Wl_interface =
  result.name = name
  result.version = version

  result.methodsLen = methods.len.int32
  result.methods = cast[ptr UncheckedArray[WlMessage]](alloc0(methods.len * sizeof(WlMessage)))
  for i, x in methods:
    result.methods[i] = x

  result.events = cast[ptr UncheckedArray[WlMessage]](alloc0(events.len * sizeof(WlMessage)))
  result.eventsLen = events.len.int32
  for i, x in events:
    result.events[i] = x

proc construct*(proxy: pointer, interfaces: pointer, t: type, dispatcher: Wl_dispatcher_proc, callbacksT: type): t =
  result.proxy.raw = cast[ptr Wl_object](proxy)
  result.proxy.wl_proxy_set_tag(proxyNimTag.addr)
  let callbacks = cast[ptr callbacksT](alloc0(callbacksT.sizeof))
  cast[ptr pointer](callbacks)[] = interfaces
  callbacks[].destroy = proc(cb: pointer) {.cdecl, raises: [].} =
    `=destroy`(cast[ptr callbacksT](cb)[])
    dealloc(cb)
  discard result.proxy.wl_proxy_add_dispatcher(dispatcher, callbacks, nil)


proc iface*(display: type Wl_display): ptr Wl_interface =
  cast[ptr Wl_interface](display.raw)  # display is {proxy, ...}, proxy is {object, ...} and object is {ptr iface, ...} so it is safe to just cast pointer to ptr Wl_interface

template proxy*(x: Wl_display): Wl_display =
  x

proc `==`*(a: WlProxyTyped, b: typeof nil): bool = a.proxy.raw == nil
proc `==`*(a: Wl_proxy, b: typeof nil): bool = a.raw == nil
proc `==`*(a: Wl_display, b: typeof nil): bool = a.raw == nil


proc toSeq*(x: Wl_array, t: type): seq[t] =
  when t.sizeof != 4: {.error: "invalid type, must be 4 bytes long".}
  let len = x[].size div t.sizeof
  if len == 0: return
  result = newSeq[t](len)
  copyMem(result[0].addr, x[].data, len * sizeof(t))
