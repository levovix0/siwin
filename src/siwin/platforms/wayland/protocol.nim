import macros, os

macro importProtocolAndGenerateItIfNeededImpl(instantiationFilename: static string) =
  if fileExists(instantiationFilename.splitPath.head / "protocol_generated.nim") and not defined(siwin_generate_wayland_protocol):
    result = nnkStmtList.newTree(
      nnkImportStmt.newTree(ident "protocol_generated"),
      nnkExportStmt.newTree(ident "protocol_generated"),
    )
  else:
    result = nnkStmtList.newTree(
      nnkImportStmt.newTree(ident "protocol_gen"),
      nnkImportStmt.newTree(ident "protocol_generated"),
      nnkExportStmt.newTree(ident "protocol_generated"),
    )

template importProtocolAndGenerateItIfNeeded*() =
  importProtocolAndGenerateItIfNeededImpl(instantiationInfo(fullPaths=true).filename)

importProtocolAndGenerateItIfNeeded()
