--!native
--!optimize 2
local doomtype = require("./doomtype")
local i_system = require("./i_system")
local i_timer = require("./i_timer")
local m_fixed = require("./m_fixed")
local i_video = require("./i_video")
local d_loop = {}

-- Net constants (net_defs.h).
local NET_MAXPLAYERS = 8
local BACKUPTICS = 128

-- The number of tics that have been run (using RunTic) so far.
d_loop.gametic = 0

-- When set to true, a single tic is run each time TryRunTics() is called
-- (-timedemo mode). Deferred until the renderer exists.
d_loop.singletics = false

-- Sample game input less when ticdup > 1 (bandwidth reduction).
d_loop.ticdup = 1

-- Amount to offset the timer for game sync (fixed_t ms).
d_loop.offsetms = 0

-- Use the new client sync code? The doomgeneric build (non-ORIGCODE)
-- hardcodes this to false, so the classic Vanilla-style sync path is used.
local new_sync = false

-- The complete set of data for a particular tic.
local ticdata = {}
for _ = 1, BACKUPTICS do
    table.insert(ticdata, { cmds = {}, ingame = {} })
end

-- The index of the next tic to be made (with a call to BuildTiccmd).
local maketic = 0

-- The number of complete tics received from the server (single player: 0;
-- only the multiplayer path of the C uses this, so it is unused here).
local _recvtic = 0

-- Index of the local player.
local localplayer = 0

-- Callback functions for loop code.
local loop_interface = nil

-- Current players in the (single-player) game.
local local_playeringame = { true }

-- 35 fps clock adjusted by offsetms milliseconds (new_sync only).
local function GetAdjustedTime()
    local time_ms = i_timer.I_GetTimeMS()
    if new_sync then
        time_ms = time_ms + (d_loop.offsetms // m_fixed.FRACUNIT)
    end
    return (time_ms * doomtype.TICRATE) // 1000
end

-- BuildNewTic: create a new ticcmd for the local player, if the game is not
-- running too far ahead.
local function BuildNewTic()
    local gameticdiv = d_loop.gametic // d_loop.ticdup

    i_video.I_StartTic() -- C: i_video.c I_StartTic -> I_GetEvent
    loop_interface.ProcessEvents()

    -- Always run the menu.
    loop_interface.RunMenu()

    if new_sync then
        -- If playing single player, do not allow tics to buffer up very far.
        if maketic - gameticdiv > 2 then
            return false
        end

        -- Never go more than ~200ms ahead.
        if maketic - gameticdiv > 8 then
            return false
        end
    else
        if maketic - gameticdiv >= 5 then
            return false
        end
    end

    local cmd = {}
    loop_interface.BuildTiccmd(cmd, maketic)

    local set = ticdata[maketic % BACKUPTICS + 1]
    set.cmds[localplayer + 1] = cmd
    set.ingame[localplayer + 1] = true

    maketic = maketic + 1

    return true
end

-- NetUpdate: build new ticcmds for the console player.
d_loop.lasttime = 0

function d_loop.NetUpdate()
    -- If running with singletics (timing a demo), this is done separately.
    if d_loop.singletics then
        return
    end

    -- Check time.
    local nowtime = GetAdjustedTime() // d_loop.ticdup
    local newtics = nowtime - d_loop.lasttime
    d_loop.lasttime = nowtime

    -- Build new ticcmds for the console player.
    for _ = 1, newtics do
        if not BuildNewTic() then
            break
        end
    end
end

-- D_StartGameLoop: called after the screen is set but before the game runs.
function d_loop.D_StartGameLoop()
    d_loop.lasttime = GetAdjustedTime() // d_loop.ticdup
end

-- D_StartNetGame: single-player game settings (the doomgeneric / non-ORIGCODE
-- path of the C function). The settings table is updated in place.
function d_loop.D_StartNetGame(settings)
    settings.consoleplayer = 0
    settings.num_players = 1
    settings.player_classes = settings.player_classes or {}
    settings.player_classes[1] = 0 -- player_class
    settings.new_sync = 0
    settings.extratics = 1
    settings.ticdup = 1

    d_loop.ticdup = settings.ticdup
    new_sync = settings.new_sync == 1
end

-- GetLowTic: the lowest tic that has ticcmds available.
local function GetLowTic()
    return maketic
end

-- When using ticdup, certain values must be cleared out when running the
-- duplicate ticcmds.
local function TicdupSquash(set)
    for i = 1, NET_MAXPLAYERS do
        local cmd = set.cmds[i]
        if cmd ~= nil then
            cmd.chatchar = 0
            if cmd.buttons ~= nil then
                -- BT_SPECIAL is bit 7 (128) in d_event.
                if bit32.band(cmd.buttons, 128) ~= 0 then
                    cmd.buttons = 0
                end
            end
        end
    end
end

-- When running in single player mode, clear all the ingame[] array except
-- the local player.
local function SinglePlayerClear(set)
    for i = 1, NET_MAXPLAYERS do
        if i ~= localplayer + 1 then
            set.ingame[i] = false
        end
    end
end

-- Returns true if there are players in the game.
local function PlayersInGame()
    return true -- single player, not a drone
end

-- static int oldentertics (C)
local oldentertics = 0

-- TryRunTics: runs at least one tic.
function d_loop.TryRunTics()
    local entertic = i_timer.I_GetTime() // d_loop.ticdup
    local realtics = entertic - oldentertics
    oldentertics = entertic

    if d_loop.singletics then
        BuildNewTic()
    else
        d_loop.NetUpdate()
    end

    local lowtic = GetLowTic()
    local availabletics = lowtic - d_loop.gametic // d_loop.ticdup

    -- Decide how many tics to run.
    local counts
    if new_sync then
        counts = availabletics
    else
        -- Old (classic Vanilla) sync path.
        if realtics < availabletics - 1 then
            counts = realtics + 1
        elseif realtics < availabletics then
            counts = realtics
        else
            counts = availabletics
        end
        if counts < 1 then
            counts = 1
        end
    end

    if counts < 1 then
        counts = 1
    end

    -- Wait for new tics if needed.
    while not PlayersInGame() or lowtic < d_loop.gametic // d_loop.ticdup + counts do
        d_loop.NetUpdate()
        lowtic = GetLowTic()

        if lowtic < d_loop.gametic // d_loop.ticdup then
            i_system.I_Error("TryRunTics: lowtic < gametic")
        end

        -- Don't stay in this loop forever. The menu is still running,
        -- so return to update the screen.
        if i_timer.I_GetTime() // d_loop.ticdup - entertic > 0 then
            return
        end

        i_timer.I_Sleep(1)
    end

    -- Run the count * ticdup tics.
    for _ = 1, counts do
        local set = ticdata[(d_loop.gametic // d_loop.ticdup) % BACKUPTICS + 1]

        SinglePlayerClear(set)

        for _ = 1, d_loop.ticdup do
            if d_loop.gametic // d_loop.ticdup > lowtic then
                i_system.I_Error("gametic>lowtic")
            end

            for i = 1, NET_MAXPLAYERS do
                local_playeringame[i] = set.ingame[i] or false
            end

            loop_interface.RunTic(set.cmds, set.ingame)
            d_loop.gametic = d_loop.gametic + 1

            -- Modify command for duplicated tics.
            TicdupSquash(set)
        end

        d_loop.NetUpdate() -- check for new console commands
    end
end

-- D_RegisterLoopCallbacks.
function d_loop.D_RegisterLoopCallbacks(i)
    loop_interface = i
end

return d_loop