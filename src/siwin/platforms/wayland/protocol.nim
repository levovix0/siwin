import macros, os
import libwayland

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



proc bindTyped*(this: Wl_registry; name: uint32, t: type, version: uint32): t =
  ## Binds a new, client-created object to the server using the
  ## specified name as the identifier.
  ## 
  ## typed version
  construct(wl_proxy_marshal_flags(this.proxy.raw, 0, t.iface, version, 0, name, t.iface[].name, version, nil), t, t.dispatch, t.Callbacks)
