import memfiles, os, protocol, vmath

type
  SharedBuffer* = object
    ## memmaped file that can be shared between processes
    shm: WlShm
    buffer: WlBuffer
    file: MemFile
    filename: string
    format: `WlShm / Format`
    pixelSize: int32

proc dataAddr*(buffer: SharedBuffer): pointer =
  buffer.file.mem

proc fileDescriptor*(buffer: SharedBuffer): FileHandle =
  buffer.file.handle

proc buffer*(buffer: SharedBuffer): WlBuffer =
  buffer.buffer

proc `=destroy`(buffer: SharedBuffer) =
  if buffer.buffer.proxy.raw != nil:
    destroy buffer.buffer

  try:
    close buffer.addr[].file
  except OsError: discard

proc create*(shm: WlShm, size: IVec2, format: `WlShm / Format`, pixelSize: int32 = 4): SharedBuffer =
  result.shm = shm
  result.format = format
  result.pixelSize = pixelSize

  let filebase = getEnv("XDG_RUNTIME_DIR") / "siwin-"
  for i in 0..int.high:
    if not fileExists(filebase & $i):
      result.filename = filebase & $i
      result.file = memfiles.open(result.filename, mode = fmReadWrite,
          allowRemap = true, newFileSize = size.x * size.y * pixelSize)
      break

  let pool = shm.create_pool(result.fileDescriptor, size.x * size.y * pixelSize)
  result.buffer = pool.create_buffer(0, size.x, size.y, size.x * pixelSize, format)
  destroy pool

proc resize*(buffer: var SharedBuffer, size: IVec2) =
  buffer.file.unmapMem(buffer.dataAddr, size.x * size.y * 4)
  buffer.file.mem = buffer.file.mapMem(fmReadWrite, size.x * size.y * 4)

  destroy buffer.buffer

  let pool = buffer.shm.create_pool(buffer.fileDescriptor, size.x * size.y * buffer.pixelSize)
  buffer.buffer = pool.create_buffer(0, size.x, size.y, size.x * buffer.pixelSize, buffer.format)
  destroy pool
