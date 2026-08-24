--!native
--!optimize 2
local doomkeys = {}

doomkeys.KEY_RIGHTARROW = 0xae
doomkeys.KEY_LEFTARROW = 0xac
doomkeys.KEY_UPARROW = 0xad
doomkeys.KEY_DOWNARROW = 0xaf
doomkeys.KEY_STRAFE_L = 0xa0
doomkeys.KEY_STRAFE_R = 0xa1
doomkeys.KEY_USE = 0xa2
doomkeys.KEY_FIRE = 0xa3
doomkeys.KEY_ESCAPE = 27
doomkeys.KEY_ENTER = 13
doomkeys.KEY_TAB = 9

doomkeys.KEY_F1 = 0x80 + 0x3b
doomkeys.KEY_F2 = 0x80 + 0x3c
doomkeys.KEY_F3 = 0x80 + 0x3d
doomkeys.KEY_F4 = 0x80 + 0x3e
doomkeys.KEY_F5 = 0x80 + 0x3f
doomkeys.KEY_F6 = 0x80 + 0x40
doomkeys.KEY_F7 = 0x80 + 0x41
doomkeys.KEY_F8 = 0x80 + 0x42
doomkeys.KEY_F9 = 0x80 + 0x43
doomkeys.KEY_F10 = 0x80 + 0x44
doomkeys.KEY_F11 = 0x80 + 0x57
doomkeys.KEY_F12 = 0x80 + 0x58

doomkeys.KEY_BACKSPACE = 0x7f
doomkeys.KEY_PAUSE = 0xff

doomkeys.KEY_EQUALS = 0x3d
doomkeys.KEY_MINUS = 0x2d

doomkeys.KEY_RSHIFT = 0x80 + 0x36
doomkeys.KEY_RCTRL = 0x80 + 0x1d
doomkeys.KEY_RALT = 0x80 + 0x38
doomkeys.KEY_LALT = doomkeys.KEY_RALT

-- new keys:
doomkeys.KEY_CAPSLOCK = 0x80 + 0x3a
doomkeys.KEY_NUMLOCK = 0x80 + 0x45
doomkeys.KEY_SCRLCK = 0x80 + 0x46
doomkeys.KEY_PRTSCR = 0x80 + 0x59

doomkeys.KEY_HOME = 0x80 + 0x47
doomkeys.KEY_END = 0x80 + 0x4f
doomkeys.KEY_PGUP = 0x80 + 0x49
doomkeys.KEY_PGDN = 0x80 + 0x51
doomkeys.KEY_INS = 0x80 + 0x52
doomkeys.KEY_DEL = 0x80 + 0x53

doomkeys.KEYP_0 = 0
doomkeys.KEYP_1 = doomkeys.KEY_END
doomkeys.KEYP_2 = doomkeys.KEY_DOWNARROW
doomkeys.KEYP_3 = doomkeys.KEY_PGDN
doomkeys.KEYP_4 = doomkeys.KEY_LEFTARROW
doomkeys.KEYP_5 = 0x35 -- '5'
doomkeys.KEYP_6 = doomkeys.KEY_RIGHTARROW
doomkeys.KEYP_7 = doomkeys.KEY_HOME
doomkeys.KEYP_8 = doomkeys.KEY_UPARROW
doomkeys.KEYP_9 = doomkeys.KEY_PGUP

doomkeys.KEYP_DIVIDE = 0x2f -- '/'
doomkeys.KEYP_PLUS = 0x2b -- '+'
doomkeys.KEYP_MINUS = 0x2d -- '-'
doomkeys.KEYP_MULTIPLY = 0x2a -- '*'
doomkeys.KEYP_PERIOD = 0
doomkeys.KEYP_EQUALS = doomkeys.KEY_EQUALS
doomkeys.KEYP_ENTER = doomkeys.KEY_ENTER

return doomkeys