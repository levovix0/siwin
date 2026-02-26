import std/os
import std/strformat


when not defined(nimscript):
  proc exec(cmd: string) =
    if (let code = execShellCmd(cmd); code != 0):
      raise OSError.newException("process '" & cmd & "' failed with code " & $code)


proc signApk*(apkname: string) =
  ## correctly sign apk
  
  if not fileExists("my.keystore"):
    exec "keytool -genkey -v -keystore my.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias app"
  # apksigner from android-sdk-build-tools (AUR)
  exec &"apksigner sign --ks my.keystore --ks-key-alias app {apkname}"


proc packApk*(apkname: string, apkroot: string, basiaExe: string, temporaryDir: string = apkroot.parentDir) =
  ## pack apk and (incorrectly) sign it
  
  let certPath = temporaryDir/"cert.x509.pem"
  let keyPath = temporaryDir/"key.pk8"
  writeFile certPath, """
-----BEGIN CERTIFICATE-----
MIGgMIGVAgEBMAMGAQEwCTEHMAUGAQETADAaFwsxNzEwMTAyMjUwWhcLMTcxMDEw
MjI1MFowCTEHMAUGAQETADBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABLAoWrpy
dzdU6PN096BcSaDRFuC+/8MjLhgeFUiogqlrZFocHudWRHJALK08ge+x0n3nwCVB
wJ4Ybfhm0sf9nowwAwYBAQMBAA==
-----END CERTIFICATE-----"""
  writeFile keyPath, "\48\65\2\1\0\48\19\6\7\42\134\72\206\61\2\1\6\8\42\134\72\206\61\3\1\7\4\39\48\37\2\1\1\4\32\175\54\219\48\21\44\88\163\189\252\173\147\60\181\180\15\79\156\8\2\164\135\157\116\26\81\82\187\46\240\155\207"
  exec &"{quoteShell(basiaExe)} -i={quoteShell(apkroot)} -c={quoteShell(certPath)} -k={quoteShell(keyPath)} -o={quoteShell(apkname)}"

