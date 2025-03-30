import platforms/any/window

when defined(android):
  import platforms/android/window
elif defined(linux):
  import platforms/x11/[offscreen, siwinGlobals]
elif defined(windows):
  import platforms/winapi/offscreen

proc newOpenglContext*(
  globals: SiwinGlobals
): Window =
  when defined(android):
    newOpenglWindowAndroid()
  elif defined(linux):
    if globals of SiwinGlobalsX11:
      globals.SiwinGlobalsX11.newOpenglContextX11()
    # elif globals of SiwinGlobalsWayland:
    #   newOpenglContextWayland()
    else:
      raise ValueError.newException("Unsupported platform")

  elif defined(windows):
    newOpenglContextWinapi()
