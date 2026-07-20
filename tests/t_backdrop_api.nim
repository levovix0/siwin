import std/assertions

import vmath
import siwin

block blur_config:
  let config = initWindowBackdrop()
  doAssert config.kind == wbkBlur
  doAssert config.regions.len == 0

block blur_regions:
  let
    regions = [WindowVisualRegion(pos: ivec2(4, 8), size: ivec2(20, 30))]
    config = initWindowBackdrop(regions)
  doAssert config.kind == wbkBlur
  doAssert config.regions == @regions

block material_config:
  let config = initWindowBackdrop(wbmSidebar)
  doAssert config.kind == wbkMaterial
  doAssert config.material == wbmSidebar

block unsupported_base_window:
  var window: Window
  new window
  doAssert not window.trySetBackdrop(initWindowBackdrop())
  doAssertRaises WindowVisualEffectError:
    window.setBackdrop(initWindowBackdrop())

block clearing_base_window:
  var window: Window
  new window
  window.clearBackdrop()
  doAssert window.backdrop.kind == wbkNone

when defined(macosx):
  block cocoa_requires_transparency:
    let window = newSoftwareRenderingWindow(size = ivec2(160, 100))
    doAssert not window.trySetBackdrop(initWindowBackdrop())
    window.close()

  block cocoa_software_window:
    let window = newSoftwareRenderingWindow(
      size = ivec2(160, 100),
      transparent = true,
    )
    doAssert window.supports(wvcBackdropBlur)
    doAssert window.supports(wvcBackdropBlurRegion)
    doAssert window.supports(wvcBackdropMaterial)
    let region = WindowVisualRegion(pos: ivec2(8, 8), size: ivec2(80, 60))
    doAssert window.trySetBackdrop(initWindowBackdrop([region]))
    doAssert window.backdrop.kind == wbkBlur
    doAssert window.trySetBackdrop(initWindowBackdrop(wbmSidebar))
    doAssert window.backdrop.kind == wbkMaterial
    window.clearBackdrop()
    doAssert window.backdrop.kind == wbkNone
    window.close()
