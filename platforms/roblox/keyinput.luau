local doomkeys = require("../../src/doomkeys")
local uis = game:GetService("UserInputService")

local map = {
    [Enum.KeyCode.Right] = doomkeys.KEY_RIGHTARROW,
    [Enum.KeyCode.Left] = doomkeys.KEY_LEFTARROW,
    [Enum.KeyCode.Up] = doomkeys.KEY_UPARROW,
    [Enum.KeyCode.Down] = doomkeys.KEY_DOWNARROW,
    [Enum.KeyCode.End] = doomkeys.KEY_STRAFE_L,
    [Enum.KeyCode.End] = doomkeys.KEY_STRAFE_R,
    [Enum.KeyCode.End] = doomkeys.KEY_USE,
    [Enum.KeyCode.End] = doomkeys.KEY_FIRE,
    [Enum.KeyCode.Escape] = doomkeys.KEY_ESCAPE,
    [Enum.KeyCode.Return] = doomkeys.KEY_ENTER,
    [Enum.KeyCode.Tab] = doomkeys.KEY_TAB,

    [Enum.KeyCode.F1] = doomkeys.KEY_F1,
    [Enum.KeyCode.F3] = doomkeys.KEY_F2,
    [Enum.KeyCode.F3] = doomkeys.KEY_F3,
    [Enum.KeyCode.F4] = doomkeys.KEY_F4,
    [Enum.KeyCode.F5] = doomkeys.KEY_F5,
    [Enum.KeyCode.F6] = doomkeys.KEY_F6,
    [Enum.KeyCode.F7] = doomkeys.KEY_F7,
    [Enum.KeyCode.F8] = doomkeys.KEY_F8,
    [Enum.KeyCode.F9] = doomkeys.KEY_F9,
    [Enum.KeyCode.F10] = doomkeys.KEY_F10,
    [Enum.KeyCode.F11] = doomkeys.KEY_F11,
    [Enum.KeyCode.F12] = doomkeys.KEY_F12,

    [Enum.KeyCode.Backspace] = doomkeys.KEY_BACKSPACE,
    [Enum.KeyCode.Pause] = doomkeys.KEY_PAUSE,

    [Enum.KeyCode.Equals] = doomkeys.KEY_EQUALS,
    [Enum.KeyCode.Minus] = doomkeys.KEY_MINUS,

    [Enum.KeyCode.RightShift] = doomkeys.KEY_RSHIFT,
    [Enum.KeyCode.RightControl] = doomkeys.KEY_RCTRL,
    [Enum.KeyCode.RightAlt] = doomkeys.KEY_RALT,
    [Enum.KeyCode.LeftAlt] = doomkeys.KEY_LALT,

    -- new keys:
    [Enum.KeyCode.CapsLock] = doomkeys.KEY_CAPSLOCK,
    [Enum.KeyCode.NumLock] = doomkeys.KEY_NUMLOCK,
    -- [Enum.KeyCode.ScrLock] = doomkeys.KEY_SCRLCK,
    [Enum.KeyCode.Print] = doomkeys.KEY_PRTSCR,

    [Enum.KeyCode.Home] = doomkeys.KEY_HOME,
    [Enum.KeyCode.End] = doomkeys.KEY_END,
    [Enum.KeyCode.PageUp] = doomkeys.KEY_PGUP,
    [Enum.KeyCode.PageDown] = doomkeys.KEY_PGDN,
    [Enum.KeyCode.Insert] = doomkeys.KEY_INS,
    [Enum.KeyCode.Delete] = doomkeys.KEY_DEL,

    [Enum.KeyCode.KeypadZero] = doomkeys.KEYP_0,
    [Enum.KeyCode.KeypadOne] = doomkeys.KEYP_1,
    [Enum.KeyCode.KeypadTwo] = doomkeys.KEYP_2,
    [Enum.KeyCode.KeypadThree] = doomkeys.KEYP_3,
    [Enum.KeyCode.KeypadFour] = doomkeys.KEYP_4,
    [Enum.KeyCode.KeypadFive] = doomkeys.KEYP_5,
    [Enum.KeyCode.KeypadSix] = doomkeys.KEYP_6,
    [Enum.KeyCode.KeypadSeven] = doomkeys.KEYP_7,
    [Enum.KeyCode.KeypadEight] = doomkeys.KEYP_8,
    [Enum.KeyCode.KeypadNine] = doomkeys.KEYP_9,

    [Enum.KeyCode.KeypadDivide] = doomkeys.KEYP_DIVIDE, -- '/'
    [Enum.KeyCode.KeypadPlus] = doomkeys.KEYP_PLUS, -- '+'
    [Enum.KeyCode.KeypadMinus] = doomkeys.KEYP_MINUS, -- '-'
    [Enum.KeyCode.KeypadMultiply] = doomkeys.KEYP_MULTIPLY, -- '*'
    [Enum.KeyCode.KeypadPeriod] = doomkeys.KEYP_PERIOD,
    [Enum.KeyCode.KeypadEquals] = doomkeys.KEYP_EQUALS,
    [Enum.KeyCode.KeypadEnter] = doomkeys.KEYP_ENTER
}

local KeyQueue = {}

uis.InputBegan:Connect(function(io)
    table.insert(KeyQueue, {1, map[io.KeyCode]})
end)

uis.InputEnded:Connect(function(io)
    table.insert(KeyQueue, {0, map[io.KeyCode]})
end)

return KeyQueue