import platforms
import platforms/any/window
when defined(linux):
  import platforms/x11/offscreen
elif defined(windows):
  import platforms/winapi/offscreen

proc newOpenglContext*(
  preferedPlatform: Platform =
    when defined(windows): Platform.winapi
    else: Platform.x11
): Window =
  when defined(linux):
    newOpenglContextX11()
  elif defined(windows):
    newOpenglContextWinapi()
