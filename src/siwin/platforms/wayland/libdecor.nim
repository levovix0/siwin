import std/[dynlib]
import ../../[siwindefs]

type
  LibdecorContext* = pointer
  LibdecorFrame* = pointer
  LibdecorConfiguration* = pointer
  LibdecorState* = pointer

  LibdecorWindowState* = enum
    none = 0
    active = 1
    maximized = 2
    fullscreen = 4
    tiledLeft = 8
    tiledRight = 16
    tiledTop = 32
    tiledBottom = 64

  LibdecorError* = enum
    compositorIncompatible = 0
    invalidFrameConfiguration = 1

  LibdecorInterface* = object
    error*: proc(context: LibdecorContext, error: LibdecorError, message: cstring) {.cdecl.}
    reserved0: pointer
    reserved1: pointer
    reserved2: pointer
    reserved3: pointer
    reserved4: pointer
    reserved5: pointer
    reserved6: pointer
    reserved7: pointer
    reserved8: pointer
    reserved9: pointer

  LibdecorFrameInterface* = object
    configure*: proc(frame: LibdecorFrame, configuration: LibdecorConfiguration, userData: pointer) {.cdecl.}
    close*: proc(frame: LibdecorFrame, userData: pointer) {.cdecl.}
    commit*: proc(frame: LibdecorFrame, userData: pointer) {.cdecl.}
    dismissPopup*: proc(frame: LibdecorFrame, seatName: cstring, userData: pointer) {.cdecl.}
    reserved0: pointer
    reserved1: pointer
    reserved2: pointer
    reserved3: pointer
    reserved4: pointer
    reserved5: pointer
    reserved6: pointer
    reserved7: pointer
    reserved8: pointer
    reserved9: pointer

var
  libdecorHandle = loadLib("libdecor-0.so")

if libdecorHandle == nil:
  libdecorHandle = loadLib("libdecor-0.so.0")

siwin_loadDynlibIfExists libdecorHandle:
  proc libdecor_new*(display: pointer, iface: ptr LibdecorInterface): LibdecorContext
  proc libdecor_unref*(context: LibdecorContext)
  proc libdecor_dispatch*(context: LibdecorContext, timeout: cint): cint

  proc libdecor_decorate*(context: LibdecorContext, surface: pointer,
                          iface: ptr LibdecorFrameInterface,
                          userData: pointer): LibdecorFrame
  proc libdecor_frame_unref*(frame: LibdecorFrame)
  proc libdecor_frame_map*(frame: LibdecorFrame)

  proc libdecor_frame_set_title*(frame: LibdecorFrame, title: cstring)
  proc libdecor_frame_set_app_id*(frame: LibdecorFrame, appId: cstring)
  proc libdecor_frame_set_visibility*(frame: LibdecorFrame, visible: bool)

  proc libdecor_frame_commit*(frame: LibdecorFrame, state: LibdecorState,
                              configuration: LibdecorConfiguration)

  proc libdecor_frame_set_min_content_size*(frame: LibdecorFrame, w: cint, h: cint)
  proc libdecor_frame_set_max_content_size*(frame: LibdecorFrame, w: cint, h: cint)

  proc libdecor_state_new*(w: cint, h: cint): LibdecorState
  proc libdecor_state_free*(state: LibdecorState)

  proc libdecor_configuration_get_content_size*(configuration: LibdecorConfiguration,
                                                frame: LibdecorFrame,
                                                w: ptr cint, h: ptr cint): bool
  proc libdecor_configuration_get_window_state*(configuration: LibdecorConfiguration,
                                                windowState: ptr uint32): bool

  proc libdecor_frame_set_fullscreen*(frame: LibdecorFrame, output: pointer)
  proc libdecor_frame_unset_fullscreen*(frame: LibdecorFrame)
  proc libdecor_frame_set_maximized*(frame: LibdecorFrame)
  proc libdecor_frame_unset_maximized*(frame: LibdecorFrame)
  proc libdecor_frame_set_minimized*(frame: LibdecorFrame)

  proc libdecor_frame_move*(frame: LibdecorFrame, seat: pointer, serial: uint32)
  proc libdecor_frame_resize*(frame: LibdecorFrame, seat: pointer, serial: uint32, edge: uint32)

  proc libdecor_frame_show_window_menu*(frame: LibdecorFrame, seat: pointer, serial: uint32, x: cint, y: cint)


proc libdecorAvailable*(): bool =
  libdecor_new != nil
