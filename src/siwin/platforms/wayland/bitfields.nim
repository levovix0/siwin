import macros

type
  Bitfield*[T: enum] = object
    raw: int32

proc asBitfield*[T: enum](v: T): Bitfield[T] = Bitfield[T](raw: cast[int32](v))
proc asEnum*[T: enum](v: Bitfield[T]): T = cast[T](v.raw)

proc contains*[T: enum](bitfield: Bitfield[T], v: T): bool =
  (bitfield.raw and cast[int32](v)) == cast[int32](v)


macro iterateHoleyEnum*(t: typed, variable, body) =
  result = newStmtList(
    nnkVarSection.newTree(
      nnkIdentDefs.newTree(
        ident("x"),
        newEmptyNode(),
        nnkDotExpr.newTree(
          t,
          ident("default")
        )
      )
    )
  )

  for x in t.getTypeImpl[1].getImpl[2]:
    if x.kind != nnkEnumFieldDef: continue
    result.add @[
      nnkAsgn.newTree(
        ident("x"),
        nnkDotExpr.newTree(
          t,
          ident(x[0].strVal)
        )
      ),
      body
    ]


proc `$`*[T: enum](bitfield: Bitfield[T]): string =
  result = "{"

  iterateHoleyEnum T, x:
    if x in bitfield:
      if result.len != 1:
        result.add ", "
      result.add $x

  result.add "}"
