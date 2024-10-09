when not (compiles do: import jnim):
  {.error: "jnim library not installed, required to cross compile to android\n please run `nimble install jnim`".}

import std/[strutils]
import pkg/[jnim, vmath]
import ../../[siwindefs]
import ../any/[window]
import ./[javalib, android]


const siwin_androidLibName* {.strdefine.} = "siwintest"
const androidLoadStmt = "System.loadLibrary(\"" & siwin_androidLibName & "\");"


type
  SiwinRenderer* = ref object of JVMObject

  SiwinGlSurfaceView* = ref object of GLSurfaceView
    renderer: SiwinRenderer

  SiwinActivity = ref object of Activity
    view: SiwinGlSurfaceView
  

  WindowAndroid* = ref WindowAndroidObj
  WindowAndroidObj* = object of Window
    self: WindowAndroidCursor


  WindowAndroidCursor = object
    raw* {.cursor.}: WindowAndroid


  WindowAndroidSoftwareRendering* = ref object of WindowAndroid


  WindowAndroidOpengl* = ref object of WindowAndroid



var
  siwinActivity*: SiwinActivity
  openWindows*: seq[WindowAndroidCursor]


proc `=destroy`(window: WindowAndroidObj) {.siwin_destructor.} =
  let i = openWindows.find(window.self)
  if i != -1:
    openWindows.delete i


jexport SiwinRenderer implements Renderer:
  proc new* =
    super()

  proc onDrawFrame(surface: GL10) =
    GLES20.glClearColor(0.2, 0.2, 0.2, 1)
    GLES20.glClear(0x00004000.int32)  # GL_COLOR_BUFFER_BIT
  
  proc onSurfaceCreated(surface: GL10, config: EGLConfig) =
    ##
  
  proc onSurfaceChanged(surface: GL10, width: jint, height: jint) =
    ##


jclassDef com.levovix.siwintest.MyGLRenderer * of Renderer


jexport SiwinGlSurfaceView extends GLSurfaceView:
  proc new*(context: Context) =
    super()

  proc nimInit*() =
    this.setEGLContextClientVersion(2)
    
    this.renderer = SiwinRenderer.new
    this.setRenderer(this.renderer)

    this.setRenderMode(0)  # RENDERMODE_WHEN_DIRTY


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

    proc NimMain {.importc.}
    NimMain()



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
  let i = openWindows.find(WindowAndroidCursor(raw: window))
  if i != -1:
    openWindows.delete i


method `title=`*(window: WindowAndroid, title: string) =
  siwinActivity.setTitle(title)



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


when isMainModule:
  let win = newOpenglWindowAndroid(title="Доброе утро!")
  close win
  # run win
