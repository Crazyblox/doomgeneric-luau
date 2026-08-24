--!native
--!optimize 2
local d_mode = require("./d_mode")
local doomstat = require("./doomstat")
local d_iwad = {}

-- The known IWAD files. Only the Doom family is supported in v1; the
-- Heretic/Hexen/Strife entries are kept for parity with the C table.
local iwads = {
    { name = "doom2.wad",    mission = d_mode.doom2,     mode = d_mode.commercial, description = "Doom II" },
    { name = "plutonia.wad", mission = d_mode.pack_plut, mode = d_mode.commercial, description = "Final Doom: Plutonia Experiment" },
    { name = "tnt.wad",      mission = d_mode.pack_tnt,  mode = d_mode.commercial, description = "Final Doom: TNT: Evilution" },
    { name = "doom.wad",     mission = d_mode.doom,      mode = d_mode.retail,     description = "Doom" },
    { name = "doom1.wad",    mission = d_mode.doom,      mode = d_mode.shareware,  description = "Doom Shareware" },
    { name = "chex.wad",     mission = d_mode.pack_chex, mode = d_mode.shareware,  description = "Chex Quest" },
    { name = "hacx.wad",     mission = d_mode.pack_hacx, mode = d_mode.commercial, description = "Hacx" },
    { name = "freedm.wad",   mission = d_mode.doom2,     mode = d_mode.commercial, description = "FreeDM" },
    { name = "freedoom2.wad", mission = d_mode.doom2,    mode = d_mode.commercial, description = "Freedoom: Phase 2" },
    { name = "freedoom1.wad", mission = d_mode.doom,     mode = d_mode.retail,     description = "Freedoom: Phase 1" },
    { name = "heretic.wad",  mission = d_mode.heretic,   mode = d_mode.retail,     description = "Heretic" },
    { name = "heretic1.wad", mission = d_mode.heretic,   mode = d_mode.shareware,  description = "Heretic Shareware" },
    { name = "hexen.wad",    mission = d_mode.hexen,     mode = d_mode.commercial, description = "Hexen" },
    { name = "strife1.wad",  mission = d_mode.strife,    mode = d_mode.commercial, description = "Strife" },
}
d_iwad.iwads = iwads

-- IWAD_MASK_DOOM etc. (bitmasks over GameMission_t). Built with bit32
-- (Luau has no native bitwise operators).
local function bit(n)
    return bit32.lshift(1, n)
end

d_iwad.IWAD_MASK_DOOM = bit32.bor(
    bit(d_mode.doom), bit(d_mode.doom2),
    bit(d_mode.pack_tnt), bit(d_mode.pack_plut),
    bit(d_mode.pack_chex), bit(d_mode.pack_hacx))
d_iwad.IWAD_MASK_HERETIC = bit(d_mode.heretic)
d_iwad.IWAD_MASK_HEXEN = bit(d_mode.hexen)
d_iwad.IWAD_MASK_STRIFE = bit(d_mode.strife)

-- D_FindIWAD: the IWAD is already loaded by DoomGeneric.SetWAD, so there is
-- no filesystem search. `gamemission` stays `none` and is identified by
-- content in D_IdentifyVersion. Returns a non-nil placeholder name.
function d_iwad.D_FindIWAD(mask, mission)
    doomstat.gamemission = d_mode.none
    if mission ~= nil then
        mission[1] = d_mode.none
    end
    return "iwad"
end

-- D_FindWADByName / D_TryFindWADByName: no filesystem in this port.
function d_iwad.D_FindWADByName(filename)
    return nil
end

function d_iwad.D_TryFindWADByName(filename)
    return filename
end

-- D_FindAllIWADs: no filesystem in this port.
function d_iwad.D_FindAllIWADs(mask)
    return nil
end

-- D_SaveGameIWADName: IWAD name used for savegames (matches on mission).
function d_iwad.D_SaveGameIWADName(gamemission)
    for _, w in ipairs(iwads) do
        if gamemission == w.mission then
            return w.name
        end
    end
    return "unknown.wad"
end

-- D_SuggestIWADName: name of the IWAD for the given mission/mode.
function d_iwad.D_SuggestIWADName(mission, mode)
    for _, w in ipairs(iwads) do
        if w.mission == mission and w.mode == mode then
            return w.name
        end
    end
    return "unknown.wad"
end

-- D_SuggestGameName: description of the game for the given mission/mode.
function d_iwad.D_SuggestGameName(mission, mode)
    for _, w in ipairs(iwads) do
        if w.mission == mission
            and (mode == d_mode.indetermined or w.mode == mode) then
            return w.description
        end
    end
    return "Unknown game?"
end

return d_iwad