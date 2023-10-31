{.used.}
import os, macros, xmltree, xmlparser, unicode

macro generateProtocolWrapperFromXmlStringImpl(outNimFile: static[string], instantiatedFrom: static[string]) =
  ## transforms every
  ## .. code-block:: xml
  ##   <interface name="t" version="1">
  ##     <request name="f">
  ##       <arg name="a" type="int"/>
  ##       <arg name="result" type="new_id" interface="r"/>
  ##     </request>
  ##   
  ##     <event name="e">
  ##       <arg name="a" type="uint" enum="e"/>
  ##     </event>
  ##   
  ##     <enum name="e">
  ##       <entry name="ea" value="3"/>
  ##       <entry name="eb" value="1"/>
  ##       <entry name="ec" value="2"/>
  ##     </enum>
  ##   </interface>
  ##
  ## to (roughly)
  ## .. code-block:: nim
  ##   # type section
  ##   type
  ##     T* = object
  ##       proxy*: WlProxy
  ##     `T/Callbacks`* = object
  ##       destroy: proc(cb: pointer) {.cdecl, raises: [].}
  ##       e*: proc(a: E)
  ##     E* = enum
  ##       eb = 1
  ##       ec = 2
  ##       ea = 3
  ##   
  ##   # interface decl section
  ##   proc ifaceName*(t: type T): string = "wl_t"
  ##   var `T/iface`: WlInterface
  ##   proc iface*(t: type T): ptr WlInterface = `T/iface`.addr
  ## 
  ##   # interface body section
  ##   `T/iface` = newWlInterface(
  ##     "T", 1,
  ##     [
  ##       newWlMessage("f", "1in", [nil, R.iface]),
  ##     ],
  ##     [
  ##       newWlMessage("e", "1i", [nil]),
  ##     ]
  ##   )
  ## 
  ##   # dispatcher section
  ##   proc `T/dispatch`(userdata: pointer, target: WlProxy, opcode: uint32, msg: ptr WlMessage, args: pointer) {.cdecl.} =
  ##     let callbacks = cast[`T/Callbacks`](target.userdata)
  ##     case opcode
  ##     of 1:
  ##       let (a) = cast[ptr (int32)](args)[]
  ##       callbacks.e(a)
  ##     else: discard
  ## 
  ##   # wrapper functions section
  ##   proc f*(this: T; a: int32): R =
  ##     let args = (a,)
  ##     let r = marshalUntyped(this.proxy, 0, T.iface, 1, 0, args.addr)
  ##     result = r[0].construct(R, `R/dispatch`, `R/Callbacks`)
  ##
  ##   template onE*(x: T; body) =
  ##     cast[`T/Callbacks`](x.userdata).e = proc(a {.inject.}: int) =
  ##       body

  let res = newStmtList()
  let
    typesection = nnkTypeSection.newTree()

  res.add newCommentStmtNode("note: this file is generated in protocol_gen.nim\ndo not edit it mannualy!\npass -d:siwin_generate_wayland_protocol to regenerate it")
  res.add nnkImportStmt.newTree(ident "libwayland")

  proc parse(xmlstring: string) =
    let xml = xmlstring.parseXml({})
    for iface in xml:
      if iface.kind != xnElement: continue
      if iface.tag != "interface": continue

      let typename = ident iface.attr("name").capitalize
      let typenameCallbacks = nnkAccQuoted.newTree(
        typename,
        ident"/",
        ident"Callbacks"
      )

      if typename.strVal != "Wl_display":
        typesection.add nnkTypeDef.newTree(
          nnkPostfix.newTree(
            ident"*",
            typename,
          ),
          newEmptyNode(),
          nnkObjectTy.newTree(
            newEmptyNode(),
            newEmptyNode(),
            nnkRecList.newTree(
              nnkIdentDefs.newTree(
                nnkPostfix.newTree(
                  ident"*",
                  ident"proxy",
                ),
                ident"Wl_proxy",
                newEmptyNode(),
              ),
            ),
          ),
        )
        typesection.add nnkTypeDef.newTree(
          nnkPostfix.newTree(
            ident"*",
            typenameCallbacks
          ),
          newEmptyNode(),
          nnkObjectTy.newTree(
            newEmptyNode(),
            newEmptyNode(),
            nnkRecList.newTree(
              nnkIdentDefs.newTree(
                newIdentNode("destroy"),
                nnkProcTy.newTree(
                  nnkFormalParams.newTree(
                    newEmptyNode(),
                    nnkIdentDefs.newTree(
                      newIdentNode("cb"),
                      newIdentNode("pointer"),
                      newEmptyNode()
                    )
                  ),
                  nnkPragma.newTree(
                    newIdentNode("cdecl"),
                    nnkExprColonExpr.newTree(
                      newIdentNode("raises"),
                      nnkBracket.newTree()
                    )
                  )
                ),
                newEmptyNode()
              )
            )
          )
        )
      
      for request in iface:
        if request.kind != xnElement: continue
        if request.tag != "request": continue
      
      for event in iface:
        if event.kind != xnElement: continue
        if event.tag != "event": continue
  
  for (kind, path) in walkDir(instantiatedFrom.splitPath.head / "protocols"):
    parse staticRead path

  res.add [typesection]

  writeFile(instantiatedFrom.splitPath.head / outNimFile, res.repr)

template generateProtocolWrapperFromXmlString*(outNimFile: static[string]) =
  generateProtocolWrapperFromXmlStringImpl(outNimFile, instantiationInfo(fullPaths=true).filename)

generateProtocolWrapperFromXmlString "protocol_generated.nim"
