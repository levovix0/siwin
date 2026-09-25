import std/dynlib
import ./x11types as x11Types

export x11Types except Screen, Window, Cursor, Time

type XGetXCBConnectionProc = proc(display: PDisplay): pointer {.cdecl, raises: [].}

proc loadFirst*(names: openArray[string]): LibHandle =
  for name in names:
    result = loadLib(name)
    if result != nil:
      return

proc loadProc*[T](handle: LibHandle, name: string): T =
  if handle != nil:
    result = cast[T](symAddr(handle, name))

let
  libX11Handle* = loadFirst(
    [
      when defined(macosx): "libX11.dylib" else: "libX11.so",
      when defined(macosx): "libX11.so" else: "libX11.so.6",
    ]
  )
  libXextHandle* = loadFirst(
    [
      when defined(macosx): "libXext.dylib" else: "libXext.so",
      when defined(macosx): "libXext.so" else: "libXext.so.6",
    ]
  )
  libXcursorHandle* = loadFirst(
    [
      when defined(macosx): "libXcursor.dylib" else: "libXcursor.so",
      when defined(macosx): "libXcursor.so" else: "libXcursor.so.1",
    ]
  )
  libXrenderHandle* = loadFirst(
    [
      when defined(macosx): "libXrender.dylib" else: "libXrender.so",
      when defined(macosx): "libXrender.so" else: "libXrender.so.1",
    ]
  )
  # The Xlib/XCB bridge is only needed by callers using XCB surfaces.
  libX11XcbHandle* = loadFirst(
    [
      when defined(macosx): "libX11-xcb.dylib" else: "libX11-xcb.so",
      when defined(macosx): "libX11-xcb.so" else: "libX11-xcb.so.1",
    ]
  )

let XGetXCBConnection* =
  loadProc[XGetXCBConnectionProc](libX11XcbHandle, "XGetXCBConnection")

proc x11XcbAvailable*(): bool =
  XGetXCBConnection != nil

let
  XChangeProperty* =
    loadProc[x11Types.x11_XChangeProperty](libX11Handle, "XChangeProperty")
  XCloseDisplay* = loadProc[x11Types.x11_XCloseDisplay](libX11Handle, "XCloseDisplay")
  XCloseIM* = loadProc[x11Types.x11_XCloseIM](libX11Handle, "XCloseIM")
  XConnectionNumber* =
    loadProc[x11Types.x11_XConnectionNumber](libX11Handle, "XConnectionNumber")
  XConvertSelection* =
    loadProc[x11Types.x11_XConvertSelection](libX11Handle, "XConvertSelection")
  XCreateBitmapFromData* =
    loadProc[x11Types.x11_XCreateBitmapFromData](libX11Handle, "XCreateBitmapFromData")
  XCreateColormap* =
    loadProc[x11Types.x11_XCreateColormap](libX11Handle, "XCreateColormap")
  XCreateFontCursor* =
    loadProc[x11Types.x11_XCreateFontCursor](libX11Handle, "XCreateFontCursor")
  XCreateGC* = loadProc[x11Types.x11_XCreateGC](libX11Handle, "XCreateGC")
  XCreateIC* = loadProc[x11Types.x11_XCreateIC](libX11Handle, "XCreateIC")
  XCreatePixmap* = loadProc[x11Types.x11_XCreatePixmap](libX11Handle, "XCreatePixmap")
  XCreatePixmapCursor* =
    loadProc[x11Types.x11_XCreatePixmapCursor](libX11Handle, "XCreatePixmapCursor")
  XCreateSimpleWindow* =
    loadProc[x11Types.x11_XCreateSimpleWindow](libX11Handle, "XCreateSimpleWindow")
  XCreateWindow* = loadProc[x11Types.x11_XCreateWindow](libX11Handle, "XCreateWindow")
  XDefineCursor* = loadProc[x11Types.x11_XDefineCursor](libX11Handle, "XDefineCursor")
  XDeleteProperty* =
    loadProc[x11Types.x11_XDeleteProperty](libX11Handle, "XDeleteProperty")
  XDestroyIC* = loadProc[x11Types.x11_XDestroyIC](libX11Handle, "XDestroyIC")
  XDestroyWindow* =
    loadProc[x11Types.x11_XDestroyWindow](libX11Handle, "XDestroyWindow")
  XFlush* = loadProc[x11Types.x11_XFlush](libX11Handle, "XFlush")
  XFree* = loadProc[x11Types.x11_XFree](libX11Handle, "XFree")
  XFreeCursor* = loadProc[x11Types.x11_XFreeCursor](libX11Handle, "XFreeCursor")
  XFreeGC* = loadProc[x11Types.x11_XFreeGC](libX11Handle, "XFreeGC")
  XFreePixmap* = loadProc[x11Types.x11_XFreePixmap](libX11Handle, "XFreePixmap")
  XGetAtomName* = loadProc[x11Types.x11_XGetAtomName](libX11Handle, "XGetAtomName")
  XGetDefault* = loadProc[x11Types.x11_XGetDefault](libX11Handle, "XGetDefault")
  XGetGeometry* = loadProc[x11Types.x11_XGetGeometry](libX11Handle, "XGetGeometry")
  XGetSelectionOwner* =
    loadProc[x11Types.x11_XGetSelectionOwner](libX11Handle, "XGetSelectionOwner")
  XGetVisualInfo* =
    loadProc[x11Types.x11_XGetVisualInfo](libX11Handle, "XGetVisualInfo")
  XGetWindowAttributes* =
    loadProc[x11Types.x11_XGetWindowAttributes](libX11Handle, "XGetWindowAttributes")
  XGetWindowProperty* =
    loadProc[x11Types.x11_XGetWindowProperty](libX11Handle, "XGetWindowProperty")
  XIconifyWindow* =
    loadProc[x11Types.x11_XIconifyWindow](libX11Handle, "XIconifyWindow")
  XInternAtom* = loadProc[x11Types.x11_XInternAtom](libX11Handle, "XInternAtom")
  XKeycodeToKeysym* =
    loadProc[x11Types.x11_XKeycodeToKeysym](libX11Handle, "XKeycodeToKeysym")
  XLookupKeysym* = loadProc[x11Types.x11_XLookupKeysym](libX11Handle, "XLookupKeysym")
  XMapRaised* = loadProc[x11Types.x11_XMapRaised](libX11Handle, "XMapRaised")
  XMapWindow* = loadProc[x11Types.x11_XMapWindow](libX11Handle, "XMapWindow")
  XMoveWindow* = loadProc[x11Types.x11_XMoveWindow](libX11Handle, "XMoveWindow")
  XNextEvent* = loadProc[x11Types.x11_XNextEvent](libX11Handle, "XNextEvent")
  XOpenDisplay* = loadProc[x11Types.x11_XOpenDisplay](libX11Handle, "XOpenDisplay")
  XOpenIM* = loadProc[x11Types.x11_XOpenIM](libX11Handle, "XOpenIM")
  XPending* = loadProc[x11Types.x11_XPending](libX11Handle, "XPending")
  XPutImage* = loadProc[x11Types.x11_XPutImage](libX11Handle, "XPutImage")
  XQueryKeymap* = loadProc[x11Types.x11_XQueryKeymap](libX11Handle, "XQueryKeymap")
  XQueryPointer* = loadProc[x11Types.x11_XQueryPointer](libX11Handle, "XQueryPointer")
  XRaiseWindow* = loadProc[x11Types.x11_XRaiseWindow](libX11Handle, "XRaiseWindow")
  XResizeWindow* = loadProc[x11Types.x11_XResizeWindow](libX11Handle, "XResizeWindow")
  XRootWindow* = loadProc[x11Types.x11_XRootWindow](libX11Handle, "XRootWindow")
  XSelectInput* = loadProc[x11Types.x11_XSelectInput](libX11Handle, "XSelectInput")
  XSendEvent* = loadProc[x11Types.x11_XSendEvent](libX11Handle, "XSendEvent")
  XSetICFocus* = loadProc[x11Types.x11_XSetICFocus](libX11Handle, "XSetICFocus")
  XSetSelectionOwner* =
    loadProc[x11Types.x11_XSetSelectionOwner](libX11Handle, "XSetSelectionOwner")
  XSetTransientForHint* =
    loadProc[x11Types.x11_XSetTransientForHint](libX11Handle, "XSetTransientForHint")
  XSetWMProtocols* =
    loadProc[x11Types.x11_XSetWMProtocols](libX11Handle, "XSetWMProtocols")
  XSync* = loadProc[x11Types.x11_XSync](libX11Handle, "XSync")
  XTranslateCoordinates* =
    loadProc[x11Types.x11_XTranslateCoordinates](libX11Handle, "XTranslateCoordinates")
  XUngrabPointer* =
    loadProc[x11Types.x11_XUngrabPointer](libX11Handle, "XUngrabPointer")
  XUnmapWindow* = loadProc[x11Types.x11_XUnmapWindow](libX11Handle, "XUnmapWindow")
  XUnsetICFocus* = loadProc[x11Types.x11_XUnsetICFocus](libX11Handle, "XUnsetICFocus")
  XVisualIDFromVisual* =
    loadProc[x11Types.x11_XVisualIDFromVisual](libX11Handle, "XVisualIDFromVisual")
  Xutf8LookupString* =
    loadProc[x11Types.x11_Xutf8LookupString](libX11Handle, "Xutf8LookupString")

  XGetNormalHints* =
    loadProc[x11Types.x11_XGetNormalHints](libX11Handle, "XGetNormalHints")
  XMatchVisualInfo* =
    loadProc[x11Types.x11_XMatchVisualInfo](libX11Handle, "XMatchVisualInfo")
  XSetClassHint* = loadProc[x11Types.x11_XSetClassHint](libX11Handle, "XSetClassHint")
  XSetNormalHints* =
    loadProc[x11Types.x11_XSetNormalHints](libX11Handle, "XSetNormalHints")
  XSetWMHints* = loadProc[x11Types.x11_XSetWMHints](libX11Handle, "XSetWMHints")
  Xutf8SetWMProperties* =
    loadProc[x11Types.x11_Xutf8SetWMProperties](libX11Handle, "Xutf8SetWMProperties")

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
