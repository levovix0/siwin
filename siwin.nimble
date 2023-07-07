version       = "0.8"
author        = "levovix0"
description   = "Simple Window Maker"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.6.10"
requires "chroma >= 0.2.6"
requires "vmath >= 1.1.4"

# note: nimble does not support "features", so just require all dependencies without any conditioning
requires "x11 >= 1.1"
requires "winim >= 3.6"
requires "jnim >= 0.5.2"


import strformat

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
  createZigccIfNeeded()

task installAndroidDeps, "install android dependencies":
  exec "nimble install dali"
  exec "nimble install https://github.com/akavel/marco"
  downloadAndroidNdkIfNeeded()
  buildBasiaIfNeeded()


const testTargets = ["t_offscreen", "tests", "t_vulkan"]

proc runTests(args: string) =
  withDir "tests":
    for target in testTargets:
      try:    exec "nim c " & args & " --hints:off -r " & target
      except: discard


task test, "test":
  runTests ""

task testOrc, "test with --mm:orc":
  runTests "--mm:orc"

task testWindows, "test windows version with wine on linux":
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc"

task testOrcWindows, "test windows version with wine on linux with --mm:orc":
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc --mm:orc"


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


task testAndroid, "test android":
  let pwd = getCurrentDir()
  mkdir "build/android"

  # build application and generate dex generator
  exec &"nim c --app:lib --os:android --cpu=arm64 --cc:clang --clang.path:{pwd}/build/android-ndk-r25c/toolchains/llvm/prebuilt/linux-x86_64/bin/ -d:noSignalHandler --tlsEmulation:off -o:build/android/apk/lib/armeabi-v7a/libsiwintest.so -d:jnimGenDex -d:siwin_generateDex_out:build/android/siwin_gen_dex.nim -d:JnimPackageName=com.levovix.siwintest src/siwin/platforms/android/ndk.nim"

  mkdir "build/android/apk"

  # generate dex
  exec "nim c -r build/android/siwin_gen_dex.nim build/android/apk/classes.dex build/android/apk/lib/armeabi-v7a/libsiwintest.so"

  writeFile "build/android/AndroidManifest.xml", """
  <?xml version="1.0" encoding="utf-8"?>
  <manifest xmlns:android="http://schemas.android.com/apk/res/android"
      package="com.levovix.siwintest">
      <application android:label="Siwin test">
          <activity android:name="Jnim$SiwinActivity">
              <intent-filter>
                  <action android:name="android.intent.action.MAIN" />
                  <category android:name="android.intent.category.LAUNCHER" />
              </intent-filter>
          </activity>
      </application>
  </manifest>
  """
  
  # compile manifest
  exec "marco -i=build/android/AndroidManifest.xml -o=build/android/apk/AndroidManifest.xml"

  writeFile "build/android/cert.x509.pem", """
-----BEGIN CERTIFICATE-----
MIGgMIGVAgEBMAMGAQEwCTEHMAUGAQETADAaFwsxNzEwMTAyMjUwWhcLMTcxMDEw
MjI1MFowCTEHMAUGAQETADBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABLAoWrpy
dzdU6PN096BcSaDRFuC+/8MjLhgeFUiogqlrZFocHudWRHJALK08ge+x0n3nwCVB
wJ4Ybfhm0sf9nowwAwYBAQMBAA==
-----END CERTIFICATE-----"""

  writeFile "build/android/key.pk8", "\048\065\002\001\000\048\019\006\007\042\134\072\206\061\002\001\006\008\042\134\072\206\061\003\001\007\004\039\048\037\002\001\001\004\032\175\054\219\048\021\044\088\163\189\252\173\147\060\181\180\015\079\156\008\002\164\135\157\116\026\081\082\187\046\240\155\207"

  # pack apk and (incorrectly) sign it
  exec "build/basia/basia -i build/android/apk -c build/android/cert.x509.pem -k build/android/key.pk8 -o build/android/siwintest.apk"
  
  # note: key was generated as "keytool -genkey -v -keystore my.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias app"
  exec "apksigner sign --ks my.keystore --ks-key-alias app build/android/siwintest.apk"


task testAll, "run all tests":
  runTests ""
  runTests "--mm:orc"
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc"
  runTests "-d:mingw --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc --mm:orc"
