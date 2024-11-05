import platforms
import platforms/any/window

when defined(nimcheck) or defined(nimsuggest):
  discard
elif defined(android):
  import platforms/android/window
elif defined(linux):
  import platforms/x11/offscreen
elif defined(windows):
  import platforms/winapi/offscreen

proc newOpenglContext*(
  preferedPlatform: Platform =
    when defined(windows): Platform.winapi
    else: Platform.x11
): Window =
  when defined(nimcheck) or defined(nimsuggest):
    discard
  elif defined(android):
    newOpenglWindowAndroid()
  elif defined(linux):
    newOpenglContextX11()
  elif defined(windows):
    newOpenglContextWinapi()
