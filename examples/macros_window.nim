import siwim

run newWindow(title = "macros window"):
  esc.keyup:
    close window

  render:
    clear 0x202020
    rectangle (100, 50), (300, 200), 0x40FF40
