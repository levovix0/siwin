import std/[strutils]
import pkg/[jnim]
import ./[javalib]


# --------- primitive utils ---------

jclass android.util.Log * of JVMObject:
  proc println*(priority: jint, tag: string, msg: string): jint {.static.}


# --------- android context ---------

jclass android.util.DisplayMetrics * of JVMObject:
  proc new*
  proc density*: jfloat {.prop.}
  proc densityDpi*: jint {.prop.}
  proc heightPixels*: jint {.prop.}
  proc widthPixels*: jint {.prop.}
  proc scaledDensity*: jfloat {.prop.}
  proc xdpi*: jfloat {.prop.}
  proc ydpi*: jfloat {.prop.}

jclassDef android.content.res.AssetManager * of JVMObject

jclassDef android.content.ContentResolver * of JVMObject

jclass android.content.Context * of JVMObject:
  proc INPUT_METHOD_SERVICE*: string {.prop, `static`, final.}
  proc getSystemService*(name: string): JVMObject
  proc getAssets*: AssetManager
  proc getContentResolver*: ContentResolver
  proc getCacheDir*: javalib.File
  proc getExternalCacheDir*: javalib.File


jclass android.content.res.Resources * of JVMObject:
  proc getDisplayMetrics*(): DisplayMetrics


jclass android.content.ContextWrapper * of Context:
  proc getResources*(): Resources


jclass android.os.BaseBundle * of JVMObject:
  proc clear*()
  proc containsKey*(key: string): bool
  proc isEmpty*(): bool
  proc getString*(key: string): string
  proc putBoolean*(key: string, val: bool)
  proc putDouble*(key: string, val: jdouble)
  proc putInt*(key: string, val: jint)
  proc putLong*(key: string, val: jlong)
  proc putString*(key: string, val: string)

jclass android.os.Bundle * of BaseBundle:
  proc new*()


jclass android.net.Uri * of JVMObject:
  proc getPath*(): string
  proc getHost*(): string
  proc getScheme*(): string
  proc toString*(): string


jclass android.content.Intent * of JVMObject:
  proc getExtras*(): Bundle
  proc getData*(): Uri
  proc hasExtra*(key: string): bool
  proc getStringExtra*(key: string): string
  proc setData*(u: Uri)
  proc removeExtra*(key: string)


jclassDef android.app.Application * of Context


# --------- alert dialog for debugging ---------

jclass android.app.Dialog * of Object:
  proc setTitle*(title: string)

jclass android.app.AlertDialog * of Dialog:
  proc setTitle*(title: string)

jclass android.app.AlertDialog$Builder * of Object:
  proc new*(context: Context)
  proc setTitle*(title: CharSequence): Builder
  proc setMessage*(message: CharSequence): Builder
  proc show*(): AlertDialog


# --------- input events ---------

jclass android.view.InputEvent * of JVMObject:
  proc cancel*()
  proc getEventTime*(): jlong
  proc getEventTimeNanos*(): jlong
  proc getId*(): jint
  proc getDeviceId*(): jint
  proc getSource*(): jint
  proc setSource*(source: jint)

jclass android.view.MotionEvent * of InputEvent:
  proc getAction*(): jint
  proc getActionMasked*(): jint
  proc getActionIndex*(): jint
  proc isTouchEvent*(): bool
  proc isStylusPointer*(): bool
  proc isHoverEvent*(): bool
  proc getFlags*(): jint
  proc getX*(): jfloat
  proc getY*(): jfloat
  proc getPressure*(): jfloat
  proc getSize*(): jfloat
  proc getTouchMajor*(): jfloat
  proc getTouchMinor*(): jfloat
  proc getToolMajor*(): jfloat
  proc getToolMinor*(): jfloat
  proc getOrientation*(): jfloat
  proc getAxisValue*(axis: jint): jfloat
  proc getPointerCount*(): jint
  proc getPointerId*(pointerIndex: jint): jint
  proc getToolType*(pointerIndex: jint): jint
  proc findPointerIndex*(pointerId: jint): jint
  proc getX*(pointerIndex: jint): jfloat
  proc getY*(pointerIndex: jint): jfloat
  proc getPressure*(pointerIndex: jint): jfloat
  proc getSize*(pointerIndex: jint): jfloat
  proc getToolMajor*(pointerIndex: jint): jfloat
  proc getToolMinor*(pointerIndex: jint): jfloat
  proc getOrientation*(pointerIndex: jint): jfloat
  proc getAxisValue*(axis: jint, pointerIndex: jint): jfloat
  # proc getPointerCoords*(pointerIndex: jint, outPointerCoords: PointerCoords)
  proc getMetaState*(): jint
  proc getButtonState*(): jint
  proc getClassification*(): jint
  proc getActionButton*(): jint
  proc getRawX*(): jfloat
  proc getRawY*(): jfloat
  proc getRawX*(pointerIndex: jint): jfloat
  proc getRawY*(pointerIndex: jint): jfloat
  proc getXPrecision*(): jfloat
  proc getYPrecision*(): jfloat
  proc getXCursorPosition*(): jfloat
  proc getYCursorPosition*(): jfloat
  proc setCursorPosition*(x: jfloat, y: jfloat)
  proc getHistorySize*(): jint
  proc getHistoricalEventTime*(pos: jint): jlong
  proc getHistoricalEventTimeNanos*(pos: jint): jlong
  proc getEdgeFlags*(): jint
  proc updateCursorPosition*()
  proc toString*(): string


# --------- rendering ---------

jclass android.view.Display * of JVMObject:
  proc getMetrics*(outMetrics: DisplayMetrics)
  proc getRealMetrics*(outMetrics: DisplayMetrics)

jclass android.view.WindowManager * of JVMObject:
  proc getDefaultDisplay*: Display


jclass android.view.View * of JVMObject:
  proc getX*(): jfloat
  proc getY*(): jfloat

jclassDef android.view.SurfaceView * of View
jclassDef javax.microedition.khronos.opengles.GL10 * of JVMObject
jclassDef javax.microedition.khronos.egl.EGLConfig * of JVMObject


jclass android.opengl.GLES20 * of JVMObject:
  proc glClearColor*(r: float32, g: float32, b: float32, a: float32) {.static.}
  proc glClear*(v: int32) {.static.}


jclass android.opengl.GLSurfaceView$Renderer * of JVMObject:
  proc onSurfaceCreated*(surface: GL10, config: EGLConfig)
  proc onSurfaceChanged*(surface: GL10, width: jint, height: jint)
  proc onDrawFrame*(surface: GL10)


jclass android.opengl.GLSurfaceView * of SurfaceView:
  proc new*(context: Context)
  proc setRenderer*(renderer: Renderer)
  proc setEGLContextClientVersion*(version: jint)
  proc setRenderMode*(mode: jint)
  proc requestRender*()
  proc onTouchEvent*(event: MotionEvent): jboolean


# --------- activity ---------

jclass android.app.Activity * of ContextWrapper:
  proc runOnUiThread*(r: Runnable)
  proc getIntent*(): Intent
  proc getApplication*(): Application
  proc getWindowManager*(): WindowManager
  proc onCreate*(savedInstanceState: Bundle)
  proc setTitle*(title: CharSequence)
  proc setContentView*(view: View)


# --------- util wrappers ---------

proc logE*(message: varargs[string, `$`]) =
  discard Log.println(6, "Siwin", message.join())

proc alert*(context: Context, message: varargs[string, `$`], title = "Siwin alert") =
  let dialog = Builder.new(context)
  discard dialog.setTitle(title)
  discard dialog.setMessage(message.join())
  discard dialog.show()
