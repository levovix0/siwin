--path:"../src"

--nimcache:".nimcache/"
--define:useMalloc

when defined(macosx):
  --passc:"-Wno-incompatible-function-pointer-types"
