--!native
--!optimize 2
local d_mode = {}

-- ---------------------------------------------------------------------------
-- GameMission_t
-- ---------------------------------------------------------------------------

d_mode.doom = 0
d_mode.doom2 = 1
d_mode.pack_tnt = 2
d_mode.pack_plut = 3
d_mode.pack_chex = 4
d_mode.pack_hacx = 5
d_mode.heretic = 6
d_mode.hexen = 7
d_mode.strife = 8
d_mode.none = 9

-- ---------------------------------------------------------------------------
-- GameMode_t
-- ---------------------------------------------------------------------------

d_mode.shareware = 0
d_mode.registered = 1
d_mode.commercial = 2
d_mode.retail = 3
d_mode.indetermined = 4

-- ---------------------------------------------------------------------------
-- GameVersion_t
-- ---------------------------------------------------------------------------

d_mode.exe_doom_1_2 = 0
d_mode.exe_doom_1_666 = 1
d_mode.exe_doom_1_7 = 2
d_mode.exe_doom_1_8 = 3
d_mode.exe_doom_1_9 = 4
d_mode.exe_hacx = 5
d_mode.exe_ultimate = 6
d_mode.exe_final = 7
d_mode.exe_final2 = 8
d_mode.exe_chex = 9
d_mode.exe_heretic_1_3 = 10
d_mode.exe_hexen_1_1 = 11
d_mode.exe_strife_1_2 = 12
d_mode.exe_strife_1_31 = 13

-- ---------------------------------------------------------------------------
-- skill_t
-- ---------------------------------------------------------------------------

d_mode.sk_noitems = -1
d_mode.sk_baby = 0
d_mode.sk_easy = 1
d_mode.sk_medium = 2
d_mode.sk_hard = 3
d_mode.sk_nightmare = 4

-- ---------------------------------------------------------------------------
-- Valid game mode/mission combinations, with the number of episodes/maps.
-- ---------------------------------------------------------------------------

local valid_modes = {
    { mission = d_mode.pack_chex, mode = d_mode.shareware, episode = 1, map = 5 },
    { mission = d_mode.doom,      mode = d_mode.shareware, episode = 1, map = 9 },
    { mission = d_mode.doom,      mode = d_mode.registered, episode = 3, map = 9 },
    { mission = d_mode.doom,      mode = d_mode.retail,    episode = 4, map = 9 },
    { mission = d_mode.doom2,     mode = d_mode.commercial, episode = 1, map = 32 },
    { mission = d_mode.pack_tnt,  mode = d_mode.commercial, episode = 1, map = 32 },
    { mission = d_mode.pack_plut, mode = d_mode.commercial, episode = 1, map = 32 },
    { mission = d_mode.pack_hacx, mode = d_mode.commercial, episode = 1, map = 32 },
    { mission = d_mode.heretic,   mode = d_mode.shareware, episode = 1, map = 9 },
    { mission = d_mode.heretic,   mode = d_mode.registered, episode = 3, map = 9 },
    { mission = d_mode.heretic,   mode = d_mode.retail,    episode = 5, map = 9 },
    { mission = d_mode.hexen,     mode = d_mode.commercial, episode = 1, map = 60 },
    { mission = d_mode.strife,    mode = d_mode.commercial, episode = 1, map = 34 },
}

-- D_ValidGameMode: check a gamemode+gamemission combination is valid.
function d_mode.D_ValidGameMode(mission, mode)
    for _, v in ipairs(valid_modes) do
        if v.mode == mode and v.mission == mission then
            return true
        end
    end
    return false
end

-- D_ValidEpisodeMap: check an episode/map is valid for the mission/mode.
function d_mode.D_ValidEpisodeMap(mission, mode, episode, map)
    -- Hacks for Heretic secret episodes.
    if mission == d_mode.heretic then
        if mode == d_mode.retail and episode == 6 then
            return map >= 1 and map <= 3
        elseif mode == d_mode.registered and episode == 4 then
            return map == 1
        end
    end

    for _, v in ipairs(valid_modes) do
        if mission == v.mission and mode == v.mode then
            return episode >= 1 and episode <= v.episode
                and map >= 1 and map <= v.map
        end
    end

    -- Unknown mode/mission combination.
    return false
end

-- D_GetNumEpisodes: number of valid episodes for the mission/mode.
function d_mode.D_GetNumEpisodes(mission, mode)
    local episode = 1
    while d_mode.D_ValidEpisodeMap(mission, mode, episode, 1) do
        episode = episode + 1
    end
    return episode - 1
end

-- Table of valid game versions.
local valid_versions = {
    { mission = d_mode.doom,    version = d_mode.exe_doom_1_9 },
    { mission = d_mode.doom,    version = d_mode.exe_hacx },
    { mission = d_mode.doom,    version = d_mode.exe_ultimate },
    { mission = d_mode.doom,    version = d_mode.exe_final },
    { mission = d_mode.doom,    version = d_mode.exe_final2 },
    { mission = d_mode.doom,    version = d_mode.exe_chex },
    { mission = d_mode.heretic, version = d_mode.exe_heretic_1_3 },
    { mission = d_mode.hexen,   version = d_mode.exe_hexen_1_1 },
    { mission = d_mode.strife,  version = d_mode.exe_strife_1_2 },
    { mission = d_mode.strife,  version = d_mode.exe_strife_1_31 },
}

function d_mode.D_ValidGameVersion(mission, version)
    -- All Doom variants can use the Doom versions.
    if mission == d_mode.doom2 or mission == d_mode.pack_plut
        or mission == d_mode.pack_tnt or mission == d_mode.pack_hacx
        or mission == d_mode.pack_chex then
        mission = d_mode.doom
    end

    for _, v in ipairs(valid_versions) do
        if v.mission == mission and v.version == version then
            return true
        end
    end
    return false
end

-- D_IsEpisodeMap: does this mission use ExMy form (rather than MAPxy)?
function d_mode.D_IsEpisodeMap(mission)
    if mission == d_mode.doom or mission == d_mode.heretic
        or mission == d_mode.pack_chex then
        return true
    end
    return false
end

-- D_GameMissionString: human-readable mission name.
function d_mode.D_GameMissionString(mission)
    if mission == d_mode.none then
        return "none"
    elseif mission == d_mode.doom then
        return "doom"
    elseif mission == d_mode.doom2 then
        return "doom2"
    elseif mission == d_mode.pack_tnt then
        return "tnt"
    elseif mission == d_mode.pack_plut then
        return "plutonia"
    elseif mission == d_mode.pack_hacx then
        return "hacx"
    elseif mission == d_mode.pack_chex then
        return "chex"
    elseif mission == d_mode.heretic then
        return "heretic"
    elseif mission == d_mode.hexen then
        return "hexen"
    elseif mission == d_mode.strife then
        return "strife"
    end
    return "none"
end

return d_mode