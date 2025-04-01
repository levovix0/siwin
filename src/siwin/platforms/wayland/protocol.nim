import ./[libwayland]

when defined(siwin_generate_wayland_protocol):
  import protocol_gen

import ./[protocol_generated]
export protocol_generated


template bindTyped*(this: Wl_registry, name: uint32, t: type, version: uint32): untyped =
  ## Binds a new, client-created object to the server using the
  ## specified name as the identifier.
  ##
  ## typed version
  let interfaces = cast[ptr ptr WaylandInterfaces](this.proxy.raw.impl)
  construct(wl_proxy_marshal_flags(
    this.proxy.raw, 0, interfaces[].`iface t`.addr, version, 0, name, ifaceName(t), version, nil
  ), interfaces[], t, `t / dispatch`, `t / Callbacks`)


proc get_registry*(this: Wl_display, interfaces: ptr WaylandInterfaces): Wl_registry =
  ## This request creates a registry object that allows the client
  ## to list and bind the global objects available from the
  ## compositor.
  ## 
  ## It should be noted that the server side resources consumed in
  ## response to a get_registry request can only be released when the
  ## client disconnects, not when the client side proxy is destroyed.
  ## Therefore, clients should invoke get_registry as infrequently as
  ## possible to avoid wasting memory.
  result = wl_proxy_marshal_flags(
    this.proxy.raw, 1, addr(interfaces.`iface Wl_registry`), 1, 0, nil
  ).construct(interfaces, Wl_registry, `Wl_registry / dispatch`, `Wl_registry / Callbacks`)

