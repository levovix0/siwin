
#ifdef __cplusplus
	namespace siwin {
#endif

typedef struct {} *SiwinGlobals;
typedef struct {} *Window;
typedef struct {} *Screen;
typedef struct {} *Clipboard;


typedef struct NimRtti {
	void* destructor;
	void* size;  // int of pointer size
	short align;
	short depth;
	unsigned int* display;
	void* traceImpl;
	void* typeInfoV1;
	void* flags;  // int of pointer size
	void* vTable[128];
} NimRtti;


typedef struct NimRootObj {
	NimRtti* rtti;
} NimRootObj;


typedef enum PixelBufferFormat {
	Format_bgra_32bit = 0,
	Format_bgrx_32bit,
	Format_bgru_32bit,
	Format_xrgb_32bit,
	Format_urgb_32bit,
	Format_rgba_32bit,
	Format_rgbx_32bit,
	Format_rgbu_32bit
} PixelBufferFormat;

typedef struct PixelBuffer {
	void* data;
  int size_x;
  int size_y;
	PixelBufferFormat format;
} PixelBuffer;



typedef enum CursorKind {
  builtin,
  image
} CursorKind;

typedef enum BuiltinCursor {
	Cursor_arrow = 0, Cursor_arrowUp, Cursor_arrowRight,
	Cursor_wait, Cursor_arrowWait,
	Cursor_pointingHand, Cursor_grab,
	Cursor_text, Cursor_cross,
	Cursor_sizeAll, Cursor_sizeHorizontal, Cursor_sizeVertical,
	Cursor_sizeTopLeft, Cursor_sizeTopRight, Cursor_sizeBottomLeft, Cursor_sizeBottomRight,
	Cursor_hided
} BuiltinCursor;

typedef struct ImageCursor {
  int origin_x;
  int origin_y;
  PixelBuffer pixels;
} ImageCursor;

typedef struct Cursor {
  CursorKind kind;
	union {
		BuiltinCursor builtin;
		ImageCursor image;
	};
} Cursor;

typedef enum Platform {
	Platform_x11 = 0,
	Platform_wayland,
	Platform_winapi,
	Platform_cocoa,
	Platform_android
} Platform;



typedef enum MouseButton {
	Button_left,
	Button_right,
	Button_middle,
	Button_forward,
	Button_backward
} MouseButton;

typedef enum Key {
	Key_unknown = 0,

	Key_a, Key_b, Key_c, Key_d, Key_e, Key_f, Key_g, Key_h, Key_i, Key_j, Key_k, Key_l,
	Key_m, Key_n, Key_o, Key_p, Key_q, Key_r, Key_s, Key_t, Key_u, Key_v, Key_w, Key_x, Key_y, Key_z,
	Key_tilde, Key_n1, Key_n2, Key_n3, Key_n4, Key_n5, Key_n6, Key_n7, Key_n8, Key_n9, Key_n0, Key_minus, Key_equal,
	Key_f1, Key_f2, Key_f3, Key_f4, Key_f5, Key_f6, Key_f7, Key_f8, Key_f9, Key_f10, Key_f11, Key_f12, Key_f13, Key_f14, Key_f15,
	Key_lcontrol, Key_rcontrol,  Key_lshift, Key_rshift,  Key_lalt, Key_ralt,  Key_lsystem, Key_rsystem, Key_lbracket, Key_rbracket,
	Key_space, Key_escape, Key_enter, Key_tab, Key_backspace, Key_menu,
	Key_slash, Key_dot, Key_comma,  Key_semicolon, Key_quote,  Key_backslash,

	Key_pageUp, Key_pageDown, Key_home, Key_End, Key_insert, Key_del,
	Key_left, Key_right, Key_up, Key_down,
	Key_npad0, Key_npad1, Key_npad2, Key_npad3, Key_npad4, Key_npad5, Key_npad6, Key_npad7, Key_npad8, Key_npad9, Key_npadDot,
	Key_add, Key_subtract, Key_multiply, Key_divide,
	Key_capsLock, Key_numLock, Key_scrollLock, Key_printScreen, Key_pause,

	Key_level3_shift, Key_level5_shift
} Key;

typedef struct Touch {
	int id;
	float pos_x;
	float pos_y;
} Touch;

typedef struct Mouse {
	float pos_x;
	float pos_y;
	unsigned char pressed_bitmask[1];
} Mouse;

typedef struct Keyboard {
	unsigned char pressed_bitmask[14];
} Keyboard;

typedef struct TouchScreen {
	void* pressed_table[3];  // id -> touch
} TouchScreen;

typedef enum Edge {
	Edge_left,
	Edge_right,
	Edge_top,
	Edge_bottom,
	Edge_topLeft,
	Edge_topRight,
	Edge_bottomLeft,
	Edge_bottomRight
} Edge;


typedef enum MouseMoveKind {
	Move_move = 0,
	Move_enter,
	Move_leave,
	Move_moveWhileDragging  // (from this or other window)
} MouseMoveKind;

typedef enum DragStatus {
	Drag_rejected,
	Drag_accepted
} DragStatus;



typedef struct AnyWindowEvent {
	NimRootObj base;
	Window window;
} AnyWindowEvent;

typedef struct CloseEvent {
	AnyWindowEvent base;
} CloseEvent;

typedef struct RenderEvent {
	AnyWindowEvent base;
} RenderEvent;

typedef struct TickEvent {
	AnyWindowEvent base;
	float deltaTime;
} TickEvent;

typedef struct ResizeEvent {
	AnyWindowEvent base;
	int size_x;
	int size_y;
	char initial;
} ResizeEvent;

typedef struct WindowMoveEvent {
	AnyWindowEvent base;
	int pos_x;
	int pos_y;
} WindowMoveEvent;

typedef struct MouseMoveEvent {
	AnyWindowEvent base;
	float pos_x;
	float pos_y;
	MouseMoveKind kind;
} MouseMoveEvent;

typedef struct MouseButtonEvent {
	AnyWindowEvent base;
	MouseButton button;
	char pressed;
	char generated;
} MouseButtonEvent;

typedef struct ScrollEvent {
	AnyWindowEvent base;
	float delta;
	float deltaX;
} ScrollEvent;

typedef struct ClickEvent {
	AnyWindowEvent base;
	MouseButton button;
	float pos_x;
	float pos_y;
	char doubleClick;
} ClickEvent;

typedef struct KeyEvent {
	AnyWindowEvent base;
	Key key;
	char pressed;
	char repeated;
	char generated;
} KeyEvent;

typedef struct TextInputEvent {
	AnyWindowEvent base;
	char* text;
	char repeated;
} TextInputEvent;

typedef struct TouchEvent {
	AnyWindowEvent base;
	int touchId;
	char pressed;
	float pos_x;
	float pos_y;
} TouchEvent;

typedef struct TouchMoveEvent {
	AnyWindowEvent base;
	int touchId;
	float pos_x;
	float pos_y;
} TouchMoveEvent;

typedef enum StateBoolChangedEventKind {
	BoolState_focus,
	BoolState_fullscreen,
	BoolState_maximized,
	BoolState_frameless
} StateBoolChangedEventKind;

typedef struct StateBoolChangedEvent {
	AnyWindowEvent base;
	char value;
	StateBoolChangedEventKind kind;
	char isExternal;
} StateBoolChangedEvent;

typedef struct DropEvent {
	AnyWindowEvent base;
} DropEvent;


typedef struct WindowEventHandler {
	void (*on_close)(CloseEvent* event, NimRootObj* env);
	NimRootObj* on_close_env;

	void (*on_render)(RenderEvent* event, NimRootObj* env);
	NimRootObj* on_render_env;

	void (*on_tick)(TickEvent* event, NimRootObj* env);
	NimRootObj* on_tick_env;

	void (*on_resize)(ResizeEvent* event, NimRootObj* env);
	NimRootObj* on_resize_env;

	void (*on_window_move)(WindowMoveEvent* event, NimRootObj* env);
	NimRootObj* on_window_move_env;

	void (*on_mouse_move)(MouseMoveEvent* event, NimRootObj* env);
	NimRootObj* on_mouse_move_env;

	void (*on_mouse_button)(MouseButtonEvent* event, NimRootObj* env);
	NimRootObj* on_mouse_button_env;

	void (*on_scroll)(ScrollEvent* event, NimRootObj* env);
	NimRootObj* on_scroll_env;

	void (*on_click)(ClickEvent* event, NimRootObj* env);
	NimRootObj* on_click_env;

	void (*on_key)(KeyEvent* event, NimRootObj* env);
	NimRootObj* on_key_env;

	void (*on_text_input)(TextInputEvent* event, NimRootObj* env);
	NimRootObj* on_text_input_env;

	void (*on_touch)(TouchEvent* event, NimRootObj* env);
	NimRootObj* on_touch_env;

	void (*on_touch_move)(TouchMoveEvent* event, NimRootObj* env);
	NimRootObj* on_touch_move_env;

	void (*on_state_bool_changed)(StateBoolChangedEvent* event, NimRootObj* env);
	NimRootObj* on_state_bool_changed_env;

	void (*on_drop)(DropEvent* event, NimRootObj* env);
	NimRootObj* on_drop_env;
} WindowEventsHandler;



#ifdef __cplusplus
	extern "C" {
#endif
	extern Platform siwin_default_platform();
	extern SiwinGlobals siwin_new_globals(Platform platform);
	extern void siwin_destroy_globals(SiwinGlobals globals);

	extern void siwin_destroy_window(Window window);
	
	extern Window siwin_new_software_rendering_window(
		SiwinGlobals globals,
		int size_x, int size_y, const char* title, int screen,
		char fullscreen, char resizable, char frameless, char transparent,
		const char* winclass
	);
	
	extern Window siwin_new_opengl_window(
		SiwinGlobals globals,
		int size_x, int size_y, const char* title, int screen,
		char fullscreen, char resizable, char frameless, char transparent, char vsync,
		const char* winclass
	);
	
	extern Window siwin_new_vulkan_window(
		SiwinGlobals globals, void* vulkan_instance,
		int size_x, int size_y, const char* title, int screen,
		char fullscreen, char resizable, char frameless, char transparent,
		const char* winclass
	);

	extern int siwin_screen_count(SiwinGlobals globals);
	extern Screen siwin_default_screen(SiwinGlobals globals);
	extern Screen siwin_get_screen(SiwinGlobals globals, int n);
	extern int siwin_screen_number(Screen screen);
	extern int siwin_sreen_width(Screen screen);
	extern int siwin_sreen_height(Screen screen);

	extern char siwin_window_closed(Window window);
	extern char siwin_window_opened(Window window);
	extern void siwin_window_close(Window window);
	extern char siwin_window_transparent(Window window);
	extern char siwin_window_frameless(Window window);
	extern void siwin_window_cursor(Window window, Cursor* out_cursor);
	extern char siwin_window_separateTouch(Window window);

	extern void siwin_window_size(Window window, int* out_size_x, int* out_size_y);
	extern void siwin_window_pos(Window window, int* out_pos_x, int* out_pos_y);

	extern char siwin_window_fullscreen(Window window);
	extern char siwin_window_maximized(Window window);
	extern char siwin_window_minimized(Window window);
	extern char siwin_window_visible(Window window);
	extern char siwin_window_resizable(Window window);

	extern void siwin_window_minSize(Window window, int* out_minSize_x, int* out_minSize_y);
	extern void siwin_window_maxSize(Window window, int* out_maxSize_x, int* out_maxSize_y);

	extern char siwin_window_focused(Window window);
	extern void siwin_window_redraw(Window window);
	extern void siwin_window_set_frameless(Window window, char v);
	extern void siwin_window_set_cursor(Window window, Cursor* v);
	extern void siwin_window_set_separate_touch(Window window, char v);
	extern void siwin_window_set_size(Window window, int size_x, int size_y);
	extern void siwin_window_set_pos(Window window, int pos_x, int pos_y);
	extern void siwin_window_set_title(Window window, const char* v);
	extern void siwin_window_set_fullscreen(Window window, char v);
	extern void siwin_window_set_maximized(Window window, char v);
	extern void siwin_window_set_minimized(Window window, char v);
	extern void siwin_window_set_visible(Window window, char v);
	extern void siwin_window_set_resizable(Window window, char v);
	extern void siwin_window_set_min_size(Window window, int v_x, int v_y);
	extern void siwin_window_set_max_size(Window window, int v_x, int v_y);

	extern void siwin_window_clear_icon(Window window);
	extern void siwin_window_set_icon(Window window, PixelBuffer* v);

	extern void siwin_window_start_interactive_move(Window window, char has_pos, float pos_x, float pos_y);
	extern void siwin_window_start_interactive_resize(Window window, Edge edge, char has_pos, float pos_x, float pos_y);
	extern void siwin_window_show_window_menu(Window window, char has_pos, float pos_x, float pos_y);

	extern void siwin_window_set_input_region(Window window, float pos_x, float pos_y, float size_x, float size_y);
	extern void siwin_window_set_title_region(Window window, float pos_x, float pos_y, float size_x, float size_y);
	extern void siwin_window_set_border_width(Window window, float innerWidth, float outerWidth, float diagonalSize);

	extern void siwin_window_pixel_buffer(Window window, PixelBuffer* out_buffer);
	extern void siwin_window_make_current(Window window);

	extern char siwin_window_set_vsync(Window window, char v);
	extern void* siwin_window_vulkan_surface(Window window);
	extern Clipboard siwin_window_clipboard(Window window);
	extern Clipboard siwin_window_selection_clipboard(Window window);
	extern Clipboard siwin_window_dragndrop_clipboard(Window window);
	extern void siwin_window_set_drag_status(Window window, DragStatus v);
	extern void siwin_window_first_step(Window window, char makeVisible);
	extern void siwin_window_step(Window window);
	extern void siwin_window_run(Window window, char makeVisible);

	extern void siwin_window_set_event_handler(Window window, struct WindowEventHandler* eventHandler);

	extern void siwin_convert_pixels_inplace(PixelBuffer* pb, PixelBufferFormat fromFormat);

	extern void siwin_destroy_clipboard(Clipboard clipboard);
	extern int siwin_clipboard_text(Clipboard clipboard, char* out_text, int maxLen);
	extern void siwin_clipboard_set_text(Clipboard clipboard, const char* text);


	#ifdef __cplusplus
	}  // extern "C"
#endif


#ifdef __cplusplus
	}  // namespace siwin
#endif


#define SIWIN_STATIC_OUTMAIN_BOILERPLATE \
	char** cmdLine; \
	int cmdCount; \
	void NimMain();

#define SIWIN_STATIC_INMAIN_BOILERPLATE \
	cmdCount = argc; \
	cmdLine = argv; \
	NimMain();

