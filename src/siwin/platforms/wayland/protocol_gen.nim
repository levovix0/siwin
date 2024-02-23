{.used.}
import os, macros, xmltree, xmlparser, unicode, strutils, algorithm, sequtils

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
  ##   proc `T/dispatch`(impl: pointer, obj: pointer, opcode: uint32, msg: ptr WlMessage, args: pointer): int32 {.cdecl.} =
  ##     let callbacks = cast[`T/Callbacks`](target.userdata)
  ##     case opcode
  ##     of 1:
  ##       let (a) = cast[ptr (int32)](args)[]
  ##       callbacks.e(a)
  ##     else: discard
  ## 
  ##   # wrapper functions section (requests)
  ##   proc f*(this: T; a: int32): R =
  ##     let args = (a,)
  ##     wl_proxy_marshal_array_flags(this.proxy, 0, T.iface, 1, 0, args.addr).construct(R, `R/dispatch`, `R/Callbacks`)
  ##
  ##   # event handler templates section (events)
  ##   template onE*(x: T; body) =
  ##     cast[`T/Callbacks`](x.userdata).e = proc(a {.inject.}: int) =
  ##       body

  let res = newStmtList()
  let
    typesection = nnkTypeSection.newTree()
    ifaceDeclSection = newStmtList()
    ifaceBodySection = newStmtList()
    dispatcherSection = newStmtList()
    wrapperFunctionsSection = newStmtList()
    eventHandlerTemplatesSection = newStmtList()
    dispatchTemplatesSection = newStmtList()
    callbacksTemplatesSection = newStmtList()

  res.add newCommentStmtNode("note: this file is generated in protocol_gen.nim\ndo not edit it mannualy!\npass -d:siwin_generate_wayland_protocol to regenerate it")
  res.add nnkImportStmt.newTree(ident "libwayland")

  proc parse(xmlstring: string) =
    let xml = xmlstring.parseXml({})
    for iface in xml:
      if iface.kind != xnElement: continue
      if iface.tag != "interface": continue

      type Message = tuple[name: string, version: int, args: seq[tuple[name: string, t: string, iface: string, enm: string, nullable: bool]], isDestructor: bool, desc: string]

      proc accquote(x: string): NimNode =
        case x
        of "method", "interface", "bind": nnkAccQuoted.newTree(ident x)
        elif x[0].isDigit: nnkAccQuoted.newTree(ident x)
        else: ident x.strip(chars={'_'})
      proc unaccquote(x: NimNode): NimNode =
        if x.kind == nnkAccQuoted: x[0]
        else: x

      let ifaceName = iface.attr("name")
      let typename = ident ifaceName.capitalize
      let typenameCallbacks = nnkAccQuoted.newTree(
        typename,
        ident"/",
        ident"Callbacks"
      )

      proc toNimType(s: string, iface: string, enm: string): NimNode =
        if enm != "":
          let enm = enm.split(".")
          if enm.len > 1:
            return nnkAccQuoted.newTree(
              ident enm[0].capitalize,
              ident "/",
              ident enm[1].capitalize
            )
          else:
            return nnkAccQuoted.newTree(
              typename,
              ident "/",
              ident enm[0].capitalize
            )
        case s
        of "int": return ident"int32"
        of "uint": return ident"uint32"
        of "string": return ident"cstring"
        of "new_id":
          if iface == "": return ident"uint32"
          else: return accquote(iface.capitalize)
        of "fd": return ident"FileHandle"
        of "object":
          if iface == "": return ident"uint32"
          else: return accquote(iface.capitalize)
        of "fixed": return ident"float32"
        of "array": return ident"Wl_array"
        else: error("unexpected type: " & s)

      var description: string
      for x in iface:
        if x.kind != xnElement: continue
        if x.tag != "description": continue
        description = (if x.len > 0: x[0].text else: x.attr("summary")).unindent.unindent(padding="\t")
        stripLineEnd description

      if typename.strVal != "Wl_display":
        # proxy type
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
              (if description != "": @[newCommentStmtNode(description)] else: @[]) &
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
        
        # interface decl
        ifaceDeclSection.add nnkVarSection.newTree(
          nnkIdentDefs.newTree(
            nnkAccQuoted.newTree(
              typename,
              ident("/"),
              ident("iface")
            ),
            ident("WlInterface"),
            newEmptyNode()
          )
        )

        # interface link (from type to ptr WlInterface) proc
        ifaceDeclSection.add nnkProcDef.newTree(
          nnkPostfix.newTree(
            ident("*"),
            ident("iface")
          ),
          newEmptyNode(),
          newEmptyNode(),
          nnkFormalParams.newTree(
            nnkPtrTy.newTree(
              ident("WlInterface")
            ),
            nnkIdentDefs.newTree(
              ident("t"),
              nnkBracketExpr.newTree(
                ident("typedesc"),
                typename
              ),
              newEmptyNode()
            )
          ),
          newEmptyNode(),
          newEmptyNode(),
          nnkStmtList.newTree(
            nnkDotExpr.newTree(
              nnkAccQuoted.newTree(
                typename,
                ident("/"),
                ident("iface")
              ),
              ident("addr")
            )
          )
        )
      
      var requests: seq[Message]
      for request in iface:
        if request.kind != xnElement: continue
        if request.tag != "request": continue

        var description: string
        for x in request:
          if x.kind != xnElement: continue
          if x.tag != "description": continue
          description = (if x.len > 0: x[0].text else: x.attr("summary")).unindent.unindent(padding="\t")
          stripLineEnd description

        requests.add (
          request.attr("name"),
          (let x = request.attr("version"); if x == "": "1" else: x).parseInt,
          request.filterIt(it.kind == xnElement and it.tag == "arg").mapIt(
            (it.attr("name"), it.attr("type"), it.attr("interface"), it.attr("enum"), it.attr("allow-null") == "true")
          ),
          request.attr("type") == "destructor",
          description
        )
      
      var events: seq[Message]
      for event in iface:
        if event.kind != xnElement: continue
        if event.tag != "event": continue

        var description: string
        for x in event:
          if x.kind != xnElement: continue
          if x.tag != "description": continue
          description = (if x.len > 0: x[0].text else: x.attr("summary")).unindent.unindent(padding="\t")
          stripLineEnd description

        events.add (
          event.attr("name"),
          (let x = event.attr("version"); if x == "": "1" else: x).parseInt,
          event.filterIt(it.kind == xnElement and it.tag == "arg").mapIt(
            (it.attr("name"), it.attr("type"), it.attr("interface"), it.attr("enum"), it.attr("allow-null") == "true")
          ),
          event.attr("type") == "destructor",
          description
        )
      
      for enumt in iface:
        if enumt.kind != xnElement: continue
        if enumt.tag != "enum": continue

        var entries: seq[tuple[intVal: int, name: string]]
        for entry in enumt:
          if entry.kind != xnElement: continue
          if entry.tag != "entry": continue

          proc parseWlInt(x: string): int =
            if x.startsWith("0x"): parseHexInt(x[2..^1])
            else: parseInt(x)

          entries.add (entry.attr("value").parseWlInt, entry.attr("name"))

        sort entries

        var description: string
        for x in enumt:
          if x.kind != xnElement: continue
          if x.tag != "description": continue
          description = (if x.len > 0: x[0].text else: x.attr("summary")).unindent.unindent(padding="\t")
          stripLineEnd description

        # enum type
        typesection.add nnkTypeDef.newTree(
          nnkPragmaExpr.newTree(
            nnkPostfix.newTree(
              ident"*",
              nnkAccQuoted.newTree(
                typename,
                ident"/",
                ident enumt.attr("name").capitalize
              )
            ),
            nnkPragma.newTree(
              nnkExprColonExpr.newTree(
                ident "size",
                newLit 4
              )
            )
          ),
          newEmptyNode(),
          nnkEnumTy.newTree(
            (if description != "": @[newCommentStmtNode(description)] else: @[]) &
            newEmptyNode() & entries.mapit(
              nnkEnumFieldDef.newTree(
                it.name.accquote,
                newLit(it.intVal)
              )
            )
          )
        )

      if typename.strVal != "Wl_display":
        # callbacks type
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
                ident("destroy"),
                nnkProcTy.newTree(
                  nnkFormalParams.newTree(
                    newEmptyNode(),
                    nnkIdentDefs.newTree(
                      ident("cb"),
                      ident("pointer"),
                      newEmptyNode()
                    )
                  ),
                  nnkPragma.newTree(
                    ident("cdecl"),
                    nnkExprColonExpr.newTree(
                      ident("raises"),
                      nnkBracket.newTree()
                    )
                  )
                ),
                newEmptyNode()
              ) & events.mapit(
                nnkIdentDefs.newTree(
                  nnkPostfix.newTree(
                    ident"*",
                    accquote(it.name)
                  ),
                  nnkProcTy.newTree(
                    nnkFormalParams.newTree(
                      newEmptyNode() & it.args.mapit(
                        nnkIdentDefs.newTree(
                          accquote(it.name),
                          toNimType(it.t, it.iface, it.enm),
                          newEmptyNode()
                        )
                      )
                    ),
                    newEmptyNode()
                  ),
                  newEmptyNode()
                )
              )
            )
          )
        )

        proc messageToWlMessage(x: Message): NimNode =
          var shortSignature = $x.version
          for (_, t, _, _, nullable) in x.args:
            if nullable: shortSignature.add "?"
            shortSignature.add case t
            of "int": "i"
            of "uint": "u"
            of "fixed": "f"
            of "string": "s"
            of "object": "o"
            of "new_id": "n"
            of "array": "a"
            of "fd": "h"
            else:
              error("unexpected type: " & t)
              ""
          
          if x.name == "bind" and ifaceName == "wl_registry":
            # in wayland protocol it's declared as taking 2 args, BUT in actual code... it takes 4.
            # idk why, but while it works like so...
            shortSignature = "1usun"
          
          var types = nnkBracket.newTree()
          for (_, _, iface, _, _) in x.args:
            if iface == "":
              types.add nnkCommand.newTree(
                nnkPar.newTree(
                  nnkPtrTy.newTree(
                    ident("WlInterface")
                  )
                ),
                newNilLit()
              )
            else:
              types.add nnkCall.newTree(
                ident("iface"),
                ident(iface.capitalize)
              )

          nnkCall.newTree(
            ident("newWlMessage"),
            newLit(ifaceName & "." & x.name),
            newLit(shortSignature),
            types
          )

        # interface body
        ifaceBodySection.add nnkAsgn.newTree(
          nnkAccQuoted.newTree(
            typename,
            ident("/"),
            ident("iface")
          ),
          nnkCall.newTree(
            ident("newWlInterface"),
            newLit ifaceName,
            newLit(iface.attr("version").parseInt),
            nnkBracket.newTree(
              requests.map(messageToWlMessage)
            ),
            nnkBracket.newTree(
              events.map(messageToWlMessage)
            )
          )
        )

        proc makeDispatchOpcode(opcode: int, msg: Message): NimNode =
          nnkOfBranch.newTree(
            newLit(opcode),
            nnkStmtList.newTree(
              (if msg.args.len != 0: @[nnkLetSection.newTree(
                nnkIdentDefs.newTree(
                  ident("args"),
                  newEmptyNode(),
                  nnkCast.newTree(
                    nnkPtrTy.newTree(
                      nnkTupleConstr.newTree(
                        msg.args.mapit(it.t.toNimType(it.iface, it.enm))
                      )
                    ),
                    ident("args")
                  )
                )
              )]
              else: @[]
              ) &
              nnkIfStmt.newTree(
                nnkElifBranch.newTree(
                  nnkInfix.newTree(
                    ident("!="),
                    nnkDotExpr.newTree(
                      ident("callbacks"),
                      accquote msg.name
                    ),
                    newNilLit()
                  ),
                  nnkStmtList.newTree(
                    nnkCall.newTree(
                      nnkDotExpr.newTree(
                        ident("callbacks"),
                        accquote msg.name
                      ) &
                      (0..msg.args.high).mapit(
                        nnkBracketExpr.newTree(
                          nnkBracketExpr.newTree(
                            ident("args"),
                          ),
                          newLit(it)
                        )
                      )
                    )
                  )
                )
              )
            )
          )

        # dispatcher
        dispatcherSection.add nnkProcDef.newTree(
          nnkPostfix.newTree(
            ident("*"),
            nnkAccQuoted.newTree(
              typename,
              ident("/"),
              ident("dispatch")
            )
          ),
          newEmptyNode(),
          newEmptyNode(),
          nnkFormalParams.newTree(
            ident("int32"),
            nnkIdentDefs.newTree(
              ident("impl"),
              ident("pointer"),
              newEmptyNode()
            ),
            nnkIdentDefs.newTree(
              ident("obj"),
              ident("pointer"),
              newEmptyNode()
            ),
            nnkIdentDefs.newTree(
              ident("opcode"),
              ident("uint32"),
              newEmptyNode()
            ),
            nnkIdentDefs.newTree(
              ident("msg"),
              nnkPtrTy.newTree(
                ident("WlMessage")
              ),
              newEmptyNode()
            ),
            nnkIdentDefs.newTree(
              ident("args"),
              ident("pointer"),
              newEmptyNode()
            )
          ),
          nnkPragma.newTree(
            ident("cdecl")
          ),
          newEmptyNode(),
          nnkStmtList.newTree(

            (if events.len != 0: @[nnkLetSection.newTree(
              nnkIdentDefs.newTree(
                ident("callbacks"),
                newEmptyNode(),
                nnkCast.newTree(
                  nnkPtrTy.newTree(
                    nnkAccQuoted.newTree(
                      typename,
                      ident("/"),
                      ident("Callbacks")
                    )
                  ),
                  ident("impl")
                )
              )
            )] else: @[]) &

            nnkCaseStmt.newTree(
              ident("opcode") &
              (block:
                var r: seq[NimNode]
                for i, x in events:
                  r.add makeDispatchOpcode(i, x)
                r
              ) &
              nnkElse.newTree(
                nnkStmtList.newTree(
                  nnkDiscardStmt.newTree(
                    newEmptyNode()
                  )
                )
              )
            )

          )
        )

      proc rettype(msg: Message): NimNode =
        result = newEmptyNode()
        for x in msg.args:
          if x.t == "new_id":
            return x.t.toNimType(x.iface, x.enm)

      # wrapper functions
      for i, req in requests:
        let rt = req.rettype
        let marshal = nnkCall.newTree(
          @[ident("wl_proxy_marshal_flags")] &
          nnkDotExpr.newTree(
            nnkDotExpr.newTree(
              ident("this"),
              ident("proxy")
            ),
            ident("raw")
          ) &
          newLit(i) &
          (if rt.kind == nnkEmpty or rt == ident("uint32"):
            newNilLit()
          else:
            nnkDotExpr.newTree(
              rt,
              ident("iface")
            )
          ) &
          newLit(req.version) &
          newLit(if req.isDestructor: 1 else: 0) &
          req.args.mapit(
            if it.t == "new_id":
              newNilLit()
            else:
              accquote it.name
          )
        )

        wrapperFunctionsSection.add nnkProcDef.newTree(
          nnkPostfix.newTree(
            ident("*"),
            accquote req.name
          ),
          newEmptyNode(),
          newEmptyNode(),
          nnkFormalParams.newTree(
            @[rt] &
            nnkIdentDefs.newTree(
              ident("this"),
              typename,
              newEmptyNode()
            ) &
            req.args.filterIt(it.t != "new_id").mapit(
              nnkIdentDefs.newTree(
                accquote it.name,
                it.t.toNimType(it.iface, it.enm),
                newEmptyNode()
              )
            )
          ),
          newEmptyNode(),
          newEmptyNode(),
          nnkStmtList.newTree(
            (if req.desc != "": @[newCommentStmtNode(req.desc)] else: @[]) &
            (if rt.kind != nnkEmpty and rt != ident("uint32"):
              nnkCall.newTree(
                ident("construct"),
                marshal,
                rt,
                nnkAccQuoted.newTree(
                  rt.unaccquote,
                  ident("/"),
                  ident("dispatch")
                ),
                nnkAccQuoted.newTree(
                  rt.unaccquote,
                  ident("/"),
                  ident("Callbacks")
                )
              )
            else:
              nnkDiscardStmt.newTree(marshal)
            )
          )
        )
  
      # event handler templates
      for evt in events:
        eventHandlerTemplatesSection.add nnkTemplateDef.newTree(
          nnkPostfix.newTree(
            ident("*"),
            accquote("on" & evt.name.capitalize)
          ),
          newEmptyNode(),
          newEmptyNode(),
          nnkFormalParams.newTree(
            newEmptyNode(),
            nnkIdentDefs.newTree(
              ident("this"),
              typename,
              newEmptyNode()
            ),
            nnkIdentDefs.newTree(
              ident("body"),
              newEmptyNode(),
              newEmptyNode()
            )
          ),
          newEmptyNode(),
          newEmptyNode(),
          nnkStmtList.newTree(
            newCommentStmtNode(evt.desc),

            nnkAsgn.newTree(

              nnkDotExpr.newTree(
                nnkCast.newTree(
                  nnkPtrTy.newTree(
                    nnkAccQuoted.newTree(
                      typename,
                      ident("/"),
                      ident("Callbacks")
                    )
                  ),
                  nnkDotExpr.newTree(
                    nnkDotExpr.newTree(
                      nnkDotExpr.newTree(
                        ident("this"),
                        ident("proxy")
                      ),
                      ident("raw")
                    ),
                    ident("impl")
                  )
                ),
                accquote evt.name
              ),

              nnkLambda.newTree(
                newEmptyNode(),
                newEmptyNode(),
                newEmptyNode(),
                nnkFormalParams.newTree(
                  newEmptyNode() &
                  evt.args.mapit(
                    nnkIdentDefs.newTree(
                      nnkPragmaExpr.newTree(
                        accquote it.name,
                        nnkPragma.newTree(
                          ident("inject")
                        )
                      ),
                      it.t.toNimType(it.iface, it.enm),
                      newEmptyNode()
                    )
                  )
                ),
                newEmptyNode(),
                newEmptyNode(),
                nnkStmtList.newTree(
                  ident("body")
                )
              )
              
            )
          )
        )

      # dispatch template
      dispatchTemplatesSection.add nnkTemplateDef.newTree(
        nnkPostfix.newTree(
          ident("*"),
          ident("dispatch")
        ),
        newEmptyNode(),
        newEmptyNode(),
        nnkFormalParams.newTree(
          ident("untyped"),
          nnkIdentDefs.newTree(
            ident("t"),
            nnkBracketExpr.newTree(
              ident("typedesc"),
              typename
            ),
            newEmptyNode()
          )
        ),
        newEmptyNode(),
        newEmptyNode(),
        nnkStmtList.newTree(
          nnkAccQuoted.newTree(
            typename,
            ident("/"),
            ident("dispatch")
          )
        )
      )

      # dispatch template
      callbacksTemplatesSection.add nnkTemplateDef.newTree(
        nnkPostfix.newTree(
          ident("*"),
          ident("Callbacks")
        ),
        newEmptyNode(),
        newEmptyNode(),
        nnkFormalParams.newTree(
          ident("untyped"),
          nnkIdentDefs.newTree(
            ident("t"),
            nnkBracketExpr.newTree(
              ident("typedesc"),
              typename
            ),
            newEmptyNode()
          )
        ),
        newEmptyNode(),
        newEmptyNode(),
        nnkStmtList.newTree(
          nnkAccQuoted.newTree(
            typename,
            ident("/"),
            ident("Callbacks")
          )
        )
      )


  for (kind, path) in walkDir(instantiatedFrom.splitPath.head / "protocols"):
    parse staticRead path

  res.add [typesection, ifaceDeclSection, ifaceBodySection, dispatcherSection, wrapperFunctionsSection, eventHandlerTemplatesSection, dispatchTemplatesSection, callbacksTemplatesSection]

  writeFile(instantiatedFrom.splitPath.head / outNimFile, res.repr)

template generateProtocolWrapperFromXmlString*(outNimFile: static[string]) =
  generateProtocolWrapperFromXmlStringImpl(outNimFile, instantiationInfo(fullPaths=true).filename)

generateProtocolWrapperFromXmlString "protocol_generated.nim"
