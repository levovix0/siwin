import macros

macro importExport*(importCond: static bool, exportCond: static bool, dynlib: static string, name: static string, body) =
  if importCond and exportCond:
    error("cannot import and export at the same time", body)
  
  elif importCond:
    result = body

    if result.pragma.kind == nnkEmpty:
      result.pragma = nnkPragma.newTree()
    
    result.pragma.add nnkExprColonExpr.newTree(ident("importc"), newLit(name))
    result.pragma.add nnkExprColonExpr.newTree(ident("dynlib"), newLit(dynlib))
    result.body = newEmptyNode()

  elif exportCond:
    result = body

    if result.pragma.kind == nnkEmpty:
      result.pragma = nnkPragma.newTree()

    result.pragma.add nnkExprColonExpr.newTree(ident("exportc"), newLit(name))
    result.pragma.add ident("dynlib")

  else:
    result = body
