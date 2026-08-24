--!native
--!optimize 2
local d_event = {}

-- Input event types (evtype_t).
d_event.ev_keydown = 0
d_event.ev_keyup = 1
d_event.ev_mouse = 2
d_event.ev_joystick = 3
d_event.ev_quit = 4

-- Button/action code definitions (buttoncode_t).
d_event.BT_ATTACK = 1
d_event.BT_USE = 2
d_event.BT_SPECIAL = 128
d_event.BT_SPECIALMASK = 3
d_event.BT_CHANGE = 4
d_event.BT_WEAPONMASK = 8 + 16 + 32
d_event.BT_WEAPONSHIFT = 3
d_event.BTS_PAUSE = 1
d_event.BTS_SAVEGAME = 2
d_event.BTS_SAVEMASK = 4 + 8 + 16
d_event.BTS_SAVESHIFT = 2

-- Strife-specific buttons (buttoncode2_t).
d_event.BT2_LOOKUP = 1
d_event.BT2_LOOKDOWN = 2
d_event.BT2_CENTERVIEW = 4
d_event.BT2_INVUSE = 8
d_event.BT2_INVDROP = 16
d_event.BT2_JUMP = 32
d_event.BT2_HEALTH = 128

local MAXEVENTS = 64
local events = {}
local eventhead = 1
local eventtail = 1

-- D_PostEvent: called by I/O functions when input is detected.
function d_event.D_PostEvent(ev)
    events[eventhead] = ev
    eventhead = eventhead % MAXEVENTS + 1
end

-- D_PopEvent: read an event from the queue; nil if none waiting.
function d_event.D_PopEvent()
    if eventtail == eventhead then
        return nil
    end
    local result = events[eventtail]
    eventtail = eventtail % MAXEVENTS + 1
    return result
end

return d_event