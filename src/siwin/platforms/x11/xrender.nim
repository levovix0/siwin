import x11/xrender as xrenderBindings
import ./x11api
import ../../siwindefs

export xrenderBindings except XRenderFindVisualFormat

siwin_loadDynlibIfExists libXrenderHandle:
  proc XRenderFindVisualFormat*(dpy: PDisplay, visual: PVisual): PXRenderPictFormat

proc xrenderAvailable*(): bool =
  libXrenderHandle != nil and XRenderFindVisualFormat != nil
