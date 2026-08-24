--!native
--!optimize 2
local doomtype = require("./doomtype")
local platform = require("./platform")
local i_timer = {}

i_timer.TICRATE = doomtype.TICRATE

local basetime = 0

-- I_GetTicks: raw milliseconds from the platform.
function i_timer.I_GetTicks()
    return platform.GetTicksMs()
end

-- I_GetTime: time in 1/35th-second tics since the first call.
function i_timer.I_GetTime()
    local ticks = i_timer.I_GetTicks()
    if basetime == 0 then
        basetime = ticks
    end
    ticks = ticks - basetime
    return (ticks * i_timer.TICRATE) // 1000
end

-- I_GetTimeMS: time in milliseconds since the first call.
function i_timer.I_GetTimeMS()
    local ticks = i_timer.I_GetTicks()
    if basetime == 0 then
        basetime = ticks
    end
    return ticks - basetime
end

-- I_Sleep: pause for the specified number of ms.
function i_timer.I_Sleep(ms)
    platform.SleepMs(ms)
end

-- I_WaitVBL: no-op.
function i_timer.I_WaitVBL()
end

-- I_InitTimer: no-op.
function i_timer.I_InitTimer()
end

return i_timer