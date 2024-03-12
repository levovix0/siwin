import posix

type
  xkb_context* = object
  xkb_keymap* = object
  xkb_state* = object

  xkb_keycode_t* = uint32
  xkb_keysym_t* = uint32
  xkb_layout_index_t* = uint32
  xkb_layout_mask_t* = uint32
  xkb_level_index_t* = uint32
  xkb_mod_index_t* = uint32
  xkb_mod_mask_t* = uint32
  xkb_led_index_t* = uint32
  xkb_led_mask_t* = uint32

  xkb_rule_names* {.bycopy.} = object
    rules*: cstring
    model*: cstring
    layout*: cstring
    variant*: cstring
    options*: cstring

  xkb_keysym_flags* = enum
    XKB_KEYSYM_NO_FLAGS = 0,
    XKB_KEYSYM_CASE_INSENSITIVE = (1 shl 0)

  xkb_context_flags* = enum
    XKB_CONTEXT_NO_FLAGS = 0,
    XKB_CONTEXT_NO_DEFAULT_INCLUDES = (1 shl 0),
    XKB_CONTEXT_NO_ENVIRONMENT_NAMES = (1 shl 1),
    XKB_CONTEXT_NO_SECURE_GETENV = (1 shl 2)

  xkb_log_level* = enum
    XKB_LOG_LEVEL_CRITICAL = 10,
    XKB_LOG_LEVEL_ERROR = 20,
    XKB_LOG_LEVEL_WARNING = 30,
    XKB_LOG_LEVEL_INFO = 40,
    XKB_LOG_LEVEL_DEBUG = 50

  xkb_keymap_compile_flags* = enum
    XKB_KEYMAP_COMPILE_NO_FLAGS = 0

  xkb_keymap_format* = enum
    XKB_KEYMAP_USE_ORIGINAL_FORMAT = -1,
    XKB_KEYMAP_FORMAT_TEXT_V1 = 1

  xkb_keymap_key_iter_t* = proc (keymap: ptr xkb_keymap; key: xkb_keycode_t;
                              data: pointer)

  xkb_key_direction* = enum
    XKB_KEY_DIRECTION_UP,
    XKB_KEY_DIRECTION_DOWN

  xkb_state_component* = enum
    XKB_STATE_MODS_DEPRESSED = (1 shl 0),
    XKB_STATE_MODS_LATCHED = (1 shl 1),
    XKB_STATE_MODS_LOCKED = (1 shl 2),
    XKB_STATE_MODS_EFFECTIVE = (1 shl 3),
    XKB_STATE_LAYOUT_DEPRESSED = (1 shl 4),
    XKB_STATE_LAYOUT_LATCHED = (1 shl 5),
    XKB_STATE_LAYOUT_LOCKED = (1 shl 6),
    XKB_STATE_LAYOUT_EFFECTIVE = (1 shl 7),
    XKB_STATE_LEDS = (1 shl 8)

  xkb_state_match* = enum
    XKB_STATE_MATCH_ANY = (1 shl 0),
    XKB_STATE_MATCH_ALL = (1 shl 1),
    XKB_STATE_MATCH_NON_EXCLUSIVE = (1 shl 16)

  xkb_consumed_mode* = enum
    XKB_CONSUMED_MODE_XKB,
    XKB_CONSUMED_MODE_GTK


const
  XKB_KEYCODE_INVALID* = (0xffffffff)
  XKB_LAYOUT_INVALID* = (0xffffffff)
  XKB_LEVEL_INVALID* = (0xffffffff)
  XKB_MOD_INVALID* = (0xffffffff)
  XKB_LED_INVALID* = (0xffffffff)
  XKB_KEYCODE_MAX* = (0xffffffff - 1)
  XKB_KEYSYM_MAX* = 0x1fffffff
const
  XKB_KEY_NoSymbol* = 0x000000


const
  XKB_KEY_VoidSymbol* = 0xffffff


const
  XKB_KEY_BackSpace* = 0xff08
  XKB_KEY_Tab* = 0xff09
  XKB_KEY_Linefeed* = 0xff0a
  XKB_KEY_Clear* = 0xff0b
  XKB_KEY_Return* = 0xff0d
  XKB_KEY_Pause* = 0xff13
  XKB_KEY_Scroll_Lock* = 0xff14
  XKB_KEY_Sys_Req* = 0xff15
  XKB_KEY_Escape* = 0xff1b
  XKB_KEY_Delete* = 0xffff


const
  XKB_KEY_Multi_key* = 0xff20
  XKB_KEY_Codeinput* = 0xff37
  XKB_KEY_SingleCandidate* = 0xff3c
  XKB_KEY_MultipleCandidate* = 0xff3d
  XKB_KEY_PreviousCandidate* = 0xff3e


const
  XKB_KEY_Kanji* = 0xff21
  XKB_KEY_Muhenkan* = 0xff22
  XKB_KEY_Henkan_Mode* = 0xff23
  XKB_KEY_Henkan* = 0xff23
  XKB_KEY_Romaji* = 0xff24
  XKB_KEY_Hiragana* = 0xff25
  XKB_KEY_Katakana* = 0xff26
  XKB_KEY_Hiragana_Katakana* = 0xff27
  XKB_KEY_Zenkaku* = 0xff28
  XKB_KEY_Hankaku* = 0xff29
  XKB_KEY_Zenkaku_Hankaku* = 0xff2a
  XKB_KEY_Touroku* = 0xff2b
  XKB_KEY_Massyo* = 0xff2c
  XKB_KEY_Kana_Lock* = 0xff2d
  XKB_KEY_Kana_Shift* = 0xff2e
  XKB_KEY_Eisu_Shift* = 0xff2f
  XKB_KEY_Eisu_toggle* = 0xff30
  XKB_KEY_Kanji_Bangou* = 0xff37
  XKB_KEY_Zen_Koho* = 0xff3d
  XKB_KEY_Mae_Koho* = 0xff3e


const
  XKB_KEY_Home* = 0xff50
  XKB_KEY_Left* = 0xff51
  XKB_KEY_Up* = 0xff52
  XKB_KEY_Right* = 0xff53
  XKB_KEY_Down* = 0xff54
  XKB_KEY_Prior* = 0xff55
  XKB_KEY_Page_Up* = 0xff55
  XKB_KEY_Next* = 0xff56
  XKB_KEY_Page_Down* = 0xff56
  XKB_KEY_End* = 0xff57
  XKB_KEY_Begin* = 0xff58


const
  XKB_KEY_Select* = 0xff60
  XKB_KEY_Print* = 0xff61
  XKB_KEY_Execute* = 0xff62
  XKB_KEY_Insert* = 0xff63
  XKB_KEY_Undo* = 0xff65
  XKB_KEY_Redo* = 0xff66
  XKB_KEY_Menu* = 0xff67
  XKB_KEY_Find* = 0xff68
  XKB_KEY_Cancel* = 0xff69
  XKB_KEY_Help* = 0xff6a
  XKB_KEY_Break* = 0xff6b
  XKB_KEY_Mode_switch* = 0xff7e
  XKB_KEY_script_switch* = 0xff7e
  XKB_KEY_Num_Lock* = 0xff7f


const
  XKB_KEY_KP_Space* = 0xff80
  XKB_KEY_KP_Tab* = 0xff89
  XKB_KEY_KP_Enter* = 0xff8d
  XKB_KEY_KP_F1* = 0xff91
  XKB_KEY_KP_F2* = 0xff92
  XKB_KEY_KP_F3* = 0xff93
  XKB_KEY_KP_F4* = 0xff94
  XKB_KEY_KP_Home* = 0xff95
  XKB_KEY_KP_Left* = 0xff96
  XKB_KEY_KP_Up* = 0xff97
  XKB_KEY_KP_Right* = 0xff98
  XKB_KEY_KP_Down* = 0xff99
  XKB_KEY_KP_Prior* = 0xff9a
  XKB_KEY_KP_Page_Up* = 0xff9a
  XKB_KEY_KP_Next* = 0xff9b
  XKB_KEY_KP_Page_Down* = 0xff9b
  XKB_KEY_KP_End* = 0xff9c
  XKB_KEY_KP_Begin* = 0xff9d
  XKB_KEY_KP_Insert* = 0xff9e
  XKB_KEY_KP_Delete* = 0xff9f
  XKB_KEY_KP_Equal* = 0xffbd
  XKB_KEY_KP_Multiply* = 0xffaa
  XKB_KEY_KP_Add* = 0xffab
  XKB_KEY_KP_Separator* = 0xffac
  XKB_KEY_KP_Subtract* = 0xffad
  XKB_KEY_KP_Decimal* = 0xffae
  XKB_KEY_KP_Divide* = 0xffaf
  XKB_KEY_KP_0* = 0xffb0
  XKB_KEY_KP_1* = 0xffb1
  XKB_KEY_KP_2* = 0xffb2
  XKB_KEY_KP_3* = 0xffb3
  XKB_KEY_KP_4* = 0xffb4
  XKB_KEY_KP_5* = 0xffb5
  XKB_KEY_KP_6* = 0xffb6
  XKB_KEY_KP_7* = 0xffb7
  XKB_KEY_KP_8* = 0xffb8
  XKB_KEY_KP_9* = 0xffb9


const
  XKB_KEY_F1* = 0xffbe
  XKB_KEY_F2* = 0xffbf
  XKB_KEY_F3* = 0xffc0
  XKB_KEY_F4* = 0xffc1
  XKB_KEY_F5* = 0xffc2
  XKB_KEY_F6* = 0xffc3
  XKB_KEY_F7* = 0xffc4
  XKB_KEY_F8* = 0xffc5
  XKB_KEY_F9* = 0xffc6
  XKB_KEY_F10* = 0xffc7
  XKB_KEY_F11* = 0xffc8
  XKB_KEY_L1* = 0xffc8
  XKB_KEY_F12* = 0xffc9
  XKB_KEY_L2* = 0xffc9
  XKB_KEY_F13* = 0xffca
  XKB_KEY_L3* = 0xffca
  XKB_KEY_F14* = 0xffcb
  XKB_KEY_L4* = 0xffcb
  XKB_KEY_F15* = 0xffcc
  XKB_KEY_L5* = 0xffcc
  XKB_KEY_F16* = 0xffcd
  XKB_KEY_L6* = 0xffcd
  XKB_KEY_F17* = 0xffce
  XKB_KEY_L7* = 0xffce
  XKB_KEY_F18* = 0xffcf
  XKB_KEY_L8* = 0xffcf
  XKB_KEY_F19* = 0xffd0
  XKB_KEY_L9* = 0xffd0
  XKB_KEY_F20* = 0xffd1
  XKB_KEY_L10* = 0xffd1
  XKB_KEY_F21* = 0xffd2
  XKB_KEY_R1* = 0xffd2
  XKB_KEY_F22* = 0xffd3
  XKB_KEY_R2* = 0xffd3
  XKB_KEY_F23* = 0xffd4
  XKB_KEY_R3* = 0xffd4
  XKB_KEY_F24* = 0xffd5
  XKB_KEY_R4* = 0xffd5
  XKB_KEY_F25* = 0xffd6
  XKB_KEY_R5* = 0xffd6
  XKB_KEY_F26* = 0xffd7
  XKB_KEY_R6* = 0xffd7
  XKB_KEY_F27* = 0xffd8
  XKB_KEY_R7* = 0xffd8
  XKB_KEY_F28* = 0xffd9
  XKB_KEY_R8* = 0xffd9
  XKB_KEY_F29* = 0xffda
  XKB_KEY_R9* = 0xffda
  XKB_KEY_F30* = 0xffdb
  XKB_KEY_R10* = 0xffdb
  XKB_KEY_F31* = 0xffdc
  XKB_KEY_R11* = 0xffdc
  XKB_KEY_F32* = 0xffdd
  XKB_KEY_R12* = 0xffdd
  XKB_KEY_F33* = 0xffde
  XKB_KEY_R13* = 0xffde
  XKB_KEY_F34* = 0xffdf
  XKB_KEY_R14* = 0xffdf
  XKB_KEY_F35* = 0xffe0
  XKB_KEY_R15* = 0xffe0


const
  XKB_KEY_Shift_L* = 0xffe1
  XKB_KEY_Shift_R* = 0xffe2
  XKB_KEY_Control_L* = 0xffe3
  XKB_KEY_Control_R* = 0xffe4
  XKB_KEY_Caps_Lock* = 0xffe5
  XKB_KEY_Shift_Lock* = 0xffe6
  XKB_KEY_Meta_L* = 0xffe7
  XKB_KEY_Meta_R* = 0xffe8
  XKB_KEY_Alt_L* = 0xffe9
  XKB_KEY_Alt_R* = 0xffea
  XKB_KEY_Super_L* = 0xffeb
  XKB_KEY_Super_R* = 0xffec
  XKB_KEY_Hyper_L* = 0xffed
  XKB_KEY_Hyper_R* = 0xffee


const
  XKB_KEY_ISO_Lock* = 0xfe01
  XKB_KEY_ISO_Level2_Latch* = 0xfe02
  XKB_KEY_ISO_Level3_Shift* = 0xfe03
  XKB_KEY_ISO_Level3_Latch* = 0xfe04
  XKB_KEY_ISO_Level3_Lock* = 0xfe05
  XKB_KEY_ISO_Level5_Shift* = 0xfe11
  XKB_KEY_ISO_Level5_Latch* = 0xfe12
  XKB_KEY_ISO_Level5_Lock* = 0xfe13
  XKB_KEY_ISO_Group_Shift* = 0xff7e
  XKB_KEY_ISO_Group_Latch* = 0xfe06
  XKB_KEY_ISO_Group_Lock* = 0xfe07
  XKB_KEY_ISO_Next_Group* = 0xfe08
  XKB_KEY_ISO_Next_Group_Lock* = 0xfe09
  XKB_KEY_ISO_Prev_Group* = 0xfe0a
  XKB_KEY_ISO_Prev_Group_Lock* = 0xfe0b
  XKB_KEY_ISO_First_Group* = 0xfe0c
  XKB_KEY_ISO_First_Group_Lock* = 0xfe0d
  XKB_KEY_ISO_Last_Group* = 0xfe0e
  XKB_KEY_ISO_Last_Group_Lock* = 0xfe0f
  XKB_KEY_ISO_Left_Tab* = 0xfe20
  XKB_KEY_ISO_Move_Line_Up* = 0xfe21
  XKB_KEY_ISO_Move_Line_Down* = 0xfe22
  XKB_KEY_ISO_Partial_Line_Up* = 0xfe23
  XKB_KEY_ISO_Partial_Line_Down* = 0xfe24
  XKB_KEY_ISO_Partial_Space_Left* = 0xfe25
  XKB_KEY_ISO_Partial_Space_Right* = 0xfe26
  XKB_KEY_ISO_Set_Margin_Left* = 0xfe27
  XKB_KEY_ISO_Set_Margin_Right* = 0xfe28
  XKB_KEY_ISO_Release_Margin_Left* = 0xfe29
  XKB_KEY_ISO_Release_Margin_Right* = 0xfe2a
  XKB_KEY_ISO_Release_Both_Margins* = 0xfe2b
  XKB_KEY_ISO_Fast_Cursor_Left* = 0xfe2c
  XKB_KEY_ISO_Fast_Cursor_Right* = 0xfe2d
  XKB_KEY_ISO_Fast_Cursor_Up* = 0xfe2e
  XKB_KEY_ISO_Fast_Cursor_Down* = 0xfe2f
  XKB_KEY_ISO_Continuous_Underline* = 0xfe30
  XKB_KEY_ISO_Discontinuous_Underline* = 0xfe31
  XKB_KEY_ISO_Emphasize* = 0xfe32
  XKB_KEY_ISO_Center_Object* = 0xfe33
  XKB_KEY_ISO_Enter* = 0xfe34
  XKB_KEY_dead_grave* = 0xfe50
  XKB_KEY_dead_acute* = 0xfe51
  XKB_KEY_dead_circumflex* = 0xfe52
  XKB_KEY_dead_tilde* = 0xfe53
  XKB_KEY_dead_perispomeni* = 0xfe53
  XKB_KEY_dead_macron* = 0xfe54
  XKB_KEY_dead_breve* = 0xfe55
  XKB_KEY_dead_abovedot* = 0xfe56
  XKB_KEY_dead_diaeresis* = 0xfe57
  XKB_KEY_dead_abovering* = 0xfe58
  XKB_KEY_dead_doubleacute* = 0xfe59
  XKB_KEY_dead_caron* = 0xfe5a
  XKB_KEY_dead_cedilla* = 0xfe5b
  XKB_KEY_dead_ogonek* = 0xfe5c
  XKB_KEY_dead_iota* = 0xfe5d
  XKB_KEY_dead_voiced_sound* = 0xfe5e
  XKB_KEY_dead_semivoiced_sound* = 0xfe5f
  XKB_KEY_dead_belowdot* = 0xfe60
  XKB_KEY_dead_hook* = 0xfe61
  XKB_KEY_dead_horn* = 0xfe62
  XKB_KEY_dead_stroke* = 0xfe63
  XKB_KEY_dead_abovecomma* = 0xfe64
  XKB_KEY_dead_psili* = 0xfe64
  XKB_KEY_dead_abovereversedcomma* = 0xfe65
  XKB_KEY_dead_dasia* = 0xfe65
  XKB_KEY_dead_doublegrave* = 0xfe66
  XKB_KEY_dead_belowring* = 0xfe67
  XKB_KEY_dead_belowmacron* = 0xfe68
  XKB_KEY_dead_belowcircumflex* = 0xfe69
  XKB_KEY_dead_belowtilde* = 0xfe6a
  XKB_KEY_dead_belowbreve* = 0xfe6b
  XKB_KEY_dead_belowdiaeresis* = 0xfe6c
  XKB_KEY_dead_invertedbreve* = 0xfe6d
  XKB_KEY_dead_belowcomma* = 0xfe6e
  XKB_KEY_dead_currency* = 0xfe6f


const
  XKB_KEY_dead_a* = 0xfe80
  XKB_KEY_dead_A_upper* = 0xfe81
  XKB_KEY_dead_e* = 0xfe82
  XKB_KEY_dead_E_upper* = 0xfe83
  XKB_KEY_dead_i* = 0xfe84
  XKB_KEY_dead_I_upper* = 0xfe85
  XKB_KEY_dead_o* = 0xfe86
  XKB_KEY_dead_O_upper* = 0xfe87
  XKB_KEY_dead_u* = 0xfe88
  XKB_KEY_dead_U_upper* = 0xfe89
  XKB_KEY_dead_schwa* = 0xfe8a
  XKB_KEY_dead_SCHWA_upper* = 0xfe8b
  XKB_KEY_dead_small_schwa* = 0xfe8a
  XKB_KEY_dead_capital_schwa* = 0xfe8b
  XKB_KEY_dead_greek* = 0xfe8c
  XKB_KEY_dead_hamza* = 0xfe8d
  XKB_KEY_First_Virtual_Screen* = 0xfed0
  XKB_KEY_Prev_Virtual_Screen* = 0xfed1
  XKB_KEY_Next_Virtual_Screen* = 0xfed2
  XKB_KEY_Last_Virtual_Screen* = 0xfed4
  XKB_KEY_Terminate_Server* = 0xfed5
  XKB_KEY_AccessX_Enable* = 0xfe70
  XKB_KEY_AccessX_Feedback_Enable* = 0xfe71
  XKB_KEY_RepeatKeys_Enable* = 0xfe72
  XKB_KEY_SlowKeys_Enable* = 0xfe73
  XKB_KEY_BounceKeys_Enable* = 0xfe74
  XKB_KEY_StickyKeys_Enable* = 0xfe75
  XKB_KEY_MouseKeys_Enable* = 0xfe76
  XKB_KEY_MouseKeys_Accel_Enable* = 0xfe77
  XKB_KEY_Overlay1_Enable* = 0xfe78
  XKB_KEY_Overlay2_Enable* = 0xfe79
  XKB_KEY_AudibleBell_Enable* = 0xfe7a
  XKB_KEY_Pointer_Left* = 0xfee0
  XKB_KEY_Pointer_Right* = 0xfee1
  XKB_KEY_Pointer_Up* = 0xfee2
  XKB_KEY_Pointer_Down* = 0xfee3
  XKB_KEY_Pointer_UpLeft* = 0xfee4
  XKB_KEY_Pointer_UpRight* = 0xfee5
  XKB_KEY_Pointer_DownLeft* = 0xfee6
  XKB_KEY_Pointer_DownRight* = 0xfee7
  XKB_KEY_Pointer_Button_Dflt* = 0xfee8
  XKB_KEY_Pointer_Button1* = 0xfee9
  XKB_KEY_Pointer_Button2* = 0xfeea
  XKB_KEY_Pointer_Button3* = 0xfeeb
  XKB_KEY_Pointer_Button4* = 0xfeec
  XKB_KEY_Pointer_Button5* = 0xfeed
  XKB_KEY_Pointer_DblClick_Dflt* = 0xfeee
  XKB_KEY_Pointer_DblClick1* = 0xfeef
  XKB_KEY_Pointer_DblClick2* = 0xfef0
  XKB_KEY_Pointer_DblClick3* = 0xfef1
  XKB_KEY_Pointer_DblClick4* = 0xfef2
  XKB_KEY_Pointer_DblClick5* = 0xfef3
  XKB_KEY_Pointer_Drag_Dflt* = 0xfef4
  XKB_KEY_Pointer_Drag1* = 0xfef5
  XKB_KEY_Pointer_Drag2* = 0xfef6
  XKB_KEY_Pointer_Drag3* = 0xfef7
  XKB_KEY_Pointer_Drag4* = 0xfef8
  XKB_KEY_Pointer_Drag5* = 0xfefd
  XKB_KEY_Pointer_EnableKeys* = 0xfef9
  XKB_KEY_Pointer_Accelerate* = 0xfefa
  XKB_KEY_Pointer_DfltBtnNext* = 0xfefb
  XKB_KEY_Pointer_DfltBtnPrev* = 0xfefc


const
  XKB_KEY_3270_Duplicate* = 0xfd01
  XKB_KEY_3270_FieldMark* = 0xfd02
  XKB_KEY_3270_Right2* = 0xfd03
  XKB_KEY_3270_Left2* = 0xfd04
  XKB_KEY_3270_BackTab* = 0xfd05
  XKB_KEY_3270_EraseEOF* = 0xfd06
  XKB_KEY_3270_EraseInput* = 0xfd07
  XKB_KEY_3270_Reset* = 0xfd08
  XKB_KEY_3270_Quit* = 0xfd09
  XKB_KEY_3270_PA1* = 0xfd0a
  XKB_KEY_3270_PA2* = 0xfd0b
  XKB_KEY_3270_PA3* = 0xfd0c
  XKB_KEY_3270_Test* = 0xfd0d
  XKB_KEY_3270_Attn* = 0xfd0e
  XKB_KEY_3270_CursorBlink* = 0xfd0f
  XKB_KEY_3270_AltCursor* = 0xfd10
  XKB_KEY_3270_KeyClick* = 0xfd11
  XKB_KEY_3270_Jump* = 0xfd12
  XKB_KEY_3270_Ident* = 0xfd13
  XKB_KEY_3270_Rule* = 0xfd14
  XKB_KEY_3270_Copy* = 0xfd15
  XKB_KEY_3270_Play* = 0xfd16
  XKB_KEY_3270_Setup* = 0xfd17
  XKB_KEY_3270_Record* = 0xfd18
  XKB_KEY_3270_ChangeScreen* = 0xfd19
  XKB_KEY_3270_DeleteWord* = 0xfd1a
  XKB_KEY_3270_ExSelect* = 0xfd1b
  XKB_KEY_3270_CursorSelect* = 0xfd1c
  XKB_KEY_3270_PrintScreen* = 0xfd1d
  XKB_KEY_3270_Enter* = 0xfd1e


const
  XKB_KEY_space* = 0x0020
  XKB_KEY_exclam* = 0x0021
  XKB_KEY_quotedbl* = 0x0022
  XKB_KEY_numbersign* = 0x0023
  XKB_KEY_dollar* = 0x0024
  XKB_KEY_percent* = 0x0025
  XKB_KEY_ampersand* = 0x0026
  XKB_KEY_apostrophe* = 0x0027
  XKB_KEY_quoteright* = 0x0027
  XKB_KEY_parenleft* = 0x0028
  XKB_KEY_parenright* = 0x0029
  XKB_KEY_asterisk* = 0x002a
  XKB_KEY_plus* = 0x002b
  XKB_KEY_comma* = 0x002c
  XKB_KEY_minus* = 0x002d
  XKB_KEY_period* = 0x002e
  XKB_KEY_slash* = 0x002f
  XKB_KEY_0* = 0x0030
  XKB_KEY_1* = 0x0031
  XKB_KEY_2* = 0x0032
  XKB_KEY_3* = 0x0033
  XKB_KEY_4* = 0x0034
  XKB_KEY_5* = 0x0035
  XKB_KEY_6* = 0x0036
  XKB_KEY_7* = 0x0037
  XKB_KEY_8* = 0x0038
  XKB_KEY_9* = 0x0039
  XKB_KEY_colon* = 0x003a
  XKB_KEY_semicolon* = 0x003b
  XKB_KEY_less* = 0x003c
  XKB_KEY_equal* = 0x003d
  XKB_KEY_greater* = 0x003e
  XKB_KEY_question* = 0x003f
  XKB_KEY_at* = 0x0040
  XKB_KEY_A_upper* = 0x0041
  XKB_KEY_B_upper* = 0x0042
  XKB_KEY_C_upper* = 0x0043
  XKB_KEY_D_upper* = 0x0044
  XKB_KEY_E_upper* = 0x0045
  XKB_KEY_F_upper* = 0x0046
  XKB_KEY_G_upper* = 0x0047
  XKB_KEY_H_upper* = 0x0048
  XKB_KEY_I_upper* = 0x0049
  XKB_KEY_J_upper* = 0x004a
  XKB_KEY_K_upper* = 0x004b
  XKB_KEY_L_upper* = 0x004c
  XKB_KEY_M_upper* = 0x004d
  XKB_KEY_N_upper* = 0x004e
  XKB_KEY_O_upper* = 0x004f
  XKB_KEY_P_upper* = 0x0050
  XKB_KEY_Q_upper* = 0x0051
  XKB_KEY_R_upper* = 0x0052
  XKB_KEY_S_upper* = 0x0053
  XKB_KEY_T_upper* = 0x0054
  XKB_KEY_U_upper* = 0x0055
  XKB_KEY_V_upper* = 0x0056
  XKB_KEY_W_upper* = 0x0057
  XKB_KEY_X_upper* = 0x0058
  XKB_KEY_Y_upper* = 0x0059
  XKB_KEY_Z_upper* = 0x005a
  XKB_KEY_bracketleft* = 0x005b
  XKB_KEY_backslash* = 0x005c
  XKB_KEY_bracketright* = 0x005d
  XKB_KEY_asciicircum* = 0x005e
  XKB_KEY_underscore* = 0x005f
  XKB_KEY_grave* = 0x0060
  XKB_KEY_quoteleft* = 0x0060
  XKB_KEY_a* = 0x0061
  XKB_KEY_b* = 0x0062
  XKB_KEY_c* = 0x0063
  XKB_KEY_d* = 0x0064
  XKB_KEY_e* = 0x0065
  XKB_KEY_f* = 0x0066
  XKB_KEY_g* = 0x0067
  XKB_KEY_h* = 0x0068
  XKB_KEY_i* = 0x0069
  XKB_KEY_j* = 0x006a
  XKB_KEY_k* = 0x006b
  XKB_KEY_l* = 0x006c
  XKB_KEY_m* = 0x006d
  XKB_KEY_n* = 0x006e
  XKB_KEY_o* = 0x006f
  XKB_KEY_p* = 0x0070
  XKB_KEY_q* = 0x0071
  XKB_KEY_r* = 0x0072
  XKB_KEY_s* = 0x0073
  XKB_KEY_t* = 0x0074
  XKB_KEY_u* = 0x0075
  XKB_KEY_v* = 0x0076
  XKB_KEY_w* = 0x0077
  XKB_KEY_x* = 0x0078
  XKB_KEY_y* = 0x0079
  XKB_KEY_z* = 0x007a
  XKB_KEY_braceleft* = 0x007b
  XKB_KEY_bar* = 0x007c
  XKB_KEY_braceright* = 0x007d
  XKB_KEY_asciitilde* = 0x007e
  XKB_KEY_nobreakspace* = 0x00a0
  XKB_KEY_exclamdown* = 0x00a1
  XKB_KEY_cent* = 0x00a2
  XKB_KEY_sterling* = 0x00a3
  XKB_KEY_currency* = 0x00a4
  XKB_KEY_yen* = 0x00a5
  XKB_KEY_brokenbar* = 0x00a6
  XKB_KEY_section* = 0x00a7
  XKB_KEY_diaeresis* = 0x00a8
  XKB_KEY_copyright* = 0x00a9
  XKB_KEY_ordfeminine* = 0x00aa
  XKB_KEY_guillemetleft* = 0x00ab
  XKB_KEY_guillemotleft* = 0x00ab
  XKB_KEY_notsign* = 0x00ac
  XKB_KEY_hyphen* = 0x00ad
  XKB_KEY_registered* = 0x00ae
  XKB_KEY_macron* = 0x00af
  XKB_KEY_degree* = 0x00b0
  XKB_KEY_plusminus* = 0x00b1
  XKB_KEY_twosuperior* = 0x00b2
  XKB_KEY_threesuperior* = 0x00b3
  XKB_KEY_acute* = 0x00b4
  XKB_KEY_mu* = 0x00b5
  XKB_KEY_paragraph* = 0x00b6
  XKB_KEY_periodcentered* = 0x00b7
  XKB_KEY_cedilla* = 0x00b8
  XKB_KEY_onesuperior* = 0x00b9
  XKB_KEY_ordmasculine* = 0x00ba
  XKB_KEY_masculine* = 0x00ba
  XKB_KEY_guillemetright* = 0x00bb
  XKB_KEY_guillemotright* = 0x00bb
  XKB_KEY_onequarter* = 0x00bc
  XKB_KEY_onehalf* = 0x00bd
  XKB_KEY_threequarters* = 0x00be
  XKB_KEY_questiondown* = 0x00bf
  XKB_KEY_Agrave* = 0x00c0
  XKB_KEY_Aacute* = 0x00c1
  XKB_KEY_Acircumflex* = 0x00c2
  XKB_KEY_Atilde* = 0x00c3
  XKB_KEY_Adiaeresis* = 0x00c4
  XKB_KEY_Aring* = 0x00c5
  XKB_KEY_AE* = 0x00c6
  XKB_KEY_Ccedilla* = 0x00c7
  XKB_KEY_Egrave* = 0x00c8
  XKB_KEY_Eacute* = 0x00c9
  XKB_KEY_Ecircumflex* = 0x00ca
  XKB_KEY_Ediaeresis* = 0x00cb
  XKB_KEY_Igrave* = 0x00cc
  XKB_KEY_Iacute* = 0x00cd
  XKB_KEY_Icircumflex* = 0x00ce
  XKB_KEY_Idiaeresis* = 0x00cf
  XKB_KEY_ETH_upper* = 0x00d0
  XKB_KEY_Eth* = 0x00d0
  XKB_KEY_Ntilde* = 0x00d1
  XKB_KEY_Ograve* = 0x00d2
  XKB_KEY_Oacute* = 0x00d3
  XKB_KEY_Ocircumflex* = 0x00d4
  XKB_KEY_Otilde* = 0x00d5
  XKB_KEY_Odiaeresis* = 0x00d6
  XKB_KEY_multiply* = 0x00d7
  XKB_KEY_Oslash* = 0x00d8
  XKB_KEY_Ooblique* = 0x00d8
  XKB_KEY_Ugrave* = 0x00d9
  XKB_KEY_Uacute* = 0x00da
  XKB_KEY_Ucircumflex* = 0x00db
  XKB_KEY_Udiaeresis* = 0x00dc
  XKB_KEY_Yacute* = 0x00dd
  XKB_KEY_THORN_upper* = 0x00de
  XKB_KEY_Thorn* = 0x00de
  XKB_KEY_ssharp* = 0x00df
  XKB_KEY_agrave_lower* = 0x00e0
  XKB_KEY_aacute_lower* = 0x00e1
  XKB_KEY_acircumflex_lower* = 0x00e2
  XKB_KEY_atilde_lower* = 0x00e3
  XKB_KEY_adiaeresis_lower* = 0x00e4
  XKB_KEY_aring_lower* = 0x00e5
  XKB_KEY_ae_lower* = 0x00e6
  XKB_KEY_ccedilla_lower* = 0x00e7
  XKB_KEY_egrave_lower* = 0x00e8
  XKB_KEY_eacute_lower* = 0x00e9
  XKB_KEY_ecircumflex_lower* = 0x00ea
  XKB_KEY_ediaeresis_lower* = 0x00eb
  XKB_KEY_igrave_lower* = 0x00ec
  XKB_KEY_iacute_lower* = 0x00ed
  XKB_KEY_icircumflex_lower* = 0x00ee
  XKB_KEY_idiaeresis_lower* = 0x00ef
  XKB_KEY_eth_lower* = 0x00f0
  XKB_KEY_ntilde_lower* = 0x00f1
  XKB_KEY_ograve_lower* = 0x00f2
  XKB_KEY_oacute_lower* = 0x00f3
  XKB_KEY_ocircumflex_lower* = 0x00f4
  XKB_KEY_otilde_lower* = 0x00f5
  XKB_KEY_odiaeresis_lower* = 0x00f6
  XKB_KEY_division* = 0x00f7
  XKB_KEY_oslash_lower* = 0x00f8
  XKB_KEY_ooblique_lower* = 0x00f8
  XKB_KEY_ugrave_lower* = 0x00f9
  XKB_KEY_uacute_lower* = 0x00fa
  XKB_KEY_ucircumflex_lower* = 0x00fb
  XKB_KEY_udiaeresis_lower* = 0x00fc
  XKB_KEY_yacute_lower* = 0x00fd
  XKB_KEY_thorn_lower* = 0x00fe
  XKB_KEY_ydiaeresis* = 0x00ff




template xkb_keycode_is_legal_ext*(key: untyped): untyped =
  (key <= XKB_KEYCODE_MAX)


template xkb_keycode_is_legal_x11*(key: untyped): untyped =
  (key >= 8 and key <= 255)


{.push, importc, dynlib: "libxkbcommon.so(|.0)".}

proc xkb_keysym_get_name*(keysym: xkb_keysym_t; buffer: cstring; size: csize_t): cint


proc xkb_keysym_from_name*(name: cstring; flags: xkb_keysym_flags): xkb_keysym_t

proc xkb_keysym_to_utf8*(keysym: xkb_keysym_t; buffer: cstring; size: csize_t): cint

proc xkb_keysym_to_utf32*(keysym: xkb_keysym_t): uint32

proc xkb_utf32_to_keysym*(ucs: uint32): xkb_keysym_t

proc xkb_keysym_to_upper*(ks: xkb_keysym_t): xkb_keysym_t

proc xkb_keysym_to_lower*(ks: xkb_keysym_t): xkb_keysym_t


proc xkb_context_new*(flags: xkb_context_flags): ptr xkb_context


proc xkb_context_ref*(context: ptr xkb_context): ptr xkb_context


proc xkb_context_unref*(context: ptr xkb_context)

proc xkb_context_set_user_data*(context: ptr xkb_context; user_data: pointer)


proc xkb_context_get_user_data*(context: ptr xkb_context): pointer


proc xkb_context_include_path_append*(context: ptr xkb_context; path: cstring): cint


proc xkb_context_include_path_append_default*(context: ptr xkb_context): cint

proc xkb_context_include_path_reset_defaults*(context: ptr xkb_context): cint


proc xkb_context_include_path_clear*(context: ptr xkb_context)


proc xkb_context_num_include_paths*(context: ptr xkb_context): cuint

proc xkb_context_include_path_get*(context: ptr xkb_context; index: cuint): cstring


proc xkb_context_set_log_level*(context: ptr xkb_context; level: xkb_log_level)


proc xkb_context_get_log_level*(context: ptr xkb_context): xkb_log_level


proc xkb_context_set_log_verbosity*(context: ptr xkb_context; verbosity: cint)


proc xkb_context_get_log_verbosity*(context: ptr xkb_context): cint

proc xkb_context_set_log_fn*(context: ptr xkb_context; log_fn: proc (
    context: ptr xkb_context; level: xkb_log_level; format: cstring;) {.varargs.})

proc xkb_keymap_new_from_names*(context: ptr xkb_context; names: ptr xkb_rule_names;
                               flags: xkb_keymap_compile_flags): ptr xkb_keymap

proc xkb_keymap_new_from_file*(context: ptr xkb_context; file: ptr FILE;
                              format: xkb_keymap_format;
                              flags: xkb_keymap_compile_flags): ptr xkb_keymap


proc xkb_keymap_new_from_string*(context: ptr xkb_context; string: cstring;
                                format: xkb_keymap_format;
                                flags: xkb_keymap_compile_flags): ptr xkb_keymap

proc xkb_keymap_new_from_buffer*(context: ptr xkb_context; buffer: cstring;
                                length: csize_t; format: xkb_keymap_format;
                                flags: xkb_keymap_compile_flags): ptr xkb_keymap


proc xkb_keymap_ref*(keymap: ptr xkb_keymap): ptr xkb_keymap


proc xkb_keymap_unref*(keymap: ptr xkb_keymap)


proc xkb_keymap_get_as_string*(keymap: ptr xkb_keymap; format: xkb_keymap_format): cstring

proc xkb_keymap_min_keycode*(keymap: ptr xkb_keymap): xkb_keycode_t


proc xkb_keymap_max_keycode*(keymap: ptr xkb_keymap): xkb_keycode_t

proc xkb_keymap_key_for_each*(keymap: ptr xkb_keymap; iter: xkb_keymap_key_iter_t;
                             data: pointer)


proc xkb_keymap_key_get_name*(keymap: ptr xkb_keymap; key: xkb_keycode_t): cstring

proc xkb_keymap_key_by_name*(keymap: ptr xkb_keymap; name: cstring): xkb_keycode_t

proc xkb_keymap_num_mods*(keymap: ptr xkb_keymap): xkb_mod_index_t

proc xkb_keymap_mod_get_name*(keymap: ptr xkb_keymap; idx: xkb_mod_index_t): cstring


proc xkb_keymap_mod_get_index*(keymap: ptr xkb_keymap; name: cstring): xkb_mod_index_t

proc xkb_keymap_num_layouts*(keymap: ptr xkb_keymap): xkb_layout_index_t

proc xkb_keymap_layout_get_name*(keymap: ptr xkb_keymap; idx: xkb_layout_index_t): cstring


proc xkb_keymap_layout_get_index*(keymap: ptr xkb_keymap; name: cstring): xkb_layout_index_t


proc xkb_keymap_num_leds*(keymap: ptr xkb_keymap): xkb_led_index_t


proc xkb_keymap_led_get_name*(keymap: ptr xkb_keymap; idx: xkb_led_index_t): cstring

proc xkb_keymap_led_get_index*(keymap: ptr xkb_keymap; name: cstring): xkb_led_index_t

proc xkb_keymap_num_layouts_for_key*(keymap: ptr xkb_keymap; key: xkb_keycode_t): xkb_layout_index_t

proc xkb_keymap_num_levels_for_key*(keymap: ptr xkb_keymap; key: xkb_keycode_t;
                                   layout: xkb_layout_index_t): xkb_level_index_t

proc xkb_keymap_key_get_mods_for_level*(keymap: ptr xkb_keymap; key: xkb_keycode_t;
                                       layout: xkb_layout_index_t;
                                       level: xkb_level_index_t;
                                       masks_out: ptr xkb_mod_mask_t;
                                       masks_size: csize_t): csize_t

proc xkb_keymap_key_get_syms_by_level*(keymap: ptr xkb_keymap; key: xkb_keycode_t;
                                      layout: xkb_layout_index_t;
                                      level: xkb_level_index_t;
                                      syms_out: ptr ptr xkb_keysym_t): cint


proc xkb_keymap_key_repeats*(keymap: ptr xkb_keymap; key: xkb_keycode_t): cint

proc xkb_state_new*(keymap: ptr xkb_keymap): ptr xkb_state


proc xkb_state_ref*(state: ptr xkb_state): ptr xkb_state


proc xkb_state_unref*(state: ptr xkb_state)

proc xkb_state_get_keymap*(state: ptr xkb_state): ptr xkb_keymap

proc xkb_state_update_key*(state: ptr xkb_state; key: xkb_keycode_t;
                          direction: xkb_key_direction): xkb_state_component

proc xkb_state_update_mask*(state: ptr xkb_state; depressed_mods: xkb_mod_mask_t;
                           latched_mods: xkb_mod_mask_t;
                           locked_mods: xkb_mod_mask_t;
                           depressed_layout: xkb_layout_index_t;
                           latched_layout: xkb_layout_index_t;
                           locked_layout: xkb_layout_index_t): xkb_state_component

proc xkb_state_key_get_syms*(state: ptr xkb_state; key: xkb_keycode_t;
                            syms_out: ptr ptr xkb_keysym_t): cint

proc xkb_state_key_get_utf8*(state: ptr xkb_state; key: xkb_keycode_t;
                            buffer: cstring; size: csize_t): cint


proc xkb_state_key_get_utf32*(state: ptr xkb_state; key: xkb_keycode_t): uint32


proc xkb_state_key_get_one_sym*(state: ptr xkb_state; key: xkb_keycode_t): xkb_keysym_t

proc xkb_state_key_get_layout*(state: ptr xkb_state; key: xkb_keycode_t): xkb_layout_index_t

proc xkb_state_key_get_level*(state: ptr xkb_state; key: xkb_keycode_t;
                             layout: xkb_layout_index_t): xkb_level_index_t


proc xkb_state_serialize_mods*(state: ptr xkb_state; components: xkb_state_component): xkb_mod_mask_t


proc xkb_state_serialize_layout*(state: ptr xkb_state;
                                components: xkb_state_component): xkb_layout_index_t

proc xkb_state_mod_name_is_active*(state: ptr xkb_state; name: cstring;
                                  `type`: xkb_state_component): cint


proc xkb_state_mod_names_are_active*(state: ptr xkb_state;
                                    `type`: xkb_state_component;
                                    match: xkb_state_match): cint {.varargs.}

proc xkb_state_mod_index_is_active*(state: ptr xkb_state; idx: xkb_mod_index_t;
                                   `type`: xkb_state_component): cint


proc xkb_state_mod_indices_are_active*(state: ptr xkb_state;
                                      `type`: xkb_state_component;
                                      match: xkb_state_match): cint {.varargs.}

proc xkb_state_key_get_consumed_mods2*(state: ptr xkb_state; key: xkb_keycode_t;
                                      mode: xkb_consumed_mode): xkb_mod_mask_t

proc xkb_state_key_get_consumed_mods*(state: ptr xkb_state; key: xkb_keycode_t): xkb_mod_mask_t


proc xkb_state_mod_index_is_consumed2*(state: ptr xkb_state; key: xkb_keycode_t;
                                      idx: xkb_mod_index_t;
                                      mode: xkb_consumed_mode): cint

proc xkb_state_mod_index_is_consumed*(state: ptr xkb_state; key: xkb_keycode_t;
                                     idx: xkb_mod_index_t): cint


proc xkb_state_mod_mask_remove_consumed*(state: ptr xkb_state; key: xkb_keycode_t;
                                        mask: xkb_mod_mask_t): xkb_mod_mask_t

proc xkb_state_layout_name_is_active*(state: ptr xkb_state; name: cstring;
                                     `type`: xkb_state_component): cint


proc xkb_state_layout_index_is_active*(state: ptr xkb_state;
                                      idx: xkb_layout_index_t;
                                      `type`: xkb_state_component): cint


proc xkb_state_led_name_is_active*(state: ptr xkb_state; name: cstring): cint


proc xkb_state_led_index_is_active*(state: ptr xkb_state; idx: xkb_led_index_t): cint

{.pop.}


var
  initialized = false

  global_xkb_context*: ptr xkb_context
  global_xkb_keymap*: ptr xkb_keymap
  global_xkb_state_unmodified*: ptr xkb_state
  global_xkb_state*: ptr xkb_state


proc initXkb* =
  if initialized: return
  initialized = true
  
  global_xkb_context = xkb_context_new(XKB_CONTEXT_NO_FLAGS)


proc updateKeymap*(fd: sink FileHandle, size: uint32) =
  initXkb()

  if global_xkb_state_unmodified != nil:
    xkb_state_unref(global_xkb_state_unmodified)
  if global_xkb_state != nil:
    xkb_state_unref(global_xkb_state)
  if global_xkb_keymap != nil:
    xkb_keymap_unref(global_xkb_keymap)

  let file_shm = mmap(nil, size.cint, PROT_READ, MAP_PRIVATE, fd.cint, 0)
  if file_shm == MAP_FAILED:
    raise OsError.newException("mmap failed")

  global_xkb_keymap = xkb_keymap_new_from_string(
    global_xkb_context, cast[cstring](file_shm), XKB_KEYMAP_FORMAT_TEXT_V1,
    XKB_KEYMAP_COMPILE_NO_FLAGS
  )
  discard munmap(file_shm, size.cint)
  discard close fd

  global_xkb_state_unmodified = xkb_state_new(global_xkb_keymap)
  global_xkb_state = xkb_state_new(global_xkb_keymap)
