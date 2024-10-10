when not (compiles do: import jnim):
  {.error: "jnim library not installed, required to cross compile to android\n please run `nimble install jnim`".}

import std/[strutils, macros, importutils, times, os, locks, deques, tables]
import pkg/[jnim, vmath]
import ../../[siwindefs]
import ../any/[window]
import ./[javalib, android, consts]


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
  eventLock: Lock

  eventQueue: Deque[proc()]
  eventDestroyQueue: seq[proc()]

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
      when defined(refc):
        GC_fullCollect()
      release drawLock
  
  proc onSurfaceCreated(surface: GL10, config: EGLConfig) =
    ##
  
  proc onSurfaceChanged(surface: GL10, width: jint, height: jint) =
    acquire drawLock
    try:
      let size = ivec2(width, height)
      for window in openWindows:
        window.raw.m_size = size
        window.raw.eventsHandler.onResize.pushEventImpl ResizeEvent(window: window.raw, size: size, initial: not window.raw.notFirstResize)
    finally:
      when defined(refc):
        GC_fullCollect()
      release drawLock


jexport SiwinGlSurfaceView extends GLSurfaceView:
  proc new*(context: Context) =
    super()

  proc nimInit*() =
    this.setEGLContextClientVersion(2)
    
    this.renderer = SiwinRenderer.new
    this.setRenderer(this.renderer)

    this.setRenderMode(0)  # RENDERMODE_WHEN_DIRTY
  

  proc onTouchEvent(event: MotionEvent): jboolean =
    acquire eventLock

    if eventDestroyQueue.len > 0:
      eventDestroyQueue = @[]
      when defined(refc):
        GC_fullCollect()

    eventQueue.addLast proc =
      let action = event.getActionMasked

      case action
      of ACTION_DOWN, ACTION_POINTER_DOWN:
        let pointerIndex =
          if action == ACTION_DOWN: 0.jint
          else: event.getActionIndex

        let pos = vec2(event.getX(pointerIndex), event.getY(pointerIndex)) - vec2(this.getX, this.getY)

        let touch = Touch(
          id:
            if action == ACTION_DOWN: 0
            else: event.getPointerId(pointerIndex),
          pos: pos
        )
        
        for window in openWindows:
          window.raw.touchScreen.pressed[touch.id] = touch
          window.raw.eventsHandler.onTouch.pushEventImpl TouchEvent(window: window.raw, pressed: true, touchId: touch.id, pos: touch.pos)

      of ACTION_UP, ACTION_POINTER_UP:
        let pointerIndex =
          if action == ACTION_UP: 0.jint
          else: event.getActionIndex
        
        let touchId =
          if action == ACTION_UP: 0
          else: event.getPointerId(pointerIndex)
        
        for window in openWindows:
          if not window.raw.touchScreen.pressed.hasKey(touchId):
            continue

          let touch = window.raw.touchScreen.pressed[touchId]
          
          window.raw.touchScreen.pressed.del touchId
          window.raw.eventsHandler.onTouch.pushEventImpl TouchEvent(window: window.raw, pressed: false, touchId: touch.id, pos: touch.pos)
      
      of ACTION_MOVE:
        for window in openWindows:
          for pointerIndex in 0..<event.getPointerCount:
            let touchId = event.getPointerId(pointerIndex)
            
            if not window.raw.touchScreen.pressed.hasKey(touchId):
              continue
            
            let pos = vec2(event.getX(pointerIndex), event.getY(pointerIndex)) - vec2(this.getX, this.getY)

            window.raw.touchScreen.pressed[touchId].pos = pos
            window.raw.eventsHandler.onTouchMove.pushEventImpl TouchMoveEvent(window: window.raw, touchId: touchId, pos: pos)

      else:
        discard
    release eventLock
    result = true.jboolean


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
    initLock eventLock
    
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
  
  acquire eventLock
  while eventQueue.len > 0:
    let f = eventQueue.popFirst()
    f()
    eventDestroyQueue.add f
  when defined(refc):
    GC_fullCollect()
  release eventLock

  release drawLock
  sleep timeToSleep
  acquire drawLock

