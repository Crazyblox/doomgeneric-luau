--!native
--!optimize 2
local platform = require("./platform")
local d_event = require("./d_event")
local doomkeys = require("./doomkeys")
local i_input = {}

-- Whether to use the vanilla keyboard mapping (i_input.c). When on, the
-- shift key is ignored when entering a savegame name.
i_input.vanilla_keyboard_mapping = 1

-- Is the shift key currently down?
local shiftdown = 0

-- Lookup table for mapping ASCII characters to their equivalent when
-- shift is pressed on an American layout keyboard (i_input.c shiftxform).
local shiftxform = {
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
    31, 32, 33, 34, 35, 36, 37, 38,
    34, -- shift-' (0x27 -> '"' is 34)
    40, 41, 42, 43,
    60, -- shift-, (0x2c -> '<' is 60)
    95, -- shift-- (0x2d -> '_' is 95)
    62, -- shift-. (0x2e -> '>' is 62)
    63, -- shift-/ (0x2f -> '?' is 63)
    41, -- shift-0 (0x30 -> ')' is 41)
    33, -- shift-1 (0x31 -> '!' is 33)
    64, -- shift-2 (0x32 -> '@' is 64)
    35, -- shift-3 (0x33 -> '#' is 35)
    36, -- shift-4 (0x34 -> '$' is 36)
    37, -- shift-5 (0x35 -> '%' is 37)
    94, -- shift-6 (0x36 -> '^' is 94)
    38, -- shift-7 (0x37 -> '&' is 38)
    42, -- shift-8 (0x38 -> '*' is 42)
    40, -- shift-9 (0x39 -> '(' is 40)
    58, -- shift-; (0x3b -> ':' is 58)
    58, -- shift-; (0x3b -> ':' is 58)
    60, -- shift-< (0x3c -> '<' is 60; the C has a duplicate <)
    43, -- shift-= (0x3d -> '+' is 43)
    62, 63, 64, -- shift-> / ? / @ (the C lists these before A..Z)
    65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78,
    79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90,
    91, -- shift-[ (0x5b -> '{' is 123? The C uses '[' here)
    33, -- shift-backslash - OH MY GOD DOES WATCOM SUCK (0x5c -> '!')
    93, -- shift-] (0x5d -> '}' is 125? The C uses ']')
    34, 95, -- shift-^ (0x5e -> '"') / shift-- (0x5f -> '_')
    39, -- shift-` (0x60 -> '\'')
    65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78,
    79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90,
    123, 124, 125, 126, 127,
}

-- TranslateKey: the C build returns the key unchanged (the at_to_doom table
-- is disabled in this port).
local function TranslateKey(key)
    return key
end

-- GetTypedChar: get the equivalent ASCII character for a keypress, applying
-- the shift translation.
local function GetTypedChar(key)
    key = TranslateKey(key)

    if shiftdown > 0 then
        if key >= 0 and key < #shiftxform then
            key = shiftxform[key + 1] -- 0-based -> 1-based Lua
        else
            key = 0
        end
    end

    return key
end

-- UpdateShiftStatus: track the shift key state.
local function UpdateShiftStatus(pressed, key)
    local change
    if pressed then
        change = 1
    else
        change = -1
    end

    if key == doomkeys.KEY_RSHIFT then
        shiftdown = shiftdown + change
    end
end

-- I_GetEvent: drain the platform key queue into Doom events.
function i_input.I_GetEvent()
    while true do
        local pressed, key = platform.GetKey()

        -- No key queued: the host returns (false, 0) / (nil, nil).
        if key == nil or key == 0 then
            break
        end

        UpdateShiftStatus(pressed, key)

        if pressed then
            -- data1 has the key pressed, data2 the shift-translated char.
            local ev = {
                type = d_event.ev_keydown,
                data1 = TranslateKey(key),
                data2 = GetTypedChar(key),
            }
            if ev.data1 ~= 0 then
                d_event.D_PostEvent(ev)
            end
        else
            local ev = {
                type = d_event.ev_keyup,
                data1 = TranslateKey(key),
                data2 = 0,
            }
            if ev.data1 ~= 0 then
                d_event.D_PostEvent(ev)
            end
            break -- process one key release per call, like the C
        end
    end
end

-- I_InitInput: no-op.
function i_input.I_InitInput()
end

return i_input