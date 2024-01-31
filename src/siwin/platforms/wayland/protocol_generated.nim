
## note: this file is generated in protocol_gen.nim
## do not edit it mannualy!
## pass -d:siwin_generate_wayland_protocol to regenerate it
import
  libwayland

type
  Xdg_wm_base* = object
    ## The xdg_wm_base interface is exposed as a global object enabling clients
    ## to turn their wl_surfaces into windows in a desktop environment. It
    ## defines the basic functionality needed for clients and the compositor to
    ## create windows that can be dragged, resized, maximized, etc, as well as
    ## creating transient windows such as popup menus.
    proxy*: Wl_proxy

  `Xdg_wm_base / Error`* {.size: 4.} = enum
    role = 0, defunct_surfaces = 1, not_the_topmost_popup = 2,
    invalid_popup_parent = 3, invalid_surface_state = 4, invalid_positioner = 5,
    unresponsive = 6
  `Xdg_wm_base / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    ping*: proc (serial: uint32)

  Xdg_positioner* = object
    ## The xdg_positioner provides a collection of rules for the placement of a
    ## child surface relative to a parent surface. Rules can be defined to ensure
    ## the child surface remains within the visible area's borders, and to
    ## specify how the child surface changes its position, such as sliding along
    ## an axis, or flipping around a rectangle. These positioner-created rules are
    ## constrained by the requirement that a child surface must intersect with or
    ## be at least partially adjacent to its parent surface.
    ## 
    ## See the various requests for details about possible rules.
    ## 
    ## At the time of the request, the compositor makes a copy of the rules
    ## specified by the xdg_positioner. Thus, after the request is complete the
    ## xdg_positioner object can be destroyed or reused; further changes to the
    ## object will have no effect on previous usages.
    ## 
    ## For an xdg_positioner object to be considered complete, it must have a
    ## non-zero size set by set_size, and a non-zero anchor rectangle set by
    ## set_anchor_rect. Passing an incomplete xdg_positioner object when
    ## positioning a surface raises an invalid_positioner error.
    proxy*: Wl_proxy

  `Xdg_positioner / Error`* {.size: 4.} = enum
    invalid_input = 0
  `Xdg_positioner / Anchor`* {.size: 4.} = enum
    none = 0, top = 1, bottom = 2, left = 3, right = 4, top_left = 5,
    bottom_left = 6, top_right = 7, bottom_right = 8
  `Xdg_positioner / Gravity`* {.size: 4.} = enum
    none = 0, top = 1, bottom = 2, left = 3, right = 4, top_left = 5,
    bottom_left = 6, top_right = 7, bottom_right = 8
  `Xdg_positioner / Constraint_adjustment`* {.size: 4.} = enum ## The constraint adjustment value define ways the compositor will adjust
                                                                ## the position of the surface, if the unadjusted position would result
                                                                ## in the surface being partly constrained.
                                                                ## 
                                                                ## Whether a surface is considered 'constrained' is left to the compositor
                                                                ## to determine. For example, the surface may be partly outside the
                                                                ## compositor's defined 'work area', thus necessitating the child surface's
                                                                ## position be adjusted until it is entirely inside the work area.
                                                                ## 
                                                                ## The adjustments can be combined, according to a defined precedence: 1)
                                                                ## Flip, 2) Slide, 3) Resize.
    none = 0, slide_x = 1, slide_y = 2, flip_x = 4, flip_y = 8, resize_x = 16,
    resize_y = 32
  `Xdg_positioner / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Xdg_surface* = object
    ## An interface that may be implemented by a wl_surface, for
    ## implementations that provide a desktop-style user interface.
    ## 
    ## It provides a base set of functionality required to construct user
    ## interface elements requiring management by the compositor, such as
    ## toplevel windows, menus, etc. The types of functionality are split into
    ## xdg_surface roles.
    ## 
    ## Creating an xdg_surface does not set the role for a wl_surface. In order
    ## to map an xdg_surface, the client must create a role-specific object
    ## using, e.g., get_toplevel, get_popup. The wl_surface for any given
    ## xdg_surface can have at most one role, and may not be assigned any role
    ## not based on xdg_surface.
    ## 
    ## A role must be assigned before any other requests are made to the
    ## xdg_surface object.
    ## 
    ## The client must call wl_surface.commit on the corresponding wl_surface
    ## for the xdg_surface state to take effect.
    ## 
    ## Creating an xdg_surface from a wl_surface which has a buffer attached or
    ## committed is a client error, and any attempts by a client to attach or
    ## manipulate a buffer prior to the first xdg_surface.configure call must
    ## also be treated as errors.
    ## 
    ## After creating a role-specific object and setting it up, the client must
    ## perform an initial commit without any buffer attached. The compositor
    ## will reply with initial wl_surface state such as
    ## wl_surface.preferred_buffer_scale followed by an xdg_surface.configure
    ## event. The client must acknowledge it and is then allowed to attach a
    ## buffer to map the surface.
    ## 
    ## Mapping an xdg_surface-based role surface is defined as making it
    ## possible for the surface to be shown by the compositor. Note that
    ## a mapped surface is not guaranteed to be visible once it is mapped.
    ## 
    ## For an xdg_surface to be mapped by the compositor, the following
    ## conditions must be met:
    ## (1) the client has assigned an xdg_surface-based role to the surface
    ## (2) the client has set and committed the xdg_surface state and the
    ##   role-dependent state to the surface
    ## (3) the client has committed a buffer to the surface
    ## 
    ## A newly-unmapped surface is considered to have met condition (1) out
    ## of the 3 required conditions for mapping a surface if its role surface
    ## has not been destroyed, i.e. the client must perform the initial commit
    ## again before attaching a buffer.
    proxy*: Wl_proxy

  `Xdg_surface / Error`* {.size: 4.} = enum
    not_constructed = 1, already_constructed = 2, unconfigured_buffer = 3,
    invalid_serial = 4, invalid_size = 5, defunct_role_object = 6
  `Xdg_surface / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    configure*: proc (serial: uint32)

  Xdg_toplevel* = object
    ## This interface defines an xdg_surface role which allows a surface to,
    ## among other things, set window-like properties such as maximize,
    ## fullscreen, and minimize, set application-specific metadata like title and
    ## id, and well as trigger user interactive operations such as interactive
    ## resize and move.
    ## 
    ## Unmapping an xdg_toplevel means that the surface cannot be shown
    ## by the compositor until it is explicitly mapped again.
    ## All active operations (e.g., move, resize) are canceled and all
    ## attributes (e.g. title, state, stacking, ...) are discarded for
    ## an xdg_toplevel surface when it is unmapped. The xdg_toplevel returns to
    ## the state it had right after xdg_surface.get_toplevel. The client
    ## can re-map the toplevel by perfoming a commit without any buffer
    ## attached, waiting for a configure event and handling it as usual (see
    ## xdg_surface description).
    ## 
    ## Attaching a null buffer to a toplevel unmaps the surface.
    proxy*: Wl_proxy

  `Xdg_toplevel / Error`* {.size: 4.} = enum
    invalid_resize_edge = 0, invalid_parent = 1, invalid_size = 2
  `Xdg_toplevel / Resize_edge`* {.size: 4.} = enum ## These values are used to indicate which edge of a surface
                                                    ## is being dragged in a resize operation.
    none = 0, top = 1, bottom = 2, left = 4, top_left = 5, bottom_left = 6,
    right = 8, top_right = 9, bottom_right = 10
  `Xdg_toplevel / State`* {.size: 4.} = enum ## The different state values used on the surface. This is designed for
                                              ## state values like maximized, fullscreen. It is paired with the
                                              ## configure event to ensure that both the client and the compositor
                                              ## setting the state can be synchronized.
                                              ## 
                                              ## States set in this way are double-buffered. They will get applied on
                                              ## the next commit.
    maximized = 1, fullscreen = 2, resizing = 3, activated = 4, tiled_left = 5,
    tiled_right = 6, tiled_top = 7, tiled_bottom = 8, suspended = 9
  `Xdg_toplevel / Wm_capabilities`* {.size: 4.} = enum
    window_menu = 1, maximize = 2, fullscreen = 3, minimize = 4
  `Xdg_toplevel / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    configure*: proc (width: int32; height: int32; states: Wl_array)
    close*: proc ()
    configure_bounds*: proc (width: int32; height: int32)
    wm_capabilities*: proc (capabilities: Wl_array)

  Xdg_popup* = object
    ## A popup surface is a short-lived, temporary surface. It can be used to
    ## implement for example menus, popovers, tooltips and other similar user
    ## interface concepts.
    ## 
    ## A popup can be made to take an explicit grab. See xdg_popup.grab for
    ## details.
    ## 
    ## When the popup is dismissed, a popup_done event will be sent out, and at
    ## the same time the surface will be unmapped. See the xdg_popup.popup_done
    ## event for details.
    ## 
    ## Explicitly destroying the xdg_popup object will also dismiss the popup and
    ## unmap the surface. Clients that want to dismiss the popup when another
    ## surface of their own is clicked should dismiss the popup using the destroy
    ## request.
    ## 
    ## A newly created xdg_popup will be stacked on top of all previously created
    ## xdg_popup surfaces associated with the same xdg_toplevel.
    ## 
    ## The parent of an xdg_popup must be mapped (see the xdg_surface
    ## description) before the xdg_popup itself.
    ## 
    ## The client must call wl_surface.commit on the corresponding wl_surface
    ## for the xdg_popup state to take effect.
    proxy*: Wl_proxy

  `Xdg_popup / Error`* {.size: 4.} = enum
    invalid_grab = 0
  `Xdg_popup / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    configure*: proc (x: int32; y: int32; width: int32; height: int32)
    popup_done*: proc ()
    repositioned*: proc (token: uint32)

  `Wl_display / Error`* {.size: 4.} = enum ## These errors are global and can be emitted in response to any
                                            ## server request.
    invalid_object = 0, invalid_method = 1, no_memory = 2, implementation = 3
  Wl_registry* = object
    ## The singleton global registry object.  The server has a number of
    ## global objects that are available to all clients.  These objects
    ## typically represent an actual object in the server (for example,
    ## an input device) or they are singleton objects that provide
    ## extension functionality.
    ## 
    ## When a client creates a registry object, the registry object
    ## will emit a global event for each global currently in the
    ## registry.  Globals come and go as a result of device or
    ## monitor hotplugs, reconfiguration or other events, and the
    ## registry will send out global and global_remove events to
    ## keep the client up to date with the changes.  To mark the end
    ## of the initial burst of events, the client can use the
    ## wl_display.sync request immediately after calling
    ## wl_display.get_registry.
    ## 
    ## A client can bind to a global object by using the bind
    ## request.  This creates a client-side handle that lets the object
    ## emit events to the client and lets the client invoke requests on
    ## the object.
    proxy*: Wl_proxy

  `Wl_registry / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    global*: proc (name: uint32; `interface`: cstring; version: uint32)
    global_remove*: proc (name: uint32)

  Wl_callback* = object
    ## Clients can handle the 'done' event to get notified when
    ## the related request is done.
    ## 
    ## Note, because wl_callback objects are created from multiple independent
    ## factory interfaces, the wl_callback interface is frozen at version 1.
    proxy*: Wl_proxy

  `Wl_callback / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    done*: proc (callback_data: uint32)

  Wl_compositor* = object
    ## A compositor.  This object is a singleton global.  The
    ## compositor is in charge of combining the contents of multiple
    ## surfaces into one displayable output.
    proxy*: Wl_proxy

  `Wl_compositor / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_shm_pool* = object
    ## The wl_shm_pool object encapsulates a piece of memory shared
    ## between the compositor and client.  Through the wl_shm_pool
    ## object, the client can allocate shared memory wl_buffer objects.
    ## All objects created through the same pool share the same
    ## underlying mapped memory. Reusing the mapped memory avoids the
    ## setup/teardown overhead and is useful when interactively resizing
    ## a surface or for many small buffers.
    proxy*: Wl_proxy

  `Wl_shm_pool / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_shm* = object
    ## A singleton global object that provides support for shared
    ## memory.
    ## 
    ## Clients can create wl_shm_pool objects using the create_pool
    ## request.
    ## 
    ## On binding the wl_shm object one or more format events
    ## are emitted to inform clients about the valid pixel formats
    ## that can be used for buffers.
    proxy*: Wl_proxy

  `Wl_shm / Error`* {.size: 4.} = enum ## These errors can be emitted in response to wl_shm requests.
    invalid_format = 0, invalid_stride = 1, invalid_fd = 2
  `Wl_shm / Format`* {.size: 4.} = enum ## This describes the memory layout of an individual pixel.
                                         ## 
                                         ## All renderers should support argb8888 and xrgb8888 but any other
                                         ## formats are optional and may not be supported by the particular
                                         ## renderer in use.
                                         ## 
                                         ## The drm format codes match the macros defined in drm_fourcc.h, except
                                         ## argb8888 and xrgb8888. The formats actually supported by the compositor
                                         ## will be reported by the format event.
                                         ## 
                                         ## For all wl_shm formats and unless specified in another protocol
                                         ## extension, pre-multiplied alpha is used for pixel values.
    argb8888 = 0, xrgb8888 = 1, c1 = 538980675, d1 = 538980676, r1 = 538980690,
    c2 = 538980931, d2 = 538980932, r2 = 538980946, c4 = 538981443,
    d4 = 538981444, r4 = 538981458, c8 = 538982467, d8 = 538982468,
    r8 = 538982482, r10 = 540029266, r12 = 540160338, r16 = 540422482,
    p010 = 808530000, p210 = 808530512, y210 = 808530521, q410 = 808531025,
    y410 = 808531033, axbxgxrx106106106106 = 808534593,
    yuv420_10bit = 808539481, p030 = 808661072, bgra1010102 = 808665410,
    rgba1010102 = 808665426, abgr2101010 = 808665665, xbgr2101010 = 808665688,
    argb2101010 = 808669761, xrgb2101010 = 808669784, vuy101010 = 808670550,
    xvyu2101010 = 808670808, bgrx1010102 = 808671298, rgbx1010102 = 808671314,
    x0l0 = 810299480, y0l0 = 810299481, q401 = 825242705, yuv411 = 825316697,
    yvu411 = 825316953, nv21 = 825382478, nv61 = 825644622, p012 = 842084432,
    y212 = 842084953, y412 = 842085465, bgra4444 = 842088770,
    rgba4444 = 842088786, abgr4444 = 842089025, xbgr4444 = 842089048,
    argb4444 = 842093121, xrgb4444 = 842093144, yuv420 = 842093913,
    nv12 = 842094158, yvu420 = 842094169, bgrx4444 = 842094658,
    rgbx4444 = 842094674, rg1616 = 842221394, gr1616 = 842224199,
    nv42 = 842290766, x0l2 = 843853912, y0l2 = 843853913, bgra8888 = 875708738,
    rgba8888 = 875708754, abgr8888 = 875708993, xbgr8888 = 875709016,
    bgr888 = 875710274, rgb888 = 875710290, vuy888 = 875713878,
    yuv444 = 875713881, nv24 = 875714126, yvu444 = 875714137,
    bgrx8888 = 875714626, rgbx8888 = 875714642, bgra5551 = 892420418,
    rgba5551 = 892420434, abgr1555 = 892420673, xbgr1555 = 892420696,
    argb1555 = 892424769, xrgb1555 = 892424792, nv15 = 892425806,
    bgrx5551 = 892426306, rgbx5551 = 892426322, p016 = 909193296,
    y216 = 909193817, y416 = 909194329, bgr565 = 909199170, rgb565 = 909199186,
    yuv422 = 909202777, nv16 = 909203022, yvu422 = 909203033,
    xvyu12_16161616 = 909334104, yuv420_8bit = 942691673,
    abgr16161616 = 942948929, xbgr16161616 = 942948952,
    argb16161616 = 942953025, xrgb16161616 = 942953048,
    xvyu16161616 = 942954072, rg88 = 943212370, gr88 = 943215175,
    bgr565_a8 = 943797570, rgb565_a8 = 943797586, bgr888_a8 = 943798338,
    rgb888_a8 = 943798354, xbgr8888_a8 = 943800920, xrgb8888_a8 = 943805016,
    bgrx8888_a8 = 943806530, rgbx8888_a8 = 943806546, rgb332 = 943867730,
    bgr233 = 944916290, yvu410 = 961893977, yuv410 = 961959257,
    abgr16161616f = 1211384385, xbgr16161616f = 1211384408,
    argb16161616f = 1211388481, xrgb16161616f = 1211388504, yvyu = 1431918169,
    ayuv = 1448433985, xyuv8888 = 1448434008, yuyv = 1448695129,
    avuy8888 = 1498764865, xvuy8888 = 1498764888, vyuy = 1498765654,
    uyvy = 1498831189
  `Wl_shm / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    format*: proc (format: `Wl_shm / Format`)

  Wl_buffer* = object
    ## A buffer provides the content for a wl_surface. Buffers are
    ## created through factory interfaces such as wl_shm, wp_linux_buffer_params
    ## (from the linux-dmabuf protocol extension) or similar. It has a width and
    ## a height and can be attached to a wl_surface, but the mechanism by which a
    ## client provides and updates the contents is defined by the buffer factory
    ## interface.
    ## 
    ## If the buffer uses a format that has an alpha channel, the alpha channel
    ## is assumed to be premultiplied in the electrical color channel values
    ## (after transfer function encoding) unless otherwise specified.
    ## 
    ## Note, because wl_buffer objects are created from multiple independent
    ## factory interfaces, the wl_buffer interface is frozen at version 1.
    proxy*: Wl_proxy

  `Wl_buffer / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    release*: proc ()

  Wl_data_offer* = object
    ## A wl_data_offer represents a piece of data offered for transfer
    ## by another client (the source client).  It is used by the
    ## copy-and-paste and drag-and-drop mechanisms.  The offer
    ## describes the different mime types that the data can be
    ## converted to and provides the mechanism for transferring the
    ## data directly from the source client.
    proxy*: Wl_proxy

  `Wl_data_offer / Error`* {.size: 4.} = enum
    invalid_finish = 0, invalid_action_mask = 1, invalid_action = 2,
    invalid_offer = 3
  `Wl_data_offer / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    offer*: proc (mime_type: cstring)
    source_actions*: proc (source_actions: `Wl_data_device_manager / Dnd_action`)
    action*: proc (dnd_action: `Wl_data_device_manager / Dnd_action`)

  Wl_data_source* = object
    ## The wl_data_source object is the source side of a wl_data_offer.
    ## It is created by the source client in a data transfer and
    ## provides a way to describe the offered data and a way to respond
    ## to requests to transfer the data.
    proxy*: Wl_proxy

  `Wl_data_source / Error`* {.size: 4.} = enum
    invalid_action_mask = 0, invalid_source = 1
  `Wl_data_source / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    target*: proc (mime_type: cstring)
    send*: proc (mime_type: cstring; fd: FileHandle)
    cancelled*: proc ()
    dnd_drop_performed*: proc ()
    dnd_finished*: proc ()
    action*: proc (dnd_action: `Wl_data_device_manager / Dnd_action`)

  Wl_data_device* = object
    ## There is one wl_data_device per seat which can be obtained
    ## from the global wl_data_device_manager singleton.
    ## 
    ## A wl_data_device provides access to inter-client data transfer
    ## mechanisms such as copy-and-paste and drag-and-drop.
    proxy*: Wl_proxy

  `Wl_data_device / Error`* {.size: 4.} = enum
    role = 0, used_source = 1
  `Wl_data_device / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    data_offer*: proc (id: Wl_data_offer)
    enter*: proc (serial: uint32; surface: Wl_surface; x: float32; y: float32;
                  id: Wl_data_offer)
    leave*: proc ()
    motion*: proc (time: uint32; x: float32; y: float32)
    drop*: proc ()
    selection*: proc (id: Wl_data_offer)

  Wl_data_device_manager* = object
    ## The wl_data_device_manager is a singleton global object that
    ## provides access to inter-client data transfer mechanisms such as
    ## copy-and-paste and drag-and-drop.  These mechanisms are tied to
    ## a wl_seat and this interface lets a client get a wl_data_device
    ## corresponding to a wl_seat.
    ## 
    ## Depending on the version bound, the objects created from the bound
    ## wl_data_device_manager object will have different requirements for
    ## functioning properly. See wl_data_source.set_actions,
    ## wl_data_offer.accept and wl_data_offer.finish for details.
    proxy*: Wl_proxy

  `Wl_data_device_manager / Dnd_action`* {.size: 4.} = enum ## This is a bitmask of the available/preferred actions in a
                                                             ## drag-and-drop operation.
                                                             ## 
                                                             ## In the compositor, the selected action is a result of matching the
                                                             ## actions offered by the source and destination sides.  "action" events
                                                             ## with a "none" action will be sent to both source and destination if
                                                             ## there is no match. All further checks will effectively happen on
                                                             ## (source actions ∩ destination actions).
                                                             ## 
                                                             ## In addition, compositors may also pick different actions in
                                                             ## reaction to key modifiers being pressed. One common design that
                                                             ## is used in major toolkits (and the behavior recommended for
                                                             ## compositors) is:
                                                             ## 
                                                             ## - If no modifiers are pressed, the first match (in bit order)
                                                             ##   will be used.
                                                             ## - Pressing Shift selects "move", if enabled in the mask.
                                                             ## - Pressing Control selects "copy", if enabled in the mask.
                                                             ## 
                                                             ## Behavior beyond that is considered implementation-dependent.
                                                             ## Compositors may for example bind other modifiers (like Alt/Meta)
                                                             ## or drags initiated with other buttons than BTN_LEFT to specific
                                                             ## actions (e.g. "ask").
    none = 0, copy = 1, move = 2, ask = 4
  `Wl_data_device_manager / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_shell* = object
    ## This interface is implemented by servers that provide
    ## desktop-style user interfaces.
    ## 
    ## It allows clients to associate a wl_shell_surface with
    ## a basic surface.
    ## 
    ## Note! This protocol is deprecated and not intended for production use.
    ## For desktop-style user interfaces, use xdg_shell. Compositors and clients
    ## should not implement this interface.
    proxy*: Wl_proxy

  `Wl_shell / Error`* {.size: 4.} = enum
    role = 0
  `Wl_shell / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_shell_surface* = object
    ## An interface that may be implemented by a wl_surface, for
    ## implementations that provide a desktop-style user interface.
    ## 
    ## It provides requests to treat surfaces like toplevel, fullscreen
    ## or popup windows, move, resize or maximize them, associate
    ## metadata like title and class, etc.
    ## 
    ## On the server side the object is automatically destroyed when
    ## the related wl_surface is destroyed. On the client side,
    ## wl_shell_surface_destroy() must be called before destroying
    ## the wl_surface object.
    proxy*: Wl_proxy

  `Wl_shell_surface / Resize`* {.size: 4.} = enum ## These values are used to indicate which edge of a surface
                                                   ## is being dragged in a resize operation. The server may
                                                   ## use this information to adapt its behavior, e.g. choose
                                                   ## an appropriate cursor image.
    none = 0, top = 1, bottom = 2, left = 4, top_left = 5, bottom_left = 6,
    right = 8, top_right = 9, bottom_right = 10
  `Wl_shell_surface / Transient`* {.size: 4.} = enum ## These flags specify details of the expected behaviour
                                                      ## of transient surfaces. Used in the set_transient request.
    inactive = 1
  `Wl_shell_surface / Fullscreen_method`* {.size: 4.} = enum ## Hints to indicate to the compositor how to deal with a conflict
                                                              ## between the dimensions of the surface and the dimensions of the
                                                              ## output. The compositor is free to ignore this parameter.
    default = 0, scale = 1, driver = 2, fill = 3
  `Wl_shell_surface / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    ping*: proc (serial: uint32)
    configure*: proc (edges: `Wl_shell_surface / Resize`; width: int32;
                      height: int32)
    popup_done*: proc ()

  Wl_surface* = object
    ## A surface is a rectangular area that may be displayed on zero
    ## or more outputs, and shown any number of times at the compositor's
    ## discretion. They can present wl_buffers, receive user input, and
    ## define a local coordinate system.
    ## 
    ## The size of a surface (and relative positions on it) is described
    ## in surface-local coordinates, which may differ from the buffer
    ## coordinates of the pixel content, in case a buffer_transform
    ## or a buffer_scale is used.
    ## 
    ## A surface without a "role" is fairly useless: a compositor does
    ## not know where, when or how to present it. The role is the
    ## purpose of a wl_surface. Examples of roles are a cursor for a
    ## pointer (as set by wl_pointer.set_cursor), a drag icon
    ## (wl_data_device.start_drag), a sub-surface
    ## (wl_subcompositor.get_subsurface), and a window as defined by a
    ## shell protocol (e.g. wl_shell.get_shell_surface).
    ## 
    ## A surface can have only one role at a time. Initially a
    ## wl_surface does not have a role. Once a wl_surface is given a
    ## role, it is set permanently for the whole lifetime of the
    ## wl_surface object. Giving the current role again is allowed,
    ## unless explicitly forbidden by the relevant interface
    ## specification.
    ## 
    ## Surface roles are given by requests in other interfaces such as
    ## wl_pointer.set_cursor. The request should explicitly mention
    ## that this request gives a role to a wl_surface. Often, this
    ## request also creates a new protocol object that represents the
    ## role and adds additional functionality to wl_surface. When a
    ## client wants to destroy a wl_surface, they must destroy this role
    ## object before the wl_surface, otherwise a defunct_role_object error is
    ## sent.
    ## 
    ## Destroying the role object does not remove the role from the
    ## wl_surface, but it may stop the wl_surface from "playing the role".
    ## For instance, if a wl_subsurface object is destroyed, the wl_surface
    ## it was created for will be unmapped and forget its position and
    ## z-order. It is allowed to create a wl_subsurface for the same
    ## wl_surface again, but it is not allowed to use the wl_surface as
    ## a cursor (cursor is a different role than sub-surface, and role
    ## switching is not allowed).
    proxy*: Wl_proxy

  `Wl_surface / Error`* {.size: 4.} = enum ## These errors can be emitted in response to wl_surface requests.
    invalid_scale = 0, invalid_transform = 1, invalid_size = 2,
    invalid_offset = 3, defunct_role_object = 4
  `Wl_surface / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    enter*: proc (output: Wl_output)
    leave*: proc (output: Wl_output)
    preferred_buffer_scale*: proc (factor: int32)
    preferred_buffer_transform*: proc (transform: `Wl_output / Transform`)

  Wl_seat* = object
    ## A seat is a group of keyboards, pointer and touch devices. This
    ## object is published as a global during start up, or when such a
    ## device is hot plugged.  A seat typically has a pointer and
    ## maintains a keyboard focus and a pointer focus.
    proxy*: Wl_proxy

  `Wl_seat / Capability`* {.size: 4.} = enum ## This is a bitmask of capabilities this seat has; if a member is
                                              ## set, then it is present on the seat.
    pointer = 1, keyboard = 2, touch = 4
  `Wl_seat / Error`* {.size: 4.} = enum ## These errors can be emitted in response to wl_seat requests.
    missing_capability = 0
  `Wl_seat / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    capabilities*: proc (capabilities: `Wl_seat / Capability`)
    name*: proc (name: cstring)

  Wl_pointer* = object
    ## The wl_pointer interface represents one or more input devices,
    ## such as mice, which control the pointer location and pointer_focus
    ## of a seat.
    ## 
    ## The wl_pointer interface generates motion, enter and leave
    ## events for the surfaces that the pointer is located over,
    ## and button and axis events for button presses, button releases
    ## and scrolling.
    proxy*: Wl_proxy

  `Wl_pointer / Error`* {.size: 4.} = enum
    role = 0
  `Wl_pointer / Button_state`* {.size: 4.} = enum ## Describes the physical state of a button that produced the button
                                                   ## event.
    released = 0, pressed = 1
  `Wl_pointer / Axis`* {.size: 4.} = enum ## Describes the axis types of scroll events.
    vertical_scroll = 0, horizontal_scroll = 1
  `Wl_pointer / Axis_source`* {.size: 4.} = enum ## Describes the source types for axis events. This indicates to the
                                                  ## client how an axis event was physically generated; a client may
                                                  ## adjust the user interface accordingly. For example, scroll events
                                                  ## from a "finger" source may be in a smooth coordinate space with
                                                  ## kinetic scrolling whereas a "wheel" source may be in discrete steps
                                                  ## of a number of lines.
                                                  ## 
                                                  ## The "continuous" axis source is a device generating events in a
                                                  ## continuous coordinate space, but using something other than a
                                                  ## finger. One example for this source is button-based scrolling where
                                                  ## the vertical motion of a device is converted to scroll events while
                                                  ## a button is held down.
                                                  ## 
                                                  ## The "wheel tilt" axis source indicates that the actual device is a
                                                  ## wheel but the scroll event is not caused by a rotation but a
                                                  ## (usually sideways) tilt of the wheel.
    wheel = 0, finger = 1, continuous = 2, wheel_tilt = 3
  `Wl_pointer / Axis_relative_direction`* {.size: 4.} = enum ## This specifies the direction of the physical motion that caused a
                                                              ## wl_pointer.axis event, relative to the wl_pointer.axis direction.
    identical = 0, inverted = 1
  `Wl_pointer / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    enter*: proc (serial: uint32; surface: Wl_surface; surface_x: float32;
                  surface_y: float32)
    leave*: proc (serial: uint32; surface: Wl_surface)
    motion*: proc (time: uint32; surface_x: float32; surface_y: float32)
    button*: proc (serial: uint32; time: uint32; button: uint32;
                   state: `Wl_pointer / Button_state`)
    axis*: proc (time: uint32; axis: `Wl_pointer / Axis`; value: float32)
    frame*: proc ()
    axis_source*: proc (axis_source: `Wl_pointer / Axis_source`)
    axis_stop*: proc (time: uint32; axis: `Wl_pointer / Axis`)
    axis_discrete*: proc (axis: `Wl_pointer / Axis`; discrete: int32)
    axis_value120*: proc (axis: `Wl_pointer / Axis`; value120: int32)
    axis_relative_direction*: proc (axis: `Wl_pointer / Axis`; direction: `Wl_pointer / Axis_relative_direction`)

  Wl_keyboard* = object
    ## The wl_keyboard interface represents one or more keyboards
    ## associated with a seat.
    proxy*: Wl_proxy

  `Wl_keyboard / Keymap_format`* {.size: 4.} = enum ## This specifies the format of the keymap provided to the
                                                     ## client with the wl_keyboard.keymap event.
    no_keymap = 0, xkb_v1 = 1
  `Wl_keyboard / Key_state`* {.size: 4.} = enum ## Describes the physical state of a key that produced the key event.
    released = 0, pressed = 1
  `Wl_keyboard / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    keymap*: proc (format: `Wl_keyboard / Keymap_format`; fd: FileHandle;
                   size: uint32)
    enter*: proc (serial: uint32; surface: Wl_surface; keys: Wl_array)
    leave*: proc (serial: uint32; surface: Wl_surface)
    key*: proc (serial: uint32; time: uint32; key: uint32;
                state: `Wl_keyboard / Key_state`)
    modifiers*: proc (serial: uint32; mods_depressed: uint32;
                      mods_latched: uint32; mods_locked: uint32; group: uint32)
    repeat_info*: proc (rate: int32; delay: int32)

  Wl_touch* = object
    ## The wl_touch interface represents a touchscreen
    ## associated with a seat.
    ## 
    ## Touch interactions can consist of one or more contacts.
    ## For each contact, a series of events is generated, starting
    ## with a down event, followed by zero or more motion events,
    ## and ending with an up event. Events relating to the same
    ## contact point can be identified by the ID of the sequence.
    proxy*: Wl_proxy

  `Wl_touch / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    down*: proc (serial: uint32; time: uint32; surface: Wl_surface; id: int32;
                 x: float32; y: float32)
    up*: proc (serial: uint32; time: uint32; id: int32)
    motion*: proc (time: uint32; id: int32; x: float32; y: float32)
    frame*: proc ()
    cancel*: proc ()
    shape*: proc (id: int32; major: float32; minor: float32)
    orientation*: proc (id: int32; orientation: float32)

  Wl_output* = object
    ## An output describes part of the compositor geometry.  The
    ## compositor works in the 'compositor coordinate system' and an
    ## output corresponds to a rectangular area in that space that is
    ## actually visible.  This typically corresponds to a monitor that
    ## displays part of the compositor space.  This object is published
    ## as global during start up, or when a monitor is hotplugged.
    proxy*: Wl_proxy

  `Wl_output / Subpixel`* {.size: 4.} = enum ## This enumeration describes how the physical
                                              ## pixels on an output are laid out.
    unknown = 0, none = 1, horizontal_rgb = 2, horizontal_bgr = 3,
    vertical_rgb = 4, vertical_bgr = 5
  `Wl_output / Transform`* {.size: 4.} = enum ## This describes the transform that a compositor will apply to a
                                               ## surface to compensate for the rotation or mirroring of an
                                               ## output device.
                                               ## 
                                               ## The flipped values correspond to an initial flip around a
                                               ## vertical axis followed by rotation.
                                               ## 
                                               ## The purpose is mainly to allow clients to render accordingly and
                                               ## tell the compositor, so that for fullscreen surfaces, the
                                               ## compositor will still be able to scan out directly from client
                                               ## surfaces.
    normal = 0, `90` = 1, `180` = 2, `270` = 3, flipped = 4, flipped_90 = 5,
    flipped_180 = 6, flipped_270 = 7
  `Wl_output / Mode`* {.size: 4.} = enum ## These flags describe properties of an output mode.
                                          ## They are used in the flags bitfield of the mode event.
    current = 1, preferred = 2
  `Wl_output / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}
    geometry*: proc (x: int32; y: int32; physical_width: int32;
                     physical_height: int32; subpixel: `Wl_output / Subpixel`;
                     make: cstring; model: cstring;
                     transform: `Wl_output / Transform`)
    mode*: proc (flags: `Wl_output / Mode`; width: int32; height: int32;
                 refresh: int32)
    done*: proc ()
    scale*: proc (factor: int32)
    name*: proc (name: cstring)
    description*: proc (description: cstring)

  Wl_region* = object
    ## A region object describes an area.
    ## 
    ## Region objects are used to describe the opaque and input
    ## regions of a surface.
    proxy*: Wl_proxy

  `Wl_region / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_subcompositor* = object
    ## The global interface exposing sub-surface compositing capabilities.
    ## A wl_surface, that has sub-surfaces associated, is called the
    ## parent surface. Sub-surfaces can be arbitrarily nested and create
    ## a tree of sub-surfaces.
    ## 
    ## The root surface in a tree of sub-surfaces is the main
    ## surface. The main surface cannot be a sub-surface, because
    ## sub-surfaces must always have a parent.
    ## 
    ## A main surface with its sub-surfaces forms a (compound) window.
    ## For window management purposes, this set of wl_surface objects is
    ## to be considered as a single window, and it should also behave as
    ## such.
    ## 
    ## The aim of sub-surfaces is to offload some of the compositing work
    ## within a window from clients to the compositor. A prime example is
    ## a video player with decorations and video in separate wl_surface
    ## objects. This should allow the compositor to pass YUV video buffer
    ## processing to dedicated overlay hardware when possible.
    proxy*: Wl_proxy

  `Wl_subcompositor / Error`* {.size: 4.} = enum
    bad_surface = 0, bad_parent = 1
  `Wl_subcompositor / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

  Wl_subsurface* = object
    ## An additional interface to a wl_surface object, which has been
    ## made a sub-surface. A sub-surface has one parent surface. A
    ## sub-surface's size and position are not limited to that of the parent.
    ## Particularly, a sub-surface is not automatically clipped to its
    ## parent's area.
    ## 
    ## A sub-surface becomes mapped, when a non-NULL wl_buffer is applied
    ## and the parent surface is mapped. The order of which one happens
    ## first is irrelevant. A sub-surface is hidden if the parent becomes
    ## hidden, or if a NULL wl_buffer is applied. These rules apply
    ## recursively through the tree of surfaces.
    ## 
    ## The behaviour of a wl_surface.commit request on a sub-surface
    ## depends on the sub-surface's mode. The possible modes are
    ## synchronized and desynchronized, see methods
    ## wl_subsurface.set_sync and wl_subsurface.set_desync. Synchronized
    ## mode caches the wl_surface state to be applied when the parent's
    ## state gets applied, and desynchronized mode applies the pending
    ## wl_surface state directly. A sub-surface is initially in the
    ## synchronized mode.
    ## 
    ## Sub-surfaces also have another kind of state, which is managed by
    ## wl_subsurface requests, as opposed to wl_surface requests. This
    ## state includes the sub-surface position relative to the parent
    ## surface (wl_subsurface.set_position), and the stacking order of
    ## the parent and its sub-surfaces (wl_subsurface.place_above and
    ## .place_below). This state is applied when the parent surface's
    ## wl_surface state is applied, regardless of the sub-surface's mode.
    ## As the exception, set_sync and set_desync are effective immediately.
    ## 
    ## The main surface can be thought to be always in desynchronized mode,
    ## since it does not have a parent in the sub-surfaces sense.
    ## 
    ## Even if a sub-surface is in desynchronized mode, it will behave as
    ## in synchronized mode, if its parent surface behaves as in
    ## synchronized mode. This rule is applied recursively throughout the
    ## tree of surfaces. This means, that one can set a sub-surface into
    ## synchronized mode, and then assume that all its child and grand-child
    ## sub-surfaces are synchronized, too, without explicitly setting them.
    ## 
    ## Destroying a sub-surface takes effect immediately. If you need to
    ## synchronize the removal of a sub-surface to the parent surface update,
    ## unmap the sub-surface first by attaching a NULL wl_buffer, update parent,
    ## and then destroy the sub-surface.
    ## 
    ## If the parent wl_surface object is destroyed, the sub-surface is
    ## unmapped.
    proxy*: Wl_proxy

  `Wl_subsurface / Error`* {.size: 4.} = enum
    bad_surface = 0
  `Wl_subsurface / Callbacks`* = object
    destroy: proc (cb: pointer) {.cdecl, raises: [].}

var `Xdg_wm_base / iface`: WlInterface
proc iface*(t: typedesc[Xdg_wm_base]): ptr WlInterface =
  `Xdg_wm_base / iface`.addr

var `Xdg_positioner / iface`: WlInterface
proc iface*(t: typedesc[Xdg_positioner]): ptr WlInterface =
  `Xdg_positioner / iface`.addr

var `Xdg_surface / iface`: WlInterface
proc iface*(t: typedesc[Xdg_surface]): ptr WlInterface =
  `Xdg_surface / iface`.addr

var `Xdg_toplevel / iface`: WlInterface
proc iface*(t: typedesc[Xdg_toplevel]): ptr WlInterface =
  `Xdg_toplevel / iface`.addr

var `Xdg_popup / iface`: WlInterface
proc iface*(t: typedesc[Xdg_popup]): ptr WlInterface =
  `Xdg_popup / iface`.addr

var `Wl_registry / iface`: WlInterface
proc iface*(t: typedesc[Wl_registry]): ptr WlInterface =
  `Wl_registry / iface`.addr

var `Wl_callback / iface`: WlInterface
proc iface*(t: typedesc[Wl_callback]): ptr WlInterface =
  `Wl_callback / iface`.addr

var `Wl_compositor / iface`: WlInterface
proc iface*(t: typedesc[Wl_compositor]): ptr WlInterface =
  `Wl_compositor / iface`.addr

var `Wl_shm_pool / iface`: WlInterface
proc iface*(t: typedesc[Wl_shm_pool]): ptr WlInterface =
  `Wl_shm_pool / iface`.addr

var `Wl_shm / iface`: WlInterface
proc iface*(t: typedesc[Wl_shm]): ptr WlInterface =
  `Wl_shm / iface`.addr

var `Wl_buffer / iface`: WlInterface
proc iface*(t: typedesc[Wl_buffer]): ptr WlInterface =
  `Wl_buffer / iface`.addr

var `Wl_data_offer / iface`: WlInterface
proc iface*(t: typedesc[Wl_data_offer]): ptr WlInterface =
  `Wl_data_offer / iface`.addr

var `Wl_data_source / iface`: WlInterface
proc iface*(t: typedesc[Wl_data_source]): ptr WlInterface =
  `Wl_data_source / iface`.addr

var `Wl_data_device / iface`: WlInterface
proc iface*(t: typedesc[Wl_data_device]): ptr WlInterface =
  `Wl_data_device / iface`.addr

var `Wl_data_device_manager / iface`: WlInterface
proc iface*(t: typedesc[Wl_data_device_manager]): ptr WlInterface =
  `Wl_data_device_manager / iface`.addr

var `Wl_shell / iface`: WlInterface
proc iface*(t: typedesc[Wl_shell]): ptr WlInterface =
  `Wl_shell / iface`.addr

var `Wl_shell_surface / iface`: WlInterface
proc iface*(t: typedesc[Wl_shell_surface]): ptr WlInterface =
  `Wl_shell_surface / iface`.addr

var `Wl_surface / iface`: WlInterface
proc iface*(t: typedesc[Wl_surface]): ptr WlInterface =
  `Wl_surface / iface`.addr

var `Wl_seat / iface`: WlInterface
proc iface*(t: typedesc[Wl_seat]): ptr WlInterface =
  `Wl_seat / iface`.addr

var `Wl_pointer / iface`: WlInterface
proc iface*(t: typedesc[Wl_pointer]): ptr WlInterface =
  `Wl_pointer / iface`.addr

var `Wl_keyboard / iface`: WlInterface
proc iface*(t: typedesc[Wl_keyboard]): ptr WlInterface =
  `Wl_keyboard / iface`.addr

var `Wl_touch / iface`: WlInterface
proc iface*(t: typedesc[Wl_touch]): ptr WlInterface =
  `Wl_touch / iface`.addr

var `Wl_output / iface`: WlInterface
proc iface*(t: typedesc[Wl_output]): ptr WlInterface =
  `Wl_output / iface`.addr

var `Wl_region / iface`: WlInterface
proc iface*(t: typedesc[Wl_region]): ptr WlInterface =
  `Wl_region / iface`.addr

var `Wl_subcompositor / iface`: WlInterface
proc iface*(t: typedesc[Wl_subcompositor]): ptr WlInterface =
  `Wl_subcompositor / iface`.addr

var `Wl_subsurface / iface`: WlInterface
proc iface*(t: typedesc[Wl_subsurface]): ptr WlInterface =
  `Wl_subsurface / iface`.addr

`Xdg_wm_base / iface` = newWlInterface("xdg_wm_base", 6, [
    newWlMessage("xdg_wm_base.destroy", "1", []), newWlMessage(
    "xdg_wm_base.create_positioner", "1n", [iface(Xdg_positioner)]), newWlMessage(
    "xdg_wm_base.get_xdg_surface", "1no",
    [iface(Xdg_surface), iface(Wl_surface)]),
    newWlMessage("xdg_wm_base.pong", "1u", [(ptr WlInterface) nil])], [
    newWlMessage("xdg_wm_base.ping", "1u", [(ptr WlInterface) nil])])
`Xdg_positioner / iface` = newWlInterface("xdg_positioner", 6, [
    newWlMessage("xdg_positioner.destroy", "1", []), newWlMessage(
    "xdg_positioner.set_size", "1ii",
    [(ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "xdg_positioner.set_anchor_rect", "1iiii", [(ptr WlInterface) nil,
    (ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("xdg_positioner.set_anchor", "1u", [(ptr WlInterface) nil]),
    newWlMessage("xdg_positioner.set_gravity", "1u", [(ptr WlInterface) nil]), newWlMessage(
    "xdg_positioner.set_constraint_adjustment", "1u", [(ptr WlInterface) nil]), newWlMessage(
    "xdg_positioner.set_offset", "1ii",
    [(ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("xdg_positioner.set_reactive", "1", []), newWlMessage(
    "xdg_positioner.set_parent_size", "1ii",
    [(ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "xdg_positioner.set_parent_configure", "1u", [(ptr WlInterface) nil])], [])
`Xdg_surface / iface` = newWlInterface("xdg_surface", 6, [
    newWlMessage("xdg_surface.destroy", "1", []),
    newWlMessage("xdg_surface.get_toplevel", "1n", [iface(Xdg_toplevel)]), newWlMessage(
    "xdg_surface.get_popup", "1n?oo",
    [iface(Xdg_popup), iface(Xdg_surface), iface(Xdg_positioner)]), newWlMessage(
    "xdg_surface.set_window_geometry", "1iiii", [(ptr WlInterface) nil,
    (ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("xdg_surface.ack_configure", "1u", [(ptr WlInterface) nil])], [
    newWlMessage("xdg_surface.configure", "1u", [(ptr WlInterface) nil])])
`Xdg_toplevel / iface` = newWlInterface("xdg_toplevel", 6, [
    newWlMessage("xdg_toplevel.destroy", "1", []),
    newWlMessage("xdg_toplevel.set_parent", "1?o", [iface(Xdg_toplevel)]),
    newWlMessage("xdg_toplevel.set_title", "1s", [(ptr WlInterface) nil]),
    newWlMessage("xdg_toplevel.set_app_id", "1s", [(ptr WlInterface) nil]), newWlMessage(
    "xdg_toplevel.show_window_menu", "1ouii", [iface(Wl_seat),
    (ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "xdg_toplevel.move", "1ou", [iface(Wl_seat), (ptr WlInterface) nil]), newWlMessage(
    "xdg_toplevel.resize", "1ouu",
    [iface(Wl_seat), (ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "xdg_toplevel.set_max_size", "1ii",
    [(ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "xdg_toplevel.set_min_size", "1ii",
    [(ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("xdg_toplevel.set_maximized", "1", []),
    newWlMessage("xdg_toplevel.unset_maximized", "1", []),
    newWlMessage("xdg_toplevel.set_fullscreen", "1?o", [iface(Wl_output)]),
    newWlMessage("xdg_toplevel.unset_fullscreen", "1", []),
    newWlMessage("xdg_toplevel.set_minimized", "1", [])], [newWlMessage(
    "xdg_toplevel.configure", "1iia",
    [(ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("xdg_toplevel.close", "1", []), newWlMessage(
    "xdg_toplevel.configure_bounds", "1ii",
    [(ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("xdg_toplevel.wm_capabilities", "1a", [(ptr WlInterface) nil])])
`Xdg_popup / iface` = newWlInterface("xdg_popup", 6, [
    newWlMessage("xdg_popup.destroy", "1", []), newWlMessage("xdg_popup.grab",
    "1ou", [iface(Wl_seat), (ptr WlInterface) nil]), newWlMessage(
    "xdg_popup.reposition", "1ou",
    [iface(Xdg_positioner), (ptr WlInterface) nil])], [newWlMessage(
    "xdg_popup.configure", "1iiii", [(ptr WlInterface) nil,
                                     (ptr WlInterface) nil,
                                     (ptr WlInterface) nil,
                                     (ptr WlInterface) nil]),
    newWlMessage("xdg_popup.popup_done", "1", []),
    newWlMessage("xdg_popup.repositioned", "1u", [(ptr WlInterface) nil])])
`Wl_registry / iface` = newWlInterface("wl_registry", 1, [newWlMessage(
    "wl_registry.bind", "1un", [(ptr WlInterface) nil, (ptr WlInterface) nil])], [newWlMessage(
    "wl_registry.global", "1usu",
    [(ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("wl_registry.global_remove", "1u", [(ptr WlInterface) nil])])
`Wl_callback / iface` = newWlInterface("wl_callback", 1, [], [
    newWlMessage("wl_callback.done", "1u", [(ptr WlInterface) nil])])
`Wl_compositor / iface` = newWlInterface("wl_compositor", 6, [
    newWlMessage("wl_compositor.create_surface", "1n", [iface(Wl_surface)]),
    newWlMessage("wl_compositor.create_region", "1n", [iface(Wl_region)])], [])
`Wl_shm_pool / iface` = newWlInterface("wl_shm_pool", 1, [newWlMessage(
    "wl_shm_pool.create_buffer", "1niiiiu", [iface(Wl_buffer),
    (ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil,
    (ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("wl_shm_pool.destroy", "1", []),
    newWlMessage("wl_shm_pool.resize", "1i", [(ptr WlInterface) nil])], [])
`Wl_shm / iface` = newWlInterface("wl_shm", 1, [newWlMessage(
    "wl_shm.create_pool", "1nhi",
    [iface(Wl_shm_pool), (ptr WlInterface) nil, (ptr WlInterface) nil])], [
    newWlMessage("wl_shm.format", "1u", [(ptr WlInterface) nil])])
`Wl_buffer / iface` = newWlInterface("wl_buffer", 1, [
    newWlMessage("wl_buffer.destroy", "1", [])], [
    newWlMessage("wl_buffer.release", "1", [])])
`Wl_data_offer / iface` = newWlInterface("wl_data_offer", 3, [newWlMessage(
    "wl_data_offer.accept", "1u?s",
    [(ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_data_offer.receive", "1sh",
    [(ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("wl_data_offer.destroy", "1", []),
    newWlMessage("wl_data_offer.finish", "1", []), newWlMessage(
    "wl_data_offer.set_actions", "1uu",
    [(ptr WlInterface) nil, (ptr WlInterface) nil])], [
    newWlMessage("wl_data_offer.offer", "1s", [(ptr WlInterface) nil]), newWlMessage(
    "wl_data_offer.source_actions", "1u", [(ptr WlInterface) nil]),
    newWlMessage("wl_data_offer.action", "1u", [(ptr WlInterface) nil])])
`Wl_data_source / iface` = newWlInterface("wl_data_source", 3, [
    newWlMessage("wl_data_source.offer", "1s", [(ptr WlInterface) nil]),
    newWlMessage("wl_data_source.destroy", "1", []),
    newWlMessage("wl_data_source.set_actions", "1u", [(ptr WlInterface) nil])], [
    newWlMessage("wl_data_source.target", "1?s", [(ptr WlInterface) nil]), newWlMessage(
    "wl_data_source.send", "1sh", [(ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("wl_data_source.cancelled", "1", []),
    newWlMessage("wl_data_source.dnd_drop_performed", "1", []),
    newWlMessage("wl_data_source.dnd_finished", "1", []),
    newWlMessage("wl_data_source.action", "1u", [(ptr WlInterface) nil])])
`Wl_data_device / iface` = newWlInterface("wl_data_device", 3, [newWlMessage(
    "wl_data_device.start_drag", "1?oo?ou", [iface(Wl_data_source),
    iface(Wl_surface), iface(Wl_surface), (ptr WlInterface) nil]), newWlMessage(
    "wl_data_device.set_selection", "1?ou",
    [iface(Wl_data_source), (ptr WlInterface) nil]),
    newWlMessage("wl_data_device.release", "1", [])], [
    newWlMessage("wl_data_device.data_offer", "1n", [iface(Wl_data_offer)]), newWlMessage(
    "wl_data_device.enter", "1uoff?o", [(ptr WlInterface) nil,
                                        iface(Wl_surface),
                                        (ptr WlInterface) nil,
                                        (ptr WlInterface) nil,
                                        iface(Wl_data_offer)]),
    newWlMessage("wl_data_device.leave", "1", []), newWlMessage(
    "wl_data_device.motion", "1uff",
    [(ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("wl_data_device.drop", "1", []),
    newWlMessage("wl_data_device.selection", "1?o", [iface(Wl_data_offer)])])
`Wl_data_device_manager / iface` = newWlInterface("wl_data_device_manager", 3, [newWlMessage(
    "wl_data_device_manager.create_data_source", "1n", [iface(Wl_data_source)]), newWlMessage(
    "wl_data_device_manager.get_data_device", "1no",
    [iface(Wl_data_device), iface(Wl_seat)])], [])
`Wl_shell / iface` = newWlInterface("wl_shell", 1, [newWlMessage(
    "wl_shell.get_shell_surface", "1no",
    [iface(Wl_shell_surface), iface(Wl_surface)])], [])
`Wl_shell_surface / iface` = newWlInterface("wl_shell_surface", 1, [
    newWlMessage("wl_shell_surface.pong", "1u", [(ptr WlInterface) nil]), newWlMessage(
    "wl_shell_surface.move", "1ou", [iface(Wl_seat), (ptr WlInterface) nil]), newWlMessage(
    "wl_shell_surface.resize", "1ouu",
    [iface(Wl_seat), (ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("wl_shell_surface.set_toplevel", "1", []), newWlMessage(
    "wl_shell_surface.set_transient", "1oiiu", [iface(Wl_surface),
    (ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_shell_surface.set_fullscreen", "1uu?o",
    [(ptr WlInterface) nil, (ptr WlInterface) nil, iface(Wl_output)]), newWlMessage(
    "wl_shell_surface.set_popup", "1ouoiiu", [iface(Wl_seat),
    (ptr WlInterface) nil, iface(Wl_surface), (ptr WlInterface) nil,
    (ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("wl_shell_surface.set_maximized", "1?o", [iface(Wl_output)]),
    newWlMessage("wl_shell_surface.set_title", "1s", [(ptr WlInterface) nil]),
    newWlMessage("wl_shell_surface.set_class", "1s", [(ptr WlInterface) nil])], [
    newWlMessage("wl_shell_surface.ping", "1u", [(ptr WlInterface) nil]), newWlMessage(
    "wl_shell_surface.configure", "1uii",
    [(ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("wl_shell_surface.popup_done", "1", [])])
`Wl_surface / iface` = newWlInterface("wl_surface", 6, [
    newWlMessage("wl_surface.destroy", "1", []), newWlMessage(
    "wl_surface.attach", "1?oii",
    [iface(Wl_buffer), (ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_surface.damage", "1iiii", [(ptr WlInterface) nil, (ptr WlInterface) nil,
                                   (ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("wl_surface.frame", "1n", [iface(Wl_callback)]),
    newWlMessage("wl_surface.set_opaque_region", "1?o", [iface(Wl_region)]),
    newWlMessage("wl_surface.set_input_region", "1?o", [iface(Wl_region)]),
    newWlMessage("wl_surface.commit", "1", []), newWlMessage(
    "wl_surface.set_buffer_transform", "1i", [(ptr WlInterface) nil]),
    newWlMessage("wl_surface.set_buffer_scale", "1i", [(ptr WlInterface) nil]), newWlMessage(
    "wl_surface.damage_buffer", "1iiii", [(ptr WlInterface) nil,
    (ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_surface.offset", "1ii", [(ptr WlInterface) nil, (ptr WlInterface) nil])], [
    newWlMessage("wl_surface.enter", "1o", [iface(Wl_output)]),
    newWlMessage("wl_surface.leave", "1o", [iface(Wl_output)]), newWlMessage(
    "wl_surface.preferred_buffer_scale", "1i", [(ptr WlInterface) nil]), newWlMessage(
    "wl_surface.preferred_buffer_transform", "1u", [(ptr WlInterface) nil])])
`Wl_seat / iface` = newWlInterface("wl_seat", 9, [
    newWlMessage("wl_seat.get_pointer", "1n", [iface(Wl_pointer)]),
    newWlMessage("wl_seat.get_keyboard", "1n", [iface(Wl_keyboard)]),
    newWlMessage("wl_seat.get_touch", "1n", [iface(Wl_touch)]),
    newWlMessage("wl_seat.release", "1", [])], [
    newWlMessage("wl_seat.capabilities", "1u", [(ptr WlInterface) nil]),
    newWlMessage("wl_seat.name", "1s", [(ptr WlInterface) nil])])
`Wl_pointer / iface` = newWlInterface("wl_pointer", 9, [newWlMessage(
    "wl_pointer.set_cursor", "1u?oii", [(ptr WlInterface) nil,
                                        iface(Wl_surface),
                                        (ptr WlInterface) nil,
                                        (ptr WlInterface) nil]),
    newWlMessage("wl_pointer.release", "1", [])], [newWlMessage(
    "wl_pointer.enter", "1uoff", [(ptr WlInterface) nil, iface(Wl_surface),
                                  (ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_pointer.leave", "1uo", [(ptr WlInterface) nil, iface(Wl_surface)]), newWlMessage(
    "wl_pointer.motion", "1uff",
    [(ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_pointer.button", "1uuuu", [(ptr WlInterface) nil, (ptr WlInterface) nil,
                                   (ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_pointer.axis", "1uuf",
    [(ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("wl_pointer.frame", "1", []),
    newWlMessage("wl_pointer.axis_source", "1u", [(ptr WlInterface) nil]), newWlMessage(
    "wl_pointer.axis_stop", "1uu",
    [(ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_pointer.axis_discrete", "1ui",
    [(ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_pointer.axis_value120", "1ui",
    [(ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_pointer.axis_relative_direction", "1uu",
    [(ptr WlInterface) nil, (ptr WlInterface) nil])])
`Wl_keyboard / iface` = newWlInterface("wl_keyboard", 9, [
    newWlMessage("wl_keyboard.release", "1", [])], [newWlMessage(
    "wl_keyboard.keymap", "1uhu",
    [(ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_keyboard.enter", "1uoa",
    [(ptr WlInterface) nil, iface(Wl_surface), (ptr WlInterface) nil]), newWlMessage(
    "wl_keyboard.leave", "1uo", [(ptr WlInterface) nil, iface(Wl_surface)]), newWlMessage(
    "wl_keyboard.key", "1uuuu", [(ptr WlInterface) nil, (ptr WlInterface) nil,
                                 (ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_keyboard.modifiers", "1uuuuu", [(ptr WlInterface) nil,
                                        (ptr WlInterface) nil,
                                        (ptr WlInterface) nil,
                                        (ptr WlInterface) nil,
                                        (ptr WlInterface) nil]), newWlMessage(
    "wl_keyboard.repeat_info", "1ii",
    [(ptr WlInterface) nil, (ptr WlInterface) nil])])
`Wl_touch / iface` = newWlInterface("wl_touch", 9, [
    newWlMessage("wl_touch.release", "1", [])], [newWlMessage("wl_touch.down",
    "1uuoiff", [(ptr WlInterface) nil, (ptr WlInterface) nil, iface(Wl_surface),
                (ptr WlInterface) nil, (ptr WlInterface) nil,
                (ptr WlInterface) nil]), newWlMessage("wl_touch.up", "1uui",
    [(ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_touch.motion", "1uiff", [(ptr WlInterface) nil, (ptr WlInterface) nil,
                                 (ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("wl_touch.frame", "1", []),
    newWlMessage("wl_touch.cancel", "1", []), newWlMessage("wl_touch.shape",
    "1iff",
    [(ptr WlInterface) nil, (ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_touch.orientation", "1if",
    [(ptr WlInterface) nil, (ptr WlInterface) nil])])
`Wl_output / iface` = newWlInterface("wl_output", 4, [
    newWlMessage("wl_output.release", "1", [])], [newWlMessage(
    "wl_output.geometry", "1iiiiissi", [(ptr WlInterface) nil,
                                        (ptr WlInterface) nil,
                                        (ptr WlInterface) nil,
                                        (ptr WlInterface) nil,
                                        (ptr WlInterface) nil,
                                        (ptr WlInterface) nil,
                                        (ptr WlInterface) nil,
                                        (ptr WlInterface) nil]), newWlMessage(
    "wl_output.mode", "1uiii", [(ptr WlInterface) nil, (ptr WlInterface) nil,
                                (ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("wl_output.done", "1", []),
    newWlMessage("wl_output.scale", "1i", [(ptr WlInterface) nil]),
    newWlMessage("wl_output.name", "1s", [(ptr WlInterface) nil]),
    newWlMessage("wl_output.description", "1s", [(ptr WlInterface) nil])])
`Wl_region / iface` = newWlInterface("wl_region", 1, [
    newWlMessage("wl_region.destroy", "1", []), newWlMessage("wl_region.add",
    "1iiii", [(ptr WlInterface) nil, (ptr WlInterface) nil,
              (ptr WlInterface) nil, (ptr WlInterface) nil]), newWlMessage(
    "wl_region.subtract", "1iiii", [(ptr WlInterface) nil,
                                    (ptr WlInterface) nil,
                                    (ptr WlInterface) nil, (ptr WlInterface) nil])],
                                     [])
`Wl_subcompositor / iface` = newWlInterface("wl_subcompositor", 1, [
    newWlMessage("wl_subcompositor.destroy", "1", []), newWlMessage(
    "wl_subcompositor.get_subsurface", "1noo",
    [iface(Wl_subsurface), iface(Wl_surface), iface(Wl_surface)])], [])
`Wl_subsurface / iface` = newWlInterface("wl_subsurface", 1, [
    newWlMessage("wl_subsurface.destroy", "1", []), newWlMessage(
    "wl_subsurface.set_position", "1ii",
    [(ptr WlInterface) nil, (ptr WlInterface) nil]),
    newWlMessage("wl_subsurface.place_above", "1o", [iface(Wl_surface)]),
    newWlMessage("wl_subsurface.place_below", "1o", [iface(Wl_surface)]),
    newWlMessage("wl_subsurface.set_sync", "1", []),
    newWlMessage("wl_subsurface.set_desync", "1", [])], [])
proc `Xdg_wm_base / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                               msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Xdg_wm_base / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (uint32,)](args)[]
    if callbacks.ping != nil:
      callbacks.ping(args[0])
  else:
    discard

proc `Xdg_positioner / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                                  msg: ptr WlMessage; args: pointer): int32 {.
    cdecl.} =
  case opcode
  else:
    discard

proc `Xdg_surface / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                               msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Xdg_surface / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (uint32,)](args)[]
    if callbacks.configure != nil:
      callbacks.configure(args[0])
  else:
    discard

proc `Xdg_toplevel / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                                msg: ptr WlMessage; args: pointer): int32 {.
    cdecl.} =
  let callbacks = cast[ptr `Xdg_toplevel / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (int32, int32, Wl_array)](args)[]
    if callbacks.configure != nil:
      callbacks.configure(args[0], args[1], args[2])
  of 1:
    if callbacks.close != nil:
      callbacks.close()
  of 2:
    let args = cast[ptr (int32, int32)](args)[]
    if callbacks.configure_bounds != nil:
      callbacks.configure_bounds(args[0], args[1])
  of 3:
    let args = cast[ptr (Wl_array,)](args)[]
    if callbacks.wm_capabilities != nil:
      callbacks.wm_capabilities(args[0])
  else:
    discard

proc `Xdg_popup / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                             msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Xdg_popup / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (int32, int32, int32, int32)](args)[]
    if callbacks.configure != nil:
      callbacks.configure(args[0], args[1], args[2], args[3])
  of 1:
    if callbacks.popup_done != nil:
      callbacks.popup_done()
  of 2:
    let args = cast[ptr (uint32,)](args)[]
    if callbacks.repositioned != nil:
      callbacks.repositioned(args[0])
  else:
    discard

proc `Wl_registry / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                               msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Wl_registry / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (uint32, cstring, uint32)](args)[]
    if callbacks.global != nil:
      callbacks.global(args[0], args[1], args[2])
  of 1:
    let args = cast[ptr (uint32,)](args)[]
    if callbacks.global_remove != nil:
      callbacks.global_remove(args[0])
  else:
    discard

proc `Wl_callback / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                               msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Wl_callback / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (uint32,)](args)[]
    if callbacks.done != nil:
      callbacks.done(args[0])
  else:
    discard

proc `Wl_compositor / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                                 msg: ptr WlMessage; args: pointer): int32 {.
    cdecl.} =
  case opcode
  else:
    discard

proc `Wl_shm_pool / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                               msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  case opcode
  else:
    discard

proc `Wl_shm / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                          msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Wl_shm / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (`Wl_shm / Format`,)](args)[]
    if callbacks.format != nil:
      callbacks.format(args[0])
  else:
    discard

proc `Wl_buffer / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                             msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Wl_buffer / Callbacks`](impl)
  case opcode
  of 0:
    if callbacks.release != nil:
      callbacks.release()
  else:
    discard

proc `Wl_data_offer / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                                 msg: ptr WlMessage; args: pointer): int32 {.
    cdecl.} =
  let callbacks = cast[ptr `Wl_data_offer / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (cstring,)](args)[]
    if callbacks.offer != nil:
      callbacks.offer(args[0])
  of 1:
    let args = cast[ptr (`Wl_data_device_manager / Dnd_action`,)](args)[]
    if callbacks.source_actions != nil:
      callbacks.source_actions(args[0])
  of 2:
    let args = cast[ptr (`Wl_data_device_manager / Dnd_action`,)](args)[]
    if callbacks.action != nil:
      callbacks.action(args[0])
  else:
    discard

proc `Wl_data_source / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                                  msg: ptr WlMessage; args: pointer): int32 {.
    cdecl.} =
  let callbacks = cast[ptr `Wl_data_source / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (cstring,)](args)[]
    if callbacks.target != nil:
      callbacks.target(args[0])
  of 1:
    let args = cast[ptr (cstring, FileHandle)](args)[]
    if callbacks.send != nil:
      callbacks.send(args[0], args[1])
  of 2:
    if callbacks.cancelled != nil:
      callbacks.cancelled()
  of 3:
    if callbacks.dnd_drop_performed != nil:
      callbacks.dnd_drop_performed()
  of 4:
    if callbacks.dnd_finished != nil:
      callbacks.dnd_finished()
  of 5:
    let args = cast[ptr (`Wl_data_device_manager / Dnd_action`,)](args)[]
    if callbacks.action != nil:
      callbacks.action(args[0])
  else:
    discard

proc `Wl_data_device / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                                  msg: ptr WlMessage; args: pointer): int32 {.
    cdecl.} =
  let callbacks = cast[ptr `Wl_data_device / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (Wl_data_offer,)](args)[]
    if callbacks.data_offer != nil:
      callbacks.data_offer(args[0])
  of 1:
    let args = cast[ptr (uint32, Wl_surface, float32, float32, Wl_data_offer)](args)[]
    if callbacks.enter != nil:
      callbacks.enter(args[0], args[1], args[2], args[3], args[4])
  of 2:
    if callbacks.leave != nil:
      callbacks.leave()
  of 3:
    let args = cast[ptr (uint32, float32, float32)](args)[]
    if callbacks.motion != nil:
      callbacks.motion(args[0], args[1], args[2])
  of 4:
    if callbacks.drop != nil:
      callbacks.drop()
  of 5:
    let args = cast[ptr (Wl_data_offer,)](args)[]
    if callbacks.selection != nil:
      callbacks.selection(args[0])
  else:
    discard

proc `Wl_data_device_manager / dispatch`*(impl: pointer; obj: pointer;
    opcode: uint32; msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  case opcode
  else:
    discard

proc `Wl_shell / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                            msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  case opcode
  else:
    discard

proc `Wl_shell_surface / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                                    msg: ptr WlMessage; args: pointer): int32 {.
    cdecl.} =
  let callbacks = cast[ptr `Wl_shell_surface / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (uint32,)](args)[]
    if callbacks.ping != nil:
      callbacks.ping(args[0])
  of 1:
    let args = cast[ptr (`Wl_shell_surface / Resize`, int32, int32)](args)[]
    if callbacks.configure != nil:
      callbacks.configure(args[0], args[1], args[2])
  of 2:
    if callbacks.popup_done != nil:
      callbacks.popup_done()
  else:
    discard

proc `Wl_surface / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                              msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Wl_surface / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (Wl_output,)](args)[]
    if callbacks.enter != nil:
      callbacks.enter(args[0])
  of 1:
    let args = cast[ptr (Wl_output,)](args)[]
    if callbacks.leave != nil:
      callbacks.leave(args[0])
  of 2:
    let args = cast[ptr (int32,)](args)[]
    if callbacks.preferred_buffer_scale != nil:
      callbacks.preferred_buffer_scale(args[0])
  of 3:
    let args = cast[ptr (`Wl_output / Transform`,)](args)[]
    if callbacks.preferred_buffer_transform != nil:
      callbacks.preferred_buffer_transform(args[0])
  else:
    discard

proc `Wl_seat / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                           msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Wl_seat / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (`Wl_seat / Capability`,)](args)[]
    if callbacks.capabilities != nil:
      callbacks.capabilities(args[0])
  of 1:
    let args = cast[ptr (cstring,)](args)[]
    if callbacks.name != nil:
      callbacks.name(args[0])
  else:
    discard

proc `Wl_pointer / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                              msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Wl_pointer / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (uint32, Wl_surface, float32, float32)](args)[]
    if callbacks.enter != nil:
      callbacks.enter(args[0], args[1], args[2], args[3])
  of 1:
    let args = cast[ptr (uint32, Wl_surface)](args)[]
    if callbacks.leave != nil:
      callbacks.leave(args[0], args[1])
  of 2:
    let args = cast[ptr (uint32, float32, float32)](args)[]
    if callbacks.motion != nil:
      callbacks.motion(args[0], args[1], args[2])
  of 3:
    let args = cast[ptr (uint32, uint32, uint32, `Wl_pointer / Button_state`)](args)[]
    if callbacks.button != nil:
      callbacks.button(args[0], args[1], args[2], args[3])
  of 4:
    let args = cast[ptr (uint32, `Wl_pointer / Axis`, float32)](args)[]
    if callbacks.axis != nil:
      callbacks.axis(args[0], args[1], args[2])
  of 5:
    if callbacks.frame != nil:
      callbacks.frame()
  of 6:
    let args = cast[ptr (`Wl_pointer / Axis_source`,)](args)[]
    if callbacks.axis_source != nil:
      callbacks.axis_source(args[0])
  of 7:
    let args = cast[ptr (uint32, `Wl_pointer / Axis`)](args)[]
    if callbacks.axis_stop != nil:
      callbacks.axis_stop(args[0], args[1])
  of 8:
    let args = cast[ptr (`Wl_pointer / Axis`, int32)](args)[]
    if callbacks.axis_discrete != nil:
      callbacks.axis_discrete(args[0], args[1])
  of 9:
    let args = cast[ptr (`Wl_pointer / Axis`, int32)](args)[]
    if callbacks.axis_value120 != nil:
      callbacks.axis_value120(args[0], args[1])
  of 10:
    let args = cast[ptr (`Wl_pointer / Axis`,
                         `Wl_pointer / Axis_relative_direction`)](args)[]
    if callbacks.axis_relative_direction != nil:
      callbacks.axis_relative_direction(args[0], args[1])
  else:
    discard

proc `Wl_keyboard / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                               msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Wl_keyboard / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (`Wl_keyboard / Keymap_format`, FileHandle, uint32)](args)[]
    if callbacks.keymap != nil:
      callbacks.keymap(args[0], args[1], args[2])
  of 1:
    let args = cast[ptr (uint32, Wl_surface, Wl_array)](args)[]
    if callbacks.enter != nil:
      callbacks.enter(args[0], args[1], args[2])
  of 2:
    let args = cast[ptr (uint32, Wl_surface)](args)[]
    if callbacks.leave != nil:
      callbacks.leave(args[0], args[1])
  of 3:
    let args = cast[ptr (uint32, uint32, uint32, `Wl_keyboard / Key_state`)](args)[]
    if callbacks.key != nil:
      callbacks.key(args[0], args[1], args[2], args[3])
  of 4:
    let args = cast[ptr (uint32, uint32, uint32, uint32, uint32)](args)[]
    if callbacks.modifiers != nil:
      callbacks.modifiers(args[0], args[1], args[2], args[3], args[4])
  of 5:
    let args = cast[ptr (int32, int32)](args)[]
    if callbacks.repeat_info != nil:
      callbacks.repeat_info(args[0], args[1])
  else:
    discard

proc `Wl_touch / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                            msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Wl_touch / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (uint32, uint32, Wl_surface, int32, float32, float32)](args)[]
    if callbacks.down != nil:
      callbacks.down(args[0], args[1], args[2], args[3], args[4], args[5])
  of 1:
    let args = cast[ptr (uint32, uint32, int32)](args)[]
    if callbacks.up != nil:
      callbacks.up(args[0], args[1], args[2])
  of 2:
    let args = cast[ptr (uint32, int32, float32, float32)](args)[]
    if callbacks.motion != nil:
      callbacks.motion(args[0], args[1], args[2], args[3])
  of 3:
    if callbacks.frame != nil:
      callbacks.frame()
  of 4:
    if callbacks.cancel != nil:
      callbacks.cancel()
  of 5:
    let args = cast[ptr (int32, float32, float32)](args)[]
    if callbacks.shape != nil:
      callbacks.shape(args[0], args[1], args[2])
  of 6:
    let args = cast[ptr (int32, float32)](args)[]
    if callbacks.orientation != nil:
      callbacks.orientation(args[0], args[1])
  else:
    discard

proc `Wl_output / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                             msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  let callbacks = cast[ptr `Wl_output / Callbacks`](impl)
  case opcode
  of 0:
    let args = cast[ptr (int32, int32, int32, int32, `Wl_output / Subpixel`,
                         cstring, cstring, `Wl_output / Transform`)](args)[]
    if callbacks.geometry != nil:
      callbacks.geometry(args[0], args[1], args[2], args[3], args[4], args[5],
                         args[6], args[7])
  of 1:
    let args = cast[ptr (`Wl_output / Mode`, int32, int32, int32)](args)[]
    if callbacks.mode != nil:
      callbacks.mode(args[0], args[1], args[2], args[3])
  of 2:
    if callbacks.done != nil:
      callbacks.done()
  of 3:
    let args = cast[ptr (int32,)](args)[]
    if callbacks.scale != nil:
      callbacks.scale(args[0])
  of 4:
    let args = cast[ptr (cstring,)](args)[]
    if callbacks.name != nil:
      callbacks.name(args[0])
  of 5:
    let args = cast[ptr (cstring,)](args)[]
    if callbacks.description != nil:
      callbacks.description(args[0])
  else:
    discard

proc `Wl_region / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                             msg: ptr WlMessage; args: pointer): int32 {.cdecl.} =
  case opcode
  else:
    discard

proc `Wl_subcompositor / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                                    msg: ptr WlMessage; args: pointer): int32 {.
    cdecl.} =
  case opcode
  else:
    discard

proc `Wl_subsurface / dispatch`*(impl: pointer; obj: pointer; opcode: uint32;
                                 msg: ptr WlMessage; args: pointer): int32 {.
    cdecl.} =
  case opcode
  else:
    discard

proc destroy*(this: Xdg_wm_base) =
  ## Destroy this xdg_wm_base object.
  ## 
  ## Destroying a bound xdg_wm_base object while there are surfaces
  ## still alive created by this xdg_wm_base object instance is illegal
  ## and will result in a defunct_surfaces error.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 1, args.addr)

proc create_positioner*(this: Xdg_wm_base): Xdg_positioner =
  ## Create a positioner object. A positioner object is used to position
  ## surfaces relative to some parent surface. See the interface description
  ## and xdg_surface.get_popup for details.
  let args = (0'u32,)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 1,
      Xdg_positioner.iface, 1, 0, args.addr), Xdg_positioner,
            `Xdg_positioner / dispatch`, `Xdg_positioner / Callbacks`)

proc get_xdg_surface*(this: Xdg_wm_base; surface: Wl_surface): Xdg_surface =
  ## This creates an xdg_surface for the given surface. While xdg_surface
  ## itself is not a role, the corresponding surface may only be assigned
  ## a role extending xdg_surface, such as xdg_toplevel or xdg_popup. It is
  ## illegal to create an xdg_surface for a wl_surface which already has an
  ## assigned role and this will result in a role error.
  ## 
  ## This creates an xdg_surface for the given surface. An xdg_surface is
  ## used as basis to define a role to a given surface, such as xdg_toplevel
  ## or xdg_popup. It also manages functionality shared between xdg_surface
  ## based surface roles.
  ## 
  ## See the documentation of xdg_surface for more details about what an
  ## xdg_surface is and how it is used.
  let args = (0'u32, surface)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 2, Xdg_surface.iface,
      1, 0, args.addr), Xdg_surface, `Xdg_surface / dispatch`,
            `Xdg_surface / Callbacks`)

proc pong*(this: Xdg_wm_base; serial: uint32) =
  ## A client must respond to a ping event with a pong request or
  ## the client may be deemed unresponsive. See xdg_wm_base.ping
  ## and xdg_wm_base.error.unresponsive.
  let args = (serial,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 3, nil, 1, 0, args.addr)

proc destroy*(this: Xdg_positioner) =
  ## Notify the compositor that the xdg_positioner will no longer be used.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 1, args.addr)

proc set_size*(this: Xdg_positioner; width: int32; height: int32) =
  ## Set the size of the surface that is to be positioned with the positioner
  ## object. The size is in surface-local coordinates and corresponds to the
  ## window geometry. See xdg_surface.set_window_geometry.
  ## 
  ## If a zero or negative size is set the invalid_input error is raised.
  let args = (width, height)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 1, nil, 1, 0, args.addr)

proc set_anchor_rect*(this: Xdg_positioner; x: int32; y: int32; width: int32;
                      height: int32) =
  ## Specify the anchor rectangle within the parent surface that the child
  ## surface will be placed relative to. The rectangle is relative to the
  ## window geometry as defined by xdg_surface.set_window_geometry of the
  ## parent surface.
  ## 
  ## When the xdg_positioner object is used to position a child surface, the
  ## anchor rectangle may not extend outside the window geometry of the
  ## positioned child's parent surface.
  ## 
  ## If a negative size is set the invalid_input error is raised.
  let args = (x, y, width, height)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 2, nil, 1, 0, args.addr)

proc set_anchor*(this: Xdg_positioner; anchor: `Xdg_positioner / Anchor`) =
  ## Defines the anchor point for the anchor rectangle. The specified anchor
  ## is used derive an anchor point that the child surface will be
  ## positioned relative to. If a corner anchor is set (e.g. 'top_left' or
  ## 'bottom_right'), the anchor point will be at the specified corner;
  ## otherwise, the derived anchor point will be centered on the specified
  ## edge, or in the center of the anchor rectangle if no edge is specified.
  let args = (anchor,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 3, nil, 1, 0, args.addr)

proc set_gravity*(this: Xdg_positioner; gravity: `Xdg_positioner / Gravity`) =
  ## Defines in what direction a surface should be positioned, relative to
  ## the anchor point of the parent surface. If a corner gravity is
  ## specified (e.g. 'bottom_right' or 'top_left'), then the child surface
  ## will be placed towards the specified gravity; otherwise, the child
  ## surface will be centered over the anchor point on any axis that had no
  ## gravity specified. If the gravity is not in the ‘gravity’ enum, an
  ## invalid_input error is raised.
  let args = (gravity,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 4, nil, 1, 0, args.addr)

proc set_constraint_adjustment*(this: Xdg_positioner;
                                constraint_adjustment: uint32) =
  ## Specify how the window should be positioned if the originally intended
  ## position caused the surface to be constrained, meaning at least
  ## partially outside positioning boundaries set by the compositor. The
  ## adjustment is set by constructing a bitmask describing the adjustment to
  ## be made when the surface is constrained on that axis.
  ## 
  ## If no bit for one axis is set, the compositor will assume that the child
  ## surface should not change its position on that axis when constrained.
  ## 
  ## If more than one bit for one axis is set, the order of how adjustments
  ## are applied is specified in the corresponding adjustment descriptions.
  ## 
  ## The default adjustment is none.
  let args = (constraint_adjustment,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 5, nil, 1, 0, args.addr)

proc set_offset*(this: Xdg_positioner; x: int32; y: int32) =
  ## Specify the surface position offset relative to the position of the
  ## anchor on the anchor rectangle and the anchor on the surface. For
  ## example if the anchor of the anchor rectangle is at (x, y), the surface
  ## has the gravity bottom|right, and the offset is (ox, oy), the calculated
  ## surface position will be (x + ox, y + oy). The offset position of the
  ## surface is the one used for constraint testing. See
  ## set_constraint_adjustment.
  ## 
  ## An example use case is placing a popup menu on top of a user interface
  ## element, while aligning the user interface element of the parent surface
  ## with some user interface element placed somewhere in the popup surface.
  let args = (x, y)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 6, nil, 1, 0, args.addr)

proc set_reactive*(this: Xdg_positioner) =
  ## When set reactive, the surface is reconstrained if the conditions used
  ## for constraining changed, e.g. the parent window moved.
  ## 
  ## If the conditions changed and the popup was reconstrained, an
  ## xdg_popup.configure event is sent with updated geometry, followed by an
  ## xdg_surface.configure event.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 7, nil, 1, 0, args.addr)

proc set_parent_size*(this: Xdg_positioner; parent_width: int32;
                      parent_height: int32) =
  ## Set the parent window geometry the compositor should use when
  ## positioning the popup. The compositor may use this information to
  ## determine the future state the popup should be constrained using. If
  ## this doesn't match the dimension of the parent the popup is eventually
  ## positioned against, the behavior is undefined.
  ## 
  ## The arguments are given in the surface-local coordinate space.
  let args = (parent_width, parent_height)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 8, nil, 1, 0, args.addr)

proc set_parent_configure*(this: Xdg_positioner; serial: uint32) =
  ## Set the serial of an xdg_surface.configure event this positioner will be
  ## used in response to. The compositor may use this information together
  ## with set_parent_size to determine what future state the popup should be
  ## constrained using.
  let args = (serial,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 9, nil, 1, 0, args.addr)

proc destroy*(this: Xdg_surface) =
  ## Destroy the xdg_surface object. An xdg_surface must only be destroyed
  ## after its role object has been destroyed, otherwise
  ## a defunct_role_object error is raised.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 1, args.addr)

proc get_toplevel*(this: Xdg_surface): Xdg_toplevel =
  ## This creates an xdg_toplevel object for the given xdg_surface and gives
  ## the associated wl_surface the xdg_toplevel role.
  ## 
  ## See the documentation of xdg_toplevel for more details about what an
  ## xdg_toplevel is and how it is used.
  let args = (0'u32,)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 1, Xdg_toplevel.iface,
      1, 0, args.addr), Xdg_toplevel, `Xdg_toplevel / dispatch`,
            `Xdg_toplevel / Callbacks`)

proc get_popup*(this: Xdg_surface; parent: Xdg_surface;
                positioner: Xdg_positioner): Xdg_popup =
  ## This creates an xdg_popup object for the given xdg_surface and gives
  ## the associated wl_surface the xdg_popup role.
  ## 
  ## If null is passed as a parent, a parent surface must be specified using
  ## some other protocol, before committing the initial state.
  ## 
  ## See the documentation of xdg_popup for more details about what an
  ## xdg_popup is and how it is used.
  let args = (0'u32, parent, positioner)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 2, Xdg_popup.iface, 1,
      0, args.addr), Xdg_popup, `Xdg_popup / dispatch`, `Xdg_popup / Callbacks`)

proc set_window_geometry*(this: Xdg_surface; x: int32; y: int32; width: int32;
                          height: int32) =
  ## The window geometry of a surface is its "visible bounds" from the
  ## user's perspective. Client-side decorations often have invisible
  ## portions like drop-shadows which should be ignored for the
  ## purposes of aligning, placing and constraining windows.
  ## 
  ## The window geometry is double buffered, and will be applied at the
  ## time wl_surface.commit of the corresponding wl_surface is called.
  ## 
  ## When maintaining a position, the compositor should treat the (x, y)
  ## coordinate of the window geometry as the top left corner of the window.
  ## A client changing the (x, y) window geometry coordinate should in
  ## general not alter the position of the window.
  ## 
  ## Once the window geometry of the surface is set, it is not possible to
  ## unset it, and it will remain the same until set_window_geometry is
  ## called again, even if a new subsurface or buffer is attached.
  ## 
  ## If never set, the value is the full bounds of the surface,
  ## including any subsurfaces. This updates dynamically on every
  ## commit. This unset is meant for extremely simple clients.
  ## 
  ## The arguments are given in the surface-local coordinate space of
  ## the wl_surface associated with this xdg_surface, and may extend outside
  ## of the wl_surface itself to mark parts of the subsurface tree as part of
  ## the window geometry.
  ## 
  ## When applied, the effective window geometry will be the set window
  ## geometry clamped to the bounding rectangle of the combined
  ## geometry of the surface of the xdg_surface and the associated
  ## subsurfaces.
  ## 
  ## The effective geometry will not be recalculated unless a new call to
  ## set_window_geometry is done and the new pending surface state is
  ## subsequently applied.
  ## 
  ## The width and height of the effective window geometry must be
  ## greater than zero. Setting an invalid size will raise an
  ## invalid_size error.
  let args = (x, y, width, height)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 3, nil, 1, 0, args.addr)

proc ack_configure*(this: Xdg_surface; serial: uint32) =
  ## When a configure event is received, if a client commits the
  ## surface in response to the configure event, then the client
  ## must make an ack_configure request sometime before the commit
  ## request, passing along the serial of the configure event.
  ## 
  ## For instance, for toplevel surfaces the compositor might use this
  ## information to move a surface to the top left only when the client has
  ## drawn itself for the maximized or fullscreen state.
  ## 
  ## If the client receives multiple configure events before it
  ## can respond to one, it only has to ack the last configure event.
  ## Acking a configure event that was never sent raises an invalid_serial
  ## error.
  ## 
  ## A client is not required to commit immediately after sending
  ## an ack_configure request - it may even ack_configure several times
  ## before its next surface commit.
  ## 
  ## A client may send multiple ack_configure requests before committing, but
  ## only the last request sent before a commit indicates which configure
  ## event the client really is responding to.
  ## 
  ## Sending an ack_configure request consumes the serial number sent with
  ## the request, as well as serial numbers sent by all configure events
  ## sent on this xdg_surface prior to the configure event referenced by
  ## the committed serial.
  ## 
  ## It is an error to issue multiple ack_configure requests referencing a
  ## serial from the same configure event, or to issue an ack_configure
  ## request referencing a serial from a configure event issued before the
  ## event identified by the last ack_configure request for the same
  ## xdg_surface. Doing so will raise an invalid_serial error.
  let args = (serial,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 4, nil, 1, 0, args.addr)

proc destroy*(this: Xdg_toplevel) =
  ## This request destroys the role surface and unmaps the surface;
  ## see "Unmapping" behavior in interface section for details.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 1, args.addr)

proc set_parent*(this: Xdg_toplevel; parent: Xdg_toplevel) =
  ## Set the "parent" of this surface. This surface should be stacked
  ## above the parent surface and all other ancestor surfaces.
  ## 
  ## Parent surfaces should be set on dialogs, toolboxes, or other
  ## "auxiliary" surfaces, so that the parent is raised when the dialog
  ## is raised.
  ## 
  ## Setting a null parent for a child surface unsets its parent. Setting
  ## a null parent for a surface which currently has no parent is a no-op.
  ## 
  ## Only mapped surfaces can have child surfaces. Setting a parent which
  ## is not mapped is equivalent to setting a null parent. If a surface
  ## becomes unmapped, its children's parent is set to the parent of
  ## the now-unmapped surface. If the now-unmapped surface has no parent,
  ## its children's parent is unset. If the now-unmapped surface becomes
  ## mapped again, its parent-child relationship is not restored.
  ## 
  ## The parent toplevel must not be one of the child toplevel's
  ## descendants, and the parent must be different from the child toplevel,
  ## otherwise the invalid_parent protocol error is raised.
  let args = (parent,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 1, nil, 1, 0, args.addr)

proc set_title*(this: Xdg_toplevel; title: cstring) =
  ## Set a short title for the surface.
  ## 
  ## This string may be used to identify the surface in a task bar,
  ## window list, or other user interface elements provided by the
  ## compositor.
  ## 
  ## The string must be encoded in UTF-8.
  let args = (title,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 2, nil, 1, 0, args.addr)

proc set_app_id*(this: Xdg_toplevel; app_id: cstring) =
  ## Set an application identifier for the surface.
  ## 
  ## The app ID identifies the general class of applications to which
  ## the surface belongs. The compositor can use this to group multiple
  ## surfaces together, or to determine how to launch a new application.
  ## 
  ## For D-Bus activatable applications, the app ID is used as the D-Bus
  ## service name.
  ## 
  ## The compositor shell will try to group application surfaces together
  ## by their app ID. As a best practice, it is suggested to select app
  ## ID's that match the basename of the application's .desktop file.
  ## For example, "org.freedesktop.FooViewer" where the .desktop file is
  ## "org.freedesktop.FooViewer.desktop".
  ## 
  ## Like other properties, a set_app_id request can be sent after the
  ## xdg_toplevel has been mapped to update the property.
  ## 
  ## See the desktop-entry specification [0] for more details on
  ## application identifiers and how they relate to well-known D-Bus
  ## names and .desktop files.
  ## 
  ## [0] https://standards.freedesktop.org/desktop-entry-spec/
  let args = (app_id,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 3, nil, 1, 0, args.addr)

proc show_window_menu*(this: Xdg_toplevel; seat: Wl_seat; serial: uint32;
                       x: int32; y: int32) =
  ## Clients implementing client-side decorations might want to show
  ## a context menu when right-clicking on the decorations, giving the
  ## user a menu that they can use to maximize or minimize the window.
  ## 
  ## This request asks the compositor to pop up such a window menu at
  ## the given position, relative to the local surface coordinates of
  ## the parent surface. There are no guarantees as to what menu items
  ## the window menu contains, or even if a window menu will be drawn
  ## at all.
  ## 
  ## This request must be used in response to some sort of user action
  ## like a button press, key press, or touch down event.
  let args = (seat, serial, x, y)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 4, nil, 1, 0, args.addr)

proc move*(this: Xdg_toplevel; seat: Wl_seat; serial: uint32) =
  ## Start an interactive, user-driven move of the surface.
  ## 
  ## This request must be used in response to some sort of user action
  ## like a button press, key press, or touch down event. The passed
  ## serial is used to determine the type of interactive move (touch,
  ## pointer, etc).
  ## 
  ## The server may ignore move requests depending on the state of
  ## the surface (e.g. fullscreen or maximized), or if the passed serial
  ## is no longer valid.
  ## 
  ## If triggered, the surface will lose the focus of the device
  ## (wl_pointer, wl_touch, etc) used for the move. It is up to the
  ## compositor to visually indicate that the move is taking place, such as
  ## updating a pointer cursor, during the move. There is no guarantee
  ## that the device focus will return when the move is completed.
  let args = (seat, serial)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 5, nil, 1, 0, args.addr)

proc resize*(this: Xdg_toplevel; seat: Wl_seat; serial: uint32;
             edges: `Xdg_toplevel / Resize_edge`) =
  ## Start a user-driven, interactive resize of the surface.
  ## 
  ## This request must be used in response to some sort of user action
  ## like a button press, key press, or touch down event. The passed
  ## serial is used to determine the type of interactive resize (touch,
  ## pointer, etc).
  ## 
  ## The server may ignore resize requests depending on the state of
  ## the surface (e.g. fullscreen or maximized).
  ## 
  ## If triggered, the client will receive configure events with the
  ## "resize" state enum value and the expected sizes. See the "resize"
  ## enum value for more details about what is required. The client
  ## must also acknowledge configure events using "ack_configure". After
  ## the resize is completed, the client will receive another "configure"
  ## event without the resize state.
  ## 
  ## If triggered, the surface also will lose the focus of the device
  ## (wl_pointer, wl_touch, etc) used for the resize. It is up to the
  ## compositor to visually indicate that the resize is taking place,
  ## such as updating a pointer cursor, during the resize. There is no
  ## guarantee that the device focus will return when the resize is
  ## completed.
  ## 
  ## The edges parameter specifies how the surface should be resized, and
  ## is one of the values of the resize_edge enum. Values not matching
  ## a variant of the enum will cause the invalid_resize_edge protocol error.
  ## The compositor may use this information to update the surface position
  ## for example when dragging the top left corner. The compositor may also
  ## use this information to adapt its behavior, e.g. choose an appropriate
  ## cursor image.
  let args = (seat, serial, edges)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 6, nil, 1, 0, args.addr)

proc set_max_size*(this: Xdg_toplevel; width: int32; height: int32) =
  ## Set a maximum size for the window.
  ## 
  ## The client can specify a maximum size so that the compositor does
  ## not try to configure the window beyond this size.
  ## 
  ## The width and height arguments are in window geometry coordinates.
  ## See xdg_surface.set_window_geometry.
  ## 
  ## Values set in this way are double-buffered. They will get applied
  ## on the next commit.
  ## 
  ## The compositor can use this information to allow or disallow
  ## different states like maximize or fullscreen and draw accurate
  ## animations.
  ## 
  ## Similarly, a tiling window manager may use this information to
  ## place and resize client windows in a more effective way.
  ## 
  ## The client should not rely on the compositor to obey the maximum
  ## size. The compositor may decide to ignore the values set by the
  ## client and request a larger size.
  ## 
  ## If never set, or a value of zero in the request, means that the
  ## client has no expected maximum size in the given dimension.
  ## As a result, a client wishing to reset the maximum size
  ## to an unspecified state can use zero for width and height in the
  ## request.
  ## 
  ## Requesting a maximum size to be smaller than the minimum size of
  ## a surface is illegal and will result in an invalid_size error.
  ## 
  ## The width and height must be greater than or equal to zero. Using
  ## strictly negative values for width or height will result in a
  ## invalid_size error.
  let args = (width, height)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 7, nil, 1, 0, args.addr)

proc set_min_size*(this: Xdg_toplevel; width: int32; height: int32) =
  ## Set a minimum size for the window.
  ## 
  ## The client can specify a minimum size so that the compositor does
  ## not try to configure the window below this size.
  ## 
  ## The width and height arguments are in window geometry coordinates.
  ## See xdg_surface.set_window_geometry.
  ## 
  ## Values set in this way are double-buffered. They will get applied
  ## on the next commit.
  ## 
  ## The compositor can use this information to allow or disallow
  ## different states like maximize or fullscreen and draw accurate
  ## animations.
  ## 
  ## Similarly, a tiling window manager may use this information to
  ## place and resize client windows in a more effective way.
  ## 
  ## The client should not rely on the compositor to obey the minimum
  ## size. The compositor may decide to ignore the values set by the
  ## client and request a smaller size.
  ## 
  ## If never set, or a value of zero in the request, means that the
  ## client has no expected minimum size in the given dimension.
  ## As a result, a client wishing to reset the minimum size
  ## to an unspecified state can use zero for width and height in the
  ## request.
  ## 
  ## Requesting a minimum size to be larger than the maximum size of
  ## a surface is illegal and will result in an invalid_size error.
  ## 
  ## The width and height must be greater than or equal to zero. Using
  ## strictly negative values for width and height will result in a
  ## invalid_size error.
  let args = (width, height)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 8, nil, 1, 0, args.addr)

proc set_maximized*(this: Xdg_toplevel) =
  ## Maximize the surface.
  ## 
  ## After requesting that the surface should be maximized, the compositor
  ## will respond by emitting a configure event. Whether this configure
  ## actually sets the window maximized is subject to compositor policies.
  ## The client must then update its content, drawing in the configured
  ## state. The client must also acknowledge the configure when committing
  ## the new content (see ack_configure).
  ## 
  ## It is up to the compositor to decide how and where to maximize the
  ## surface, for example which output and what region of the screen should
  ## be used.
  ## 
  ## If the surface was already maximized, the compositor will still emit
  ## a configure event with the "maximized" state.
  ## 
  ## If the surface is in a fullscreen state, this request has no direct
  ## effect. It may alter the state the surface is returned to when
  ## unmaximized unless overridden by the compositor.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 9, nil, 1, 0, args.addr)

proc unset_maximized*(this: Xdg_toplevel) =
  ## Unmaximize the surface.
  ## 
  ## After requesting that the surface should be unmaximized, the compositor
  ## will respond by emitting a configure event. Whether this actually
  ## un-maximizes the window is subject to compositor policies.
  ## If available and applicable, the compositor will include the window
  ## geometry dimensions the window had prior to being maximized in the
  ## configure event. The client must then update its content, drawing it in
  ## the configured state. The client must also acknowledge the configure
  ## when committing the new content (see ack_configure).
  ## 
  ## It is up to the compositor to position the surface after it was
  ## unmaximized; usually the position the surface had before maximizing, if
  ## applicable.
  ## 
  ## If the surface was already not maximized, the compositor will still
  ## emit a configure event without the "maximized" state.
  ## 
  ## If the surface is in a fullscreen state, this request has no direct
  ## effect. It may alter the state the surface is returned to when
  ## unmaximized unless overridden by the compositor.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 10, nil, 1, 0, args.addr)

proc set_fullscreen*(this: Xdg_toplevel; output: Wl_output) =
  ## Make the surface fullscreen.
  ## 
  ## After requesting that the surface should be fullscreened, the
  ## compositor will respond by emitting a configure event. Whether the
  ## client is actually put into a fullscreen state is subject to compositor
  ## policies. The client must also acknowledge the configure when
  ## committing the new content (see ack_configure).
  ## 
  ## The output passed by the request indicates the client's preference as
  ## to which display it should be set fullscreen on. If this value is NULL,
  ## it's up to the compositor to choose which display will be used to map
  ## this surface.
  ## 
  ## If the surface doesn't cover the whole output, the compositor will
  ## position the surface in the center of the output and compensate with
  ## with border fill covering the rest of the output. The content of the
  ## border fill is undefined, but should be assumed to be in some way that
  ## attempts to blend into the surrounding area (e.g. solid black).
  ## 
  ## If the fullscreened surface is not opaque, the compositor must make
  ## sure that other screen content not part of the same surface tree (made
  ## up of subsurfaces, popups or similarly coupled surfaces) are not
  ## visible below the fullscreened surface.
  let args = (output,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 11, nil, 1, 0, args.addr)

proc unset_fullscreen*(this: Xdg_toplevel) =
  ## Make the surface no longer fullscreen.
  ## 
  ## After requesting that the surface should be unfullscreened, the
  ## compositor will respond by emitting a configure event.
  ## Whether this actually removes the fullscreen state of the client is
  ## subject to compositor policies.
  ## 
  ## Making a surface unfullscreen sets states for the surface based on the following:
  ## * the state(s) it may have had before becoming fullscreen
  ## * any state(s) decided by the compositor
  ## * any state(s) requested by the client while the surface was fullscreen
  ## 
  ## The compositor may include the previous window geometry dimensions in
  ## the configure event, if applicable.
  ## 
  ## The client must also acknowledge the configure when committing the new
  ## content (see ack_configure).
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 12, nil, 1, 0, args.addr)

proc set_minimized*(this: Xdg_toplevel) =
  ## Request that the compositor minimize your surface. There is no
  ## way to know if the surface is currently minimized, nor is there
  ## any way to unset minimization on this surface.
  ## 
  ## If you are looking to throttle redrawing when minimized, please
  ## instead use the wl_surface.frame event for this, as this will
  ## also work with live previews on windows in Alt-Tab, Expose or
  ## similar compositor features.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 13, nil, 1, 0, args.addr)

proc destroy*(this: Xdg_popup) =
  ## This destroys the popup. Explicitly destroying the xdg_popup
  ## object will also dismiss the popup, and unmap the surface.
  ## 
  ## If this xdg_popup is not the "topmost" popup, the
  ## xdg_wm_base.not_the_topmost_popup protocol error will be sent.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 1, args.addr)

proc grab*(this: Xdg_popup; seat: Wl_seat; serial: uint32) =
  ## This request makes the created popup take an explicit grab. An explicit
  ## grab will be dismissed when the user dismisses the popup, or when the
  ## client destroys the xdg_popup. This can be done by the user clicking
  ## outside the surface, using the keyboard, or even locking the screen
  ## through closing the lid or a timeout.
  ## 
  ## If the compositor denies the grab, the popup will be immediately
  ## dismissed.
  ## 
  ## This request must be used in response to some sort of user action like a
  ## button press, key press, or touch down event. The serial number of the
  ## event should be passed as 'serial'.
  ## 
  ## The parent of a grabbing popup must either be an xdg_toplevel surface or
  ## another xdg_popup with an explicit grab. If the parent is another
  ## xdg_popup it means that the popups are nested, with this popup now being
  ## the topmost popup.
  ## 
  ## Nested popups must be destroyed in the reverse order they were created
  ## in, e.g. the only popup you are allowed to destroy at all times is the
  ## topmost one.
  ## 
  ## When compositors choose to dismiss a popup, they may dismiss every
  ## nested grabbing popup as well. When a compositor dismisses popups, it
  ## will follow the same dismissing order as required from the client.
  ## 
  ## If the topmost grabbing popup is destroyed, the grab will be returned to
  ## the parent of the popup, if that parent previously had an explicit grab.
  ## 
  ## If the parent is a grabbing popup which has already been dismissed, this
  ## popup will be immediately dismissed. If the parent is a popup that did
  ## not take an explicit grab, an error will be raised.
  ## 
  ## During a popup grab, the client owning the grab will receive pointer
  ## and touch events for all their surfaces as normal (similar to an
  ## "owner-events" grab in X11 parlance), while the top most grabbing popup
  ## will always have keyboard focus.
  let args = (seat, serial)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 1, nil, 1, 0, args.addr)

proc reposition*(this: Xdg_popup; positioner: Xdg_positioner; token: uint32) =
  ## Reposition an already-mapped popup. The popup will be placed given the
  ## details in the passed xdg_positioner object, and a
  ## xdg_popup.repositioned followed by xdg_popup.configure and
  ## xdg_surface.configure will be emitted in response. Any parameters set
  ## by the previous positioner will be discarded.
  ## 
  ## The passed token will be sent in the corresponding
  ## xdg_popup.repositioned event. The new popup position will not take
  ## effect until the corresponding configure event is acknowledged by the
  ## client. See xdg_popup.repositioned for details. The token itself is
  ## opaque, and has no other special meaning.
  ## 
  ## If multiple reposition requests are sent, the compositor may skip all
  ## but the last one.
  ## 
  ## If the popup is repositioned in response to a configure event for its
  ## parent, the client should send an xdg_positioner.set_parent_configure
  ## and possibly an xdg_positioner.set_parent_size request to allow the
  ## compositor to properly constrain the popup.
  ## 
  ## If the popup is repositioned together with a parent that is being
  ## resized, but not in response to a configure event, the client should
  ## send an xdg_positioner.set_parent_size request.
  let args = (positioner, token)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 2, nil, 1, 0, args.addr)

proc sync*(this: Wl_display): Wl_callback =
  ## The sync request asks the server to emit the 'done' event
  ## on the returned wl_callback object.  Since requests are
  ## handled in-order and events are delivered in-order, this can
  ## be used as a barrier to ensure all previous requests and the
  ## resulting events have been handled.
  ## 
  ## The object returned by this request will be destroyed by the
  ## compositor after the callback is fired and as such the client must not
  ## attempt to use it after that point.
  ## 
  ## The callback_data passed in the callback is the event serial.
  let args = (0'u32,)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 0, Wl_callback.iface,
      1, 0, args.addr), Wl_callback, `Wl_callback / dispatch`,
            `Wl_callback / Callbacks`)

proc get_registry*(this: Wl_display): Wl_registry =
  ## This request creates a registry object that allows the client
  ## to list and bind the global objects available from the
  ## compositor.
  ## 
  ## It should be noted that the server side resources consumed in
  ## response to a get_registry request can only be released when the
  ## client disconnects, not when the client side proxy is destroyed.
  ## Therefore, clients should invoke get_registry as infrequently as
  ## possible to avoid wasting memory.
  let args = (0'u32,)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 1, Wl_registry.iface,
      1, 0, args.addr), Wl_registry, `Wl_registry / dispatch`,
            `Wl_registry / Callbacks`)

proc `bind`*(this: Wl_registry; name: uint32): uint32 =
  ## Binds a new, client-created object to the server using the
  ## specified name as the identifier.
  let args = (name, 0'u32)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 0, args.addr)

proc create_surface*(this: Wl_compositor): Wl_surface =
  ## Ask the compositor to create a new surface.
  let args = (0'u32,)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 0, Wl_surface.iface, 1,
      0, args.addr), Wl_surface, `Wl_surface / dispatch`, `Wl_surface / Callbacks`)

proc create_region*(this: Wl_compositor): Wl_region =
  ## Ask the compositor to create a new region.
  let args = (0'u32,)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 1, Wl_region.iface, 1,
      0, args.addr), Wl_region, `Wl_region / dispatch`, `Wl_region / Callbacks`)

proc create_buffer*(this: Wl_shm_pool; offset: int32; width: int32;
                    height: int32; stride: int32; format: `Wl_shm / Format`): Wl_buffer =
  ## Create a wl_buffer object from the pool.
  ## 
  ## The buffer is created offset bytes into the pool and has
  ## width and height as specified.  The stride argument specifies
  ## the number of bytes from the beginning of one row to the beginning
  ## of the next.  The format is the pixel format of the buffer and
  ## must be one of those advertised through the wl_shm.format event.
  ## 
  ## A buffer will keep a reference to the pool it was created from
  ## so it is valid to destroy the pool immediately after creating
  ## a buffer from it.
  let args = (0'u32, offset, width, height, stride, format)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 0, Wl_buffer.iface, 1,
      0, args.addr), Wl_buffer, `Wl_buffer / dispatch`, `Wl_buffer / Callbacks`)

proc destroy*(this: Wl_shm_pool) =
  ## Destroy the shared memory pool.
  ## 
  ## The mmapped memory will be released when all
  ## buffers that have been created from this pool
  ## are gone.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 1, nil, 1, 1, args.addr)

proc resize*(this: Wl_shm_pool; size: int32) =
  ## This request will cause the server to remap the backing memory
  ## for the pool from the file descriptor passed when the pool was
  ## created, but using the new size.  This request can only be
  ## used to make the pool bigger.
  ## 
  ## This request only changes the amount of bytes that are mmapped
  ## by the server and does not touch the file corresponding to the
  ## file descriptor passed at creation time. It is the client's
  ## responsibility to ensure that the file is at least as big as
  ## the new pool size.
  let args = (size,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 2, nil, 1, 0, args.addr)

proc create_pool*(this: Wl_shm; fd: FileHandle; size: int32): Wl_shm_pool =
  ## Create a new wl_shm_pool object.
  ## 
  ## The pool can be used to create shared memory based buffer
  ## objects.  The server will mmap size bytes of the passed file
  ## descriptor, to use as backing memory for the pool.
  let args = (0'u32, fd, size)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 0, Wl_shm_pool.iface,
      1, 0, args.addr), Wl_shm_pool, `Wl_shm_pool / dispatch`,
            `Wl_shm_pool / Callbacks`)

proc destroy*(this: Wl_buffer) =
  ## Destroy a buffer. If and how you need to release the backing
  ## storage is defined by the buffer factory interface.
  ## 
  ## For possible side-effects to a surface, see wl_surface.attach.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 1, args.addr)

proc accept*(this: Wl_data_offer; serial: uint32; mime_type: cstring) =
  ## Indicate that the client can accept the given mime type, or
  ## NULL for not accepted.
  ## 
  ## For objects of version 2 or older, this request is used by the
  ## client to give feedback whether the client can receive the given
  ## mime type, or NULL if none is accepted; the feedback does not
  ## determine whether the drag-and-drop operation succeeds or not.
  ## 
  ## For objects of version 3 or newer, this request determines the
  ## final result of the drag-and-drop operation. If the end result
  ## is that no mime types were accepted, the drag-and-drop operation
  ## will be cancelled and the corresponding drag source will receive
  ## wl_data_source.cancelled. Clients may still use this event in
  ## conjunction with wl_data_source.action for feedback.
  let args = (serial, mime_type)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 0, args.addr)

proc receive*(this: Wl_data_offer; mime_type: cstring; fd: FileHandle) =
  ## To transfer the offered data, the client issues this request
  ## and indicates the mime type it wants to receive.  The transfer
  ## happens through the passed file descriptor (typically created
  ## with the pipe system call).  The source client writes the data
  ## in the mime type representation requested and then closes the
  ## file descriptor.
  ## 
  ## The receiving client reads from the read end of the pipe until
  ## EOF and then closes its end, at which point the transfer is
  ## complete.
  ## 
  ## This request may happen multiple times for different mime types,
  ## both before and after wl_data_device.drop. Drag-and-drop destination
  ## clients may preemptively fetch data or examine it more closely to
  ## determine acceptance.
  let args = (mime_type, fd)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 1, nil, 1, 0, args.addr)

proc destroy*(this: Wl_data_offer) =
  ## Destroy the data offer.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 2, nil, 1, 1, args.addr)

proc finish*(this: Wl_data_offer) =
  ## Notifies the compositor that the drag destination successfully
  ## finished the drag-and-drop operation.
  ## 
  ## Upon receiving this request, the compositor will emit
  ## wl_data_source.dnd_finished on the drag source client.
  ## 
  ## It is a client error to perform other requests than
  ## wl_data_offer.destroy after this one. It is also an error to perform
  ## this request after a NULL mime type has been set in
  ## wl_data_offer.accept or no action was received through
  ## wl_data_offer.action.
  ## 
  ## If wl_data_offer.finish request is received for a non drag and drop
  ## operation, the invalid_finish protocol error is raised.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 3, nil, 1, 0, args.addr)

proc set_actions*(this: Wl_data_offer;
                  dnd_actions: `Wl_data_device_manager / Dnd_action`;
                  preferred_action: `Wl_data_device_manager / Dnd_action`) =
  ## Sets the actions that the destination side client supports for
  ## this operation. This request may trigger the emission of
  ## wl_data_source.action and wl_data_offer.action events if the compositor
  ## needs to change the selected action.
  ## 
  ## This request can be called multiple times throughout the
  ## drag-and-drop operation, typically in response to wl_data_device.enter
  ## or wl_data_device.motion events.
  ## 
  ## This request determines the final result of the drag-and-drop
  ## operation. If the end result is that no action is accepted,
  ## the drag source will receive wl_data_source.cancelled.
  ## 
  ## The dnd_actions argument must contain only values expressed in the
  ## wl_data_device_manager.dnd_actions enum, and the preferred_action
  ## argument must only contain one of those values set, otherwise it
  ## will result in a protocol error.
  ## 
  ## While managing an "ask" action, the destination drag-and-drop client
  ## may perform further wl_data_offer.receive requests, and is expected
  ## to perform one last wl_data_offer.set_actions request with a preferred
  ## action other than "ask" (and optionally wl_data_offer.accept) before
  ## requesting wl_data_offer.finish, in order to convey the action selected
  ## by the user. If the preferred action is not in the
  ## wl_data_offer.source_actions mask, an error will be raised.
  ## 
  ## If the "ask" action is dismissed (e.g. user cancellation), the client
  ## is expected to perform wl_data_offer.destroy right away.
  ## 
  ## This request can only be made on drag-and-drop offers, a protocol error
  ## will be raised otherwise.
  let args = (dnd_actions, preferred_action)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 4, nil, 1, 0, args.addr)

proc offer*(this: Wl_data_source; mime_type: cstring) =
  ## This request adds a mime type to the set of mime types
  ## advertised to targets.  Can be called several times to offer
  ## multiple types.
  let args = (mime_type,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 0, args.addr)

proc destroy*(this: Wl_data_source) =
  ## Destroy the data source.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 1, nil, 1, 1, args.addr)

proc set_actions*(this: Wl_data_source;
                  dnd_actions: `Wl_data_device_manager / Dnd_action`) =
  ## Sets the actions that the source side client supports for this
  ## operation. This request may trigger wl_data_source.action and
  ## wl_data_offer.action events if the compositor needs to change the
  ## selected action.
  ## 
  ## The dnd_actions argument must contain only values expressed in the
  ## wl_data_device_manager.dnd_actions enum, otherwise it will result
  ## in a protocol error.
  ## 
  ## This request must be made once only, and can only be made on sources
  ## used in drag-and-drop, so it must be performed before
  ## wl_data_device.start_drag. Attempting to use the source other than
  ## for drag-and-drop will raise a protocol error.
  let args = (dnd_actions,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 2, nil, 1, 0, args.addr)

proc start_drag*(this: Wl_data_device; source: Wl_data_source;
                 origin: Wl_surface; icon: Wl_surface; serial: uint32) =
  ## This request asks the compositor to start a drag-and-drop
  ## operation on behalf of the client.
  ## 
  ## The source argument is the data source that provides the data
  ## for the eventual data transfer. If source is NULL, enter, leave
  ## and motion events are sent only to the client that initiated the
  ## drag and the client is expected to handle the data passing
  ## internally. If source is destroyed, the drag-and-drop session will be
  ## cancelled.
  ## 
  ## The origin surface is the surface where the drag originates and
  ## the client must have an active implicit grab that matches the
  ## serial.
  ## 
  ## The icon surface is an optional (can be NULL) surface that
  ## provides an icon to be moved around with the cursor.  Initially,
  ## the top-left corner of the icon surface is placed at the cursor
  ## hotspot, but subsequent wl_surface.attach request can move the
  ## relative position. Attach requests must be confirmed with
  ## wl_surface.commit as usual. The icon surface is given the role of
  ## a drag-and-drop icon. If the icon surface already has another role,
  ## it raises a protocol error.
  ## 
  ## The input region is ignored for wl_surfaces with the role of a
  ## drag-and-drop icon.
  ## 
  ## The given source may not be used in any further set_selection or
  ## start_drag requests. Attempting to reuse a previously-used source
  ## may send a used_source error.
  let args = (source, origin, icon, serial)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 0, args.addr)

proc set_selection*(this: Wl_data_device; source: Wl_data_source; serial: uint32) =
  ## This request asks the compositor to set the selection
  ## to the data from the source on behalf of the client.
  ## 
  ## To unset the selection, set the source to NULL.
  ## 
  ## The given source may not be used in any further set_selection or
  ## start_drag requests. Attempting to reuse a previously-used source
  ## may send a used_source error.
  let args = (source, serial)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 1, nil, 1, 0, args.addr)

proc release*(this: Wl_data_device) =
  ## This request destroys the data device.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 2, nil, 1, 1, args.addr)

proc create_data_source*(this: Wl_data_device_manager): Wl_data_source =
  ## Create a new data source.
  let args = (0'u32,)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 0,
      Wl_data_source.iface, 1, 0, args.addr), Wl_data_source,
            `Wl_data_source / dispatch`, `Wl_data_source / Callbacks`)

proc get_data_device*(this: Wl_data_device_manager; seat: Wl_seat): Wl_data_device =
  ## Create a new data device for a given seat.
  let args = (0'u32, seat)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 1,
      Wl_data_device.iface, 1, 0, args.addr), Wl_data_device,
            `Wl_data_device / dispatch`, `Wl_data_device / Callbacks`)

proc get_shell_surface*(this: Wl_shell; surface: Wl_surface): Wl_shell_surface =
  ## Create a shell surface for an existing surface. This gives
  ## the wl_surface the role of a shell surface. If the wl_surface
  ## already has another role, it raises a protocol error.
  ## 
  ## Only one shell surface can be associated with a given surface.
  let args = (0'u32, surface)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 0,
      Wl_shell_surface.iface, 1, 0, args.addr), Wl_shell_surface,
            `Wl_shell_surface / dispatch`, `Wl_shell_surface / Callbacks`)

proc pong*(this: Wl_shell_surface; serial: uint32) =
  ## A client must respond to a ping event with a pong request or
  ## the client may be deemed unresponsive.
  let args = (serial,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 0, args.addr)

proc move*(this: Wl_shell_surface; seat: Wl_seat; serial: uint32) =
  ## Start a pointer-driven move of the surface.
  ## 
  ## This request must be used in response to a button press event.
  ## The server may ignore move requests depending on the state of
  ## the surface (e.g. fullscreen or maximized).
  let args = (seat, serial)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 1, nil, 1, 0, args.addr)

proc resize*(this: Wl_shell_surface; seat: Wl_seat; serial: uint32;
             edges: `Wl_shell_surface / Resize`) =
  ## Start a pointer-driven resizing of the surface.
  ## 
  ## This request must be used in response to a button press event.
  ## The server may ignore resize requests depending on the state of
  ## the surface (e.g. fullscreen or maximized).
  let args = (seat, serial, edges)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 2, nil, 1, 0, args.addr)

proc set_toplevel*(this: Wl_shell_surface) =
  ## Map the surface as a toplevel surface.
  ## 
  ## A toplevel surface is not fullscreen, maximized or transient.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 3, nil, 1, 0, args.addr)

proc set_transient*(this: Wl_shell_surface; parent: Wl_surface; x: int32;
                    y: int32; flags: `Wl_shell_surface / Transient`) =
  ## Map the surface relative to an existing surface.
  ## 
  ## The x and y arguments specify the location of the upper left
  ## corner of the surface relative to the upper left corner of the
  ## parent surface, in surface-local coordinates.
  ## 
  ## The flags argument controls details of the transient behaviour.
  let args = (parent, x, y, flags)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 4, nil, 1, 0, args.addr)

proc set_fullscreen*(this: Wl_shell_surface;
                     `method`: `Wl_shell_surface / Fullscreen_method`;
                     framerate: uint32; output: Wl_output) =
  ## Map the surface as a fullscreen surface.
  ## 
  ## If an output parameter is given then the surface will be made
  ## fullscreen on that output. If the client does not specify the
  ## output then the compositor will apply its policy - usually
  ## choosing the output on which the surface has the biggest surface
  ## area.
  ## 
  ## The client may specify a method to resolve a size conflict
  ## between the output size and the surface size - this is provided
  ## through the method parameter.
  ## 
  ## The framerate parameter is used only when the method is set
  ## to "driver", to indicate the preferred framerate. A value of 0
  ## indicates that the client does not care about framerate.  The
  ## framerate is specified in mHz, that is framerate of 60000 is 60Hz.
  ## 
  ## A method of "scale" or "driver" implies a scaling operation of
  ## the surface, either via a direct scaling operation or a change of
  ## the output mode. This will override any kind of output scaling, so
  ## that mapping a surface with a buffer size equal to the mode can
  ## fill the screen independent of buffer_scale.
  ## 
  ## A method of "fill" means we don't scale up the buffer, however
  ## any output scale is applied. This means that you may run into
  ## an edge case where the application maps a buffer with the same
  ## size of the output mode but buffer_scale 1 (thus making a
  ## surface larger than the output). In this case it is allowed to
  ## downscale the results to fit the screen.
  ## 
  ## The compositor must reply to this request with a configure event
  ## with the dimensions for the output on which the surface will
  ## be made fullscreen.
  let args = (`method`, framerate, output)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 5, nil, 1, 0, args.addr)

proc set_popup*(this: Wl_shell_surface; seat: Wl_seat; serial: uint32;
                parent: Wl_surface; x: int32; y: int32;
                flags: `Wl_shell_surface / Transient`) =
  ## Map the surface as a popup.
  ## 
  ## A popup surface is a transient surface with an added pointer
  ## grab.
  ## 
  ## An existing implicit grab will be changed to owner-events mode,
  ## and the popup grab will continue after the implicit grab ends
  ## (i.e. releasing the mouse button does not cause the popup to
  ## be unmapped).
  ## 
  ## The popup grab continues until the window is destroyed or a
  ## mouse button is pressed in any other client's window. A click
  ## in any of the client's surfaces is reported as normal, however,
  ## clicks in other clients' surfaces will be discarded and trigger
  ## the callback.
  ## 
  ## The x and y arguments specify the location of the upper left
  ## corner of the surface relative to the upper left corner of the
  ## parent surface, in surface-local coordinates.
  let args = (seat, serial, parent, x, y, flags)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 6, nil, 1, 0, args.addr)

proc set_maximized*(this: Wl_shell_surface; output: Wl_output) =
  ## Map the surface as a maximized surface.
  ## 
  ## If an output parameter is given then the surface will be
  ## maximized on that output. If the client does not specify the
  ## output then the compositor will apply its policy - usually
  ## choosing the output on which the surface has the biggest surface
  ## area.
  ## 
  ## The compositor will reply with a configure event telling
  ## the expected new surface size. The operation is completed
  ## on the next buffer attach to this surface.
  ## 
  ## A maximized surface typically fills the entire output it is
  ## bound to, except for desktop elements such as panels. This is
  ## the main difference between a maximized shell surface and a
  ## fullscreen shell surface.
  ## 
  ## The details depend on the compositor implementation.
  let args = (output,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 7, nil, 1, 0, args.addr)

proc set_title*(this: Wl_shell_surface; title: cstring) =
  ## Set a short title for the surface.
  ## 
  ## This string may be used to identify the surface in a task bar,
  ## window list, or other user interface elements provided by the
  ## compositor.
  ## 
  ## The string must be encoded in UTF-8.
  let args = (title,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 8, nil, 1, 0, args.addr)

proc set_class*(this: Wl_shell_surface; class: cstring) =
  ## Set a class for the surface.
  ## 
  ## The surface class identifies the general class of applications
  ## to which the surface belongs. A common convention is to use the
  ## file name (or the full path if it is a non-standard location) of
  ## the application's .desktop file as the class.
  let args = (class,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 9, nil, 1, 0, args.addr)

proc destroy*(this: Wl_surface) =
  ## Deletes the surface and invalidates its object ID.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 1, args.addr)

proc attach*(this: Wl_surface; buffer: Wl_buffer; x: int32; y: int32) =
  ## Set a buffer as the content of this surface.
  ## 
  ## The new size of the surface is calculated based on the buffer
  ## size transformed by the inverse buffer_transform and the
  ## inverse buffer_scale. This means that at commit time the supplied
  ## buffer size must be an integer multiple of the buffer_scale. If
  ## that's not the case, an invalid_size error is sent.
  ## 
  ## The x and y arguments specify the location of the new pending
  ## buffer's upper left corner, relative to the current buffer's upper
  ## left corner, in surface-local coordinates. In other words, the
  ## x and y, combined with the new surface size define in which
  ## directions the surface's size changes. Setting anything other than 0
  ## as x and y arguments is discouraged, and should instead be replaced
  ## with using the separate wl_surface.offset request.
  ## 
  ## When the bound wl_surface version is 5 or higher, passing any
  ## non-zero x or y is a protocol violation, and will result in an
  ## 'invalid_offset' error being raised. The x and y arguments are ignored
  ## and do not change the pending state. To achieve equivalent semantics,
  ## use wl_surface.offset.
  ## 
  ## Surface contents are double-buffered state, see wl_surface.commit.
  ## 
  ## The initial surface contents are void; there is no content.
  ## wl_surface.attach assigns the given wl_buffer as the pending
  ## wl_buffer. wl_surface.commit makes the pending wl_buffer the new
  ## surface contents, and the size of the surface becomes the size
  ## calculated from the wl_buffer, as described above. After commit,
  ## there is no pending buffer until the next attach.
  ## 
  ## Committing a pending wl_buffer allows the compositor to read the
  ## pixels in the wl_buffer. The compositor may access the pixels at
  ## any time after the wl_surface.commit request. When the compositor
  ## will not access the pixels anymore, it will send the
  ## wl_buffer.release event. Only after receiving wl_buffer.release,
  ## the client may reuse the wl_buffer. A wl_buffer that has been
  ## attached and then replaced by another attach instead of committed
  ## will not receive a release event, and is not used by the
  ## compositor.
  ## 
  ## If a pending wl_buffer has been committed to more than one wl_surface,
  ## the delivery of wl_buffer.release events becomes undefined. A well
  ## behaved client should not rely on wl_buffer.release events in this
  ## case. Alternatively, a client could create multiple wl_buffer objects
  ## from the same backing storage or use wp_linux_buffer_release.
  ## 
  ## Destroying the wl_buffer after wl_buffer.release does not change
  ## the surface contents. Destroying the wl_buffer before wl_buffer.release
  ## is allowed as long as the underlying buffer storage isn't re-used (this
  ## can happen e.g. on client process termination). However, if the client
  ## destroys the wl_buffer before receiving the wl_buffer.release event and
  ## mutates the underlying buffer storage, the surface contents become
  ## undefined immediately.
  ## 
  ## If wl_surface.attach is sent with a NULL wl_buffer, the
  ## following wl_surface.commit will remove the surface content.
  let args = (buffer, x, y)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 1, nil, 1, 0, args.addr)

proc damage*(this: Wl_surface; x: int32; y: int32; width: int32; height: int32) =
  ## This request is used to describe the regions where the pending
  ## buffer is different from the current surface contents, and where
  ## the surface therefore needs to be repainted. The compositor
  ## ignores the parts of the damage that fall outside of the surface.
  ## 
  ## Damage is double-buffered state, see wl_surface.commit.
  ## 
  ## The damage rectangle is specified in surface-local coordinates,
  ## where x and y specify the upper left corner of the damage rectangle.
  ## 
  ## The initial value for pending damage is empty: no damage.
  ## wl_surface.damage adds pending damage: the new pending damage
  ## is the union of old pending damage and the given rectangle.
  ## 
  ## wl_surface.commit assigns pending damage as the current damage,
  ## and clears pending damage. The server will clear the current
  ## damage as it repaints the surface.
  ## 
  ## Note! New clients should not use this request. Instead damage can be
  ## posted with wl_surface.damage_buffer which uses buffer coordinates
  ## instead of surface coordinates.
  let args = (x, y, width, height)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 2, nil, 1, 0, args.addr)

proc frame*(this: Wl_surface): Wl_callback =
  ## Request a notification when it is a good time to start drawing a new
  ## frame, by creating a frame callback. This is useful for throttling
  ## redrawing operations, and driving animations.
  ## 
  ## When a client is animating on a wl_surface, it can use the 'frame'
  ## request to get notified when it is a good time to draw and commit the
  ## next frame of animation. If the client commits an update earlier than
  ## that, it is likely that some updates will not make it to the display,
  ## and the client is wasting resources by drawing too often.
  ## 
  ## The frame request will take effect on the next wl_surface.commit.
  ## The notification will only be posted for one frame unless
  ## requested again. For a wl_surface, the notifications are posted in
  ## the order the frame requests were committed.
  ## 
  ## The server must send the notifications so that a client
  ## will not send excessive updates, while still allowing
  ## the highest possible update rate for clients that wait for the reply
  ## before drawing again. The server should give some time for the client
  ## to draw and commit after sending the frame callback events to let it
  ## hit the next output refresh.
  ## 
  ## A server should avoid signaling the frame callbacks if the
  ## surface is not visible in any way, e.g. the surface is off-screen,
  ## or completely obscured by other opaque surfaces.
  ## 
  ## The object returned by this request will be destroyed by the
  ## compositor after the callback is fired and as such the client must not
  ## attempt to use it after that point.
  ## 
  ## The callback_data passed in the callback is the current time, in
  ## milliseconds, with an undefined base.
  let args = (0'u32,)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 3, Wl_callback.iface,
      1, 0, args.addr), Wl_callback, `Wl_callback / dispatch`,
            `Wl_callback / Callbacks`)

proc set_opaque_region*(this: Wl_surface; region: Wl_region) =
  ## This request sets the region of the surface that contains
  ## opaque content.
  ## 
  ## The opaque region is an optimization hint for the compositor
  ## that lets it optimize the redrawing of content behind opaque
  ## regions.  Setting an opaque region is not required for correct
  ## behaviour, but marking transparent content as opaque will result
  ## in repaint artifacts.
  ## 
  ## The opaque region is specified in surface-local coordinates.
  ## 
  ## The compositor ignores the parts of the opaque region that fall
  ## outside of the surface.
  ## 
  ## Opaque region is double-buffered state, see wl_surface.commit.
  ## 
  ## wl_surface.set_opaque_region changes the pending opaque region.
  ## wl_surface.commit copies the pending region to the current region.
  ## Otherwise, the pending and current regions are never changed.
  ## 
  ## The initial value for an opaque region is empty. Setting the pending
  ## opaque region has copy semantics, and the wl_region object can be
  ## destroyed immediately. A NULL wl_region causes the pending opaque
  ## region to be set to empty.
  let args = (region,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 4, nil, 1, 0, args.addr)

proc set_input_region*(this: Wl_surface; region: Wl_region) =
  ## This request sets the region of the surface that can receive
  ## pointer and touch events.
  ## 
  ## Input events happening outside of this region will try the next
  ## surface in the server surface stack. The compositor ignores the
  ## parts of the input region that fall outside of the surface.
  ## 
  ## The input region is specified in surface-local coordinates.
  ## 
  ## Input region is double-buffered state, see wl_surface.commit.
  ## 
  ## wl_surface.set_input_region changes the pending input region.
  ## wl_surface.commit copies the pending region to the current region.
  ## Otherwise the pending and current regions are never changed,
  ## except cursor and icon surfaces are special cases, see
  ## wl_pointer.set_cursor and wl_data_device.start_drag.
  ## 
  ## The initial value for an input region is infinite. That means the
  ## whole surface will accept input. Setting the pending input region
  ## has copy semantics, and the wl_region object can be destroyed
  ## immediately. A NULL wl_region causes the input region to be set
  ## to infinite.
  let args = (region,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 5, nil, 1, 0, args.addr)

proc commit*(this: Wl_surface) =
  ## Surface state (input, opaque, and damage regions, attached buffers,
  ## etc.) is double-buffered. Protocol requests modify the pending state,
  ## as opposed to the current state in use by the compositor. A commit
  ## request atomically applies all pending state, replacing the current
  ## state. After commit, the new pending state is as documented for each
  ## related request.
  ## 
  ## On commit, a pending wl_buffer is applied first, and all other state
  ## second. This means that all coordinates in double-buffered state are
  ## relative to the new wl_buffer coming into use, except for
  ## wl_surface.attach itself. If there is no pending wl_buffer, the
  ## coordinates are relative to the current surface contents.
  ## 
  ## All requests that need a commit to become effective are documented
  ## to affect double-buffered state.
  ## 
  ## Other interfaces may add further double-buffered surface state.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 6, nil, 1, 0, args.addr)

proc set_buffer_transform*(this: Wl_surface; transform: `Wl_output / Transform`) =
  ## This request sets an optional transformation on how the compositor
  ## interprets the contents of the buffer attached to the surface. The
  ## accepted values for the transform parameter are the values for
  ## wl_output.transform.
  ## 
  ## Buffer transform is double-buffered state, see wl_surface.commit.
  ## 
  ## A newly created surface has its buffer transformation set to normal.
  ## 
  ## wl_surface.set_buffer_transform changes the pending buffer
  ## transformation. wl_surface.commit copies the pending buffer
  ## transformation to the current one. Otherwise, the pending and current
  ## values are never changed.
  ## 
  ## The purpose of this request is to allow clients to render content
  ## according to the output transform, thus permitting the compositor to
  ## use certain optimizations even if the display is rotated. Using
  ## hardware overlays and scanning out a client buffer for fullscreen
  ## surfaces are examples of such optimizations. Those optimizations are
  ## highly dependent on the compositor implementation, so the use of this
  ## request should be considered on a case-by-case basis.
  ## 
  ## Note that if the transform value includes 90 or 270 degree rotation,
  ## the width of the buffer will become the surface height and the height
  ## of the buffer will become the surface width.
  ## 
  ## If transform is not one of the values from the
  ## wl_output.transform enum the invalid_transform protocol error
  ## is raised.
  let args = (transform,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 7, nil, 1, 0, args.addr)

proc set_buffer_scale*(this: Wl_surface; scale: int32) =
  ## This request sets an optional scaling factor on how the compositor
  ## interprets the contents of the buffer attached to the window.
  ## 
  ## Buffer scale is double-buffered state, see wl_surface.commit.
  ## 
  ## A newly created surface has its buffer scale set to 1.
  ## 
  ## wl_surface.set_buffer_scale changes the pending buffer scale.
  ## wl_surface.commit copies the pending buffer scale to the current one.
  ## Otherwise, the pending and current values are never changed.
  ## 
  ## The purpose of this request is to allow clients to supply higher
  ## resolution buffer data for use on high resolution outputs. It is
  ## intended that you pick the same buffer scale as the scale of the
  ## output that the surface is displayed on. This means the compositor
  ## can avoid scaling when rendering the surface on that output.
  ## 
  ## Note that if the scale is larger than 1, then you have to attach
  ## a buffer that is larger (by a factor of scale in each dimension)
  ## than the desired surface size.
  ## 
  ## If scale is not positive the invalid_scale protocol error is
  ## raised.
  let args = (scale,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 8, nil, 1, 0, args.addr)

proc damage_buffer*(this: Wl_surface; x: int32; y: int32; width: int32;
                    height: int32) =
  ## This request is used to describe the regions where the pending
  ## buffer is different from the current surface contents, and where
  ## the surface therefore needs to be repainted. The compositor
  ## ignores the parts of the damage that fall outside of the surface.
  ## 
  ## Damage is double-buffered state, see wl_surface.commit.
  ## 
  ## The damage rectangle is specified in buffer coordinates,
  ## where x and y specify the upper left corner of the damage rectangle.
  ## 
  ## The initial value for pending damage is empty: no damage.
  ## wl_surface.damage_buffer adds pending damage: the new pending
  ## damage is the union of old pending damage and the given rectangle.
  ## 
  ## wl_surface.commit assigns pending damage as the current damage,
  ## and clears pending damage. The server will clear the current
  ## damage as it repaints the surface.
  ## 
  ## This request differs from wl_surface.damage in only one way - it
  ## takes damage in buffer coordinates instead of surface-local
  ## coordinates. While this generally is more intuitive than surface
  ## coordinates, it is especially desirable when using wp_viewport
  ## or when a drawing library (like EGL) is unaware of buffer scale
  ## and buffer transform.
  ## 
  ## Note: Because buffer transformation changes and damage requests may
  ## be interleaved in the protocol stream, it is impossible to determine
  ## the actual mapping between surface and buffer damage until
  ## wl_surface.commit time. Therefore, compositors wishing to take both
  ## kinds of damage into account will have to accumulate damage from the
  ## two requests separately and only transform from one to the other
  ## after receiving the wl_surface.commit.
  let args = (x, y, width, height)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 9, nil, 1, 0, args.addr)

proc offset*(this: Wl_surface; x: int32; y: int32) =
  ## The x and y arguments specify the location of the new pending
  ## buffer's upper left corner, relative to the current buffer's upper
  ## left corner, in surface-local coordinates. In other words, the
  ## x and y, combined with the new surface size define in which
  ## directions the surface's size changes.
  ## 
  ## Surface location offset is double-buffered state, see
  ## wl_surface.commit.
  ## 
  ## This request is semantically equivalent to and the replaces the x and y
  ## arguments in the wl_surface.attach request in wl_surface versions prior
  ## to 5. See wl_surface.attach for details.
  let args = (x, y)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 10, nil, 1, 0, args.addr)

proc get_pointer*(this: Wl_seat): Wl_pointer =
  ## The ID provided will be initialized to the wl_pointer interface
  ## for this seat.
  ## 
  ## This request only takes effect if the seat has the pointer
  ## capability, or has had the pointer capability in the past.
  ## It is a protocol violation to issue this request on a seat that has
  ## never had the pointer capability. The missing_capability error will
  ## be sent in this case.
  let args = (0'u32,)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 0, Wl_pointer.iface, 1,
      0, args.addr), Wl_pointer, `Wl_pointer / dispatch`, `Wl_pointer / Callbacks`)

proc get_keyboard*(this: Wl_seat): Wl_keyboard =
  ## The ID provided will be initialized to the wl_keyboard interface
  ## for this seat.
  ## 
  ## This request only takes effect if the seat has the keyboard
  ## capability, or has had the keyboard capability in the past.
  ## It is a protocol violation to issue this request on a seat that has
  ## never had the keyboard capability. The missing_capability error will
  ## be sent in this case.
  let args = (0'u32,)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 1, Wl_keyboard.iface,
      1, 0, args.addr), Wl_keyboard, `Wl_keyboard / dispatch`,
            `Wl_keyboard / Callbacks`)

proc get_touch*(this: Wl_seat): Wl_touch =
  ## The ID provided will be initialized to the wl_touch interface
  ## for this seat.
  ## 
  ## This request only takes effect if the seat has the touch
  ## capability, or has had the touch capability in the past.
  ## It is a protocol violation to issue this request on a seat that has
  ## never had the touch capability. The missing_capability error will
  ## be sent in this case.
  let args = (0'u32,)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 2, Wl_touch.iface, 1,
      0, args.addr), Wl_touch, `Wl_touch / dispatch`, `Wl_touch / Callbacks`)

proc release*(this: Wl_seat) =
  ## Using this request a client can tell the server that it is not going to
  ## use the seat object anymore.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 3, nil, 1, 1, args.addr)

proc set_cursor*(this: Wl_pointer; serial: uint32; surface: Wl_surface;
                 hotspot_x: int32; hotspot_y: int32) =
  ## Set the pointer surface, i.e., the surface that contains the
  ## pointer image (cursor). This request gives the surface the role
  ## of a cursor. If the surface already has another role, it raises
  ## a protocol error.
  ## 
  ## The cursor actually changes only if the pointer
  ## focus for this device is one of the requesting client's surfaces
  ## or the surface parameter is the current pointer surface. If
  ## there was a previous surface set with this request it is
  ## replaced. If surface is NULL, the pointer image is hidden.
  ## 
  ## The parameters hotspot_x and hotspot_y define the position of
  ## the pointer surface relative to the pointer location. Its
  ## top-left corner is always at (x, y) - (hotspot_x, hotspot_y),
  ## where (x, y) are the coordinates of the pointer location, in
  ## surface-local coordinates.
  ## 
  ## On wl_surface.offset requests to the pointer surface, hotspot_x
  ## and hotspot_y are decremented by the x and y parameters
  ## passed to the request. The offset must be applied by
  ## wl_surface.commit as usual.
  ## 
  ## The hotspot can also be updated by passing the currently set
  ## pointer surface to this request with new values for hotspot_x
  ## and hotspot_y.
  ## 
  ## The input region is ignored for wl_surfaces with the role of
  ## a cursor. When the use as a cursor ends, the wl_surface is
  ## unmapped.
  ## 
  ## The serial parameter must match the latest wl_pointer.enter
  ## serial number sent to the client. Otherwise the request will be
  ## ignored.
  let args = (serial, surface, hotspot_x, hotspot_y)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 0, args.addr)

proc release*(this: Wl_pointer) =
  ## Using this request a client can tell the server that it is not going to
  ## use the pointer object anymore.
  ## 
  ## This request destroys the pointer proxy object, so clients must not call
  ## wl_pointer_destroy() after using this request.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 1, nil, 1, 1, args.addr)

proc release*(this: Wl_keyboard) =
  ## release the keyboard object
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 1, args.addr)

proc release*(this: Wl_touch) =
  ## release the touch object
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 1, args.addr)

proc release*(this: Wl_output) =
  ## Using this request a client can tell the server that it is not going to
  ## use the output object anymore.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 1, args.addr)

proc destroy*(this: Wl_region) =
  ## Destroy the region.  This will invalidate the object ID.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 1, args.addr)

proc add*(this: Wl_region; x: int32; y: int32; width: int32; height: int32) =
  ## Add the specified rectangle to the region.
  let args = (x, y, width, height)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 1, nil, 1, 0, args.addr)

proc subtract*(this: Wl_region; x: int32; y: int32; width: int32; height: int32) =
  ## Subtract the specified rectangle from the region.
  let args = (x, y, width, height)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 2, nil, 1, 0, args.addr)

proc destroy*(this: Wl_subcompositor) =
  ## Informs the server that the client will not be using this
  ## protocol object anymore. This does not affect any other
  ## objects, wl_subsurface objects included.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 1, args.addr)

proc get_subsurface*(this: Wl_subcompositor; surface: Wl_surface;
                     parent: Wl_surface): Wl_subsurface =
  ## Create a sub-surface interface for the given surface, and
  ## associate it with the given parent surface. This turns a
  ## plain wl_surface into a sub-surface.
  ## 
  ## The to-be sub-surface must not already have another role, and it
  ## must not have an existing wl_subsurface object. Otherwise the
  ## bad_surface protocol error is raised.
  ## 
  ## Adding sub-surfaces to a parent is a double-buffered operation on the
  ## parent (see wl_surface.commit). The effect of adding a sub-surface
  ## becomes visible on the next time the state of the parent surface is
  ## applied.
  ## 
  ## The parent surface must not be one of the child surface's descendants,
  ## and the parent must be different from the child surface, otherwise the
  ## bad_parent protocol error is raised.
  ## 
  ## This request modifies the behaviour of wl_surface.commit request on
  ## the sub-surface, see the documentation on wl_subsurface interface.
  let args = (0'u32, surface, parent)
  construct(wl_proxy_marshal_array_flags(this.proxy.raw, 1, Wl_subsurface.iface,
      1, 0, args.addr), Wl_subsurface, `Wl_subsurface / dispatch`,
            `Wl_subsurface / Callbacks`)

proc destroy*(this: Wl_subsurface) =
  ## The sub-surface interface is removed from the wl_surface object
  ## that was turned into a sub-surface with a
  ## wl_subcompositor.get_subsurface request. The wl_surface's association
  ## to the parent is deleted. The wl_surface is unmapped immediately.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 0, nil, 1, 1, args.addr)

proc set_position*(this: Wl_subsurface; x: int32; y: int32) =
  ## This schedules a sub-surface position change.
  ## The sub-surface will be moved so that its origin (top left
  ## corner pixel) will be at the location x, y of the parent surface
  ## coordinate system. The coordinates are not restricted to the parent
  ## surface area. Negative values are allowed.
  ## 
  ## The scheduled coordinates will take effect whenever the state of the
  ## parent surface is applied. When this happens depends on whether the
  ## parent surface is in synchronized mode or not. See
  ## wl_subsurface.set_sync and wl_subsurface.set_desync for details.
  ## 
  ## If more than one set_position request is invoked by the client before
  ## the commit of the parent surface, the position of a new request always
  ## replaces the scheduled position from any previous request.
  ## 
  ## The initial position is 0, 0.
  let args = (x, y)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 1, nil, 1, 0, args.addr)

proc place_above*(this: Wl_subsurface; sibling: Wl_surface) =
  ## This sub-surface is taken from the stack, and put back just
  ## above the reference surface, changing the z-order of the sub-surfaces.
  ## The reference surface must be one of the sibling surfaces, or the
  ## parent surface. Using any other surface, including this sub-surface,
  ## will cause a protocol error.
  ## 
  ## The z-order is double-buffered. Requests are handled in order and
  ## applied immediately to a pending state. The final pending state is
  ## copied to the active state the next time the state of the parent
  ## surface is applied. When this happens depends on whether the parent
  ## surface is in synchronized mode or not. See wl_subsurface.set_sync and
  ## wl_subsurface.set_desync for details.
  ## 
  ## A new sub-surface is initially added as the top-most in the stack
  ## of its siblings and parent.
  let args = (sibling,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 2, nil, 1, 0, args.addr)

proc place_below*(this: Wl_subsurface; sibling: Wl_surface) =
  ## The sub-surface is placed just below the reference surface.
  ## See wl_subsurface.place_above.
  let args = (sibling,)
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 3, nil, 1, 0, args.addr)

proc set_sync*(this: Wl_subsurface) =
  ## Change the commit behaviour of the sub-surface to synchronized
  ## mode, also described as the parent dependent mode.
  ## 
  ## In synchronized mode, wl_surface.commit on a sub-surface will
  ## accumulate the committed state in a cache, but the state will
  ## not be applied and hence will not change the compositor output.
  ## The cached state is applied to the sub-surface immediately after
  ## the parent surface's state is applied. This ensures atomic
  ## updates of the parent and all its synchronized sub-surfaces.
  ## Applying the cached state will invalidate the cache, so further
  ## parent surface commits do not (re-)apply old state.
  ## 
  ## See wl_subsurface for the recursive effect of this mode.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 4, nil, 1, 0, args.addr)

proc set_desync*(this: Wl_subsurface) =
  ## Change the commit behaviour of the sub-surface to desynchronized
  ## mode, also described as independent or freely running mode.
  ## 
  ## In desynchronized mode, wl_surface.commit on a sub-surface will
  ## apply the pending state directly, without caching, as happens
  ## normally with a wl_surface. Calling wl_surface.commit on the
  ## parent surface has no effect on the sub-surface's wl_surface
  ## state. This mode allows a sub-surface to be updated on its own.
  ## 
  ## If cached state exists when wl_surface.commit is called in
  ## desynchronized mode, the pending state is added to the cached
  ## state, and applied as a whole. This invalidates the cache.
  ## 
  ## Note: even if a sub-surface is set to desynchronized, a parent
  ## sub-surface may override it to behave as synchronized. For details,
  ## see wl_subsurface.
  ## 
  ## If a surface's parent surface behaves as desynchronized, then
  ## the cached state is applied on set_desync.
  let args = ()
  discard wl_proxy_marshal_array_flags(this.proxy.raw, 5, nil, 1, 0, args.addr)

template onPing*(this: Xdg_wm_base; body) =
  ## The ping event asks the client if it's still alive. Pass the
  ## serial specified in the event back to the compositor by sending
  ## a "pong" request back with the specified serial. See xdg_wm_base.pong.
  ## 
  ## Compositors can use this to determine if the client is still
  ## alive. It's unspecified what will happen if the client doesn't
  ## respond to the ping request, or in what timeframe. Clients should
  ## try to respond in a reasonable amount of time. The “unresponsive”
  ## error is provided for compositors that wish to disconnect unresponsive
  ## clients.
  ## 
  ## A compositor is free to ping in any way it wants, but a client must
  ## always respond to any xdg_wm_base object it created.
  cast[ptr `Xdg_wm_base / Callbacks`](this.proxy.raw.impl).ping = proc (
      serial {.inject.}: uint32) =
    body

template onConfigure*(this: Xdg_surface; body) =
  ## The configure event marks the end of a configure sequence. A configure
  ## sequence is a set of one or more events configuring the state of the
  ## xdg_surface, including the final xdg_surface.configure event.
  ## 
  ## Where applicable, xdg_surface surface roles will during a configure
  ## sequence extend this event as a latched state sent as events before the
  ## xdg_surface.configure event. Such events should be considered to make up
  ## a set of atomically applied configuration states, where the
  ## xdg_surface.configure commits the accumulated state.
  ## 
  ## Clients should arrange their surface for the new states, and then send
  ## an ack_configure request with the serial sent in this configure event at
  ## some point before committing the new surface.
  ## 
  ## If the client receives multiple configure events before it can respond
  ## to one, it is free to discard all but the last event it received.
  cast[ptr `Xdg_surface / Callbacks`](this.proxy.raw.impl).configure = proc (
      serial {.inject.}: uint32) =
    body

template onConfigure*(this: Xdg_toplevel; body) =
  ## This configure event asks the client to resize its toplevel surface or
  ## to change its state. The configured state should not be applied
  ## immediately. See xdg_surface.configure for details.
  ## 
  ## The width and height arguments specify a hint to the window
  ## about how its surface should be resized in window geometry
  ## coordinates. See set_window_geometry.
  ## 
  ## If the width or height arguments are zero, it means the client
  ## should decide its own window dimension. This may happen when the
  ## compositor needs to configure the state of the surface but doesn't
  ## have any information about any previous or expected dimension.
  ## 
  ## The states listed in the event specify how the width/height
  ## arguments should be interpreted, and possibly how it should be
  ## drawn.
  ## 
  ## Clients must send an ack_configure in response to this event. See
  ## xdg_surface.configure and xdg_surface.ack_configure for details.
  cast[ptr `Xdg_toplevel / Callbacks`](this.proxy.raw.impl).configure = proc (
      width {.inject.}: int32; height {.inject.}: int32;
      states {.inject.}: Wl_array) =
    body

template onClose*(this: Xdg_toplevel; body) =
  ## The close event is sent by the compositor when the user
  ## wants the surface to be closed. This should be equivalent to
  ## the user clicking the close button in client-side decorations,
  ## if your application has any.
  ## 
  ## This is only a request that the user intends to close the
  ## window. The client may choose to ignore this request, or show
  ## a dialog to ask the user to save their data, etc.
  cast[ptr `Xdg_toplevel / Callbacks`](this.proxy.raw.impl).close = proc () =
    body

template onConfigure_bounds*(this: Xdg_toplevel; body) =
  ## The configure_bounds event may be sent prior to a xdg_toplevel.configure
  ## event to communicate the bounds a window geometry size is recommended
  ## to constrain to.
  ## 
  ## The passed width and height are in surface coordinate space. If width
  ## and height are 0, it means bounds is unknown and equivalent to as if no
  ## configure_bounds event was ever sent for this surface.
  ## 
  ## The bounds can for example correspond to the size of a monitor excluding
  ## any panels or other shell components, so that a surface isn't created in
  ## a way that it cannot fit.
  ## 
  ## The bounds may change at any point, and in such a case, a new
  ## xdg_toplevel.configure_bounds will be sent, followed by
  ## xdg_toplevel.configure and xdg_surface.configure.
  cast[ptr `Xdg_toplevel / Callbacks`](this.proxy.raw.impl).configure_bounds = proc (
      width {.inject.}: int32; height {.inject.}: int32) =
    body

template onWm_capabilities*(this: Xdg_toplevel; body) =
  ## This event advertises the capabilities supported by the compositor. If
  ## a capability isn't supported, clients should hide or disable the UI
  ## elements that expose this functionality. For instance, if the
  ## compositor doesn't advertise support for minimized toplevels, a button
  ## triggering the set_minimized request should not be displayed.
  ## 
  ## The compositor will ignore requests it doesn't support. For instance,
  ## a compositor which doesn't advertise support for minimized will ignore
  ## set_minimized requests.
  ## 
  ## Compositors must send this event once before the first
  ## xdg_surface.configure event. When the capabilities change, compositors
  ## must send this event again and then send an xdg_surface.configure
  ## event.
  ## 
  ## The configured state should not be applied immediately. See
  ## xdg_surface.configure for details.
  ## 
  ## The capabilities are sent as an array of 32-bit unsigned integers in
  ## native endianness.
  cast[ptr `Xdg_toplevel / Callbacks`](this.proxy.raw.impl).wm_capabilities = proc (
      capabilities {.inject.}: Wl_array) =
    body

template onConfigure*(this: Xdg_popup; body) =
  ## This event asks the popup surface to configure itself given the
  ## configuration. The configured state should not be applied immediately.
  ## See xdg_surface.configure for details.
  ## 
  ## The x and y arguments represent the position the popup was placed at
  ## given the xdg_positioner rule, relative to the upper left corner of the
  ## window geometry of the parent surface.
  ## 
  ## For version 2 or older, the configure event for an xdg_popup is only
  ## ever sent once for the initial configuration. Starting with version 3,
  ## it may be sent again if the popup is setup with an xdg_positioner with
  ## set_reactive requested, or in response to xdg_popup.reposition requests.
  cast[ptr `Xdg_popup / Callbacks`](this.proxy.raw.impl).configure = proc (
      x {.inject.}: int32; y {.inject.}: int32; width {.inject.}: int32;
      height {.inject.}: int32) =
    body

template onPopup_done*(this: Xdg_popup; body) =
  ## The popup_done event is sent out when a popup is dismissed by the
  ## compositor. The client should destroy the xdg_popup object at this
  ## point.
  cast[ptr `Xdg_popup / Callbacks`](this.proxy.raw.impl).popup_done = proc () =
    body

template onRepositioned*(this: Xdg_popup; body) =
  ## The repositioned event is sent as part of a popup configuration
  ## sequence, together with xdg_popup.configure and lastly
  ## xdg_surface.configure to notify the completion of a reposition request.
  ## 
  ## The repositioned event is to notify about the completion of a
  ## xdg_popup.reposition request. The token argument is the token passed
  ## in the xdg_popup.reposition request.
  ## 
  ## Immediately after this event is emitted, xdg_popup.configure and
  ## xdg_surface.configure will be sent with the updated size and position,
  ## as well as a new configure serial.
  ## 
  ## The client should optionally update the content of the popup, but must
  ## acknowledge the new popup configuration for the new position to take
  ## effect. See xdg_surface.ack_configure for details.
  cast[ptr `Xdg_popup / Callbacks`](this.proxy.raw.impl).repositioned = proc (
      token {.inject.}: uint32) =
    body

template onError*(this: Wl_display; body) =
  ## The error event is sent out when a fatal (non-recoverable)
  ## error has occurred.  The object_id argument is the object
  ## where the error occurred, most often in response to a request
  ## to that object.  The code identifies the error and is defined
  ## by the object interface.  As such, each interface defines its
  ## own set of error codes.  The message is a brief description
  ## of the error, for (debugging) convenience.
  cast[ptr `Wl_display / Callbacks`](this.proxy.raw.impl).error = proc (
      object_id {.inject.}: uint32; code {.inject.}: uint32;
      message {.inject.}: cstring) =
    body

template onDelete_id*(this: Wl_display; body) =
  ## This event is used internally by the object ID management
  ## logic. When a client deletes an object that it had created,
  ## the server will send this event to acknowledge that it has
  ## seen the delete request. When the client receives this event,
  ## it will know that it can safely reuse the object ID.
  cast[ptr `Wl_display / Callbacks`](this.proxy.raw.impl).delete_id = proc (
      id {.inject.}: uint32) =
    body

template onGlobal*(this: Wl_registry; body) =
  ## Notify the client of global objects.
  ## 
  ## The event notifies the client that a global object with
  ## the given name is now available, and it implements the
  ## given version of the given interface.
  cast[ptr `Wl_registry / Callbacks`](this.proxy.raw.impl).global = proc (
      name {.inject.}: uint32; `interface` {.inject.}: cstring;
      version {.inject.}: uint32) =
    body

template onGlobal_remove*(this: Wl_registry; body) =
  ## Notify the client of removed global objects.
  ## 
  ## This event notifies the client that the global identified
  ## by name is no longer available.  If the client bound to
  ## the global using the bind request, the client should now
  ## destroy that object.
  ## 
  ## The object remains valid and requests to the object will be
  ## ignored until the client destroys it, to avoid races between
  ## the global going away and a client sending a request to it.
  cast[ptr `Wl_registry / Callbacks`](this.proxy.raw.impl).global_remove = proc (
      name {.inject.}: uint32) =
    body

template onDone*(this: Wl_callback; body) =
  ## Notify the client when the related request is done.
  cast[ptr `Wl_callback / Callbacks`](this.proxy.raw.impl).done = proc (
      callback_data {.inject.}: uint32) =
    body

template onFormat*(this: Wl_shm; body) =
  ## Informs the client about a valid pixel format that
  ## can be used for buffers. Known formats include
  ## argb8888 and xrgb8888.
  cast[ptr `Wl_shm / Callbacks`](this.proxy.raw.impl).format = proc (
      format {.inject.}: `Wl_shm / Format`) =
    body

template onRelease*(this: Wl_buffer; body) =
  ## Sent when this wl_buffer is no longer used by the compositor.
  ## The client is now free to reuse or destroy this buffer and its
  ## backing storage.
  ## 
  ## If a client receives a release event before the frame callback
  ## requested in the same wl_surface.commit that attaches this
  ## wl_buffer to a surface, then the client is immediately free to
  ## reuse the buffer and its backing storage, and does not need a
  ## second buffer for the next surface content update. Typically
  ## this is possible, when the compositor maintains a copy of the
  ## wl_surface contents, e.g. as a GL texture. This is an important
  ## optimization for GL(ES) compositors with wl_shm clients.
  cast[ptr `Wl_buffer / Callbacks`](this.proxy.raw.impl).release = proc () =
    body

template onOffer*(this: Wl_data_offer; body) =
  ## Sent immediately after creating the wl_data_offer object.  One
  ## event per offered mime type.
  cast[ptr `Wl_data_offer / Callbacks`](this.proxy.raw.impl).offer = proc (
      mime_type {.inject.}: cstring) =
    body

template onSource_actions*(this: Wl_data_offer; body) =
  ## This event indicates the actions offered by the data source. It
  ## will be sent immediately after creating the wl_data_offer object,
  ## or anytime the source side changes its offered actions through
  ## wl_data_source.set_actions.
  cast[ptr `Wl_data_offer / Callbacks`](this.proxy.raw.impl).source_actions = proc (
      source_actions {.inject.}: `Wl_data_device_manager / Dnd_action`) =
    body

template onAction*(this: Wl_data_offer; body) =
  ## This event indicates the action selected by the compositor after
  ## matching the source/destination side actions. Only one action (or
  ## none) will be offered here.
  ## 
  ## This event can be emitted multiple times during the drag-and-drop
  ## operation in response to destination side action changes through
  ## wl_data_offer.set_actions.
  ## 
  ## This event will no longer be emitted after wl_data_device.drop
  ## happened on the drag-and-drop destination, the client must
  ## honor the last action received, or the last preferred one set
  ## through wl_data_offer.set_actions when handling an "ask" action.
  ## 
  ## Compositors may also change the selected action on the fly, mainly
  ## in response to keyboard modifier changes during the drag-and-drop
  ## operation.
  ## 
  ## The most recent action received is always the valid one. Prior to
  ## receiving wl_data_device.drop, the chosen action may change (e.g.
  ## due to keyboard modifiers being pressed). At the time of receiving
  ## wl_data_device.drop the drag-and-drop destination must honor the
  ## last action received.
  ## 
  ## Action changes may still happen after wl_data_device.drop,
  ## especially on "ask" actions, where the drag-and-drop destination
  ## may choose another action afterwards. Action changes happening
  ## at this stage are always the result of inter-client negotiation, the
  ## compositor shall no longer be able to induce a different action.
  ## 
  ## Upon "ask" actions, it is expected that the drag-and-drop destination
  ## may potentially choose a different action and/or mime type,
  ## based on wl_data_offer.source_actions and finally chosen by the
  ## user (e.g. popping up a menu with the available options). The
  ## final wl_data_offer.set_actions and wl_data_offer.accept requests
  ## must happen before the call to wl_data_offer.finish.
  cast[ptr `Wl_data_offer / Callbacks`](this.proxy.raw.impl).action = proc (
      dnd_action {.inject.}: `Wl_data_device_manager / Dnd_action`) =
    body

template onTarget*(this: Wl_data_source; body) =
  ## Sent when a target accepts pointer_focus or motion events.  If
  ## a target does not accept any of the offered types, type is NULL.
  ## 
  ## Used for feedback during drag-and-drop.
  cast[ptr `Wl_data_source / Callbacks`](this.proxy.raw.impl).target = proc (
      mime_type {.inject.}: cstring) =
    body

template onSend*(this: Wl_data_source; body) =
  ## Request for data from the client.  Send the data as the
  ## specified mime type over the passed file descriptor, then
  ## close it.
  cast[ptr `Wl_data_source / Callbacks`](this.proxy.raw.impl).send = proc (
      mime_type {.inject.}: cstring; fd {.inject.}: FileHandle) =
    body

template onCancelled*(this: Wl_data_source; body) =
  ## This data source is no longer valid. There are several reasons why
  ## this could happen:
  ## 
  ## - The data source has been replaced by another data source.
  ## - The drag-and-drop operation was performed, but the drop destination
  ##   did not accept any of the mime types offered through
  ##   wl_data_source.target.
  ## - The drag-and-drop operation was performed, but the drop destination
  ##   did not select any of the actions present in the mask offered through
  ##   wl_data_source.action.
  ## - The drag-and-drop operation was performed but didn't happen over a
  ##   surface.
  ## - The compositor cancelled the drag-and-drop operation (e.g. compositor
  ##   dependent timeouts to avoid stale drag-and-drop transfers).
  ## 
  ## The client should clean up and destroy this data source.
  ## 
  ## For objects of version 2 or older, wl_data_source.cancelled will
  ## only be emitted if the data source was replaced by another data
  ## source.
  cast[ptr `Wl_data_source / Callbacks`](this.proxy.raw.impl).cancelled = proc () =
    body

template onDnd_drop_performed*(this: Wl_data_source; body) =
  ## The user performed the drop action. This event does not indicate
  ## acceptance, wl_data_source.cancelled may still be emitted afterwards
  ## if the drop destination does not accept any mime type.
  ## 
  ## However, this event might however not be received if the compositor
  ## cancelled the drag-and-drop operation before this event could happen.
  ## 
  ## Note that the data_source may still be used in the future and should
  ## not be destroyed here.
  cast[ptr `Wl_data_source / Callbacks`](this.proxy.raw.impl).dnd_drop_performed = proc () =
    body

template onDnd_finished*(this: Wl_data_source; body) =
  ## The drop destination finished interoperating with this data
  ## source, so the client is now free to destroy this data source and
  ## free all associated data.
  ## 
  ## If the action used to perform the operation was "move", the
  ## source can now delete the transferred data.
  cast[ptr `Wl_data_source / Callbacks`](this.proxy.raw.impl).dnd_finished = proc () =
    body

template onAction*(this: Wl_data_source; body) =
  ## This event indicates the action selected by the compositor after
  ## matching the source/destination side actions. Only one action (or
  ## none) will be offered here.
  ## 
  ## This event can be emitted multiple times during the drag-and-drop
  ## operation, mainly in response to destination side changes through
  ## wl_data_offer.set_actions, and as the data device enters/leaves
  ## surfaces.
  ## 
  ## It is only possible to receive this event after
  ## wl_data_source.dnd_drop_performed if the drag-and-drop operation
  ## ended in an "ask" action, in which case the final wl_data_source.action
  ## event will happen immediately before wl_data_source.dnd_finished.
  ## 
  ## Compositors may also change the selected action on the fly, mainly
  ## in response to keyboard modifier changes during the drag-and-drop
  ## operation.
  ## 
  ## The most recent action received is always the valid one. The chosen
  ## action may change alongside negotiation (e.g. an "ask" action can turn
  ## into a "move" operation), so the effects of the final action must
  ## always be applied in wl_data_offer.dnd_finished.
  ## 
  ## Clients can trigger cursor surface changes from this point, so
  ## they reflect the current action.
  cast[ptr `Wl_data_source / Callbacks`](this.proxy.raw.impl).action = proc (
      dnd_action {.inject.}: `Wl_data_device_manager / Dnd_action`) =
    body

template onData_offer*(this: Wl_data_device; body) =
  ## The data_offer event introduces a new wl_data_offer object,
  ## which will subsequently be used in either the
  ## data_device.enter event (for drag-and-drop) or the
  ## data_device.selection event (for selections).  Immediately
  ## following the data_device.data_offer event, the new data_offer
  ## object will send out data_offer.offer events to describe the
  ## mime types it offers.
  cast[ptr `Wl_data_device / Callbacks`](this.proxy.raw.impl).data_offer = proc (
      id {.inject.}: Wl_data_offer) =
    body

template onEnter*(this: Wl_data_device; body) =
  ## This event is sent when an active drag-and-drop pointer enters
  ## a surface owned by the client.  The position of the pointer at
  ## enter time is provided by the x and y arguments, in surface-local
  ## coordinates.
  cast[ptr `Wl_data_device / Callbacks`](this.proxy.raw.impl).enter = proc (
      serial {.inject.}: uint32; surface {.inject.}: Wl_surface;
      x {.inject.}: float32; y {.inject.}: float32; id {.inject.}: Wl_data_offer) =
    body

template onLeave*(this: Wl_data_device; body) =
  ## This event is sent when the drag-and-drop pointer leaves the
  ## surface and the session ends.  The client must destroy the
  ## wl_data_offer introduced at enter time at this point.
  cast[ptr `Wl_data_device / Callbacks`](this.proxy.raw.impl).leave = proc () =
    body

template onMotion*(this: Wl_data_device; body) =
  ## This event is sent when the drag-and-drop pointer moves within
  ## the currently focused surface. The new position of the pointer
  ## is provided by the x and y arguments, in surface-local
  ## coordinates.
  cast[ptr `Wl_data_device / Callbacks`](this.proxy.raw.impl).motion = proc (
      time {.inject.}: uint32; x {.inject.}: float32; y {.inject.}: float32) =
    body

template onDrop*(this: Wl_data_device; body) =
  ## The event is sent when a drag-and-drop operation is ended
  ## because the implicit grab is removed.
  ## 
  ## The drag-and-drop destination is expected to honor the last action
  ## received through wl_data_offer.action, if the resulting action is
  ## "copy" or "move", the destination can still perform
  ## wl_data_offer.receive requests, and is expected to end all
  ## transfers with a wl_data_offer.finish request.
  ## 
  ## If the resulting action is "ask", the action will not be considered
  ## final. The drag-and-drop destination is expected to perform one last
  ## wl_data_offer.set_actions request, or wl_data_offer.destroy in order
  ## to cancel the operation.
  cast[ptr `Wl_data_device / Callbacks`](this.proxy.raw.impl).drop = proc () =
    body

template onSelection*(this: Wl_data_device; body) =
  ## The selection event is sent out to notify the client of a new
  ## wl_data_offer for the selection for this device.  The
  ## data_device.data_offer and the data_offer.offer events are
  ## sent out immediately before this event to introduce the data
  ## offer object.  The selection event is sent to a client
  ## immediately before receiving keyboard focus and when a new
  ## selection is set while the client has keyboard focus.  The
  ## data_offer is valid until a new data_offer or NULL is received
  ## or until the client loses keyboard focus.  Switching surface with
  ## keyboard focus within the same client doesn't mean a new selection
  ## will be sent.  The client must destroy the previous selection
  ## data_offer, if any, upon receiving this event.
  cast[ptr `Wl_data_device / Callbacks`](this.proxy.raw.impl).selection = proc (
      id {.inject.}: Wl_data_offer) =
    body

template onPing*(this: Wl_shell_surface; body) =
  ## Ping a client to check if it is receiving events and sending
  ## requests. A client is expected to reply with a pong request.
  cast[ptr `Wl_shell_surface / Callbacks`](this.proxy.raw.impl).ping = proc (
      serial {.inject.}: uint32) =
    body

template onConfigure*(this: Wl_shell_surface; body) =
  ## The configure event asks the client to resize its surface.
  ## 
  ## The size is a hint, in the sense that the client is free to
  ## ignore it if it doesn't resize, pick a smaller size (to
  ## satisfy aspect ratio or resize in steps of NxM pixels).
  ## 
  ## The edges parameter provides a hint about how the surface
  ## was resized. The client may use this information to decide
  ## how to adjust its content to the new size (e.g. a scrolling
  ## area might adjust its content position to leave the viewable
  ## content unmoved).
  ## 
  ## The client is free to dismiss all but the last configure
  ## event it received.
  ## 
  ## The width and height arguments specify the size of the window
  ## in surface-local coordinates.
  cast[ptr `Wl_shell_surface / Callbacks`](this.proxy.raw.impl).configure = proc (
      edges {.inject.}: `Wl_shell_surface / Resize`; width {.inject.}: int32;
      height {.inject.}: int32) =
    body

template onPopup_done*(this: Wl_shell_surface; body) =
  ## The popup_done event is sent out when a popup grab is broken,
  ## that is, when the user clicks a surface that doesn't belong
  ## to the client owning the popup surface.
  cast[ptr `Wl_shell_surface / Callbacks`](this.proxy.raw.impl).popup_done = proc () =
    body

template onEnter*(this: Wl_surface; body) =
  ## This is emitted whenever a surface's creation, movement, or resizing
  ## results in some part of it being within the scanout region of an
  ## output.
  ## 
  ## Note that a surface may be overlapping with zero or more outputs.
  cast[ptr `Wl_surface / Callbacks`](this.proxy.raw.impl).enter = proc (
      output {.inject.}: Wl_output) =
    body

template onLeave*(this: Wl_surface; body) =
  ## This is emitted whenever a surface's creation, movement, or resizing
  ## results in it no longer having any part of it within the scanout region
  ## of an output.
  ## 
  ## Clients should not use the number of outputs the surface is on for frame
  ## throttling purposes. The surface might be hidden even if no leave event
  ## has been sent, and the compositor might expect new surface content
  ## updates even if no enter event has been sent. The frame event should be
  ## used instead.
  cast[ptr `Wl_surface / Callbacks`](this.proxy.raw.impl).leave = proc (
      output {.inject.}: Wl_output) =
    body

template onPreferred_buffer_scale*(this: Wl_surface; body) =
  ## This event indicates the preferred buffer scale for this surface. It is
  ## sent whenever the compositor's preference changes.
  ## 
  ## It is intended that scaling aware clients use this event to scale their
  ## content and use wl_surface.set_buffer_scale to indicate the scale they
  ## have rendered with. This allows clients to supply a higher detail
  ## buffer.
  cast[ptr `Wl_surface / Callbacks`](this.proxy.raw.impl).preferred_buffer_scale = proc (
      factor {.inject.}: int32) =
    body

template onPreferred_buffer_transform*(this: Wl_surface; body) =
  ## This event indicates the preferred buffer transform for this surface.
  ## It is sent whenever the compositor's preference changes.
  ## 
  ## It is intended that transform aware clients use this event to apply the
  ## transform to their content and use wl_surface.set_buffer_transform to
  ## indicate the transform they have rendered with.
  cast[ptr `Wl_surface / Callbacks`](this.proxy.raw.impl).preferred_buffer_transform = proc (
      transform {.inject.}: `Wl_output / Transform`) =
    body

template onCapabilities*(this: Wl_seat; body) =
  ## This is emitted whenever a seat gains or loses the pointer,
  ## keyboard or touch capabilities.  The argument is a capability
  ## enum containing the complete set of capabilities this seat has.
  ## 
  ## When the pointer capability is added, a client may create a
  ## wl_pointer object using the wl_seat.get_pointer request. This object
  ## will receive pointer events until the capability is removed in the
  ## future.
  ## 
  ## When the pointer capability is removed, a client should destroy the
  ## wl_pointer objects associated with the seat where the capability was
  ## removed, using the wl_pointer.release request. No further pointer
  ## events will be received on these objects.
  ## 
  ## In some compositors, if a seat regains the pointer capability and a
  ## client has a previously obtained wl_pointer object of version 4 or
  ## less, that object may start sending pointer events again. This
  ## behavior is considered a misinterpretation of the intended behavior
  ## and must not be relied upon by the client. wl_pointer objects of
  ## version 5 or later must not send events if created before the most
  ## recent event notifying the client of an added pointer capability.
  ## 
  ## The above behavior also applies to wl_keyboard and wl_touch with the
  ## keyboard and touch capabilities, respectively.
  cast[ptr `Wl_seat / Callbacks`](this.proxy.raw.impl).capabilities = proc (
      capabilities {.inject.}: `Wl_seat / Capability`) =
    body

template onName*(this: Wl_seat; body) =
  ## In a multi-seat configuration the seat name can be used by clients to
  ## help identify which physical devices the seat represents.
  ## 
  ## The seat name is a UTF-8 string with no convention defined for its
  ## contents. Each name is unique among all wl_seat globals. The name is
  ## only guaranteed to be unique for the current compositor instance.
  ## 
  ## The same seat names are used for all clients. Thus, the name can be
  ## shared across processes to refer to a specific wl_seat global.
  ## 
  ## The name event is sent after binding to the seat global. This event is
  ## only sent once per seat object, and the name does not change over the
  ## lifetime of the wl_seat global.
  ## 
  ## Compositors may re-use the same seat name if the wl_seat global is
  ## destroyed and re-created later.
  cast[ptr `Wl_seat / Callbacks`](this.proxy.raw.impl).name = proc (
      name {.inject.}: cstring) =
    body

template onEnter*(this: Wl_pointer; body) =
  ## Notification that this seat's pointer is focused on a certain
  ## surface.
  ## 
  ## When a seat's focus enters a surface, the pointer image
  ## is undefined and a client should respond to this event by setting
  ## an appropriate pointer image with the set_cursor request.
  cast[ptr `Wl_pointer / Callbacks`](this.proxy.raw.impl).enter = proc (
      serial {.inject.}: uint32; surface {.inject.}: Wl_surface;
      surface_x {.inject.}: float32; surface_y {.inject.}: float32) =
    body

template onLeave*(this: Wl_pointer; body) =
  ## Notification that this seat's pointer is no longer focused on
  ## a certain surface.
  ## 
  ## The leave notification is sent before the enter notification
  ## for the new focus.
  cast[ptr `Wl_pointer / Callbacks`](this.proxy.raw.impl).leave = proc (
      serial {.inject.}: uint32; surface {.inject.}: Wl_surface) =
    body

template onMotion*(this: Wl_pointer; body) =
  ## Notification of pointer location change. The arguments
  ## surface_x and surface_y are the location relative to the
  ## focused surface.
  cast[ptr `Wl_pointer / Callbacks`](this.proxy.raw.impl).motion = proc (
      time {.inject.}: uint32; surface_x {.inject.}: float32;
      surface_y {.inject.}: float32) =
    body

template onButton*(this: Wl_pointer; body) =
  ## Mouse button click and release notifications.
  ## 
  ## The location of the click is given by the last motion or
  ## enter event.
  ## The time argument is a timestamp with millisecond
  ## granularity, with an undefined base.
  ## 
  ## The button is a button code as defined in the Linux kernel's
  ## linux/input-event-codes.h header file, e.g. BTN_LEFT.
  ## 
  ## Any 16-bit button code value is reserved for future additions to the
  ## kernel's event code list. All other button codes above 0xFFFF are
  ## currently undefined but may be used in future versions of this
  ## protocol.
  cast[ptr `Wl_pointer / Callbacks`](this.proxy.raw.impl).button = proc (
      serial {.inject.}: uint32; time {.inject.}: uint32;
      button {.inject.}: uint32; state {.inject.}: `Wl_pointer / Button_state`) =
    body

template onAxis*(this: Wl_pointer; body) =
  ## Scroll and other axis notifications.
  ## 
  ## For scroll events (vertical and horizontal scroll axes), the
  ## value parameter is the length of a vector along the specified
  ## axis in a coordinate space identical to those of motion events,
  ## representing a relative movement along the specified axis.
  ## 
  ## For devices that support movements non-parallel to axes multiple
  ## axis events will be emitted.
  ## 
  ## When applicable, for example for touch pads, the server can
  ## choose to emit scroll events where the motion vector is
  ## equivalent to a motion event vector.
  ## 
  ## When applicable, a client can transform its content relative to the
  ## scroll distance.
  cast[ptr `Wl_pointer / Callbacks`](this.proxy.raw.impl).axis = proc (
      time {.inject.}: uint32; axis {.inject.}: `Wl_pointer / Axis`;
      value {.inject.}: float32) =
    body

template onFrame*(this: Wl_pointer; body) =
  ## Indicates the end of a set of events that logically belong together.
  ## A client is expected to accumulate the data in all events within the
  ## frame before proceeding.
  ## 
  ## All wl_pointer events before a wl_pointer.frame event belong
  ## logically together. For example, in a diagonal scroll motion the
  ## compositor will send an optional wl_pointer.axis_source event, two
  ## wl_pointer.axis events (horizontal and vertical) and finally a
  ## wl_pointer.frame event. The client may use this information to
  ## calculate a diagonal vector for scrolling.
  ## 
  ## When multiple wl_pointer.axis events occur within the same frame,
  ## the motion vector is the combined motion of all events.
  ## When a wl_pointer.axis and a wl_pointer.axis_stop event occur within
  ## the same frame, this indicates that axis movement in one axis has
  ## stopped but continues in the other axis.
  ## When multiple wl_pointer.axis_stop events occur within the same
  ## frame, this indicates that these axes stopped in the same instance.
  ## 
  ## A wl_pointer.frame event is sent for every logical event group,
  ## even if the group only contains a single wl_pointer event.
  ## Specifically, a client may get a sequence: motion, frame, button,
  ## frame, axis, frame, axis_stop, frame.
  ## 
  ## The wl_pointer.enter and wl_pointer.leave events are logical events
  ## generated by the compositor and not the hardware. These events are
  ## also grouped by a wl_pointer.frame. When a pointer moves from one
  ## surface to another, a compositor should group the
  ## wl_pointer.leave event within the same wl_pointer.frame.
  ## However, a client must not rely on wl_pointer.leave and
  ## wl_pointer.enter being in the same wl_pointer.frame.
  ## Compositor-specific policies may require the wl_pointer.leave and
  ## wl_pointer.enter event being split across multiple wl_pointer.frame
  ## groups.
  cast[ptr `Wl_pointer / Callbacks`](this.proxy.raw.impl).frame = proc () =
    body

template onAxis_source*(this: Wl_pointer; body) =
  ## Source information for scroll and other axes.
  ## 
  ## This event does not occur on its own. It is sent before a
  ## wl_pointer.frame event and carries the source information for
  ## all events within that frame.
  ## 
  ## The source specifies how this event was generated. If the source is
  ## wl_pointer.axis_source.finger, a wl_pointer.axis_stop event will be
  ## sent when the user lifts the finger off the device.
  ## 
  ## If the source is wl_pointer.axis_source.wheel,
  ## wl_pointer.axis_source.wheel_tilt or
  ## wl_pointer.axis_source.continuous, a wl_pointer.axis_stop event may
  ## or may not be sent. Whether a compositor sends an axis_stop event
  ## for these sources is hardware-specific and implementation-dependent;
  ## clients must not rely on receiving an axis_stop event for these
  ## scroll sources and should treat scroll sequences from these scroll
  ## sources as unterminated by default.
  ## 
  ## This event is optional. If the source is unknown for a particular
  ## axis event sequence, no event is sent.
  ## Only one wl_pointer.axis_source event is permitted per frame.
  ## 
  ## The order of wl_pointer.axis_discrete and wl_pointer.axis_source is
  ## not guaranteed.
  cast[ptr `Wl_pointer / Callbacks`](this.proxy.raw.impl).axis_source = proc (
      axis_source {.inject.}: `Wl_pointer / Axis_source`) =
    body

template onAxis_stop*(this: Wl_pointer; body) =
  ## Stop notification for scroll and other axes.
  ## 
  ## For some wl_pointer.axis_source types, a wl_pointer.axis_stop event
  ## is sent to notify a client that the axis sequence has terminated.
  ## This enables the client to implement kinetic scrolling.
  ## See the wl_pointer.axis_source documentation for information on when
  ## this event may be generated.
  ## 
  ## Any wl_pointer.axis events with the same axis_source after this
  ## event should be considered as the start of a new axis motion.
  ## 
  ## The timestamp is to be interpreted identical to the timestamp in the
  ## wl_pointer.axis event. The timestamp value may be the same as a
  ## preceding wl_pointer.axis event.
  cast[ptr `Wl_pointer / Callbacks`](this.proxy.raw.impl).axis_stop = proc (
      time {.inject.}: uint32; axis {.inject.}: `Wl_pointer / Axis`) =
    body

template onAxis_discrete*(this: Wl_pointer; body) =
  ## Discrete step information for scroll and other axes.
  ## 
  ## This event carries the axis value of the wl_pointer.axis event in
  ## discrete steps (e.g. mouse wheel clicks).
  ## 
  ## This event is deprecated with wl_pointer version 8 - this event is not
  ## sent to clients supporting version 8 or later.
  ## 
  ## This event does not occur on its own, it is coupled with a
  ## wl_pointer.axis event that represents this axis value on a
  ## continuous scale. The protocol guarantees that each axis_discrete
  ## event is always followed by exactly one axis event with the same
  ## axis number within the same wl_pointer.frame. Note that the protocol
  ## allows for other events to occur between the axis_discrete and
  ## its coupled axis event, including other axis_discrete or axis
  ## events. A wl_pointer.frame must not contain more than one axis_discrete
  ## event per axis type.
  ## 
  ## This event is optional; continuous scrolling devices
  ## like two-finger scrolling on touchpads do not have discrete
  ## steps and do not generate this event.
  ## 
  ## The discrete value carries the directional information. e.g. a value
  ## of -2 is two steps towards the negative direction of this axis.
  ## 
  ## The axis number is identical to the axis number in the associated
  ## axis event.
  ## 
  ## The order of wl_pointer.axis_discrete and wl_pointer.axis_source is
  ## not guaranteed.
  cast[ptr `Wl_pointer / Callbacks`](this.proxy.raw.impl).axis_discrete = proc (
      axis {.inject.}: `Wl_pointer / Axis`; discrete {.inject.}: int32) =
    body

template onAxis_value120*(this: Wl_pointer; body) =
  ## Discrete high-resolution scroll information.
  ## 
  ## This event carries high-resolution wheel scroll information,
  ## with each multiple of 120 representing one logical scroll step
  ## (a wheel detent). For example, an axis_value120 of 30 is one quarter of
  ## a logical scroll step in the positive direction, a value120 of
  ## -240 are two logical scroll steps in the negative direction within the
  ## same hardware event.
  ## Clients that rely on discrete scrolling should accumulate the
  ## value120 to multiples of 120 before processing the event.
  ## 
  ## The value120 must not be zero.
  ## 
  ## This event replaces the wl_pointer.axis_discrete event in clients
  ## supporting wl_pointer version 8 or later.
  ## 
  ## Where a wl_pointer.axis_source event occurs in the same
  ## wl_pointer.frame, the axis source applies to this event.
  ## 
  ## The order of wl_pointer.axis_value120 and wl_pointer.axis_source is
  ## not guaranteed.
  cast[ptr `Wl_pointer / Callbacks`](this.proxy.raw.impl).axis_value120 = proc (
      axis {.inject.}: `Wl_pointer / Axis`; value120 {.inject.}: int32) =
    body

template onAxis_relative_direction*(this: Wl_pointer; body) =
  ## Relative directional information of the entity causing the axis
  ## motion.
  ## 
  ## For a wl_pointer.axis event, the wl_pointer.axis_relative_direction
  ## event specifies the movement direction of the entity causing the
  ## wl_pointer.axis event. For example:
  ## - if a user's fingers on a touchpad move down and this
  ##   causes a wl_pointer.axis vertical_scroll down event, the physical
  ##   direction is 'identical'
  ## - if a user's fingers on a touchpad move down and this causes a
  ##   wl_pointer.axis vertical_scroll up scroll up event ('natural
  ##   scrolling'), the physical direction is 'inverted'.
  ## 
  ## A client may use this information to adjust scroll motion of
  ## components. Specifically, enabling natural scrolling causes the
  ## content to change direction compared to traditional scrolling.
  ## Some widgets like volume control sliders should usually match the
  ## physical direction regardless of whether natural scrolling is
  ## active. This event enables clients to match the scroll direction of
  ## a widget to the physical direction.
  ## 
  ## This event does not occur on its own, it is coupled with a
  ## wl_pointer.axis event that represents this axis value.
  ## The protocol guarantees that each axis_relative_direction event is
  ## always followed by exactly one axis event with the same
  ## axis number within the same wl_pointer.frame. Note that the protocol
  ## allows for other events to occur between the axis_relative_direction
  ## and its coupled axis event.
  ## 
  ## The axis number is identical to the axis number in the associated
  ## axis event.
  ## 
  ## The order of wl_pointer.axis_relative_direction,
  ## wl_pointer.axis_discrete and wl_pointer.axis_source is not
  ## guaranteed.
  cast[ptr `Wl_pointer / Callbacks`](this.proxy.raw.impl).axis_relative_direction = proc (
      axis {.inject.}: `Wl_pointer / Axis`;
      direction {.inject.}: `Wl_pointer / Axis_relative_direction`) =
    body

template onKeymap*(this: Wl_keyboard; body) =
  ## This event provides a file descriptor to the client which can be
  ## memory-mapped in read-only mode to provide a keyboard mapping
  ## description.
  ## 
  ## From version 7 onwards, the fd must be mapped with MAP_PRIVATE by
  ## the recipient, as MAP_SHARED may fail.
  cast[ptr `Wl_keyboard / Callbacks`](this.proxy.raw.impl).keymap = proc (
      format {.inject.}: `Wl_keyboard / Keymap_format`;
      fd {.inject.}: FileHandle; size {.inject.}: uint32) =
    body

template onEnter*(this: Wl_keyboard; body) =
  ## Notification that this seat's keyboard focus is on a certain
  ## surface.
  ## 
  ## The compositor must send the wl_keyboard.modifiers event after this
  ## event.
  cast[ptr `Wl_keyboard / Callbacks`](this.proxy.raw.impl).enter = proc (
      serial {.inject.}: uint32; surface {.inject.}: Wl_surface;
      keys {.inject.}: Wl_array) =
    body

template onLeave*(this: Wl_keyboard; body) =
  ## Notification that this seat's keyboard focus is no longer on
  ## a certain surface.
  ## 
  ## The leave notification is sent before the enter notification
  ## for the new focus.
  ## 
  ## After this event client must assume that no keys are pressed,
  ## it must stop key repeating if there's some going on and until
  ## it receives the next wl_keyboard.modifiers event, the client
  ## must also assume no modifiers are active.
  cast[ptr `Wl_keyboard / Callbacks`](this.proxy.raw.impl).leave = proc (
      serial {.inject.}: uint32; surface {.inject.}: Wl_surface) =
    body

template onKey*(this: Wl_keyboard; body) =
  ## A key was pressed or released.
  ## The time argument is a timestamp with millisecond
  ## granularity, with an undefined base.
  ## 
  ## The key is a platform-specific key code that can be interpreted
  ## by feeding it to the keyboard mapping (see the keymap event).
  ## 
  ## If this event produces a change in modifiers, then the resulting
  ## wl_keyboard.modifiers event must be sent after this event.
  ## 
  ## The compositor must not send this event without a surface of the client
  ## having keyboard focus.
  cast[ptr `Wl_keyboard / Callbacks`](this.proxy.raw.impl).key = proc (
      serial {.inject.}: uint32; time {.inject.}: uint32; key {.inject.}: uint32;
      state {.inject.}: `Wl_keyboard / Key_state`) =
    body

template onModifiers*(this: Wl_keyboard; body) =
  ## Notifies clients that the modifier and/or group state has
  ## changed, and it should update its local state.
  ## 
  ## The compositor may send this event without a surface of the client
  ## having keyboard focus, for example to tie modifier information to
  ## pointer focus instead. If a modifier event with pressed modifiers is sent
  ## without a prior enter event, the client can assume the modifier state is
  ## valid until it receives the next wl_keyboard.modifiers event. In order to
  ## reset the modifier state again, the compositor can send a
  ## wl_keyboard.modifiers event with no pressed modifiers.
  cast[ptr `Wl_keyboard / Callbacks`](this.proxy.raw.impl).modifiers = proc (
      serial {.inject.}: uint32; mods_depressed {.inject.}: uint32;
      mods_latched {.inject.}: uint32; mods_locked {.inject.}: uint32;
      group {.inject.}: uint32) =
    body

template onRepeat_info*(this: Wl_keyboard; body) =
  ## Informs the client about the keyboard's repeat rate and delay.
  ## 
  ## This event is sent as soon as the wl_keyboard object has been created,
  ## and is guaranteed to be received by the client before any key press
  ## event.
  ## 
  ## Negative values for either rate or delay are illegal. A rate of zero
  ## will disable any repeating (regardless of the value of delay).
  ## 
  ## This event can be sent later on as well with a new value if necessary,
  ## so clients should continue listening for the event past the creation
  ## of wl_keyboard.
  cast[ptr `Wl_keyboard / Callbacks`](this.proxy.raw.impl).repeat_info = proc (
      rate {.inject.}: int32; delay {.inject.}: int32) =
    body

template onDown*(this: Wl_touch; body) =
  ## A new touch point has appeared on the surface. This touch point is
  ## assigned a unique ID. Future events from this touch point reference
  ## this ID. The ID ceases to be valid after a touch up event and may be
  ## reused in the future.
  cast[ptr `Wl_touch / Callbacks`](this.proxy.raw.impl).down = proc (
      serial {.inject.}: uint32; time {.inject.}: uint32;
      surface {.inject.}: Wl_surface; id {.inject.}: int32;
      x {.inject.}: float32; y {.inject.}: float32) =
    body

template onUp*(this: Wl_touch; body) =
  ## The touch point has disappeared. No further events will be sent for
  ## this touch point and the touch point's ID is released and may be
  ## reused in a future touch down event.
  cast[ptr `Wl_touch / Callbacks`](this.proxy.raw.impl).up = proc (
      serial {.inject.}: uint32; time {.inject.}: uint32; id {.inject.}: int32) =
    body

template onMotion*(this: Wl_touch; body) =
  ## A touch point has changed coordinates.
  cast[ptr `Wl_touch / Callbacks`](this.proxy.raw.impl).motion = proc (
      time {.inject.}: uint32; id {.inject.}: int32; x {.inject.}: float32;
      y {.inject.}: float32) =
    body

template onFrame*(this: Wl_touch; body) =
  ## Indicates the end of a set of events that logically belong together.
  ## A client is expected to accumulate the data in all events within the
  ## frame before proceeding.
  ## 
  ## A wl_touch.frame terminates at least one event but otherwise no
  ## guarantee is provided about the set of events within a frame. A client
  ## must assume that any state not updated in a frame is unchanged from the
  ## previously known state.
  cast[ptr `Wl_touch / Callbacks`](this.proxy.raw.impl).frame = proc () =
    body

template onCancel*(this: Wl_touch; body) =
  ## Sent if the compositor decides the touch stream is a global
  ## gesture. No further events are sent to the clients from that
  ## particular gesture. Touch cancellation applies to all touch points
  ## currently active on this client's surface. The client is
  ## responsible for finalizing the touch points, future touch points on
  ## this surface may reuse the touch point ID.
  cast[ptr `Wl_touch / Callbacks`](this.proxy.raw.impl).cancel = proc () =
    body

template onShape*(this: Wl_touch; body) =
  ## Sent when a touchpoint has changed its shape.
  ## 
  ## This event does not occur on its own. It is sent before a
  ## wl_touch.frame event and carries the new shape information for
  ## any previously reported, or new touch points of that frame.
  ## 
  ## Other events describing the touch point such as wl_touch.down,
  ## wl_touch.motion or wl_touch.orientation may be sent within the
  ## same wl_touch.frame. A client should treat these events as a single
  ## logical touch point update. The order of wl_touch.shape,
  ## wl_touch.orientation and wl_touch.motion is not guaranteed.
  ## A wl_touch.down event is guaranteed to occur before the first
  ## wl_touch.shape event for this touch ID but both events may occur within
  ## the same wl_touch.frame.
  ## 
  ## A touchpoint shape is approximated by an ellipse through the major and
  ## minor axis length. The major axis length describes the longer diameter
  ## of the ellipse, while the minor axis length describes the shorter
  ## diameter. Major and minor are orthogonal and both are specified in
  ## surface-local coordinates. The center of the ellipse is always at the
  ## touchpoint location as reported by wl_touch.down or wl_touch.move.
  ## 
  ## This event is only sent by the compositor if the touch device supports
  ## shape reports. The client has to make reasonable assumptions about the
  ## shape if it did not receive this event.
  cast[ptr `Wl_touch / Callbacks`](this.proxy.raw.impl).shape = proc (
      id {.inject.}: int32; major {.inject.}: float32; minor {.inject.}: float32) =
    body

template onOrientation*(this: Wl_touch; body) =
  ## Sent when a touchpoint has changed its orientation.
  ## 
  ## This event does not occur on its own. It is sent before a
  ## wl_touch.frame event and carries the new shape information for
  ## any previously reported, or new touch points of that frame.
  ## 
  ## Other events describing the touch point such as wl_touch.down,
  ## wl_touch.motion or wl_touch.shape may be sent within the
  ## same wl_touch.frame. A client should treat these events as a single
  ## logical touch point update. The order of wl_touch.shape,
  ## wl_touch.orientation and wl_touch.motion is not guaranteed.
  ## A wl_touch.down event is guaranteed to occur before the first
  ## wl_touch.orientation event for this touch ID but both events may occur
  ## within the same wl_touch.frame.
  ## 
  ## The orientation describes the clockwise angle of a touchpoint's major
  ## axis to the positive surface y-axis and is normalized to the -180 to
  ## +180 degree range. The granularity of orientation depends on the touch
  ## device, some devices only support binary rotation values between 0 and
  ## 90 degrees.
  ## 
  ## This event is only sent by the compositor if the touch device supports
  ## orientation reports.
  cast[ptr `Wl_touch / Callbacks`](this.proxy.raw.impl).orientation = proc (
      id {.inject.}: int32; orientation {.inject.}: float32) =
    body

template onGeometry*(this: Wl_output; body) =
  ## The geometry event describes geometric properties of the output.
  ## The event is sent when binding to the output object and whenever
  ## any of the properties change.
  ## 
  ## The physical size can be set to zero if it doesn't make sense for this
  ## output (e.g. for projectors or virtual outputs).
  ## 
  ## The geometry event will be followed by a done event (starting from
  ## version 2).
  ## 
  ## Note: wl_output only advertises partial information about the output
  ## position and identification. Some compositors, for instance those not
  ## implementing a desktop-style output layout or those exposing virtual
  ## outputs, might fake this information. Instead of using x and y, clients
  ## should use xdg_output.logical_position. Instead of using make and model,
  ## clients should use name and description.
  cast[ptr `Wl_output / Callbacks`](this.proxy.raw.impl).geometry = proc (
      x {.inject.}: int32; y {.inject.}: int32; physical_width {.inject.}: int32;
      physical_height {.inject.}: int32;
      subpixel {.inject.}: `Wl_output / Subpixel`; make {.inject.}: cstring;
      model {.inject.}: cstring; transform {.inject.}: `Wl_output / Transform`) =
    body

template onMode*(this: Wl_output; body) =
  ## The mode event describes an available mode for the output.
  ## 
  ## The event is sent when binding to the output object and there
  ## will always be one mode, the current mode.  The event is sent
  ## again if an output changes mode, for the mode that is now
  ## current.  In other words, the current mode is always the last
  ## mode that was received with the current flag set.
  ## 
  ## Non-current modes are deprecated. A compositor can decide to only
  ## advertise the current mode and never send other modes. Clients
  ## should not rely on non-current modes.
  ## 
  ## The size of a mode is given in physical hardware units of
  ## the output device. This is not necessarily the same as
  ## the output size in the global compositor space. For instance,
  ## the output may be scaled, as described in wl_output.scale,
  ## or transformed, as described in wl_output.transform. Clients
  ## willing to retrieve the output size in the global compositor
  ## space should use xdg_output.logical_size instead.
  ## 
  ## The vertical refresh rate can be set to zero if it doesn't make
  ## sense for this output (e.g. for virtual outputs).
  ## 
  ## The mode event will be followed by a done event (starting from
  ## version 2).
  ## 
  ## Clients should not use the refresh rate to schedule frames. Instead,
  ## they should use the wl_surface.frame event or the presentation-time
  ## protocol.
  ## 
  ## Note: this information is not always meaningful for all outputs. Some
  ## compositors, such as those exposing virtual outputs, might fake the
  ## refresh rate or the size.
  cast[ptr `Wl_output / Callbacks`](this.proxy.raw.impl).mode = proc (
      flags {.inject.}: `Wl_output / Mode`; width {.inject.}: int32;
      height {.inject.}: int32; refresh {.inject.}: int32) =
    body

template onDone*(this: Wl_output; body) =
  ## This event is sent after all other properties have been
  ## sent after binding to the output object and after any
  ## other property changes done after that. This allows
  ## changes to the output properties to be seen as
  ## atomic, even if they happen via multiple events.
  cast[ptr `Wl_output / Callbacks`](this.proxy.raw.impl).done = proc () =
    body

template onScale*(this: Wl_output; body) =
  ## This event contains scaling geometry information
  ## that is not in the geometry event. It may be sent after
  ## binding the output object or if the output scale changes
  ## later. If it is not sent, the client should assume a
  ## scale of 1.
  ## 
  ## A scale larger than 1 means that the compositor will
  ## automatically scale surface buffers by this amount
  ## when rendering. This is used for very high resolution
  ## displays where applications rendering at the native
  ## resolution would be too small to be legible.
  ## 
  ## It is intended that scaling aware clients track the
  ## current output of a surface, and if it is on a scaled
  ## output it should use wl_surface.set_buffer_scale with
  ## the scale of the output. That way the compositor can
  ## avoid scaling the surface, and the client can supply
  ## a higher detail image.
  ## 
  ## The scale event will be followed by a done event.
  cast[ptr `Wl_output / Callbacks`](this.proxy.raw.impl).scale = proc (
      factor {.inject.}: int32) =
    body

template onName*(this: Wl_output; body) =
  ## Many compositors will assign user-friendly names to their outputs, show
  ## them to the user, allow the user to refer to an output, etc. The client
  ## may wish to know this name as well to offer the user similar behaviors.
  ## 
  ## The name is a UTF-8 string with no convention defined for its contents.
  ## Each name is unique among all wl_output globals. The name is only
  ## guaranteed to be unique for the compositor instance.
  ## 
  ## The same output name is used for all clients for a given wl_output
  ## global. Thus, the name can be shared across processes to refer to a
  ## specific wl_output global.
  ## 
  ## The name is not guaranteed to be persistent across sessions, thus cannot
  ## be used to reliably identify an output in e.g. configuration files.
  ## 
  ## Examples of names include 'HDMI-A-1', 'WL-1', 'X11-1', etc. However, do
  ## not assume that the name is a reflection of an underlying DRM connector,
  ## X11 connection, etc.
  ## 
  ## The name event is sent after binding the output object. This event is
  ## only sent once per output object, and the name does not change over the
  ## lifetime of the wl_output global.
  ## 
  ## Compositors may re-use the same output name if the wl_output global is
  ## destroyed and re-created later. Compositors should avoid re-using the
  ## same name if possible.
  ## 
  ## The name event will be followed by a done event.
  cast[ptr `Wl_output / Callbacks`](this.proxy.raw.impl).name = proc (
      name {.inject.}: cstring) =
    body

template onDescription*(this: Wl_output; body) =
  ## Many compositors can produce human-readable descriptions of their
  ## outputs. The client may wish to know this description as well, e.g. for
  ## output selection purposes.
  ## 
  ## The description is a UTF-8 string with no convention defined for its
  ## contents. The description is not guaranteed to be unique among all
  ## wl_output globals. Examples might include 'Foocorp 11" Display' or
  ## 'Virtual X11 output via :1'.
  ## 
  ## The description event is sent after binding the output object and
  ## whenever the description changes. The description is optional, and may
  ## not be sent at all.
  ## 
  ## The description event will be followed by a done event.
  cast[ptr `Wl_output / Callbacks`](this.proxy.raw.impl).description = proc (
      description {.inject.}: cstring) =
    body
