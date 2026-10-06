import std/dynlib
import x11/[x, xlib, xutil]
import ../../siwindefs

export xlib except
  Screen, Window, Cursor, Time, XChangeProperty, XCloseDisplay, XCloseIM, XConnectionNumber,
  XConvertSelection, XCreateBitmapFromData, XCreateColormap, XCreateFontCursor, XCreateGC,
  XCreateIC, XCreatePixmap, XCreatePixmapCursor, XCreateSimpleWindow, XCreateWindow, XDefineCursor,
  XDeleteProperty, XDestroyIC, XDestroyWindow, XFlush, XFree, XFreeCursor, XFreeGC, XFreePixmap,
  XGetAtomName, XGetDefault, XGetGeometry, XGetSelectionOwner, XGetWindowProperty, XIconifyWindow,
  XInternAtom, XKeycodeToKeysym, XLookupKeysym, XMapRaised, XMapWindow, XMoveWindow, XNextEvent,
  XOpenDisplay, XOpenIM, XPending, XPutImage, XQueryKeymap, XQueryPointer, XRaiseWindow,
  XResizeWindow, XRootWindow, XSelectInput, XSendEvent, XSetICFocus, XSetSelectionOwner,
  XSetTransientForHint, XSetWMProtocols, XSync, XTranslateCoordinates, XUngrabPointer,
  XUnmapWindow, XUnsetICFocus, XVisualIDFromVisual, XGetWindowAttributes, Xutf8LookupString
export xutil except
  XGetNormalHints, XGetVisualInfo, XMatchVisualInfo, XSetClassHint, XSetNormalHints, XSetWMHints,
  Xutf8SetWMProperties

let
  libX11Handle* = loadLibPattern(when defined(macosx): "libX11.(dylib|so)" else: "libX11.so(|.6)")
  libXextHandle* = loadLibPattern(when defined(macosx): "libXext.(dylib|so)" else: "libXext.so(|.6)")
  libXcursorHandle* = loadLibPattern(when defined(macosx): "libXcursor.(dylib|so)" else: "libXcursor.so(|.1)")
  libXrenderHandle* = loadLibPattern(when defined(macosx): "libXrender.(dylib|so)" else: "libXrender.so(|.1)")

  # The Xlib/XCB bridge is only needed by callers using XCB surfaces.
  libX11XcbHandle* = loadLibPattern(when defined(macosx): "libX11-xcb.(dylib|so)" else: "libX11-xcb.so(|.1)")

siwin_loadDynlibIfExists libX11XcbHandle:
  proc XGetXCBConnection*(display: PDisplay): pointer {.raises: [].}

proc x11XcbAvailable*(): bool =
  XGetXCBConnection != nil

siwin_loadDynlibIfExists libX11Handle:
  proc XChangeProperty*(
    para1: PDisplay,
    para2: Window,
    para3: Atom,
    para4: Atom,
    para5: cint,
    para6: cint,
    para7: Pcuchar,
    para8: cint,
  ): cint {.raises: [].}
  proc XCloseDisplay*(para1: PDisplay): cint {.raises: [].}
  proc XCloseIM*(para1: XIM): Status {.varargs, raises: [].}
  proc XConnectionNumber*(para1: PDisplay): cint {.raises: [].}
  proc XConvertSelection*(
    para1: PDisplay, para2: Atom, para3: Atom, para4: Atom, para5: Window, para6: Time
  ): cint {.raises: [].}
  proc XCreateBitmapFromData*(
    para1: PDisplay, para2: Drawable, para3: cstring, para4: cuint, para5: cuint
  ): Pixmap {.raises: [].}
  proc XCreateColormap*(
    para1: PDisplay, para2: Window, para3: PVisual, para4: cint
  ): Colormap {.raises: [].}
  proc XCreateFontCursor*(para1: PDisplay, para2: cuint): Cursor {.raises: [].}
  proc XCreateGC*(
    para1: PDisplay, para2: Drawable, para3: culong, para4: PXGCValues
  ): GC {.raises: [].}
  proc XCreateIC*(para1: XIM): XIC {.varargs, raises: [].}
  proc XCreatePixmap*(
    para1: PDisplay, para2: Drawable, para3: cuint, para4: cuint, para5: cuint
  ): Pixmap {.raises: [].}
  proc XCreatePixmapCursor*(
    para1: PDisplay,
    para2: Pixmap,
    para3: Pixmap,
    para4: PXColor,
    para5: PXColor,
    para6: cuint,
    para7: cuint,
  ): Cursor {.raises: [].}
  proc XCreateSimpleWindow*(
    para1: PDisplay,
    para2: Window,
    para3: cint,
    para4: cint,
    para5: cuint,
    para6: cuint,
    para7: cuint,
    para8: culong,
    para9: culong,
  ): Window {.raises: [].}
  proc XCreateWindow*(
    para1: PDisplay,
    para2: Window,
    para3: cint,
    para4: cint,
    para5: cuint,
    para6: cuint,
    para7: cuint,
    para8: cint,
    para9: cuint,
    para10: PVisual,
    para11: culong,
    para12: PXSetWindowAttributes,
  ): Window {.raises: [].}
  proc XDefineCursor*(para1: PDisplay, para2: Window, para3: Cursor): cint {.raises: [].}
  proc XDeleteProperty*(para1: PDisplay, para2: Window, para3: Atom): cint {.raises: [].}
  proc XDestroyIC*(para1: XIC) {.raises: [].}
  proc XDestroyWindow*(para1: PDisplay, para2: Window): cint {.raises: [].}
  proc XFlush*(para1: PDisplay): cint {.raises: [].}
  proc XFree*(para1: pointer): cint {.raises: [].}
  proc XFreeCursor*(para1: PDisplay, para2: Cursor): cint {.raises: [].}
  proc XFreeGC*(para1: PDisplay, para2: GC): cint {.raises: [].}
  proc XFreePixmap*(para1: PDisplay, para2: Pixmap): cint {.raises: [].}
  proc XGetAtomName*(para1: PDisplay, para2: Atom): cstring {.raises: [].}
  proc XGetDefault*(para1: PDisplay, para2: cstring, para3: cstring): cstring {.raises: [].}
  proc XGetGeometry*(
    para1: PDisplay,
    para2: Drawable,
    para3: PWindow,
    para4: Pcint,
    para5: Pcint,
    para6: Pcuint,
    para7: Pcuint,
    para8: Pcuint,
    para9: Pcuint,
  ): Status {.raises: [].}
  proc XGetSelectionOwner*(para1: PDisplay, para2: Atom): Window {.raises: [].}
  proc XGetVisualInfo*(
    para1: PDisplay, para2: clong, para3: PXVisualInfo, para4: Pcint
  ): PXVisualInfo {.raises: [].}
  proc XGetWindowAttributes*(
    para1: PDisplay, para2: Window, para3: PXWindowAttributes
  ): Status {.raises: [].}
  proc XGetWindowProperty*(
    para1: PDisplay,
    para2: Window,
    para3: Atom,
    para4: clong,
    para5: clong,
    para6: XBool,
    para7: Atom,
    para8: PAtom,
    para9: Pcint,
    para10: Pculong,
    para11: Pculong,
    para12: PPcuchar,
  ): cint {.raises: [].}
  proc XIconifyWindow*(para1: PDisplay, para2: Window, para3: cint): Status {.raises: [].}
  proc XInternAtom*(para1: PDisplay, para2: cstring, para3: XBool): Atom {.raises: [].}
  proc XKeycodeToKeysym*(para1: PDisplay, para2: KeyCode, para3: cint): KeySym {.raises: [].}
  proc XLookupKeysym*(para1: PXKeyEvent, para2: cint): KeySym {.raises: [].}
  proc XMapRaised*(para1: PDisplay, para2: Window): cint {.raises: [].}
  proc XMapWindow*(para1: PDisplay, para2: Window): cint {.raises: [].}
  proc XMoveWindow*(
    para1: PDisplay, para2: Window, para3: cint, para4: cint
  ): cint {.raises: [].}
  proc XNextEvent*(para1: PDisplay, para2: PXEvent): cint {.raises: [].}
  proc XOpenDisplay*(para1: cstring): PDisplay {.raises: [].}
  proc XOpenIM*(
    para1: PDisplay, para2: PXrmHashBucketRec, para3: cstring, para4: cstring
  ): XIM {.raises: [].}
  proc XPending*(para1: PDisplay): cint {.raises: [].}
  proc XPutImage*(
    para1: PDisplay,
    para2: Drawable,
    para3: GC,
    para4: PXImage,
    para5: cint,
    para6: cint,
    para7: cint,
    para8: cint,
    para9: cuint,
    para10: cuint,
  ): cint {.raises: [].}
  proc XQueryKeymap*(para1: PDisplay, para2: chararr32): cint {.raises: [].}
  proc XQueryPointer*(
    para1: PDisplay,
    para2: Window,
    para3: PWindow,
    para4: PWindow,
    para5: Pcint,
    para6: Pcint,
    para7: Pcint,
    para8: Pcint,
    para9: Pcuint,
  ): XBool {.raises: [].}
  proc XRaiseWindow*(para1: PDisplay, para2: Window): cint {.raises: [].}
  proc XResizeWindow*(
    para1: PDisplay, para2: Window, para3: cuint, para4: cuint
  ): cint {.raises: [].}
  proc XRootWindow*(para1: PDisplay, para2: cint): Window {.raises: [].}
  proc XSelectInput*(para1: PDisplay, para2: Window, para3: clong): cint {.raises: [].}
  proc XSendEvent*(
    para1: PDisplay, para2: Window, para3: XBool, para4: clong, para5: PXEvent
  ): Status {.raises: [].}
  proc XSetICFocus*(para1: XIC) {.raises: [].}
  proc XSetSelectionOwner*(
    para1: PDisplay, para2: Atom, para3: Window, para4: Time
  ): cint {.raises: [].}
  proc XSetTransientForHint*(para1: PDisplay, para2: Window, para3: Window): cint {.raises: [].}
  proc XSetWMProtocols*(
    para1: PDisplay, para2: Window, para3: PAtom, para4: cint
  ): Status {.raises: [].}
  proc XSync*(para1: PDisplay, para2: XBool): cint {.raises: [].}
  proc XTranslateCoordinates*(
    para1: PDisplay,
    para2: Window,
    para3: Window,
    para4: cint,
    para5: cint,
    para6: Pcint,
    para7: Pcint,
    para8: PWindow,
  ): XBool {.raises: [].}
  proc XUngrabPointer*(para1: PDisplay, para2: Time): cint {.raises: [].}
  proc XUnmapWindow*(para1: PDisplay, para2: Window): cint {.raises: [].}
  proc XUnsetICFocus*(para1: XIC) {.raises: [].}
  proc XVisualIDFromVisual*(para1: PVisual): VisualID {.raises: [].}
  proc Xutf8LookupString*(
    para1: XIC,
    para2: PXKeyPressedEvent,
    para3: cstring,
    para4: cint,
    para5: PKeySym,
    para6: PStatus,
  ): cint {.raises: [].}
  proc XGetNormalHints*(para1: PDisplay, para2: Window, para3: PXSizeHints): Status {.raises: [].}
  proc XMatchVisualInfo*(
    para1: PDisplay, para2: cint, para3: cint, para4: cint, para5: PXVisualInfo
  ): Status {.raises: [].}
  proc XSetClassHint*(para1: PDisplay, para2: Window, para3: PXClassHint): cint {.raises: [].}
  proc XSetNormalHints*(para1: PDisplay, para2: Window, para3: PXSizeHints): cint {.raises: [].}
  proc XSetWMHints*(para1: PDisplay, para2: Window, para3: PXWMHints): cint {.raises: [].}
  proc Xutf8SetWMProperties*(
    para1: PDisplay,
    para2: Window,
    para3: cstring,
    para4: cstring,
    para5: PPchar,
    para6: cint,
    para7: PXSizeHints,
    para8: PXWMHints,
    para9: PXClassHint,
  ) {.raises: [].}

proc x11Available*(): bool =
  libX11Handle != nil and XChangeProperty != nil and XCloseDisplay != nil and
    XCloseIM != nil and XConnectionNumber != nil and XConvertSelection != nil and
    XCreateBitmapFromData != nil and XCreateColormap != nil and XCreateFontCursor != nil and
    XCreateGC != nil and XCreateIC != nil and XCreatePixmap != nil and
    XCreatePixmapCursor != nil and XCreateSimpleWindow != nil and XCreateWindow != nil and
    XDefineCursor != nil and XDeleteProperty != nil and XDestroyIC != nil and
    XDestroyWindow != nil and XFlush != nil and XFree != nil and XFreeCursor != nil and
    XFreeGC != nil and XFreePixmap != nil and XGetAtomName != nil and XGetDefault != nil and
    XGetGeometry != nil and XGetSelectionOwner != nil and XGetVisualInfo != nil and
    XGetWindowAttributes != nil and XGetWindowProperty != nil and XIconifyWindow != nil and
    XInternAtom != nil and XKeycodeToKeysym != nil and XLookupKeysym != nil and
    XMapRaised != nil and XMapWindow != nil and XNextEvent != nil and XMoveWindow != nil and
    XOpenDisplay != nil and XOpenIM != nil and XPending != nil and XPutImage != nil and
    XQueryKeymap != nil and XQueryPointer != nil and XRaiseWindow != nil and
    XResizeWindow != nil and XRootWindow != nil and XSelectInput != nil and
    XSendEvent != nil and XSetICFocus != nil and XSetSelectionOwner != nil and
    XSetTransientForHint != nil and XSetWMProtocols != nil and XSync != nil and
    XTranslateCoordinates != nil and XUngrabPointer != nil and XUnmapWindow != nil and
    XUnsetICFocus != nil and XVisualIDFromVisual != nil and Xutf8LookupString != nil and
    XGetNormalHints != nil and XMatchVisualInfo != nil and XSetClassHint != nil and
    XSetNormalHints != nil and XSetWMHints != nil and Xutf8SetWMProperties != nil
