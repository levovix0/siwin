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
  proc wl_display_disconnect*(this: pointer)
  proc wl_display_connect*(name: cstring): pointer
  proc wl_display_connect_to_fd*(fd: FileHandle): pointer
  proc wl_display_get_fd*(this: pointer): FileHandle
  proc wl_display_flush*(this: pointer): int32
  proc wl_display_prepare_read*(this: pointer): int32
  proc wl_display_read_events*(this: pointer): int32
  proc wl_display_cancel_read*(this: pointer)
  proc wl_display_roundtrip*(this: pointer): int32
  proc wl_proxy_set_user_data*(this: pointer, v: pointer)
  proc wl_proxy_get_user_data*(this: pointer): pointer
  proc wl_proxy_set_tag*(this: pointer, v: ptr cstring)
  proc wl_proxy_get_tag*(this: pointer): ptr cstring
  proc wl_proxy_destroy*(this: pointer)
  proc wl_proxy_get_version*(this: pointer): uint32
  proc wl_proxy_get_id*(this: pointer): uint32
  proc wl_proxy_marshal_array_flags*(
    proxy: pointer, opcode: uint32, iface: ptr Wl_interface, version: uint32, flags: uint32, args: pointer
  ): pointer
  proc wl_proxy_marshal_flags*(
    proxy: pointer, opcode: uint32, iface: ptr Wl_interface, version: uint32, flags: uint32
  ): pointer {.varargs.}
  proc wl_display_dispatch_pending*(this: pointer): int32
  proc wl_proxy_add_dispatcher*(
    proxy: pointer, callback: Wl_dispatcher_proc, impl: pointer, proxyUserdata: pointer
  ): int32

proc wl_display_disconnect_nim*(this: Wl_display) =
  if this.raw != nil and wl_display_disconnect != nil:
    wl_display_disconnect(this.raw)

proc wl_display_connect_nim*(name: cstring): Wl_display =
  if wl_display_connect != nil:
    result.raw = wl_display_connect(name)

proc wl_display_connect_to_fd_nim*(fd: FileHandle): Wl_display =
  if wl_display_connect_to_fd != nil:
    result.raw = wl_display_connect_to_fd(fd)

proc wl_display_get_fd_nim*(this: Wl_display): FileHandle =
  wl_display_get_fd(this.raw)

proc wl_display_flush_nim*(this: Wl_display): int32 =
  wl_display_flush(this.raw)

proc wl_display_prepare_read_nim*(this: Wl_display): int32 =
  wl_display_prepare_read(this.raw)

proc wl_display_read_events_nim*(this: Wl_display): int32 =
  wl_display_read_events(this.raw)

proc wl_display_cancel_read_nim*(this: Wl_display) =
  wl_display_cancel_read(this.raw)

proc wl_display_roundtrip_nim*(this: Wl_display): int32 =
  wl_display_roundtrip(this.raw)

proc wl_proxy_set_user_data_nim*(this: Wl_proxy, v: pointer) =
  wl_proxy_set_user_data(cast[pointer](this.raw), v)

proc wl_proxy_get_user_data_nim*(this: Wl_proxy): pointer =
  wl_proxy_get_user_data(cast[pointer](this.raw))

proc wl_proxy_set_tag_nim*(this: Wl_proxy, v: ptr cstring) =
  wl_proxy_set_tag(cast[pointer](this.raw), v)

proc wl_proxy_get_tag_nim*(this: Wl_proxy): ptr cstring =
  wl_proxy_get_tag(cast[pointer](this.raw))

proc wl_proxy_destroy_nim*(this: Wl_proxy) =
  wl_proxy_destroy(cast[pointer](this.raw))

proc wl_proxy_get_version_nim*(this: Wl_proxy): uint32 =
  wl_proxy_get_version(cast[pointer](this.raw))

proc wl_proxy_get_id_nim*(this: Wl_proxy): uint32 =
  wl_proxy_get_id(cast[pointer](this.raw))

proc wl_display_dispatch_pending_nim*(this: Wl_display): int32 =
  wl_display_dispatch_pending(this.raw)

proc wl_proxy_add_dispatcher_nim*(
  proxy: Wl_proxy, callback: Wl_dispatcher_proc, impl: pointer, proxyUserdata: pointer
): int32 =
  wl_proxy_add_dispatcher(cast[pointer](proxy.raw), callback, impl, proxyUserdata)

proc `=destroy`*(this: Wl_display) {.siwin_destructor.} =
  if this.raw != nil and wl_display_disconnect != nil:
    try:
      wl_display_disconnect_nim this
    except:
      discard

proc destroyCallbacks*(this: Wl_proxy) =
  if this.raw == nil: return
  if this.wl_proxy_get_tag_nim == proxyNimTag.addr:
    cast[ptr tuple[a: pointer, f: proc(cb: pointer) {.cdecl, raises: [].}]](this.raw.impl)[].f(this.raw.impl)
    this.wl_proxy_set_tag_nim nil

proc destroy*(this: Wl_proxy) =
  if this.raw == nil: return
  destroyCallbacks this
  wl_proxy_destroy_nim this

# proc `=destroy`*(this: Wl_proxy) =
#   destroy(this)

# proc `=copy`*(this: var Wl_proxy, v: Wl_proxy) {.error.}
# proc `=sink`*(this: var Wl_proxy, v: Wl_proxy) =
#   this.raw = v.raw

proc dispatchPending*(this: Wl_display): int32 =
  if wl_display_dispatch_pending == nil:
    raise OSError.newException("Wayland client library is not available")
  result = wl_display_dispatch_pending_nim(this)
  if result == -1:
    raise WaylandProtocolError.newException("failed to dispatch events")

proc waylandClientAvailable*(): bool =
  libwaylandclientHandle != nil and wl_display_disconnect != nil and
    wl_display_connect != nil and wl_display_connect_to_fd != nil and
    wl_display_get_fd != nil and wl_display_flush != nil and
    wl_display_prepare_read != nil and wl_display_read_events != nil and
    wl_display_cancel_read != nil and wl_display_roundtrip != nil and
    wl_display_dispatch_pending != nil and wl_proxy_set_user_data != nil and
    wl_proxy_get_user_data != nil and wl_proxy_set_tag != nil and
    wl_proxy_get_tag != nil and wl_proxy_destroy != nil and
    wl_proxy_get_version != nil and wl_proxy_get_id != nil and
    wl_proxy_marshal_array_flags != nil and wl_proxy_marshal_flags != nil and
    wl_proxy_add_dispatcher != nil

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
  result.proxy.wl_proxy_set_tag_nim(proxyNimTag.addr)
  let callbacks = cast[ptr callbacksT](alloc0(callbacksT.sizeof))
  cast[ptr pointer](callbacks)[] = interfaces
  callbacks[].destroy = proc(cb: pointer) {.cdecl, raises: [].} =
    `=destroy`(cast[ptr callbacksT](cb)[])
    dealloc(cb)
  discard result.proxy.wl_proxy_add_dispatcher_nim(dispatcher, callbacks, nil)


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
