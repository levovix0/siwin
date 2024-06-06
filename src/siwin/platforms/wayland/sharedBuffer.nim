import std/[memfiles, os]
import pkg/[vmath]
import ./[protocol, libwayland]

type
  SharedBuffer* = object
    ## memmaped file that can be shared between processes
    shm: WlShm
    pool: WlShmPool
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
  
  if buffer.pool.proxy.raw != nil:
    destroy buffer.pool

  try:
    close buffer.addr[].file
    removeFile(buffer.filename)
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

  result.pool = shm.create_pool(result.fileDescriptor, size.x * size.y * pixelSize)
  result.buffer = result.pool.create_buffer(0, size.x, size.y, size.x * pixelSize, format)


proc resize*(buffer: var SharedBuffer, size: IVec2) =
  let newSizeInBytes = size.x * size.y * buffer.pixelSize

  #? destroying buffer (even if not nil) causes to crash somehow, so we just don't do it

  if newSizeInBytes > buffer.file.size:
    try:
      buffer.file.resize(newSizeInBytes)
    except OsError:
      #? sometimes somehow (in the tests/tests.nim bgrx image test) OS declines resizing memfile (i have no glue what heapening)
      buffer = create(buffer.shm, size, buffer.format, buffer.pixelSize)
      return
    
    buffer.pool.resize(newSizeInBytes)

  buffer.buffer = buffer.pool.create_buffer(0, size.x, size.y, size.x * buffer.pixelSize, buffer.format)
