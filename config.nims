
when fileExists("src/siwin/build_utils/tasks.nim"):
  include "src/siwin/build_utils/tasks.nim"

when fileExists("src/siwin/build_utils/android.nim"):
  import "src/siwin/build_utils/android.nim"
  when fileExists("src/siwin/build_utils/androidTasks.nim"):
    include "src/siwin/build_utils/androidTasks.nim"

when fileExists("src/siwin/build_utils/macosTasks.nim"):
  include "src/siwin/build_utils/macosTasks.nim"


