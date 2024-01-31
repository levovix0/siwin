
{.pragma: importwayland, cdecl, dynlib: "libwayland-client.so(|.0)".}

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

  Wl_dispatcher_proc* = proc(
      impl: pointer, obj: pointer, opcode: uint32, msg: ptr WlMessage, args: pointer
    ): int32 {.cdecl.}
  
  Wl_array* = object
    size*: int
    alloc*: int
    data*: pointer
  
  WlProxyTyped* = concept x
    x.proxy is Wl_proxy


let proxyNimTag: cstring = "nim-side proxy (userdata is ref RootObj and it requires destruction)"


{.push, cdecl, dynlib: "libwayland-client.so(|.0)", importc.}

proc wl_display_disconnect*(this: Wl_display)

proc wl_display_connect*(name: cstring = nil): Wl_display
proc wl_display_connect_to_fd*(fd: FileHandle): Wl_display

proc wl_display_get_fd*(this: Wl_display): FileHandle

proc wl_display_flush*(this: Wl_display)
proc wl_display_roundtrip*(this: Wl_display)


proc wl_proxy_set_user_data*(this: Wl_proxy, v: pointer)
proc wl_proxy_get_user_data*(this: Wl_proxy): pointer

proc wl_proxy_set_tag*(this: Wl_proxy, v: ptr cstring)
proc wl_proxy_get_tag*(this: Wl_proxy): ptr cstring

proc wl_proxy_destroy*(this: Wl_proxy)

proc wl_proxy_get_version*(this: Wl_proxy): uint32
proc wl_proxy_get_id*(this: Wl_proxy): uint32

proc wl_proxy_marshal_array_flags*(
  proxy: pointer, opcode: uint32, iface: ptr Wl_interface, version: uint32, flags: uint32, args: pointer
): pointer

proc wl_proxy_add_dispatcher*(
  proxy: Wl_proxy, callback: Wl_dispatcher_proc, impl: pointer, proxyUserdata: pointer
): int32

{.pop.}


proc `=destroy`*(this: Wl_display) =
  if this.raw != nil:
    wl_display_disconnect this

proc `=destroy`*(this: Wl_proxy) =
  if this.raw == nil: return
  if this.wl_proxy_get_tag == proxyNimTag.addr:
    cast[ptr proc(cb: pointer) {.cdecl, raises: [].}](this.raw.impl)[](this.raw.impl)
  wl_proxy_destroy this

proc `=copy`*(this: var Wl_proxy, v: Wl_proxy) {.error.}
proc `=sink`*(this: var Wl_proxy, v: Wl_proxy) =
  this.raw = v.raw


proc dispatch*(this: Wl_display): int32 =
  proc impl(this: Wl_display): int32 {.importc: "wl_display_dispatch_pending", importwayland.}
  result = impl(this)
  if result == -1:
    raise WaylandProtocolError.newException("failed to dispatch events")

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

proc construct*(proxy: pointer, t: type, dispatcher: Wl_dispatcher_proc, callbacksT: type): t =
  result.proxy.raw = cast[ptr Wl_object](proxy)
  result.proxy.wl_proxy_set_tag(proxyNimTag.addr)
  let callbacks = cast[ptr callbacksT](alloc0(callbacksT.sizeof))
  callbacks.destroy = proc(cb: pointer) {.cdecl, raises: [].} =
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
