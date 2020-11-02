#include "siwim.hpp"
using namespace siwim

int main() {
  Window win(1280, 720, "basic window");

  win.on_key_down = [&win](KeyEvent e) {
    if (e.key == Key.escape) {
      win.close();
    }
  }

  win.on_render = [&win](RenderEvent e) {
    Renderer r(win);
    r.clear(Color(0x202020));
    r.rectangle(100, 50, 300, 200, Color(0x40FF40));
  }

  win.run();

  return 0;
}
