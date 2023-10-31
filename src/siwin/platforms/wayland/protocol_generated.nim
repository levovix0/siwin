
## note: this file is generated in protocol_gen.nim
## do not edit it mannualy!
## pass -d:siwin_generate_wayland_protocol to regenerate it
import
  libwayland

type
  Wl_registry* = object
    proxy*: Wl_proxy

  `Wl_registry / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_callback* = object
    proxy*: Wl_proxy

  `Wl_callback / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_compositor* = object
    proxy*: Wl_proxy

  `Wl_compositor / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_shm_pool* = object
    proxy*: Wl_proxy

  `Wl_shm_pool / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_shm* = object
    proxy*: Wl_proxy

  `Wl_shm / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_buffer* = object
    proxy*: Wl_proxy

  `Wl_buffer / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_data_offer* = object
    proxy*: Wl_proxy

  `Wl_data_offer / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_data_source* = object
    proxy*: Wl_proxy

  `Wl_data_source / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_data_device* = object
    proxy*: Wl_proxy

  `Wl_data_device / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_data_device_manager* = object
    proxy*: Wl_proxy

  `Wl_data_device_manager / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_shell* = object
    proxy*: Wl_proxy

  `Wl_shell / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_shell_surface* = object
    proxy*: Wl_proxy

  `Wl_shell_surface / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_surface* = object
    proxy*: Wl_proxy

  `Wl_surface / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_seat* = object
    proxy*: Wl_proxy

  `Wl_seat / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_pointer* = object
    proxy*: Wl_proxy

  `Wl_pointer / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_keyboard* = object
    proxy*: Wl_proxy

  `Wl_keyboard / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_touch* = object
    proxy*: Wl_proxy

  `Wl_touch / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_output* = object
    proxy*: Wl_proxy

  `Wl_output / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_region* = object
    proxy*: Wl_proxy

  `Wl_region / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_subcompositor* = object
    proxy*: Wl_proxy

  `Wl_subcompositor / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_subsurface* = object
    proxy*: Wl_proxy

  `Wl_subsurface / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
