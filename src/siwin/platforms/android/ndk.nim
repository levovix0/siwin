import jnim
import android/os/bundle
import jnim/java/lang # for Runnable
import android / content / [ context_wrapper, intent ]
import android/app/application
import android/view/window_manager


{.push, warning[Spacing]: off.}

jclassDef android.View* of JVMObject
jclassDef javax.microedition.khronos.opengles.GL10* of JVMObject
jclassDef javax.microedition.khronos.egl.EGLConfig* of JVMObject


jclass android.opengl.GLSurfaceView$Renderer* of JVMObject:
  proc onSurfaceCreated*(surface: GL10, config: EGLConfig)
  proc onSurfaceChanged*(surface: GL10, width: jint, height: jint)
  proc onDrawFrame*(surface: GL10)


jclass android.opengl.GLSurfaceView* of View:
  proc setRenderer*(renderer: Renderer)
  proc setEGLContextClientVersion*(version: jint)
  proc setRenderMode*(mode: jint)


jclass android.app.Activity* of ContextWrapper:
  proc runOnUiThread*(r: Runnable)
  proc getIntent*(): Intent
  proc getApplication*(): Application
  proc getWindowManager*(): WindowManager
  proc onCreate*(savedInstanceState: Bundle)
  proc setContentView*(view: View)

{.pop.}


type
  SiwinRenderer* = ref object of Renderer

  SiwinActivity = ref object of Activity
    view: GLSurfaceView
    renderer: SiwinRenderer


jexport SiwinRenderer extends Renderer:
  proc onSurfaceCreated(surface: GL10, config: EGLConfig) =
    ##
  proc onSurfaceChanged(surface: GL10, width: jint, height: jint) =
    ##
  proc onDrawFrame(surface: GL10) =
    ##

jexport SiwinActivity extends Activity:
  proc new* =
    # proc NimMain {.importc.}
    # NimMain()
    # initJNI()
    # initJNIThread()
    super()
  
  proc onCreate(b: Bundle) =
    this.super.onCreate(b)
    this.view = GLSurfaceView.new
    this.renderer = SiwinRenderer.new
    this.view.setRenderer(this.renderer)
    this.setContentView(this.view)
    this.view.setRenderMode(0)  # RENDERMODE_WHEN_DIRTY


when defined(jnimGenDex):
  const siwin_generateDex_out {.strdefine.} = "build/siwin_gen_dex.nim"
  jnimDexWrite(siwin_generateDex_out)
