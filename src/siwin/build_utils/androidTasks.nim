# file is meant to be included in .nimble or in config.nims
# see https://github.com/levovix0/siwin/issues/19 for more details
# import siwin/build_utils/android.nim before including this file



proc buildBasiaIfNeeded* =
  if not dirExists "build/basia":
    withDir "build":
      exec "git clone https://github.com/akavel/basia"
      withDir "basia":
        exec "go build"

proc downloadAndroidNdkIfNeeded* =
  if not dirExists "build/android-ndk-r25c":
    withDir "build":
      exec "wget https://dl.google.com/android/repository/android-ndk-r25c-linux.zip"
      exec "unzip android-ndk-r25c-linux.zip"
      rmFile "android-ndk-r25c-linux.zip"



task installAndroidDeps, "install android dependencies":
  exec "nimble install https://github.com/levovix0/dali"
  exec "nimble install https://github.com/levovix0/marco@0.1.2"
  downloadAndroidNdkIfNeeded()
  # note: requires androids sdk also!
  buildBasiaIfNeeded()


proc buildAndroid*() =
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
  packApk("siwintest.apk", "apk/", "../basia/basia")
  

  # sign apk
  withDir "build/android":
    signApk("siwintest.apk")


task testAndroid, "test android":
  buildAndroid()
  try: exec "adb uninstall com.levovix.siwintest"
  except: discard
  exec "adb install -r build/android/siwintest.apk"
