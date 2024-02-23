import memfiles, os, protocol, vmath

type
  SharedBuffer* = object
    ## memmaped file that can be shared between processes
    shm: WlShm
    buffer: WlBuffer
    file: MemFile
    filename: string

proc dataAddr*(buffer: SharedBuffer): pointer =
  buffer.file.mem

proc fileDescriptor*(buffer: SharedBuffer): FileHandle =
  buffer.file.handle

proc buffer*(buffer: SharedBuffer): WlBuffer =
  buffer.buffer

proc `=destroy`(buffer: SharedBuffer) =
  try:
    close buffer.addr[].file
  except OsError: discard

proc create*(shm: WlShm, size: IVec2, format: `WlShm / Format`, pixelSize = 4): SharedBuffer =
  result.shm = shm

  let filebase = getEnv("XDG_RUNTIME_DIR") / "siwin-"
  for i in 0..int.high:
    if not fileExists(filebase & $i):
      result.filename = filebase & $i
      result.file = memfiles.open(result.filename, mode = fmReadWrite,
          allowRemap = true, newFileSize = size.x * size.y * pixelSize)
      break

  let pool = shm.create_pool(result.fileDescriptor, size.x * size.y * 4)
  result.buffer = pool.create_buffer(0, size.x, size.y, size.x * 4, format)
  destroy pool
