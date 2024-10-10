import pkg/[jnim]
import pkg/jnim/java/[lang, util]

export lang, util


jclassDef java.lang.CharSequence * of JVMObject


jclass java.io.File * of JVMObject:
  proc getAbsolutePath*: string


jclass java.lang.Thread * of JVMObject:
  proc run*()
  proc start*()


converter toCharSequence*(s: string): CharSequence = cast[CharSequence](s.toJVMObject)


proc JNI_OnLoad(vm: JavaVMPtr; reserved: pointer): jint {.cdecl, exportc, dynlib.} =
  initJNI(vm)
  # initJNIThread()
  
  return JNI_VERSION_1_6
