when not (compiles do: import jnim):
  {.error: "jnim library not installed, required to cross compile to android\n please run `nimble install jnim`".}

import std/[strutils, macros, importutils, times, os, locks]
import pkg/[jnim, vmath]
import ../../[siwindefs]
import ../any/[window]
import ./[javalib, android]


privateAccess Window


{.passl: "-lGLESv2".}  # for opengl to work


const siwin_androidLibName* {.strdefine.} = "siwintest"
const androidLoadStmt = "System.loadLibrary(\"" & siwin_androidLibName & "\");"


type
  Thread = javalib.Thread

  SiwinRenderer* = ref object of JVMObject

  SiwinGlSurfaceView* = ref object of GLSurfaceView
    renderer: SiwinRenderer

  SiwinActivity = ref object of Activity
    view: SiwinGlSurfaceView
  
  NimMainThread = ref object of Thread
  

  WindowAndroid* = ref WindowAndroidObj
  WindowAndroidObj* = object of Window
    self: WindowAndroidCursor
    notFirstResize: bool


  WindowAndroidCursor = object
    raw* {.cursor.}: WindowAndroid


  WindowAndroidSoftwareRendering* = ref object of WindowAndroid


  WindowAndroidOpengl* = ref object of WindowAndroid


var
  siwinActivity*: SiwinActivity
  openWindows*: seq[WindowAndroidCursor]
  
  drawLock: Lock

acquire drawLock


proc `=destroy`(window: WindowAndroidObj) {.siwin_destructor.} =
  let i = openWindows.find(window.self)
  if i != -1:
    openWindows.delete i



proc pushEventImpl[T](event: proc(e: T), args: T) =
  if event != nil: event(args)

macro pushEvent(eventName: untyped, args: untyped) =
  nnkStmtList.newTree(
    nnkForStmt.newTree(
      ident("window"),
      bindSym("openWindows"),
      nnkStmtList.newTree(
        nnkCall.newTree(
          nnkDotExpr.newTree(
            nnkDotExpr.newTree(
              nnkDotExpr.newTree(
                nnkDotExpr.newTree(
                  ident("window"),
                  ident("raw")
                ),
                ident("eventsHandler")
              ),
              eventName
            ),
            bindSym("pushEventImpl")
          ),
          args
        )
      )
    )
  )



jexport SiwinRenderer implements Renderer:
  proc new* =
    super()

  proc onDrawFrame(surface: GL10) =
    acquire drawLock
    try:
      pushEvent onRender, RenderEvent(window: window.raw)
    finally:
      release drawLock
  
  proc onSurfaceCreated(surface: GL10, config: EGLConfig) =
    ##
  
  proc onSurfaceChanged(surface: GL10, width: jint, height: jint) =
    acquire drawLock
    try:
      let size = ivec2(width, height)
      pushEvent onResize, ResizeEvent(window: window.raw, size: size, initial: not window.raw.notFirstResize)
    finally:
      release drawLock


jexport SiwinGlSurfaceView extends GLSurfaceView:
  proc new*(context: Context) =
    super()

  proc nimInit*() =
    this.setEGLContextClientVersion(2)
    
    this.renderer = SiwinRenderer.new
    this.setRenderer(this.renderer)

    this.setRenderMode(0)  # RENDERMODE_WHEN_DIRTY


jexport NimMainThread extends Thread:
  proc new* =
    super()

  proc run() =
    proc NimMain {.importc.}
    NimMain()


jexport SiwinActivity extends Activity:
  proc new* =
    super()
  
  staticSection androidLoadStmt


  proc onCreate(b: Bundle) =
    this.super.onCreate(b)

    siwinActivity = this

    this.view = SiwinGlSurfaceView.new(this)
    this.view.nimInit()

    this.setContentView(this.view)

    initLock drawLock
    
    start NimMainThread.new()



when defined(jnimGenDex):
  const siwin_generateDex_out {.strdefine.} = "build/siwin_gen_dex.nim"
  jnimDexWrite(siwin_generateDex_out)



proc basicInitWindow(window: WindowAndroid, size: IVec2) =
  openWindows.add WindowAndroidCursor(raw: window)


proc initSoftwareRenderingWindow(
  window: WindowAndroidSoftwareRendering,
  size: IVec2,
  fullscreen, frameless, transparent: bool,
) =
  window.basicInitWindow size


proc initOpenglWindow(
  window: WindowAndroidOpengl,
  size: IVec2,
  fullscreen, frameless, transparent: bool,
) =
  window.basicInitWindow size


method close*(window: WindowAndroid) =
  window.m_closed = true
  let i = openWindows.find(WindowAndroidCursor(raw: window))
  if i != -1:
    openWindows.delete i


method `title=`*(window: WindowAndroid, title: string) =
  siwinActivity.setTitle(title)

method redraw*(window: WindowAndroid) =
  siwinActivity.view.requestRender()


proc newSoftwareRenderingWindowAndroid*(
  size = ivec2(1280, 720),
  title = "",
  # screen = defaultScreenAndroid(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,

  class = "", # window class (used in x11), equals to title if not specified
): WindowAndroidSoftwareRendering =
  new result
  result.initSoftwareRenderingWindow(size, fullscreen, frameless, transparent)
  result.title = title
  if not resizable: result.resizable = false


proc newOpenglWindowAndroid*(
  size = ivec2(1280, 720),
  title = "",
  # screen = defaultScreenAndroid(),
  resizable = true,
  fullscreen = false,
  frameless = false,
  transparent = false,
  vsync = true,

  class = "", # window class (used in x11), equals to title if not specified
): WindowAndroidOpengl =
  new result
  result.initOpenglWindow(size, fullscreen, frameless, transparent)
  result.title = title
  result.`vsync=`(vsync, silent=true)
  if not resizable: result.resizable = false


method firstStep*(window: WindowAndroid, makeVisible = true) =
  if makeVisible:
    window.visible = true
  
  redraw window


method step*(window: WindowAndroid) =
  let time = getTime()
  window.eventsHandler.onTick.pushEventImpl TickEvent(window: window, deltaTime: time - window.lastTickTime)
  window.lastTickTime = time
  let timeToSleep =
    if time - window.lastTickTime > initDuration(milliseconds=10):
      1
    else:
      20

  release drawLock
  sleep timeToSleep
  acquire drawLock

