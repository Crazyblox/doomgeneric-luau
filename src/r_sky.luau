--!native
--!optimize 2
local m_fixed = require("./m_fixed")
local r_state = require("./r_state")
local r_sky = {}

-- R_InitSkyMap: called whenever the view size changes.
function r_sky.R_InitSkyMap()
    -- skyflatnum = R_FlatNumForName("F_SKY1") would be set here in the C;
    -- the port resolves it in R_InitTextures/R_InitFlats order and sets
    -- r_state.skyflatnum when R_InitFlats runs (see r_data.lua).
    r_state.skytexturemid = 100 * m_fixed.FRACUNIT
end

return r_sky