import siwin/[siwindefs, window, windowOpengl, windowVulkan, clipboards, offscreen, colorutils, platforms]
export window, windowOpengl, windowVulkan, clipboards, offscreen, colorutils, platforms


when siwin_build_lib:
  # needed to not conflict with the NimMain of dynlib user
  {.emit: "#define NimMain siwin_main".}

