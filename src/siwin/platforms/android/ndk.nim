when not (compiles do: import jnim):
  {.error: "jnim library not installed, required to cross compile to android\n please run `nimble install jnim`".}

when not (compiles do: import android/app/application):
  {.error: "android library not installed, required to cross compile to android\n please run `nimble install https://github.com/levovix0/android`".}

import std/[strutils]
import jnim
import android/os/bundle
import jnim/java/lang # for Runnable
import android/content/[context, context_wrapper, intent]
# import android/app/application
import android/view/window_manager



# jclassDef android.View * of JVMObject
# jclassDef javax.microedition.khronos.opengles.GL10 * of JVMObject
# jclassDef javax.microedition.khronos.egl.EGLConfig * of JVMObject


# jclass android.opengl.GLES20 * of JVMObject:
#   proc glClearColor*(r: float32, g: float32, b: float32, a: float32) {.static.}
#   proc glClear*(v: int32) {.static.}


# jclass android.opengl.GLSurfaceView$Renderer * of JVMObject:
#   proc onSurfaceCreated*(surface: GL10, config: EGLConfig)
#   proc onSurfaceChanged*(surface: GL10, width: jint, height: jint)
#   proc onDrawFrame*(surface: GL10)


# jclass android.opengl.GLSurfaceView * of View:
#   proc setRenderer*(renderer: Renderer)
#   proc setEGLContextClientVersion*(version: jint)
#   proc setRenderMode*(mode: jint)


jclass android.app.Activity * of ContextWrapper:
  proc runOnUiThread*(r: Runnable)
  proc getIntent*(): Intent
  proc getApplication*(): Application
  proc getWindowManager*(): WindowManager
  proc onCreate*(savedInstanceState: Bundle)
  # proc setContentView*(view: View)


jclass android.util.Log * of JVMObject:
  proc println*(priority: jint, tag: string, msg: string): jint {.static.}


jclassDef java.lang.CharSequence * of JVMObject
converter toCharSequence*(s: string): CharSequence = cast[CharSequence](s.toJVMObject)


jclass android.app.Dialog * of Object:
  proc setTitle*(title: string)

jclass android.app.AlertDialog * of Dialog:
  proc setTitle*(title: string)

jclass android.app.AlertDialog$Builder * of Object:
  proc new(context: Context)
  proc setTitle*(title: CharSequence): Builder
  proc setMessage*(message: CharSequence): Builder
  proc show*(): AlertDialog


proc logE*(message: varargs[string, `$`]) =
  discard Log.println(6, "Siwin", message.join())

proc alert*(context: Context, message: varargs[string, `$`]) =
  let dialog = Builder.new(context)
  discard dialog.setTitle("Siwin alert")
  discard dialog.setMessage(message.join())
  discard dialog.show()


when isMainModule:
  # import opengl

  type
    # SiwinRenderer* = ref object of Renderer

    SiwinActivity = ref object of Activity
      # view: GLSurfaceView
      # renderer: SiwinRenderer

  # jexport SiwinRenderer extends Renderer:
  #   proc onDrawFrame(surface: GL10) =
  #     GLES20.glClearColor(0.4, 1, 1, 1)
  #     GLES20.glClear(GL_COLOR_BUFFER_BIT.int32)
    
  #   proc onSurfaceCreated(surface: GL10, config: EGLConfig) =
  #     ##
    
  #   proc onSurfaceChanged(surface: GL10, width: jint, height: jint) =
  #     ##

  # initJNI()
  # initJNIThread()
  # discard Log.println(6, "SiwinActivity", "got it!")

  proc JNI_OnLoad*(vm: JavaVMPtr; reserved: pointer): jint {.cdecl, exportc, dynlib.} =
    initJNI(vm)
    # initJNIThread()

    proc NimMain {.importc.}
    NimMain()
    
    return JNI_VERSION_1_6


  jexport SiwinActivity extends Activity:
    proc new* =
      super()

    
    staticSection """System.loadLibrary("siwintest");"""


    proc onCreate(b: Bundle) =
      this.super.onCreate(b)

      this.alert "Hello from Nim!"

      # this.view = GLSurfaceView.new
      # this.view.setRenderMode(0)  # RENDERMODE_WHEN_DIRTY
      # this.renderer = SiwinRenderer.new
      # this.view.setRenderer(this.renderer)
      # this.setContentView(this.view)


  when defined(jnimGenDex):
    const siwin_generateDex_out {.strdefine.} = "build/siwin_gen_dex.nim"
    jnimDexWrite(siwin_generateDex_out)
