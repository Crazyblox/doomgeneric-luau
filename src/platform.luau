--!native
--!optimize 2
local Platform = {
    Init = function() end,
    DrawFrame = function() end,
    SleepMs = function(ms) end,
    GetTicksMs = function() return 0 end,
    GetKey = function() return false, 0 end,
    SetWindowTitle = function(title) end,
}

return Platform