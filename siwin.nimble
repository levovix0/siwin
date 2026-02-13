version       = "0.9.3"
author        = "levovix0"
description   = "Simple Window Maker"
license       = "MIT"
srcDir        = "src"

requires "nim >= 2.0"
requires "chroma >= 0.2.6"
requires "vmath >= 1.1.4"

# note: require platform dependencies only if it is the platform on which userprogrammer works.
#       ask a userprogrammer to install specific platform dependencies if cross compiling.
when defined(linux):
  requires "x11 >= 1.1"

when defined(windows):
  requires "winim >= 3.6"

when defined(android):
  requires "jnim >= 0.5.2"
  requires "https://github.com/yglukhov/android"

when defined(macosx):
  requires "darwin >= 0.2.1"


const dynlibName =
  when defined(windows): "siwin.dll"
  elif defined(macosx): "siwin.dynlib"
  else: "libsiwin.so"

const staticlibName =
  when defined(windows): "siwin.lib"
  else: "libsiwin.a"



task buildDynlib, "build siwin as a dynamic library":
  when not defined(windows):
    exec "nim c --experimental:vtables -d:siwin_build_lib:on --app:lib -o:bindings/" & dynlibName & " src/siwin.nim"
  
  else:
    exec "nim c --passl:-static --experimental:vtables -d:siwin_build_lib:on --app:lib -o:bindings/" & dynlibName & " src/siwin.nim"


task buildStaticlib, "build siwin as a dynamic library":
  exec "nim c --noMain --experimental:vtables -d:siwin_build_lib:on --app:staticlib -o:bindings/" & staticlibName & " src/siwin.nim"


task testBindings, "build and run tests/et_bindings with static and dynamic siwin":
  exec "gcc tests/et_bindings.c bindings/" & dynlibName & " -o tests/et_bindings"
  
  when not defined(windows):
    exec "gcc tests/et_bindings.c bindings/" & staticlibName & " -DSIWIN_STATIC -o tests/et_bindings_static"
  
  when not defined(windows):
    exec "./tests/et_bindings_static"
    exec "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD ./tests/et_bindings"
  
  else:
    cpFile "bindings/siwin.dll", "tests/siwin.dll"
    exec "./tests/et_bindings.exe"


task testUseLib, "build and run tests/t_opengl using dynamic linking to siwin":
  const dynlibName =
    when defined(windows): "siwin.dll"
    elif defined(macosx): "siwin.dynlib"
    else: "libsiwin.so"

  
  exec "nim c --experimental:vtables -d:siwin_use_lib:on --passl:bindings/" & dynlibName & " -r tests/t_opengl.nim"



import strformat, os

proc createZigccIfNeeded =
  let code = "import std/[os, osproc]; quit startProcess(\"/usr/bin/zig\", args = @[\"cc\"] & commandLineParams(), options = {poParentStreams}).waitForExit"
  if not fileExists("build/zigcc.nim"):
    writeFile "build/zigcc.nim", code
  if not fileExists("build/zigcc"):
    exec "nim c build/zigcc.nim"

proc buildBasiaIfNeeded =
  if not dirExists "build/basia":
    withDir "build":
      exec "git clone https://github.com/akavel/basia"
      withDir "basia":
        exec "go build"

proc downloadAndroidNdkIfNeeded() =
  if not dirExists "build/android-ndk-r25c":
    withDir "build":
      exec "wget https://dl.google.com/android/repository/android-ndk-r25c-linux.zip"
      exec "unzip android-ndk-r25c-linux.zip"
      rmFile "android-ndk-r25c-linux.zip"

task installTestDeps, "install test dependencies":
  exec "nimble install opengl"
  exec "nimble install nimgl"
  exec "nimble install pixie"
  #createZigccIfNeeded()

task installAndroidDeps, "install android dependencies":
  exec "nimble install https://github.com/levovix0/dali"
  exec "nimble install https://github.com/levovix0/marco@0.1.2"
  downloadAndroidNdkIfNeeded()
  # note: requires androids sdk also!
  buildBasiaIfNeeded()


const testTargets = ["t_opengl_es", "t_opengl", "t_swrendering", "t_multiwindow", "t_vulkan", "t_offscreen"]

proc runTests(args: string) =
  withDir "tests":
    for target in testTargets:
      try:    exec "nim c " & args & " --hints:off -r " & target
      except: discard


task test, "test":
  runTests ""

task testRefc, "test with --mm:refc":
  runTests "--mm:refc"

task testWindows, "test windows version with wine on linux":
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc"

task testRefcWindows, "test windows version with wine on linux with --mm:refc":
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc --mm:refc"


task testMacos, "test macos":
  createZigccIfNeeded()
  let pwd = getCurrentDir()
  let target = "x86_64-macos-none"
  withDir "tests":
    for file in testTargets:
      try:
        exec &"nim c --os:macosx --cc:clang --clang.exe:{pwd}/build/zigcc --clang.linkerexe:{pwd}/build/zigcc --passc:--target={target} --passl:--target={target} --hints:off -o:{file}-macos {file}"
        exec &"echo ./{file}-macos | darling shell"
      except: discard


proc buildAndroid() =
  let pwd = getCurrentDir()
  mkdir "build/android"
  mkdir "build/android/apk"

  var androidSdk = getEnv("ANDROID_SDK_ROOT")
  if androidSdk == "":
    androidSdk = getHomeDir() / "Android/Sdk"

  let packageName = "com.levovix.siwintest"
  let compiler32 = &"--arm.android.clang.path:{pwd}/build/android-ndk-r25c/toolchains/llvm/prebuilt/linux-x86_64/bin/ --arm.android.clang.exe:armv7a-linux-androideabi24-clang --arm.android.clang.linkerexe:armv7a-linux-androideabi24-clang"
  let compiler64 = &"--arm64.android.clang.path:{pwd}/build/android-ndk-r25c/toolchains/llvm/prebuilt/linux-x86_64/bin/ --arm64.android.clang.exe:aarch64-linux-android24-clang --arm64.android.clang.linkerexe:aarch64-linux-android24-clang"


  # compile manifest
  writeFile "build/android/AndroidManifest.xml", &"""
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
  package="{packageName}"
  android:versionCode="1" android:versionName="1.0"
>
  <uses-feature android:glEsVersion="0x00020000" android:required="true" />
  <uses-sdk android:minSdkVersion="1" android:targetSdkVersion="30" />
  <application android:label="Siwin test">
    <activity android:name="Jnim$SiwinActivity">
      <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
      </intent-filter>
    </activity>
  </application>
</manifest>"""
  
  # https://github.com/akavel/marco
  exec "marco -i=build/android/AndroidManifest.xml -o=build/android/apk/AndroidManifest.xml"
  # cpFile "build/android/AndroidManifest.xml", "build/android/apk/AndroidManifest.xml"


  # build so
  # exec &"nim c --noMain --app:lib --os:android --cpu=arm --threads:on --tlsEmulation:off -d:noSignalHandler {compiler32} -d:JnimPackageName={packageName} -d:jnimGenDex -d:siwin_generateDex_out=build/android/siwin_gen_dex.nim -o:build/android/apk/lib/armeabi-v7a/libsiwintest.so src/siwin/platforms/android/window.nim"
  # exec &"nim c --noMain --app:lib --os:android --cpu=arm64 --threads:on --tlsEmulation:off -d:noSignalHandler {compiler64} -d:JnimPackageName={packageName} -d:jnimGenDex -d:siwin_generateDex_out=build/android/siwin_gen_dex.nim -o:build/android/apk/lib/arm64-v8a/libsiwintest.so src/siwin/platforms/android/window.nim"
  exec &"nim c --noMain --app:lib --os:android --cpu=arm --threads:on --tlsEmulation:off -d:noSignalHandler {compiler32} -d:JnimPackageName={packageName} -o:build/android/apk/lib/armeabi-v7a/libsiwintest.so tests/et_android.nim"
  exec &"nim c --noMain --app:lib --os:android --cpu=arm64 --threads:on --tlsEmulation:off -d:noSignalHandler {compiler64} -d:JnimPackageName={packageName} -o:build/android/apk/lib/arm64-v8a/libsiwintest.so tests/et_android.nim"


  # compile java
  mkdir "build/android/java"
  mvFile "Jnim.java", "build/android/java/Jnim.java"
  
  withDir "build/android/java":
    exec &"javac --release 8 -cp \".:{androidSdk}/platforms/android-33/android.jar\" ../java/Jnim.java"
    exec "d8 *.class"

  cpFile "build/android/java/classes.dex", "build/android/apk/classes.dex"


  # compile java using https://github.com/akavel/dali, the alternative way
  # withDir "build/android":
  #   writeFile("siwin_gen_dex.nim", readFile("siwin_gen_dex.nim").replace("@@[", "@["))  #? idk wtf
  #   exec "nim c -r siwin_gen_dex.nim apk/classes.dex libsiwintest.so"


  # pack apk and (incorrectly) sign it
  writeFile "build/android/cert.x509.pem", """
-----BEGIN CERTIFICATE-----
MIGgMIGVAgEBMAMGAQEwCTEHMAUGAQETADAaFwsxNzEwMTAyMjUwWhcLMTcxMDEw
MjI1MFowCTEHMAUGAQETADBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABLAoWrpy
dzdU6PN096BcSaDRFuC+/8MjLhgeFUiogqlrZFocHudWRHJALK08ge+x0n3nwCVB
wJ4Ybfhm0sf9nowwAwYBAQMBAA==
-----END CERTIFICATE-----"""
  writeFile "build/android/key.pk8", "\048\065\002\001\000\048\019\006\007\042\134\072\206\061\002\001\006\008\042\134\072\206\061\003\001\007\004\039\048\037\002\001\001\004\032\175\054\219\048\021\044\088\163\189\252\173\147\060\181\180\015\079\156\008\002\164\135\157\116\026\081\082\187\046\240\155\207"
  withDir "build/android":
    exec "../basia/basia -i=apk/ -c=cert.x509.pem -k=key.pk8 -o=siwintest.apk"
  

  # sign apk
  withDir "build/android":
    if not fileExists("my.keystore"):
      exec "keytool -genkey -v -keystore my.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias app"
    # apksigner from android-sdk-build-tools (AUR)
    exec "apksigner sign --ks my.keystore --ks-key-alias app siwintest.apk"


task testAndroid, "test android":
  buildAndroid()
  try: exec "adb uninstall com.levovix.siwintest"
  except: discard
  exec "adb install -r build/android/siwintest.apk"


task testAll, "run all tests":
  runTests ""
  runTests "--mm:refc"
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc"
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc --mm:refc"


task testIc, "test incremental compilation":
  exec "nim c -r --mm:refc --incremental:on tests/et_ic.nim"
