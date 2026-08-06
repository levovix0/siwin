#include "../bindings/siwin.h"

#ifdef __cplusplus
	using namespace siwin;
#endif


void on_render(RenderEvent* e, NimRootObj* env) {
	PixelBuffer pb = {0};
	siwin_window_pixel_buffer(e->base.window, &pb);

	for (int y = 0; y < pb.size_y; ++y) {
		for (int x = 0; x < pb.size_x; ++x) {
			unsigned char *pixel = (unsigned char*)pb.data + y * pb.size_x * 4 + x * 4;
			pixel[0] = 255; // R
			pixel[1] = 0;   // G
			pixel[2] = 0;   // B
			pixel[3] = 255; // A
		}
	}

	siwin_convert_pixels_inplace(&pb, Format_rgba_32bit);
}


#ifdef SIWIN_STATIC
	SIWIN_STATIC_OUTMAIN_BOILERPLATE
#endif


int main(int argc, char *argv[]) {
	#ifdef SIWIN_STATIC
		SIWIN_STATIC_INMAIN_BOILERPLATE
	#endif

  Platform platform = siwin_default_platform();
  SiwinGlobals globals = siwin_new_globals(platform);
  SiwinEventLoopWaker waker = siwin_event_loop_waker(globals);

  /* A retained waker can be handed to a producer without sharing globals. */
  siwin_event_loop_waker_wake(waker);
  if (siwin_wait_events(globals, 0) != 0) {
    return 1;
  }

  Window win = siwin_new_software_rendering_window(
		globals,
		800, 600, "Default title", 0, 0,
		1, 0, 0, ""
	);

	struct WindowEventHandler eh = {0};
	eh.on_render = &on_render;

	siwin_window_set_event_handler(win, &eh);

	Clipboard clipboard = siwin_window_clipboard(win);
	siwin_clipboard_set_text(clipboard, "Sorry for messing up with your keyboard, but hello from siwin C bindings!");

	siwin_window_set_title(win, "Hello from C bindings of siwin!");
	siwin_window_run(win, 1);
	siwin_destroy_window(win);

	siwin_destroy_globals(globals);
  /* Retaining the waker past loop shutdown is safe; waking becomes a no-op. */
  siwin_event_loop_waker_wake(waker);
  siwin_destroy_event_loop_waker(waker);
  return 0;
}
