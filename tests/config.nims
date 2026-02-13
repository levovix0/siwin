switch("path", "$projectDir/../src")
--define:siwin_use_pure_enums

when defined(macosx):
  switch("passC", "-Wno-incompatible-function-pointer-types")
  switch("passC", "-Wno-error=incompatible-function-pointer-types")
