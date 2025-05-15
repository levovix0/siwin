import std/[macros]

const siwin_use_pure_enums* {.booldefine.} = off

const siwin_dynlib_name* =
  when defined(windows): "siwin.dll"
  elif defined(maxosx): "libsiwin.dylib"
  else: "libsiwin.so"


const siwin_build_lib* {.booldefine.} = off
const siwin_use_lib* {.booldefine.} = off


macro siwin_destructor*(body) =
  result = body

  when compileOption("mm", "refc"):
    # refc requires destructor to be `=destroy`(v: var object)
    result.params[1][1] = nnkVarTy.newTree(result.params[1][1])
  
  else:
    discard


macro siwin_loadDynlibIfExists*(handle, body) =
  result = newStmtList()

  for body in body:
    var pragma =
      if body.pragma.kind == nnkEmpty: nnkPragma.newTree()
      else: body.pragma
    
    pragma.add(ident("cdecl"))

    result.add(
      nnkVarSection.newTree(
        nnkIdentDefs.newTree(
          body[0],
          nnkProcTy.newTree(
            body.params,
            pragma,
          ),
          newEmptyNode()
        )
      ),
      nnkIfStmt.newTree(
        nnkElifBranch.newTree(
          nnkInfix.newTree(
            ident("!="),
            handle,
            newNilLit()
          ),
          nnkStmtList.newTree(
            nnkAsgn.newTree(
              body.name,
              nnkCast.newTree(
                nnkProcTy.newTree(
                  body.params,
                  pragma,
                ),
                nnkCall.newTree(
                  ident("symAddr"),
                  handle,
                  newLit($body.name)
                )
              )
            )
          )
        )
      )
    )
