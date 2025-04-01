import std/[memfiles, os, times, sequtils]
import pkg/[vmath]
import ../../[siwindefs]
import ./[protocol, libwayland, siwinGlobals]

type
  SharedBuffer* = ref SharedBufferObj
  SharedBufferObj* = object
    ## memmaped file that can be shared between processes
    globals: SiwinGlobalsWayland
    shm: WlShm
    pool: WlShmPool
    file: MemFile
    filename: string
    format: `WlShm / Format`
    bytesPerPixel: int32
    size: IVec2
    buffers: seq[tuple[locked: bool, buffer: WlBuffer]]
    currentBuffer: int


proc dataAddr*(buffer: SharedBuffer): pointer =
  cast[pointer](cast[int](buffer.file.mem) + buffer.size.x * buffer.size.y * buffer.bytesPerPixel * buffer.currentBuffer.int32)

proc fileDescriptor*(buffer: SharedBuffer): FileHandle =
  buffer.file.handle

proc buffer*(buffer: SharedBuffer): WlBuffer =
  buffer.buffers[buffer.currentBuffer].buffer
  # buffer buffer

proc locked*(buffer: SharedBuffer): bool =
  buffer.buffers.anyIt(it.locked)



proc release*(buffer: SharedBuffer) {.raises: [Exception].} =
  for v in buffer.buffers.mitems:
    if v.buffer.proxy.raw != nil:
      destroy v.buffer
    v.buffer.proxy.raw = nil


proc `=destroy`(buffer: SharedBufferObj) {.siwin_destructor.} =
  try:
    for v in buffer.buffers:
      if v.buffer.proxy.raw != nil:
        destroy v.buffer
    
    if buffer.pool.proxy.raw != nil:
      destroy buffer.pool

    discard wl_display_roundtrip buffer.globals.display  # make sure server don't use the memory we about to dealloc
  except: discard

  try:
    close buffer.addr[].file
    removeFile(buffer.filename)
  except OsError: discard


proc swapBuffers*(
  buffer: var SharedBuffer, timeout: Duration = initDuration(milliseconds = 500)
) {.raises: [OsError, Exception].} =
  ## locks current buffer, then swaps current buffer with not-locked one.
  ## of all buffers are locked, synchronically waits up to timeout time until server unlockes one of them.
  ## if timeout reached, raises OsError.
  ## ! please make sure you attached current buffer to a surface before calling this proc

  # first, lock, attach and commit current buffer
  buffer.buffers[buffer.currentBuffer].locked = true

  # then, swap to not-locked buffer
  for i, v in buffer.buffers:
    if not v.locked:
      buffer.currentBuffer = i
      break

  # if unlocked buffer was not found, wait up to timeout while trying again
  if buffer.buffers[buffer.currentBuffer].locked:
    let deadline = now() + timeout
    
    block waiting_for_unlocked_buffer:
      while now() < deadline:
        for i in 0..buffer.buffers.high:
          if not buffer.buffers[i].locked:
            buffer.currentBuffer = i
            break waiting_for_unlocked_buffer
        
        discard wl_display_roundtrip buffer.globals.display  # let libwayland process events
  
  if buffer.buffers[buffer.currentBuffer].locked:
    raise OsError.newException("timed out waiting for all buffers to be unlocked by server. (needed to commit shared buffer)")

  # current buffer are now unlocked and free to use.



proc create_wl_buffers(buffer: SharedBuffer) =
  for i, v in buffer.buffers.mpairs:
    v.buffer = buffer.pool.create_buffer(
      offset = buffer.size.x * buffer.size.y * buffer.bytesPerPixel * i.int32,
      buffer.size.x, buffer.size.y,
      buffer.size.x * buffer.bytesPerPixel, buffer.format
    )

    (proc(this: SharedBuffer, i: int) {.nimcall.} =
      this.buffers[i].buffer.onRelease:
        this.buffers[i].locked = false
    )(buffer, i)



proc create*(globals: SiwinGlobalsWayland, shm: WlShm, size: IVec2, format: `WlShm / Format`, bytesPerPixel: int32 = 4, bufferCount = 2): SharedBuffer =
  new result
  result.globals = globals
  result.shm = shm
  result.format = format
  result.bytesPerPixel = bytesPerPixel
  result.size = size

  assert bufferCount >= 1, "at least one buffer is required"
  result.buffers.setLen bufferCount

  let filebase = getEnv("XDG_RUNTIME_DIR") / "siwin-"
  for i in 0..int.high:
    if not fileExists(filebase & $i):
      result.filename = filebase & $i
      result.file = memfiles.open(
        result.filename, mode = fmReadWrite, allowRemap = true,
        newFileSize = size.x * size.y * bytesPerPixel * bufferCount.int32
      )
      break

  result.pool = shm.create_pool(result.fileDescriptor, size.x * size.y * bytesPerPixel * bufferCount.int32)
  result.create_wl_buffers()



proc resize*(buffer: var SharedBuffer, size: IVec2, timeout: Duration = initDuration(milliseconds = 500)) =
  ## ! please make sure buffer is currently not attached to any surface before calling this proc
  buffer.size = size
  let newSizeInBytes = size.x * size.y * buffer.bytesPerPixel * buffer.buffers.len.int32

  let deadline = now() + timeout
  while now() < deadline and buffer.buffers.anyIt(it.locked):
    discard wl_display_roundtrip buffer.globals.display

  if newSizeInBytes > buffer.file.size:
    buffer.file.resize(newSizeInBytes)
    buffer.file.flush()
    buffer.pool.resize(newSizeInBytes)

  if buffer.buffers.anyIt(it.locked):
    raise OsError.newException("timed out waiting for all buffers to be unlocked by server. (needed to resize shared buffer)")
  
  for v in buffer.buffers:
    if v.buffer.proxy.raw != nil:
      destroy v.buffer

  buffer.create_wl_buffers()
