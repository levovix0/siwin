import std/[importutils]
import pkg/[vmath]
import ./[winapi]
import ../any/[window {.all.}, windowUtils]


privateAccess SiwinGlobalsObj


# todo: multiscreen support
proc winapi_screenCount*(globals: SiwinGlobals): int = 1
proc winapi_defaultScreen*(globals: SiwinGlobals): Screen = 0.Screen
proc winapi_screenSize*(globals: SiwinGlobals, n: Screen): IVec2 =
  ivec2(GetSystemMetrics(SmCxScreen), GetSystemMetrics(SmCyScreen))
  
proc winapiSiwinGlobalsVtable: SiwinGlobalsVtable =
  makeSiwinGlobalsVtable(winapi)

proc newWinapiSiwinGlobals*(): SiwinGlobals =
  result = create(SiwinGlobalsObj)
  result.vtable = winapiSiwinGlobalsVtable()

