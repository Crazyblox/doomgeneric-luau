--!native
--!optimize 2

-- doomgeneric-luau [In-development]
-- A port of doomgeneric, based on chocolate doom, based on the original doom...
-- Port is in-dev, meaning that implemented code is unstable, or missing features completely.
--
-- doomgeneric-luau:    Copyright(C) 2026 Crazyblox, GPLv2
-- doomgeneric:         Copyright(C) 2005-2014 Simon Howard, GPLv2
-- DOOM engine:         Copyright(C) 1993-1996 Id Software, Inc., GPLv2

-- Level 0 [Top-level]: These modules do not require other modules.
local d_event   = require("@self/d_event")
local d_items   = require("@self/d_items")
local d_mode    = require("@self/d_mode")
local deh_misc  = require("@self/deh_misc")
local deh_str   = require("@self/deh_str")
local doomkeys  = require("@self/doomkeys")
local doomtype  = require("@self/doomtype")
local dstrings  = require("@self/dstrings")
local i_system  = require("@self/i_system")
local info      = require("@self/info")
local m_argv    = require("@self/m_argv")
local m_bbox    = require("@self/m_bbox")
local m_cheat   = require("@self/m_cheat")
local m_misc    = require("@self/m_misc")
local m_random  = require("@self/m_random")
local platform  = require("@self/platform")
local r_state   = require("@self/r_state")
local s_sound   = require("@self/s_sound")
local sounds    = require("@self/sounds")
local z_zone    = require("@self/z_zone")

-- Level 1: Depends exclusively on level 0 modules.
local m_fixed   = require("@self/m_fixed")      -- doomtype
local doomdef   = require("@self/doomdef")      -- doomtype
local tables    = require("@self/tables")       -- doomtype
local m_config  = require("@self/m_config")     -- doomkeys
local i_timer   = require("@self/i_timer")      -- doomtype, platform
local r_sky     = require("@self/r_sky")        -- r_state, m_fixed
local i_input   = require("@self/i_input")      -- doomkeys, platform, d_event

-- Level 2: Depends on level 0 and level 1 modules
local p_sight   = require("@self/p_sight")      -- doomtype, m_fixed, r_state
local doomstat  = require("@self/doomstat")     -- doomdef, d_mode
local m_controls= require("@self/m_controls")   -- doomkeys, m_config
local i_video   = require("@self/i_video")      -- doomtype, z_zone, tables, platform, i_input
local d_iwad    = require("@self/d_iwad")       -- doomstat, d_mode
local w_wad     = require("@self/w_wad")        -- i_system, d_mode, d_iwad
local v_video   = require("@self/v_video")      -- i_video, m_bbox, i_system
local f_wipe    = require("@self/f_wipe")       -- i_video, v_video, m_random
local d_loop    = require("@self/d_loop")       -- doomtype, i_system, i_timer, m_fixed, i_video
local r_draw    = require("@self/r_draw")       -- deh_str, doomstat, r_state, v_video, i_video, z_zone, w_wad
local hu_lib    = require("@self/hu_lib")       -- doomstat, v_video, r_state, r_draw
local st_lib    = require("@self/st_lib")       -- deh_str, z_zone, w_wad, i_system, v_video
local hu_stuff  = require("@self/hu_stuff")     -- doomtype, doomstat, dstrings, deh_str, w_wad, z_zone, hu_lib, d_mode, doomkeys, m_controls, d_event

-- Level 3: Circular dependencies with one another, included below.
-- [Luau can't resolve circular dependencies, so these stay here or get rewritten...]
local am_map        -- doomtype, m_fixed, m_cheat, r_state, doomstat, i_video, st_stuff, deh_str, w_wad, z_zone, m_controls, dstrings, m_misc, doomdef, tables, v_video ...
local d_main        -- am_map, d_event, m_menu, g_game, doomstat, r_state, r_main, f_wipe, doomdef, d_loop, hu_stuff, wi_stuff, f_finale, i_video, w_wad, deh_str, z_zone, r_draw, v_video, i_timer, m_controls, doomtype, m_config, s_sound ...
local d_net         -- doomtype, doomstat, g_game, m_menu, d_loop, d_main, m_argv ...
local doomgeneric   -- ...
local f_finale      -- ...
local g_game        -- am_map, wi_stuff, doomdef, d_mode, doomtype, m_fixed, doomstat, deh_misc, p_inter, p_mobj, d_loop, p_setup, z_zone, m_controls, hu_stuff, d_event, m_menu, st_stuff, f_finale, m_misc, i_system, m_random, s_sound, p_tick, d_main, w_wad, info, m_argv, i_timer ...
local m_menu        -- ...
local p_ceilng      -- ...
local p_doors       -- ...
local p_enemy       -- ...
local p_floor       -- ...
local p_inter       -- ...
local p_lights      -- ...
local p_map         -- ...
local p_maputl      -- doomstat, m_fixed, r_state, m_bbox, r_main, p_spr ... 
local p_mobj        -- ...
local p_plats       -- ...
local p_pspr        -- ...
local p_setup       -- deh_str, doomstat, m_bbox, d_mode, m_fixed, r_state, w_wad, z_zone, r_data, m_argv, p_mobj, s_sound, p_tick, g_game, p_spec, r_things, info ... 
local p_spec        -- ...
local p_switch      -- ...
local p_telept      -- p_mobj, r_state, p_tick, p_mobj, info, p_map, doomstat, d_mode, s_sound, sounds, tables ...
local p_tick        -- doomstat, doomtype, p_user, p_spec, p_mobj ...
local p_user        -- m_fixed, doomtype, tables, info, p_mobj, p_pspr, r_main, p_spec, p_map, doomdef, doomstat ... 
local r_bsp         -- ...
local r_data        -- deh_str, doomstat, m_fixed, r_state, w_wad, z_zone, i_system, p_tick ... 
local r_main        -- ...
local r_plane       -- ...
local r_segs        -- ...
local r_things      -- ...
local st_stuff      -- ...
local wi_stuff      -- deh_str, doomtype, v_video, doomstat, d_mode, m_random, s_sound, w_wad, z_zone, g_game ...

-- Recommend collapsing these entries for easier browsing.
doomgeneric = (function()
local DoomGeneric = {}

-- Host-implemented platform functions (DG_Init, DG_DrawFrame, DG_SleepMs,
-- DG_GetTicksMs, DG_GetKey, DG_SetWindowTitle).
DoomGeneric.Platform = platform

-- The framebuffer the host reads in DrawFrame.
DoomGeneric.DG_ScreenBuffer = nil

-- WAD input (raw bytes as a Luau buffer).
function DoomGeneric.SetWAD(wadBuffer)
    w_wad.SetWAD(wadBuffer)
end

function DoomGeneric.AddPWAD(wadBuffer)
    w_wad.AddPWAD(wadBuffer)
end

-- doomgeneric_Create(argc, argv)
function DoomGeneric.Create(args)
    -- Save arguments.
    m_argv.SetArgs(args or {})

    m_argv.M_FindResponseFile()

    -- Allocate the 32bpp framebuffer.
    DoomGeneric.DG_ScreenBuffer = buffer.create(
        doomtype.DOOMGENERIC_RESX * doomtype.DOOMGENERIC_RESY * 4)
    i_video.SetScreenBuffer(DoomGeneric.DG_ScreenBuffer)

    -- DG_Init
    platform.Init()

    d_main.D_DoomMain()
end

-- doomgeneric_Tick()
function DoomGeneric.Tick()
    d_main.doomgeneric_Tick()
end

return DoomGeneric
end)()

d_net = (function()
local d_net = {}

-- Called when a player leaves the game. Phase 2: single-player stub.
local function PlayerQuitGame(player_num)
    doomstat.playeringame[player_num + 1] = false
    if doomstat.players[doomstat.consoleplayer + 1] ~= nil then
        doomstat.players[doomstat.consoleplayer + 1].message =
            string.format("Player %i left the game", player_num + 1)
    end
    -- TODO (Phase 4): if demorecording then G_CheckDemoStatus()
end

-- RunTic: the per-tic callback of the loop interface.
local function RunTic(cmds, ingame)
    -- Check for player quits.
    for i = 1, doomtype.MAXPLAYERS do
        if not doomstat.demoplayback
            and doomstat.playeringame[i]
            and not ingame[i] then
            PlayerQuitGame(i - 1)
        end
    end

    doomstat.netcmds = cmds

    -- Check that there are players in the game. If not, we cannot run a tic.
    if d_main.advancedemo then
        d_main.D_DoAdvanceDemo()
    end

    g_game.G_Ticker()
end

-- The Doom loop interface (loop_interface_t in d_loop.h).
local doom_loop_interface = {
    ProcessEvents = function() d_main.D_ProcessEvents() end,
    BuildTiccmd = function(cmd, maketic) g_game.G_BuildTiccmd(cmd, maketic) end,
    RunTic = function(cmds, ingame) RunTic(cmds, ingame) end,
    RunMenu = function() m_menu.M_Ticker() end,
}

-- D_ConnectNetGame: multiplayer is cut in v1, so netgame is always false
-- (the -solo-net path is deferred with multiplayer).
function d_net.D_ConnectNetGame()
    doomstat.netgame = false
end

-- D_CheckNetGame: work out player numbers among the net participants
-- (single-player: just register the loop callbacks and start the game).
function d_net.D_CheckNetGame()
    local settings = {}

    if doomstat.netgame then
        doomstat.autostart = true
    end

    d_loop.D_RegisterLoopCallbacks(doom_loop_interface)

    d_loop.D_StartNetGame(settings)

    -- LoadGameSettings (d_net.c): copy the single-player settings back into
    -- the game globals. playeringame[i] = i < settings.num_players, so with
    -- num_players = 1 only player 0 is in the game.
    doomstat.consoleplayer = settings.consoleplayer
    for i = 1, doomtype.MAXPLAYERS do
        doomstat.playeringame[i] = i <= settings.num_players
    end

    print(string.format("startskill %i  deathmatch: %i  startmap: %i  startepisode: %i",
        doomstat.startskill, doomstat.deathmatch, doomstat.startmap,
        doomstat.startepisode))
    print(string.format("player %i of %i (%i nodes)",
        doomstat.consoleplayer + 1, settings.num_players, settings.num_players))

    if doomstat.timelimit > 0 and doomstat.deathmatch then
        print(string.format("Levels will end after %d minute", doomstat.timelimit))
        if doomstat.timelimit > 1 then
            print("s")
        end
        print(".")
    end
end

return d_net
end)()

f_finale = (function()
local f_finale = {}

local SCREENWIDTH = 320
local SCREENHEIGHT = 200
local TICRATE = doomtype.TICRATE

-- finalestage_t.
local F_STAGE_TEXT = 0
local F_STAGE_ARTSCREEN = 1
local F_STAGE_CAST = 2

-- Stage of animation.
local finalestage = F_STAGE_TEXT
local finalecount = 0

local TEXTSPEED = 3
local TEXTWAIT = 250

-- textscreen_t table.
local textscreens = {
    { mission = d_mode.doom,   episode = 1, level = 8,  background = "FLOOR4_8", text = dstrings.E1TEXT },
    { mission = d_mode.doom,   episode = 2, level = 8,  background = "SFLR6_1",  text = dstrings.E2TEXT },
    { mission = d_mode.doom,   episode = 3, level = 8,  background = "MFLR8_4",  text = dstrings.E3TEXT },
    { mission = d_mode.doom,   episode = 4, level = 8,  background = "MFLR8_3",  text = dstrings.E4TEXT },

    { mission = d_mode.doom2,  episode = 1, level = 6,  background = "SLIME16",  text = dstrings.C1TEXT },
    { mission = d_mode.doom2,  episode = 1, level = 11, background = "RROCK14",  text = dstrings.C2TEXT },
    { mission = d_mode.doom2,  episode = 1, level = 20, background = "RROCK07",  text = dstrings.C3TEXT },
    { mission = d_mode.doom2,  episode = 1, level = 30, background = "RROCK17",  text = dstrings.C4TEXT },
    { mission = d_mode.doom2,  episode = 1, level = 15, background = "RROCK13",  text = dstrings.C5TEXT },
    { mission = d_mode.doom2,  episode = 1, level = 31, background = "RROCK19",  text = dstrings.C6TEXT },

    { mission = d_mode.pack_tnt,  episode = 1, level = 6,  background = "SLIME16",  text = dstrings.T1TEXT },
    { mission = d_mode.pack_tnt,  episode = 1, level = 11, background = "RROCK14",  text = dstrings.T2TEXT },
    { mission = d_mode.pack_tnt,  episode = 1, level = 20, background = "RROCK07",  text = dstrings.T3TEXT },
    { mission = d_mode.pack_tnt,  episode = 1, level = 30, background = "RROCK17",  text = dstrings.T4TEXT },
    { mission = d_mode.pack_tnt,  episode = 1, level = 15, background = "RROCK13",  text = dstrings.T5TEXT },
    { mission = d_mode.pack_tnt,  episode = 1, level = 31, background = "RROCK19",  text = dstrings.T6TEXT },

    { mission = d_mode.pack_plut, episode = 1, level = 6,  background = "SLIME16",  text = dstrings.P1TEXT },
    { mission = d_mode.pack_plut, episode = 1, level = 11, background = "RROCK14",  text = dstrings.P2TEXT },
    { mission = d_mode.pack_plut, episode = 1, level = 20, background = "RROCK07",  text = dstrings.P3TEXT },
    { mission = d_mode.pack_plut, episode = 1, level = 30, background = "RROCK17",  text = dstrings.P4TEXT },
    { mission = d_mode.pack_plut, episode = 1, level = 15, background = "RROCK13",  text = dstrings.P5TEXT },
    { mission = d_mode.pack_plut, episode = 1, level = 31, background = "RROCK19",  text = dstrings.P6TEXT },
}

local finaletext = nil
local finaleflat = nil

local HU_FONTSTART = 33 -- '!'
local HU_FONTSIZE = 63 -- HU_FONTEND('_') - HU_FONTSTART + 1

-- Logical gamemission (doomstat.h macro).
local function logical_gamemission()
    if doomstat.gamemission == d_mode.pack_chex then
        return d_mode.doom
    elseif doomstat.gamemission == d_mode.pack_hacx then
        return d_mode.doom2
    end
    return doomstat.gamemission
end

-- Helper: set g_game.gameaction = ga_nothing (lazy to avoid cycles).
local function g_gameaction_ga_nothing()
    g_game.gameaction = doomdef.ga_nothing
end

-- ---------------------------------------------------------------------------
-- F_StartFinale
-- ---------------------------------------------------------------------------

function f_finale.F_StartFinale()
    local i

    g_gameaction_ga_nothing()
    doomstat.gamestate = doomdef.GS_FINALE
    doomstat.viewactive = false
    doomstat.automapactive = false

    -- Find the right screen and set the text and background.
    for i = 1, #textscreens do
        local screen = textscreens[i]

        -- Hack for Chex Quest.
        if doomstat.gameversion == d_mode.exe_chex and screen.mission == d_mode.doom then
            screen.level = 5
        end

        if logical_gamemission() == screen.mission
            and (logical_gamemission() ~= d_mode.doom or doomstat.gameepisode == screen.episode)
            and doomstat.gamemap == screen.level then
            finaletext = screen.text
            finaleflat = screen.background
        end
    end

    -- Do dehacked substitutions of strings.
    finaletext = deh_str.DEH_String(finaletext)
    finaleflat = deh_str.DEH_String(finaleflat)

    finalestage = F_STAGE_TEXT
    finalecount = 0
end

-- ---------------------------------------------------------------------------
-- F_Responder
-- ---------------------------------------------------------------------------

function f_finale.F_Responder(ev)
    if finalestage == F_STAGE_CAST then
        return f_finale.F_CastResponder(ev)
    end
    return false
end

-- ---------------------------------------------------------------------------
-- F_Ticker
-- ---------------------------------------------------------------------------

function f_finale.F_Ticker()
    -- Check for skipping.
    if doomstat.gamemode == d_mode.commercial and finalecount > 50 then
        -- Go on to the next level.
        local i = 1
        while i <= doomtype.MAXPLAYERS do
            if doomstat.players[i].cmd.buttons ~= 0 then
                break
            end
            i = i + 1
        end

        if i <= doomtype.MAXPLAYERS then
            if doomstat.gamemap == 30 then
                f_finale.F_StartCast()
            else
                g_game.gameaction = doomdef.ga_worlddone
            end
        end
    end

    -- Advance animation.
    finalecount = finalecount + 1

    if finalestage == F_STAGE_CAST then
        f_finale.F_CastTicker()
        return
    end

    if doomstat.gamemode == d_mode.commercial then
        return
    end

    if finalestage == F_STAGE_TEXT
        and finalecount > #finaletext * TEXTSPEED + TEXTWAIT then
        finalecount = 0
        finalestage = F_STAGE_ARTSCREEN
        doomstat.wipegamestate = -1 -- force a wipe
        if doomstat.gameepisode == 3 then
            s_sound.S_StartMusic(0)
        end
    end
end

-- ---------------------------------------------------------------------------
-- F_TextWrite
-- ---------------------------------------------------------------------------

local function F_TextWrite()
    local src
    local x
    local y
    local w
    local count
    local c
    local cx
    local cy

    if finaletext == nil or finaleflat == nil then
        return
    end

    -- Erase the entire screen to a tiled background.
    src = w_wad.W_CacheLumpName(finaleflat, z_zone.PU_CACHE)
    local dest = 0

    for y = 0, SCREENHEIGHT - 1 do
        for x = 0, SCREENWIDTH // 64 - 1 do
            buffer.copy(i_video.I_VideoBuffer, dest, src.buffer,
                src.offset + bit32.band(y, 63) * 64, 64)
            dest = dest + 64
        end
        if bit32.band(SCREENWIDTH, 63) ~= 0 then
            buffer.copy(i_video.I_VideoBuffer, dest, src.buffer,
                src.offset + bit32.band(y, 63) * 64,
                bit32.band(SCREENWIDTH, 63))
            dest = dest + bit32.band(SCREENWIDTH, 63)
        end
    end

    v_video.V_MarkRect(0, 0, SCREENWIDTH, SCREENHEIGHT)

    -- Draw some of the text onto the screen.
    cx = 10
    cy = 10
    local ch = 1 -- index into finaletext

    count = (finalecount - 10) // TEXTSPEED
    if count < 0 then
        count = 0
    end
    while count > 0 do
        count = count - 1
        c = string.byte(finaletext, ch)
        ch = ch + 1
        if not c or c == 0 then
            break
        end
        if c == 10 then -- '\n'
            cx = 10
            cy = cy + 11
            -- continue
        else
            c = string.byte(string.upper(string.char(c))) - HU_FONTSTART
            if c < 0 or c > HU_FONTSIZE then
                cx = cx + 4
                -- continue
            else
                local glyph = hu_stuff.hu_font[c + 1]
                if glyph == nil then
                    cx = cx + 4
                else
                    w = buffer.readi16(glyph.buffer, glyph.offset)
                    if cx + w > SCREENWIDTH then
                        break
                    end
                    v_video.V_DrawPatch(cx, cy, glyph)
                    cx = cx + w
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Cast (Final DOOM 2 animation)
-- ---------------------------------------------------------------------------

local castorder = {
    { name = dstrings.CC_ZOMBIE, type = info.mobjtype.MT_POSSESSED },
    { name = dstrings.CC_SHOTGUN, type = info.mobjtype.MT_SHOTGUY },
    { name = dstrings.CC_HEAVY, type = info.mobjtype.MT_CHAINGUY },
    { name = dstrings.CC_IMP, type = info.mobjtype.MT_TROOP },
    { name = dstrings.CC_DEMON, type = info.mobjtype.MT_SERGEANT },
    { name = dstrings.CC_LOST, type = info.mobjtype.MT_SKULL },
    { name = dstrings.CC_CACO, type = info.mobjtype.MT_HEAD },
    { name = dstrings.CC_HELL, type = info.mobjtype.MT_KNIGHT },
    { name = dstrings.CC_BARON, type = info.mobjtype.MT_BRUISER },
    { name = dstrings.CC_ARACH, type = info.mobjtype.MT_BABY },
    { name = dstrings.CC_PAIN, type = info.mobjtype.MT_PAIN },
    { name = dstrings.CC_REVEN, type = info.mobjtype.MT_UNDEAD },
    { name = dstrings.CC_MANCU, type = info.mobjtype.MT_FATSO },
    { name = dstrings.CC_ARCH, type = info.mobjtype.MT_VILE },
    { name = dstrings.CC_SPIDER, type = info.mobjtype.MT_SPIDER },
    { name = dstrings.CC_CYBER, type = info.mobjtype.MT_CYBORG },
    { name = dstrings.CC_HERO, type = info.mobjtype.MT_PLAYER },
}

local castnum = 0
local casttics = 0
local caststate = nil
local castdeath = false
local castframes = 0
local castonmelee = 0
local castattacking = false

-- FF_FRAMEMASK = 0x7fff (r_state).
local FF_FRAMEMASK = r_state.FF_FRAMEMASK

function f_finale.F_StartCast()
    doomstat.wipegamestate = -1 -- force a screen wipe
    castnum = 0
    caststate = info.states[info.mobjinfo[castorder[1].type + 1].seestate + 1]
    casttics = caststate.tics
    castdeath = false
    finalestage = F_STAGE_CAST
    castframes = 0
    castonmelee = 0
    castattacking = false
    s_sound.S_ChangeMusic(0, true)
end

function f_finale.F_CastTicker()
    local st
    local sfx

    casttics = casttics - 1
    if casttics > 0 then
        return -- not time to change state yet
    end

    if caststate.tics == -1 or caststate.nextstate == 0 then -- S_NULL
        -- Switch from deathstate to next monster.
        castnum = castnum + 1
        castdeath = false
        if castorder[castnum + 1] == nil then
            castnum = 0
        end
        if info.mobjinfo[castorder[castnum + 1].type + 1].seesound ~= 0 then
            s_sound.S_StartSound(nil,
                info.mobjinfo[castorder[castnum + 1].type + 1].seesound)
        end
        caststate = info.states[info.mobjinfo[castorder[castnum + 1].type + 1].seestate + 1]
        castframes = 0
    else
        -- Just advance to next state in animation.
        if caststate == info.states[info.statenum.S_PLAY_ATK1 + 1] then
            -- Oh, gross hack! (goto stopattack)
            castattacking = false
            castframes = 0
            caststate = info.states[info.mobjinfo[castorder[castnum + 1].type + 1].seestate + 1]
        else
            st = caststate.nextstate
            caststate = info.states[st + 1]
            castframes = castframes + 1

            -- Sound hacks...
            sfx = 0
            if st == info.statenum.S_PLAY_ATK1 then
                sfx = sounds.sfxenum.sfx_dshtgn
            elseif st == info.statenum.S_POSS_ATK2 then
                sfx = sounds.sfxenum.sfx_pistol
            elseif st == info.statenum.S_SPOS_ATK2 then
                sfx = sounds.sfxenum.sfx_shotgn
            elseif st == info.statenum.S_VILE_ATK2 then
                sfx = sounds.sfxenum.sfx_vilatk
            elseif st == info.statenum.S_SKEL_FIST2 then
                sfx = sounds.sfxenum.sfx_skeswg
            elseif st == info.statenum.S_SKEL_FIST4 then
                sfx = sounds.sfxenum.sfx_skepch
            elseif st == info.statenum.S_SKEL_MISS2 then
                sfx = sounds.sfxenum.sfx_skeatk
            elseif st == info.statenum.S_FATT_ATK8
                or st == info.statenum.S_FATT_ATK5
                or st == info.statenum.S_FATT_ATK2 then
                sfx = sounds.sfxenum.sfx_firsht
            elseif st == info.statenum.S_CPOS_ATK2
                or st == info.statenum.S_CPOS_ATK3
                or st == info.statenum.S_CPOS_ATK4 then
                sfx = sounds.sfxenum.sfx_shotgn
            elseif st == info.statenum.S_TROO_ATK3 then
                sfx = sounds.sfxenum.sfx_claw
            elseif st == info.statenum.S_SARG_ATK2 then
                sfx = sounds.sfxenum.sfx_sgtatk
            elseif st == info.statenum.S_BOSS_ATK2
                or st == info.statenum.S_BOS2_ATK2
                or st == info.statenum.S_HEAD_ATK2 then
                sfx = sounds.sfxenum.sfx_firsht
            elseif st == info.statenum.S_SKULL_ATK2 then
                sfx = sounds.sfxenum.sfx_sklatk
            elseif st == info.statenum.S_SPID_ATK2
                or st == info.statenum.S_SPID_ATK3 then
                sfx = sounds.sfxenum.sfx_shotgn
            elseif st == info.statenum.S_BSPI_ATK2 then
                sfx = sounds.sfxenum.sfx_plasma
            elseif st == info.statenum.S_CYBER_ATK2
                or st == info.statenum.S_CYBER_ATK4
                or st == info.statenum.S_CYBER_ATK6 then
                sfx = sounds.sfxenum.sfx_rlaunc
            elseif st == info.statenum.S_PAIN_ATK3 then
                sfx = sounds.sfxenum.sfx_sklatk
            else
                sfx = 0
            end

            if sfx ~= 0 then
                s_sound.S_StartSound(nil, sfx)
            end
        end
    end

    if castframes == 12 then
        -- Go into attack frame.
        castattacking = true
        if castonmelee ~= 0 then
            caststate = info.states[info.mobjinfo[castorder[castnum + 1].type + 1].meleestate + 1]
        else
            caststate = info.states[info.mobjinfo[castorder[castnum + 1].type + 1].missilestate + 1]
        end
        castonmelee = bit32.bxor(castonmelee, 1)
        if caststate == info.states[1] then -- S_NULL
            if castonmelee ~= 0 then
                caststate = info.states[info.mobjinfo[castorder[castnum + 1].type + 1].meleestate + 1]
            else
                caststate = info.states[info.mobjinfo[castorder[castnum + 1].type + 1].missilestate + 1]
            end
        end
    end

    if castattacking then
        if castframes == 24
            or caststate == info.states[info.mobjinfo[castorder[castnum + 1].type + 1].seestate + 1] then
            castattacking = false
            castframes = 0
            caststate = info.states[info.mobjinfo[castorder[castnum + 1].type + 1].seestate + 1]
        end
    end

    casttics = caststate.tics
    if casttics == -1 then
        casttics = 15
    end
end

function f_finale.F_CastResponder(ev)
    if ev.type ~= 0 then -- ev_keydown
        return false
    end

    if castdeath then
        return true -- already in dying frames
    end

    -- Go into death frame.
    castdeath = true
    caststate = info.states[info.mobjinfo[castorder[castnum + 1].type + 1].deathstate + 1]
    casttics = caststate.tics
    castframes = 0
    castattacking = false
    if info.mobjinfo[castorder[castnum + 1].type + 1].deathsound ~= 0 then
        s_sound.S_StartSound(nil,
            info.mobjinfo[castorder[castnum + 1].type + 1].deathsound)
    end

    return true
end

local function F_CastPrint(text)
    local c
    local cx
    local w
    local width

    -- Find width.
    local ch = 1
    width = 0
    while ch <= #text do
        c = string.byte(text, ch)
        ch = ch + 1
        if not c or c == 0 then
            break
        end
        c = string.byte(string.upper(string.char(c))) - HU_FONTSTART
        if c < 0 or c > HU_FONTSIZE then
            width = width + 4
            -- continue
        else
            local glyph = hu_stuff.hu_font[c + 1]
            if glyph == nil then
                width = width + 4
            else
                w = buffer.readi16(glyph.buffer, glyph.offset)
                width = width + w
            end
        end
    end

    -- Draw it.
    cx = 160 - width // 2
    ch = 1
    while ch <= #text do
        c = string.byte(text, ch)
        ch = ch + 1
        if not c or c == 0 then
            break
        end
        c = string.byte(string.upper(string.char(c))) - HU_FONTSTART
        if c < 0 or c > HU_FONTSIZE then
            cx = cx + 4
            -- continue
        else
            local glyph = hu_stuff.hu_font[c + 1]
            if glyph == nil then
                cx = cx + 4
            else
                w = buffer.readi16(glyph.buffer, glyph.offset)
                v_video.V_DrawPatch(cx, 180, glyph)
                cx = cx + w
            end
        end
    end
end

local function F_CastDrawer()
    local sprdef
    local sprframe
    local lump
    local flip
    local patch

    -- Erase the entire screen to a background.
    v_video.V_DrawPatch(0, 0,
        w_wad.W_CacheLumpName(deh_str.DEH_String("BOSSBACK"), z_zone.PU_CACHE))

    F_CastPrint(deh_str.DEH_String(castorder[castnum + 1].name))

    -- Draw the current frame in the middle of the screen.
    sprdef = r_state.sprites[caststate.sprite + 1]
    sprframe = sprdef.spriteframes[bit32.band(caststate.frame, FF_FRAMEMASK) + 1]
    lump = sprframe.lump[1]
    flip = sprframe.flip[1]

    patch = w_wad.W_CacheLumpNum(lump + r_state.firstspritelump, z_zone.PU_CACHE)
    if flip then
        v_video.V_DrawPatchFlipped(160, 170, patch)
    else
        v_video.V_DrawPatch(160, 170, patch)
    end
end

-- ---------------------------------------------------------------------------
-- F_DrawPatchCol
-- ---------------------------------------------------------------------------

local function F_DrawPatchCol(x, patch, col)
    local column
    local source
    local dest
    local desttop
    local count

    local pb = patch.buffer
    local base = patch.offset
    column = base + buffer.readi32(pb, base + 8 + col * 4)
    desttop = x -- byte offset into I_VideoBuffer (column x)

    -- Step through the posts in a column.
    while buffer.readu8(pb, column) ~= 0xff do
        source = column + 3
        dest = desttop + buffer.readu8(pb, column) * SCREENWIDTH
        count = buffer.readu8(pb, column + 1)

        while count > 0 do
            buffer.writeu8(i_video.I_VideoBuffer, dest,
                buffer.readu8(pb, source))
            dest = dest + SCREENWIDTH
            source = source + 1
            count = count - 1
        end
        column = column + buffer.readu8(pb, column + 1) + 4
    end
end

-- ---------------------------------------------------------------------------
-- F_BunnyScroll
-- ---------------------------------------------------------------------------

local laststage = 0

local function F_BunnyScroll()
    local scrolled
    local x
    local p1
    local p2
    local stage

    p1 = w_wad.W_CacheLumpName(deh_str.DEH_String("PFUB2"), z_zone.PU_LEVEL)
    p2 = w_wad.W_CacheLumpName(deh_str.DEH_String("PFUB1"), z_zone.PU_LEVEL)

    v_video.V_MarkRect(0, 0, SCREENWIDTH, SCREENHEIGHT)

    scrolled = (320 - (finalecount - 230) // 2)
    if scrolled > 320 then
        scrolled = 320
    end
    if scrolled < 0 then
        scrolled = 0
    end

    for x = 0, SCREENWIDTH - 1 do
        if x + scrolled < 320 then
            F_DrawPatchCol(x, p1, x + scrolled)
        else
            F_DrawPatchCol(x, p2, x + scrolled - 320)
        end
    end

    if finalecount < 1130 then
        return
    end
    if finalecount < 1180 then
        v_video.V_DrawPatch((SCREENWIDTH - 13 * 8) // 2,
            (SCREENHEIGHT - 8 * 8) // 2,
            w_wad.W_CacheLumpName(deh_str.DEH_String("END0"), z_zone.PU_CACHE))
        laststage = 0
        return
    end

    stage = (finalecount - 1180) // 5
    if stage > 6 then
        stage = 6
    end
    if stage > laststage then
        s_sound.S_StartSound(nil, 1) -- sfx_pistol
        laststage = stage
    end

    local name = deh_str.DEH_snprintf("END%i", stage)
    v_video.V_DrawPatch((SCREENWIDTH - 13 * 8) // 2,
        (SCREENHEIGHT - 8 * 8) // 2,
        w_wad.W_CacheLumpName(name, z_zone.PU_CACHE))
end

local function F_ArtScreenDrawer()
    local lumpname

    if doomstat.gameepisode == 3 then
        F_BunnyScroll()
    else
        if doomstat.gameepisode == 1 then
            if doomstat.gamemode == d_mode.retail then
                lumpname = "CREDIT"
            else
                lumpname = "HELP2"
            end
        elseif doomstat.gameepisode == 2 then
            lumpname = "VICTORY2"
        elseif doomstat.gameepisode == 4 then
            lumpname = "ENDPIC"
        else
            return
        end

        lumpname = deh_str.DEH_String(lumpname)

        v_video.V_DrawPatch(0, 0,
            w_wad.W_CacheLumpName(lumpname, z_zone.PU_CACHE))
    end
end

-- ---------------------------------------------------------------------------
-- F_Drawer
-- ---------------------------------------------------------------------------

function f_finale.F_Drawer()
    if finalestage == F_STAGE_CAST then
        F_CastDrawer()
    elseif finalestage == F_STAGE_TEXT then
        F_TextWrite()
    elseif finalestage == F_STAGE_ARTSCREEN then
        F_ArtScreenDrawer()
    end
end

return f_finale
end)()

am_map = (function()
local am_map = {}

local SCREENWIDTH = 320
local SCREENHEIGHT = 200

local FRACUNIT = doomtype.FRACUNIT
local FRACBITS = doomtype.FRACBITS
local ANGLETOFINESHIFT = doomtype.ANGLETOFINESHIFT

local INT_MAX = 2147483647

-- Automap colors.
local REDS = 256 - 5 * 16 -- 176
local REDRANGE = 16
local WALLRANGE = REDRANGE
local BLUES = 256 - 4 * 16 + 8 -- 200
local BLUERANGE = 8
local GREENS = 7 * 16 -- 112
local GREENRANGE = 16
local GRAYS = 6 * 16 -- 96
local GRAYSRANGE = 16
local BROWNS = 4 * 16 -- 64
local BROWNRANGE = 16
local YELLOWS = 256 - 32 + 7 -- 231
local YELLOWRANGE = 1
local BLACK = 0
local WHITE = 256 - 47 -- 209

local BACKGROUND = BLACK
local YOURCOLORS = WHITE
local WALLCOLORS = REDS
local TSWALLCOLORS = GRAYS
local FDWALLCOLORS = BROWNS
local CDWALLCOLORS = YELLOWS
local THINGCOLORS = GREENS
local GRIDCOLORS = GRAYS + GRAYSRANGE // 2 -- 104
local XHAIRCOLORS = GRAYS

local AM_NUMMARKPOINTS = 10

-- C float -> int cast: truncate toward zero (used for the scale / zoom
-- constants below; defined here so it is in scope for the module init).
local function trunc_f(v)
    if v < 0 then
        return math.ceil(v)
    end
    return math.floor(v)
end

-- Scale on entry.
local INITSCALEMTOF = trunc_f(0.2 * FRACUNIT) -- 13107 (C int cast)
-- How much the automap moves window per tic (140 pixels in 1 second).
local F_PANINC = 4
-- Zoom in / out per tic.
local M_ZOOMIN = 1.02 * FRACUNIT -- 66846
local M_ZOOMOUT = FRACUNIT / 1.02 -- 64250

-- LINE_NEVERSEE = ML_DONTDRAW (doomdata.h).
local LINE_NEVERSEE = 128

-- PLAYERRADIUS (p_local.h).
local PLAYERRADIUS = 16 * FRACUNIT
-- MAPBLOCKUNITS (p_local.h).
local MAPBLOCKUNITS = 128

-- State referenced by the FTOM / MTOF translations below. Declared here so
-- the helper functions see them as upvalues (the C statics live later in
-- this module but are in scope for the whole file).

-- Location / size of window on screen.
local f_x = 0
local f_y = 0
local f_w = 0
local f_h = 0

-- LL / UR x,y where the window is on the map (map coords).
local m_x = 0
local m_y = 0
local m_x2 = 0
local m_y2 = 0

-- Used by MTOF to scale from map-to-frame-buffer coords.
local scale_mtof = INITSCALEMTOF
-- Used by FTOM to scale from frame-buffer-to-map coords (=1/scale_mtof).
local scale_ftom = 0

-- FTOM / MTOF translations.
local function FTOM(x)
    return m_fixed.FixedMul(x * 65536, scale_ftom)
end
local function MTOF(x)
    return math.floor(m_fixed.FixedMul(x, scale_mtof) / 65536)
end
local function CXMTOF(x)
    return f_x + MTOF(x - m_x)
end
local function CYMTOF(y)
    return f_y + (f_h - MTOF(y - m_y))
end

-- C remainder operator (sign of dividend), for the grid alignment modulo.
local function c_rem(a, b)
    return a - doomtype.truncdiv(a, b) * b
end

-- ---------------------------------------------------------------------------
-- Automap message header (am_map.h), used by ST_Responder.
-- ---------------------------------------------------------------------------

am_map.AM_MSGHEADER = 0x616d0000 -- ('a'<<24)+('m'<<16)
am_map.AM_MSGENTERED = am_map.AM_MSGHEADER + 0x6500 -- | ('e'<<8)
am_map.AM_MSGEXITED = am_map.AM_MSGHEADER + 0x7800 -- | ('x'<<8)

-- ---------------------------------------------------------------------------
-- Vector graphics for the automap (the C mline_t tables).
-- ---------------------------------------------------------------------------

-- Player arrow (line drawing of the player pointing right).
local function player_arrow_lines()
    local R = (8 * PLAYERRADIUS) // 7
    local R2 = R // 2
    local R4 = R // 4
    local R8 = R // 8
    local R38 = (3 * R) // 8
    return {
        { a = { -R + R8, 0 }, b = { R, 0 } }, -- -----
        { a = { R, 0 }, b = { R - R2, R4 } }, -- ----->
        { a = { R, 0 }, b = { R - R2, -R4 } },
        { a = { -R + R8, 0 }, b = { -R - R8, R4 } }, -- >---->
        { a = { -R + R8, 0 }, b = { -R - R8, -R4 } },
        { a = { -R + R38, 0 }, b = { -R + R8, R4 } }, -- >>--->
        { a = { -R + R38, 0 }, b = { -R + R8, -R4 } },
    }
end

local function cheat_player_arrow_lines()
    local R = (8 * PLAYERRADIUS) // 7
    local R2 = R // 2
    local R4 = R // 4
    local R6 = R // 6
    local R7 = R // 7
    local R8 = R // 8
    local R32 = R // 32
    local R10 = R // 10
    local R38 = (3 * R) // 8
    return {
        { a = { -R + R8, 0 }, b = { R, 0 } }, -- -----
        { a = { R, 0 }, b = { R - R2, R6 } }, -- ----->
        { a = { R, 0 }, b = { R - R2, -R6 } },
        { a = { -R + R8, 0 }, b = { -R - R8, R6 } }, -- >----->
        { a = { -R + R8, 0 }, b = { -R - R8, -R6 } },
        { a = { -R + R38, 0 }, b = { -R + R8, R6 } }, -- >>----->
        { a = { -R + R38, 0 }, b = { -R + R8, -R6 } },
        { a = { -R2, 0 }, b = { -R2, -R6 } }, -- >>-d--->
        { a = { -R2, -R6 }, b = { -R2 + R6, -R6 } },
        { a = { -R2 + R6, -R6 }, b = { -R2 + R6, R4 } },
        { a = { -R6, 0 }, b = { -R6, -R6 } }, -- >>-dd-->
        { a = { -R6, -R6 }, b = { 0, -R6 } },
        { a = { 0, -R6 }, b = { 0, R4 } },
        { a = { R6, R4 }, b = { R6, -R7 } }, -- >>-ddt->
        { a = { R6, -R7 }, b = { R6 + R32, -R7 - R32 } },
        { a = { R6 + R32, -R7 - R32 }, b = { R6 + R10, -R7 } },
    }
end

-- Triangle guy (things).
local function triangle_guy_lines()
    local R = FRACUNIT
    local n867 = trunc_f(-0.867 * R)
    local p867 = trunc_f(0.867 * R)
    local n5 = trunc_f(-0.5 * R)
    local p5 = trunc_f(0.5 * R)
    return {
        { a = { n867, n5 }, b = { p867, n5 } },
        { a = { p867, n5 }, b = { 0, R } },
        { a = { 0, R }, b = { n867, n5 } },
    }
end

-- Thin triangle guy (things, cheat mode).
local function thintriangle_guy_lines()
    local R = FRACUNIT
    local n5 = trunc_f(-0.5 * R)
    local n7 = trunc_f(-0.7 * R)
    local p7 = trunc_f(0.7 * R)
    return {
        { a = { n5, n7 }, b = { R, 0 } },
        { a = { R, 0 }, b = { n5, p7 } },
        { a = { n5, p7 }, b = { n5, n7 } },
    }
end

local player_arrow = player_arrow_lines()
local cheat_player_arrow = cheat_player_arrow_lines()
local triangle_guy = triangle_guy_lines()
local thintriangle_guy = thintriangle_guy_lines()

-- ---------------------------------------------------------------------------
-- State (C statics)
-- ---------------------------------------------------------------------------

local cheating = 0
local grid = 0
local leveljuststarted = 1 -- kluge until AM_LevelInit() is called
local finit_width = SCREENWIDTH
local finit_height = SCREENHEIGHT - 32

local lightlev = 0 -- used for funky strobing effect
local fb = nil -- pseudo-frame buffer
local amclock = 0

local m_paninc = { x = 0, y = 0 } -- how far the window pans each tic
local mtof_zoommul = 0 -- zoom per tic (map coords)
local ftom_zoommul = 0 -- zoom per tic (fb coords)

-- Width/height of window on map.
local m_w = 0
local m_h = 0

-- Based on level size.
local min_x = 0
local min_y = 0
local max_x = 0
local max_y = 0
local max_w = 0 -- max_x-min_x
local max_h = 0 -- max_y-min_y

-- Based on player size.
local min_w = 0
local min_h = 0

local min_scale_mtof = 0 -- used to tell when to stop zooming out
local max_scale_mtof = 0 -- used to tell when to stop zooming in

-- Old stuff for recovery later.
local old_m_w = 0
local old_m_h = 0
local old_m_x = 0
local old_m_y = 0

-- Old location used by the Follower routine.
local f_oldloc = { x = INT_MAX, y = 0 }

local plr = nil -- the player represented by an arrow

local marknums = {} -- numbers used for marking by the automap
local markpoints = {} -- where the points are
local markpointnum = 0 -- next point to be assigned

local followplayer = 1 -- specifies whether to follow the player around

local cheat_amap = m_cheat.CHEAT("iddt", 0)

local stopped = true

-- ---------------------------------------------------------------------------
-- Scale / location helpers
-- ---------------------------------------------------------------------------

local function AM_activateNewScale()
    m_x = m_x + m_w // 2
    m_y = m_y + m_h // 2
    m_w = FTOM(f_w)
    m_h = FTOM(f_h)
    m_x = m_x - m_w // 2
    m_y = m_y - m_h // 2
    m_x2 = m_x + m_w
    m_y2 = m_y + m_h
end

local function AM_saveScaleAndLoc()
    old_m_x = m_x
    old_m_y = m_y
    old_m_w = m_w
    old_m_h = m_h
end

local function AM_restoreScaleAndLoc()
    m_w = old_m_w
    m_h = old_m_h
    if followplayer == 0 then
        m_x = old_m_x
        m_y = old_m_y
    else
        m_x = plr.mo.x - m_w // 2
        m_y = plr.mo.y - m_h // 2
    end
    m_x2 = m_x + m_w
    m_y2 = m_y + m_h

    -- Change the scaling multipliers.
    scale_mtof = m_fixed.FixedDiv(f_w * 65536, m_w)
    scale_ftom = m_fixed.FixedDiv(FRACUNIT, scale_mtof)
end

local function AM_addMark()
    markpoints[markpointnum + 1] = { x = m_x + m_w // 2, y = m_y + m_h // 2 }
    markpointnum = (markpointnum + 1) % AM_NUMMARKPOINTS
end

-- ---------------------------------------------------------------------------
-- AM_findMinMaxBoundaries
-- ---------------------------------------------------------------------------

local function AM_findMinMaxBoundaries()
    local i
    local a
    local b

    min_x = INT_MAX
    min_y = INT_MAX
    max_x = -INT_MAX
    max_y = -INT_MAX

    for i = 1, r_state.numvertexes do
        local v = r_state.vertexes[i]
        if v.x < min_x then
            min_x = v.x
        elseif v.x > max_x then
            max_x = v.x
        end
        if v.y < min_y then
            min_y = v.y
        elseif v.y > max_y then
            max_y = v.y
        end
    end

    max_w = max_x - min_x
    max_h = max_y - min_y

    min_w = 2 * PLAYERRADIUS -- const? never changed?
    min_h = 2 * PLAYERRADIUS

    a = m_fixed.FixedDiv(f_w * 65536, max_w)
    b = m_fixed.FixedDiv(f_h * 65536, max_h)

    if a < b then
        min_scale_mtof = a
    else
        min_scale_mtof = b
    end
    max_scale_mtof = m_fixed.FixedDiv(f_h * 65536, 2 * PLAYERRADIUS)
end

-- ---------------------------------------------------------------------------
-- AM_changeWindowLoc
-- ---------------------------------------------------------------------------

local function AM_changeWindowLoc()
    if m_paninc.x ~= 0 or m_paninc.y ~= 0 then
        followplayer = 0
        f_oldloc.x = INT_MAX
    end

    m_x = m_x + m_paninc.x
    m_y = m_y + m_paninc.y

    if m_x + m_w // 2 > max_x then
        m_x = max_x - m_w // 2
    elseif m_x + m_w // 2 < min_x then
        m_x = min_x - m_w // 2
    end

    if m_y + m_h // 2 > max_y then
        m_y = max_y - m_h // 2
    elseif m_y + m_h // 2 < min_y then
        m_y = min_y - m_h // 2
    end

    m_x2 = m_x + m_w
    m_y2 = m_y + m_h
end

-- ---------------------------------------------------------------------------
-- AM_initVariables
-- ---------------------------------------------------------------------------

local function AM_initVariables()
    local pnum

    doomstat.automapactive = true
    fb = i_video.I_VideoBuffer

    f_oldloc.x = INT_MAX
    amclock = 0
    lightlev = 0

    m_paninc.x = 0
    m_paninc.y = 0
    ftom_zoommul = FRACUNIT
    mtof_zoommul = FRACUNIT

    m_w = FTOM(f_w)
    m_h = FTOM(f_h)

    -- Find player to center on initially.
    if doomstat.playeringame[doomstat.consoleplayer + 1] then
        plr = doomstat.players[doomstat.consoleplayer + 1]
    else
        plr = doomstat.players[1]
        for pnum = 1, doomtype.MAXPLAYERS do
            if doomstat.playeringame[pnum] then
                plr = doomstat.players[pnum]
                break
            end
        end
    end

    m_x = plr.mo.x - m_w // 2
    m_y = plr.mo.y - m_h // 2
    AM_changeWindowLoc()

    -- For saving & restoring.
    old_m_x = m_x
    old_m_y = m_y
    old_m_w = m_w
    old_m_h = m_h

    -- Inform the status bar of the change.
    st_stuff.ST_Responder({
        type = 1, -- ev_keyup
        data1 = am_map.AM_MSGENTERED, data2 = 0, data3 = 0, data4 = 0,
    })
end

-- ---------------------------------------------------------------------------
-- AM_loadPics / AM_unloadPics / AM_clearMarks
-- ---------------------------------------------------------------------------

local function AM_loadPics()
    for i = 0, 9 do
        local namebuf = deh_str.DEH_snprintf("AMMNUM%d", i)
        marknums[i + 1] = w_wad.W_CacheLumpName(namebuf, z_zone.PU_STATIC)
    end
end

local function AM_unloadPics()
    for i = 0, 9 do
        local namebuf = deh_str.DEH_snprintf("AMMNUM%d", i)
        w_wad.W_ReleaseLumpName(namebuf)
    end
end

local function AM_clearMarks()
    for i = 1, AM_NUMMARKPOINTS do
        markpoints[i] = { x = -1, y = 0 } -- x == -1 means empty
    end
    markpointnum = 0
end

-- ---------------------------------------------------------------------------
-- AM_LevelInit
-- ---------------------------------------------------------------------------

local function AM_LevelInit()
    leveljuststarted = 0

    f_x = 0
    f_y = 0
    f_w = finit_width
    f_h = finit_height

    AM_clearMarks()

    AM_findMinMaxBoundaries()
    scale_mtof = m_fixed.FixedDiv(min_scale_mtof, trunc_f(0.7 * FRACUNIT))
    if scale_mtof > max_scale_mtof then
        scale_mtof = min_scale_mtof
    end
    scale_ftom = m_fixed.FixedDiv(FRACUNIT, scale_mtof)
end

-- ---------------------------------------------------------------------------
-- AM_Stop / AM_Start
-- ---------------------------------------------------------------------------

function am_map.AM_Stop()
    AM_unloadPics()
    doomstat.automapactive = false
    st_stuff.ST_Responder({
        type = 0, -- ev_keydown (C's odd initializer order: {0, ev_keyup, AM_MSGEXITED, 0})
        data1 = 1, data2 = am_map.AM_MSGEXITED, data3 = 0, data4 = 0,
    })
    stopped = true
end

local lastlevel = -1
local lastepisode = -1

function am_map.AM_Start()
    if not stopped then
        am_map.AM_Stop()
    end
    stopped = false
    if lastlevel ~= doomstat.gamemap or lastepisode ~= doomstat.gameepisode then
        AM_LevelInit()
        lastlevel = doomstat.gamemap
        lastepisode = doomstat.gameepisode
    end
    AM_initVariables()
    AM_loadPics()
end

-- ---------------------------------------------------------------------------
-- Scale window helpers
-- ---------------------------------------------------------------------------

local function AM_minOutWindowScale()
    scale_mtof = min_scale_mtof
    scale_ftom = m_fixed.FixedDiv(FRACUNIT, scale_mtof)
    AM_activateNewScale()
end

local function AM_maxOutWindowScale()
    scale_mtof = max_scale_mtof
    scale_ftom = m_fixed.FixedDiv(FRACUNIT, scale_mtof)
    AM_activateNewScale()
end

-- ---------------------------------------------------------------------------
-- AM_Responder
-- ---------------------------------------------------------------------------

local bigstate = 0 -- C static int in AM_Responder

function am_map.AM_Responder(ev)
    local rc = false
    local buffer = ""
    local key

    if not doomstat.automapactive then
        if ev.type == 0 -- ev_keydown
            and ev.data1 == m_controls.key_map_toggle then
            am_map.AM_Start()
            doomstat.viewactive = false
            rc = true
        end
    elseif ev.type == 0 then -- ev_keydown
        rc = true
        key = ev.data1

        if key == m_controls.key_map_east then -- pan right
            if followplayer == 0 then
                m_paninc.x = FTOM(F_PANINC)
            else
                rc = false
            end
        elseif key == m_controls.key_map_west then -- pan left
            if followplayer == 0 then
                m_paninc.x = -FTOM(F_PANINC)
            else
                rc = false
            end
        elseif key == m_controls.key_map_north then -- pan up
            if followplayer == 0 then
                m_paninc.y = FTOM(F_PANINC)
            else
                rc = false
            end
        elseif key == m_controls.key_map_south then -- pan down
            if followplayer == 0 then
                m_paninc.y = -FTOM(F_PANINC)
            else
                rc = false
            end
        elseif key == m_controls.key_map_zoomout then -- zoom out
            mtof_zoommul = trunc_f(M_ZOOMOUT)
            ftom_zoommul = trunc_f(M_ZOOMIN)
        elseif key == m_controls.key_map_zoomin then -- zoom in
            mtof_zoommul = trunc_f(M_ZOOMIN)
            ftom_zoommul = trunc_f(M_ZOOMOUT)
        elseif key == m_controls.key_map_toggle then
            bigstate = 0
            doomstat.viewactive = true
            am_map.AM_Stop()
        elseif key == m_controls.key_map_maxzoom then
            bigstate = bigstate == 0 and 1 or 0
            if bigstate ~= 0 then
                AM_saveScaleAndLoc()
                AM_minOutWindowScale()
            else
                AM_restoreScaleAndLoc()
            end
        elseif key == m_controls.key_map_follow then
            followplayer = followplayer == 0 and 1 or 0
            f_oldloc.x = INT_MAX
            if followplayer ~= 0 then
                plr.message = deh_str.DEH_String(dstrings.AMSTR_FOLLOWON)
            else
                plr.message = deh_str.DEH_String(dstrings.AMSTR_FOLLOWOFF)
            end
        elseif key == m_controls.key_map_grid then
            grid = grid == 0 and 1 or 0
            if grid ~= 0 then
                plr.message = deh_str.DEH_String(dstrings.AMSTR_GRIDON)
            else
                plr.message = deh_str.DEH_String(dstrings.AMSTR_GRIDOFF)
            end
        elseif key == m_controls.key_map_mark then
            local b = m_misc.M_snprintf("%s %d",
                deh_str.DEH_String(dstrings.AMSTR_MARKEDSPOT), markpointnum)
            plr.message = b
            AM_addMark()
        elseif key == m_controls.key_map_clearmark then
            AM_clearMarks()
            plr.message = deh_str.DEH_String(dstrings.AMSTR_MARKSCLEARED)
        else
            rc = false
        end

        if doomstat.deathmatch == 0 and m_cheat.cht_CheckCheat(cheat_amap, ev.data2) then
            rc = false
            cheating = (cheating + 1) % 3
        end
    elseif ev.type == 1 then -- ev_keyup
        rc = false
        key = ev.data1

        if key == m_controls.key_map_east then
            if followplayer == 0 then
                m_paninc.x = 0
            end
        elseif key == m_controls.key_map_west then
            if followplayer == 0 then
                m_paninc.x = 0
            end
        elseif key == m_controls.key_map_north then
            if followplayer == 0 then
                m_paninc.y = 0
            end
        elseif key == m_controls.key_map_south then
            if followplayer == 0 then
                m_paninc.y = 0
            end
        elseif key == m_controls.key_map_zoomout or key == m_controls.key_map_zoomin then
            mtof_zoommul = FRACUNIT
            ftom_zoommul = FRACUNIT
        end
    end

    return rc
end

-- ---------------------------------------------------------------------------
-- Zooming
-- ---------------------------------------------------------------------------

local function AM_changeWindowScale()
    -- Change the scaling multipliers.
    scale_mtof = m_fixed.FixedMul(scale_mtof, mtof_zoommul)
    scale_ftom = m_fixed.FixedDiv(FRACUNIT, scale_mtof)

    if scale_mtof < min_scale_mtof then
        AM_minOutWindowScale()
    elseif scale_mtof > max_scale_mtof then
        AM_maxOutWindowScale()
    else
        AM_activateNewScale()
    end
end

local function AM_doFollowPlayer()
    if f_oldloc.x ~= plr.mo.x or f_oldloc.y ~= plr.mo.y then
        m_x = FTOM(MTOF(plr.mo.x)) - m_w // 2
        m_y = FTOM(MTOF(plr.mo.y)) - m_h // 2
        m_x2 = m_x + m_w
        m_y2 = m_y + m_h
        f_oldloc.x = plr.mo.x
        f_oldloc.y = plr.mo.y
    end
end

-- ---------------------------------------------------------------------------
-- AM_Ticker
-- ---------------------------------------------------------------------------

function am_map.AM_Ticker()
    if not doomstat.automapactive then
        return
    end

    amclock = amclock + 1

    if followplayer ~= 0 then
        AM_doFollowPlayer()
    end

    -- Change the zoom if necessary.
    if ftom_zoommul ~= FRACUNIT then
        AM_changeWindowScale()
    end

    -- Change x,y location.
    if m_paninc.x ~= 0 or m_paninc.y ~= 0 then
        AM_changeWindowLoc()
    end

    -- Update light level (the C calls AM_updateLightLev, which is disabled).
end

-- ---------------------------------------------------------------------------
-- Drawing
-- ---------------------------------------------------------------------------

local function AM_clearFB(color)
    buffer.fill(fb, 0, f_w * f_h, color)
end

-- Automap clipping of lines (Cohen-Sutherland with precalculated slopes).
local LEFT = 1
local RIGHT = 2
local BOTTOM = 4
local TOP = 8

local function AM_clipMline(ml, fl)
    local outcode1 = 0
    local outcode2 = 0
    local outside
    local tmp = { x = 0, y = 0 }
    local dx
    local dy

    -- Do trivial rejects and outcodes.
    if ml.a.y > m_y2 then
        outcode1 = TOP
    elseif ml.a.y < m_y then
        outcode1 = BOTTOM
    end

    if ml.b.y > m_y2 then
        outcode2 = TOP
    elseif ml.b.y < m_y then
        outcode2 = BOTTOM
    end

    if bit32.band(outcode1, outcode2) ~= 0 then
        return false -- trivially outside
    end

    if ml.a.x < m_x then
        outcode1 = bit32.bor(outcode1, LEFT)
    elseif ml.a.x > m_x2 then
        outcode1 = bit32.bor(outcode1, RIGHT)
    end

    if ml.b.x < m_x then
        outcode2 = bit32.bor(outcode2, LEFT)
    elseif ml.b.x > m_x2 then
        outcode2 = bit32.bor(outcode2, RIGHT)
    end

    if bit32.band(outcode1, outcode2) ~= 0 then
        return false -- trivially outside
    end

    -- Transform to frame-buffer coordinates.
    fl.a.x = CXMTOF(ml.a.x)
    fl.a.y = CYMTOF(ml.a.y)
    fl.b.x = CXMTOF(ml.b.x)
    fl.b.y = CYMTOF(ml.b.y)

    -- DOOUTCODE(outcode1, fl.a.x, fl.a.y)
    outcode1 = 0
    if fl.a.y < 0 then
        outcode1 = bit32.bor(outcode1, TOP)
    elseif fl.a.y >= f_h then
        outcode1 = bit32.bor(outcode1, BOTTOM)
    end
    if fl.a.x < 0 then
        outcode1 = bit32.bor(outcode1, LEFT)
    elseif fl.a.x >= f_w then
        outcode1 = bit32.bor(outcode1, RIGHT)
    end

    -- DOOUTCODE(outcode2, fl.b.x, fl.b.y)
    outcode2 = 0
    if fl.b.y < 0 then
        outcode2 = bit32.bor(outcode2, TOP)
    elseif fl.b.y >= f_h then
        outcode2 = bit32.bor(outcode2, BOTTOM)
    end
    if fl.b.x < 0 then
        outcode2 = bit32.bor(outcode2, LEFT)
    elseif fl.b.x >= f_w then
        outcode2 = bit32.bor(outcode2, RIGHT)
    end

    if bit32.band(outcode1, outcode2) ~= 0 then
        return false
    end

    while bit32.bor(outcode1, outcode2) ~= 0 do
        -- May be partially inside box; find an outside point.
        if outcode1 ~= 0 then
            outside = outcode1
        else
            outside = outcode2
        end

        -- Clip to each side.
        if bit32.band(outside, TOP) ~= 0 then
            dy = fl.a.y - fl.b.y
            dx = fl.b.x - fl.a.x
            tmp.x = fl.a.x + doomtype.truncdiv(dx * fl.a.y, dy)
            tmp.y = 0
        elseif bit32.band(outside, BOTTOM) ~= 0 then
            dy = fl.a.y - fl.b.y
            dx = fl.b.x - fl.a.x
            tmp.x = fl.a.x + doomtype.truncdiv(dx * (fl.a.y - f_h), dy)
            tmp.y = f_h - 1
        elseif bit32.band(outside, RIGHT) ~= 0 then
            dy = fl.b.y - fl.a.y
            dx = fl.b.x - fl.a.x
            tmp.y = fl.a.y + doomtype.truncdiv(dy * (f_w - 1 - fl.a.x), dx)
            tmp.x = f_w - 1
        elseif bit32.band(outside, LEFT) ~= 0 then
            dy = fl.b.y - fl.a.y
            dx = fl.b.x - fl.a.x
            tmp.y = fl.a.y + doomtype.truncdiv(dy * (-fl.a.x), dx)
            tmp.x = 0
        else
            tmp.x = 0
            tmp.y = 0
        end

        if outside == outcode1 then
            fl.a.x = tmp.x
            fl.a.y = tmp.y
            -- DOOUTCODE(outcode1, fl.a.x, fl.a.y)
            outcode1 = 0
            if fl.a.y < 0 then
                outcode1 = bit32.bor(outcode1, TOP)
            elseif fl.a.y >= f_h then
                outcode1 = bit32.bor(outcode1, BOTTOM)
            end
            if fl.a.x < 0 then
                outcode1 = bit32.bor(outcode1, LEFT)
            elseif fl.a.x >= f_w then
                outcode1 = bit32.bor(outcode1, RIGHT)
            end
        else
            fl.b.x = tmp.x
            fl.b.y = tmp.y
            -- DOOUTCODE(outcode2, fl.b.x, fl.b.y)
            outcode2 = 0
            if fl.b.y < 0 then
                outcode2 = bit32.bor(outcode2, TOP)
            elseif fl.b.y >= f_h then
                outcode2 = bit32.bor(outcode2, BOTTOM)
            end
            if fl.b.x < 0 then
                outcode2 = bit32.bor(outcode2, LEFT)
            elseif fl.b.x >= f_w then
                outcode2 = bit32.bor(outcode2, RIGHT)
            end
        end

        if bit32.band(outcode1, outcode2) ~= 0 then
            return false -- trivially outside
        end
    end

    return true
end

-- Classic Bresenham line drawing (with whatever optimizations needed for
-- speed).
local function AM_drawFline(fl, color)
    local x
    local y
    local dx
    local dy
    local sx
    local sy
    local ax
    local ay
    local d

    -- For debugging only: reject lines whose endpoints are out of bounds.
    if fl.a.x < 0 or fl.a.x >= f_w
        or fl.a.y < 0 or fl.a.y >= f_h
        or fl.b.x < 0 or fl.b.x >= f_w
        or fl.b.y < 0 or fl.b.y >= f_h then
        return
    end

    dx = fl.b.x - fl.a.x
    ax = 2 * (dx < 0 and -dx or dx)
    sx = dx < 0 and -1 or 1

    dy = fl.b.y - fl.a.y
    ay = 2 * (dy < 0 and -dy or dy)
    sy = dy < 0 and -1 or 1

    x = fl.a.x
    y = fl.a.y

    if ax > ay then
        d = ay - ax // 2
        while true do
            buffer.writeu8(fb, y * f_w + x, color)
            if x == fl.b.x then
                return
            end
            if d >= 0 then
                y = y + sy
                d = d - ax
            end
            x = x + sx
            d = d + ay
        end
    else
        d = ax - ay // 2
        while true do
            buffer.writeu8(fb, y * f_w + x, color)
            if y == fl.b.y then
                return
            end
            if d >= 0 then
                x = x + sx
                d = d - ay
            end
            y = y + sy
            d = d + ax
        end
    end
end

-- Clip lines, draw visible parts of lines.
local function AM_drawMline(ml, color)
    local fl = { a = { x = 0, y = 0 }, b = { x = 0, y = 0 } }
    if AM_clipMline(ml, fl) then
        AM_drawFline(fl, color)
    end
end

-- Draws flat (floor/ceiling tile) aligned grid lines.
local function AM_drawGrid(color)
    local x
    local y
    local start
    local end_
    local ml = { a = { x = 0, y = 0 }, b = { x = 0, y = 0 } }
    local bsize = MAPBLOCKUNITS * 65536

    -- Figure out start of vertical gridlines.
    start = m_x
    if c_rem(start - r_state.bmaporgx, bsize) ~= 0 then
        start = start + bsize - c_rem(start - r_state.bmaporgx, bsize)
    end
    end_ = m_x + m_w

    -- Draw vertical gridlines.
    ml.a.y = m_y
    ml.b.y = m_y + m_h
    x = start
    while x < end_ do
        ml.a.x = x
        ml.b.x = x
        AM_drawMline(ml, color)
        x = x + bsize
    end

    -- Figure out start of horizontal gridlines.
    start = m_y
    if c_rem(start - r_state.bmaporgy, bsize) ~= 0 then
        start = start + bsize - c_rem(start - r_state.bmaporgy, bsize)
    end
    end_ = m_y + m_h

    -- Draw horizontal gridlines.
    ml.a.x = m_x
    ml.b.x = m_x + m_w
    y = start
    while y < end_ do
        ml.a.y = y
        ml.b.y = y
        AM_drawMline(ml, color)
        y = y + bsize
    end
end

-- Determines visible lines, draws them. This is LineDef based, not LineSeg
-- based.
local function AM_drawWalls()
    local i
    local l = { a = { x = 0, y = 0 }, b = { x = 0, y = 0 } }

    for i = 1, r_state.numlines do
        local line = r_state.lines[i]
        l.a.x = line.v1.x
        l.a.y = line.v1.y
        l.b.x = line.v2.x
        l.b.y = line.v2.y
        if cheating ~= 0 or bit32.band(line.flags, 256) ~= 0 then -- ML_MAPPED
            if bit32.band(line.flags, LINE_NEVERSEE) ~= 0 and cheating == 0 then
                -- continue
            elseif not line.backsector then
                AM_drawMline(l, WALLCOLORS + lightlev)
            else
                if line.special == 39 then -- teleporters
                    AM_drawMline(l, WALLCOLORS + WALLRANGE // 2)
                elseif bit32.band(line.flags, 32) ~= 0 then -- ML_SECRET
                    if cheating ~= 0 then
                        AM_drawMline(l, WALLCOLORS + lightlev)
                    else
                        AM_drawMline(l, WALLCOLORS + lightlev)
                    end
                elseif line.backsector.floorheight ~= line.frontsector.floorheight then
                    AM_drawMline(l, FDWALLCOLORS + lightlev) -- floor level change
                elseif line.backsector.ceilingheight ~= line.frontsector.ceilingheight then
                    AM_drawMline(l, CDWALLCOLORS + lightlev) -- ceiling level change
                elseif cheating ~= 0 then
                    AM_drawMline(l, TSWALLCOLORS + lightlev)
                end
            end
        elseif plr.powers[doomdef.pw_allmap + 1] then
            if bit32.band(line.flags, LINE_NEVERSEE) == 0 then
                AM_drawMline(l, GRAYS + 3)
            end
        end
    end
end

-- Rotation in 2D (used to rotate the player arrow line character).
local function AM_rotate(x, y, a)
    local idx = bit32.rshift(a, ANGLETOFINESHIFT)
    local cosine = tables.finesine[idx + 2048 + 1]
    local sine = tables.finesine[idx + 1]

    local sx = x
    local sy = y
    local tmpx = m_fixed.FixedMul(sx, cosine) - m_fixed.FixedMul(sy, sine)
    local tmpy = m_fixed.FixedMul(sx, sine) + m_fixed.FixedMul(sy, cosine)

    return tmpx, tmpy
end

local function AM_drawLineCharacter(lineguy, lineguylines, scale, angle, color, x, y)
    local i
    local l = { a = { x = 0, y = 0 }, b = { x = 0, y = 0 } }

    for i = 1, lineguylines do
        l.a.x = lineguy[i].a[1]
        l.a.y = lineguy[i].a[2]

        if scale ~= 0 then
            l.a.x = m_fixed.FixedMul(scale, l.a.x)
            l.a.y = m_fixed.FixedMul(scale, l.a.y)
        end

        if angle ~= 0 then
            l.a.x, l.a.y = AM_rotate(l.a.x, l.a.y, angle)
        end

        l.a.x = l.a.x + x
        l.a.y = l.a.y + y

        l.b.x = lineguy[i].b[1]
        l.b.y = lineguy[i].b[2]

        if scale ~= 0 then
            l.b.x = m_fixed.FixedMul(scale, l.b.x)
            l.b.y = m_fixed.FixedMul(scale, l.b.y)
        end

        if angle ~= 0 then
            l.b.x, l.b.y = AM_rotate(l.b.x, l.b.y, angle)
        end

        l.b.x = l.b.x + x
        l.b.y = l.b.y + y

        AM_drawMline(l, color)
    end
end

local function AM_drawPlayers()
    local i
    local p
    local their_colors = { GREENS, GRAYS, BROWNS, REDS }
    local their_color = -1
    local color

    if not doomstat.netgame then
        if cheating ~= 0 then
            AM_drawLineCharacter(cheat_player_arrow, #cheat_player_arrow, 0,
                plr.mo.angle, WHITE, plr.mo.x, plr.mo.y)
        else
            AM_drawLineCharacter(player_arrow, #player_arrow, 0,
                plr.mo.angle, WHITE, plr.mo.x, plr.mo.y)
        end
        return
    end

    for i = 1, doomtype.MAXPLAYERS do
        their_color = their_color + 1
        p = doomstat.players[i]

        if doomstat.deathmatch ~= 0 and not doomstat.singledemo and p ~= plr then
            -- continue
        elseif not doomstat.playeringame[i] then
            -- continue
        else
            if p.powers[doomdef.pw_invisibility + 1] then
                color = 246 -- *close* to black
            else
                color = their_colors[their_color + 1]
            end

            AM_drawLineCharacter(player_arrow, #player_arrow, 0, p.mo.angle,
                color, p.mo.x, p.mo.y)
        end
    end
end

local function AM_drawThings(colors, colorrange)
    local i
    local t

    for i = 1, r_state.numsectors do
        t = r_state.sectors[i].thinglist
        while t do
            AM_drawLineCharacter(thintriangle_guy, #thintriangle_guy,
                16 * 65536, t.angle, colors + lightlev, t.x, t.y)
            t = t.snext
        end
    end
end

local function AM_drawMarks()
    local i
    local fx
    local fy
    local w
    local h

    for i = 1, AM_NUMMARKPOINTS do
        if markpoints[i].x ~= -1 then
            -- w = SHORT(marknums[i]->width); h = SHORT(marknums[i]->height)
            w = 5 -- because something's wrong with the wad, i guess
            h = 6 -- because something's wrong with the wad, i guess
            fx = CXMTOF(markpoints[i].x)
            fy = CYMTOF(markpoints[i].y)
            if fx >= f_x and fx <= f_w - w and fy >= f_y and fy <= f_h - h then
                v_video.V_DrawPatch(fx, fy, marknums[i])
            end
        end
    end
end

local function AM_drawCrosshair(color)
    buffer.writeu8(fb, (f_w * (f_h + 1)) // 2, color) -- single point for now
end

function am_map.AM_Drawer()
    if not doomstat.automapactive then
        return
    end

    AM_clearFB(BACKGROUND)
    if grid ~= 0 then
        AM_drawGrid(GRIDCOLORS)
    end
    AM_drawWalls()
    AM_drawPlayers()
    if cheating == 2 then
        AM_drawThings(THINGCOLORS, 16) -- THINGRANGE
    end
    AM_drawCrosshair(XHAIRCOLORS)

    AM_drawMarks()

    v_video.V_MarkRect(f_x, f_y, f_w, f_h)
end

return am_map
end)()

g_game = (function()
local g_game = {}

-- ---------------------------------------------------------------------------
-- Globals (g_game.c)
-- ---------------------------------------------------------------------------

-- Gamestate the last time G_Ticker was called.
g_game.oldgamestate = nil

g_game.gameaction = doomdef.ga_nothing

-- (gamestate lives on doomstat.gamestate, matching the extern in doomstat.h.)

g_game.gameskill = d_mode.sk_medium
g_game.gameepisode = 1
g_game.gamemap = 1

g_game.respawnmonsters = false
g_game.timelimit = 0

g_game.paused = false
g_game.sendpause = false
g_game.sendsave = false
g_game.usergame = false

g_game.timingdemo = false
g_game.nodrawers = false
g_game.starttime = 0

g_game.viewactive = false
g_game.defdemoname = nil

-- Demo state (g_game.c): demorecording / demoplayback / singledemo /
-- lowres_turn live on doomstat; longtics / netdemo / demobuffer / demo_p /
-- demoend are here.
g_game.longtics = false
g_game.netdemo = false
g_game.demobuffer = nil -- { buffer, offset, size } view of the demo lump
g_game.demo_p = 0       -- absolute byte offset into the WAD buffer
g_game.demoend = 0      -- absolute byte offset marking the lump end
g_game.demoname = nil   -- demo recording file (cut in v1)

g_game.secretexit = false

-- Deferred new-game parameters (d_skill / d_episode / d_map).
g_game.d_skill = d_mode.sk_medium
g_game.d_episode = 1
g_game.d_map = 1

g_game.turbodetected = { false, false, false, false }

g_game.savegameslot = 0
g_game.savedescription = ""

-- Input state (g_game.c statics).
g_game.next_weapon = 0
g_game.turnheld = 0
g_game.mousex = 0
g_game.mousey = 0
g_game.dclicktime = 0
g_game.dclickstate = false
g_game.dclicks = 0
g_game.dclicktime2 = 0
g_game.dclickstate2 = false
g_game.dclicks2 = 0
g_game.joyxmove = 0
g_game.joyymove = 0
g_game.joystrafemove = 0

-- Consistency buffer (byte consistancy[MAXPLAYERS][BACKUPTICS]).
g_game.consistancy = {}
for p = 1, doomtype.MAXPLAYERS do
    g_game.consistancy[p] = {}
    for b = 1, 128 do -- BACKUPTICS
        g_game.consistancy[p][b] = 0
    end
end

-- ---------------------------------------------------------------------------
-- Constants (g_game.c)
-- ---------------------------------------------------------------------------

local MAXPLAYERS = doomtype.MAXPLAYERS
local BACKUPTICS = 128
local NUMKEYS = 256
local MAX_JOY_BUTTONS = 20
local MAX_MOUSE_BUTTONS = 8

local MAXPLMOVE = 0x32 -- forwardmove[1]
local TURBOTHRESHOLD = 0x32
local SLOWTURNTICS = 6
local DEMOMARKER = 0x80

local FRACUNIT = m_fixed.FRACUNIT

-- Movement values (g_game.c): fixed_t forwardmove[2], sidemove[2],
-- angleturn[3] (+ slow turn). 1-based Lua arrays: [1] is C index 0.
g_game.forwardmove = { 0x19, 0x32 }
g_game.sidemove = { 0x18, 0x28 }
g_game.angleturn = { 640, 1280, 320 }

-- weapon_keys[]: the C holds pointers to the config key_weaponN variables;
-- the port stores the m_controls field names and looks them up live so user
-- rebinds take effect.
local weapon_keys = {
    "key_weapon1", "key_weapon2", "key_weapon3", "key_weapon4",
    "key_weapon5", "key_weapon6", "key_weapon7", "key_weapon8",
}

-- weapon_order_table: used by the prev/next weapon keys.
local weapon_order_table = {
    { weapon = doomdef.wp_fist,          weapon_num = doomdef.wp_fist },
    { weapon = doomdef.wp_chainsaw,      weapon_num = doomdef.wp_fist },
    { weapon = doomdef.wp_pistol,        weapon_num = doomdef.wp_pistol },
    { weapon = doomdef.wp_shotgun,       weapon_num = doomdef.wp_shotgun },
    { weapon = doomdef.wp_supershotgun,  weapon_num = doomdef.wp_shotgun },
    { weapon = doomdef.wp_chaingun,      weapon_num = doomdef.wp_chaingun },
    { weapon = doomdef.wp_missile,       weapon_num = doomdef.wp_missile },
    { weapon = doomdef.wp_plasma,        weapon_num = doomdef.wp_plasma },
    { weapon = doomdef.wp_bfg,           weapon_num = doomdef.wp_bfg },
}

-- Keyboard / mouse / joystick state tables (0-based keys, like the C).
local gamekeydown = {}
for i = 0, NUMKEYS - 1 do
    gamekeydown[i] = false
end

-- The C has mousearray[MAX_MOUSE_BUTTONS + 1] and `mousebuttons =
-- &mousearray[1]` to allow [-1]. The disabled mouse buttons default to -1,
-- so mousebuttons[-1] reads the never-set array[0] slot (false).
local mousebuttons = {}
for i = 0, MAX_MOUSE_BUTTONS - 1 do
    mousebuttons[i] = false
end
mousebuttons[-1] = false

local joybuttons = {}
for i = 0, MAX_JOY_BUTTONS - 1 do
    joybuttons[i] = false
end

-- DOOM Par Times (g_game.c): pars[4][10] (pars[0] = {0} is unused; row
-- index is the episode) and DOOM II cpars[32] (0-based C).
local pars = {
    [0] = { 0 },
    [1] = { 0, 30, 75, 120, 90, 165, 180, 180, 30, 165 },
    [2] = { 0, 90, 90, 90, 120, 90, 360, 240, 30, 170 },
    [3] = { 0, 90, 45, 90, 150, 90, 90, 165, 30, 135 },
}
local cpars = {
    30, 90, 120, 120, 90, 150, 120, 120, 270, 90, --  1-10
    210, 150, 150, 150, 210, 150, 420, 150, 210, 150, -- 11-20
    240, 150, 180, 150, 150, 300, 330, 420, 300, 180, -- 21-30
    120, 30, -- 31-32
}

-- ---------------------------------------------------------------------------
-- G_PlayerReborn
-- Called after a player dies; almost everything is cleared and initialized.
-- ---------------------------------------------------------------------------

function g_game.G_PlayerReborn(player)
    local doomdef_ = doomdef
    local doomstat_ = doomstat
    local deh_misc = deh_misc

    local p = doomstat_.players[player + 1]

    -- Preserve intermission stats (frags / killcount / itemcount / secretcount).
    local frags = p.frags or {}
    local killcount = p.killcount or 0
    local itemcount = p.itemcount or 0
    local secretcount = p.secretcount or 0

    -- memset(p, 0, sizeof(*p)) -- clear everything else to defaults.
    p.mo = nil
    p.playerstate = 0 -- PST_LIVE
    p.cmd = {
        forwardmove = 0, sidemove = 0, angleturn = 0, chatchar = 0,
        buttons = 0, consistancy = 0, buttons2 = 0, inventory = 0,
        lookfly = 0, arti = 0,
    }
    p.viewz = 0
    p.viewheight = 0
    p.deltaviewheight = 0
    p.bob = 0
    p.health = deh_misc.deh_initial_health
    p.armorpoints = 0
    p.armortype = 0
    p.powers = { 0, 0, 0, 0, 0, 0 } -- NUMPOWERS
    p.cards = { false, false, false, false, false, false } -- NUMCARDS
    p.backpack = false
    p.frags = { 0, 0, 0, 0 } -- MAXPLAYERS
    p.readyweapon = doomdef_.wp_pistol
    p.pendingweapon = doomdef_.wp_pistol
    p.weaponowned = {}
    p.weaponowned[doomdef_.wp_fist + 1] = true
    p.weaponowned[doomdef_.wp_pistol + 1] = true
    -- memset zeroes the whole player, so every ammo slot is 0 except the
    -- initial clip. (Phase 4d: the demo picks up ammo, so the missing slots
    -- must read as 0, not nil.)
    p.ammo = {}
    for i = 0, doomdef_.NUMAMMO - 1 do
        p.ammo[i + 1] = 0
    end
    p.ammo[doomdef_.am_clip + 1] = deh_misc.deh_initial_bullets
    p.maxammo = {}
    for i = 0, doomdef_.NUMAMMO - 1 do
        p.maxammo[i + 1] = p_inter.maxammo[i + 1]
    end
    p.attackdown = true
    p.usedown = true
    p.cheats = 0
    p.refire = 0
    p.message = nil
    p.damagecount = 0
    p.bonuscount = 0
    p.attacker = nil
    p.extralight = 0
    p.fixedcolormap = 0
    p.colormap = 0
    p.psprites = {
        { state = nil, tics = 0, sx = 0, sy = 0 },
        { state = nil, tics = 0, sx = 0, sy = 0 },
    }
    p.didsecret = false

    -- Restore the preserved intermission stats.
    p.frags = frags
    p.killcount = killcount
    p.itemcount = itemcount
    p.secretcount = secretcount
end

-- G_InitPlayer: called at the start by the game initialization functions.
function g_game.G_InitPlayer(player)
    g_game.G_PlayerReborn(player)
end

-- ---------------------------------------------------------------------------
-- G_PlayerFinishLevel
-- Called when a player completes a level.
-- ---------------------------------------------------------------------------

function g_game.G_PlayerFinishLevel(player)
    local p = doomstat.players[player + 1]

    p.powers = { 0, 0, 0, 0, 0, 0 } -- memset(p->powers, 0, ...)
    p.cards = { false, false, false, false, false, false } -- memset(cards, 0)
    if p.mo ~= nil then
        -- cancel invisibility
        p.mo.flags = bit32.band(p.mo.flags, bit32.bnot(p_mobj.MF_SHADOW))
    end
    p.extralight = 0 -- cancel gun flashes
    p.fixedcolormap = 0 -- cancel ir gogles
    p.damagecount = 0 -- no palette changes
    p.bonuscount = 0
end

-- ---------------------------------------------------------------------------
-- G_DoLoadLevel
-- ---------------------------------------------------------------------------

function g_game.G_DoLoadLevel()
    local players = doomstat.players

    -- The sky map is set by P_SetupSky (p_setup.luau), which mirrors the C
    -- G_DoLoadLevel / G_InitNew sky setup.

    -- levelstarttic = gametic; for time calculation.
    doomstat.levelstarttic = d_loop.gametic

    -- If we are already in a level, force a wipe on the next draw.
    if doomstat.wipegamestate == doomdef.GS_LEVEL then
        doomstat.wipegamestate = -1
    end

    doomstat.gamestate = doomdef.GS_LEVEL

    for i = 1, MAXPLAYERS do
        g_game.turbodetected[i] = false
        if doomstat.playeringame[i]
            and players[i] ~= nil
            and players[i].playerstate == 1 then -- PST_DEAD
            players[i].playerstate = 2 -- PST_REBORN
        end
        if players[i] ~= nil then
            players[i].frags = { 0, 0, 0, 0 }
        end
    end

    p_setup.P_SetupLevel(g_game.gameepisode, g_game.gamemap, 0, g_game.gameskill)
    doomstat.displayplayer = doomstat.consoleplayer -- view the guy you are playing
    g_game.gameaction = doomdef.ga_nothing
    z_zone.Z_CheckHeap()

    -- Clear cmd building stuff.
    for i = 0, NUMKEYS - 1 do
        gamekeydown[i] = false
    end
    g_game.joyxmove = 0
    g_game.joyymove = 0
    g_game.joystrafemove = 0
    g_game.mousex = 0
    g_game.mousey = 0
    g_game.sendpause = false
    g_game.sendsave = false
    g_game.paused = false
    doomstat.paused = false
    for i = 0, MAX_MOUSE_BUTTONS - 1 do
        mousebuttons[i] = false
    end
    mousebuttons[-1] = false
    for i = 0, MAX_JOY_BUTTONS - 1 do
        joybuttons[i] = false
    end

    if doomstat.testcontrols then
        players[doomstat.consoleplayer + 1].message = "Press escape to quit."
    end
end

-- ---------------------------------------------------------------------------
-- SetMouseButtons / SetJoyButtons
-- ---------------------------------------------------------------------------

local function SetMouseButtons(buttons_mask)
    for i = 0, MAX_MOUSE_BUTTONS - 1 do
        local button_on = bit32.band(buttons_mask, bit32.lshift(1, i)) ~= 0

        -- Detect button press.
        if not mousebuttons[i] and button_on then
            if i == m_controls.mousebprevweapon then
                g_game.next_weapon = -1
            elseif i == m_controls.mousebnextweapon then
                g_game.next_weapon = 1
            end
        end

        mousebuttons[i] = button_on
    end
end

local function SetJoyButtons(buttons_mask)
    for i = 0, MAX_JOY_BUTTONS - 1 do
        local button_on = bit32.band(buttons_mask, bit32.lshift(1, i)) ~= 0

        -- Detect button press.
        if not joybuttons[i] and button_on then
            -- Weapon cycling.
            if i == m_controls.joybprevweapon then
                g_game.next_weapon = -1
            elseif i == m_controls.joybnextweapon then
                g_game.next_weapon = 1
            end
        end

        joybuttons[i] = button_on
    end
end

-- ---------------------------------------------------------------------------
-- Weapon selection (WeaponSelectable / G_NextWeapon)
-- ---------------------------------------------------------------------------

local function logical_gamemission()
    local gamemission = doomstat.gamemission
    if gamemission == d_mode.pack_chex then
        return d_mode.doom
    elseif gamemission == d_mode.pack_hacx then
        return d_mode.doom2
    end
    return gamemission
end

local function WeaponSelectable(weapon)
    local p = doomstat.players[doomstat.consoleplayer + 1]

    -- Can't select the super shotgun in Doom 1.
    if weapon == doomdef.wp_supershotgun and logical_gamemission() == d_mode.doom then
        return false
    end

    -- These weapons aren't available in shareware.
    if (weapon == doomdef.wp_plasma or weapon == doomdef.wp_bfg)
        and doomstat.gamemission == d_mode.doom
        and doomstat.gamemode == d_mode.shareware then
        return false
    end

    -- Can't select a weapon if we don't own it.
    if not p.weaponowned[weapon + 1] then
        return false
    end

    -- Can't select the fist if we have the chainsaw, unless
    -- we also have the berserk pack.
    if weapon == doomdef.wp_fist
        and p.weaponowned[doomdef.wp_chainsaw + 1]
        and not (p.powers[doomdef.pw_strength + 1] ~= 0) then
        return false
    end

    return true
end

local function G_NextWeapon(direction)
    local p = doomstat.players[doomstat.consoleplayer + 1]
    local weapon
    local i

    -- Find index in the table.
    if p.pendingweapon == doomdef.wp_nochange then
        weapon = p.readyweapon
    else
        weapon = p.pendingweapon
    end

    for i = 1, #weapon_order_table do
        if weapon_order_table[i].weapon == weapon then
            break
        end
    end

    -- Switch weapon. Don't loop forever.
    local start_i = i
    repeat
        i = i + direction
        i = (i + #weapon_order_table - 1) % #weapon_order_table + 1 -- 1-based wrap
    until i == start_i or WeaponSelectable(weapon_order_table[i].weapon)

    return weapon_order_table[i].weapon_num
end

-- ---------------------------------------------------------------------------
-- G_BuildTiccmd
-- Builds a ticcmd from all of the available inputs, or reads it from the
-- demo buffer. (If recording a demo, writes it out -- cut in v1.)
-- ---------------------------------------------------------------------------

function g_game.G_BuildTiccmd(cmd, maketic)
    local strafe
    local bstrafe
    local speed
    local tspeed
    local forward
    local side

    cmd.forwardmove = 0
    cmd.sidemove = 0
    cmd.angleturn = 0
    cmd.chatchar = 0
    cmd.buttons = 0
    cmd.consistancy = g_game.consistancy[doomstat.consoleplayer + 1][maketic % BACKUPTICS + 1]
    cmd.buttons2 = 0
    cmd.inventory = 0
    cmd.lookfly = 0
    cmd.arti = 0

    strafe = gamekeydown[m_controls.key_strafe]
        or mousebuttons[m_controls.mousebstrafe]
        or joybuttons[m_controls.joybstrafe]

    -- fraggle: support the old "joyb_speed = 31" hack which
    -- allowed an autorun effect.
    speed = 0
    if m_controls.key_speed >= NUMKEYS
        or m_controls.joybspeed >= MAX_JOY_BUTTONS
        or gamekeydown[m_controls.key_speed]
        or joybuttons[m_controls.joybspeed] then
        speed = 1
    end

    forward = 0
    side = 0

    -- Use two stage accelerative turning on the keyboard and joystick.
    if g_game.joyxmove < 0
        or g_game.joyxmove > 0
        or gamekeydown[m_controls.key_right]
        or gamekeydown[m_controls.key_left] then
        g_game.turnheld = g_game.turnheld + d_loop.ticdup
    else
        g_game.turnheld = 0
    end

    if g_game.turnheld < SLOWTURNTICS then
        tspeed = 2 -- slow turn
    else
        tspeed = speed
    end

    -- Let movement keys cancel each other out.
    if strafe then
        if gamekeydown[m_controls.key_right] then
            side = side + g_game.sidemove[speed + 1]
        end
        if gamekeydown[m_controls.key_left] then
            side = side - g_game.sidemove[speed + 1]
        end
        if g_game.joyxmove > 0 then
            side = side + g_game.sidemove[speed + 1]
        end
        if g_game.joyxmove < 0 then
            side = side - g_game.sidemove[speed + 1]
        end
    else
        if gamekeydown[m_controls.key_right] then
            cmd.angleturn = cmd.angleturn - g_game.angleturn[tspeed + 1]
        end
        if gamekeydown[m_controls.key_left] then
            cmd.angleturn = cmd.angleturn + g_game.angleturn[tspeed + 1]
        end
        if g_game.joyxmove > 0 then
            cmd.angleturn = cmd.angleturn - g_game.angleturn[tspeed + 1]
        end
        if g_game.joyxmove < 0 then
            cmd.angleturn = cmd.angleturn + g_game.angleturn[tspeed + 1]
        end
    end

    if gamekeydown[m_controls.key_up] then
        forward = forward + g_game.forwardmove[speed + 1]
    end
    if gamekeydown[m_controls.key_down] then
        forward = forward - g_game.forwardmove[speed + 1]
    end

    if g_game.joyymove < 0 then
        forward = forward + g_game.forwardmove[speed + 1]
    end
    if g_game.joyymove > 0 then
        forward = forward - g_game.forwardmove[speed + 1]
    end

    if gamekeydown[m_controls.key_strafeleft]
        or joybuttons[m_controls.joybstrafeleft]
        or mousebuttons[m_controls.mousebstrafeleft]
        or g_game.joystrafemove < 0 then
        side = side - g_game.sidemove[speed + 1]
    end

    if gamekeydown[m_controls.key_straferight]
        or joybuttons[m_controls.joybstraferight]
        or mousebuttons[m_controls.mousebstraferight]
        or g_game.joystrafemove > 0 then
        side = side + g_game.sidemove[speed + 1]
    end

    -- Buttons.
    cmd.chatchar = hu_stuff.HU_dequeueChatChar()

    if gamekeydown[m_controls.key_fire]
        or mousebuttons[m_controls.mousebfire]
        or joybuttons[m_controls.joybfire] then
        cmd.buttons = bit32.bor(cmd.buttons, d_event.BT_ATTACK)
    end

    if gamekeydown[m_controls.key_use]
        or joybuttons[m_controls.joybuse]
        or mousebuttons[m_controls.mousebuse] then
        cmd.buttons = bit32.bor(cmd.buttons, d_event.BT_USE)
        -- Clear double clicks if hit use button.
        g_game.dclicks = 0
    end

    -- If the previous or next weapon button is pressed, the next_weapon
    -- variable is set to change weapons when we generate a ticcmd.
    -- Choose a new weapon.
    if doomstat.gamestate == doomdef.GS_LEVEL and g_game.next_weapon ~= 0 then
        local i = G_NextWeapon(g_game.next_weapon)
        cmd.buttons = bit32.bor(cmd.buttons, d_event.BT_CHANGE)
        cmd.buttons = bit32.bor(cmd.buttons,
            bit32.lshift(i, d_event.BT_WEAPONSHIFT))
    else
        -- Check weapon keys.
        for i = 1, #weapon_keys do
            local key = m_controls[weapon_keys[i]]
            if gamekeydown[key] then
                cmd.buttons = bit32.bor(cmd.buttons, d_event.BT_CHANGE)
                cmd.buttons = bit32.bor(cmd.buttons,
                    bit32.lshift(i - 1, d_event.BT_WEAPONSHIFT))
                break
            end
        end
    end

    g_game.next_weapon = 0

    -- Mouse.
    if mousebuttons[m_controls.mousebforward] then
        forward = forward + g_game.forwardmove[speed + 1]
    end
    if mousebuttons[m_controls.mousebbackward] then
        forward = forward - g_game.forwardmove[speed + 1]
    end

    if m_controls.dclick_use ~= 0 then
        -- Forward double click.
        if mousebuttons[m_controls.mousebforward] ~= g_game.dclickstate
            and g_game.dclicktime > 1 then
            g_game.dclickstate = mousebuttons[m_controls.mousebforward]
            if g_game.dclickstate then
                g_game.dclicks = g_game.dclicks + 1
            end
            if g_game.dclicks == 2 then
                cmd.buttons = bit32.bor(cmd.buttons, d_event.BT_USE)
                g_game.dclicks = 0
            else
                g_game.dclicktime = 0
            end
        else
            g_game.dclicktime = g_game.dclicktime + d_loop.ticdup
            if g_game.dclicktime > 20 then
                g_game.dclicks = 0
                g_game.dclickstate = false
            end
        end

        -- Strafe double click.
        bstrafe = mousebuttons[m_controls.mousebstrafe]
            or joybuttons[m_controls.joybstrafe]
        if bstrafe ~= g_game.dclickstate2 and g_game.dclicktime2 > 1 then
            g_game.dclickstate2 = bstrafe
            if g_game.dclickstate2 then
                g_game.dclicks2 = g_game.dclicks2 + 1
            end
            if g_game.dclicks2 == 2 then
                cmd.buttons = bit32.bor(cmd.buttons, d_event.BT_USE)
                g_game.dclicks2 = 0
            else
                g_game.dclicktime2 = 0
            end
        else
            g_game.dclicktime2 = g_game.dclicktime2 + d_loop.ticdup
            if g_game.dclicktime2 > 20 then
                g_game.dclicks2 = 0
                g_game.dclickstate2 = false
            end
        end
    end

    forward = forward + g_game.mousey

    if strafe then
        side = side + g_game.mousex * 2
    else
        cmd.angleturn = cmd.angleturn - g_game.mousex * 0x8
    end

    if g_game.mousex == 0 then
        -- No movement in the previous frame.
        doomstat.testcontrols_mousespeed = 0
    end

    g_game.mousex = 0
    g_game.mousey = 0

    if forward > MAXPLMOVE then
        forward = MAXPLMOVE
    elseif forward < -MAXPLMOVE then
        forward = -MAXPLMOVE
    end
    if side > MAXPLMOVE then
        side = MAXPLMOVE
    elseif side < -MAXPLMOVE then
        side = -MAXPLMOVE
    end

    cmd.forwardmove = cmd.forwardmove + forward
    cmd.sidemove = cmd.sidemove + side

    -- Special buttons.
    if g_game.sendpause then
        g_game.sendpause = false
        cmd.buttons = bit32.bor(d_event.BT_SPECIAL, d_event.BTS_PAUSE)
    end

    if g_game.sendsave then
        g_game.sendsave = false
        cmd.buttons = bit32.bor(d_event.BT_SPECIAL, d_event.BTS_SAVEGAME,
            bit32.lshift(g_game.savegameslot, d_event.BTS_SAVESHIFT))
    end

    -- Low-res turning (only used when recording demos; cut in v1).
    -- if lowres_turn then ... end
end

-- ---------------------------------------------------------------------------
-- G_Responder
-- Get info needed to make ticcmds for the players.
-- ---------------------------------------------------------------------------

function g_game.G_Responder(ev)
    -- Allow spy mode changes even during the demo.
    if doomstat.gamestate == doomdef.GS_LEVEL
        and ev.type == d_event.ev_keydown
        and ev.data1 == m_controls.key_spy
        and (doomstat.singledemo or doomstat.deathmatch == 0) then
        -- Spy mode.
        repeat
            doomstat.displayplayer = doomstat.displayplayer + 1
            if doomstat.displayplayer == MAXPLAYERS then
                doomstat.displayplayer = 0
            end
        until doomstat.playeringame[doomstat.displayplayer + 1]
            or doomstat.displayplayer == doomstat.consoleplayer
        return true
    end

    -- Any other key pops up the menu if in demos.
    if g_game.gameaction == doomdef.ga_nothing
        and not doomstat.singledemo
        and (doomstat.demoplayback or doomstat.gamestate == doomdef.GS_DEMOSCREEN) then
        if ev.type == d_event.ev_keydown
            or (ev.type == d_event.ev_mouse and ev.data1)
            or (ev.type == d_event.ev_joystick and ev.data1) then
            m_menu.M_StartControlPanel()
            return true
        end
        return false
    end

    if doomstat.gamestate == doomdef.GS_LEVEL then
        if hu_stuff.HU_Responder(ev) then
            return true -- chat ate the event
        end
        if st_stuff.ST_Responder(ev) then
            return true -- status window ate it
        end
        if am_map.AM_Responder(ev) then
            return true -- automap ate it
        end
    end

    if doomstat.gamestate == doomdef.GS_FINALE then
        if f_finale.F_Responder(ev) then
            return true -- finale ate the event
        end
    end

    if doomstat.testcontrols and ev.type == d_event.ev_mouse then
        -- If we are invoked by setup to test the controls, save the
        -- mouse speed so that we can display it on-screen. Perform a low
        -- pass filter on this so that the thermometer appears to move
        -- smoothly.
        doomstat.testcontrols_mousespeed = math.abs(ev.data2)
    end

    -- If the next/previous weapon keys are pressed, set the next_weapon
    -- variable to change weapons when the next ticcmd is generated.
    if ev.type == d_event.ev_keydown and ev.data1 == m_controls.key_prevweapon then
        g_game.next_weapon = -1
    elseif ev.type == d_event.ev_keydown and ev.data1 == m_controls.key_nextweapon then
        g_game.next_weapon = 1
    end

    if ev.type == d_event.ev_keydown then
        if ev.data1 == m_controls.key_pause then
            g_game.sendpause = true
        elseif ev.data1 < NUMKEYS then
            gamekeydown[ev.data1] = true
        end
        return true -- eat key down events
    elseif ev.type == d_event.ev_keyup then
        if ev.data1 < NUMKEYS then
            gamekeydown[ev.data1] = false
        end
        return false -- always let key up events filter down
    elseif ev.type == d_event.ev_mouse then
        SetMouseButtons(ev.data1)
        g_game.mousex = doomtype.truncdiv(
            ev.data2 * (doomstat.mouseSensitivity + 5), 10)
        g_game.mousey = doomtype.truncdiv(
            ev.data3 * (doomstat.mouseSensitivity + 5), 10)
        return true -- eat events
    elseif ev.type == d_event.ev_joystick then
        SetJoyButtons(ev.data1)
        g_game.joyxmove = ev.data2
        g_game.joyymove = ev.data3
        g_game.joystrafemove = ev.data4
        return true -- eat events
    end

    return false
end

-- ---------------------------------------------------------------------------
-- G_Ticker
-- Make ticcmds for the players.
-- ---------------------------------------------------------------------------

function g_game.G_Ticker()
    local buf
    local cmd

    -- The C players[] is a static zeroed array; the port creates the player
    -- tables lazily. Ensure the player tables + zeroed cmds exist so the
    -- title-screen / pre-G_InitNew path processes a zeroed ticcmd like the C.
    for i = 1, MAXPLAYERS do
        if doomstat.players[i] == nil then
            doomstat.players[i] = {}
        end
        if doomstat.players[i].cmd == nil then
            doomstat.players[i].cmd = {
                forwardmove = 0, sidemove = 0, angleturn = 0, chatchar = 0,
                buttons = 0, consistancy = 0, buttons2 = 0, inventory = 0,
                lookfly = 0, arti = 0,
            }
        end
    end

    -- Do player reborns if needed.
    for i = 1, MAXPLAYERS do
        if doomstat.playeringame[i]
            and doomstat.players[i] ~= nil
            and doomstat.players[i].playerstate == 2 then -- PST_REBORN
            g_game.G_DoReborn(i - 1)
        end
    end

    -- Do things to change the game state.
    while g_game.gameaction ~= doomdef.ga_nothing do
        if g_game.gameaction == doomdef.ga_loadlevel then
            g_game.G_DoLoadLevel()
        elseif g_game.gameaction == doomdef.ga_newgame then
            g_game.G_DoNewGame()
        elseif g_game.gameaction == doomdef.ga_loadgame then
            g_game.G_DoLoadGame() -- savegames cut in v1: no-op
        elseif g_game.gameaction == doomdef.ga_savegame then
            g_game.G_DoSaveGame() -- savegames cut in v1: no-op
        elseif g_game.gameaction == doomdef.ga_playdemo then
            g_game.G_DoPlayDemo()
        elseif g_game.gameaction == doomdef.ga_completed then
            g_game.G_DoCompleted()
        elseif g_game.gameaction == doomdef.ga_victory then
            f_finale.F_StartFinale()
        elseif g_game.gameaction == doomdef.ga_worlddone then
            g_game.G_DoWorldDone()
        elseif g_game.gameaction == doomdef.ga_screenshot then
            -- V_ScreenShot("DOOM%02i.%s") is cut in v1.
            doomstat.players[doomstat.consoleplayer + 1].message = "screen shot"
            g_game.gameaction = doomdef.ga_nothing
        elseif g_game.gameaction == doomdef.ga_nothing then
            -- nothing
        end
    end

    -- Get commands, check consistency, and build new consistency check.
    buf = (d_loop.gametic // d_loop.ticdup) % BACKUPTICS

    for i = 1, MAXPLAYERS do
        if doomstat.playeringame[i] then
            cmd = doomstat.players[i].cmd

            -- memcpy(cmd, &netcmds[i], sizeof(ticcmd_t))
            local netcmd = doomstat.netcmds and doomstat.netcmds[i]
            if netcmd == nil then
                cmd.forwardmove = 0
                cmd.sidemove = 0
                cmd.angleturn = 0
                cmd.chatchar = 0
                cmd.buttons = 0
                cmd.consistancy = 0
                cmd.buttons2 = 0
                cmd.inventory = 0
                cmd.lookfly = 0
                cmd.arti = 0
            else
                cmd.forwardmove = netcmd.forwardmove
                cmd.sidemove = netcmd.sidemove
                cmd.angleturn = netcmd.angleturn
                cmd.chatchar = netcmd.chatchar
                cmd.buttons = netcmd.buttons
                cmd.consistancy = netcmd.consistancy
                cmd.buttons2 = netcmd.buttons2
                cmd.inventory = netcmd.inventory
                cmd.lookfly = netcmd.lookfly
                cmd.arti = netcmd.arti
            end

            if doomstat.demoplayback then
                g_game.G_ReadDemoTiccmd(cmd)
            end
            -- if demorecording then G_WriteDemoTiccmd(cmd) -- cut in v1

            -- Check for turbo cheats: check ~4 seconds whether to display
            -- the turbo message. Store if the turbo threshold was exceeded
            -- in any tics over the past 4 seconds. Offset the checking
            -- period for each player so messages are not displayed at the
            -- same time.
            if cmd.forwardmove > TURBOTHRESHOLD then
                g_game.turbodetected[i] = true
            end

            if bit32.band(d_loop.gametic, 31) == 0
                and (bit32.rshift(d_loop.gametic, 5) % MAXPLAYERS) == i - 1
                and g_game.turbodetected[i] then
                local message = m_misc.M_snprintf("%s is turbo!",
                    hu_stuff.player_names[i])
                doomstat.players[doomstat.consoleplayer + 1].message = message
                g_game.turbodetected[i] = false
            end

            if doomstat.netgame
                and not g_game.netdemo
                and d_loop.gametic % d_loop.ticdup == 0 then
                if d_loop.gametic > BACKUPTICS
                    and g_game.consistancy[i][buf + 1] ~= cmd.consistancy then
                    i_system.I_Error("consistency failure (%i should be %i)",
                        cmd.consistancy, g_game.consistancy[i][buf + 1])
                end
                if doomstat.players[i].mo ~= nil then
                    g_game.consistancy[i][buf + 1] = doomstat.players[i].mo.x
                else
                    g_game.consistancy[i][buf + 1] = m_random.rndindex
                end
            end
        end
    end

    -- Check for special buttons.
    for i = 1, MAXPLAYERS do
        if doomstat.playeringame[i] then
            if bit32.band(doomstat.players[i].cmd.buttons, d_event.BT_SPECIAL) ~= 0 then
                local special = bit32.band(doomstat.players[i].cmd.buttons,
                    d_event.BT_SPECIALMASK)
                if special == d_event.BTS_PAUSE then
                    g_game.paused = not g_game.paused
                    doomstat.paused = g_game.paused
                    if g_game.paused then
                        s_sound.S_PauseSound()
                    else
                        s_sound.S_ResumeSound()
                    end
                elseif special == d_event.BTS_SAVEGAME then
                    -- Savegames are cut in v1; the C writes a savegame file.
                    g_game.savegameslot = bit32.rshift(
                        bit32.band(doomstat.players[i].cmd.buttons,
                            d_event.BTS_SAVEMASK), d_event.BTS_SAVESHIFT)
                    g_game.gameaction = doomdef.ga_savegame
                end
            end
        end
    end

    -- Have we just finished displaying an intermission screen?
    if g_game.oldgamestate == doomdef.GS_INTERMISSION
        and doomstat.gamestate ~= doomdef.GS_INTERMISSION then
        wi_stuff.WI_End()
    end

    g_game.oldgamestate = doomstat.gamestate

    -- Do main actions.
    if doomstat.gamestate == doomdef.GS_LEVEL then
        p_tick.P_Ticker()
        st_stuff.ST_Ticker()
        am_map.AM_Ticker()
        hu_stuff.HU_Ticker()
    elseif doomstat.gamestate == doomdef.GS_INTERMISSION then
        wi_stuff.WI_Ticker()
    elseif doomstat.gamestate == doomdef.GS_FINALE then
        f_finale.F_Ticker()
    elseif doomstat.gamestate == doomdef.GS_DEMOSCREEN then
        d_main.D_PageTicker()
    end
end

-- ---------------------------------------------------------------------------
-- G_DoReborn
-- ---------------------------------------------------------------------------

function g_game.G_DoReborn(playernum)
    if not doomstat.netgame then
        -- Reload the level from scratch.
        g_game.gameaction = doomdef.ga_loadlevel
    else
        -- Netgame respawn (deathmatch / coop) is cut in v1.
    end
end

-- ---------------------------------------------------------------------------
-- G_DeathMatchSpawnPlayer
-- Deathmatch is cut in v1 (multiplayer deferred), so this is a no-op stub.
-- P_SetupLevel references it only in the deathmatch block, which never runs.
-- ---------------------------------------------------------------------------

function g_game.G_DeathMatchSpawnPlayer(player)
end

-- ---------------------------------------------------------------------------
-- G_ScreenShot
-- ---------------------------------------------------------------------------

function g_game.G_ScreenShot()
    g_game.gameaction = doomdef.ga_screenshot
end

-- ---------------------------------------------------------------------------
-- G_ExitLevel / G_SecretExitLevel
-- ---------------------------------------------------------------------------

function g_game.G_ExitLevel()
    g_game.secretexit = false
    g_game.gameaction = doomdef.ga_completed
end

-- Here's for the german edition.
function g_game.G_SecretExitLevel()
    -- IF NO WOLF3D LEVELS, NO SECRET EXIT!
    if doomstat.gamemode == d_mode.commercial
        and w_wad.W_CheckNumForName("map31") < 0 then
        g_game.secretexit = false
    else
        g_game.secretexit = true
    end
    g_game.gameaction = doomdef.ga_completed
end

-- ---------------------------------------------------------------------------
-- G_DoCompleted
-- ---------------------------------------------------------------------------

function g_game.G_DoCompleted()
    g_game.gameaction = doomdef.ga_nothing

    for i = 1, MAXPLAYERS do
        if doomstat.playeringame[i] then
            g_game.G_PlayerFinishLevel(i - 1) -- take away cards and stuff
        end
    end

    if doomstat.automapactive then
        am_map.AM_Stop()
    end

    if doomstat.gamemode ~= d_mode.commercial then
        -- Chex Quest ends after 5 levels, rather than 8.
        if doomstat.gameversion == d_mode.exe_chex then
            if g_game.gamemap == 5 then
                g_game.gameaction = doomdef.ga_victory
                return
            end
        else
            if g_game.gamemap == 8 then
                g_game.gameaction = doomdef.ga_victory
                return
            elseif g_game.gamemap == 9 then
                for i = 1, MAXPLAYERS do
                    if doomstat.players[i] ~= nil then
                        doomstat.players[i].didsecret = true
                    end
                end
            end
        end
    end

    if g_game.gamemap == 8 and doomstat.gamemode ~= d_mode.commercial then
        -- Victory.
        g_game.gameaction = doomdef.ga_victory
        return
    end

    if g_game.gamemap == 9 and doomstat.gamemode ~= d_mode.commercial then
        -- Exit secret level.
        for i = 1, MAXPLAYERS do
            if doomstat.players[i] ~= nil then
                doomstat.players[i].didsecret = true
            end
        end
    end

    local wminfo = {
        didsecret = false,
        epsd = 0,
        last = 0,
        next = 0,
        maxkills = 0,
        maxitems = 0,
        maxsecret = 0,
        maxfrags = 0,
        partime = 0,
        pnum = 0,
        plyr = {},
    }
    for i = 1, MAXPLAYERS do
        wminfo.plyr[i] = {
            ["in"] = false, skills = 0, sitems = 0, ssecret = 0, stime = 0,
            frags = { 0, 0, 0, 0 }, score = 0,
        }
    end

    wminfo.didsecret = doomstat.players[doomstat.consoleplayer + 1].didsecret
    wminfo.epsd = g_game.gameepisode - 1
    wminfo.last = g_game.gamemap - 1

    -- wminfo.next is 0 biased, unlike gamemap.
    if doomstat.gamemode == d_mode.commercial then
        if g_game.secretexit then
            if g_game.gamemap == 15 then
                wminfo.next = 30
            elseif g_game.gamemap == 31 then
                wminfo.next = 31
            end
        else
            if g_game.gamemap == 31 or g_game.gamemap == 32 then
                wminfo.next = 15
            else
                wminfo.next = g_game.gamemap
            end
        end
    else
        if g_game.secretexit then
            wminfo.next = 8 -- go to secret level
        elseif g_game.gamemap == 9 then
            -- Returning from secret level.
            if g_game.gameepisode == 1 then
                wminfo.next = 3
            elseif g_game.gameepisode == 2 then
                wminfo.next = 5
            elseif g_game.gameepisode == 3 then
                wminfo.next = 6
            else -- episode 4
                wminfo.next = 2
            end
        else
            wminfo.next = g_game.gamemap -- go to next level
        end
    end

    wminfo.maxkills = doomstat.totalkills
    wminfo.maxitems = doomstat.totalitems
    wminfo.maxsecret = doomstat.totalsecret
    wminfo.maxfrags = 0

    -- Set par time. Doom episode 4 doesn't have a par time, so this
    -- overflows into the cpars array. It's necessary to emulate this
    -- for statcheck regression testing.
    if doomstat.gamemode == d_mode.commercial then
        wminfo.partime = doomtype.TICRATE * cpars[g_game.gamemap]
    elseif g_game.gameepisode < 4 then
        wminfo.partime = doomtype.TICRATE * pars[g_game.gameepisode][g_game.gamemap + 1]
    else
        wminfo.partime = doomtype.TICRATE * cpars[g_game.gamemap + 1]
    end

    wminfo.pnum = doomstat.consoleplayer

    for i = 1, MAXPLAYERS do
        local plyr = wminfo.plyr[i]
        plyr["in"] = doomstat.playeringame[i]
        plyr.skills = doomstat.players[i].killcount
        plyr.sitems = doomstat.players[i].itemcount
        plyr.ssecret = doomstat.players[i].secretcount
        plyr.stime = doomstat.leveltime
        -- memcpy(wminfo.plyr[i].frags, players[i].frags, ...)
        for j = 1, MAXPLAYERS do
            plyr.frags[j] = doomstat.players[i].frags[j]
        end
    end

    doomstat.wminfo = wminfo

    doomstat.gamestate = doomdef.GS_INTERMISSION
    g_game.viewactive = false
    doomstat.viewactive = false
    doomstat.automapactive = false

    -- StatCopy(&wminfo): statdump.c is cut in v1.

    wi_stuff.WI_Start(wminfo)
end

-- ---------------------------------------------------------------------------
-- G_WorldDone / G_DoWorldDone
-- ---------------------------------------------------------------------------

function g_game.G_WorldDone()
    g_game.gameaction = doomdef.ga_worlddone

    if g_game.secretexit then
        doomstat.players[doomstat.consoleplayer + 1].didsecret = true
    end

    if doomstat.gamemode == d_mode.commercial then
        local gamemap = g_game.gamemap
        local finale = false
        if gamemap == 15 or gamemap == 31 then
            if g_game.secretexit then
                finale = true
            end
        elseif gamemap == 6 or gamemap == 11 or gamemap == 20 or gamemap == 30 then
            finale = true
        end
        if finale then
            f_finale.F_StartFinale()
        end
    end
end

function g_game.G_DoWorldDone()
    doomstat.gamestate = doomdef.GS_LEVEL
    g_game.gamemap = doomstat.wminfo.next + 1
    g_game.G_DoLoadLevel()
    g_game.gameaction = doomdef.ga_nothing
    g_game.viewactive = true
    doomstat.viewactive = true
end

-- ---------------------------------------------------------------------------
-- Savegames (cut in v1)
-- ---------------------------------------------------------------------------

function g_game.G_LoadGame(name)
    g_game.gameaction = doomdef.ga_loadgame
end

function g_game.G_DoLoadGame()
    g_game.gameaction = doomdef.ga_nothing
end

function g_game.G_SaveGame(slot, description)
    g_game.sendsave = true
end

function g_game.G_DoSaveGame()
    g_game.gameaction = doomdef.ga_nothing
end

-- ---------------------------------------------------------------------------
-- G_DeferedInitNew / G_DoNewGame / G_InitNew
-- ---------------------------------------------------------------------------

function g_game.G_DeferedInitNew(skill, episode, map)
    g_game.d_skill = skill
    g_game.d_episode = episode
    g_game.d_map = map
    g_game.gameaction = doomdef.ga_newgame
end

function g_game.G_DoNewGame()
    doomstat.demoplayback = false
    g_game.netdemo = false
    doomstat.netgame = false
    doomstat.deathmatch = 0
    doomstat.playeringame[2] = false
    doomstat.playeringame[3] = false
    doomstat.playeringame[4] = false
    doomstat.respawnparm = false
    doomstat.fastparm = false
    doomstat.nomonsters = false
    doomstat.consoleplayer = 0
    g_game.G_InitNew(g_game.d_skill, g_game.d_episode, g_game.d_map)
    g_game.gameaction = doomdef.ga_nothing
end

function g_game.G_InitNew(skill, episode, map)
    local old_gameskill = doomstat.gameskill

    if g_game.paused then
        g_game.paused = false
        doomstat.paused = false
        s_sound.S_ResumeSound()
    end

    if skill > d_mode.sk_nightmare then
        skill = d_mode.sk_nightmare
    end

    if doomstat.gameversion >= d_mode.exe_ultimate then
        if episode == 0 then
            episode = 4
        end
    else
        if episode < 1 then
            episode = 1
        end
        if episode > 3 then
            episode = 3
        end
    end

    if episode > 1 and doomstat.gamemode == d_mode.shareware then
        episode = 1
    end

    if map < 1 then
        map = 1
    end

    if map > 9 and doomstat.gamemode ~= d_mode.commercial then
        map = 9
    end

    m_random.M_ClearRandom()

    if skill == d_mode.sk_nightmare or doomstat.respawnparm then
        g_game.respawnmonsters = true
        doomstat.respawnmonsters = true
    else
        g_game.respawnmonsters = false
        doomstat.respawnmonsters = false
    end

    if doomstat.fastparm
        or (skill == d_mode.sk_nightmare and old_gameskill ~= d_mode.sk_nightmare) then
        -- Fast monsters: halve the sargeant's run/pain state tics and
        -- speed up the monster fireballs.
        for i = info.statenum.S_SARG_RUN1, info.statenum.S_SARG_PAIN2 do
            info.states[i + 1].tics = info.states[i + 1].tics // 2 -- >>= 1
        end
        info.mobjinfo[info.mobjtype.MT_BRUISERSHOT + 1].speed = 20 * FRACUNIT
        info.mobjinfo[info.mobjtype.MT_HEADSHOT + 1].speed = 20 * FRACUNIT
        info.mobjinfo[info.mobjtype.MT_TROOPSHOT + 1].speed = 20 * FRACUNIT
    elseif skill ~= d_mode.sk_nightmare and old_gameskill == d_mode.sk_nightmare then
        -- Restore the slow monster states when leaving nightmare mode.
        for i = info.statenum.S_SARG_RUN1, info.statenum.S_SARG_PAIN2 do
            info.states[i + 1].tics = info.states[i + 1].tics * 2 -- <<= 1
        end
        info.mobjinfo[info.mobjtype.MT_BRUISERSHOT + 1].speed = 15 * FRACUNIT
        info.mobjinfo[info.mobjtype.MT_HEADSHOT + 1].speed = 10 * FRACUNIT
        info.mobjinfo[info.mobjtype.MT_TROOPSHOT + 1].speed = 10 * FRACUNIT
    end

    -- Force players to be initialized upon first level load.
    for i = 1, MAXPLAYERS do
        if doomstat.players[i] == nil then
            doomstat.players[i] = {}
        end
        doomstat.players[i].playerstate = 2 -- PST_REBORN
    end

    g_game.usergame = true -- will be set false if a demo
    doomstat.usergame = true
    g_game.paused = false
    doomstat.paused = false
    doomstat.demoplayback = false
    doomstat.automapactive = false
    g_game.viewactive = true
    doomstat.viewactive = true
    g_game.gameepisode = episode
    doomstat.gameepisode = episode
    g_game.gamemap = map
    doomstat.gamemap = map
    g_game.gameskill = skill
    doomstat.gameskill = skill

    -- The sky to use is set by P_SetupSky (p_setup.luau), which mirrors the
    -- C's G_InitNew / G_DoLoadLevel sky setup.

    g_game.G_DoLoadLevel()
end

-- ---------------------------------------------------------------------------
-- Demo playback
-- ---------------------------------------------------------------------------

-- G_CmdChecksum: checksum of a ticcmd (only used for netgame consistency,
-- which is cut in v1; kept for parity).
function g_game.G_CmdChecksum(cmd)
    return cmd.forwardmove + cmd.sidemove + cmd.angleturn
        + cmd.chatchar + cmd.buttons + cmd.consistancy
end

-- G_VanillaVersionCode.
function g_game.G_VanillaVersionCode()
    if doomstat.gameversion == d_mode.exe_doom_1_2 then
        i_system.I_Error("Doom 1.2 does not have a version code!")
    elseif doomstat.gameversion == d_mode.exe_doom_1_666 then
        return 106
    elseif doomstat.gameversion == d_mode.exe_doom_1_7 then
        return 107
    elseif doomstat.gameversion == d_mode.exe_doom_1_8 then
        return 108
    else
        return 109 -- exe_doom_1_9 / all other versions are v1.9 variants
    end
    return 109
end

-- Read a signed byte (C signed char).
local function readSignedChar(buf, off)
    local b = buffer.readu8(buf, off)
    if b >= 128 then
        b = b - 256
    end
    return b
end

-- Read a 16-bit little-endian value as a signed short.
local function readSignedShort(buf, off)
    local v = buffer.readu8(buf, off) + buffer.readu8(buf, off + 1) * 256
    if v >= 0x8000 then
        v = v - 0x10000
    end
    return v
end

-- G_ReadDemoTiccmd.
function g_game.G_ReadDemoTiccmd(cmd)
    local buf = g_game.demobuffer.buffer

    if buffer.readu8(buf, g_game.demo_p) == DEMOMARKER then
        -- End of demo data stream.
        g_game.G_CheckDemoStatus()
        return
    end

    cmd.forwardmove = readSignedChar(buf, g_game.demo_p)
    g_game.demo_p = g_game.demo_p + 1
    cmd.sidemove = readSignedChar(buf, g_game.demo_p)
    g_game.demo_p = g_game.demo_p + 1

    -- If this is a longtics demo, read back in higher resolution.
    if g_game.longtics then
        cmd.angleturn = readSignedShort(buf, g_game.demo_p)
        g_game.demo_p = g_game.demo_p + 2
    else
        local b = buffer.readu8(buf, g_game.demo_p)
        g_game.demo_p = g_game.demo_p + 1
        cmd.angleturn = bit32.lshift(b, 8)
        if cmd.angleturn >= 0x8000 then
            cmd.angleturn = cmd.angleturn - 0x10000 -- signed short wrap
        end
    end

    cmd.buttons = buffer.readu8(buf, g_game.demo_p)
    g_game.demo_p = g_game.demo_p + 1
end

-- Generate a string describing a demo version.
local function DemoVersionDescription(version)
    if version == 104 then
        return "v1.4"
    elseif version == 105 then
        return "v1.5"
    elseif version == 106 then
        return "v1.6/v1.666"
    elseif version == 107 then
        return "v1.7/v1.7a"
    elseif version == 108 then
        return "v1.8"
    elseif version == 109 then
        return "v1.9"
    end

    -- Unknown version. Perhaps this is a pre-v1.4 IWAD? If the version
    -- byte is in the range 0-4 then it can be a v1.0-v1.2 demo.
    if version >= 0 and version <= 4 then
        return "v1.0/v1.1/v1.2"
    else
        return string.format("%i.%i (unknown)", version // 100, version % 100)
    end
end

-- G_DoPlayDemo.
function g_game.G_DoPlayDemo()
    local skill
    local episode
    local map
    local demoversion

    g_game.gameaction = doomdef.ga_nothing
    g_game.demobuffer = w_wad.W_CacheLumpName(g_game.defdemoname, z_zone.PU_STATIC)
    g_game.demo_p = g_game.demobuffer.offset
    g_game.demoend = g_game.demobuffer.offset + g_game.demobuffer.size
    local buf = g_game.demobuffer.buffer

    demoversion = buffer.readu8(buf, g_game.demo_p)
    g_game.demo_p = g_game.demo_p + 1

    if demoversion == g_game.G_VanillaVersionCode() then
        g_game.longtics = false
    elseif demoversion == doomtype.DOOM_191_VERSION then
        -- Demo recorded with cph's modified "v1.91" doom exe.
        g_game.longtics = true
    else
        local message = "Demo is from a different game version!\n" ..
            "(read %i, should be %i)\n\n" ..
            "*** You may need to upgrade your version of Doom to v1.9. ***\n" ..
            "    See: https://www.doomworld.com/classicdoom/info/patches.php\n" ..
            "    This appears to be %s."
        -- The C uses printf here (not I_Error) and continues.
        print(string.format(message, demoversion,
            g_game.G_VanillaVersionCode(), DemoVersionDescription(demoversion)))
    end

    skill = buffer.readu8(buf, g_game.demo_p); g_game.demo_p = g_game.demo_p + 1
    episode = buffer.readu8(buf, g_game.demo_p); g_game.demo_p = g_game.demo_p + 1
    map = buffer.readu8(buf, g_game.demo_p); g_game.demo_p = g_game.demo_p + 1
    doomstat.deathmatch = buffer.readu8(buf, g_game.demo_p); g_game.demo_p = g_game.demo_p + 1
    doomstat.respawnparm = buffer.readu8(buf, g_game.demo_p) ~= 0; g_game.demo_p = g_game.demo_p + 1
    doomstat.fastparm = buffer.readu8(buf, g_game.demo_p) ~= 0; g_game.demo_p = g_game.demo_p + 1
    doomstat.nomonsters = buffer.readu8(buf, g_game.demo_p) ~= 0; g_game.demo_p = g_game.demo_p + 1
    doomstat.consoleplayer = buffer.readu8(buf, g_game.demo_p); g_game.demo_p = g_game.demo_p + 1

    for i = 1, MAXPLAYERS do
        doomstat.playeringame[i] = buffer.readu8(buf, g_game.demo_p) ~= 0
        g_game.demo_p = g_game.demo_p + 1
    end

    if doomstat.playeringame[2] -- C playeringame[1]
        or m_argv.M_CheckParm("-solo-net") > 0
        or m_argv.M_CheckParm("-netdemo") > 0 then
        doomstat.netgame = true
        g_game.netdemo = true
    end

    -- Don't spend a lot of time in loadlevel.
    doomstat.precache = false
    g_game.G_InitNew(skill, episode, map)
    doomstat.precache = true
    g_game.starttime = i_timer.I_GetTime()

    g_game.usergame = false
    doomstat.usergame = false
    doomstat.demoplayback = true
end

-- G_TimeDemo.
function g_game.G_TimeDemo(name)
    -- Disable rendering the screen entirely (-nodraw).
    doomstat.nodrawers = m_argv.M_CheckParm("-nodraw") ~= 0

    g_game.timingdemo = true
    d_loop.singletics = true

    g_game.defdemoname = name
    g_game.gameaction = doomdef.ga_playdemo
end

-- G_CheckDemoStatus: called after a death or level completion to allow
-- demos to be cleaned up. Returns true if a new demo loop action will take
-- place.
function g_game.G_CheckDemoStatus()
    if g_game.timingdemo then
        local endtime = i_timer.I_GetTime()
        local realtics = endtime - g_game.starttime
        local fps = (d_loop.gametic * doomtype.TICRATE) / realtics

        -- Prevent recursive calls.
        g_game.timingdemo = false
        doomstat.demoplayback = false

        i_system.I_Error("timed %i gametics in %i realtics (%f fps)",
            d_loop.gametic, realtics, fps)
    end

    if doomstat.demoplayback then
        w_wad.W_ReleaseLumpName(g_game.defdemoname)
        doomstat.demoplayback = false
        g_game.netdemo = false
        doomstat.netgame = false
        doomstat.deathmatch = 0
        doomstat.playeringame[2] = false
        doomstat.playeringame[3] = false
        doomstat.playeringame[4] = false
        doomstat.respawnparm = false
        doomstat.fastparm = false
        doomstat.nomonsters = false
        doomstat.consoleplayer = 0

        if doomstat.singledemo then
            i_system.I_Quit()
        else
            d_main.D_AdvanceDemo()
        end

        return true
    end

    -- if demorecording then ... end -- cut in v1

    return false
end

-- ---------------------------------------------------------------------------
-- G_DeferedPlayDemo
-- ---------------------------------------------------------------------------

function g_game.G_DeferedPlayDemo(name)
    g_game.defdemoname = name
    g_game.gameaction = doomdef.ga_playdemo
end

-- ---------------------------------------------------------------------------
-- G_Ticker helpers used by the loop callbacks (G_BuildTiccmd is above).
-- ---------------------------------------------------------------------------

return g_game
end)()

m_menu = (function()
local m_menu = {}

local SCREENWIDTH = 320
local SCREENHEIGHT = 200

local SKULLXOFF = -32
local LINEHEIGHT = 16

local SAVESTRINGSIZE = 24
local NUM_QUITMESSAGES = 8

local HU_FONTSTART = 33 -- '!'
local HU_FONTSIZE = 63 -- HU_FONTEND('_') - HU_FONTSTART + 1

local function patch_short(patch, off)
    return buffer.readi16(patch.buffer, patch.offset + off)
end

local function hu_font_width(c)
    -- c is a 0-based glyph index (from toupper(ch) - HU_FONTSTART).
    local glyph = hu_stuff.hu_font[c + 1]
    if glyph == nil then
        return 0
    end
    return patch_short(glyph, 0)
end

local function hu_font_height()
    return patch_short(hu_stuff.hu_font[1], 2)
end

-- ---------------------------------------------------------------------------
-- Globals (C defaults)
-- ---------------------------------------------------------------------------

local screenSize = 0 -- temp for screenblocks (0-9)
local quickSaveSlot = -1 -- -1 = no quicksave slot picked!
local messageToPrint = 0 -- 1 = message to be printed
local messageString = nil -- ...and here is the message string!
local messageLastMenuActive = false
local messageNeedsInput = false -- timed message = no input from user
local messageRoutine = nil -- void (*messageRoutine)(int response)

local saveStringEnter = 0 -- we are going to be entering a savegame string
local saveSlot = 0 -- which slot to save in
local saveCharIndex = 0 -- which char we're editing
local saveOldString = "" -- old save description before edit

m_menu.inhelpscreens = false

local savegamestrings = {}
for _ = 1, 6 do
    table.insert(savegamestrings, dstrings.EMPTYSTRING)
end

local endstring = ""

-- Current menu state.
local currentMenu = nil
local itemOn = 0 -- menu item skull is on
local skullAnimCounter = 10 -- skull animation counter
local whichSkull = 0 -- which skull to draw
local skullName = { "M_SKULL1", "M_SKULL2" }

local epi = 0

local tempstring = ""

local detailNames = { "M_GDHIGH", "M_GDLOW" }
local msgNames = { "M_MSGOFF", "M_MSGON" }

local gammamsg = {
    dstrings.GAMMALVL0,
    dstrings.GAMMALVL1,
    dstrings.GAMMALVL2,
    dstrings.GAMMALVL3,
    dstrings.GAMMALVL4,
}

local quitsounds = {}
local quitsounds2 = {}

-- ---------------------------------------------------------------------------
-- Forward declarations (upvalues assigned below)
-- ---------------------------------------------------------------------------

local M_NewGame, M_Episode, M_ChooseSkill, M_LoadGame, M_SaveGame
local M_Options, M_EndGame, M_ReadThis, M_ReadThis2, M_QuitDOOM
local M_ChangeMessages, M_ChangeSensitivity, M_SfxVol, M_MusicVol
local M_ChangeDetail, M_SizeDisplay, M_Sound, M_FinishReadThis
local M_LoadSelect, M_SaveSelect, M_ReadSaveStrings, M_QuickSave, M_QuickLoad
local M_DrawMainMenu, M_DrawReadThis1, M_DrawReadThis2, M_DrawNewGame
local M_DrawEpisode, M_DrawOptions, M_DrawSound, M_DrawLoad, M_DrawSave
local M_DrawSaveLoadBorder, M_SetupNextMenu, M_DrawThermo, M_DrawEmptyCell
local M_DrawSelCell, M_WriteText, M_StringWidth, M_StringHeight
local M_StartMessage, M_StopMessage, M_ClearMenus, M_QuickSaveResponse
local M_QuickLoadResponse, M_VerifyNightmare, M_EndGameResponse, M_QuitResponse
local M_DoSave, M_SelectEndMessage, M_StartGame

local MainDef, EpiDef, NewDef, OptionsDef, ReadDef1, ReadDef2, SoundDef
local LoadDef, SaveDef
local MainMenu, EpisodeMenu, NewGameMenu, OptionsMenu, ReadMenu1, ReadMenu2
local SoundMenu, LoadMenu, SaveMenu

-- Menu item enums.
local newgame = 0
local options = 1
local loadgame = 2
local savegame = 3
local readthis = 4
local quitdoom = 5

local ep1 = 0
local ep2 = 1
local ep3 = 2
local ep4 = 3

local killthings = 0
local toorough = 1
local hurtme = 2
local violence = 3
local nightmare = 4

local endgame = 0
local messages = 1
local detail = 2
local scrnsize = 3
local option_empty1 = 4
local mousesens = 5
local option_empty2 = 6
local soundvol = 7

local rdthsempty1 = 0
local read1_end = 1
local rdthsempty2 = 0
local read2_end = 1

local sfx_vol = 0
local sfx_empty1 = 1
local music_vol = 2
local sfx_empty2 = 3
local sound_end = 4

local load1 = 0
local load2 = 1
local load3 = 2
local load4 = 3
local load5 = 4
local load6 = 5
local load_end = 6

-- ---------------------------------------------------------------------------
-- Function definitions
-- ---------------------------------------------------------------------------

-- M_ReadSaveStrings: read the strings from the savegame files. Savegames
-- are cut in v1 (no filesystem), so all slots are the empty-slot case.
M_ReadSaveStrings = function()
    for i = 0, load_end - 1 do
        savegamestrings[i + 1] = dstrings.EMPTYSTRING
        LoadMenu[i + 1].status = 0
    end
end

-- M_DrawLoad.
M_DrawLoad = function()
    local i

    v_video.V_DrawPatchDirect(72, 28,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_LOADG"), z_zone.PU_CACHE))

    for i = 0, load_end - 1 do
        M_DrawSaveLoadBorder(LoadDef.x, LoadDef.y + LINEHEIGHT * i)
        M_WriteText(LoadDef.x, LoadDef.y + LINEHEIGHT * i, savegamestrings[i + 1])
    end
end

-- Draw border for the savegame description.
M_DrawSaveLoadBorder = function(x, y)
    local i

    v_video.V_DrawPatchDirect(x - 8, y + 7,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_LSLEFT"), z_zone.PU_CACHE))

    for i = 0, 23 do
        v_video.V_DrawPatchDirect(x, y + 7,
            w_wad.W_CacheLumpName(deh_str.DEH_String("M_LSCNTR"), z_zone.PU_CACHE))
        x = x + 8
    end

    v_video.V_DrawPatchDirect(x, y + 7,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_LSRGHT"), z_zone.PU_CACHE))
end

-- User wants to load this game.
M_LoadSelect = function(choice)
    g_game.G_LoadGame("")
    M_ClearMenus()
end

-- Selected from DOOM menu.
M_LoadGame = function(choice)
    if doomstat.netgame then
        M_StartMessage(deh_str.DEH_String(dstrings.LOADNET), nil, false)
        return
    end

    M_SetupNextMenu(LoadDef)
    M_ReadSaveStrings()
end

-- M_DrawSave.
M_DrawSave = function()
    local i

    v_video.V_DrawPatchDirect(72, 28,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_SAVEG"), z_zone.PU_CACHE))
    for i = 0, load_end - 1 do
        M_DrawSaveLoadBorder(LoadDef.x, LoadDef.y + LINEHEIGHT * i)
        M_WriteText(LoadDef.x, LoadDef.y + LINEHEIGHT * i, savegamestrings[i + 1])
    end

    if saveStringEnter ~= 0 then
        i = M_StringWidth(savegamestrings[saveSlot + 1])
        M_WriteText(LoadDef.x + i, LoadDef.y + LINEHEIGHT * saveSlot, "_")
    end
end

-- M_Responder calls this when user is finished.
M_DoSave = function(slot)
    g_game.G_SaveGame(slot, savegamestrings[slot + 1])
    M_ClearMenus()

    -- PICK QUICKSAVE SLOT YET?
    if quickSaveSlot == -2 then
        quickSaveSlot = slot
    end
end

-- User wants to save. Start string input for M_Responder.
M_SaveSelect = function(choice)
    -- We are going to be intercepting all chars.
    saveStringEnter = 1

    saveSlot = choice
    saveOldString = savegamestrings[choice + 1]
    if savegamestrings[choice + 1] == dstrings.EMPTYSTRING then
        savegamestrings[choice + 1] = ""
    end
    saveCharIndex = #savegamestrings[choice + 1]
end

-- Selected from DOOM menu.
M_SaveGame = function(choice)
    if not doomstat.usergame then
        M_StartMessage(deh_str.DEH_String(dstrings.SAVEDEAD), nil, false)
        return
    end

    if doomstat.gamestate ~= doomdef.GS_LEVEL then
        return
    end

    M_SetupNextMenu(SaveDef)
    M_ReadSaveStrings()
end

M_QuickSaveResponse = function(key)
    if key == m_controls.key_menu_confirm then
        M_DoSave(quickSaveSlot)
        s_sound.S_StartSound(nil, 0)
    end
end

M_QuickSave = function()
    if not doomstat.usergame then
        s_sound.S_StartSound(nil, 0)
        return
    end

    if doomstat.gamestate ~= doomdef.GS_LEVEL then
        return
    end

    if quickSaveSlot < 0 then
        m_menu.M_StartControlPanel()
        M_ReadSaveStrings()
        M_SetupNextMenu(SaveDef)
        quickSaveSlot = -2 -- means to pick a slot now
        return
    end
    tempstring = m_misc.M_snprintf(dstrings.QSPROMPT, savegamestrings[quickSaveSlot + 1])
    M_StartMessage(tempstring, M_QuickSaveResponse, true)
end

M_QuickLoadResponse = function(key)
    if key == m_controls.key_menu_confirm then
        M_LoadSelect(quickSaveSlot)
        s_sound.S_StartSound(nil, 0)
    end
end

M_QuickLoad = function()
    if doomstat.netgame then
        M_StartMessage(deh_str.DEH_String(dstrings.QLOADNET), nil, false)
        return
    end

    if quickSaveSlot < 0 then
        M_StartMessage(deh_str.DEH_String(dstrings.QSAVESPOT), nil, false)
        return
    end
    tempstring = m_misc.M_snprintf(dstrings.QLPROMPT, savegamestrings[quickSaveSlot + 1])
    M_StartMessage(tempstring, M_QuickLoadResponse, true)
end

-- Read This Menus.
M_DrawReadThis1 = function()
    local lumpname = "CREDIT"
    local skullx = 330
    local skully = 175

    m_menu.inhelpscreens = true

    -- Different versions of Doom 1.9 work differently.
    if doomstat.gameversion == d_mode.exe_doom_1_666
        or doomstat.gameversion == d_mode.exe_doom_1_7
        or doomstat.gameversion == d_mode.exe_doom_1_8
        or doomstat.gameversion == d_mode.exe_doom_1_9
        or doomstat.gameversion == d_mode.exe_hacx then
        if doomstat.gamemode == d_mode.commercial then
            -- Doom 2.
            lumpname = "HELP"
            skullx = 330
            skully = 165
        else
            -- Doom 1. HELP2 is the first screen shown in Doom 1.
            lumpname = "HELP2"
            skullx = 280
            skully = 185
        end
    elseif doomstat.gameversion == d_mode.exe_ultimate
        or doomstat.gameversion == d_mode.exe_chex then
        -- Ultimate Doom always displays "HELP1".
        lumpname = "HELP1"
    elseif doomstat.gameversion == d_mode.exe_final
        or doomstat.gameversion == d_mode.exe_final2 then
        -- Final Doom always displays "HELP".
        lumpname = "HELP"
    else
        i_system.I_Error("Unhandled game version")
    end

    lumpname = deh_str.DEH_String(lumpname)

    v_video.V_DrawPatchDirect(0, 0,
        w_wad.W_CacheLumpName(lumpname, z_zone.PU_CACHE))

    ReadDef1.x = skullx
    ReadDef1.y = skully
end

-- Read This Menus - optional second page.
M_DrawReadThis2 = function()
    m_menu.inhelpscreens = true

    -- We only ever draw the second page if this is gameversion ==
    -- exe_doom_1_9 and gamemode == registered.
    v_video.V_DrawPatchDirect(0, 0,
        w_wad.W_CacheLumpName(deh_str.DEH_String("HELP1"), z_zone.PU_CACHE))
end

-- Change Sfx & Music volumes.
M_DrawSound = function()
    v_video.V_DrawPatchDirect(60, 38,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_SVOL"), z_zone.PU_CACHE))

    M_DrawThermo(SoundDef.x, SoundDef.y + LINEHEIGHT * (sfx_vol + 1),
        16, doomstat.sfxVolume)

    M_DrawThermo(SoundDef.x, SoundDef.y + LINEHEIGHT * (music_vol + 1),
        16, doomstat.musicVolume)
end

M_Sound = function(choice)
    M_SetupNextMenu(SoundDef)
end

M_SfxVol = function(choice)
    if choice == 0 then
        if doomstat.sfxVolume ~= 0 then
            doomstat.sfxVolume = doomstat.sfxVolume - 1
        end
    elseif choice == 1 then
        if doomstat.sfxVolume < 15 then
            doomstat.sfxVolume = doomstat.sfxVolume + 1
        end
    end

    s_sound.S_SetSfxVolume(doomstat.sfxVolume * 8)
end

M_MusicVol = function(choice)
    if choice == 0 then
        if doomstat.musicVolume ~= 0 then
            doomstat.musicVolume = doomstat.musicVolume - 1
        end
    elseif choice == 1 then
        if doomstat.musicVolume < 15 then
            doomstat.musicVolume = doomstat.musicVolume + 1
        end
    end

    s_sound.S_SetMusicVolume(doomstat.musicVolume * 8)
end

M_DrawMainMenu = function()
    v_video.V_DrawPatchDirect(94, 2,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_DOOM"), z_zone.PU_CACHE))
end

M_DrawNewGame = function()
    v_video.V_DrawPatchDirect(96, 14,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_NEWG"), z_zone.PU_CACHE))
    v_video.V_DrawPatchDirect(54, 38,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_SKILL"), z_zone.PU_CACHE))
end

M_NewGame = function(choice)
    if doomstat.netgame and not doomstat.demoplayback then
        M_StartMessage(deh_str.DEH_String(dstrings.NEWGAME), nil, false)
        return
    end

    -- Chex Quest disabled the episode select screen, as did Doom II.
    if doomstat.gamemode == d_mode.commercial
        or doomstat.gameversion == d_mode.exe_chex then
        M_SetupNextMenu(NewDef)
    else
        M_SetupNextMenu(EpiDef)
    end
end

M_DrawEpisode = function()
    v_video.V_DrawPatchDirect(54, 38,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_EPISOD"), z_zone.PU_CACHE))
end

M_VerifyNightmare = function(key)
    if key ~= m_controls.key_menu_confirm then
        return
    end

    g_game.G_DeferedInitNew(nightmare, epi + 1, 1)
    M_ClearMenus()
end

M_ChooseSkill = function(choice)
    if choice == nightmare then
        M_StartMessage(deh_str.DEH_String(dstrings.NIGHTMARE), M_VerifyNightmare, true)
        return
    end

    g_game.G_DeferedInitNew(choice, epi + 1, 1)
    M_ClearMenus()
end

M_Episode = function(choice)
    if doomstat.gamemode == d_mode.shareware and choice ~= 0 then
        M_StartMessage(deh_str.DEH_String(dstrings.SWSTRING), nil, false)
        M_SetupNextMenu(ReadDef1)
        return
    end

    -- Yet another hack...
    if doomstat.gamemode == d_mode.registered and choice > 2 then
        print("M_Episode: 4th episode requires UltimateDOOM")
        choice = 0
    end

    epi = choice
    M_SetupNextMenu(NewDef)
end

M_DrawOptions = function()
    v_video.V_DrawPatchDirect(108, 15,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_OPTTTL"), z_zone.PU_CACHE))

    v_video.V_DrawPatchDirect(OptionsDef.x + 175, OptionsDef.y + LINEHEIGHT * doomstat.detailLevel,
        w_wad.W_CacheLumpName(deh_str.DEH_String(detailNames[doomstat.detailLevel + 1]),
            z_zone.PU_CACHE))

    v_video.V_DrawPatchDirect(OptionsDef.x + 120, OptionsDef.y + LINEHEIGHT * doomstat.showMessages,
        w_wad.W_CacheLumpName(deh_str.DEH_String(msgNames[doomstat.showMessages + 1]),
            z_zone.PU_CACHE))

    M_DrawThermo(OptionsDef.x, OptionsDef.y + LINEHEIGHT * (mousesens + 1),
        10, doomstat.mouseSensitivity)

    M_DrawThermo(OptionsDef.x, OptionsDef.y + LINEHEIGHT * (scrnsize + 1),
        9, screenSize)
end

M_Options = function(choice)
    M_SetupNextMenu(OptionsDef)
end

-- Toggle messages on/off.
M_ChangeMessages = function(choice)
    choice = 0
    doomstat.showMessages = 1 - doomstat.showMessages

    if doomstat.showMessages == 0 then
        doomstat.players[doomstat.consoleplayer + 1].message =
            deh_str.DEH_String(dstrings.MSGOFF)
    else
        doomstat.players[doomstat.consoleplayer + 1].message =
            deh_str.DEH_String(dstrings.MSGON)
    end

    hu_stuff.message_dontfuckwithme = true
end

M_EndGameResponse = function(key)
    if key ~= m_controls.key_menu_confirm then
        return
    end

    currentMenu.lastOn = itemOn
    M_ClearMenus()
    d_main.D_StartTitle()
end

M_EndGame = function(choice)
    choice = 0
    if not doomstat.usergame then
        s_sound.S_StartSound(nil, 0)
        return
    end

    if doomstat.netgame then
        M_StartMessage(deh_str.DEH_String(dstrings.NETEND), nil, false)
        return
    end

    M_StartMessage(deh_str.DEH_String(dstrings.ENDGAME), M_EndGameResponse, true)
end

M_ReadThis = function(choice)
    choice = 0
    M_SetupNextMenu(ReadDef1)
end

M_ReadThis2 = function(choice)
    -- Doom 1.9 had two menus when playing Doom 1; all others had only one.
    if doomstat.gameversion <= d_mode.exe_doom_1_9
        and doomstat.gamemode ~= d_mode.commercial then
        choice = 0
        M_SetupNextMenu(ReadDef2)
    else
        -- Close the menu.
        M_FinishReadThis(0)
    end
end

M_FinishReadThis = function(choice)
    choice = 0
    M_SetupNextMenu(MainDef)
end

M_QuitResponse = function(key)
    if key ~= m_controls.key_menu_confirm then
        return
    end
    if not doomstat.netgame then
        if doomstat.gamemode == d_mode.commercial then
            s_sound.S_StartSound(nil, quitsounds2[((d_loop.gametic // 4) % 8) + 1])
        else
            s_sound.S_StartSound(nil, quitsounds[((d_loop.gametic // 4) % 8) + 1])
        end
        i_timer.I_WaitVBL(105)
    end
    i_system.I_Quit()
end

M_SelectEndMessage = function()
    local endmsg

    -- Logical gamemission.
    local gamemission = doomstat.gamemission
    if gamemission == d_mode.pack_chex then
        gamemission = d_mode.doom
    elseif gamemission == d_mode.pack_hacx then
        gamemission = d_mode.doom2
    end

    if gamemission == d_mode.doom then
        -- Doom 1.
        endmsg = dstrings.doom1_endmsg
    else
        -- Doom 2.
        endmsg = dstrings.doom2_endmsg
    end

    return endmsg[(d_loop.gametic % NUM_QUITMESSAGES) + 1]
end

M_QuitDOOM = function(choice)
    endstring = m_misc.M_snprintf("%s\n\n" .. dstrings.DOSY,
        deh_str.DEH_String(M_SelectEndMessage()))

    M_StartMessage(endstring, M_QuitResponse, true)
end

M_ChangeSensitivity = function(choice)
    if choice == 0 then
        if doomstat.mouseSensitivity ~= 0 then
            doomstat.mouseSensitivity = doomstat.mouseSensitivity - 1
        end
    elseif choice == 1 then
        if doomstat.mouseSensitivity < 9 then
            doomstat.mouseSensitivity = doomstat.mouseSensitivity + 1
        end
    end
end

M_ChangeDetail = function(choice)
    choice = 0
    doomstat.detailLevel = 1 - doomstat.detailLevel

    r_main.R_SetViewSize(doomstat.screenblocks, doomstat.detailLevel)

    if doomstat.detailLevel == 0 then
        doomstat.players[doomstat.consoleplayer + 1].message =
            deh_str.DEH_String(dstrings.DETAILHI)
    else
        doomstat.players[doomstat.consoleplayer + 1].message =
            deh_str.DEH_String(dstrings.DETAILLO)
    end
end

M_SizeDisplay = function(choice)
    if choice == 0 then
        if screenSize > 0 then
            doomstat.screenblocks = doomstat.screenblocks - 1
            screenSize = screenSize - 1
        end
    elseif choice == 1 then
        if screenSize < 8 then
            doomstat.screenblocks = doomstat.screenblocks + 1
            screenSize = screenSize + 1
        end
    end

    r_main.R_SetViewSize(doomstat.screenblocks, doomstat.detailLevel)
end

M_StartGame = function(choice)
    -- Unused in the Doom build; kept for parity.
end

M_DrawThermo = function(x, y, thermWidth, thermDot)
    local xx
    local i

    xx = x
    v_video.V_DrawPatchDirect(xx, y,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_THERML"), z_zone.PU_CACHE))
    xx = xx + 8
    for i = 0, thermWidth - 1 do
        v_video.V_DrawPatchDirect(xx, y,
            w_wad.W_CacheLumpName(deh_str.DEH_String("M_THERMM"), z_zone.PU_CACHE))
        xx = xx + 8
    end
    v_video.V_DrawPatchDirect(xx, y,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_THERMR"), z_zone.PU_CACHE))

    v_video.V_DrawPatchDirect((x + 8) + thermDot * 8, y,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_THERMO"), z_zone.PU_CACHE))
end

M_DrawEmptyCell = function(menu, item)
    v_video.V_DrawPatchDirect(menu.x - 10, menu.y + item * LINEHEIGHT - 1,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_CELL1"), z_zone.PU_CACHE))
end

M_DrawSelCell = function(menu, item)
    v_video.V_DrawPatchDirect(menu.x - 10, menu.y + item * LINEHEIGHT - 1,
        w_wad.W_CacheLumpName(deh_str.DEH_String("M_CELL2"), z_zone.PU_CACHE))
end

M_StartMessage = function(string_, routine, input)
    messageLastMenuActive = doomstat.menuactive
    messageToPrint = 1
    messageString = string_
    messageRoutine = routine
    messageNeedsInput = input
    doomstat.menuactive = true
end

M_StopMessage = function()
    doomstat.menuactive = messageLastMenuActive
    messageToPrint = 0
end

-- Find string width from hu_font chars.
M_StringWidth = function(string_)
    local w = 0
    local c

    for i = 1, #string_ do
        c = string.byte(string.upper(string_), i) - HU_FONTSTART
        if c < 0 or c >= HU_FONTSIZE then
            w = w + 4
        else
            w = w + hu_font_width(c)
        end
    end

    return w
end

-- Find string height from hu_font chars.
M_StringHeight = function(string_)
    local h = hu_font_height()

    for i = 1, #string_ do
        if string.byte(string_, i) == 10 then -- '\n'
            h = h + hu_font_height()
        end
    end

    return h
end

-- Write a string using the hu_font.
M_WriteText = function(x, y, string_)
    local w
    local c
    local cx
    local cy

    cx = x
    cy = y
    local ch = 1

    while true do
        c = string.byte(string_, ch)
        ch = ch + 1
        if not c or c == 0 then
            break
        end
        if c == 10 then -- '\n'
            cx = x
            cy = cy + 12
        else
            c = string.byte(string.upper(string.char(c))) - HU_FONTSTART
            if c < 0 or c >= HU_FONTSIZE then
                cx = cx + 4
            else
                local glyph = hu_stuff.hu_font[c + 1]
                if glyph == nil then
                    cx = cx + 4
                else
                    w = patch_short(glyph, 0)
                    if cx + w > SCREENWIDTH then
                        break
                    end
                    v_video.V_DrawPatchDirect(cx, cy, glyph)
                    cx = cx + w
                end
            end
        end
    end
end

-- These keys evaluate to a "null" key in Vanilla Doom that allows weird
-- jumping in the menus. Preserve this behavior for accuracy.
local function IsNullKey(key)
    return key == doomkeys.KEY_PAUSE or key == doomkeys.KEY_CAPSLOCK
        or key == doomkeys.KEY_SCRLCK or key == doomkeys.KEY_NUMLOCK
end

-- ---------------------------------------------------------------------------
-- M_Responder
-- ---------------------------------------------------------------------------

local joywait = 0
local mousewait = 0
local mousey = 0
local lasty = 0
local mousex = 0
local lastx = 0

function m_menu.M_Responder(ev)
    local ch
    local key
    local i

    -- In testcontrols mode, none of the function keys should do anything:
    -- the only key is escape to quit.
    if doomstat.testcontrols then
        if ev.type == 4 -- ev_quit
            or (ev.type == 0 -- ev_keydown
                and (ev.data1 == m_controls.key_menu_activate
                    or ev.data1 == m_controls.key_menu_quit)) then
            i_system.I_Quit()
            return true
        end

        return false
    end

    -- "close" button pressed on window?
    if ev.type == 4 then -- ev_quit
        -- First click on close button = bring up quit confirm message.
        -- Second click on close button = confirm quit.
        if doomstat.menuactive and messageToPrint ~= 0 and messageRoutine == M_QuitResponse then
            M_QuitResponse(m_controls.key_menu_confirm)
        else
            s_sound.S_StartSound(nil, 0)
            M_QuitDOOM(0)
        end

        return true
    end

    -- key is the key pressed, ch is the actual character typed.
    ch = 0
    key = -1

    if ev.type == 3 -- ev_joystick
        and joywait < i_timer.I_GetTime() then
        if ev.data3 < 0 then
            key = m_controls.key_menu_up
            joywait = i_timer.I_GetTime() + 5
        elseif ev.data3 > 0 then
            key = m_controls.key_menu_down
            joywait = i_timer.I_GetTime() + 5
        end

        if ev.data2 < 0 then
            key = m_controls.key_menu_left
            joywait = i_timer.I_GetTime() + 2
        elseif ev.data2 > 0 then
            key = m_controls.key_menu_right
            joywait = i_timer.I_GetTime() + 2
        end

        if bit32.band(ev.data1, 1) ~= 0 then
            key = m_controls.key_menu_forward
            joywait = i_timer.I_GetTime() + 5
        end
        if bit32.band(ev.data1, 2) ~= 0 then
            key = m_controls.key_menu_back
            joywait = i_timer.I_GetTime() + 5
        end
        if m_controls.joybmenu >= 0 and bit32.band(ev.data1, bit32.lshift(1, m_controls.joybmenu)) ~= 0 then
            key = m_controls.key_menu_activate
            joywait = i_timer.I_GetTime() + 5
        end
    elseif ev.type == 2 -- ev_mouse
        and mousewait < i_timer.I_GetTime() then
        mousey = mousey + ev.data3
        if mousey < lasty - 30 then
            key = m_controls.key_menu_down
            mousewait = i_timer.I_GetTime() + 5
            mousey = lasty - 30
            lasty = lasty - 30
        elseif mousey > lasty + 30 then
            key = m_controls.key_menu_up
            mousewait = i_timer.I_GetTime() + 5
            mousey = lasty + 30
            lasty = lasty + 30
        end

        mousex = mousex + ev.data2
        if mousex < lastx - 30 then
            key = m_controls.key_menu_left
            mousewait = i_timer.I_GetTime() + 5
            mousex = lastx - 30
            lastx = lastx - 30
        elseif mousex > lastx + 30 then
            key = m_controls.key_menu_right
            mousewait = i_timer.I_GetTime() + 5
            mousex = lastx + 30
            lastx = lastx + 30
        end

        if bit32.band(ev.data1, 1) ~= 0 then
            key = m_controls.key_menu_forward
            mousewait = i_timer.I_GetTime() + 15
        end

        if bit32.band(ev.data1, 2) ~= 0 then
            key = m_controls.key_menu_back
            mousewait = i_timer.I_GetTime() + 15
        end
    else
        if ev.type == 0 then -- ev_keydown
            key = ev.data1
            ch = ev.data2
        end
    end

    if key == -1 then
        return false
    end

    -- Save Game string input.
    if saveStringEnter ~= 0 then
        if key == doomkeys.KEY_BACKSPACE then
            if saveCharIndex > 0 then
                saveCharIndex = saveCharIndex - 1
                savegamestrings[saveSlot + 1] =
                    string.sub(savegamestrings[saveSlot + 1], 1, saveCharIndex)
            end
        elseif key == doomkeys.KEY_ESCAPE then
            saveStringEnter = 0
            savegamestrings[saveSlot + 1] = saveOldString
        elseif key == doomkeys.KEY_ENTER then
            saveStringEnter = 0
            if savegamestrings[saveSlot + 1] ~= "" then
                M_DoSave(saveSlot)
            end
        else
            -- This is complicated. Vanilla has a bug where the shift key is
            -- ignored when entering a savegame name. If
            -- vanilla_keyboard_mapping is on, we want to emulate this bug by
            -- using 'data1'. But if it's turned off, it implies the user
            -- doesn't care about Vanilla emulation: just use the correct
            -- 'data2'.
            if i_input.vanilla_keyboard_mapping ~= 0 then
                ch = key
            end

            ch = string.byte(string.upper(string.char(ch)))

            if ch ~= 32 -- ' '
                and (ch - HU_FONTSTART < 0 or ch - HU_FONTSTART >= HU_FONTSIZE) then
                -- break
            elseif ch >= 32 and ch <= 127
                and saveCharIndex < SAVESTRINGSIZE - 1
                and M_StringWidth(savegamestrings[saveSlot + 1]) < (SAVESTRINGSIZE - 2) * 8 then
                savegamestrings[saveSlot + 1] =
                    savegamestrings[saveSlot + 1] .. string.char(ch)
                saveCharIndex = saveCharIndex + 1
            end
        end
        return true
    end

    -- Take care of any messages that need input.
    if messageToPrint ~= 0 then
        if messageNeedsInput then
            if key ~= 32 -- ' '
                and key ~= doomkeys.KEY_ESCAPE
                and key ~= m_controls.key_menu_confirm
                and key ~= m_controls.key_menu_abort then
                return false
            end
        end

        doomstat.menuactive = messageLastMenuActive
        messageToPrint = 0
        if messageRoutine ~= nil then
            messageRoutine(key)
        end

        doomstat.menuactive = false
        s_sound.S_StartSound(nil, 0)
        return true
    end

    if (doomstat.devparm and key == m_controls.key_menu_help)
        or (key ~= 0 and key == m_controls.key_menu_screenshot) then
        g_game.G_ScreenShot()
        return true
    end

    -- F-Keys.
    if not doomstat.menuactive then
        if key == m_controls.key_menu_decscreen then -- Screen size down
            if doomstat.automapactive or hu_stuff.chat_on then
                return false
            end
            M_SizeDisplay(0)
            s_sound.S_StartSound(nil, 0)
            return true
        elseif key == m_controls.key_menu_incscreen then -- Screen size up
            if doomstat.automapactive or hu_stuff.chat_on then
                return false
            end
            M_SizeDisplay(1)
            s_sound.S_StartSound(nil, 0)
            return true
        elseif key == m_controls.key_menu_help then -- Help key
            m_menu.M_StartControlPanel()

            if doomstat.gamemode == d_mode.retail then
                currentMenu = ReadDef2
            else
                currentMenu = ReadDef1
            end

            itemOn = 0
            s_sound.S_StartSound(nil, 0)
            return true
        elseif key == m_controls.key_menu_save then -- Save
            m_menu.M_StartControlPanel()
            s_sound.S_StartSound(nil, 0)
            M_SaveGame(0)
            return true
        elseif key == m_controls.key_menu_load then -- Load
            m_menu.M_StartControlPanel()
            s_sound.S_StartSound(nil, 0)
            M_LoadGame(0)
            return true
        elseif key == m_controls.key_menu_volume then -- Sound Volume
            m_menu.M_StartControlPanel()
            currentMenu = SoundDef
            itemOn = sfx_vol
            s_sound.S_StartSound(nil, 0)
            return true
        elseif key == m_controls.key_menu_detail then -- Detail toggle
            M_ChangeDetail(0)
            s_sound.S_StartSound(nil, 0)
            return true
        elseif key == m_controls.key_menu_qsave then -- Quicksave
            s_sound.S_StartSound(nil, 0)
            M_QuickSave()
            return true
        elseif key == m_controls.key_menu_endgame then -- End game
            s_sound.S_StartSound(nil, 0)
            M_EndGame(0)
            return true
        elseif key == m_controls.key_menu_messages then -- Toggle messages
            M_ChangeMessages(0)
            s_sound.S_StartSound(nil, 0)
            return true
        elseif key == m_controls.key_menu_qload then -- Quickload
            s_sound.S_StartSound(nil, 0)
            M_QuickLoad()
            return true
        elseif key == m_controls.key_menu_quit then -- Quit DOOM
            s_sound.S_StartSound(nil, 0)
            M_QuitDOOM(0)
            return true
        elseif key == m_controls.key_menu_gamma then -- gamma toggle
            i_video.usegamma = i_video.usegamma + 1
            if i_video.usegamma > 4 then
                i_video.usegamma = 0
            end
            doomstat.players[doomstat.consoleplayer + 1].message =
                deh_str.DEH_String(gammamsg[i_video.usegamma + 1])
            local playpal = w_wad.W_CacheLumpName(deh_str.DEH_String("PLAYPAL"), z_zone.PU_CACHE)
            i_video.I_SetPalette(playpal.buffer, playpal.offset)
            return true
        end
    end

    -- Pop-up menu?
    if not doomstat.menuactive then
        if key == m_controls.key_menu_activate then
            m_menu.M_StartControlPanel()
            s_sound.S_StartSound(nil, 0)
            return true
        end
        return false
    end

    -- Keys usable within menu.
    if key == m_controls.key_menu_down then
        -- Move down to next item.
        repeat
            if itemOn + 1 > currentMenu.numitems - 1 then
                itemOn = 0
            else
                itemOn = itemOn + 1
            end
            s_sound.S_StartSound(nil, 0)
        until currentMenu.menuitems[itemOn + 1].status ~= -1

        return true
    elseif key == m_controls.key_menu_up then
        -- Move back up to previous item.
        repeat
            if itemOn == 0 then
                itemOn = currentMenu.numitems - 1
            else
                itemOn = itemOn - 1
            end
            s_sound.S_StartSound(nil, 0)
        until currentMenu.menuitems[itemOn + 1].status ~= -1

        return true
    elseif key == m_controls.key_menu_left then
        -- Slide slider left.
        if currentMenu.menuitems[itemOn + 1].routine ~= nil
            and currentMenu.menuitems[itemOn + 1].status == 2 then
            s_sound.S_StartSound(nil, 0)
            currentMenu.menuitems[itemOn + 1].routine(0)
        end
        return true
    elseif key == m_controls.key_menu_right then
        -- Slide slider right.
        if currentMenu.menuitems[itemOn + 1].routine ~= nil
            and currentMenu.menuitems[itemOn + 1].status == 2 then
            s_sound.S_StartSound(nil, 0)
            currentMenu.menuitems[itemOn + 1].routine(1)
        end
        return true
    elseif key == m_controls.key_menu_forward then
        -- Activate menu item.
        if currentMenu.menuitems[itemOn + 1].routine ~= nil
            and currentMenu.menuitems[itemOn + 1].status ~= 0 then
            currentMenu.lastOn = itemOn
            if currentMenu.menuitems[itemOn + 1].status == 2 then
                currentMenu.menuitems[itemOn + 1].routine(1) -- right arrow
                s_sound.S_StartSound(nil, 0)
            else
                currentMenu.menuitems[itemOn + 1].routine(itemOn)
                s_sound.S_StartSound(nil, 0)
            end
        end
        return true
    elseif key == m_controls.key_menu_activate then
        -- Deactivate menu.
        currentMenu.lastOn = itemOn
        M_ClearMenus()
        s_sound.S_StartSound(nil, 0)
        return true
    elseif key == m_controls.key_menu_back then
        -- Go back to previous menu.
        currentMenu.lastOn = itemOn
        if currentMenu.prevMenu ~= nil then
            currentMenu = currentMenu.prevMenu
            itemOn = currentMenu.lastOn
            s_sound.S_StartSound(nil, 0)
        end
        return true
    end

    -- Keyboard shortcut? Vanilla Doom has a weird behavior where it jumps
    -- to the scroll bars when certain keys are pressed, so emulate this.
    if ch ~= 0 or IsNullKey(key) then
        for i = itemOn + 1, currentMenu.numitems - 1 do
            if currentMenu.menuitems[i + 1].alphaKey == ch then
                itemOn = i
                s_sound.S_StartSound(nil, 0)
                return true
            end
        end

        for i = 0, itemOn do
            if currentMenu.menuitems[i + 1].alphaKey == ch then
                itemOn = i
                s_sound.S_StartSound(nil, 0)
                return true
            end
        end
    end

    return false
end

-- ---------------------------------------------------------------------------
-- M_StartControlPanel
-- ---------------------------------------------------------------------------

function m_menu.M_StartControlPanel()
    -- Intro might call this repeatedly.
    if doomstat.menuactive then
        return
    end

    doomstat.menuactive = true
    currentMenu = MainDef -- JDC
    itemOn = currentMenu.lastOn -- JDC
end

-- ---------------------------------------------------------------------------
-- M_Drawer
-- ---------------------------------------------------------------------------

function m_menu.M_Drawer()
    local x
    local y
    local i
    local max
    local name

    m_menu.inhelpscreens = false

    -- Horiz. & Vertically center string and print it.
    if messageToPrint ~= 0 and messageString ~= nil then
        local y = SCREENHEIGHT // 2 - M_StringHeight(messageString) // 2
        local remaining = messageString
        while #remaining > 0 do
            local foundnewline = false
            local line = remaining

            -- Find the first newline in the remaining text.
            for i = 1, #remaining do
                if string.byte(remaining, i) == 10 then -- '\n'
                    line = m_misc.M_StringCopy(string.sub(remaining, 1, i - 1), 80)
                    remaining = string.sub(remaining, i + 1)
                    foundnewline = true
                    break
                end
            end

            if not foundnewline then
                line = m_misc.M_StringCopy(remaining, 80)
                remaining = ""
            end

            x = SCREENWIDTH // 2 - M_StringWidth(line) // 2
            M_WriteText(x, y, line)
            y = y + hu_font_height()
        end
        return
    end

    if not doomstat.menuactive then
        return
    end

    if currentMenu.routine ~= nil then
        currentMenu.routine() -- call Draw routine
    end

    -- DRAW MENU.
    x = currentMenu.x
    y = currentMenu.y
    max = currentMenu.numitems

    for i = 0, max - 1 do
        name = deh_str.DEH_String(currentMenu.menuitems[i + 1].name)
        if name ~= "" then
            v_video.V_DrawPatchDirect(x, y,
                w_wad.W_CacheLumpName(name, z_zone.PU_CACHE))
        end
        y = y + LINEHEIGHT
    end

    -- DRAW SKULL.
    v_video.V_DrawPatchDirect(x + SKULLXOFF, currentMenu.y - 5 + itemOn * LINEHEIGHT,
        w_wad.W_CacheLumpName(deh_str.DEH_String(skullName[whichSkull + 1]),
            z_zone.PU_CACHE))
end

-- ---------------------------------------------------------------------------
-- M_ClearMenus
-- ---------------------------------------------------------------------------

function M_ClearMenus()
    doomstat.menuactive = false
end

-- ---------------------------------------------------------------------------
-- M_SetupNextMenu
-- ---------------------------------------------------------------------------

function M_SetupNextMenu(menudef)
    currentMenu = menudef
    itemOn = currentMenu.lastOn
end

-- ---------------------------------------------------------------------------
-- M_Ticker
-- ---------------------------------------------------------------------------

function m_menu.M_Ticker()
    skullAnimCounter = skullAnimCounter - 1
    if skullAnimCounter <= 0 then
        whichSkull = bit32.bxor(whichSkull, 1)
        skullAnimCounter = 8
    end
end

-- ---------------------------------------------------------------------------
-- M_Init
-- ---------------------------------------------------------------------------

function m_menu.M_Init()
    currentMenu = MainDef
    doomstat.menuactive = false
    itemOn = currentMenu.lastOn
    whichSkull = 0
    skullAnimCounter = 10
    screenSize = doomstat.screenblocks - 3
    messageToPrint = 0
    messageString = nil
    messageLastMenuActive = doomstat.menuactive
    quickSaveSlot = -1

    -- Here we could catch other version dependencies, like HELP1/2, and
    -- four episodes.

    if doomstat.gamemode == d_mode.commercial then
        -- Commercial has no "read this" entry.
        MainMenu[readthis + 1] = MainMenu[quitdoom + 1]
        MainDef.numitems = MainDef.numitems - 1
        MainDef.y = MainDef.y + 8
        NewDef.prevMenu = MainDef
    end

    -- Versions of doom.exe before the Ultimate Doom release only had three
    -- episodes; if we're emulating one of those then don't try to show
    -- episode four.
    if doomstat.gameversion < d_mode.exe_ultimate then
        EpiDef.numitems = EpiDef.numitems - 1
    end
end

-- ---------------------------------------------------------------------------
-- Menu tables (built after the functions so the routine fields hold the
-- real implementations).
-- ---------------------------------------------------------------------------

MainMenu = {
    { status = 1, name = "M_NGAME", routine = M_NewGame, alphaKey = string.byte("n") },
    { status = 1, name = "M_OPTION", routine = M_Options, alphaKey = string.byte("o") },
    { status = 1, name = "M_LOADG", routine = M_LoadGame, alphaKey = string.byte("l") },
    { status = 1, name = "M_SAVEG", routine = M_SaveGame, alphaKey = string.byte("s") },
    { status = 1, name = "M_RDTHIS", routine = M_ReadThis, alphaKey = string.byte("r") },
    { status = 1, name = "M_QUITG", routine = M_QuitDOOM, alphaKey = string.byte("q") },
}

MainDef = {
    numitems = 6,
    prevMenu = nil,
    menuitems = MainMenu,
    routine = M_DrawMainMenu,
    x = 97,
    y = 64,
    lastOn = newgame,
}

EpisodeMenu = {
    { status = 1, name = "M_EPI1", routine = M_Episode, alphaKey = string.byte("k") },
    { status = 1, name = "M_EPI2", routine = M_Episode, alphaKey = string.byte("t") },
    { status = 1, name = "M_EPI3", routine = M_Episode, alphaKey = string.byte("i") },
    { status = 1, name = "M_EPI4", routine = M_Episode, alphaKey = string.byte("t") },
}

EpiDef = {
    numitems = 4,
    prevMenu = MainDef,
    menuitems = EpisodeMenu,
    routine = M_DrawEpisode,
    x = 48,
    y = 63,
    lastOn = ep1,
}

NewGameMenu = {
    { status = 1, name = "M_JKILL", routine = M_ChooseSkill, alphaKey = string.byte("i") },
    { status = 1, name = "M_ROUGH", routine = M_ChooseSkill, alphaKey = string.byte("h") },
    { status = 1, name = "M_HURT", routine = M_ChooseSkill, alphaKey = string.byte("h") },
    { status = 1, name = "M_ULTRA", routine = M_ChooseSkill, alphaKey = string.byte("u") },
    { status = 1, name = "M_NMARE", routine = M_ChooseSkill, alphaKey = string.byte("n") },
}

NewDef = {
    numitems = 5,
    prevMenu = EpiDef,
    menuitems = NewGameMenu,
    routine = M_DrawNewGame,
    x = 48,
    y = 63,
    lastOn = hurtme,
}

OptionsMenu = {
    { status = 1, name = "M_ENDGAM", routine = M_EndGame, alphaKey = string.byte("e") },
    { status = 1, name = "M_MESSG", routine = M_ChangeMessages, alphaKey = string.byte("m") },
    { status = 1, name = "M_DETAIL", routine = M_ChangeDetail, alphaKey = string.byte("g") },
    { status = 2, name = "M_SCRNSZ", routine = M_SizeDisplay, alphaKey = string.byte("s") },
    { status = -1, name = "", routine = nil, alphaKey = 0 },
    { status = 2, name = "M_MSENS", routine = M_ChangeSensitivity, alphaKey = string.byte("m") },
    { status = -1, name = "", routine = nil, alphaKey = 0 },
    { status = 1, name = "M_SVOL", routine = M_Sound, alphaKey = string.byte("s") },
}

OptionsDef = {
    numitems = 8,
    prevMenu = MainDef,
    menuitems = OptionsMenu,
    routine = M_DrawOptions,
    x = 60,
    y = 37,
    lastOn = endgame,
}

ReadMenu1 = {
    { status = 1, name = "", routine = M_ReadThis2, alphaKey = 0 },
}

ReadDef1 = {
    numitems = read1_end,
    prevMenu = MainDef,
    menuitems = ReadMenu1,
    routine = M_DrawReadThis1,
    x = 280,
    y = 185,
    lastOn = rdthsempty1,
}

ReadMenu2 = {
    { status = 1, name = "", routine = M_FinishReadThis, alphaKey = 0 },
}

ReadDef2 = {
    numitems = read2_end,
    prevMenu = ReadDef1,
    menuitems = ReadMenu2,
    routine = M_DrawReadThis2,
    x = 330,
    y = 175,
    lastOn = rdthsempty2,
}

SoundMenu = {
    { status = 2, name = "M_SFXVOL", routine = M_SfxVol, alphaKey = string.byte("s") },
    { status = -1, name = "", routine = nil, alphaKey = 0 },
    { status = 2, name = "M_MUSVOL", routine = M_MusicVol, alphaKey = string.byte("m") },
    { status = -1, name = "", routine = nil, alphaKey = 0 },
}

SoundDef = {
    numitems = sound_end,
    prevMenu = OptionsDef,
    menuitems = SoundMenu,
    routine = M_DrawSound,
    x = 80,
    y = 64,
    lastOn = sfx_vol,
}

LoadMenu = {
    { status = 1, name = "", routine = M_LoadSelect, alphaKey = string.byte("1") },
    { status = 1, name = "", routine = M_LoadSelect, alphaKey = string.byte("2") },
    { status = 1, name = "", routine = M_LoadSelect, alphaKey = string.byte("3") },
    { status = 1, name = "", routine = M_LoadSelect, alphaKey = string.byte("4") },
    { status = 1, name = "", routine = M_LoadSelect, alphaKey = string.byte("5") },
    { status = 1, name = "", routine = M_LoadSelect, alphaKey = string.byte("6") },
}

LoadDef = {
    numitems = load_end,
    prevMenu = MainDef,
    menuitems = LoadMenu,
    routine = M_DrawLoad,
    x = 80,
    y = 54,
    lastOn = load1,
}

SaveMenu = {
    { status = 1, name = "", routine = M_SaveSelect, alphaKey = string.byte("1") },
    { status = 1, name = "", routine = M_SaveSelect, alphaKey = string.byte("2") },
    { status = 1, name = "", routine = M_SaveSelect, alphaKey = string.byte("3") },
    { status = 1, name = "", routine = M_SaveSelect, alphaKey = string.byte("4") },
    { status = 1, name = "", routine = M_SaveSelect, alphaKey = string.byte("5") },
    { status = 1, name = "", routine = M_SaveSelect, alphaKey = string.byte("6") },
}

SaveDef = {
    numitems = load_end,
    prevMenu = MainDef,
    menuitems = SaveMenu,
    routine = M_DrawSave,
    x = 80,
    y = 54,
    lastOn = load1,
}

-- Quit sounds (m_menu.c quitsounds / quitsounds2).
do
    quitsounds = {
        sounds.sfxenum.sfx_pldeth,
        sounds.sfxenum.sfx_dmpain,
        sounds.sfxenum.sfx_popain,
        sounds.sfxenum.sfx_slop,
        sounds.sfxenum.sfx_telept,
        sounds.sfxenum.sfx_posit1,
        sounds.sfxenum.sfx_posit3,
        sounds.sfxenum.sfx_sgtatk,
    }
    quitsounds2 = {
        sounds.sfxenum.sfx_vilact,
        sounds.sfxenum.sfx_getpow,
        sounds.sfxenum.sfx_boscub,
        sounds.sfxenum.sfx_slop,
        sounds.sfxenum.sfx_skeswg,
        sounds.sfxenum.sfx_kntdth,
        sounds.sfxenum.sfx_bspact,
        sounds.sfxenum.sfx_sgtatk,
    }
end

return m_menu
end)()

p_ceiling = (function()
local p_ceilng = {}

local FRACUNIT = m_fixed.FRACUNIT
local CEILSPEED = FRACUNIT
local MAXCEILINGS = 30

-- ceiling_e (p_spec.h).
p_ceilng.lowerToFloor = 0
p_ceilng.raiseToHighest = 1
p_ceilng.lowerAndCrush = 2
p_ceilng.crushAndRaise = 3
p_ceilng.fastCrushAndRaise = 4
p_ceilng.silentCrushAndRaise = 5

-- Active ceiling list (C: ceiling_t* activeceilings[MAXCEILINGS]).
p_ceilng.activeceilings = {}
for _ = 1, MAXCEILINGS do
    table.insert(p_ceilng.activeceilings, nil)
end

-- ---------------------------------------------------------------------------
-- T_MoveCeiling
-- ---------------------------------------------------------------------------

function p_ceilng.T_MoveCeiling(ceiling)
    local res

    if ceiling.direction == 0 then
        -- IN STASIS
        return
    elseif ceiling.direction == 1 then
        -- UP
        res = p_floor.T_MovePlane(ceiling.sector, ceiling.speed, ceiling.topheight,
            false, 1, ceiling.direction)

        if bit32.band(doomstat.leveltime, 7) == 0 then
            if ceiling.type ~= p_ceilng.silentCrushAndRaise then
                s_sound.S_StartSound(ceiling.sector.soundorg, sounds.sfxenum.sfx_stnmov)
            end
        end

        if res == p_floor.pastdest then
            if ceiling.type == p_ceilng.raiseToHighest then
                p_ceilng.P_RemoveActiveCeiling(ceiling)
            elseif ceiling.type == p_ceilng.silentCrushAndRaise then
                s_sound.S_StartSound(ceiling.sector.soundorg, sounds.sfxenum.sfx_pstop)
                ceiling.direction = -1
            elseif ceiling.type == p_ceilng.fastCrushAndRaise
                or ceiling.type == p_ceilng.crushAndRaise then
                ceiling.direction = -1
            end
        end
    elseif ceiling.direction == -1 then
        -- DOWN
        res = p_floor.T_MovePlane(ceiling.sector, ceiling.speed, ceiling.bottomheight,
            ceiling.crush, 1, ceiling.direction)

        if bit32.band(doomstat.leveltime, 7) == 0 then
            if ceiling.type ~= p_ceilng.silentCrushAndRaise then
                s_sound.S_StartSound(ceiling.sector.soundorg, sounds.sfxenum.sfx_stnmov)
            end
        end

        if res == p_floor.pastdest then
            if ceiling.type == p_ceilng.silentCrushAndRaise then
                s_sound.S_StartSound(ceiling.sector.soundorg, sounds.sfxenum.sfx_pstop)
                ceiling.direction = 1
            elseif ceiling.type == p_ceilng.crushAndRaise then
                ceiling.speed = CEILSPEED
                ceiling.direction = 1
            elseif ceiling.type == p_ceilng.fastCrushAndRaise then
                ceiling.direction = 1
            elseif ceiling.type == p_ceilng.lowerAndCrush
                or ceiling.type == p_ceilng.lowerToFloor then
                p_ceilng.P_RemoveActiveCeiling(ceiling)
            end
        elseif res == p_floor.crushed then
            if ceiling.type == p_ceilng.silentCrushAndRaise
                or ceiling.type == p_ceilng.crushAndRaise
                or ceiling.type == p_ceilng.lowerAndCrush then
                ceiling.speed = CEILSPEED // 8
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- EV_DoCeiling
-- Move a ceiling up/down and all around!
-- ---------------------------------------------------------------------------

function p_ceilng.EV_DoCeiling(line, type)
    local secnum
    local rtn
    local sec
    local ceiling

    secnum = -1
    rtn = 0

    -- Reactivate in-stasis ceilings...for certain types.
    if type == p_ceilng.fastCrushAndRaise
        or type == p_ceilng.silentCrushAndRaise
        or type == p_ceilng.crushAndRaise then
        p_ceilng.P_ActivateInStasisCeiling(line)
    end

    while true do
        secnum = p_spec.P_FindSectorFromLineTag(line, secnum)
        if secnum < 0 then
            break
        end

        sec = r_state.sectors[secnum + 1]
        if sec.specialdata then
            -- continue
        else
            -- new door thinker
            rtn = 1
            ceiling = {}
            p_tick.P_AddThinker(ceiling)
            sec.specialdata = ceiling
            ceiling.thinkfunc = p_ceilng.T_MoveCeiling
            ceiling.sector = sec
            ceiling.crush = false

            if type == p_ceilng.fastCrushAndRaise then
                ceiling.crush = true
                ceiling.topheight = sec.ceilingheight
                ceiling.bottomheight = sec.floorheight + (8 * FRACUNIT)
                ceiling.direction = -1
                ceiling.speed = CEILSPEED * 2
            elseif type == p_ceilng.silentCrushAndRaise
                or type == p_ceilng.crushAndRaise then
                ceiling.crush = true
                ceiling.topheight = sec.ceilingheight
                ceiling.bottomheight = sec.floorheight
                if type ~= p_ceilng.lowerToFloor then
                    ceiling.bottomheight = ceiling.bottomheight + 8 * FRACUNIT
                end
                ceiling.direction = -1
                ceiling.speed = CEILSPEED
            elseif type == p_ceilng.lowerAndCrush
                or type == p_ceilng.lowerToFloor then
                ceiling.bottomheight = sec.floorheight
                if type ~= p_ceilng.lowerToFloor then
                    ceiling.bottomheight = ceiling.bottomheight + 8 * FRACUNIT
                end
                ceiling.direction = -1
                ceiling.speed = CEILSPEED
            elseif type == p_ceilng.raiseToHighest then
                ceiling.topheight = p_spec.P_FindHighestCeilingSurrounding(sec)
                ceiling.direction = 1
                ceiling.speed = CEILSPEED
            end

            ceiling.tag = sec.tag
            ceiling.type = type
            p_ceilng.P_AddActiveCeiling(ceiling)
        end
    end
    return rtn
end

-- ---------------------------------------------------------------------------
-- P_AddActiveCeiling
-- ---------------------------------------------------------------------------

function p_ceilng.P_AddActiveCeiling(c)
    for i = 1, MAXCEILINGS do
        if p_ceilng.activeceilings[i] == nil then
            p_ceilng.activeceilings[i] = c
            return
        end
    end
end

-- ---------------------------------------------------------------------------
-- P_RemoveActiveCeiling
-- Remove a ceiling's thinker.
-- ---------------------------------------------------------------------------

function p_ceilng.P_RemoveActiveCeiling(c)
    for i = 1, MAXCEILINGS do
        if p_ceilng.activeceilings[i] == c then
            p_ceilng.activeceilings[i].sector.specialdata = nil
            p_tick.P_RemoveThinker(p_ceilng.activeceilings[i])
            p_ceilng.activeceilings[i] = nil
            break
        end
    end
end

-- ---------------------------------------------------------------------------
-- P_ActivateInStasisCeiling
-- Restart a ceiling that's in-stasis.
-- ---------------------------------------------------------------------------

function p_ceilng.P_ActivateInStasisCeiling(line)
    for i = 1, MAXCEILINGS do
        local c = p_ceilng.activeceilings[i]
        if c and c.tag == line.tag and c.direction == 0 then
            c.direction = c.olddirection
            c.thinkfunc = p_ceilng.T_MoveCeiling
        end
    end
end

-- ---------------------------------------------------------------------------
-- EV_CeilingCrushStop
-- Stop a ceiling from crushing!
-- ---------------------------------------------------------------------------

function p_ceilng.EV_CeilingCrushStop(line)
    local rtn = 0
    for i = 1, MAXCEILINGS do
        local c = p_ceilng.activeceilings[i]
        if c and c.tag == line.tag and c.direction ~= 0 then
            c.olddirection = c.direction
            c.thinkfunc = nil -- NULL action (in-stasis)
            c.direction = 0 -- in-stasis
            rtn = 1
        end
    end
    return rtn
end

return p_ceilng
end)()

p_doors = (function()
local p_doors = {}

local FRACUNIT = m_fixed.FRACUNIT
local VDOORSPEED = FRACUNIT * 2
local VDOORWAIT = 150
local TICRATE = doomtype.TICRATE

-- vldoor_e (p_spec.h).
p_doors.vld_normal = 0
p_doors.vld_close30ThenOpen = 1
p_doors.vld_close = 2
p_doors.vld_open = 3
p_doors.vld_raiseIn5Mins = 4
p_doors.vld_blazeRaise = 5
p_doors.vld_blazeOpen = 6
p_doors.vld_blazeClose = 7

-- Locked-door messages (d_englsh.h).
local PD_BLUEK = "You need a blue key to open this door"
local PD_YELLOWK = "You need a yellow key to open this door"
local PD_REDK = "You need a red key to open this door"

-- ---------------------------------------------------------------------------
-- T_VerticalDoor
-- ---------------------------------------------------------------------------

function p_doors.T_VerticalDoor(door)
    local res

    if door.direction == 0 then
        -- WAITING
        door.topcountdown = door.topcountdown - 1
        if door.topcountdown == 0 then
            if door.type == p_doors.vld_blazeRaise then
                door.direction = -1 -- time to go back down
                s_sound.S_StartSound(door.sector.soundorg, sounds.sfxenum.sfx_bdcls)
            elseif door.type == p_doors.vld_normal then
                door.direction = -1 -- time to go back down
                s_sound.S_StartSound(door.sector.soundorg, sounds.sfxenum.sfx_dorcls)
            elseif door.type == p_doors.vld_close30ThenOpen then
                door.direction = 1
                s_sound.S_StartSound(door.sector.soundorg, sounds.sfxenum.sfx_doropn)
            end
        end
    elseif door.direction == 2 then
        -- INITIAL WAIT
        door.topcountdown = door.topcountdown - 1
        if door.topcountdown == 0 then
            if door.type == p_doors.vld_raiseIn5Mins then
                door.direction = 1
                door.type = p_doors.vld_normal
                s_sound.S_StartSound(door.sector.soundorg, sounds.sfxenum.sfx_doropn)
            end
        end
    elseif door.direction == -1 then
        -- DOWN
        res = p_floor.T_MovePlane(door.sector, door.speed,
            door.sector.floorheight, false, 1, door.direction)
        if res == p_floor.pastdest then
            if door.type == p_doors.vld_blazeRaise
                or door.type == p_doors.vld_blazeClose then
                door.sector.specialdata = nil
                p_tick.P_RemoveThinker(door) -- unlink and free
                s_sound.S_StartSound(door.sector.soundorg, sounds.sfxenum.sfx_bdcls)
            elseif door.type == p_doors.vld_normal
                or door.type == p_doors.vld_close then
                door.sector.specialdata = nil
                p_tick.P_RemoveThinker(door) -- unlink and free
            elseif door.type == p_doors.vld_close30ThenOpen then
                door.direction = 0
                door.topcountdown = TICRATE * 30
            end
        elseif res == p_floor.crushed then
            if door.type == p_doors.vld_blazeClose
                or door.type == p_doors.vld_close then
                -- DO NOT GO BACK UP!
            else
                door.direction = 1
                s_sound.S_StartSound(door.sector.soundorg, sounds.sfxenum.sfx_doropn)
            end
        end
    elseif door.direction == 1 then
        -- UP
        res = p_floor.T_MovePlane(door.sector, door.speed, door.topheight,
            false, 1, door.direction)

        if res == p_floor.pastdest then
            if door.type == p_doors.vld_blazeRaise
                or door.type == p_doors.vld_normal then
                door.direction = 0 -- wait at top
                door.topcountdown = door.topwait
            elseif door.type == p_doors.vld_close30ThenOpen
                or door.type == p_doors.vld_blazeOpen
                or door.type == p_doors.vld_open then
                door.sector.specialdata = nil
                p_tick.P_RemoveThinker(door) -- unlink and free
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- EV_DoLockedDoor
-- Move a locked door up/down.
-- ---------------------------------------------------------------------------

function p_doors.EV_DoLockedDoor(line, type, thing)
    local p

    p = thing.player

    if not p then
        return 0
    end

    if line.special == 99 or line.special == 133 then -- Blue Lock
        if not p.cards[doomdef.it_bluecard + 1]
            and not p.cards[doomdef.it_blueskull + 1] then
            p.message = deh_str.DEH_String(PD_BLUEK)
            s_sound.S_StartSound(nil, sounds.sfxenum.sfx_oof)
            return 0
        end
    elseif line.special == 134 or line.special == 135 then -- Red Lock
        if not p.cards[doomdef.it_redcard + 1]
            and not p.cards[doomdef.it_redskull + 1] then
            p.message = deh_str.DEH_String(PD_REDK)
            s_sound.S_StartSound(nil, sounds.sfxenum.sfx_oof)
            return 0
        end
    elseif line.special == 136 or line.special == 137 then -- Yellow Lock
        if not p.cards[doomdef.it_yellowcard + 1]
            and not p.cards[doomdef.it_yellowskull + 1] then
            p.message = deh_str.DEH_String(PD_YELLOWK)
            s_sound.S_StartSound(nil, sounds.sfxenum.sfx_oof)
            return 0
        end
    end

    return p_doors.EV_DoDoor(line, type)
end

-- ---------------------------------------------------------------------------
-- EV_DoDoor
-- ---------------------------------------------------------------------------

function p_doors.EV_DoDoor(line, type)
    local secnum
    local rtn
    local sec
    local door

    secnum = -1
    rtn = 0

    while true do
        secnum = p_spec.P_FindSectorFromLineTag(line, secnum)
        if secnum < 0 then
            break
        end

        sec = r_state.sectors[secnum + 1]
        if sec.specialdata then
            -- continue
        else
            -- new door thinker
            rtn = 1
            door = {}
            p_tick.P_AddThinker(door)
            sec.specialdata = door

            door.thinkfunc = p_doors.T_VerticalDoor
            door.sector = sec
            door.type = type
            door.topwait = VDOORWAIT
            door.speed = VDOORSPEED

            if type == p_doors.vld_blazeClose then
                door.topheight = p_spec.P_FindLowestCeilingSurrounding(sec)
                door.topheight = door.topheight - 4 * FRACUNIT
                door.direction = -1
                door.speed = VDOORSPEED * 4
                s_sound.S_StartSound(door.sector.soundorg, sounds.sfxenum.sfx_bdcls)
            elseif type == p_doors.vld_close then
                door.topheight = p_spec.P_FindLowestCeilingSurrounding(sec)
                door.topheight = door.topheight - 4 * FRACUNIT
                door.direction = -1
                s_sound.S_StartSound(door.sector.soundorg, sounds.sfxenum.sfx_dorcls)
            elseif type == p_doors.vld_close30ThenOpen then
                door.topheight = sec.ceilingheight
                door.direction = -1
                s_sound.S_StartSound(door.sector.soundorg, sounds.sfxenum.sfx_dorcls)
            elseif type == p_doors.vld_blazeRaise
                or type == p_doors.vld_blazeOpen then
                door.direction = 1
                door.topheight = p_spec.P_FindLowestCeilingSurrounding(sec)
                door.topheight = door.topheight - 4 * FRACUNIT
                door.speed = VDOORSPEED * 4
                if door.topheight ~= sec.ceilingheight then
                    s_sound.S_StartSound(door.sector.soundorg, sounds.sfxenum.sfx_bdopn)
                end
            elseif type == p_doors.vld_normal
                or type == p_doors.vld_open then
                door.direction = 1
                door.topheight = p_spec.P_FindLowestCeilingSurrounding(sec)
                door.topheight = door.topheight - 4 * FRACUNIT
                if door.topheight ~= sec.ceilingheight then
                    s_sound.S_StartSound(door.sector.soundorg, sounds.sfxenum.sfx_doropn)
                end
            end
        end
    end
    return rtn
end

-- ---------------------------------------------------------------------------
-- EV_VerticalDoor
-- Open a door manually, no tag value.
-- ---------------------------------------------------------------------------

function p_doors.EV_VerticalDoor(line, thing)
    local player
    local sec
    local door
    local side

    side = 0 -- only front sides can be used

    -- Check for locks
    player = thing.player

    if line.special == 26 or line.special == 32 then -- Blue Lock
        if not player then
            return
        end
        if not player.cards[doomdef.it_bluecard + 1]
            and not player.cards[doomdef.it_blueskull + 1] then
            player.message = deh_str.DEH_String(PD_BLUEK)
            s_sound.S_StartSound(nil, sounds.sfxenum.sfx_oof)
            return
        end
    elseif line.special == 27 or line.special == 34 then -- Yellow Lock
        if not player then
            return
        end
        if not player.cards[doomdef.it_yellowcard + 1]
            and not player.cards[doomdef.it_yellowskull + 1] then
            player.message = deh_str.DEH_String(PD_YELLOWK)
            s_sound.S_StartSound(nil, sounds.sfxenum.sfx_oof)
            return
        end
    elseif line.special == 28 or line.special == 33 then -- Red Lock
        if not player then
            return
        end
        if not player.cards[doomdef.it_redcard + 1]
            and not player.cards[doomdef.it_redskull + 1] then
            player.message = deh_str.DEH_String(PD_REDK)
            s_sound.S_StartSound(nil, sounds.sfxenum.sfx_oof)
            return
        end
    end

    -- if the sector has an active thinker, use it
    sec = r_state.sides[line.sidenum[bit32.bxor(side, 1) + 1] + 1].sector

    if sec.specialdata then
        door = sec.specialdata
        if line.special == 1 -- ONLY FOR "RAISE" DOORS, NOT "OPEN"s
            or line.special == 26
            or line.special == 27
            or line.special == 28
            or line.special == 117 then
            -- The C aliases vldoor_t and plat_t (the specialdata may point
            -- at either). The "direction" field of vldoor_t corresponds to
            -- the "wait" field of plat_t, so emulate the union.
            local dir
            if door.thinkfunc == p_plats.T_PlatRaise then
                dir = door.wait
            else
                dir = door.direction
            end

            if dir == -1 then
                -- go back up
                if door.thinkfunc == p_plats.T_PlatRaise then
                    door.wait = 1
                else
                    door.direction = 1
                end
            else
                if not thing.player then
                    return -- JDC: bad guys never close doors
                end

                -- When is a door not a door?
                if door.thinkfunc == p_doors.T_VerticalDoor then
                    door.direction = -1 -- start going down immediately
                elseif door.thinkfunc == p_plats.T_PlatRaise then
                    -- This is a plat, not a door. (ep1-0500.lmp bug)
                    door.wait = -1
                else
                    -- This isn't a door OR a plat.
                    print("EV_VerticalDoor: Tried to close something that wasn't a door.")
                    door.direction = -1
                end
            end
            return
        end
    end

    -- for proper sound
    if line.special == 117 or line.special == 118 then -- BLAZING DOOR RAISE/OPEN
        s_sound.S_StartSound(sec.soundorg, sounds.sfxenum.sfx_bdopn)
    else
        -- NORMAL DOOR SOUND / LOCKED DOOR SOUND
        s_sound.S_StartSound(sec.soundorg, sounds.sfxenum.sfx_doropn)
    end

    -- new door thinker
    door = {}
    p_tick.P_AddThinker(door)
    sec.specialdata = door
    door.thinkfunc = p_doors.T_VerticalDoor
    door.sector = sec
    door.direction = 1
    door.speed = VDOORSPEED
    door.topwait = VDOORWAIT

    if line.special == 1 or line.special == 26
        or line.special == 27 or line.special == 28 then
        door.type = p_doors.vld_normal
    elseif line.special == 31 or line.special == 32
        or line.special == 33 or line.special == 34 then
        door.type = p_doors.vld_open
        line.special = 0
    elseif line.special == 117 then -- blazing door raise
        door.type = p_doors.vld_blazeRaise
        door.speed = VDOORSPEED * 4
    elseif line.special == 118 then -- blazing door open
        door.type = p_doors.vld_blazeOpen
        line.special = 0
        door.speed = VDOORSPEED * 4
    end

    -- find the top and bottom of the movement range
    door.topheight = p_spec.P_FindLowestCeilingSurrounding(sec)
    door.topheight = door.topheight - 4 * FRACUNIT
end

-- ---------------------------------------------------------------------------
-- P_SpawnDoorCloseIn30
-- Spawn a door that closes after 30 seconds.
-- ---------------------------------------------------------------------------

function p_doors.P_SpawnDoorCloseIn30(sec)
    local door

    door = {}
    p_tick.P_AddThinker(door)

    sec.specialdata = door
    sec.special = 0

    door.thinkfunc = p_doors.T_VerticalDoor
    door.sector = sec
    door.direction = 0
    door.type = p_doors.vld_normal
    door.speed = VDOORSPEED
    door.topcountdown = 30 * TICRATE
end

-- ---------------------------------------------------------------------------
-- P_SpawnDoorRaiseIn5Mins
-- Spawn a door that opens after 5 minutes.
-- ---------------------------------------------------------------------------

function p_doors.P_SpawnDoorRaiseIn5Mins(sec, secnum)
    local door

    door = {}
    p_tick.P_AddThinker(door)

    sec.specialdata = door
    sec.special = 0

    door.thinkfunc = p_doors.T_VerticalDoor
    door.sector = sec
    door.direction = 2
    door.type = p_doors.vld_raiseIn5Mins
    door.speed = VDOORSPEED
    door.topheight = p_spec.P_FindLowestCeilingSurrounding(sec)
    door.topheight = door.topheight - 4 * FRACUNIT
    door.topwait = VDOORWAIT
    door.topcountdown = 5 * 60 * TICRATE
end

return p_doors
end)()

p_mobj = (function()
local p_mobj = {}

-- ---------------------------------------------------------------------------
-- Mobj flags (p_mobj.h mobjflag_t).
-- ---------------------------------------------------------------------------

p_mobj.MF_SPECIAL = 1
p_mobj.MF_SOLID = 2
p_mobj.MF_SHOOTABLE = 4
p_mobj.MF_NOSECTOR = 8
p_mobj.MF_NOBLOCKMAP = 16
p_mobj.MF_AMBUSH = 32
p_mobj.MF_JUSTHIT = 64
p_mobj.MF_JUSTATTACKED = 128
p_mobj.MF_SPAWNCEILING = 256
p_mobj.MF_NOGRAVITY = 512
p_mobj.MF_DROPOFF = 0x400
p_mobj.MF_PICKUP = 0x800
p_mobj.MF_NOCLIP = 0x1000
p_mobj.MF_SLIDE = 0x2000
p_mobj.MF_FLOAT = 0x4000
p_mobj.MF_TELEPORT = 0x8000
p_mobj.MF_MISSILE = 0x10000
p_mobj.MF_DROPPED = 0x20000
p_mobj.MF_SHADOW = 0x40000
p_mobj.MF_NOBLOOD = 0x80000
p_mobj.MF_CORPSE = 0x100000
p_mobj.MF_INFLOAT = 0x200000
p_mobj.MF_COUNTKILL = 0x400000
p_mobj.MF_COUNTITEM = 0x800000
p_mobj.MF_SKULLFLY = 0x1000000
p_mobj.MF_NOTDMATCH = 0x2000000
p_mobj.MF_TRANSLATION = 0xc000000
p_mobj.MF_TRANSSHIFT = 26

-- Movement constants (p_local.h).
local FRACUNIT = m_fixed.FRACUNIT
local FLOATSPEED = FRACUNIT * 4
local VIEWHEIGHT = 41 * FRACUNIT
local MAXRADIUS = 32 * FRACUNIT
local GRAVITY = FRACUNIT
local MAXMOVE = 30 * FRACUNIT
local MELEERANGE = 64 * FRACUNIT
local BASETHRESHOLD = 100

local ONFLOORZ = -2147483648 -- INT_MIN
local ONCEILINGZ = 2147483647 -- INT_MAX

-- P_XYMovement constants.
local STOPSPEED = 0x1000
local FRICTION = 0xe800

-- ---------------------------------------------------------------------------
-- Mobj action registry (acp1). Phase 4c registers the monster AI actions
-- here; 4b registers the actions the simulation core needs.
-- ---------------------------------------------------------------------------

local mobj_actions = {}
local warned_actions = {}

-- Reverse map: state table -> statenum index (the C state_t* -> index).
local state_to_index = {}
for i, st in ipairs(info.states) do
    state_to_index[st] = i - 1
end

-- Return the statenum index of a state table (or nil).
function p_mobj.stateIndex(st)
    if st == nil then
        return nil
    end
    return state_to_index[st]
end

-- Register a mobj action by state-action name (later phases extend this).
function p_mobj.registerMobjAction(name, fn)
    mobj_actions[name] = fn
end

-- Resolve a state's action name to its acp1 function (or nil).
function p_mobj.getMobjAction(name)
    if name == nil then
        return nil
    end
    local fn = mobj_actions[name]
    if fn == nil and not warned_actions[name] then
        warned_actions[name] = true
        print(string.format("p_mobj: action %s not yet ported (Phase 4c); no-op", name))
    end
    return fn
end

-- A_Explode: spawn a radius attack at the missile's position.
p_mobj.registerMobjAction("A_Explode", function(thingy)
    p_map.P_RadiusAttack(thingy, thingy.target, 128)
end)

-- A_Fall: the actor is on ground, it can be walked over.
p_mobj.registerMobjAction("A_Fall", function(actor)
    actor.flags = bit32.band(actor.flags, bit32.bnot(p_mobj.MF_SOLID))
end)

-- Sound-only pain/death screams: sound is cut in v1, so no-ops.
for _, name in ipairs({ "A_Pain", "A_Scream", "A_XScream", "A_PlayerScream" }) do
    p_mobj.registerMobjAction(name, function()
    end)
end

-- ---------------------------------------------------------------------------
-- P_SetMobjState
-- Returns true if the mobj is still present.
-- ---------------------------------------------------------------------------

function p_mobj.P_SetMobjState(mobj, state)
    local st

    while true do
        if state == 0 then -- S_NULL
            mobj.state = nil
            p_mobj.P_RemoveMobj(mobj)
            return false
        end

        st = info.states[state + 1]
        mobj.state = st
        mobj.tics = st.tics
        mobj.sprite = st.sprite
        mobj.frame = st.frame

        -- Modified handling.
        -- Call action functions when the state is set.
        local fn = p_mobj.getMobjAction(st.action)
        if fn then
            fn(mobj)
        end

        state = st.nextstate

        if mobj.tics ~= 0 then
            break
        end
    end

    return true
end

-- ---------------------------------------------------------------------------
-- P_ExplodeMissile
-- ---------------------------------------------------------------------------

function p_mobj.P_ExplodeMissile(mo)
    mo.momx = 0
    mo.momy = 0
    mo.momz = 0

    p_mobj.P_SetMobjState(mo, info.mobjinfo[mo.type + 1].deathstate)

    mo.tics = mo.tics - (m_random.P_Random() % 4) -- P_Random()&3

    if mo.tics < 1 then
        mo.tics = 1
    end

    mo.flags = bit32.band(mo.flags, bit32.bnot(p_mobj.MF_MISSILE))

    if info.mobjinfo[mo.type + 1].deathsound ~= 0 then
        s_sound.S_StartSound(mo, info.mobjinfo[mo.type + 1].deathsound)
    end
end

-- ---------------------------------------------------------------------------
-- P_XYMovement
-- ---------------------------------------------------------------------------

function p_mobj.P_XYMovement(mo)
    local ptryx
    local ptryy
    local player
    local xmove
    local ymove

    if mo.momx == 0 and mo.momy == 0 then
        if bit32.band(mo.flags, p_mobj.MF_SKULLFLY) ~= 0 then
            -- the skull slammed into something
            mo.flags = bit32.band(mo.flags, bit32.bnot(p_mobj.MF_SKULLFLY))
            mo.momx = 0
            mo.momy = 0
            mo.momz = 0

            p_mobj.P_SetMobjState(mo, info.mobjinfo[mo.type + 1].spawnstate)
        end
        return
    end

    player = mo.player

    if mo.momx > MAXMOVE then
        mo.momx = MAXMOVE
    elseif mo.momx < -MAXMOVE then
        mo.momx = -MAXMOVE
    end

    if mo.momy > MAXMOVE then
        mo.momy = MAXMOVE
    elseif mo.momy < -MAXMOVE then
        mo.momy = -MAXMOVE
    end

    xmove = mo.momx
    ymove = mo.momy

    while true do
        if xmove > MAXMOVE // 2 or ymove > MAXMOVE // 2 then
            ptryx = mo.x + xmove // 2
            ptryy = mo.y + ymove // 2
            xmove = xmove // 2
            ymove = ymove // 2
        else
            ptryx = mo.x + xmove
            ptryy = mo.y + ymove
            xmove = 0
            ymove = 0
        end

        if not p_map.P_TryMove(mo, ptryx, ptryy) then
            -- blocked move
            if mo.player then
                -- try to slide along it
                p_map.P_SlideMove(mo)
            elseif bit32.band(mo.flags, p_mobj.MF_MISSILE) ~= 0 then
                -- explode a missile
                if p_map.ceilingline
                    and p_map.ceilingline.backsector
                    and p_map.ceilingline.backsector.ceilingpic == r_state.skyflatnum then
                    -- Hack to prevent missiles exploding against the sky.
                    -- Does not handle sky floors.
                    p_mobj.P_RemoveMobj(mo)
                    return
                end
                p_mobj.P_ExplodeMissile(mo)
            else
                mo.momx = 0
                mo.momy = 0
            end
        end

        if xmove == 0 and ymove == 0 then
            break
        end
    end

    -- slow down
    if player and bit32.band(player.cheats, 4) ~= 0 then -- CF_NOMOMENTUM
        -- debug option for no sliding at all
        mo.momx = 0
        mo.momy = 0
        return
    end

    if bit32.band(mo.flags, p_mobj.MF_MISSILE + p_mobj.MF_SKULLFLY) ~= 0 then
        return -- no friction for missiles ever
    end

    if mo.z > mo.floorz then
        return -- no friction when airborne
    end

    if bit32.band(mo.flags, p_mobj.MF_CORPSE) ~= 0 then
        -- do not stop sliding
        --  if halfway off a step with some momentum
        if mo.momx > FRACUNIT // 4
            or mo.momx < -(FRACUNIT // 4)
            or mo.momy > FRACUNIT // 4
            or mo.momy < -(FRACUNIT // 4) then
            if mo.subsector and mo.floorz ~= mo.subsector.sector.floorheight then
                return
            end
        end
    end

    if mo.momx > -STOPSPEED
        and mo.momx < STOPSPEED
        and mo.momy > -STOPSPEED
        and mo.momy < STOPSPEED
        and (not player
            or (player.cmd.forwardmove == 0
                and player.cmd.sidemove == 0)) then
        -- if in a walking frame, stop moving
        if player
            and p_mobj.stateIndex(player.mo.state) ~= nil
            and (p_mobj.stateIndex(player.mo.state) - info.statenum.S_PLAY_RUN1) < 4 then
            p_mobj.P_SetMobjState(player.mo, info.statenum.S_PLAY)
        end

        mo.momx = 0
        mo.momy = 0
    else
        mo.momx = m_fixed.FixedMul(mo.momx, FRICTION)
        mo.momy = m_fixed.FixedMul(mo.momy, FRICTION)
    end
end

-- ---------------------------------------------------------------------------
-- P_ZMovement
-- ---------------------------------------------------------------------------

function p_mobj.P_ZMovement(mo)
    local dist
    local delta

    -- check for smooth step up
    if mo.player and mo.z < mo.floorz then
        mo.player.viewheight = mo.player.viewheight - (mo.floorz - mo.z)

        mo.player.deltaviewheight = (VIEWHEIGHT - mo.player.viewheight) // 8 -- >>3
    end

    -- adjust height
    mo.z = mo.z + mo.momz

    if bit32.band(mo.flags, p_mobj.MF_FLOAT) ~= 0
        and mo.target then
        -- float down towards target if too close
        if bit32.band(mo.flags, p_mobj.MF_SKULLFLY) == 0
            and bit32.band(mo.flags, p_mobj.MF_INFLOAT) == 0 then
            dist = p_maputl.P_AproxDistance(mo.x - mo.target.x,
                mo.y - mo.target.y)

            delta = (mo.target.z + (mo.height // 2)) - mo.z

            if delta < 0 and dist < -(delta * 3) then
                mo.z = mo.z - FLOATSPEED
            elseif delta > 0 and dist < (delta * 3) then
                mo.z = mo.z + FLOATSPEED
            end
        end
    end

    -- clip movement
    if mo.z <= mo.floorz then
        -- hit the floor

        local correct_lost_soul_bounce = doomstat.gameversion >= 6 -- exe_ultimate

        if correct_lost_soul_bounce and bit32.band(mo.flags, p_mobj.MF_SKULLFLY) ~= 0 then
            -- the skull slammed into something
            mo.momz = -mo.momz
        end

        if mo.momz < 0 then
            if mo.player
                and mo.momz < -(GRAVITY * 8) then
                -- Squat down.
                -- Decrease viewheight for a moment
                -- after hitting the ground (hard),
                -- and utter appropriate sound.
                mo.player.deltaviewheight = mo.momz // 8 -- >>3
                s_sound.S_StartSound(mo, sounds.sfxenum.sfx_oof)
            end
            mo.momz = 0
        end
        mo.z = mo.floorz

        if not correct_lost_soul_bounce and bit32.band(mo.flags, p_mobj.MF_SKULLFLY) ~= 0 then
            mo.momz = -mo.momz
        end

        if bit32.band(mo.flags, p_mobj.MF_MISSILE) ~= 0
            and bit32.band(mo.flags, p_mobj.MF_NOCLIP) == 0 then
            p_mobj.P_ExplodeMissile(mo)
            return
        end
    elseif bit32.band(mo.flags, p_mobj.MF_NOGRAVITY) == 0 then
        if mo.momz == 0 then
            mo.momz = -(GRAVITY * 2)
        else
            mo.momz = mo.momz - GRAVITY
        end
    end

    if mo.z + mo.height > mo.ceilingz then
        -- hit the ceiling
        if mo.momz > 0 then
            mo.momz = 0
        end
        mo.z = mo.ceilingz - mo.height

        if bit32.band(mo.flags, p_mobj.MF_SKULLFLY) ~= 0 then
            -- the skull slammed into something
            mo.momz = -mo.momz
        end

        if bit32.band(mo.flags, p_mobj.MF_MISSILE) ~= 0
            and bit32.band(mo.flags, p_mobj.MF_NOCLIP) == 0 then
            p_mobj.P_ExplodeMissile(mo)
            return
        end
    end
end

-- ---------------------------------------------------------------------------
-- P_NightmareRespawn
-- ---------------------------------------------------------------------------

function p_mobj.P_NightmareRespawn(mobj)
    local x
    local y
    local z
    local ss
    local mo
    local mthing

    x = mobj.spawnpoint.x * FRACUNIT -- << FRACBITS
    y = mobj.spawnpoint.y * FRACUNIT

    -- something is occupying its position?
    if not p_map.P_CheckPosition(mobj, x, y) then
        return -- no respawn
    end

    -- spawn a teleport fog at old spot
    -- because of removal of the body?
    mo = p_mobj.P_SpawnMobj(mobj.x, mobj.y,
        mobj.subsector.sector.floorheight, info.mobjtype.MT_TFOG)
    -- initiate teleport sound
    s_sound.S_StartSound(mo, sounds.sfxenum.sfx_telept)

    -- spawn a teleport fog at the new spot
    ss = r_main.R_PointInSubsector(x, y)

    mo = p_mobj.P_SpawnMobj(x, y, ss.sector.floorheight, info.mobjtype.MT_TFOG)

    s_sound.S_StartSound(mo, sounds.sfxenum.sfx_telept)

    -- spawn the new monster
    mthing = mobj.spawnpoint

    -- spawn it
    if bit32.band(info.mobjinfo[mobj.type + 1].flags, p_mobj.MF_SPAWNCEILING) ~= 0 then
        z = ONCEILINGZ
    else
        z = ONFLOORZ
    end

    -- inherit attributes from deceased one
    mo = p_mobj.P_SpawnMobj(x, y, z, mobj.type)
    mo.spawnpoint = mobj.spawnpoint
    mo.angle = (doomtype.ANG45 * (mthing.angle // 45)) % 0x100000000

    if bit32.band(mthing.options, 8) ~= 0 then -- MTF_AMBUSH
        mo.flags = bit32.bor(mo.flags, p_mobj.MF_AMBUSH)
    end

    mo.reactiontime = 18

    -- remove the old monster
    p_mobj.P_RemoveMobj(mobj)
end

-- ---------------------------------------------------------------------------
-- P_MobjThinker
-- ---------------------------------------------------------------------------

function p_mobj.P_MobjThinker(mobj)
    -- momentum movement
    if mobj.momx ~= 0
        or mobj.momy ~= 0
        or bit32.band(mobj.flags, p_mobj.MF_SKULLFLY) ~= 0 then
        p_mobj.P_XYMovement(mobj)

        if mobj.thinkfunc == -1 then
            return -- mobj was removed
        end
    end
    if mobj.z ~= mobj.floorz or mobj.momz ~= 0 then
        p_mobj.P_ZMovement(mobj)

        if mobj.thinkfunc == -1 then
            return -- mobj was removed
        end
    end

    -- cycle through states,
    -- calling action functions at transitions
    if mobj.tics ~= -1 then
        mobj.tics = mobj.tics - 1

        -- you can cycle through multiple states in a tic
        if mobj.tics == 0 then
            if not p_mobj.P_SetMobjState(mobj, mobj.state.nextstate) then
                return -- freed itself
            end
        end
    else
        -- check for nightmare respawn
        if bit32.band(mobj.flags, p_mobj.MF_COUNTKILL) == 0 then
            return
        end

        if not doomstat.respawnmonsters then
            return
        end

        mobj.movecount = mobj.movecount + 1

        if mobj.movecount < 12 * doomtype.TICRATE then
            return
        end

        if bit32.band(doomstat.leveltime, 31) ~= 0 then
            return
        end

        if m_random.P_Random() > 4 then
            return
        end

        p_mobj.P_NightmareRespawn(mobj)
    end
end

-- ---------------------------------------------------------------------------
-- P_SpawnMobj
-- ---------------------------------------------------------------------------

function p_mobj.P_SpawnMobj(x, y, z, type)
    local mobj
    local st
    local mobjinfo_

    mobj = {}
    mobjinfo_ = info.mobjinfo[type + 1]

    -- The C zero-initializes the whole mobj_t (memset); initialize every
    -- field to its default so later reads never hit nil.
    mobj.angle = 0
    mobj.sprite = 0
    mobj.frame = 0
    mobj.snext = nil
    mobj.sprev = nil
    mobj.bnext = nil
    mobj.bprev = nil
    mobj.subsector = nil
    mobj.floorz = 0
    mobj.ceilingz = 0
    mobj.momx = 0
    mobj.momy = 0
    mobj.momz = 0
    mobj.validcount = 0
    mobj.movedir = 0
    mobj.movecount = 0
    mobj.target = nil
    mobj.tracer = nil
    mobj.threshold = 0
    mobj.player = nil
    mobj.player_index = nil
    mobj.spawnpoint = nil
    mobj.lastlook = 0

    mobj.type = type
    mobj.info = mobjinfo_
    mobj.x = x
    mobj.y = y
    mobj.radius = mobjinfo_.radius
    mobj.height = mobjinfo_.height
    mobj.flags = mobjinfo_.flags
    mobj.health = mobjinfo_.spawnhealth

    if doomstat.gameskill ~= 4 then -- sk_nightmare
        mobj.reactiontime = mobjinfo_.reactiontime
    else
        mobj.reactiontime = 0
    end

    mobj.lastlook = m_random.P_Random() % doomtype.MAXPLAYERS
    -- do not set the state with P_SetMobjState,
    -- because action routines can not be called yet
    st = info.states[mobjinfo_.spawnstate + 1]

    mobj.state = st
    mobj.tics = st.tics
    mobj.sprite = st.sprite
    mobj.frame = st.frame

    -- set subsector and/or block links
    p_maputl.P_SetThingPosition(mobj)

    mobj.floorz = mobj.subsector.sector.floorheight
    mobj.ceilingz = mobj.subsector.sector.ceilingheight

    if z == ONFLOORZ then
        mobj.z = mobj.floorz
    elseif z == ONCEILINGZ then
        mobj.z = mobj.ceilingz - mobj.info.height
    else
        mobj.z = z
    end

    mobj.prev = nil
    mobj.next = nil
    mobj.thinkfunc = p_mobj.P_MobjThinker

    p_tick.P_AddThinker(mobj)

    return mobj
end

-- ---------------------------------------------------------------------------
-- P_RemoveMobj
-- ---------------------------------------------------------------------------

local ITEMQUESIZE = 128
local itemrespawnque = {}
local itemrespawntime = {}

p_mobj.itemrespawnque = itemrespawnque
p_mobj.itemrespawntime = itemrespawntime
p_mobj.iquehead = 0
p_mobj.iquetail = 0

function p_mobj.P_RemoveMobj(mobj)
    if bit32.band(mobj.flags, p_mobj.MF_SPECIAL) ~= 0
        and bit32.band(mobj.flags, p_mobj.MF_DROPPED) == 0
        and mobj.type ~= info.mobjtype.MT_INV
        and mobj.type ~= info.mobjtype.MT_INS then
        itemrespawnque[p_mobj.iquehead] = mobj.spawnpoint
        itemrespawntime[p_mobj.iquehead] = doomstat.leveltime
        p_mobj.iquehead = bit32.band(p_mobj.iquehead + 1, ITEMQUESIZE - 1)

        -- lose one off the end?
        if p_mobj.iquehead == p_mobj.iquetail then
            p_mobj.iquetail = bit32.band(p_mobj.iquetail + 1, ITEMQUESIZE - 1)
        end
    end

    -- unlink from sector and block lists
    p_maputl.P_UnsetThingPosition(mobj)

    -- stop any playing sound
    s_sound.S_StopSound(mobj)

    -- free block
    p_tick.P_RemoveThinker(mobj)
end

-- ---------------------------------------------------------------------------
-- P_RespawnSpecials
-- ---------------------------------------------------------------------------

function p_mobj.P_RespawnSpecials()
    local x
    local y
    local z

    local ss
    local mo
    local mthing

    local i

    -- only respawn items in deathmatch
    if doomstat.deathmatch ~= 2 then
        return
    end

    -- nothing left to respawn?
    if p_mobj.iquehead == p_mobj.iquetail then
        return
    end

    -- wait at least 30 seconds
    if doomstat.leveltime - itemrespawntime[p_mobj.iquetail] < 30 * doomtype.TICRATE then
        return
    end

    mthing = itemrespawnque[p_mobj.iquetail]

    x = mthing.x * FRACUNIT
    y = mthing.y * FRACUNIT

    -- spawn a teleport fog at the new spot
    ss = r_main.R_PointInSubsector(x, y)
    mo = p_mobj.P_SpawnMobj(x, y, ss.sector.floorheight, info.mobjtype.MT_IFOG)
    s_sound.S_StartSound(mo, sounds.sfxenum.sfx_itmbk)

    -- find which type to spawn
    local i = info.NUMMOBJTYPES
    for j = 0, info.NUMMOBJTYPES - 1 do
        if mthing.type == info.mobjinfo[j + 1].doomednum then
            i = j
            break
        end
    end

    if i >= info.NUMMOBJTYPES then
        -- Vanilla would index out of bounds here; guard to avoid a crash.
        return
    end

    -- spawn it
    if bit32.band(info.mobjinfo[i + 1].flags, p_mobj.MF_SPAWNCEILING) ~= 0 then
        z = ONCEILINGZ
    else
        z = ONFLOORZ
    end

    mo = p_mobj.P_SpawnMobj(x, y, z, i)
    mo.spawnpoint = mthing
    mo.angle = (doomtype.ANG45 * (mthing.angle // 45)) % 0x100000000

    -- pull it from the que
    p_mobj.iquetail = bit32.band(p_mobj.iquetail + 1, ITEMQUESIZE - 1)
end

-- ---------------------------------------------------------------------------
-- P_SpawnPlayer
-- Called when a player is spawned on the level.
-- ---------------------------------------------------------------------------

function p_mobj.P_SpawnPlayer(mthing)
    local p
    local x
    local y
    local z

    local mobj

    local i

    if mthing.type == 0 then
        return
    end

    -- not playing?
    if not doomstat.playeringame[mthing.type] then -- type-1 -> 0-based, Lua 1-based
        return
    end

    p = doomstat.players[mthing.type]

    if p.playerstate == 2 then -- PST_REBORN
        g_game.G_PlayerReborn(mthing.type - 1)
    end

    x = mthing.x * FRACUNIT
    y = mthing.y * FRACUNIT
    z = ONFLOORZ
    mobj = p_mobj.P_SpawnMobj(x, y, z, info.mobjtype.MT_PLAYER)

    -- set color translations for player sprites
    if mthing.type > 1 then
        mobj.flags = bit32.bor(mobj.flags,
            doomtype.lshift32(mthing.type - 1, 26)) -- (type-1)<<MF_TRANSSHIFT
    end

    mobj.angle = (doomtype.ANG45 * (mthing.angle // 45)) % 0x100000000
    mobj.player = p
    mobj.player_index = mthing.type - 1
    mobj.health = p.health

    p.mo = mobj
    p.playerstate = 0 -- PST_LIVE
    p.refire = 0
    p.message = nil
    p.damagecount = 0
    p.bonuscount = 0
    p.extralight = 0
    p.fixedcolormap = 0
    p.viewheight = VIEWHEIGHT

    -- setup gun psprite
    p_pspr.P_SetupPsprites(p)

    -- give all cards in death match mode
    if doomstat.deathmatch ~= 0 then
        for i = 0, doomdef.NUMCARDS - 1 do
            p.cards[i + 1] = true
        end
    end

    if mthing.type - 1 == doomstat.consoleplayer then
        -- Wake up the status bar and heads-up text.
        st_stuff.ST_Start()
        hu_stuff.HU_Start()
    end
end

-- ---------------------------------------------------------------------------
-- P_SpawnMapThing
-- The fields of the mapthing should already be in host byte order.
-- ---------------------------------------------------------------------------

function p_mobj.P_SpawnMapThing(mthing)
    local i
    local bit_
    local mobj
    local x
    local y
    local z

    -- count deathmatch start positions
    if mthing.type == 11 then
        local dp = doomstat.deathmatch_p or 1
        if dp <= doomstat.MAX_DM_STARTS then
            doomstat.deathmatchstarts[dp] = mthing
            doomstat.deathmatch_p = dp + 1
        end
        return
    end

    if mthing.type <= 0 then
        -- Thing type 0 is actually "player -1 start".
        -- For some reason, Vanilla Doom accepts/ignores this.
        return
    end

    -- check for players specially
    if mthing.type <= 4 then
        -- save spots for respawning in network games
        doomstat.playerstarts[mthing.type] = mthing
        if doomstat.deathmatch == 0 then
            p_mobj.P_SpawnPlayer(mthing)
        end
        return
    end

    -- check for appropriate skill level
    if not doomstat.netgame and bit32.band(mthing.options, 16) ~= 0 then
        return
    end

    if doomstat.gameskill == 0 then -- sk_baby
        bit_ = 1
    elseif doomstat.gameskill == 4 then -- sk_nightmare
        bit_ = 4
    else
        bit_ = 2 ^ (doomstat.gameskill - 1) -- 1 << (gameskill-1)
    end

    if bit32.band(mthing.options, bit_) == 0 then
        return
    end

    -- find which type to spawn
    local i = info.NUMMOBJTYPES
    for j = 0, info.NUMMOBJTYPES - 1 do
        if mthing.type == info.mobjinfo[j + 1].doomednum then
            i = j
            break
        end
    end

    if i == info.NUMMOBJTYPES then
        i_system.I_Error("P_SpawnMapThing: Unknown type %i at (%i, %i)",
            mthing.type, mthing.x, mthing.y)
    end

    -- don't spawn keycards and players in deathmatch
    if doomstat.deathmatch ~= 0
        and bit32.band(info.mobjinfo[i + 1].flags, p_mobj.MF_NOTDMATCH) ~= 0 then
        return
    end

    -- don't spawn any monsters if -nomonsters
    if doomstat.nomonsters
        and (i == info.mobjtype.MT_SKULL
            or bit32.band(info.mobjinfo[i + 1].flags, p_mobj.MF_COUNTKILL) ~= 0) then
        return
    end

    -- spawn it
    x = mthing.x * FRACUNIT
    y = mthing.y * FRACUNIT

    if bit32.band(info.mobjinfo[i + 1].flags, p_mobj.MF_SPAWNCEILING) ~= 0 then
        z = ONCEILINGZ
    else
        z = ONFLOORZ
    end

    mobj = p_mobj.P_SpawnMobj(x, y, z, i)
    mobj.spawnpoint = mthing

    if mobj.tics > 0 then
        mobj.tics = 1 + (m_random.P_Random() % mobj.tics)
    end
    if bit32.band(mobj.flags, p_mobj.MF_COUNTKILL) ~= 0 then
        doomstat.totalkills = doomstat.totalkills + 1
    end
    if bit32.band(mobj.flags, p_mobj.MF_COUNTITEM) ~= 0 then
        doomstat.totalitems = doomstat.totalitems + 1
    end

    mobj.angle = (doomtype.ANG45 * (mthing.angle // 45)) % 0x100000000
    if bit32.band(mthing.options, 8) ~= 0 then -- MTF_AMBUSH
        mobj.flags = bit32.bor(mobj.flags, p_mobj.MF_AMBUSH)
    end
end

-- ---------------------------------------------------------------------------
-- GAME SPAWN FUNCTIONS
-- ---------------------------------------------------------------------------

-- P_SpawnPuff.
function p_mobj.P_SpawnPuff(x, y, z)
    local th

    z = z + ((m_random.P_Random() - m_random.P_Random()) * 1024) -- <<10

    th = p_mobj.P_SpawnMobj(x, y, z, info.mobjtype.MT_PUFF)
    th.momz = FRACUNIT
    th.tics = th.tics - (m_random.P_Random() % 4) -- &3

    if th.tics < 1 then
        th.tics = 1
    end

    -- don't make punches spark on the wall
    if p_map.attackrange == MELEERANGE then
        p_mobj.P_SetMobjState(th, info.statenum.S_PUFF3)
    end
end

-- P_SpawnBlood.
function p_mobj.P_SpawnBlood(x, y, z, damage)
    local th

    z = z + ((m_random.P_Random() - m_random.P_Random()) * 1024) -- <<10
    th = p_mobj.P_SpawnMobj(x, y, z, info.mobjtype.MT_BLOOD)
    th.momz = FRACUNIT * 2
    th.tics = th.tics - (m_random.P_Random() % 4) -- &3

    if th.tics < 1 then
        th.tics = 1
    end

    if damage <= 12 and damage >= 9 then
        p_mobj.P_SetMobjState(th, info.statenum.S_BLOOD2)
    elseif damage < 9 then
        p_mobj.P_SetMobjState(th, info.statenum.S_BLOOD3)
    end
end

-- ---------------------------------------------------------------------------
-- P_CheckMissileSpawn
-- Moves the missile forward a bit and possibly explodes it right there.
-- ---------------------------------------------------------------------------

function p_mobj.P_CheckMissileSpawn(th)
    th.tics = th.tics - (m_random.P_Random() % 4) -- &3
    if th.tics < 1 then
        th.tics = 1
    end

    -- move a little forward so an angle can
    -- be computed if it immediately explodes
    th.x = th.x + (th.momx // 2)
    th.y = th.y + (th.momy // 2)
    th.z = th.z + (th.momz // 2)

    if not p_map.P_TryMove(th, th.x, th.y) then
        p_mobj.P_ExplodeMissile(th)
    end
end

-- P_SubstNullMobj: certain functions assume a mobj pointer is non-NULL.
-- Vanilla Doom did not crash because of the lack of proper memory protection;
-- we substitute NULL pointers with a dummy mobj to avoid crashes.
function p_mobj.P_SubstNullMobj(mobj)
    if mobj == nil then
        if p_mobj.dummy_mobj == nil then
            p_mobj.dummy_mobj = {
                x = 0, y = 0, z = 0, flags = 0,
            }
        end
        return p_mobj.dummy_mobj
    end
    return mobj
end

-- ---------------------------------------------------------------------------
-- P_SpawnMissile
-- ---------------------------------------------------------------------------

function p_mobj.P_SpawnMissile(source, dest, type)
    local th
    local an
    local dist

    th = p_mobj.P_SpawnMobj(source.x, source.y, source.z + 4 * 8 * FRACUNIT, type)

    if info.mobjinfo[type + 1].seesound ~= 0 then
        s_sound.S_StartSound(th, info.mobjinfo[type + 1].seesound)
    end

    th.target = source -- where it came from
    an = r_main.R_PointToAngle2(source.x, source.y, dest.x, dest.y)

    -- fuzzy player
    if bit32.band(dest.flags, p_mobj.MF_SHADOW) ~= 0 then
        an = (an + doomtype.lshift32(
            m_random.P_Random() - m_random.P_Random(), 20)) % 0x100000000
    end

    th.angle = an
    an = bit32.rshift(an, 19) -- ANGLETOFINESHIFT
    th.momx = m_fixed.FixedMul(th.info.speed, tables.finesine[an + 1 + 2048]) -- finecosine[an]
    th.momy = m_fixed.FixedMul(th.info.speed, tables.finesine[an + 1])

    dist = p_maputl.P_AproxDistance(dest.x - source.x, dest.y - source.y)
    dist = dist // th.info.speed

    if dist < 1 then
        dist = 1
    end

    th.momz = (dest.z - source.z) // dist
    p_mobj.P_CheckMissileSpawn(th)

    return th
end

-- ---------------------------------------------------------------------------
-- P_SpawnPlayerMissile
-- Tries to aim at a nearby monster.
-- ---------------------------------------------------------------------------

function p_mobj.P_SpawnPlayerMissile(source, type)
    local th
    local an

    local x
    local y
    local z
    local slope

    -- see which target is to be aimed at
    an = source.angle
    slope = p_map.P_AimLineAttack(source, an, 16 * 64 * FRACUNIT)

    if not p_map.linetarget then
        an = (an + 2 ^ 26) % 0x100000000 -- (1<<26)
        slope = p_map.P_AimLineAttack(source, an, 16 * 64 * FRACUNIT)

        if not p_map.linetarget then
            an = (an - 2 ^ 27) % 0x100000000 -- (2<<26)
            slope = p_map.P_AimLineAttack(source, an, 16 * 64 * FRACUNIT)
        end

        if not p_map.linetarget then
            an = source.angle
            slope = 0
        end
    end

    x = source.x
    y = source.y
    z = source.z + 4 * 8 * FRACUNIT

    th = p_mobj.P_SpawnMobj(x, y, z, type)

    if info.mobjinfo[type + 1].seesound ~= 0 then
        s_sound.S_StartSound(th, info.mobjinfo[type + 1].seesound)
    end

    th.target = source
    th.angle = an
    th.momx = m_fixed.FixedMul(th.info.speed,
        tables.finesine[bit32.rshift(an, 19) + 1 + 2048]) -- finecosine[an>>ANGLETOFINESHIFT]
    th.momy = m_fixed.FixedMul(th.info.speed,
        tables.finesine[bit32.rshift(an, 19) + 1])
    th.momz = m_fixed.FixedMul(th.info.speed, slope)

    p_mobj.P_CheckMissileSpawn(th)
end

return p_mobj
end)()

p_enemy = (function()
local p_enemy = {}

local FRACUNIT = m_fixed.FRACUNIT
local FLOATSPEED = FRACUNIT * 4
local MELEERANGE = 64 * FRACUNIT
local MISSILERANGE = 32 * 64 * FRACUNIT
local MAXRADIUS = 32 * FRACUNIT
local SKULLSPEED = 20 * FRACUNIT
local TRACEANGLE = 0xc000000
local FATSPREAD = doomtype.ANG90 // 8 -- ANG90/8

local ANG90 = doomtype.ANG90
local ANG180 = doomtype.ANG180
local ANG270 = doomtype.ANG270

-- ---------------------------------------------------------------------------
-- dirtype_t (p_enemy.c)
-- ---------------------------------------------------------------------------

p_enemy.DI_EAST = 0
p_enemy.DI_NORTHEAST = 1
p_enemy.DI_NORTH = 2
p_enemy.DI_NORTHWEST = 3
p_enemy.DI_WEST = 4
p_enemy.DI_SOUTHWEST = 5
p_enemy.DI_SOUTH = 6
p_enemy.DI_SOUTHEAST = 7
p_enemy.DI_NODIR = 8
p_enemy.NUMDIRS = 9

-- P_NewChaseDir related LUT.
local opposite = {
    p_enemy.DI_WEST, p_enemy.DI_SOUTHWEST, p_enemy.DI_SOUTH, p_enemy.DI_SOUTHEAST,
    p_enemy.DI_EAST, p_enemy.DI_NORTHEAST, p_enemy.DI_NORTH, p_enemy.DI_NORTHWEST,
    p_enemy.DI_NODIR,
}

local diags = {
    p_enemy.DI_NORTHWEST, p_enemy.DI_NORTHEAST,
    p_enemy.DI_SOUTHWEST, p_enemy.DI_SOUTHEAST,
}

local xspeed = { FRACUNIT, 47000, 0, -47000, -FRACUNIT, -47000, 0, 47000 }
local yspeed = { 0, 47000, FRACUNIT, 47000, 0, -47000, -FRACUNIT, -47000 }

-- ---------------------------------------------------------------------------
-- P_RecursiveSound / P_NoiseAlert
-- If a monster yells at a player, it will alert other monsters to the
-- player. Recursively traverses adjacent sectors; sound blocking lines cut
-- off traversal.
-- ---------------------------------------------------------------------------

local soundtarget = nil

local function P_RecursiveSound(sec, soundblocks)
    local check
    local other

    -- wake up all monsters in this sector
    if sec.validcount == r_state.validcount
        and sec.soundtraversed <= soundblocks + 1 then
        return -- already flooded
    end

    sec.validcount = r_state.validcount
    sec.soundtraversed = soundblocks + 1
    sec.soundtarget = soundtarget

    for i = 1, sec.linecount do
        check = sec.lines[i]
        if bit32.band(check.flags, 4) == 0 then -- ML_TWOSIDED
            -- continue
        else
            p_maputl.P_LineOpening(check)

            if p_maputl.openrange <= 0 then
                -- closed door
            else
                if r_state.sides[check.sidenum[1] + 1].sector == sec then
                    other = r_state.sides[check.sidenum[2] + 1].sector
                else
                    other = r_state.sides[check.sidenum[1] + 1].sector
                end

                if bit32.band(check.flags, 64) ~= 0 then -- ML_SOUNDBLOCK
                    if soundblocks == 0 then
                        P_RecursiveSound(other, 1)
                    end
                else
                    P_RecursiveSound(other, soundblocks)
                end
            end
        end
    end
end

function p_enemy.P_NoiseAlert(target, emmiter)
    soundtarget = target
    r_state.validcount = r_state.validcount + 1
    P_RecursiveSound(emmiter.subsector.sector, 0)
end

-- ---------------------------------------------------------------------------
-- P_CheckMeleeRange
-- ---------------------------------------------------------------------------

function p_enemy.P_CheckMeleeRange(actor)
    local pl
    local dist

    if not actor.target then
        return false
    end

    pl = actor.target
    dist = p_maputl.P_AproxDistance(pl.x - actor.x, pl.y - actor.y)

    if dist >= MELEERANGE - 20 * FRACUNIT + pl.info.radius then
        return false
    end

    if not p_sight.P_CheckSight(actor, actor.target) then
        return false
    end

    return true
end

-- ---------------------------------------------------------------------------
-- P_CheckMissileRange
-- ---------------------------------------------------------------------------

function p_enemy.P_CheckMissileRange(actor)
    local dist

    if not p_sight.P_CheckSight(actor, actor.target) then
        return false
    end

    if bit32.band(actor.flags, p_mobj.MF_JUSTHIT) ~= 0 then
        -- the target just hit the enemy, so fight back!
        actor.flags = bit32.band(actor.flags, bit32.bnot(p_mobj.MF_JUSTHIT))
        return true
    end

    if actor.reactiontime ~= 0 then
        return false -- do not attack yet
    end

    -- OPTIMIZE: get this from a global checksight
    dist = p_maputl.P_AproxDistance(actor.x - actor.target.x,
        actor.y - actor.target.y) - 64 * FRACUNIT

    if actor.info.meleestate == 0 then
        dist = dist - 128 * FRACUNIT -- no melee attack, so fire more
    end

    dist = doomtype.rshift32(dist, 16) -- >>= 16

    if actor.type == info.mobjtype.MT_VILE then
        if dist > 14 * 64 then
            return false -- too far away
        end
    end

    if actor.type == info.mobjtype.MT_UNDEAD then
        if dist < 196 then
            return false -- close for fist attack
        end
        dist = doomtype.rshift32(dist, 1) -- >>= 1
    end

    if actor.type == info.mobjtype.MT_CYBORG
        or actor.type == info.mobjtype.MT_SPIDER
        or actor.type == info.mobjtype.MT_SKULL then
        dist = doomtype.rshift32(dist, 1) -- >>= 1
    end

    if dist > 200 then
        dist = 200
    end

    if actor.type == info.mobjtype.MT_CYBORG and dist > 160 then
        dist = 160
    end

    if m_random.P_Random() < dist then
        return false
    end

    return true
end

-- ---------------------------------------------------------------------------
-- P_Move
-- Move in the current direction; returns false if the move is blocked.
-- ---------------------------------------------------------------------------

function p_enemy.P_Move(actor)
    local tryx
    local tryy
    local ld
    local try_ok
    local good

    if actor.movedir == p_enemy.DI_NODIR then
        return false
    end

    if actor.movedir >= 8 then
        i_system.I_Error("Weird actor->movedir!")
    end

    tryx = actor.x + actor.info.speed * xspeed[actor.movedir + 1]
    tryy = actor.y + actor.info.speed * yspeed[actor.movedir + 1]

    try_ok = p_map.P_TryMove(actor, tryx, tryy)

    if not try_ok then
        -- open any specials
        if bit32.band(actor.flags, p_mobj.MF_FLOAT) ~= 0
            and p_map.floatok then
            -- must adjust height
            if actor.z < p_map.tmfloorz then
                actor.z = actor.z + FLOATSPEED
            else
                actor.z = actor.z - FLOATSPEED
            end

            actor.flags = bit32.bor(actor.flags, p_mobj.MF_INFLOAT)
            return true
        end

        if p_map.numspechit == 0 then
            return false
        end

        actor.movedir = p_enemy.DI_NODIR
        good = false
        while p_map.numspechit > 0 do
            p_map.numspechit = p_map.numspechit - 1
            ld = p_map.spechit[p_map.numspechit + 1]
            -- if the special is not a door that can be opened, return false
            if p_spec.P_UseSpecialLine(actor, ld, 0) then
                good = true
            end
        end
        return good
    else
        actor.flags = bit32.band(actor.flags, bit32.bnot(p_mobj.MF_INFLOAT))
    end

    if bit32.band(actor.flags, p_mobj.MF_FLOAT) == 0 then
        actor.z = actor.floorz
    end
    return true
end

-- ---------------------------------------------------------------------------
-- P_TryWalk
-- Attempts to move actor on in its current (ob->moveangle) direction.
-- If blocked by either a wall or an actor returns FALSE.
-- If move is either clear or blocked only by a door, returns TRUE and
-- sets... If a door is in the way, an OpenDoor call is made to start it
-- opening.
-- ---------------------------------------------------------------------------

function p_enemy.P_TryWalk(actor)
    if not p_enemy.P_Move(actor) then
        return false
    end

    actor.movecount = bit32.band(m_random.P_Random(), 15) -- &15
    return true
end

-- ---------------------------------------------------------------------------
-- P_NewChaseDir
-- ---------------------------------------------------------------------------

function p_enemy.P_NewChaseDir(actor)
    local deltax
    local deltay
    local d = { 0, 0, 0 }
    local olddir
    local turnaround

    if not actor.target then
        i_system.I_Error("P_NewChaseDir: called with no target")
    end

    olddir = actor.movedir
    turnaround = opposite[olddir + 1]

    deltax = actor.target.x - actor.x
    deltay = actor.target.y - actor.y

    if deltax > 10 * FRACUNIT then
        d[2] = p_enemy.DI_EAST -- d[1]
    elseif deltax < -10 * FRACUNIT then
        d[2] = p_enemy.DI_WEST
    else
        d[2] = p_enemy.DI_NODIR
    end

    if deltay < -10 * FRACUNIT then
        d[3] = p_enemy.DI_SOUTH -- d[2]
    elseif deltay > 10 * FRACUNIT then
        d[3] = p_enemy.DI_NORTH
    else
        d[3] = p_enemy.DI_NODIR
    end

    -- try direct route
    if d[2] ~= p_enemy.DI_NODIR and d[3] ~= p_enemy.DI_NODIR then
        -- diags[((deltay<0)<<1)+(deltax>0)]
        actor.movedir = diags[
            ((deltay < 0 and 1 or 0) * 2) + (deltax > 0 and 1 or 0) + 1]
        if actor.movedir ~= turnaround and p_enemy.P_TryWalk(actor) then
            return
        end
    end

    -- try other directions
    if m_random.P_Random() > 200 or math.abs(deltay) > math.abs(deltax) then
        local tdir = d[2]
        d[2] = d[3]
        d[3] = tdir
    end

    if d[2] == turnaround then
        d[2] = p_enemy.DI_NODIR
    end
    if d[3] == turnaround then
        d[3] = p_enemy.DI_NODIR
    end

    if d[2] ~= p_enemy.DI_NODIR then
        actor.movedir = d[2]
        if p_enemy.P_TryWalk(actor) then
            -- either moved forward or attacked
            return
        end
    end

    if d[3] ~= p_enemy.DI_NODIR then
        actor.movedir = d[3]
        if p_enemy.P_TryWalk(actor) then
            return
        end
    end

    -- there is no direct path to the player, so pick another direction.
    if olddir ~= p_enemy.DI_NODIR then
        actor.movedir = olddir
        if p_enemy.P_TryWalk(actor) then
            return
        end
    end

    -- randomly determine direction of search
    if bit32.band(m_random.P_Random(), 1) ~= 0 then
        for td = p_enemy.DI_EAST, p_enemy.DI_SOUTHEAST do
            if td ~= turnaround then
                actor.movedir = td
                if p_enemy.P_TryWalk(actor) then
                    return
                end
            end
        end
    else
        for td = p_enemy.DI_SOUTHEAST, p_enemy.DI_EAST, -1 do
            if td ~= turnaround then
                actor.movedir = td
                if p_enemy.P_TryWalk(actor) then
                    return
                end
            end
        end
    end

    if turnaround ~= p_enemy.DI_NODIR then
        actor.movedir = turnaround
        if p_enemy.P_TryWalk(actor) then
            return
        end
    end

    actor.movedir = p_enemy.DI_NODIR -- can not move
end

-- ---------------------------------------------------------------------------
-- P_LookForPlayers
-- If allaround is false, only look 180 degrees in front.
-- Returns true if a player is targeted.
-- ---------------------------------------------------------------------------

function p_enemy.P_LookForPlayers(actor, allaround)
    local c
    local stop
    local player
    local an
    local dist

    c = 0
    stop = bit32.band(actor.lastlook - 1, 3)

    while true do
        if doomstat.playeringame[actor.lastlook + 1] then
            c = c + 1

            if c == 3 or actor.lastlook == stop then
                -- done looking
                return false
            end

            player = doomstat.players[actor.lastlook + 1]

            if player.health > 0 then
                if p_sight.P_CheckSight(actor, player.mo) then
                    if allaround == 0 then
                        an = (r_main.R_PointToAngle2(actor.x, actor.y,
                            player.mo.x, player.mo.y) - actor.angle) % 0x100000000

                        if an > ANG90 and an < ANG270 then
                            dist = p_maputl.P_AproxDistance(
                                player.mo.x - actor.x, player.mo.y - actor.y)
                            -- if real close, react anyway
                            if dist <= MELEERANGE then
                                actor.target = player.mo
                                return true
                            end
                            -- behind back
                        else
                            actor.target = player.mo
                            return true
                        end
                    else
                        actor.target = player.mo
                        return true
                    end
                end
            end
        end

        actor.lastlook = bit32.band(actor.lastlook + 1, 3)
    end

    return false
end

-- ---------------------------------------------------------------------------
-- A_KeenDie
-- DOOM II special, map 32. Uses special tag 666.
-- ---------------------------------------------------------------------------

function p_enemy.A_KeenDie(mo)
    local mo2
    local junk

    p_enemy.A_Fall(mo)

    -- scan the remaining thinkers to see if all Keens are dead
    local allDead = true
    p_tick.iterateThinkers(function(th)
        if th.thinkfunc ~= p_mobj.P_MobjThinker then
            return
        end
        mo2 = th
        if mo2 ~= mo and mo2.type == mo.type and mo2.health > 0 then
            -- other Keen not dead
            allDead = false
        end
    end)

    if not allDead then
        return
    end

    junk = { tag = 666 }
    p_doors.EV_DoDoor(junk, p_doors.vld_open)
end

-- ---------------------------------------------------------------------------
-- A_Look
-- Stay in state until a player is sighted.
-- ---------------------------------------------------------------------------

function p_enemy.A_Look(actor)
    local targ

    actor.threshold = 0 -- any shot will wake up
    targ = actor.subsector.sector.soundtarget

    local seeyou = false

    if targ and bit32.band(targ.flags, p_mobj.MF_SHOOTABLE) ~= 0 then
        actor.target = targ

        if bit32.band(actor.flags, p_mobj.MF_AMBUSH) ~= 0 then
            if p_sight.P_CheckSight(actor, actor.target) then
                seeyou = true
            end
        else
            seeyou = true
        end
    end

    if not seeyou then
        if not p_enemy.P_LookForPlayers(actor, false) then
            return
        end
    end

    -- go into chase state
    -- seeyou:
    if actor.info.seesound ~= 0 then
        local sound

        local seesound = actor.info.seesound
        if seesound == sounds.sfxenum.sfx_posit1
            or seesound == sounds.sfxenum.sfx_posit2
            or seesound == sounds.sfxenum.sfx_posit3 then
            sound = sounds.sfxenum.sfx_posit1 + (m_random.P_Random() % 3)
        elseif seesound == sounds.sfxenum.sfx_bgsit1
            or seesound == sounds.sfxenum.sfx_bgsit2 then
            sound = sounds.sfxenum.sfx_bgsit1 + (m_random.P_Random() % 2)
        else
            sound = actor.info.seesound
        end

        if actor.type == info.mobjtype.MT_SPIDER
            or actor.type == info.mobjtype.MT_CYBORG then
            -- full volume
            s_sound.S_StartSound(nil, sound)
        else
            s_sound.S_StartSound(actor, sound)
        end
    end

    p_mobj.P_SetMobjState(actor, actor.info.seestate)
end

-- ---------------------------------------------------------------------------
-- A_Chase
-- Actor has a melee attack, so it tries to close as fast as possible.
-- ---------------------------------------------------------------------------

function p_enemy.A_Chase(actor)
    local delta

    if actor.reactiontime ~= 0 then
        actor.reactiontime = actor.reactiontime - 1
    end

    -- modify target threshold
    if actor.threshold ~= 0 then
        if not actor.target or actor.target.health <= 0 then
            actor.threshold = 0
        else
            actor.threshold = actor.threshold - 1
        end
    end

    -- turn towards movement direction if not there yet
    if actor.movedir < 8 then
        actor.angle = bit32.band(actor.angle, doomtype.lshift32(7, 29)) -- (7<<29)
        delta = actor.angle - doomtype.lshift32(actor.movedir, 29)

        if delta > 0 then
            actor.angle = (actor.angle - ANG90 // 2) % 0x100000000
        elseif delta < 0 then
            actor.angle = (actor.angle + ANG90 // 2) % 0x100000000
        end
    end

    if not actor.target
        or bit32.band(actor.target.flags, p_mobj.MF_SHOOTABLE) == 0 then
        -- look for a new target
        if p_enemy.P_LookForPlayers(actor, true) then
            return -- got a new target
        end

        p_mobj.P_SetMobjState(actor, actor.info.spawnstate)
        return
    end

    -- do not attack twice in a row
    if bit32.band(actor.flags, p_mobj.MF_JUSTATTACKED) ~= 0 then
        actor.flags = bit32.band(actor.flags, bit32.bnot(p_mobj.MF_JUSTATTACKED))
        if doomstat.gameskill ~= d_mode.sk_nightmare and not doomstat.fastparm then
            p_enemy.P_NewChaseDir(actor)
        end
        return
    end

    -- check for melee attack
    if actor.info.meleestate ~= 0
        and p_enemy.P_CheckMeleeRange(actor) then
        if actor.info.attacksound ~= 0 then
            s_sound.S_StartSound(actor, actor.info.attacksound)
        end

        p_mobj.P_SetMobjState(actor, actor.info.meleestate)
        return
    end

    -- check for missile attack
    if actor.info.missilestate ~= 0 then
        local missile_ok = not (doomstat.gameskill < d_mode.sk_nightmare
            and not doomstat.fastparm and actor.movecount ~= 0)

        if missile_ok and p_enemy.P_CheckMissileRange(actor) then
            p_mobj.P_SetMobjState(actor, actor.info.missilestate)
            actor.flags = bit32.bor(actor.flags, p_mobj.MF_JUSTATTACKED)
            return
        end
    end

    -- ? (nomissile:)
    -- possibly choose another target
    if doomstat.netgame
        and actor.threshold == 0
        and not p_sight.P_CheckSight(actor, actor.target) then
        if p_enemy.P_LookForPlayers(actor, true) then
            return -- got a new target
        end
    end

    -- chase towards player
    actor.movecount = actor.movecount - 1
    if actor.movecount < 0 or not p_enemy.P_Move(actor) then
        p_enemy.P_NewChaseDir(actor)
    end

    -- make active sound
    if actor.info.activesound ~= 0 and m_random.P_Random() < 3 then
        s_sound.S_StartSound(actor, actor.info.activesound)
    end
end

-- ---------------------------------------------------------------------------
-- A_FaceTarget
-- ---------------------------------------------------------------------------

function p_enemy.A_FaceTarget(actor)
    if not actor.target then
        return
    end

    actor.flags = bit32.band(actor.flags, bit32.bnot(p_mobj.MF_AMBUSH))

    actor.angle = r_main.R_PointToAngle2(actor.x, actor.y,
        actor.target.x, actor.target.y) % 0x100000000

    if bit32.band(actor.target.flags, p_mobj.MF_SHADOW) ~= 0 then
        actor.angle = (actor.angle + doomtype.lshift32(
            m_random.P_Random() - m_random.P_Random(), 21)) % 0x100000000
    end
end

-- ---------------------------------------------------------------------------
-- A_PosAttack
-- ---------------------------------------------------------------------------

function p_enemy.A_PosAttack(actor)
    local angle
    local damage
    local slope

    if not actor.target then
        return
    end

    p_enemy.A_FaceTarget(actor)
    angle = actor.angle
    slope = p_map.P_AimLineAttack(actor, angle, MISSILERANGE)

    s_sound.S_StartSound(actor, sounds.sfxenum.sfx_pistol)
    angle = (angle + doomtype.lshift32(
        m_random.P_Random() - m_random.P_Random(), 20)) % 0x100000000
    damage = ((m_random.P_Random() % 5) + 1) * 3
    p_map.P_LineAttack(actor, angle, MISSILERANGE, slope, damage)
end

-- ---------------------------------------------------------------------------
-- A_SPosAttack
-- ---------------------------------------------------------------------------

function p_enemy.A_SPosAttack(actor)
    local angle
    local bangle
    local damage
    local slope

    if not actor.target then
        return
    end

    s_sound.S_StartSound(actor, sounds.sfxenum.sfx_shotgn)
    p_enemy.A_FaceTarget(actor)
    bangle = actor.angle
    slope = p_map.P_AimLineAttack(actor, bangle, MISSILERANGE)

    for i = 0, 2 do
        angle = (bangle + doomtype.lshift32(
            m_random.P_Random() - m_random.P_Random(), 20)) % 0x100000000
        damage = ((m_random.P_Random() % 5) + 1) * 3
        p_map.P_LineAttack(actor, angle, MISSILERANGE, slope, damage)
    end
end

-- ---------------------------------------------------------------------------
-- A_CPosAttack
-- ---------------------------------------------------------------------------

function p_enemy.A_CPosAttack(actor)
    local angle
    local bangle
    local damage
    local slope

    if not actor.target then
        return
    end

    s_sound.S_StartSound(actor, sounds.sfxenum.sfx_shotgn)
    p_enemy.A_FaceTarget(actor)
    bangle = actor.angle
    slope = p_map.P_AimLineAttack(actor, bangle, MISSILERANGE)

    angle = (bangle + doomtype.lshift32(
        m_random.P_Random() - m_random.P_Random(), 20)) % 0x100000000
    damage = ((m_random.P_Random() % 5) + 1) * 3
    p_map.P_LineAttack(actor, angle, MISSILERANGE, slope, damage)
end

-- ---------------------------------------------------------------------------
-- A_CPosRefire
-- Keep firing unless target got out of sight.
-- ---------------------------------------------------------------------------

function p_enemy.A_CPosRefire(actor)
    p_enemy.A_FaceTarget(actor)

    if m_random.P_Random() < 40 then
        return
    end

    if not actor.target
        or actor.target.health <= 0
        or not p_sight.P_CheckSight(actor, actor.target) then
        p_mobj.P_SetMobjState(actor, actor.info.seestate)
    end
end

-- ---------------------------------------------------------------------------
-- A_SpidRefire
-- Keep firing unless target got out of sight.
-- ---------------------------------------------------------------------------

function p_enemy.A_SpidRefire(actor)
    p_enemy.A_FaceTarget(actor)

    if m_random.P_Random() < 10 then
        return
    end

    if not actor.target
        or actor.target.health <= 0
        or not p_sight.P_CheckSight(actor, actor.target) then
        p_mobj.P_SetMobjState(actor, actor.info.seestate)
    end
end

-- ---------------------------------------------------------------------------
-- A_BspiAttack
-- ---------------------------------------------------------------------------

function p_enemy.A_BspiAttack(actor)
    if not actor.target then
        return
    end

    p_enemy.A_FaceTarget(actor)

    -- launch a missile
    p_mobj.P_SpawnMissile(actor, actor.target, info.mobjtype.MT_ARACHPLAZ)
end

-- ---------------------------------------------------------------------------
-- A_TroopAttack
-- ---------------------------------------------------------------------------

function p_enemy.A_TroopAttack(actor)
    local damage

    if not actor.target then
        return
    end

    p_enemy.A_FaceTarget(actor)
    if p_enemy.P_CheckMeleeRange(actor) then
        s_sound.S_StartSound(actor, sounds.sfxenum.sfx_claw)
        damage = (m_random.P_Random() % 8 + 1) * 3
        p_inter.P_DamageMobj(actor.target, actor, actor, damage)
        return
    end

    -- launch a missile
    p_mobj.P_SpawnMissile(actor, actor.target, info.mobjtype.MT_TROOPSHOT)
end

-- ---------------------------------------------------------------------------
-- A_SargAttack
-- ---------------------------------------------------------------------------

function p_enemy.A_SargAttack(actor)
    local damage

    if not actor.target then
        return
    end

    p_enemy.A_FaceTarget(actor)
    if p_enemy.P_CheckMeleeRange(actor) then
        damage = ((m_random.P_Random() % 10) + 1) * 4
        p_inter.P_DamageMobj(actor.target, actor, actor, damage)
    end
end

-- ---------------------------------------------------------------------------
-- A_HeadAttack
-- ---------------------------------------------------------------------------

function p_enemy.A_HeadAttack(actor)
    local damage

    if not actor.target then
        return
    end

    p_enemy.A_FaceTarget(actor)
    if p_enemy.P_CheckMeleeRange(actor) then
        damage = (m_random.P_Random() % 6 + 1) * 10
        p_inter.P_DamageMobj(actor.target, actor, actor, damage)
        return
    end

    -- launch a missile
    p_mobj.P_SpawnMissile(actor, actor.target, info.mobjtype.MT_HEADSHOT)
end

-- ---------------------------------------------------------------------------
-- A_CyberAttack
-- ---------------------------------------------------------------------------

function p_enemy.A_CyberAttack(actor)
    if not actor.target then
        return
    end

    p_enemy.A_FaceTarget(actor)
    p_mobj.P_SpawnMissile(actor, actor.target, info.mobjtype.MT_ROCKET)
end

-- ---------------------------------------------------------------------------
-- A_BruisAttack
-- ---------------------------------------------------------------------------

function p_enemy.A_BruisAttack(actor)
    local damage

    if not actor.target then
        return
    end

    if p_enemy.P_CheckMeleeRange(actor) then
        s_sound.S_StartSound(actor, sounds.sfxenum.sfx_claw)
        damage = (m_random.P_Random() % 8 + 1) * 10
        p_inter.P_DamageMobj(actor.target, actor, actor, damage)
        return
    end

    -- launch a missile
    p_mobj.P_SpawnMissile(actor, actor.target, info.mobjtype.MT_BRUISERSHOT)
end

-- ---------------------------------------------------------------------------
-- A_SkelMissile
-- ---------------------------------------------------------------------------

function p_enemy.A_SkelMissile(actor)
    local mo

    if not actor.target then
        return
    end

    p_enemy.A_FaceTarget(actor)
    actor.z = actor.z + 16 * FRACUNIT -- so missile spawns higher
    mo = p_mobj.P_SpawnMissile(actor, actor.target, info.mobjtype.MT_TRACER)
    actor.z = actor.z - 16 * FRACUNIT -- back to normal

    mo.x = mo.x + mo.momx
    mo.y = mo.y + mo.momy
    mo.tracer = actor.target
end

-- ---------------------------------------------------------------------------
-- A_Tracer
-- ---------------------------------------------------------------------------

function p_enemy.A_Tracer(actor)
    local exact
    local dist
    local slope
    local dest
    local th

    if bit32.band(d_loop.gametic, 3) ~= 0 then
        return
    end

    -- spawn a puff of smoke behind the rocket
    p_mobj.P_SpawnPuff(actor.x, actor.y, actor.z)

    th = p_mobj.P_SpawnMobj(actor.x - actor.momx,
        actor.y - actor.momy, actor.z, info.mobjtype.MT_SMOKE)

    th.momz = FRACUNIT
    th.tics = th.tics - bit32.band(m_random.P_Random(), 3) -- &3
    if th.tics < 1 then
        th.tics = 1
    end

    -- adjust direction
    dest = actor.tracer

    if not dest or dest.health <= 0 then
        return
    end

    -- change angle
    exact = r_main.R_PointToAngle2(actor.x, actor.y,
        dest.x, dest.y) % 0x100000000

    if exact ~= actor.angle then
        if (exact - actor.angle) % 0x100000000 > 0x80000000 then
            actor.angle = (actor.angle - TRACEANGLE) % 0x100000000
            if (exact - actor.angle) % 0x100000000 < 0x80000000 then
                actor.angle = exact
            end
        else
            actor.angle = (actor.angle + TRACEANGLE) % 0x100000000
            if (exact - actor.angle) % 0x100000000 > 0x80000000 then
                actor.angle = exact
            end
        end
    end

    exact = bit32.rshift(actor.angle, 19) -- ANGLETOFINESHIFT
    actor.momx = m_fixed.FixedMul(actor.info.speed,
        tables.finesine[exact + 1 + 2048]) -- finecosine[exact]
    actor.momy = m_fixed.FixedMul(actor.info.speed,
        tables.finesine[exact + 1])

    -- change slope
    dist = p_maputl.P_AproxDistance(dest.x - actor.x, dest.y - actor.y)

    dist = doomtype.truncdiv(dist, actor.info.speed)

    if dist < 1 then
        dist = 1
    end
    slope = doomtype.truncdiv(dest.z + 40 * FRACUNIT - actor.z, dist)

    if slope < actor.momz then
        actor.momz = actor.momz - FRACUNIT // 8
    else
        actor.momz = actor.momz + FRACUNIT // 8
    end
end

-- ---------------------------------------------------------------------------
-- A_SkelWhoosh
-- ---------------------------------------------------------------------------

function p_enemy.A_SkelWhoosh(actor)
    if not actor.target then
        return
    end
    p_enemy.A_FaceTarget(actor)
    s_sound.S_StartSound(actor, sounds.sfxenum.sfx_skeswg)
end

-- ---------------------------------------------------------------------------
-- A_SkelFist
-- ---------------------------------------------------------------------------

function p_enemy.A_SkelFist(actor)
    local damage

    if not actor.target then
        return
    end

    p_enemy.A_FaceTarget(actor)

    if p_enemy.P_CheckMeleeRange(actor) then
        damage = ((m_random.P_Random() % 10) + 1) * 6
        s_sound.S_StartSound(actor, sounds.sfxenum.sfx_skepch)
        p_inter.P_DamageMobj(actor.target, actor, actor, damage)
    end
end

-- ---------------------------------------------------------------------------
-- PIT_VileCheck
-- Detect a corpse that could be raised.
-- ---------------------------------------------------------------------------

local corpsehit = nil
local viletryx = 0
local viletryy = 0

-- C extern: mobj_t* vileobj (set by A_VileChase; never read in the C).
p_enemy.vileobj = nil

local function PIT_VileCheck(thing)
    local maxdist
    local check

    if bit32.band(thing.flags, p_mobj.MF_CORPSE) == 0 then
        return true -- not a monster
    end

    if thing.tics ~= -1 then
        return true -- not lying still yet
    end

    if thing.info.raisestate == 0 then -- S_NULL
        return true -- monster doesn't have a raise state
    end

    maxdist = thing.info.radius + info.mobjinfo[info.mobjtype.MT_VILE + 1].radius

    if math.abs(thing.x - viletryx) > maxdist
        or math.abs(thing.y - viletryy) > maxdist then
        return true -- not actually touching
    end

    corpsehit = thing
    corpsehit.momx = 0
    corpsehit.momy = 0
    corpsehit.height = doomtype.lshift32(corpsehit.height, 2) -- <<= 2
    check = p_map.P_CheckPosition(corpsehit, corpsehit.x, corpsehit.y)
    corpsehit.height = doomtype.rshift32(corpsehit.height, 2) -- >>= 2

    if not check then
        return true -- doesn't fit here
    end

    return false -- got one, so stop checking
end

-- ---------------------------------------------------------------------------
-- A_VileChase
-- Check for resurrecting a body.
-- ---------------------------------------------------------------------------

function p_enemy.A_VileChase(actor)
    local xl
    local xh
    local yl
    local yh
    local mobjinfo
    local temp

    if actor.movedir ~= p_enemy.DI_NODIR then
        -- check for corpses to raise
        viletryx = actor.x + actor.info.speed * xspeed[actor.movedir + 1]
        viletryy = actor.y + actor.info.speed * yspeed[actor.movedir + 1]

        xl = (viletryx - r_state.bmaporgx - MAXRADIUS * 2) // 2 ^ 23 -- >>MAPBLOCKSHIFT
        xh = (viletryx - r_state.bmaporgx + MAXRADIUS * 2) // 2 ^ 23
        yl = (viletryy - r_state.bmaporgy - MAXRADIUS * 2) // 2 ^ 23
        yh = (viletryy - r_state.bmaporgy + MAXRADIUS * 2) // 2 ^ 23

        p_enemy.vileobj = actor
        for bx = xl, xh do
            for by = yl, yh do
                -- Call PIT_VileCheck to check whether object is a corpse
                -- that can be raised.
                if not p_maputl.P_BlockThingsIterator(bx, by, PIT_VileCheck) then
                    -- got one!
                    temp = actor.target
                    actor.target = corpsehit
                    p_enemy.A_FaceTarget(actor)
                    actor.target = temp

                    p_mobj.P_SetMobjState(actor, info.statenum.S_VILE_HEAL1)
                    s_sound.S_StartSound(corpsehit, sounds.sfxenum.sfx_slop)
                    mobjinfo = corpsehit.info

                    p_mobj.P_SetMobjState(corpsehit, mobjinfo.raisestate)
                    corpsehit.height = doomtype.lshift32(corpsehit.height, 2)
                    corpsehit.flags = mobjinfo.flags
                    corpsehit.health = mobjinfo.spawnhealth
                    corpsehit.target = nil

                    return
                end
            end
        end
    end

    -- Return to normal attack.
    p_enemy.A_Chase(actor)
end

-- ---------------------------------------------------------------------------
-- A_VileStart
-- ---------------------------------------------------------------------------

function p_enemy.A_VileStart(actor)
    s_sound.S_StartSound(actor, sounds.sfxenum.sfx_vilatk)
end

-- ---------------------------------------------------------------------------
-- A_Fire / A_StartFire / A_FireCrackle
-- Keep fire in front of player unless out of sight.
-- ---------------------------------------------------------------------------

function p_enemy.A_Fire(actor)
    local dest
    local target
    local an

    dest = actor.tracer
    if not dest then
        return
    end

    target = p_mobj.P_SubstNullMobj(actor.target)

    -- don't move it if the vile lost sight
    if not p_sight.P_CheckSight(target, dest) then
        return
    end

    an = bit32.rshift(dest.angle, 19) -- ANGLETOFINESHIFT

    p_maputl.P_UnsetThingPosition(actor)
    actor.x = dest.x + m_fixed.FixedMul(24 * FRACUNIT,
        tables.finesine[an + 1 + 2048]) -- finecosine[an]
    actor.y = dest.y + m_fixed.FixedMul(24 * FRACUNIT,
        tables.finesine[an + 1])
    actor.z = dest.z
    p_maputl.P_SetThingPosition(actor)
end

function p_enemy.A_StartFire(actor)
    s_sound.S_StartSound(actor, sounds.sfxenum.sfx_flamst)
    p_enemy.A_Fire(actor)
end

function p_enemy.A_FireCrackle(actor)
    s_sound.S_StartSound(actor, sounds.sfxenum.sfx_flame)
    p_enemy.A_Fire(actor)
end

-- ---------------------------------------------------------------------------
-- A_VileTarget
-- Spawn the hellfire.
-- ---------------------------------------------------------------------------

function p_enemy.A_VileTarget(actor)
    local fog

    if not actor.target then
        return
    end

    p_enemy.A_FaceTarget(actor)

    fog = p_mobj.P_SpawnMobj(actor.target.x, actor.target.x,
        actor.target.z, info.mobjtype.MT_FIRE)

    actor.tracer = fog
    fog.target = actor
    fog.tracer = actor.target
    p_enemy.A_Fire(fog)
end

-- ---------------------------------------------------------------------------
-- A_VileAttack
-- ---------------------------------------------------------------------------

function p_enemy.A_VileAttack(actor)
    local fire
    local an

    if not actor.target then
        return
    end

    p_enemy.A_FaceTarget(actor)

    if not p_sight.P_CheckSight(actor, actor.target) then
        return
    end

    s_sound.S_StartSound(actor, sounds.sfxenum.sfx_barexp)
    p_inter.P_DamageMobj(actor.target, actor, actor, 20)
    actor.target.momz = doomtype.truncdiv(1000 * FRACUNIT,
        actor.target.info.mass)

    an = bit32.rshift(actor.angle, 19) -- ANGLETOFINESHIFT

    fire = actor.tracer

    if not fire then
        return
    end

    -- move the fire between the vile and the player
    fire.x = actor.target.x - m_fixed.FixedMul(24 * FRACUNIT,
        tables.finesine[an + 1 + 2048]) -- finecosine[an]
    fire.y = actor.target.y - m_fixed.FixedMul(24 * FRACUNIT,
        tables.finesine[an + 1])
    p_map.P_RadiusAttack(fire, actor, 70)
end

-- ---------------------------------------------------------------------------
-- A_FatRaise / A_FatAttack1/2/3
-- Mancubus attack, firing three missiles (bruisers) in three different
-- directions.
-- ---------------------------------------------------------------------------

function p_enemy.A_FatRaise(actor)
    p_enemy.A_FaceTarget(actor)
    s_sound.S_StartSound(actor, sounds.sfxenum.sfx_manatk)
end

function p_enemy.A_FatAttack1(actor)
    local mo
    local target
    local an

    p_enemy.A_FaceTarget(actor)

    -- Change direction to ...
    actor.angle = (actor.angle + FATSPREAD) % 0x100000000
    target = p_mobj.P_SubstNullMobj(actor.target)
    p_mobj.P_SpawnMissile(actor, target, info.mobjtype.MT_FATSHOT)

    mo = p_mobj.P_SpawnMissile(actor, target, info.mobjtype.MT_FATSHOT)
    mo.angle = (mo.angle + FATSPREAD) % 0x100000000
    an = bit32.rshift(mo.angle, 19) -- ANGLETOFINESHIFT
    mo.momx = m_fixed.FixedMul(mo.info.speed,
        tables.finesine[an + 1 + 2048]) -- finecosine[an]
    mo.momy = m_fixed.FixedMul(mo.info.speed,
        tables.finesine[an + 1])
end

function p_enemy.A_FatAttack2(actor)
    local mo
    local target
    local an

    p_enemy.A_FaceTarget(actor)
    -- Now here choose opposite deviation.
    actor.angle = (actor.angle - FATSPREAD) % 0x100000000
    target = p_mobj.P_SubstNullMobj(actor.target)
    p_mobj.P_SpawnMissile(actor, target, info.mobjtype.MT_FATSHOT)

    mo = p_mobj.P_SpawnMissile(actor, target, info.mobjtype.MT_FATSHOT)
    mo.angle = (mo.angle - FATSPREAD * 2) % 0x100000000
    an = bit32.rshift(mo.angle, 19) -- ANGLETOFINESHIFT
    mo.momx = m_fixed.FixedMul(mo.info.speed,
        tables.finesine[an + 1 + 2048]) -- finecosine[an]
    mo.momy = m_fixed.FixedMul(mo.info.speed,
        tables.finesine[an + 1])
end

function p_enemy.A_FatAttack3(actor)
    local mo
    local target
    local an

    p_enemy.A_FaceTarget(actor)

    target = p_mobj.P_SubstNullMobj(actor.target)

    mo = p_mobj.P_SpawnMissile(actor, target, info.mobjtype.MT_FATSHOT)
    mo.angle = (mo.angle - FATSPREAD // 2) % 0x100000000
    an = bit32.rshift(mo.angle, 19) -- ANGLETOFINESHIFT
    mo.momx = m_fixed.FixedMul(mo.info.speed,
        tables.finesine[an + 1 + 2048]) -- finecosine[an]
    mo.momy = m_fixed.FixedMul(mo.info.speed,
        tables.finesine[an + 1])

    mo = p_mobj.P_SpawnMissile(actor, target, info.mobjtype.MT_FATSHOT)
    mo.angle = (mo.angle + FATSPREAD // 2) % 0x100000000
    an = bit32.rshift(mo.angle, 19) -- ANGLETOFINESHIFT
    mo.momx = m_fixed.FixedMul(mo.info.speed,
        tables.finesine[an + 1 + 2048]) -- finecosine[an]
    mo.momy = m_fixed.FixedMul(mo.info.speed,
        tables.finesine[an + 1])
end

-- ---------------------------------------------------------------------------
-- A_SkullAttack
-- Fly at the player like a missile.
-- ---------------------------------------------------------------------------

function p_enemy.A_SkullAttack(actor)
    local dest
    local an
    local dist

    if not actor.target then
        return
    end

    dest = actor.target
    actor.flags = bit32.bor(actor.flags, p_mobj.MF_SKULLFLY)

    s_sound.S_StartSound(actor, actor.info.attacksound)
    p_enemy.A_FaceTarget(actor)
    an = bit32.rshift(actor.angle, 19) -- ANGLETOFINESHIFT
    actor.momx = m_fixed.FixedMul(SKULLSPEED,
        tables.finesine[an + 1 + 2048]) -- finecosine[an]
    actor.momy = m_fixed.FixedMul(SKULLSPEED,
        tables.finesine[an + 1])
    dist = p_maputl.P_AproxDistance(dest.x - actor.x, dest.y - actor.y)
    dist = doomtype.truncdiv(dist, SKULLSPEED)

    if dist < 1 then
        dist = 1
    end
    actor.momz = doomtype.truncdiv(
        dest.z + doomtype.rshift32(dest.height, 1) - actor.z, dist) -- height>>1
end

-- ---------------------------------------------------------------------------
-- A_PainShootSkull
-- Spawn a lost soul and launch it at the target.
-- ---------------------------------------------------------------------------

function p_enemy.A_PainShootSkull(actor, angle)
    local x
    local y
    local z
    local newmobj
    local an
    local prestep
    local count

    -- count total number of skulls currently on the level
    count = 0

    p_tick.iterateThinkers(function(currentthinker)
        if currentthinker.thinkfunc == p_mobj.P_MobjThinker
            and currentthinker.type == info.mobjtype.MT_SKULL then
            count = count + 1
        end
    end)

    -- if there are already 20 skulls on the level, don't spit another one
    if count > 20 then
        return
    end

    -- okay, there's playe for another one
    an = bit32.rshift(angle, 19) -- ANGLETOFINESHIFT

    prestep = 4 * FRACUNIT
        + 3 * (actor.info.radius + info.mobjinfo[info.mobjtype.MT_SKULL + 1].radius) // 2

    x = actor.x + m_fixed.FixedMul(prestep,
        tables.finesine[an + 1 + 2048]) -- finecosine[an]
    y = actor.y + m_fixed.FixedMul(prestep,
        tables.finesine[an + 1])
    z = actor.z + 8 * FRACUNIT

    newmobj = p_mobj.P_SpawnMobj(x, y, z, info.mobjtype.MT_SKULL)

    -- Check for movements.
    if not p_map.P_TryMove(newmobj, newmobj.x, newmobj.y) then
        -- kill it immediately
        p_inter.P_DamageMobj(newmobj, actor, actor, 10000)
        return
    end

    newmobj.target = actor.target
    p_enemy.A_SkullAttack(newmobj)
end

-- ---------------------------------------------------------------------------
-- A_PainAttack
-- Spawn a lost soul and launch it at the target.
-- ---------------------------------------------------------------------------

function p_enemy.A_PainAttack(actor)
    if not actor.target then
        return
    end

    p_enemy.A_FaceTarget(actor)
    p_enemy.A_PainShootSkull(actor, actor.angle)
end

-- ---------------------------------------------------------------------------
-- A_PainDie
-- ---------------------------------------------------------------------------

function p_enemy.A_PainDie(actor)
    p_enemy.A_Fall(actor)
    p_enemy.A_PainShootSkull(actor, (actor.angle + ANG90) % 0x100000000)
    p_enemy.A_PainShootSkull(actor, (actor.angle + ANG180) % 0x100000000)
    p_enemy.A_PainShootSkull(actor, (actor.angle + ANG270) % 0x100000000)
end

-- ---------------------------------------------------------------------------
-- A_Fall
-- Actor is on ground, it can be walked over.
-- ---------------------------------------------------------------------------

function p_enemy.A_Fall(actor)
    -- actor is on ground, it can be walked over
    actor.flags = bit32.band(actor.flags, bit32.bnot(p_mobj.MF_SOLID))

    -- So change this if corpse objects
    -- are meant to be obstacles.
end

-- ---------------------------------------------------------------------------
-- CheckBossEnd
-- Whether the death of the specified monster type is allowed to trigger the
-- end of episode special action. (This behavior changed in v1.9.)
-- ---------------------------------------------------------------------------

local function CheckBossEnd(motype)
    if doomstat.gameversion < d_mode.exe_ultimate then
        if doomstat.gamemap ~= 8 then
            return false
        end

        -- Baron death on later episodes is nothing special.
        if motype == info.mobjtype.MT_BRUISER and doomstat.gameepisode ~= 1 then
            return false
        end

        return true
    else
        -- New logic that appeared in Ultimate Doom.
        local ep = doomstat.gameepisode
        local map = doomstat.gamemap
        if ep == 1 then
            return map == 8 and motype == info.mobjtype.MT_BRUISER
        elseif ep == 2 then
            return map == 8 and motype == info.mobjtype.MT_CYBORG
        elseif ep == 3 then
            return map == 8 and motype == info.mobjtype.MT_SPIDER
        elseif ep == 4 then
            return (map == 6 and motype == info.mobjtype.MT_CYBORG)
                or (map == 8 and motype == info.mobjtype.MT_SPIDER)
        else
            return map == 8
        end
    end
end

-- ---------------------------------------------------------------------------
-- A_BossDeath
-- Possibly trigger special effects if on first boss level.
-- ---------------------------------------------------------------------------

function p_enemy.A_BossDeath(mo)
    local mo2
    local junk

    if doomstat.gamemode == d_mode.commercial then
        if doomstat.gamemap ~= 7 then
            return
        end

        if mo.type ~= info.mobjtype.MT_FATSO
            and mo.type ~= info.mobjtype.MT_BABY then
            return
        end
    else
        if not CheckBossEnd(mo.type) then
            return
        end
    end

    -- make sure there is a player alive for victory
    local playerAlive = false
    for i = 0, doomtype.MAXPLAYERS - 1 do
        if doomstat.playeringame[i + 1] and doomstat.players[i + 1].health > 0 then
            playerAlive = true
            break
        end
    end

    if not playerAlive then
        return -- no one left alive, so do not end game
    end

    -- scan the remaining thinkers to see if all bosses are dead
    local otherBoss = false
    p_tick.iterateThinkers(function(th)
        if th.thinkfunc ~= p_mobj.P_MobjThinker then
            return
        end
        mo2 = th
        if mo2 ~= mo and mo2.type == mo.type and mo2.health > 0 then
            -- other boss not dead
            otherBoss = true
        end
    end)

    if otherBoss then
        return
    end

    -- victory!
    if doomstat.gamemode == d_mode.commercial then
        if doomstat.gamemap == 7 then
            if mo.type == info.mobjtype.MT_FATSO then
                junk = { tag = 666 }
                p_floor.EV_DoFloor(junk, p_floor.lowerFloorToLowest)
                return
            end

            if mo.type == info.mobjtype.MT_BABY then
                junk = { tag = 667 }
                p_floor.EV_DoFloor(junk, p_floor.raiseToTexture)
                return
            end
        end
    else
        if doomstat.gameepisode == 1 then
            junk = { tag = 666 }
            p_floor.EV_DoFloor(junk, p_floor.lowerFloorToLowest)
            return
        elseif doomstat.gameepisode == 4 then
            if doomstat.gamemap == 6 then
                junk = { tag = 666 }
                p_doors.EV_DoDoor(junk, p_doors.vld_blazeOpen)
                return
            elseif doomstat.gamemap == 8 then
                junk = { tag = 666 }
                p_floor.EV_DoFloor(junk, p_floor.lowerFloorToLowest)
                return
            end
        end
    end

    g_game.G_ExitLevel()
end

-- ---------------------------------------------------------------------------
-- A_Hoof / A_Metal / A_BabyMetal
-- ---------------------------------------------------------------------------

function p_enemy.A_Hoof(mo)
    s_sound.S_StartSound(mo, sounds.sfxenum.sfx_hoof)
    p_enemy.A_Chase(mo)
end

function p_enemy.A_Metal(mo)
    s_sound.S_StartSound(mo, sounds.sfxenum.sfx_metal)
    p_enemy.A_Chase(mo)
end

function p_enemy.A_BabyMetal(mo)
    s_sound.S_StartSound(mo, sounds.sfxenum.sfx_bspwlk)
    p_enemy.A_Chase(mo)
end

-- ---------------------------------------------------------------------------
-- Boss Brain functions
-- ---------------------------------------------------------------------------

p_enemy.braintargets = {}
for _ = 1, 32 do
    table.insert(p_enemy.braintargets, nil)
end
p_enemy.numbraintargets = 0
p_enemy.braintargeton = 0

function p_enemy.A_BrainAwake(mo)
    local m

    -- find all the target spots
    p_enemy.numbraintargets = 0
    p_enemy.braintargeton = 0

    p_tick.iterateThinkers(function(thinker)
        if thinker.thinkfunc ~= p_mobj.P_MobjThinker then
            return -- not a mobj
        end

        m = thinker

        if m.type == info.mobjtype.MT_BOSSTARGET then
            p_enemy.braintargets[p_enemy.numbraintargets + 1] = m
            p_enemy.numbraintargets = p_enemy.numbraintargets + 1
        end
    end)

    s_sound.S_StartSound(nil, sounds.sfxenum.sfx_bossit)
end

function p_enemy.A_BrainPain(mo)
    s_sound.S_StartSound(nil, sounds.sfxenum.sfx_bospn)
end

function p_enemy.A_BrainScream(mo)
    local x
    local y
    local z
    local th

    x = mo.x - 196 * FRACUNIT
    while x < mo.x + 320 * FRACUNIT do
        y = mo.y - 320 * FRACUNIT
        z = 128 + m_random.P_Random() * 2 * FRACUNIT
        th = p_mobj.P_SpawnMobj(x, y, z, info.mobjtype.MT_ROCKET)
        th.momz = m_random.P_Random() * 512

        p_mobj.P_SetMobjState(th, info.statenum.S_BRAINEXPLODE1)

        th.tics = th.tics - bit32.band(m_random.P_Random(), 7) -- &7
        if th.tics < 1 then
            th.tics = 1
        end

        x = x + FRACUNIT * 8
    end

    s_sound.S_StartSound(nil, sounds.sfxenum.sfx_bosdth)
end

function p_enemy.A_BrainExplode(mo)
    local x
    local y
    local z
    local th

    x = mo.x + (m_random.P_Random() - m_random.P_Random()) * 2048
    y = mo.y
    z = 128 + m_random.P_Random() * 2 * FRACUNIT
    th = p_mobj.P_SpawnMobj(x, y, z, info.mobjtype.MT_ROCKET)
    th.momz = m_random.P_Random() * 512

    p_mobj.P_SetMobjState(th, info.statenum.S_BRAINEXPLODE1)

    th.tics = th.tics - bit32.band(m_random.P_Random(), 7) -- &7
    if th.tics < 1 then
        th.tics = 1
    end
end

function p_enemy.A_BrainDie(mo)
    g_game.G_ExitLevel()
end

-- C static int easy in A_BrainSpit: toggles each call, persists across calls.
local brain_easy = 0

function p_enemy.A_BrainSpit(mo)
    local targ
    local newmobj

    brain_easy = bit32.bxor(brain_easy, 1)

    if doomstat.gameskill <= d_mode.sk_easy and brain_easy == 0 then
        return
    end

    -- shoot a cube at current target
    targ = p_enemy.braintargets[p_enemy.braintargeton + 1]
    p_enemy.braintargeton = (p_enemy.braintargeton + 1) % p_enemy.numbraintargets

    -- spawn brain missile
    newmobj = p_mobj.P_SpawnMissile(mo, targ, info.mobjtype.MT_SPAWNSHOT)
    newmobj.target = targ
    newmobj.reactiontime = doomtype.truncdiv(
        doomtype.truncdiv(targ.y - mo.y, newmobj.momy), newmobj.state.tics)

    s_sound.S_StartSound(nil, sounds.sfxenum.sfx_bospit)
end

-- ---------------------------------------------------------------------------
-- A_SpawnSound / A_SpawnFly
-- ---------------------------------------------------------------------------

function p_enemy.A_SpawnSound(mo)
    s_sound.S_StartSound(mo, sounds.sfxenum.sfx_boscub)
    p_enemy.A_SpawnFly(mo)
end

function p_enemy.A_SpawnFly(mo)
    local newmobj
    local fog
    local targ
    local r
    local type

    mo.reactiontime = mo.reactiontime - 1
    if mo.reactiontime ~= 0 then
        return -- still flying
    end

    targ = p_mobj.P_SubstNullMobj(mo.target)

    -- First spawn teleport fog.
    fog = p_mobj.P_SpawnMobj(targ.x, targ.y, targ.z, info.mobjtype.MT_SPAWNFIRE)
    s_sound.S_StartSound(fog, sounds.sfxenum.sfx_telept)

    -- Randomly select monster to spawn.
    r = m_random.P_Random()

    -- Probability distribution (kind of :), decreasing likelihood.
    if r < 50 then
        type = info.mobjtype.MT_TROOP
    elseif r < 90 then
        type = info.mobjtype.MT_SERGEANT
    elseif r < 120 then
        type = info.mobjtype.MT_SHADOWS
    elseif r < 130 then
        type = info.mobjtype.MT_PAIN
    elseif r < 160 then
        type = info.mobjtype.MT_HEAD
    elseif r < 162 then
        type = info.mobjtype.MT_VILE
    elseif r < 172 then
        type = info.mobjtype.MT_UNDEAD
    elseif r < 192 then
        type = info.mobjtype.MT_BABY
    elseif r < 222 then
        type = info.mobjtype.MT_FATSO
    elseif r < 246 then
        type = info.mobjtype.MT_KNIGHT
    else
        type = info.mobjtype.MT_BRUISER
    end

    newmobj = p_mobj.P_SpawnMobj(targ.x, targ.y, targ.z, type)
    if p_enemy.P_LookForPlayers(newmobj, true) then
        p_mobj.P_SetMobjState(newmobj, newmobj.info.seestate)
    end

    -- telefrag anything in this spot
    p_map.P_TeleportMove(newmobj, newmobj.x, newmobj.y)

    -- remove self (i.e., cube).
    p_mobj.P_RemoveMobj(mo)
end

-- ---------------------------------------------------------------------------
-- Register the monster AI actions into p_mobj's action registry.
-- ---------------------------------------------------------------------------

p_mobj.registerMobjAction("A_Look", p_enemy.A_Look)
p_mobj.registerMobjAction("A_Chase", p_enemy.A_Chase)
p_mobj.registerMobjAction("A_FaceTarget", p_enemy.A_FaceTarget)
p_mobj.registerMobjAction("A_PosAttack", p_enemy.A_PosAttack)
p_mobj.registerMobjAction("A_SPosAttack", p_enemy.A_SPosAttack)
p_mobj.registerMobjAction("A_CPosAttack", p_enemy.A_CPosAttack)
p_mobj.registerMobjAction("A_CPosRefire", p_enemy.A_CPosRefire)
p_mobj.registerMobjAction("A_SpidRefire", p_enemy.A_SpidRefire)
p_mobj.registerMobjAction("A_BspiAttack", p_enemy.A_BspiAttack)
p_mobj.registerMobjAction("A_TroopAttack", p_enemy.A_TroopAttack)
p_mobj.registerMobjAction("A_SargAttack", p_enemy.A_SargAttack)
p_mobj.registerMobjAction("A_HeadAttack", p_enemy.A_HeadAttack)
p_mobj.registerMobjAction("A_CyberAttack", p_enemy.A_CyberAttack)
p_mobj.registerMobjAction("A_BruisAttack", p_enemy.A_BruisAttack)
p_mobj.registerMobjAction("A_SkelMissile", p_enemy.A_SkelMissile)
p_mobj.registerMobjAction("A_Tracer", p_enemy.A_Tracer)
p_mobj.registerMobjAction("A_SkelWhoosh", p_enemy.A_SkelWhoosh)
p_mobj.registerMobjAction("A_SkelFist", p_enemy.A_SkelFist)
p_mobj.registerMobjAction("A_VileChase", p_enemy.A_VileChase)
p_mobj.registerMobjAction("A_VileStart", p_enemy.A_VileStart)
p_mobj.registerMobjAction("A_Fire", p_enemy.A_Fire)
p_mobj.registerMobjAction("A_StartFire", p_enemy.A_StartFire)
p_mobj.registerMobjAction("A_FireCrackle", p_enemy.A_FireCrackle)
p_mobj.registerMobjAction("A_VileTarget", p_enemy.A_VileTarget)
p_mobj.registerMobjAction("A_VileAttack", p_enemy.A_VileAttack)
p_mobj.registerMobjAction("A_FatRaise", p_enemy.A_FatRaise)
p_mobj.registerMobjAction("A_FatAttack1", p_enemy.A_FatAttack1)
p_mobj.registerMobjAction("A_FatAttack2", p_enemy.A_FatAttack2)
p_mobj.registerMobjAction("A_FatAttack3", p_enemy.A_FatAttack3)
p_mobj.registerMobjAction("A_SkullAttack", p_enemy.A_SkullAttack)
p_mobj.registerMobjAction("A_PainAttack", p_enemy.A_PainAttack)
p_mobj.registerMobjAction("A_PainDie", p_enemy.A_PainDie)
p_mobj.registerMobjAction("A_BossDeath", p_enemy.A_BossDeath)
p_mobj.registerMobjAction("A_Hoof", p_enemy.A_Hoof)
p_mobj.registerMobjAction("A_Metal", p_enemy.A_Metal)
p_mobj.registerMobjAction("A_BabyMetal", p_enemy.A_BabyMetal)
p_mobj.registerMobjAction("A_KeenDie", p_enemy.A_KeenDie)
p_mobj.registerMobjAction("A_BrainAwake", p_enemy.A_BrainAwake)
p_mobj.registerMobjAction("A_BrainPain", p_enemy.A_BrainPain)
p_mobj.registerMobjAction("A_BrainScream", p_enemy.A_BrainScream)
p_mobj.registerMobjAction("A_BrainExplode", p_enemy.A_BrainExplode)
p_mobj.registerMobjAction("A_BrainDie", p_enemy.A_BrainDie)
p_mobj.registerMobjAction("A_BrainSpit", p_enemy.A_BrainSpit)
p_mobj.registerMobjAction("A_SpawnSound", p_enemy.A_SpawnSound)
p_mobj.registerMobjAction("A_SpawnFly", p_enemy.A_SpawnFly)

return p_enemy
end)()

p_floor = (function()
local p_floor = {}

local FRACUNIT = m_fixed.FRACUNIT
local FLOORSPEED = FRACUNIT

local INT_MAX = 2147483647

-- floor_e (p_spec.h).
p_floor.lowerFloor = 0
p_floor.lowerFloorToLowest = 1
p_floor.turboLower = 2
p_floor.raiseFloor = 3
p_floor.raiseFloorToNearest = 4
p_floor.raiseToTexture = 5
p_floor.lowerAndChange = 6
p_floor.raiseFloor24 = 7
p_floor.raiseFloor24AndChange = 8
p_floor.raiseFloorCrush = 9
p_floor.raiseFloorTurbo = 10
p_floor.donutRaise = 11
p_floor.raiseFloor512 = 12

-- stair_e (p_spec.h).
p_floor.build8 = 0
p_floor.turbo16 = 1

-- result_e (p_spec.h).
p_floor.ok = 0
p_floor.crushed = 1
p_floor.pastdest = 2

-- ---------------------------------------------------------------------------
-- T_MovePlane
-- Move a plane (floor or ceiling) and check for crushing.
-- ---------------------------------------------------------------------------

function p_floor.T_MovePlane(sector, speed, dest, crush, floorOrCeiling, direction)
    local flag
    local lastpos

    if floorOrCeiling == 0 then
        -- FLOOR
        if direction == -1 then
            -- DOWN
            if sector.floorheight - speed < dest then
                lastpos = sector.floorheight
                sector.floorheight = dest
                flag = p_map.P_ChangeSector(sector, crush)
                if flag == true then
                    sector.floorheight = lastpos
                    p_map.P_ChangeSector(sector, crush)
                    -- return crushed;
                end
                return p_floor.pastdest
            end
            -- COULD GET CRUSHED
            lastpos = sector.floorheight
            sector.floorheight = sector.floorheight - speed
            flag = p_map.P_ChangeSector(sector, crush)
            if flag == true then
                sector.floorheight = lastpos
                p_map.P_ChangeSector(sector, crush)
                return p_floor.crushed
            end
        elseif direction == 1 then
            -- UP
            if sector.floorheight + speed > dest then
                lastpos = sector.floorheight
                sector.floorheight = dest
                flag = p_map.P_ChangeSector(sector, crush)
                if flag == true then
                    sector.floorheight = lastpos
                    p_map.P_ChangeSector(sector, crush)
                    -- return crushed;
                end
                return p_floor.pastdest
            end
            -- COULD GET CRUSHED
            lastpos = sector.floorheight
            sector.floorheight = sector.floorheight + speed
            flag = p_map.P_ChangeSector(sector, crush)
            if flag == true then
                if crush == true then
                    return p_floor.crushed
                end
                sector.floorheight = lastpos
                p_map.P_ChangeSector(sector, crush)
                return p_floor.crushed
            end
        end
    elseif floorOrCeiling == 1 then
        -- CEILING
        if direction == -1 then
            -- DOWN
            if sector.ceilingheight - speed < dest then
                lastpos = sector.ceilingheight
                sector.ceilingheight = dest
                flag = p_map.P_ChangeSector(sector, crush)
                if flag == true then
                    sector.ceilingheight = lastpos
                    p_map.P_ChangeSector(sector, crush)
                    -- return crushed;
                end
                return p_floor.pastdest
            end
            -- COULD GET CRUSHED
            lastpos = sector.ceilingheight
            sector.ceilingheight = sector.ceilingheight - speed
            flag = p_map.P_ChangeSector(sector, crush)
            if flag == true then
                if crush == true then
                    return p_floor.crushed
                end
                sector.ceilingheight = lastpos
                p_map.P_ChangeSector(sector, crush)
                return p_floor.crushed
            end
        elseif direction == 1 then
            -- UP
            if sector.ceilingheight + speed > dest then
                lastpos = sector.ceilingheight
                sector.ceilingheight = dest
                flag = p_map.P_ChangeSector(sector, crush)
                if flag == true then
                    sector.ceilingheight = lastpos
                    p_map.P_ChangeSector(sector, crush)
                    -- return crushed;
                end
                return p_floor.pastdest
            end
            lastpos = sector.ceilingheight
            sector.ceilingheight = sector.ceilingheight + speed
            flag = p_map.P_ChangeSector(sector, crush)
            -- UNUSED block omitted
        end
    end
    return p_floor.ok
end

-- ---------------------------------------------------------------------------
-- T_MoveFloor
-- Move a floor to its destination (up or down).
-- ---------------------------------------------------------------------------

function p_floor.T_MoveFloor(floor)
    local res

    res = p_floor.T_MovePlane(floor.sector, floor.speed, floor.floordestheight,
        floor.crush, 0, floor.direction)

    if bit32.band(doomstat.leveltime, 7) == 0 then
        s_sound.S_StartSound(floor.sector.soundorg, sounds.sfxenum.sfx_stnmov)
    end

    if res == p_floor.pastdest then
        floor.sector.specialdata = nil

        if floor.direction == 1 then
            if floor.type == p_floor.donutRaise then
                floor.sector.special = floor.newspecial
                floor.sector.floorpic = floor.texture
            end
        elseif floor.direction == -1 then
            if floor.type == p_floor.lowerAndChange then
                floor.sector.special = floor.newspecial
                floor.sector.floorpic = floor.texture
            end
        end
        p_tick.P_RemoveThinker(floor)

        s_sound.S_StartSound(floor.sector.soundorg, sounds.sfxenum.sfx_pstop)
    end
end

-- ---------------------------------------------------------------------------
-- EV_DoFloor
-- ---------------------------------------------------------------------------

function p_floor.EV_DoFloor(line, floortype)
    local secnum
    local rtn
    local sec
    local floor

    secnum = -1
    rtn = 0
    while true do
        secnum = p_spec.P_FindSectorFromLineTag(line, secnum)
        if secnum < 0 then
            break
        end

        sec = r_state.sectors[secnum + 1]

        -- ALREADY MOVING?  IF SO, KEEP GOING...
        if sec.specialdata then
            -- continue
        else
            -- new floor thinker
            rtn = 1
            floor = {}
            p_tick.P_AddThinker(floor)
            sec.specialdata = floor
            floor.thinkfunc = p_floor.T_MoveFloor
            floor.type = floortype
            floor.crush = false

            if floortype == p_floor.lowerFloor then
                floor.direction = -1
                floor.sector = sec
                floor.speed = FLOORSPEED
                floor.floordestheight = p_spec.P_FindHighestFloorSurrounding(sec)
            elseif floortype == p_floor.lowerFloorToLowest then
                floor.direction = -1
                floor.sector = sec
                floor.speed = FLOORSPEED
                floor.floordestheight = p_spec.P_FindLowestFloorSurrounding(sec)
            elseif floortype == p_floor.turboLower then
                floor.direction = -1
                floor.sector = sec
                floor.speed = FLOORSPEED * 4
                floor.floordestheight = p_spec.P_FindHighestFloorSurrounding(sec)
                if floor.floordestheight ~= sec.floorheight then
                    floor.floordestheight = floor.floordestheight + 8 * FRACUNIT
                end
            elseif floortype == p_floor.raiseFloorCrush then
                floor.crush = true
                floor.direction = 1
                floor.sector = sec
                floor.speed = FLOORSPEED
                floor.floordestheight = p_spec.P_FindLowestCeilingSurrounding(sec)
                if floor.floordestheight > sec.ceilingheight then
                    floor.floordestheight = sec.ceilingheight
                end
                floor.floordestheight = floor.floordestheight - 8 * FRACUNIT
            elseif floortype == p_floor.raiseFloor then
                floor.direction = 1
                floor.sector = sec
                floor.speed = FLOORSPEED
                floor.floordestheight = p_spec.P_FindLowestCeilingSurrounding(sec)
                if floor.floordestheight > sec.ceilingheight then
                    floor.floordestheight = sec.ceilingheight
                end
            elseif floortype == p_floor.raiseFloorTurbo then
                floor.direction = 1
                floor.sector = sec
                floor.speed = FLOORSPEED * 4
                floor.floordestheight = p_spec.P_FindNextHighestFloor(sec, sec.floorheight)
            elseif floortype == p_floor.raiseFloorToNearest then
                floor.direction = 1
                floor.sector = sec
                floor.speed = FLOORSPEED
                floor.floordestheight = p_spec.P_FindNextHighestFloor(sec, sec.floorheight)
            elseif floortype == p_floor.raiseFloor24 then
                floor.direction = 1
                floor.sector = sec
                floor.speed = FLOORSPEED
                floor.floordestheight = floor.sector.floorheight + 24 * FRACUNIT
            elseif floortype == p_floor.raiseFloor512 then
                floor.direction = 1
                floor.sector = sec
                floor.speed = FLOORSPEED
                floor.floordestheight = floor.sector.floorheight + 512 * FRACUNIT
            elseif floortype == p_floor.raiseFloor24AndChange then
                floor.direction = 1
                floor.sector = sec
                floor.speed = FLOORSPEED
                floor.floordestheight = floor.sector.floorheight + 24 * FRACUNIT
                sec.floorpic = line.frontsector.floorpic
                sec.special = line.frontsector.special
            elseif floortype == p_floor.raiseToTexture then
                local minsize = INT_MAX
                local side

                floor.direction = 1
                floor.sector = sec
                floor.speed = FLOORSPEED
                for i = 0, sec.linecount - 1 do
                    if p_spec.twoSided(secnum, i) then
                        side = p_spec.getSide(secnum, i, 0)
                        if side.bottomtexture >= 0
                            and r_state.textureheight[side.bottomtexture + 1] < minsize then
                            minsize = r_state.textureheight[side.bottomtexture + 1]
                        end
                        side = p_spec.getSide(secnum, i, 1)
                        if side.bottomtexture >= 0
                            and r_state.textureheight[side.bottomtexture + 1] < minsize then
                            minsize = r_state.textureheight[side.bottomtexture + 1]
                        end
                    end
                end
                floor.floordestheight = doomtype.u32_to_s32(
                    -- (floor.sector.floorheight + minsize) % 0x100000000)
                    (floor.sector.floorheight + minsize))
            elseif floortype == p_floor.lowerAndChange then
                floor.direction = -1
                floor.sector = sec
                floor.speed = FLOORSPEED
                floor.floordestheight = p_spec.P_FindLowestFloorSurrounding(sec)
                floor.texture = sec.floorpic

                -- The C loop is `for (i = 0; i < sec->linecount; i++)` and
                -- reassigns `sec` inside, so the bound is re-read each
                -- iteration; use a while loop to match.
                local i = 0
                while i < sec.linecount do
                    if p_spec.twoSided(secnum, i) then
                        if p_spec.getSide(secnum, i, 0).sector.index == secnum then
                            sec = p_spec.getSector(secnum, i, 1)
                            if sec.floorheight == floor.floordestheight then
                                floor.texture = sec.floorpic
                                floor.newspecial = sec.special
                                break
                            end
                        else
                            sec = p_spec.getSector(secnum, i, 0)
                            if sec.floorheight == floor.floordestheight then
                                floor.texture = sec.floorpic
                                floor.newspecial = sec.special
                                break
                            end
                        end
                    end
                    i = i + 1
                end
            end
        end
    end
    return rtn
end

-- ---------------------------------------------------------------------------
-- EV_BuildStairs
-- Build a staircase!
-- ---------------------------------------------------------------------------

function p_floor.EV_BuildStairs(line, type)
    local secnum
    local height
    local newsecnum
    local texture
    local ok
    local rtn

    local sec
    local tsec

    local floor

    local stairsize = 0
    local speed = 0

    secnum = -1
    rtn = 0
    while true do
        secnum = p_spec.P_FindSectorFromLineTag(line, secnum)
        if secnum < 0 then
            break
        end

        sec = r_state.sectors[secnum + 1]

        -- ALREADY MOVING?  IF SO, KEEP GOING...
        if sec.specialdata then
            -- continue
        else
            -- new floor thinker
            rtn = 1
            floor = {}
            p_tick.P_AddThinker(floor)
            sec.specialdata = floor
            floor.thinkfunc = p_floor.T_MoveFloor
            floor.direction = 1
            floor.sector = sec
            if type == p_floor.build8 then
                speed = FLOORSPEED // 4
                stairsize = 8 * FRACUNIT
            elseif type == p_floor.turbo16 then
                speed = FLOORSPEED * 4
                stairsize = 16 * FRACUNIT
            end
            floor.speed = speed
            height = sec.floorheight + stairsize
            floor.floordestheight = height

            texture = sec.floorpic

            -- Find next sector to raise
            -- 1. Find 2-sided line with same sector side[0]
            -- 2. Other side is the next sector to raise
            repeat
                ok = 0
                for i = 0, sec.linecount - 1 do
                    if bit32.band(sec.lines[i + 1].flags, 4) == 0 then -- ML_TWOSIDED
                        -- continue
                    else
                        tsec = sec.lines[i + 1].frontsector
                        newsecnum = tsec.index

                        if secnum == newsecnum then
                            tsec = sec.lines[i + 1].backsector
                            newsecnum = tsec.index

                            if tsec.floorpic == texture then
                                height = height + stairsize

                                if not tsec.specialdata then
                                    sec = tsec
                                    secnum = newsecnum
                                    floor = {}
                                    p_tick.P_AddThinker(floor)

                                    sec.specialdata = floor
                                    floor.thinkfunc = p_floor.T_MoveFloor
                                    floor.direction = 1
                                    floor.sector = sec
                                    floor.speed = speed
                                    floor.floordestheight = height
                                    ok = 1
                                    break
                                end
                            end
                        end
                    end
                end
            until ok == 0
        end
    end
    return rtn
end

return p_floor
end)()

p_inter = (function()
local p_inter = {}

-- The GOT* strings (d_englsh.h), used by P_TouchSpecialThing.
local got = {
    GOTARMOR = "Picked up the armor.",
    GOTMEGA = "Picked up the MegaArmor!",
    GOTHTHBONUS = "Picked up a health bonus.",
    GOTARMBONUS = "Picked up an armor bonus.",
    GOTSTIM = "Picked up a stimpack.",
    GOTMEDINEED = "Picked up a medikit that you REALLY need!",
    GOTMEDIKIT = "Picked up a medikit.",
    GOTSUPER = "Supercharge!",
    GOTBLUECARD = "Picked up a blue keycard.",
    GOTYELWCARD = "Picked up a yellow keycard.",
    GOTREDCARD = "Picked up a red keycard.",
    GOTBLUESKUL = "Picked up a blue skull key.",
    GOTYELWSKUL = "Picked up a yellow skull key.",
    GOTREDSKULL = "Picked up a red skull key.",
    GOTINVUL = "Invulnerability!",
    GOTBERSERK = "Berserk!",
    GOTINVIS = "Partial Invisibility",
    GOTSUIT = "Radiation Shielding Suit",
    GOTMAP = "Computer Area Map",
    GOTVISOR = "Light Amplification Visor",
    GOTMSPHERE = "MegaSphere!",
    GOTCLIP = "Picked up a clip.",
    GOTCLIPBOX = "Picked up a box of bullets.",
    GOTROCKET = "Picked up a rocket.",
    GOTROCKBOX = "Picked up a box of rockets.",
    GOTCELL = "Picked up an energy cell.",
    GOTCELLBOX = "Picked up an energy cell pack.",
    GOTSHELLS = "Picked up 4 shotgun shells.",
    GOTSHELLBOX = "Picked up a box of shotgun shells.",
    GOTBACKPACK = "Picked up a backpack full of ammo!",
    GOTBFG9000 = "You got the BFG9000!  Oh, yes.",
    GOTCHAINGUN = "You got the chaingun!",
    GOTCHAINSAW = "A chainsaw!  Find some meat!",
    GOTLAUNCHER = "You got the rocket launcher!",
    GOTPLASMA = "You got the plasma gun!",
    GOTSHOTGUN = "You got the shotgun!",
    GOTSHOTGUN2 = "You got the super shotgun!",
}

local BONUSADD = 6
local MAXHEALTH = 100

-- A weapon is found with two clip loads, a big item has five clip loads.
p_inter.maxammo = { 200, 50, 300, 50 }
p_inter.clipammo = { 10, 4, 20, 1 }

-- ---------------------------------------------------------------------------
-- P_GiveAmmo
-- Num is the number of clip loads, not the individual count (0 = 1/2 clip).
-- Returns false if the ammo can't be picked up at all.
-- ---------------------------------------------------------------------------

function p_inter.P_GiveAmmo(player, ammo, num)
    local oldammo

    if ammo == doomdef.am_noammo then
        return false
    end

    if ammo > doomdef.NUMAMMO then
        i_system.I_Error("P_GiveAmmo: bad type %i", ammo)
    end

    -- Lua arrays are 1-based: C ammo[ammo] is player.ammo[ammo+1].
    if player.ammo[ammo + 1] == player.maxammo[ammo + 1] then
        return false
    end

    if num ~= 0 then
        num = num * p_inter.clipammo[ammo + 1]
    else
        num = p_inter.clipammo[ammo + 1] // 2
    end

    if doomstat.gameskill == 0 -- sk_baby
        or doomstat.gameskill == 4 then -- sk_nightmare
        -- give double ammo in trainer mode, you'll need in nightmare
        num = num * 2 -- num <<= 1
    end

    oldammo = player.ammo[ammo + 1]
    player.ammo[ammo + 1] = player.ammo[ammo + 1] + num

    if player.ammo[ammo + 1] > player.maxammo[ammo + 1] then
        player.ammo[ammo + 1] = player.maxammo[ammo + 1]
    end

    -- If non zero ammo, don't change up weapons,
    -- player was lower on purpose.
    if oldammo ~= 0 then
        return true
    end

    -- We were down to zero, so select a new weapon.
    -- Preferences are not user selectable.
    if ammo == doomdef.am_clip then
        if player.readyweapon == doomdef.wp_fist then
            if player.weaponowned[doomdef.wp_chaingun + 1] then
                player.pendingweapon = doomdef.wp_chaingun
            else
                player.pendingweapon = doomdef.wp_pistol
            end
        end
    elseif ammo == doomdef.am_shell then
        if player.readyweapon == doomdef.wp_fist
            or player.readyweapon == doomdef.wp_pistol then
            if player.weaponowned[doomdef.wp_shotgun + 1] then
                player.pendingweapon = doomdef.wp_shotgun
            end
        end
    elseif ammo == doomdef.am_cell then
        if player.readyweapon == doomdef.wp_fist
            or player.readyweapon == doomdef.wp_pistol then
            if player.weaponowned[doomdef.wp_plasma + 1] then
                player.pendingweapon = doomdef.wp_plasma
            end
        end
    elseif ammo == doomdef.am_misl then
        if player.readyweapon == doomdef.wp_fist then
            if player.weaponowned[doomdef.wp_missile + 1] then
                player.pendingweapon = doomdef.wp_missile
            end
        end
        -- default: break
    end

    return true
end

-- ---------------------------------------------------------------------------
-- P_GiveWeapon
-- The weapon name may have a MF_DROPPED flag ored in.
-- ---------------------------------------------------------------------------

function p_inter.P_GiveWeapon(player, weapon, dropped)
    local gaveammo
    local gaveweapon
    local weaponinfo = d_items.weaponinfo

    -- netgame with deathmatch!=2: leave placed weapons forever.
    -- (Multiplayer is cut in v1, so this branch never runs; kept for parity.)
    if doomstat.netgame and doomstat.deathmatch ~= 2 and not dropped then
        if player.weaponowned[weapon + 1] then
            return false
        end

        player.bonuscount = player.bonuscount + BONUSADD
        player.weaponowned[weapon + 1] = true

        if doomstat.deathmatch ~= 0 then
            p_inter.P_GiveAmmo(player, weaponinfo[weapon + 1].ammo, 5)
        else
            p_inter.P_GiveAmmo(player, weaponinfo[weapon + 1].ammo, 2)
        end
        player.pendingweapon = weapon

        if player == doomstat.players[doomstat.consoleplayer + 1] then
            s_sound.S_StartSound(nil, sounds.sfxenum.sfx_wpnup)
        end
        return false
    end

    if weaponinfo[weapon + 1].ammo ~= doomdef.am_noammo then
        -- give one clip with a dropped weapon,
        -- two clips with a found weapon
        if dropped then
            gaveammo = p_inter.P_GiveAmmo(player, weaponinfo[weapon + 1].ammo, 1)
        else
            gaveammo = p_inter.P_GiveAmmo(player, weaponinfo[weapon + 1].ammo, 2)
        end
    else
        gaveammo = false
    end

    if player.weaponowned[weapon + 1] then
        gaveweapon = false
    else
        gaveweapon = true
        player.weaponowned[weapon + 1] = true
        player.pendingweapon = weapon
    end

    return gaveweapon or gaveammo
end

-- ---------------------------------------------------------------------------
-- P_GiveBody
-- Returns false if the body isn't needed at all.
-- ---------------------------------------------------------------------------

function p_inter.P_GiveBody(player, num)
    if player.health >= MAXHEALTH then
        return false
    end

    player.health = player.health + num
    if player.health > MAXHEALTH then
        player.health = MAXHEALTH
    end
    if player.mo then
        player.mo.health = player.health
    end

    return true
end

-- ---------------------------------------------------------------------------
-- P_GiveArmor
-- Returns false if the armor is worse than the current armor.
-- ---------------------------------------------------------------------------

function p_inter.P_GiveArmor(player, armortype)
    local hits

    hits = armortype * 100
    if player.armorpoints >= hits then
        return false -- don't pick up
    end

    player.armortype = armortype
    player.armorpoints = hits

    return true
end

-- ---------------------------------------------------------------------------
-- P_GiveCard
-- ---------------------------------------------------------------------------

function p_inter.P_GiveCard(player, card)
    if player.cards[card + 1] then
        return
    end

    player.bonuscount = BONUSADD
    player.cards[card + 1] = true
end

-- ---------------------------------------------------------------------------
-- P_GivePower
-- ---------------------------------------------------------------------------

function p_inter.P_GivePower(player, power)
    if power == doomdef.pw_invulnerability then
        player.powers[power + 1] = doomdef.INVULNTICS
        return true
    end

    if power == doomdef.pw_invisibility then
        player.powers[power + 1] = doomdef.INVISTICS
        if player.mo then
            player.mo.flags = bit32.bor(player.mo.flags, p_mobj.MF_SHADOW)
        end
        return true
    end

    if power == doomdef.pw_infrared then
        player.powers[power + 1] = doomdef.INFRATICS
        return true
    end

    if power == doomdef.pw_ironfeet then
        player.powers[power + 1] = doomdef.IRONTICS
        return true
    end

    if power == doomdef.pw_strength then
        p_inter.P_GiveBody(player, 100)
        player.powers[power + 1] = 1
        return true
    end

    if player.powers[power + 1] then
        return false -- already got it
    end

    player.powers[power + 1] = 1
    return true
end

-- ---------------------------------------------------------------------------
-- P_TouchSpecialThing
-- ---------------------------------------------------------------------------

function p_inter.P_TouchSpecialThing(special, toucher)
    local player
    local i
    local delta
    local sound

    delta = special.z - toucher.z

    if delta > toucher.height or delta < -8 * m_fixed.FRACUNIT then
        -- out of reach
        return
    end

    sound = sounds.sfxenum.sfx_itemup
    player = toucher.player

    -- Dead thing touching. Can happen with a sliding player corpse.
    if toucher.health <= 0 then
        return
    end

    -- Identify by sprite.
    local spr = special.sprite

    if spr == info.spritenum.SPR_ARM1 then -- armor
        if not p_inter.P_GiveArmor(player, deh_misc.deh_green_armor_class) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTARMOR)
    elseif spr == info.spritenum.SPR_ARM2 then
        if not p_inter.P_GiveArmor(player, deh_misc.deh_blue_armor_class) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTMEGA)
    elseif spr == info.spritenum.SPR_BON1 then -- bonus items
        player.health = player.health + 1 -- can go over 100%
        if player.health > deh_misc.deh_max_health then
            player.health = deh_misc.deh_max_health
        end
        if player.mo then
            player.mo.health = player.health
        end
        player.message = deh_str.DEH_String(got.GOTHTHBONUS)
    elseif spr == info.spritenum.SPR_BON2 then
        player.armorpoints = player.armorpoints + 1 -- can go over 100%
        if player.armorpoints > deh_misc.deh_max_armor then
            player.armorpoints = deh_misc.deh_max_armor
        end
        -- deh_green_armor_class only applies to the green armor shirt;
        -- for the armor helmets, armortype 1 is always used.
        if player.armortype == 0 then
            player.armortype = 1
        end
        player.message = deh_str.DEH_String(got.GOTARMBONUS)
    elseif spr == info.spritenum.SPR_SOUL then
        player.health = player.health + deh_misc.deh_soulsphere_health
        if player.health > deh_misc.deh_max_soulsphere then
            player.health = deh_misc.deh_max_soulsphere
        end
        if player.mo then
            player.mo.health = player.health
        end
        player.message = deh_str.DEH_String(got.GOTSUPER)
        sound = sounds.sfxenum.sfx_getpow
    elseif spr == info.spritenum.SPR_MEGA then
        if doomstat.gamemode ~= 2 then -- commercial
            return
        end
        player.health = deh_misc.deh_megasphere_health
        if player.mo then
            player.mo.health = player.health
        end
        -- We always give armor type 2 for the megasphere; dehacked only
        -- affects the MegaArmor.
        p_inter.P_GiveArmor(player, 2)
        player.message = deh_str.DEH_String(got.GOTMSPHERE)
        sound = sounds.sfxenum.sfx_getpow
    elseif spr == info.spritenum.SPR_BKEY then -- cards
        -- leave cards for everyone
        if not player.cards[doomdef.it_bluecard + 1] then
            player.message = deh_str.DEH_String(got.GOTBLUECARD)
        end
        p_inter.P_GiveCard(player, doomdef.it_bluecard)
        if not doomstat.netgame then
            -- break
        else
            return
        end
    elseif spr == info.spritenum.SPR_YKEY then
        if not player.cards[doomdef.it_yellowcard + 1] then
            player.message = deh_str.DEH_String(got.GOTYELWCARD)
        end
        p_inter.P_GiveCard(player, doomdef.it_yellowcard)
        if not doomstat.netgame then
            -- break
        else
            return
        end
    elseif spr == info.spritenum.SPR_RKEY then
        if not player.cards[doomdef.it_redcard + 1] then
            player.message = deh_str.DEH_String(got.GOTREDCARD)
        end
        p_inter.P_GiveCard(player, doomdef.it_redcard)
        if not doomstat.netgame then
            -- break
        else
            return
        end
    elseif spr == info.spritenum.SPR_BSKU then
        if not player.cards[doomdef.it_blueskull + 1] then
            player.message = deh_str.DEH_String(got.GOTBLUESKUL)
        end
        p_inter.P_GiveCard(player, doomdef.it_blueskull)
        if not doomstat.netgame then
            -- break
        else
            return
        end
    elseif spr == info.spritenum.SPR_YSKU then
        if not player.cards[doomdef.it_yellowskull + 1] then
            player.message = deh_str.DEH_String(got.GOTYELWSKUL)
        end
        p_inter.P_GiveCard(player, doomdef.it_yellowskull)
        if not doomstat.netgame then
            -- break
        else
            return
        end
    elseif spr == info.spritenum.SPR_RSKU then
        if not player.cards[doomdef.it_redskull + 1] then
            player.message = deh_str.DEH_String(got.GOTREDSKULL)
        end
        p_inter.P_GiveCard(player, doomdef.it_redskull)
        if not doomstat.netgame then
            -- break
        else
            return
        end
    elseif spr == info.spritenum.SPR_STIM then -- medikits, heals
        if not p_inter.P_GiveBody(player, 10) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTSTIM)
    elseif spr == info.spritenum.SPR_MEDI then
        if not p_inter.P_GiveBody(player, 25) then
            return
        end

        if player.health < 25 then
            player.message = deh_str.DEH_String(got.GOTMEDINEED)
        else
            player.message = deh_str.DEH_String(got.GOTMEDIKIT)
        end
    elseif spr == info.spritenum.SPR_PINV then -- power ups
        if not p_inter.P_GivePower(player, doomdef.pw_invulnerability) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTINVUL)
        sound = sounds.sfxenum.sfx_getpow
    elseif spr == info.spritenum.SPR_PSTR then
        if not p_inter.P_GivePower(player, doomdef.pw_strength) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTBERSERK)
        if player.readyweapon ~= doomdef.wp_fist then
            player.pendingweapon = doomdef.wp_fist
        end
        sound = sounds.sfxenum.sfx_getpow
    elseif spr == info.spritenum.SPR_PINS then
        if not p_inter.P_GivePower(player, doomdef.pw_invisibility) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTINVIS)
        sound = sounds.sfxenum.sfx_getpow
    elseif spr == info.spritenum.SPR_SUIT then
        if not p_inter.P_GivePower(player, doomdef.pw_ironfeet) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTSUIT)
        sound = sounds.sfxenum.sfx_getpow
    elseif spr == info.spritenum.SPR_PMAP then
        if not p_inter.P_GivePower(player, doomdef.pw_allmap) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTMAP)
        sound = sounds.sfxenum.sfx_getpow
    elseif spr == info.spritenum.SPR_PVIS then
        if not p_inter.P_GivePower(player, doomdef.pw_infrared) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTVISOR)
        sound = sounds.sfxenum.sfx_getpow
    elseif spr == info.spritenum.SPR_CLIP then -- ammo
        if bit32.band(special.flags, p_mobj.MF_DROPPED) ~= 0 then
            if not p_inter.P_GiveAmmo(player, doomdef.am_clip, 0) then
                return
            end
        else
            if not p_inter.P_GiveAmmo(player, doomdef.am_clip, 1) then
                return
            end
        end
        player.message = deh_str.DEH_String(got.GOTCLIP)
    elseif spr == info.spritenum.SPR_AMMO then
        if not p_inter.P_GiveAmmo(player, doomdef.am_clip, 5) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTCLIPBOX)
    elseif spr == info.spritenum.SPR_ROCK then
        if not p_inter.P_GiveAmmo(player, doomdef.am_misl, 1) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTROCKET)
    elseif spr == info.spritenum.SPR_BROK then
        if not p_inter.P_GiveAmmo(player, doomdef.am_misl, 5) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTROCKBOX)
    elseif spr == info.spritenum.SPR_CELL then
        if not p_inter.P_GiveAmmo(player, doomdef.am_cell, 1) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTCELL)
    elseif spr == info.spritenum.SPR_CELP then
        if not p_inter.P_GiveAmmo(player, doomdef.am_cell, 5) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTCELLBOX)
    elseif spr == info.spritenum.SPR_SHEL then
        if not p_inter.P_GiveAmmo(player, doomdef.am_shell, 1) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTSHELLS)
    elseif spr == info.spritenum.SPR_SBOX then
        if not p_inter.P_GiveAmmo(player, doomdef.am_shell, 5) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTSHELLBOX)
    elseif spr == info.spritenum.SPR_BPAK then
        if not player.backpack then
            for i = 0, doomdef.NUMAMMO - 1 do
                player.maxammo[i + 1] = player.maxammo[i + 1] * 2
            end
            player.backpack = true
        end
        for i = 0, doomdef.NUMAMMO - 1 do
            p_inter.P_GiveAmmo(player, i, 1)
        end
        player.message = deh_str.DEH_String(got.GOTBACKPACK)
    elseif spr == info.spritenum.SPR_BFUG then -- weapons
        if not p_inter.P_GiveWeapon(player, doomdef.wp_bfg, false) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTBFG9000)
        sound = sounds.sfxenum.sfx_wpnup
    elseif spr == info.spritenum.SPR_MGUN then
        if not p_inter.P_GiveWeapon(player, doomdef.wp_chaingun,
            bit32.band(special.flags, p_mobj.MF_DROPPED) ~= 0) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTCHAINGUN)
        sound = sounds.sfxenum.sfx_wpnup
    elseif spr == info.spritenum.SPR_CSAW then
        if not p_inter.P_GiveWeapon(player, doomdef.wp_chainsaw, false) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTCHAINSAW)
        sound = sounds.sfxenum.sfx_wpnup
    elseif spr == info.spritenum.SPR_LAUN then
        if not p_inter.P_GiveWeapon(player, doomdef.wp_missile, false) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTLAUNCHER)
        sound = sounds.sfxenum.sfx_wpnup
    elseif spr == info.spritenum.SPR_PLAS then
        if not p_inter.P_GiveWeapon(player, doomdef.wp_plasma, false) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTPLASMA)
        sound = sounds.sfxenum.sfx_wpnup
    elseif spr == info.spritenum.SPR_SHOT then
        if not p_inter.P_GiveWeapon(player, doomdef.wp_shotgun,
            bit32.band(special.flags, p_mobj.MF_DROPPED) ~= 0) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTSHOTGUN)
        sound = sounds.sfxenum.sfx_wpnup
    elseif spr == info.spritenum.SPR_SGN2 then
        if not p_inter.P_GiveWeapon(player, doomdef.wp_supershotgun,
            bit32.band(special.flags, p_mobj.MF_DROPPED) ~= 0) then
            return
        end
        player.message = deh_str.DEH_String(got.GOTSHOTGUN2)
        sound = sounds.sfxenum.sfx_wpnup
    else
        i_system.I_Error("P_SpecialThing: Unknown gettable thing")
    end

    if bit32.band(special.flags, p_mobj.MF_COUNTITEM) ~= 0 then
        player.itemcount = player.itemcount + 1
    end
    p_mobj.P_RemoveMobj(special)
    player.bonuscount = player.bonuscount + BONUSADD
    if player == doomstat.players[doomstat.consoleplayer + 1] then
        s_sound.S_StartSound(nil, sound)
    end
end

-- ---------------------------------------------------------------------------
-- P_KillMobj
-- ---------------------------------------------------------------------------

function p_inter.P_KillMobj(source, target)
    local item
    local mo

    target.flags = bit32.band(target.flags,
        bit32.bnot(p_mobj.MF_SHOOTABLE + p_mobj.MF_FLOAT + p_mobj.MF_SKULLFLY))

    if target.type ~= info.mobjtype.MT_SKULL then
        target.flags = bit32.band(target.flags, bit32.bnot(p_mobj.MF_NOGRAVITY))
    end

    target.flags = bit32.bor(target.flags,
        p_mobj.MF_CORPSE + p_mobj.MF_DROPOFF)
    target.height = target.height // 4 -- >>2

    if source and source.player then
        -- count for intermission
        if bit32.band(target.flags, p_mobj.MF_COUNTKILL) ~= 0 then
            source.player.killcount = source.player.killcount + 1
        end

        if target.player then
            local pidx = target.player_index
            if pidx ~= nil then
                source.player.frags[pidx + 1] =
                    (source.player.frags[pidx + 1] or 0) + 1
            end
        end
    elseif not doomstat.netgame and bit32.band(target.flags, p_mobj.MF_COUNTKILL) ~= 0 then
        -- count all monster deaths, even those caused by other monsters
        local players = doomstat.players
        if players[1] then
            players[1].killcount = players[1].killcount + 1
        end
    end

    if target.player then
        -- count environment kills against you
        if not source then
            local pidx = target.player_index
            if pidx ~= nil then
                target.player.frags[pidx + 1] =
                    (target.player.frags[pidx + 1] or 0) + 1
            end
        end

        target.flags = bit32.band(target.flags, bit32.bnot(p_mobj.MF_SOLID))
        target.player.playerstate = 1 -- PST_DEAD
        p_pspr.P_DropWeapon(target.player)

        if target.player == doomstat.players[doomstat.consoleplayer + 1]
            and doomstat.automapactive then
            -- don't die in auto map, switch view prior to dying
            -- AM_Stop() (Phase 4e: am_map)
        end
    end

    if target.health < -target.info.spawnhealth
        and target.info.xdeathstate ~= 0 then
        p_mobj.P_SetMobjState(target, target.info.xdeathstate)
    else
        p_mobj.P_SetMobjState(target, target.info.deathstate)
    end
    target.tics = target.tics - (m_random.P_Random() % 4) -- &3

    if target.tics < 1 then
        target.tics = 1
    end

    -- In Chex Quest, monsters don't drop items.
    if doomstat.gameversion == 9 then -- exe_chex
        return
    end

    -- Drop stuff.
    -- This determines the kind of object spawned during the death frame of
    -- a thing.
    if target.type == info.mobjtype.MT_WOLFSS
        or target.type == info.mobjtype.MT_POSSESSED then
        item = info.mobjtype.MT_CLIP
    elseif target.type == info.mobjtype.MT_SHOTGUY then
        item = info.mobjtype.MT_SHOTGUN
    elseif target.type == info.mobjtype.MT_CHAINGUY then
        item = info.mobjtype.MT_CHAINGUN
    else
        return
    end

    mo = p_mobj.P_SpawnMobj(target.x, target.y, -2147483648, item) -- ONFLOORZ
    mo.flags = bit32.bor(mo.flags, p_mobj.MF_DROPPED) -- special versions of items
end

-- ---------------------------------------------------------------------------
-- P_DamageMobj
-- Damages both enemies and players.
-- ---------------------------------------------------------------------------

function p_inter.P_DamageMobj(target, inflictor, source, damage)
    local ang
    local saved
    local player
    local thrust
    local temp

    if bit32.band(target.flags, p_mobj.MF_SHOOTABLE) == 0 then
        return -- shouldn't happen...
    end

    if target.health <= 0 then
        return
    end

    if bit32.band(target.flags, p_mobj.MF_SKULLFLY) ~= 0 then
        target.momx = 0
        target.momy = 0
        target.momz = 0
    end

    player = target.player
    if player and doomstat.gameskill == 0 then -- sk_baby
        damage = damage // 2 -- take half damage in trainer mode
    end

    -- Some close combat weapons should not inflict thrust and push the
    -- victim out of reach, thus kick away unless using the chainsaw.
    if inflictor
        and bit32.band(target.flags, p_mobj.MF_NOCLIP) == 0
        and (not source
            or not source.player
            or source.player.readyweapon ~= doomdef.wp_chainsaw) then
        ang = r_main.R_PointToAngle2(inflictor.x, inflictor.y,
            target.x, target.y)

        thrust = damage * (m_fixed.FRACUNIT // 8) * 100 // target.info.mass

        -- make fall forwards sometimes
        if damage < 40
            and damage > target.health
            and target.z - inflictor.z > 64 * m_fixed.FRACUNIT
            and bit32.band(m_random.P_Random(), 1) ~= 0 then
            ang = (ang + doomtype.ANG180) % 0x100000000
            thrust = thrust * 4
        end

        ang = bit32.rshift(ang, 19) -- ANGLETOFINESHIFT
        target.momx = target.momx + m_fixed.FixedMul(thrust,
            tables.finesine[ang + 1 + 2048]) -- finecosine[ang]
        target.momy = target.momy + m_fixed.FixedMul(thrust,
            tables.finesine[ang + 1])
    end

    -- player specific
    if player then
        -- end of game hell hack
        if target.subsector
            and target.subsector.sector.special == 11
            and damage >= target.health then
            damage = target.health - 1
        end

        -- Below certain threshold, ignore damage in GOD mode, or with
        -- INVUL power.
        if damage < 1000
            and (bit32.band(player.cheats, 2) ~= 0 -- CF_GODMODE
                or player.powers[doomdef.pw_invulnerability + 1] ~= 0) then
            return
        end

        if player.armortype ~= 0 then
            if player.armortype == 1 then
                saved = damage // 3
            else
                saved = damage // 2
            end

            if player.armorpoints <= saved then
                -- armor is used up
                saved = player.armorpoints
                player.armortype = 0
            end
            player.armorpoints = player.armorpoints - saved
            damage = damage - saved
        end
        player.health = player.health - damage -- mirror mobj health here
        if player.health < 0 then
            player.health = 0
        end

        player.attacker = source
        player.damagecount = player.damagecount + damage -- add damage after armor / invuln

        if player.damagecount > 100 then
            player.damagecount = 100 -- teleport stomp does 10k points...
        end

        temp = damage < 100 and damage or 100

        if player == doomstat.players[doomstat.consoleplayer + 1] then
            i_system.I_Tactile(40, 10, 40 + temp * 2)
        end
    end

    -- do the damage
    target.health = target.health - damage
    if target.health <= 0 then
        p_inter.P_KillMobj(source, target)
        return
    end

    if m_random.P_Random() < target.info.painchance
        and bit32.band(target.flags, p_mobj.MF_SKULLFLY) == 0 then
        target.flags = bit32.bor(target.flags, p_mobj.MF_JUSTHIT) -- fight back!

        p_mobj.P_SetMobjState(target, target.info.painstate)
    end

    target.reactiontime = 0 -- we're awake now...

    if (target.threshold == 0 or target.type == info.mobjtype.MT_VILE)
        and source and source ~= target
        and source.type ~= info.mobjtype.MT_VILE then
        -- if not intent on another player, chase after this one
        target.target = source
        target.threshold = 100 -- BASETHRESHOLD
        if target.state == info.states[target.info.spawnstate + 1]
            and target.info.seestate ~= 0 then -- S_NULL
            p_mobj.P_SetMobjState(target, target.info.seestate)
        end
    end
end

return p_inter
end)()

p_lights = (function()
local p_lights = {}

local GLOWSPEED = 8
local STROBEBRIGHT = 5
local SLOWDARK = 35

-- ---------------------------------------------------------------------------
-- T_FireFlicker
-- ---------------------------------------------------------------------------

function p_lights.T_FireFlicker(flick)
    local amount

    flick.count = flick.count - 1
    if flick.count ~= 0 then
        return
    end

    amount = bit32.band(m_random.P_Random(), 3) * 16 -- &3)*16

    if flick.sector.lightlevel - amount < flick.minlight then
        flick.sector.lightlevel = flick.minlight
    else
        flick.sector.lightlevel = flick.maxlight - amount
    end

    flick.count = 4
end

-- ---------------------------------------------------------------------------
-- P_SpawnFireFlicker
-- ---------------------------------------------------------------------------

function p_lights.P_SpawnFireFlicker(sector)
    local flick

    -- Note that we are resetting sector attributes.
    -- Nothing special about it during gameplay.
    sector.special = 0

    flick = {}
    p_tick.P_AddThinker(flick)

    flick.thinkfunc = p_lights.T_FireFlicker
    flick.sector = sector
    flick.maxlight = sector.lightlevel
    flick.minlight = p_spec.P_FindMinSurroundingLight(sector, sector.lightlevel) + 16
    flick.count = 4
end

-- ---------------------------------------------------------------------------
-- T_LightFlash
-- Do flashing lights.
-- ---------------------------------------------------------------------------

function p_lights.T_LightFlash(flash)
    flash.count = flash.count - 1
    if flash.count ~= 0 then
        return
    end

    if flash.sector.lightlevel == flash.maxlight then
        flash.sector.lightlevel = flash.minlight
        flash.count = bit32.band(m_random.P_Random(), flash.mintime) + 1
    else
        flash.sector.lightlevel = flash.maxlight
        flash.count = bit32.band(m_random.P_Random(), flash.maxtime) + 1
    end
end

-- ---------------------------------------------------------------------------
-- P_SpawnLightFlash
-- After the map has been loaded, scan each sector for specials that spawn
-- thinkers.
-- ---------------------------------------------------------------------------

function p_lights.P_SpawnLightFlash(sector)
    local flash

    -- nothing special about it during gameplay
    sector.special = 0

    flash = {}
    p_tick.P_AddThinker(flash)

    flash.thinkfunc = p_lights.T_LightFlash
    flash.sector = sector
    flash.maxlight = sector.lightlevel

    flash.minlight = p_spec.P_FindMinSurroundingLight(sector, sector.lightlevel)
    flash.maxtime = 64
    flash.mintime = 7
    flash.count = bit32.band(m_random.P_Random(), flash.maxtime) + 1
end

-- ---------------------------------------------------------------------------
-- T_StrobeFlash
-- ---------------------------------------------------------------------------

function p_lights.T_StrobeFlash(flash)
    flash.count = flash.count - 1
    if flash.count ~= 0 then
        return
    end

    if flash.sector.lightlevel == flash.minlight then
        flash.sector.lightlevel = flash.maxlight
        flash.count = flash.brighttime
    else
        flash.sector.lightlevel = flash.minlight
        flash.count = flash.darktime
    end
end

-- ---------------------------------------------------------------------------
-- P_SpawnStrobeFlash
-- After the map has been loaded, scan each sector for specials that spawn
-- thinkers.
-- ---------------------------------------------------------------------------

function p_lights.P_SpawnStrobeFlash(sector, fastOrSlow, inSync)
    local flash

    flash = {}
    p_tick.P_AddThinker(flash)

    flash.sector = sector
    flash.darktime = fastOrSlow
    flash.brighttime = STROBEBRIGHT
    flash.thinkfunc = p_lights.T_StrobeFlash
    flash.maxlight = sector.lightlevel
    flash.minlight = p_spec.P_FindMinSurroundingLight(sector, sector.lightlevel)

    if flash.minlight == flash.maxlight then
        flash.minlight = 0
    end

    -- nothing special about it during gameplay
    sector.special = 0

    if inSync == 0 then
        flash.count = bit32.band(m_random.P_Random(), 7) + 1
    else
        flash.count = 1
    end
end

-- ---------------------------------------------------------------------------
-- EV_StartLightStrobing
-- Start strobing lights (usually from a trigger).
-- ---------------------------------------------------------------------------

function p_lights.EV_StartLightStrobing(line)
    local secnum
    local sec

    secnum = -1
    while true do
        secnum = p_spec.P_FindSectorFromLineTag(line, secnum)
        if secnum < 0 then
            break
        end

        sec = r_state.sectors[secnum + 1]
        if sec.specialdata then
            -- continue
        else
            p_lights.P_SpawnStrobeFlash(sec, SLOWDARK, 0)
        end
    end
end

-- ---------------------------------------------------------------------------
-- EV_TurnTagLightsOff
-- Turn line's tag lights off.
-- ---------------------------------------------------------------------------

function p_lights.EV_TurnTagLightsOff(line)
    local min
    local sector
    local tsec
    local templine

    for j = 1, r_state.numsectors do
        sector = r_state.sectors[j]
        if sector.tag == line.tag then
            min = sector.lightlevel
            for i = 1, sector.linecount do
                templine = sector.lines[i]
                tsec = p_spec.getNextSector(templine, sector)
                if tsec then
                    if tsec.lightlevel < min then
                        min = tsec.lightlevel
                    end
                end
            end
            sector.lightlevel = min
        end
    end
end

-- ---------------------------------------------------------------------------
-- EV_LightTurnOn
-- Turn line's tag lights on.
-- ---------------------------------------------------------------------------

function p_lights.EV_LightTurnOn(line, bright)
    local sector
    local temp
    local templine

    -- bright is modified across sectors in the C (first tagged sector's
    -- brightest neighbour sets the value for all tagged sectors), so keep a
    -- mutable local.
    local brightval = bright

    for i = 1, r_state.numsectors do
        sector = r_state.sectors[i]
        if sector.tag == line.tag then
            -- bright = 0 means to search
            -- for highest light level
            -- surrounding sector
            if brightval == 0 then
                for j = 1, sector.linecount do
                    templine = sector.lines[j]
                    temp = p_spec.getNextSector(templine, sector)

                    if temp then
                        if temp.lightlevel > brightval then
                            brightval = temp.lightlevel
                        end
                    end
                end
            end
            sector.lightlevel = brightval
        end
    end
end

-- ---------------------------------------------------------------------------
-- T_Glow
-- ---------------------------------------------------------------------------

function p_lights.T_Glow(g)
    if g.direction == -1 then
        -- DOWN
        g.sector.lightlevel = g.sector.lightlevel - GLOWSPEED
        if g.sector.lightlevel <= g.minlight then
            g.sector.lightlevel = g.sector.lightlevel + GLOWSPEED
            g.direction = 1
        end
    elseif g.direction == 1 then
        -- UP
        g.sector.lightlevel = g.sector.lightlevel + GLOWSPEED
        if g.sector.lightlevel >= g.maxlight then
            g.sector.lightlevel = g.sector.lightlevel - GLOWSPEED
            g.direction = -1
        end
    end
end

-- ---------------------------------------------------------------------------
-- P_SpawnGlowingLight
-- ---------------------------------------------------------------------------

function p_lights.P_SpawnGlowingLight(sector)
    local g

    g = {}
    p_tick.P_AddThinker(g)

    g.sector = sector
    g.minlight = p_spec.P_FindMinSurroundingLight(sector, sector.lightlevel)
    g.maxlight = sector.lightlevel
    g.thinkfunc = p_lights.T_Glow
    g.direction = -1

    sector.special = 0
end

return p_lights
end)()

p_map = (function()
local p_map = {}

-- Spechit overrun magic value (see the C comments; PrBoom-plus compatible).
local DEFAULT_SPECHIT_MAGIC = 0x01C09C98

-- ---------------------------------------------------------------------------
-- Globals (p_local.h / p_map.c externs)
-- ---------------------------------------------------------------------------

p_map.tmbbox = { 0, 0, 0, 0 } -- [BOXTOP, BOXBOTTOM, BOXRIGHT, BOXLEFT] (C order)
p_map.tmthing = nil
p_map.tmflags = 0
p_map.tmx = 0
p_map.tmy = 0

-- If "floatok" true, move would be ok if within "tmfloorz - tmceilingz".
p_map.floatok = false

p_map.tmfloorz = 0
p_map.tmceilingz = 0
p_map.tmdropoffz = 0

-- Keep track of the line that lowers the ceiling, so missiles don't explode
-- against sky hack walls.
p_map.ceilingline = nil

-- Keep track of special lines as they are hit, but don't process them until
-- the move is proven valid.
local MAXSPECIALCROSS = 20
local MAXSPECIALCROSS_ORIGINAL = 8
p_map.spechit = {}
for _ = 1, MAXSPECIALCROSS do
    table.insert(p_map.spechit, nil)
end
p_map.numspechit = 0

local FRACUNIT = m_fixed.FRACUNIT
local MAXRADIUS = 32 * FRACUNIT
local MAPBLOCKSHIFT = 23
local ANG180 = doomtype.ANG180

-- ---------------------------------------------------------------------------
-- PIT_StompThing
-- ---------------------------------------------------------------------------

function p_map.PIT_StompThing(thing)
    local blockdist

    if bit32.band(thing.flags, p_mobj.MF_SHOOTABLE) == 0 then
        return true
    end

    blockdist = thing.radius + p_map.tmthing.radius

    if math.abs(thing.x - p_map.tmx) >= blockdist
        or math.abs(thing.y - p_map.tmy) >= blockdist then
        -- didn't hit it
        return true
    end

    -- don't clip against self
    if thing == p_map.tmthing then
        return true
    end

    -- monsters don't stomp things except on boss level
    if not p_map.tmthing.player and doomstat.gamemap ~= 30 then
        return false
    end

    p_inter.P_DamageMobj(thing, p_map.tmthing, p_map.tmthing, 10000)

    return true
end

-- ---------------------------------------------------------------------------
-- P_TeleportMove
-- ---------------------------------------------------------------------------

function p_map.P_TeleportMove(thing, x, y)
    local xl
    local xh
    local yl
    local yh
    local bx
    local by

    local newsubsec

    -- kill anything occupying the position
    p_map.tmthing = thing
    p_map.tmflags = thing.flags

    p_map.tmx = x
    p_map.tmy = y

    p_map.tmbbox[m_bbox.BOXTOP] = y + thing.radius
    p_map.tmbbox[m_bbox.BOXBOTTOM] = y - thing.radius
    p_map.tmbbox[m_bbox.BOXRIGHT] = x + thing.radius
    p_map.tmbbox[m_bbox.BOXLEFT] = x - thing.radius

    newsubsec = r_main.R_PointInSubsector(x, y)
    p_map.ceilingline = nil

    -- The base floor/ceiling is from the subsector that contains the point.
    -- Any contacted lines the step closer together will adjust them.
    p_map.tmfloorz = newsubsec.sector.floorheight
    p_map.tmdropoffz = newsubsec.sector.floorheight
    p_map.tmceilingz = newsubsec.sector.ceilingheight

    r_state.validcount = r_state.validcount + 1
    p_map.numspechit = 0

    -- stomp on any things contacted
    xl = (p_map.tmbbox[m_bbox.BOXLEFT] - r_state.bmaporgx - MAXRADIUS) // 2 ^ MAPBLOCKSHIFT
    xh = (p_map.tmbbox[m_bbox.BOXRIGHT] - r_state.bmaporgx + MAXRADIUS) // 2 ^ MAPBLOCKSHIFT
    yl = (p_map.tmbbox[m_bbox.BOXBOTTOM] - r_state.bmaporgy - MAXRADIUS) // 2 ^ MAPBLOCKSHIFT
    yh = (p_map.tmbbox[m_bbox.BOXTOP] - r_state.bmaporgy + MAXRADIUS) // 2 ^ MAPBLOCKSHIFT

    for bx = xl, xh do
        for by = yl, yh do
            if not p_maputl.P_BlockThingsIterator(bx, by, p_map.PIT_StompThing) then
                return false
            end
        end
    end

    -- the move is ok, so link the thing into its new position
    p_maputl.P_UnsetThingPosition(thing)

    thing.floorz = p_map.tmfloorz
    thing.ceilingz = p_map.tmceilingz
    thing.x = x
    thing.y = y

    p_maputl.P_SetThingPosition(thing)

    return true
end

-- ---------------------------------------------------------------------------
-- PIT_CheckLine
-- Adjusts tmfloorz and tmceilingz as lines are contacted.
-- ---------------------------------------------------------------------------

local function SpechitOverrun(ld)
    local baseaddr = DEFAULT_SPECHIT_MAGIC

    -- Calculate address used in doom2.exe
    local addr = baseaddr + (ld.index or 0) * 0x3E

    if p_map.numspechit == 9
        or p_map.numspechit == 10
        or p_map.numspechit == 11
        or p_map.numspechit == 12 then
        p_map.tmbbox[p_map.numspechit - 8] = addr -- tmbbox[numspechit-9]
    elseif p_map.numspechit == 13 then
        p_map.crushchange = addr
    elseif p_map.numspechit == 14 then
        p_map.nofit = addr
    else
        print(string.format(
            "SpechitOverrun: Warning: unable to emulate an overrun where numspechit=%i",
            p_map.numspechit))
    end
end

function p_map.PIT_CheckLine(ld)
    if p_map.tmbbox[m_bbox.BOXRIGHT] <= ld.bbox[m_bbox.BOXLEFT]
        or p_map.tmbbox[m_bbox.BOXLEFT] >= ld.bbox[m_bbox.BOXRIGHT]
        or p_map.tmbbox[m_bbox.BOXTOP] <= ld.bbox[m_bbox.BOXBOTTOM]
        or p_map.tmbbox[m_bbox.BOXBOTTOM] >= ld.bbox[m_bbox.BOXTOP] then
        return true
    end

    if p_maputl.P_BoxOnLineSide(p_map.tmbbox, ld) ~= -1 then
        return true
    end

    -- A line has been hit

    -- The moving thing's destination position will cross the given line.
    -- If this should not be allowed, return false.
    -- If the line is special, keep track of it to process later if the move
    -- is proven ok.

    if not ld.backsector then
        return false -- one sided line
    end

    if bit32.band(p_map.tmflags, p_mobj.MF_MISSILE) == 0 then
        if bit32.band(ld.flags, 1) ~= 0 then -- ML_BLOCKING
            return false -- explicitly blocking everything
        end

        if not p_map.tmthing.player
            and bit32.band(ld.flags, 2) ~= 0 then -- ML_BLOCKMONSTERS
            return false -- block monsters only
        end
    end

    -- set openrange, opentop, openbottom
    p_maputl.P_LineOpening(ld)

    -- adjust floor / ceiling heights
    if p_maputl.opentop < p_map.tmceilingz then
        p_map.tmceilingz = p_maputl.opentop
        p_map.ceilingline = ld
    end

    if p_maputl.openbottom > p_map.tmfloorz then
        p_map.tmfloorz = p_maputl.openbottom
    end

    if p_maputl.lowfloor < p_map.tmdropoffz then
        p_map.tmdropoffz = p_maputl.lowfloor
    end

    -- if contacted a special line, add it to the list
    if ld.special ~= 0 then
        p_map.spechit[p_map.numspechit + 1] = ld
        p_map.numspechit = p_map.numspechit + 1

        -- spechits overrun emulation code from prboom-plus
        if p_map.numspechit > MAXSPECIALCROSS_ORIGINAL then
            SpechitOverrun(ld)
        end
    end

    return true
end

-- ---------------------------------------------------------------------------
-- PIT_CheckThing
-- ---------------------------------------------------------------------------

function p_map.PIT_CheckThing(thing)
    local blockdist
    local solid
    local damage

    if bit32.band(thing.flags,
        p_mobj.MF_SOLID + p_mobj.MF_SPECIAL + p_mobj.MF_SHOOTABLE) == 0 then
        return true
    end

    blockdist = thing.radius + p_map.tmthing.radius

    if math.abs(thing.x - p_map.tmx) >= blockdist
        or math.abs(thing.y - p_map.tmy) >= blockdist then
        -- didn't hit it
        return true
    end

    -- don't clip against self
    if thing == p_map.tmthing then
        return true
    end

    -- check for skulls slamming into things
    if bit32.band(p_map.tmflags, p_mobj.MF_SKULLFLY) ~= 0 then
        damage = ((m_random.P_Random() % 8) + 1) * p_map.tmthing.info.damage

        p_inter.P_DamageMobj(thing, p_map.tmthing, p_map.tmthing, damage)

        p_map.tmthing.flags = bit32.band(p_map.tmthing.flags,
            bit32.bnot(p_mobj.MF_SKULLFLY))
        p_map.tmthing.momx = 0
        p_map.tmthing.momy = 0
        p_map.tmthing.momz = 0

        p_mobj.P_SetMobjState(p_map.tmthing,
            p_map.tmthing.info.spawnstate)

        return false -- stop moving
    end

    -- missiles can hit other things
    if bit32.band(p_map.tmflags, p_mobj.MF_MISSILE) ~= 0 then
        -- see if it went over / under
        if p_map.tmthing.z > thing.z + thing.height then
            return true -- overhead
        end
        if p_map.tmthing.z + p_map.tmthing.height < thing.z then
            return true -- underneath
        end

        if p_map.tmthing.target
            and (p_map.tmthing.target.type == thing.type
                or (p_map.tmthing.target.type == info.mobjtype.MT_KNIGHT
                    and thing.type == info.mobjtype.MT_BRUISER)
                or (p_map.tmthing.target.type == info.mobjtype.MT_BRUISER
                    and thing.type == info.mobjtype.MT_KNIGHT)) then
            -- Don't hit same species as originator.
            if thing == p_map.tmthing.target then
                return true
            end

            -- deh_species_infighting is 0 (DeHacked disabled in v1)
            if thing.type ~= info.mobjtype.MT_PLAYER then
                -- Explode, but do no damage.
                -- Let players missile other players.
                return false
            end
        end

        if bit32.band(thing.flags, p_mobj.MF_SHOOTABLE) == 0 then
            -- didn't do any damage
            return bit32.band(thing.flags, p_mobj.MF_SOLID) == 0
        end

        -- damage / explode
        damage = ((m_random.P_Random() % 8) + 1) * p_map.tmthing.info.damage
        p_inter.P_DamageMobj(thing, p_map.tmthing, p_map.tmthing.target, damage)

        -- don't traverse any more
        return false
    end

    -- check for special pickup
    if bit32.band(thing.flags, p_mobj.MF_SPECIAL) ~= 0 then
        solid = bit32.band(thing.flags, p_mobj.MF_SOLID) ~= 0
        if bit32.band(p_map.tmflags, p_mobj.MF_PICKUP) ~= 0 then
            -- can remove thing
            p_inter.P_TouchSpecialThing(thing, p_map.tmthing)
        end
        return not solid
    end

    return bit32.band(thing.flags, p_mobj.MF_SOLID) == 0
end

-- ---------------------------------------------------------------------------
-- P_CheckPosition
-- ---------------------------------------------------------------------------

function p_map.P_CheckPosition(thing, x, y)
    local xl
    local xh
    local yl
    local yh
    local bx
    local by
    local newsubsec

    p_map.tmthing = thing
    p_map.tmflags = thing.flags

    p_map.tmx = x
    p_map.tmy = y

    p_map.tmbbox[m_bbox.BOXTOP] = y + thing.radius
    p_map.tmbbox[m_bbox.BOXBOTTOM] = y - thing.radius
    p_map.tmbbox[m_bbox.BOXRIGHT] = x + thing.radius
    p_map.tmbbox[m_bbox.BOXLEFT] = x - thing.radius

    newsubsec = r_main.R_PointInSubsector(x, y)
    p_map.ceilingline = nil

    -- The base floor / ceiling is from the subsector that contains the point.
    -- Any contacted lines the step closer together will adjust them.
    p_map.tmfloorz = newsubsec.sector.floorheight
    p_map.tmdropoffz = newsubsec.sector.floorheight
    p_map.tmceilingz = newsubsec.sector.ceilingheight

    r_state.validcount = r_state.validcount + 1
    p_map.numspechit = 0

    if bit32.band(p_map.tmflags, p_mobj.MF_NOCLIP) ~= 0 then
        return true
    end

    -- Check things first, possibly picking things up.
    -- The bounding box is extended by MAXRADIUS because mobjs are grouped
    -- into mapblocks based on their origin point, and can overlap into
    -- adjacent blocks by up to MAXRADIUS units.
    xl = (p_map.tmbbox[m_bbox.BOXLEFT] - r_state.bmaporgx - MAXRADIUS) // 2 ^ MAPBLOCKSHIFT
    xh = (p_map.tmbbox[m_bbox.BOXRIGHT] - r_state.bmaporgx + MAXRADIUS) // 2 ^ MAPBLOCKSHIFT
    yl = (p_map.tmbbox[m_bbox.BOXBOTTOM] - r_state.bmaporgy - MAXRADIUS) // 2 ^ MAPBLOCKSHIFT
    yh = (p_map.tmbbox[m_bbox.BOXTOP] - r_state.bmaporgy + MAXRADIUS) // 2 ^ MAPBLOCKSHIFT

    for bx = xl, xh do
        for by = yl, yh do
            if not p_maputl.P_BlockThingsIterator(bx, by, p_map.PIT_CheckThing) then
                return false
            end
        end
    end

    -- check lines
    xl = (p_map.tmbbox[m_bbox.BOXLEFT] - r_state.bmaporgx) // 2 ^ MAPBLOCKSHIFT
    xh = (p_map.tmbbox[m_bbox.BOXRIGHT] - r_state.bmaporgx) // 2 ^ MAPBLOCKSHIFT
    yl = (p_map.tmbbox[m_bbox.BOXBOTTOM] - r_state.bmaporgy) // 2 ^ MAPBLOCKSHIFT
    yh = (p_map.tmbbox[m_bbox.BOXTOP] - r_state.bmaporgy) // 2 ^ MAPBLOCKSHIFT

    for bx = xl, xh do
        for by = yl, yh do
            if not p_maputl.P_BlockLinesIterator(bx, by, p_map.PIT_CheckLine) then
                return false
            end
        end
    end

    return true
end

-- ---------------------------------------------------------------------------
-- P_TryMove
-- ---------------------------------------------------------------------------

function p_map.P_TryMove(thing, x, y)
    local oldx
    local oldy
    local side
    local oldside
    local ld

    p_map.floatok = false
    if not p_map.P_CheckPosition(thing, x, y) then
        return false -- solid wall or thing
    end

    if bit32.band(thing.flags, p_mobj.MF_NOCLIP) == 0 then
        if p_map.tmceilingz - p_map.tmfloorz < thing.height then
            return false -- doesn't fit
        end

        p_map.floatok = true

        if bit32.band(thing.flags, p_mobj.MF_TELEPORT) == 0
            and p_map.tmceilingz - thing.z < thing.height then
            return false -- mobj must lower itself to fit
        end

        if bit32.band(thing.flags, p_mobj.MF_TELEPORT) == 0
            and p_map.tmfloorz - thing.z > 24 * FRACUNIT then
            return false -- too big a step up
        end

        if bit32.band(thing.flags, p_mobj.MF_DROPOFF + p_mobj.MF_FLOAT) == 0
            and p_map.tmfloorz - p_map.tmdropoffz > 24 * FRACUNIT then
            return false -- don't stand over a dropoff
        end
    end

    -- the move is ok, so link the thing into its new position
    p_maputl.P_UnsetThingPosition(thing)

    oldx = thing.x
    oldy = thing.y
    thing.floorz = p_map.tmfloorz
    thing.ceilingz = p_map.tmceilingz
    thing.x = x
    thing.y = y

    p_maputl.P_SetThingPosition(thing)

    -- if any special lines were hit, do the effect
    if bit32.band(thing.flags, p_mobj.MF_TELEPORT + p_mobj.MF_NOCLIP) == 0 then
        while p_map.numspechit > 0 do
            p_map.numspechit = p_map.numspechit - 1
            -- see if the line was crossed
            ld = p_map.spechit[p_map.numspechit + 1]
            side = p_maputl.P_PointOnLineSide(thing.x, thing.y, ld)
            oldside = p_maputl.P_PointOnLineSide(oldx, oldy, ld)
            if side ~= oldside then
                if ld.special ~= 0 then
                    p_spec.P_CrossSpecialLine(ld.index, oldside, thing)
                end
            end
        end
    end

    return true
end

-- ---------------------------------------------------------------------------
-- P_ThingHeightClip
-- ---------------------------------------------------------------------------

function p_map.P_ThingHeightClip(thing)
    local onfloor

    onfloor = thing.z == thing.floorz

    p_map.P_CheckPosition(thing, thing.x, thing.y)

    thing.floorz = p_map.tmfloorz
    thing.ceilingz = p_map.tmceilingz

    if onfloor then
        -- walking monsters rise and fall with the floor
        thing.z = thing.floorz
    else
        -- don't adjust a floating monster unless forced to
        if thing.z + thing.height > thing.ceilingz then
            thing.z = thing.ceilingz - thing.height
        end
    end

    if thing.ceilingz - thing.floorz < thing.height then
        return false
    end

    return true
end

-- ---------------------------------------------------------------------------
-- SLIDE MOVE
-- ---------------------------------------------------------------------------

p_map.bestslidefrac = 0
p_map.secondslidefrac = 0
p_map.bestslideline = nil
p_map.secondslideline = nil
p_map.slidemo = nil
p_map.tmxmove = 0
p_map.tmymove = 0

-- P_HitSlideLine: adjusts the xmove / ymove so that the next move will slide
-- along the wall.
function p_map.P_HitSlideLine(ld)
    local side

    local lineangle
    local moveangle
    local deltaangle

    local movelen
    local newlen

    if ld.slopetype == 0 then -- ST_HORIZONTAL
        p_map.tmymove = 0
        return
    end

    if ld.slopetype == 1 then -- ST_VERTICAL
        p_map.tmxmove = 0
        return
    end

    side = p_maputl.P_PointOnLineSide(p_map.slidemo.x, p_map.slidemo.y, ld)

    lineangle = r_main.R_PointToAngle2(0, 0, ld.dx, ld.dy)

    if side == 1 then
        lineangle = (lineangle + ANG180) % 0x100000000
    end

    moveangle = r_main.R_PointToAngle2(0, 0, p_map.tmxmove, p_map.tmymove)
    deltaangle = (moveangle - lineangle) % 0x100000000

    if deltaangle > ANG180 then
        deltaangle = (deltaangle + ANG180) % 0x100000000
    end

    lineangle = bit32.rshift(lineangle, 19)
    deltaangle = bit32.rshift(deltaangle, 19)

    movelen = p_maputl.P_AproxDistance(p_map.tmxmove, p_map.tmymove)
    newlen = m_fixed.FixedMul(movelen, tables.finesine[deltaangle + 1])

    p_map.tmxmove = m_fixed.FixedMul(newlen, tables.finesine[lineangle + 1 + 2048])
    p_map.tmymove = m_fixed.FixedMul(newlen, tables.finesine[lineangle + 1])
end

-- Shared "isblocking" body for PTR_SlideTraverse (the C goto isblocking).
local function SlideIsBlocking(in_)
    if in_.frac < p_map.bestslidefrac then
        p_map.secondslidefrac = p_map.bestslidefrac
        p_map.secondslideline = p_map.bestslideline
        p_map.bestslidefrac = in_.frac
        p_map.bestslideline = in_.line
    end

    return false -- stop
end

-- PTR_SlideTraverse.
function p_map.PTR_SlideTraverse(in_)
    local li

    if not in_.isaline then
        i_system.I_Error("PTR_SlideTraverse: not a line?")
    end

    li = in_.line

    if bit32.band(li.flags, 4) == 0 then -- ML_TWOSIDED
        if p_maputl.P_PointOnLineSide(p_map.slidemo.x, p_map.slidemo.y, li) ~= 0 then
            -- don't hit the back side
            return true
        end
        return SlideIsBlocking(in_)
    end

    -- set openrange, opentop, openbottom
    p_maputl.P_LineOpening(li)

    if p_maputl.openrange < p_map.slidemo.height then
        return SlideIsBlocking(in_) -- doesn't fit
    end

    if p_maputl.opentop - p_map.slidemo.z < p_map.slidemo.height then
        return SlideIsBlocking(in_) -- mobj is too high
    end

    if p_maputl.openbottom - p_map.slidemo.z > 24 * FRACUNIT then
        return SlideIsBlocking(in_) -- too big a step up
    end

    -- this line doesn't block movement
    return true
end

-- ---------------------------------------------------------------------------
-- P_SlideMove
-- ---------------------------------------------------------------------------

function p_map.P_SlideMove(mo)
    local leadx
    local leady
    local trailx
    local traily
    local newx
    local newy
    local hitcount

    p_map.slidemo = mo
    hitcount = 0

    while true do
        hitcount = hitcount + 1
        if hitcount == 3 then
            -- don't loop forever
            -- stairstep
            if not p_map.P_TryMove(mo, mo.x, mo.y + mo.momy) then
                p_map.P_TryMove(mo, mo.x + mo.momx, mo.y)
            end
            return
        end

        -- trace along the three leading corners
        if mo.momx > 0 then
            leadx = mo.x + mo.radius
            trailx = mo.x - mo.radius
        else
            leadx = mo.x - mo.radius
            trailx = mo.x + mo.radius
        end

        if mo.momy > 0 then
            leady = mo.y + mo.radius
            traily = mo.y - mo.radius
        else
            leady = mo.y - mo.radius
            traily = mo.y + mo.radius
        end

        p_map.bestslidefrac = FRACUNIT + 1

        p_maputl.P_PathTraverse(leadx, leady, leadx + mo.momx, leady + mo.momy,
            1, p_map.PTR_SlideTraverse) -- PT_ADDLINES
        p_maputl.P_PathTraverse(trailx, leady, trailx + mo.momx, leady + mo.momy,
            1, p_map.PTR_SlideTraverse)
        p_maputl.P_PathTraverse(leadx, traily, leadx + mo.momx, traily + mo.momy,
            1, p_map.PTR_SlideTraverse)

        -- move up to the wall
        if p_map.bestslidefrac == FRACUNIT + 1 then
            -- the move must have hit the middle, so stairstep
            if not p_map.P_TryMove(mo, mo.x, mo.y + mo.momy) then
                p_map.P_TryMove(mo, mo.x + mo.momx, mo.y)
            end
            return
        end

        -- fudge a bit to make sure it doesn't hit
        p_map.bestslidefrac = p_map.bestslidefrac - 0x800
        if p_map.bestslidefrac > 0 then
            newx = m_fixed.FixedMul(mo.momx, p_map.bestslidefrac)
            newy = m_fixed.FixedMul(mo.momy, p_map.bestslidefrac)

            if not p_map.P_TryMove(mo, mo.x + newx, mo.y + newy) then
                -- stairstep
                if not p_map.P_TryMove(mo, mo.x, mo.y + mo.momy) then
                    p_map.P_TryMove(mo, mo.x + mo.momx, mo.y)
                end
                return
            end
        end

        -- Now continue along the wall.
        -- First calculate remainder.
        p_map.bestslidefrac = FRACUNIT - (p_map.bestslidefrac + 0x800)

        if p_map.bestslidefrac > FRACUNIT then
            p_map.bestslidefrac = FRACUNIT
        end

        if p_map.bestslidefrac <= 0 then
            return
        end

        p_map.tmxmove = m_fixed.FixedMul(mo.momx, p_map.bestslidefrac)
        p_map.tmymove = m_fixed.FixedMul(mo.momy, p_map.bestslidefrac)

        p_map.P_HitSlideLine(p_map.bestslideline) -- clip the moves

        mo.momx = p_map.tmxmove
        mo.momy = p_map.tmymove

        if not p_map.P_TryMove(mo, mo.x + p_map.tmxmove, mo.y + p_map.tmymove) then
            -- retry
            -- continue (the while loop increments hitcount)
        else
            return
        end
    end
end

-- ---------------------------------------------------------------------------
-- P_LineAttack
-- ---------------------------------------------------------------------------

p_map.linetarget = nil -- who got hit (or NULL)
p_map.shootthing = nil
p_map.shootz = 0
p_map.la_damage = 0
p_map.attackrange = 0
p_map.aimslope = 0

-- Slopes to top and bottom of target.
p_map.topslope = 0
p_map.bottomslope = 0

-- PTR_AimTraverse: sets linetarget and aimslope when a target is aimed at.
function p_map.PTR_AimTraverse(in_)
    local li
    local th
    local slope
    local thingtopslope
    local thingbottomslope
    local dist

    if in_.isaline then
        li = in_.line

        if bit32.band(li.flags, 4) == 0 then -- ML_TWOSIDED
            return false -- stop
        end

        -- Crosses a two sided line.
        -- A two sided line will restrict the possible target ranges.
        p_maputl.P_LineOpening(li)

        if p_maputl.openbottom >= p_maputl.opentop then
            return false -- stop
        end

        dist = m_fixed.FixedMul(p_map.attackrange, in_.frac)

        if li.backsector == nil
            or li.frontsector.floorheight ~= li.backsector.floorheight then
            slope = m_fixed.FixedDiv(p_maputl.openbottom - p_map.shootz, dist)
            if slope > p_map.bottomslope then
                p_map.bottomslope = slope
            end
        end

        if li.backsector == nil
            or li.frontsector.ceilingheight ~= li.backsector.ceilingheight then
            slope = m_fixed.FixedDiv(p_maputl.opentop - p_map.shootz, dist)
            if slope < p_map.topslope then
                p_map.topslope = slope
            end
        end

        if p_map.topslope <= p_map.bottomslope then
            return false -- stop
        end

        return true -- shot continues
    end

    -- shoot a thing
    th = in_.thing
    if th == p_map.shootthing then
        return true -- can't shoot self
    end

    if bit32.band(th.flags, p_mobj.MF_SHOOTABLE) == 0 then
        return true -- corpse or something
    end

    -- check angles to see if the thing can be aimed at
    dist = m_fixed.FixedMul(p_map.attackrange, in_.frac)
    thingtopslope = m_fixed.FixedDiv(th.z + th.height - p_map.shootz, dist)

    if thingtopslope < p_map.bottomslope then
        return true -- shot over the thing
    end

    thingbottomslope = m_fixed.FixedDiv(th.z - p_map.shootz, dist)

    if thingbottomslope > p_map.topslope then
        return true -- shot under the thing
    end

    -- this thing can be hit!
    if thingtopslope > p_map.topslope then
        thingtopslope = p_map.topslope
    end

    if thingbottomslope < p_map.bottomslope then
        thingbottomslope = p_map.bottomslope
    end

    p_map.aimslope = (thingtopslope + thingbottomslope) // 2
    p_map.linetarget = th

    return false -- don't go any farther
end

-- PTR_ShootTraverse.
function p_map.PTR_ShootTraverse(in_)
    local x
    local y
    local z
    local frac

    local li

    local th

    local slope
    local dist
    local thingtopslope
    local thingbottomslope

    if in_.isaline then
        li = in_.line

        if li.special ~= 0 then
            p_spec.P_ShootSpecialLine(p_map.shootthing, li)
        end

        if bit32.band(li.flags, 4) == 0 then -- ML_TWOSIDED
            return p_map.HitLine(li, in_)
        end

        -- crosses a two sided line
        p_maputl.P_LineOpening(li)

        dist = m_fixed.FixedMul(p_map.attackrange, in_.frac)

        -- e6y: emulation of missed back side on two-sided lines.
        -- backsector can be NULL when emulating missing back side.
        if li.backsector == nil then
            slope = m_fixed.FixedDiv(p_maputl.openbottom - p_map.shootz, dist)
            if slope > p_map.aimslope then
                -- hit line (share the code below via a local helper)
                return p_map.HitLine(li, in_)
            end

            slope = m_fixed.FixedDiv(p_maputl.opentop - p_map.shootz, dist)
            if slope < p_map.aimslope then
                return p_map.HitLine(li, in_)
            end
        else
            if li.frontsector.floorheight ~= li.backsector.floorheight then
                slope = m_fixed.FixedDiv(p_maputl.openbottom - p_map.shootz, dist)
                if slope > p_map.aimslope then
                    return p_map.HitLine(li, in_)
                end
            end

            if li.frontsector.ceilingheight ~= li.backsector.ceilingheight then
                slope = m_fixed.FixedDiv(p_maputl.opentop - p_map.shootz, dist)
                if slope < p_map.aimslope then
                    return p_map.HitLine(li, in_)
                end
            end
        end

        -- shot continues
        return true
    end

    -- shoot a thing
    th = in_.thing
    if th == p_map.shootthing then
        return true -- can't shoot self
    end

    if bit32.band(th.flags, p_mobj.MF_SHOOTABLE) == 0 then
        return true -- corpse or something
    end

    -- check angles to see if the thing can be aimed at
    dist = m_fixed.FixedMul(p_map.attackrange, in_.frac)
    thingtopslope = m_fixed.FixedDiv(th.z + th.height - p_map.shootz, dist)

    if thingtopslope < p_map.aimslope then
        return true -- shot over the thing
    end

    thingbottomslope = m_fixed.FixedDiv(th.z - p_map.shootz, dist)

    if thingbottomslope > p_map.aimslope then
        return true -- shot under the thing
    end

    -- hit thing
    -- position a bit closer
    frac = in_.frac - m_fixed.FixedDiv(10 * FRACUNIT, p_map.attackrange)

    x = p_maputl.trace.x + m_fixed.FixedMul(p_maputl.trace.dx, frac)
    y = p_maputl.trace.y + m_fixed.FixedMul(p_maputl.trace.dy, frac)
    z = p_map.shootz + m_fixed.FixedMul(p_map.aimslope,
        m_fixed.FixedMul(frac, p_map.attackrange))

    -- Spawn bullet puffs or blood spots, depending on target type.
    if bit32.band(in_.thing.flags, p_mobj.MF_NOBLOOD) ~= 0 then
        p_mobj.P_SpawnPuff(x, y, z)
    else
        p_mobj.P_SpawnBlood(x, y, z, p_map.la_damage)
    end

    if p_map.la_damage ~= 0 then
        p_inter.P_DamageMobj(th, p_map.shootthing, p_map.shootthing, p_map.la_damage)
    end

    -- don't go any farther
    return false
end

-- Shared "hit line" body for PTR_ShootTraverse (the C goto hitline).
function p_map.HitLine(li, in_)
    local x
    local y
    local z
    local frac

    -- position a bit closer
    frac = in_.frac - m_fixed.FixedDiv(4 * FRACUNIT, p_map.attackrange)
    x = p_maputl.trace.x + m_fixed.FixedMul(p_maputl.trace.dx, frac)
    y = p_maputl.trace.y + m_fixed.FixedMul(p_maputl.trace.dy, frac)
    z = p_map.shootz + m_fixed.FixedMul(p_map.aimslope,
        m_fixed.FixedMul(frac, p_map.attackrange))

    if li.frontsector.ceilingpic == r_state.skyflatnum then
        -- don't shoot the sky!
        if z > li.frontsector.ceilingheight then
            return false
        end

        -- it's a sky hack wall
        if li.backsector and li.backsector.ceilingpic == r_state.skyflatnum then
            return false
        end
    end

    -- Spawn bullet puffs.
    p_mobj.P_SpawnPuff(x, y, z)

    -- don't go any farther
    return false
end

-- ---------------------------------------------------------------------------
-- P_AimLineAttack
-- ---------------------------------------------------------------------------

function p_map.P_AimLineAttack(t1, angle, distance)
    local x2
    local y2

    t1 = p_mobj.P_SubstNullMobj(t1)

    local fineangle = bit32.rshift(angle, 19) -- ANGLETOFINESHIFT
    p_map.shootthing = t1

    x2 = t1.x + (distance // FRACUNIT) * tables.finesine[fineangle + 1 + 2048]
    y2 = t1.y + (distance // FRACUNIT) * tables.finesine[fineangle + 1]
    p_map.shootz = t1.z + (t1.height // 2) + 8 * FRACUNIT

    -- can't shoot outside view angles
    p_map.topslope = 100 * FRACUNIT // 160
    p_map.bottomslope = -100 * FRACUNIT // 160

    p_map.attackrange = distance
    p_map.linetarget = nil

    p_maputl.P_PathTraverse(t1.x, t1.y, x2, y2,
        3, -- PT_ADDLINES|PT_ADDTHINGS
        p_map.PTR_AimTraverse)

    if p_map.linetarget then
        return p_map.aimslope
    end

    return 0
end

-- ---------------------------------------------------------------------------
-- P_LineAttack
-- If damage == 0, it is just a test trace that will leave linetarget set.
-- ---------------------------------------------------------------------------

function p_map.P_LineAttack(t1, angle, distance, slope, damage)
    local x2
    local y2

    local fineangle = bit32.rshift(angle, 19) -- ANGLETOFINESHIFT
    p_map.shootthing = t1
    p_map.la_damage = damage
    x2 = t1.x + (distance // FRACUNIT) * tables.finesine[fineangle + 1 + 2048]
    y2 = t1.y + (distance // FRACUNIT) * tables.finesine[fineangle + 1]
    p_map.shootz = t1.z + (t1.height // 2) + 8 * FRACUNIT
    p_map.attackrange = distance
    p_map.aimslope = slope

    p_maputl.P_PathTraverse(t1.x, t1.y, x2, y2,
        3, -- PT_ADDLINES|PT_ADDTHINGS
        p_map.PTR_ShootTraverse)
end

-- ---------------------------------------------------------------------------
-- USE LINES
-- ---------------------------------------------------------------------------

p_map.usething = nil

-- PTR_UseTraverse.
function p_map.PTR_UseTraverse(in_)
    local side

    if in_.line.special == 0 then
        p_maputl.P_LineOpening(in_.line)
        if p_maputl.openrange <= 0 then
            s_sound.S_StartSound(p_map.usething, sounds.sfxenum.sfx_noway)

            -- can't use through a wall
            return false
        end
        -- not a special line, but keep checking
        return true
    end

    side = 0
    if p_maputl.P_PointOnLineSide(p_map.usething.x, p_map.usething.y, in_.line) == 1 then
        side = 1
    end

    -- return false;  // don't use back side

    p_spec.P_UseSpecialLine(p_map.usething, in_.line, side)

    -- can't use for more than one special line in a row
    return false
end

-- P_UseLines: looks for special lines in front of the player to activate.
function p_map.P_UseLines(player)
    local angle
    local x1
    local y1
    local x2
    local y2

    p_map.usething = player.mo

    angle = bit32.rshift(player.mo.angle, 19) -- ANGLETOFINESHIFT

    x1 = player.mo.x
    y1 = player.mo.y
    x2 = x1 + (64 * FRACUNIT // FRACUNIT) * tables.finesine[angle + 1 + 2048] -- USERANGE>>FRACBITS
    y2 = y1 + (64 * FRACUNIT // FRACUNIT) * tables.finesine[angle + 1]

    p_maputl.P_PathTraverse(x1, y1, x2, y2, 1, p_map.PTR_UseTraverse) -- PT_ADDLINES
end

-- ---------------------------------------------------------------------------
-- RADIUS ATTACK
-- ---------------------------------------------------------------------------

p_map.bombsource = nil
p_map.bombspot = nil
p_map.bombdamage = 0

-- PIT_RadiusAttack: "bombsource" is the creature that caused the explosion
-- at "bombspot".
function p_map.PIT_RadiusAttack(thing)
    local dx
    local dy
    local dist

    if bit32.band(thing.flags, p_mobj.MF_SHOOTABLE) == 0 then
        return true
    end

    -- Boss spider and cyborg take no damage from concussion.
    if thing.type == info.mobjtype.MT_CYBORG
        or thing.type == info.mobjtype.MT_SPIDER then
        return true
    end

    dx = math.abs(thing.x - p_map.bombspot.x)
    dy = math.abs(thing.y - p_map.bombspot.y)

    dist = dx > dy and dx or dy
    dist = (dist - thing.radius) // FRACUNIT

    if dist < 0 then
        dist = 0
    end

    if dist >= p_map.bombdamage then
        return true -- out of range
    end

    if p_sight.P_CheckSight(thing, p_map.bombspot) then
        -- must be in direct path
        p_inter.P_DamageMobj(thing, p_map.bombspot, p_map.bombsource,
            p_map.bombdamage - dist)
    end

    return true
end

-- P_RadiusAttack: source is the creature that caused the explosion at spot.
function p_map.P_RadiusAttack(spot, source, damage)
    local x
    local y

    local xl
    local xh
    local yl
    local yh

    local dist

    dist = (damage + MAXRADIUS) * FRACUNIT -- << FRACBITS
    yh = (spot.y + dist - r_state.bmaporgy) // 2 ^ MAPBLOCKSHIFT
    yl = (spot.y - dist - r_state.bmaporgy) // 2 ^ MAPBLOCKSHIFT
    xh = (spot.x + dist - r_state.bmaporgx) // 2 ^ MAPBLOCKSHIFT
    xl = (spot.x - dist - r_state.bmaporgx) // 2 ^ MAPBLOCKSHIFT
    p_map.bombspot = spot
    p_map.bombsource = source
    p_map.bombdamage = damage

    for y = yl, yh do -- TODO: Script exhaustion; wrong numbers provided to process, range way too high
        for x = xl, xh do
            p_maputl.P_BlockThingsIterator(x, y, p_map.PIT_RadiusAttack)
        end
    end
end

-- ---------------------------------------------------------------------------
-- SECTOR HEIGHT CHANGING
-- ---------------------------------------------------------------------------

p_map.crushchange = false
p_map.nofit = false

-- PIT_ChangeSector.
function p_map.PIT_ChangeSector(thing)
    local mo

    if p_map.P_ThingHeightClip(thing) then
        -- keep checking
        return true
    end

    -- crunch bodies to giblets
    if thing.health <= 0 then
        p_mobj.P_SetMobjState(thing, info.statenum.S_GIBS)

        thing.flags = bit32.band(thing.flags, bit32.bnot(p_mobj.MF_SOLID))
        thing.height = 0
        thing.radius = 0

        -- keep checking
        return true
    end

    -- crunch dropped items
    if bit32.band(thing.flags, p_mobj.MF_DROPPED) ~= 0 then
        p_mobj.P_RemoveMobj(thing)

        -- keep checking
        return true
    end

    if bit32.band(thing.flags, p_mobj.MF_SHOOTABLE) == 0 then
        -- assume it is bloody gibs or something
        return true
    end

    p_map.nofit = true

    if p_map.crushchange and bit32.band(doomstat.leveltime, 3) ~= 0 then
        p_inter.P_DamageMobj(thing, nil, nil, 10)

        -- spray blood in a random direction
        mo = p_mobj.P_SpawnMobj(thing.x, thing.y, thing.z + thing.height // 2,
            info.mobjtype.MT_BLOOD)

        mo.momx = (m_random.P_Random() - m_random.P_Random()) * 4096 -- <<12
        mo.momy = (m_random.P_Random() - m_random.P_Random()) * 4096
    end

    -- keep checking (crush other things)
    return true
end

-- P_ChangeSector.
function p_map.P_ChangeSector(sector, crunch)
    local x
    local y

    p_map.nofit = false
    p_map.crushchange = crunch

    -- re-check heights for all things near the moving sector
    for x = sector.blockbox[m_bbox.BOXLEFT], sector.blockbox[m_bbox.BOXRIGHT] do
        for y = sector.blockbox[m_bbox.BOXBOTTOM], sector.blockbox[m_bbox.BOXTOP] do
            p_maputl.P_BlockThingsIterator(x, y, p_map.PIT_ChangeSector)
        end
    end

    return p_map.nofit
end

return p_map
end)()

p_maputl = (function()
local p_maputl = {}

-- MAPBLOCK constants (p_local.h).
local FRACUNIT = m_fixed.FRACUNIT
local MAPBLOCKSIZE = 128 * FRACUNIT -- 8388608
local MAPBLOCKSHIFT = 23 -- FRACBITS+7
local MAPBTOFRAC = 7 -- MAPBLOCKSHIFT-FRACBITS
local FRACUNIT_MASK = FRACUNIT - 1 -- 0xffff

-- ---------------------------------------------------------------------------
-- P_AproxDistance
-- Gives an estimation of distance (not exact).
-- ---------------------------------------------------------------------------

function p_maputl.P_AproxDistance(dx, dy)
    dx = math.abs(dx)
    dy = math.abs(dy)
    if dx < dy then
        return dx + dy - (dx // 2) -- dx+dy-(dx>>1)
    end
    return dx + dy - (dy // 2) -- dx+dy-(dy>>1)
end

-- ---------------------------------------------------------------------------
-- P_PointOnLineSide
-- Returns 0 or 1.
-- ---------------------------------------------------------------------------

function p_maputl.P_PointOnLineSide(x, y, line)
    local dx
    local dy
    local left
    local right

    if line.dx == 0 then
        if x <= line.v1.x then
            return line.dy > 0 and 1 or 0
        end
        return line.dy < 0 and 1 or 0
    end
    if line.dy == 0 then
        if y <= line.v1.y then
            return line.dx < 0 and 1 or 0
        end
        return line.dx > 0 and 1 or 0
    end

    dx = x - line.v1.x
    dy = y - line.v1.y

    left = m_fixed.FixedMul(line.dy // FRACUNIT, dx)
    right = m_fixed.FixedMul(dy, line.dx // FRACUNIT)

    if right < left then
        return 0 -- front side
    end
    return 1 -- back side
end

-- ---------------------------------------------------------------------------
-- P_BoxOnLineSide
-- Considers the line to be infinite.
-- Returns side 0 or 1, -1 if box crosses the line.
-- ---------------------------------------------------------------------------

function p_maputl.P_BoxOnLineSide(tmbox, ld)
    local p1 = 0
    local p2 = 0

    if ld.slopetype == 0 then -- ST_HORIZONTAL
        p1 = tmbox[m_bbox.BOXTOP] > ld.v1.y and 1 or 0
        p2 = tmbox[m_bbox.BOXBOTTOM] > ld.v1.y and 1 or 0
        if ld.dx < 0 then
            p1 = bit32.bxor(p1, 1)
            p2 = bit32.bxor(p2, 1)
        end
    elseif ld.slopetype == 1 then -- ST_VERTICAL
        p1 = tmbox[m_bbox.BOXRIGHT] < ld.v1.x and 1 or 0
        p2 = tmbox[m_bbox.BOXLEFT] < ld.v1.x and 1 or 0
        if ld.dy < 0 then
            p1 = bit32.bxor(p1, 1)
            p2 = bit32.bxor(p2, 1)
        end
    elseif ld.slopetype == 2 then -- ST_POSITIVE
        p1 = p_maputl.P_PointOnLineSide(tmbox[m_bbox.BOXLEFT], tmbox[m_bbox.BOXTOP], ld)
        p2 = p_maputl.P_PointOnLineSide(tmbox[m_bbox.BOXRIGHT], tmbox[m_bbox.BOXBOTTOM], ld)
    else -- ST_NEGATIVE
        p1 = p_maputl.P_PointOnLineSide(tmbox[m_bbox.BOXRIGHT], tmbox[m_bbox.BOXTOP], ld)
        p2 = p_maputl.P_PointOnLineSide(tmbox[m_bbox.BOXLEFT], tmbox[m_bbox.BOXBOTTOM], ld)
    end

    if p1 == p2 then
        return p1
    end
    return -1
end

-- ---------------------------------------------------------------------------
-- P_PointOnDivlineSide
-- Returns 0 or 1.
-- ---------------------------------------------------------------------------

function p_maputl.P_PointOnDivlineSide(x, y, line)
    local dx
    local dy
    local left
    local right

    if line.dx == 0 then
        if x <= line.x then
            return line.dy > 0 and 1 or 0
        end
        return line.dy < 0 and 1 or 0
    end
    if line.dy == 0 then
        if y <= line.y then
            return line.dx < 0 and 1 or 0
        end
        return line.dx > 0 and 1 or 0
    end

    dx = x - line.x
    dy = y - line.y

    -- try to quickly decide by looking at sign bits
    if bit32.band(bit32.bxor(line.dy % 0x100000000, line.dx % 0x100000000,
        dx % 0x100000000, dy % 0x100000000), 0x80000000) ~= 0 then
        if bit32.band(bit32.bxor(line.dy % 0x100000000, dx % 0x100000000),
            0x80000000) ~= 0 then
            return 1 -- (left is negative)
        end
        return 0
    end

    left = m_fixed.FixedMul(line.dy // 256, dx // 256) -- dy>>8, dx>>8
    right = m_fixed.FixedMul(dy // 256, line.dx // 256)

    if right < left then
        return 0 -- front side
    end
    return 1 -- back side
end

-- ---------------------------------------------------------------------------
-- P_MakeDivline
-- ---------------------------------------------------------------------------

function p_maputl.P_MakeDivline(li, dl)
    dl.x = li.v1.x
    dl.y = li.v1.y
    dl.dx = li.dx
    dl.dy = li.dy
end

-- ---------------------------------------------------------------------------
-- P_InterceptVector
-- Returns the fractional intercept point along the first divline.
-- ---------------------------------------------------------------------------

function p_maputl.P_InterceptVector(v2, v1)
    local frac
    local num
    local den

    den = m_fixed.FixedMul(v1.dy // 256, v2.dx) - m_fixed.FixedMul(v1.dx // 256, v2.dy)

    if den == 0 then
        return 0 -- parallel
    end

    num = m_fixed.FixedMul((v1.x - v2.x) // 256, v1.dy)
        + m_fixed.FixedMul((v2.y - v1.y) // 256, v1.dx)

    frac = m_fixed.FixedDiv(num, den)

    return frac
end

-- ---------------------------------------------------------------------------
-- P_LineOpening
-- Sets opentop and openbottom to the window through a two sided line.
-- ---------------------------------------------------------------------------

p_maputl.opentop = 0
p_maputl.openbottom = 0
p_maputl.openrange = 0
p_maputl.lowfloor = 0

function p_maputl.P_LineOpening(linedef)
    local front
    local back

    if linedef.sidenum[2] == -1 then -- [1] in C (0-based index 1)
        -- single sided line
        p_maputl.openrange = 0
        return
    end

    front = linedef.frontsector
    back = linedef.backsector

    if front.ceilingheight < back.ceilingheight then
        p_maputl.opentop = front.ceilingheight
    else
        p_maputl.opentop = back.ceilingheight
    end

    if front.floorheight > back.floorheight then
        p_maputl.openbottom = front.floorheight
        p_maputl.lowfloor = back.floorheight
    else
        p_maputl.openbottom = back.floorheight
        p_maputl.lowfloor = front.floorheight
    end

    p_maputl.openrange = p_maputl.opentop - p_maputl.openbottom
end

-- ---------------------------------------------------------------------------
-- P_UnsetThingPosition
-- Unlinks a thing from block map and sectors.
-- ---------------------------------------------------------------------------

function p_maputl.P_UnsetThingPosition(thing)
    local S = r_state
    local blockx
    local blocky

    if bit32.band(thing.flags, 8) == 0 then -- MF_NOSECTOR
        -- inert things don't need to be in blockmap?
        -- unlink from subsector
        if thing.snext then
            thing.snext.sprev = thing.sprev
        end

        if thing.sprev then
            thing.sprev.snext = thing.snext
        elseif thing.subsector then
            thing.subsector.sector.thinglist = thing.snext
        end
    end

    if bit32.band(thing.flags, 16) == 0 then -- MF_NOBLOCKMAP
        -- inert things don't need to be in blockmap
        -- unlink from block map
        if thing.bnext then
            thing.bnext.bprev = thing.bprev
        end

        if thing.bprev then
            thing.bprev.bnext = thing.bnext
        else
            blockx = (thing.x - S.bmaporgx) // 2 ^ MAPBLOCKSHIFT
            blocky = (thing.y - S.bmaporgy) // 2 ^ MAPBLOCKSHIFT

            if blockx >= 0 and blockx < S.bmapwidth
                and blocky >= 0 and blocky < S.bmapheight then
                S.blocklinks[blocky * S.bmapwidth + blockx] = thing.bnext
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- P_SetThingPosition
-- Links a thing into both a block and a subsector based on its x y.
-- Sets thing.subsector properly.
-- ---------------------------------------------------------------------------

function p_maputl.P_SetThingPosition(thing)
    local S = r_state
    local ss
    local sec
    local blockx
    local blocky
    local link

    -- link into subsector
    ss = r_main.R_PointInSubsector(thing.x, thing.y)
    thing.subsector = ss

    if bit32.band(thing.flags, 8) == 0 then -- MF_NOSECTOR
        -- invisible things don't go into the sector links
        sec = ss.sector

        thing.sprev = nil
        thing.snext = sec.thinglist

        if sec.thinglist then
            sec.thinglist.sprev = thing
        end

        sec.thinglist = thing
    end

    -- link into blockmap
    if bit32.band(thing.flags, 16) == 0 then -- MF_NOBLOCKMAP
        -- inert things don't need to be in blockmap
        blockx = (thing.x - S.bmaporgx) // 2 ^ MAPBLOCKSHIFT
        blocky = (thing.y - S.bmaporgy) // 2 ^ MAPBLOCKSHIFT

        if blockx >= 0 and blockx < S.bmapwidth
            and blocky >= 0 and blocky < S.bmapheight then
            local idx = blocky * S.bmapwidth + blockx
            link = S.blocklinks[idx]
            thing.bprev = nil
            thing.bnext = link
            if link then
                link.bprev = thing
            end
            S.blocklinks[idx] = thing
        else
            -- thing is off the map
            thing.bnext = nil
            thing.bprev = nil
        end
    end
end

-- ---------------------------------------------------------------------------
-- BLOCK MAP ITERATORS
-- For each line/thing in the given mapblock, call the passed PIT_* function.
-- If the function returns false, exit with false without checking anything
-- else.
-- ---------------------------------------------------------------------------

-- P_BlockLinesIterator: the validcount flags are used to avoid checking lines
-- that are marked in multiple mapblocks.

function p_maputl.P_BlockLinesIterator(x, y, func)
    local S = r_state

    if x < 0 or y < 0 or x >= S.bmapwidth or y >= S.bmapheight then
        return true
    end

    local offset = y * S.bmapwidth + x

    offset = S.blockmaplump[S.blockmap + offset + 1]

    local i = S.blockmap + offset
    while S.blockmaplump[i + 1] ~= -1 do
        local ld = r_state.lines[S.blockmaplump[i + 1] + 1]

        if ld.validcount ~= S.validcount then
            -- line has not already been checked
            ld.validcount = S.validcount

            if not func(ld) then
                return false
            end
        end
        i = i + 1
    end
    return true -- everything was checked
end

-- P_BlockThingsIterator.
function p_maputl.P_BlockThingsIterator(x, y, func)
    local S = r_state

    if x < 0 or y < 0 or x >= S.bmapwidth or y >= S.bmapheight then
        return true
    end

    local mobj = S.blocklinks[y * S.bmapwidth + x]
    while mobj do
        if not func(mobj) then
            return false
        end
        mobj = mobj.bnext
    end
    return true
end

-- ---------------------------------------------------------------------------
-- INTERCEPT ROUTINES
-- ---------------------------------------------------------------------------

local MAXINTERCEPTS_ORIGINAL = 128
local MAXINTERCEPTS = MAXINTERCEPTS_ORIGINAL + 61

-- Preallocate the intercept slots (C: static intercepts[MAXINTERCEPTS]).
local intercepts = {}
for _ = 1, MAXINTERCEPTS do
    table.insert(intercepts, { frac = 0, isaline = false, line = nil, thing = nil })
end
p_maputl.intercepts = intercepts

local intercept_p = 1 -- C: intercept_t* intercept_p (0-based; Lua 1-based)

p_maputl.trace = { x = 0, y = 0, dx = 0, dy = 0 } -- divline_t trace
local earlyout = false
local ptflags = 0

local INT_MAX = 2147483647

-- Intercepts Overrun emulation, from PrBoom-plus. When the intercepts table
-- overflows (numspechit > MAXINTERCEPTS_ORIGINAL), Vanilla Doom writes the
-- overflowing intercept fields over adjacent memory. We emulate the writes
-- onto the Lua globals that live at those addresses.
--
-- C table (intercepts_overrun[]): {len, addr, int16_array}. NULL addrs are
-- variables that the port does not keep (earlyout, intercept_p, activeplats,
-- swingx/swingy, blocklinks, blockmap, blockmaplump).

-- bulletslope lives in p_pspr; write through a lazily-required hook.
local function write_bulletslope(value)
    p_pspr.bulletslope = value
end

local intercepts_overrun = {
    { len = 4,   write = nil },                            -- unused
    { len = 4,   write = nil },                            -- earlyout
    { len = 4,   write = nil },                            -- intercept_p
    { len = 4,   write = function(v) p_maputl.lowfloor = v end },
    { len = 4,   write = function(v) p_maputl.openbottom = v end },
    { len = 4,   write = function(v) p_maputl.opentop = v end },
    { len = 4,   write = function(v) p_maputl.openrange = v end },
    { len = 4,   write = nil },                            -- unused
    { len = 120, write = nil },                            -- activeplats
    { len = 8,   write = nil },                            -- unused
    { len = 4,   write = write_bulletslope },
    { len = 4,   write = nil },                            -- swingx
    { len = 4,   write = nil },                            -- swingy
    { len = 4,   write = nil },                            -- unused
    { len = 40,  int16 = true },                           -- playerstarts
    { len = 4,   write = nil },                            -- blocklinks
    { len = 4,   write = function(v) r_state.bmapwidth = v end },
    { len = 4,   write = nil },                            -- blockmap
    { len = 4,   write = function(v) r_state.bmaporgx = v end },
    { len = 4,   write = function(v) r_state.bmaporgy = v end },
    { len = 4,   write = nil },                            -- blockmaplump
    { len = 4,   write = function(v) r_state.bmapheight = v end },
    { len = 0,   write = nil },                            -- terminator
}

-- Overwrite a specific memory location with a value.
local function InterceptsMemoryOverrun(location, value)
    local i = 1
    local offset = 0
    local entry = intercepts_overrun[i]

    -- Search down the array until we find the right entry.
    while entry.len ~= 0 do
        if offset + entry.len > location then
            if entry.int16 then
                -- playerstarts: effectively an array of 16-bit ints.
                local index = (location - offset) // 2
                -- C writes two shorts into the short array that starts at
                -- playerstarts: index and index+1 map into the mapthing_t
                -- x/y/angle/type/options fields. The C array is laid out as
                -- mapthing_t playerstarts[MAXPLAYERS] (10 bytes each), so a
                -- short index i maps to field (i%5) of playerstarts[i//5].
                local ps = doomstat.playerstarts
                local base = index // 5
                local field = index % 5
                local p = ps[base + 1]
                if p == nil then
                    p = {}
                    ps[base + 1] = p
                end
                local fields = { "x", "y", "angle", "type", "options" }
                p[fields[field + 1]] = bit32.band(value, 0xffff)
                local p2 = ps[base + 1]
                if p2 == nil then
                    p2 = {}
                    ps[base + 1] = p2
                end
                p2[fields[(field % 5) + 1]] =
                    bit32.band(value // 0x10000, 0xffff)
            elseif entry.write then
                local index = (location - offset) // 4
                entry.write(value)
            end
            break
        end

        offset = offset + entry.len
        i = i + 1
        entry = intercepts_overrun[i]
    end
end

-- Emulate overruns of the intercepts[] array.
local function InterceptsOverrun(num_intercepts, intercept)
    local location

    if num_intercepts <= MAXINTERCEPTS_ORIGINAL then
        -- No overrun
        return
    end

    location = (num_intercepts - MAXINTERCEPTS_ORIGINAL - 1) * 12

    -- Overwrite memory that is overwritten in Vanilla Doom, using the values
    -- from the intercept structure.
    InterceptsMemoryOverrun(location, intercept.frac)
    InterceptsMemoryOverrun(location + 4, intercept.isaline and 1 or 0)
    InterceptsMemoryOverrun(location + 8, 0) -- d.thing pointer (not kept)
end

-- ---------------------------------------------------------------------------
-- PIT_AddLineIntercepts
-- Looks for lines in the given block that intercept the given trace to add
-- to the intercepts list.
-- ---------------------------------------------------------------------------

function p_maputl.PIT_AddLineIntercepts(ld)
    local s1
    local s2
    local frac
    local dl = {}

    -- avoid precision problems with two routines
    if p_maputl.trace.dx > 16 * FRACUNIT
        or p_maputl.trace.dy > 16 * FRACUNIT
        or p_maputl.trace.dx < -16 * FRACUNIT
        or p_maputl.trace.dy < -16 * FRACUNIT then
        s1 = p_maputl.P_PointOnDivlineSide(ld.v1.x, ld.v1.y, p_maputl.trace)
        s2 = p_maputl.P_PointOnDivlineSide(ld.v2.x, ld.v2.y, p_maputl.trace)
    else
        s1 = p_maputl.P_PointOnLineSide(p_maputl.trace.x, p_maputl.trace.y, ld)
        s2 = p_maputl.P_PointOnLineSide(
            p_maputl.trace.x + p_maputl.trace.dx,
            p_maputl.trace.y + p_maputl.trace.dy, ld)
    end

    if s1 == s2 then
        return true -- line isn't crossed
    end

    -- hit the line
    p_maputl.P_MakeDivline(ld, dl)
    frac = p_maputl.P_InterceptVector(p_maputl.trace, dl)

    if frac < 0 then
        return true -- behind source
    end

    -- try to early out the check
    if earlyout
        and frac < FRACUNIT
        and not ld.backsector then
        return false -- stop checking
    end

    local in_ = intercepts[intercept_p]
    in_.frac = frac
    in_.isaline = true
    in_.line = ld
    in_.thing = nil
    InterceptsOverrun(intercept_p - 1, in_) -- C passes (intercept_p - intercepts)
    intercept_p = intercept_p + 1

    return true -- continue
end

-- ---------------------------------------------------------------------------
-- PIT_AddThingIntercepts
-- ---------------------------------------------------------------------------

function p_maputl.PIT_AddThingIntercepts(thing)
    local x1
    local y1
    local x2
    local y2

    local s1
    local s2

    local tracepositive

    local dl = {}

    local frac

    tracepositive = bit32.band(bit32.bxor(
        p_maputl.trace.dx % 0x100000000, p_maputl.trace.dy % 0x100000000),
        0x80000000) == 0 -- (trace.dx ^ trace.dy) > 0

    -- check a corner to corner crossection for hit
    if tracepositive then
        x1 = thing.x - thing.radius
        y1 = thing.y + thing.radius

        x2 = thing.x + thing.radius
        y2 = thing.y - thing.radius
    else
        x1 = thing.x - thing.radius
        y1 = thing.y - thing.radius

        x2 = thing.x + thing.radius
        y2 = thing.y + thing.radius
    end

    s1 = p_maputl.P_PointOnDivlineSide(x1, y1, p_maputl.trace)
    s2 = p_maputl.P_PointOnDivlineSide(x2, y2, p_maputl.trace)

    if s1 == s2 then
        return true -- line isn't crossed
    end

    dl.x = x1
    dl.y = y1
    dl.dx = x2 - x1
    dl.dy = y2 - y1

    frac = p_maputl.P_InterceptVector(p_maputl.trace, dl)

    if frac < 0 then
        return true -- behind source
    end

    local in_ = intercepts[intercept_p]
    in_.frac = frac
    in_.isaline = false
    in_.thing = thing
    in_.line = nil
    InterceptsOverrun(intercept_p - 1, in_)
    intercept_p = intercept_p + 1

    return true -- keep going
end

-- ---------------------------------------------------------------------------
-- P_TraverseIntercepts
-- Returns true if the traverser function returns true for all lines.
-- ---------------------------------------------------------------------------

function p_maputl.P_TraverseIntercepts(func, maxfrac)
    local count = intercept_p - 1
    local dist
    local scan
    local in_

    in_ = nil

    while count > 0 do
        dist = INT_MAX
        for scan = 1, intercept_p - 1 do
            if intercepts[scan].frac < dist then
                dist = intercepts[scan].frac
                in_ = intercepts[scan]
            end
        end

        if dist > maxfrac then
            return true -- checked everything in range
        end

        if not func(in_) then
            return false -- don't bother going farther
        end

        in_.frac = INT_MAX
        count = count - 1
    end

    return true -- everything was traversed
end

-- ---------------------------------------------------------------------------
-- P_PathTraverse
-- Traces a line from x1,y1 to x2,y2, calling the traverser function for
-- each. Returns true if the traverser function returns true for all lines.
-- ---------------------------------------------------------------------------

function p_maputl.P_PathTraverse(x1, y1, x2, y2, flags, trav)
    local xt1
    local yt1
    local xt2
    local yt2

    local xstep
    local ystep

    local partial

    local xintercept
    local yintercept

    local mapx
    local mapy

    local mapxstep
    local mapystep

    local count

    local S = r_state

    earlyout = bit32.band(flags, 4) ~= 0 -- PT_EARLYOUT
    ptflags = flags

    S.validcount = S.validcount + 1
    intercept_p = 1

    if bit32.band((x1 - S.bmaporgx) % 0x100000000, MAPBLOCKSIZE - 1) == 0 then
        x1 = x1 + FRACUNIT -- don't side exactly on a line
    end

    if bit32.band((y1 - S.bmaporgy) % 0x100000000, MAPBLOCKSIZE - 1) == 0 then
        y1 = y1 + FRACUNIT -- don't side exactly on a line
    end

    p_maputl.trace.x = x1
    p_maputl.trace.y = y1
    p_maputl.trace.dx = x2 - x1
    p_maputl.trace.dy = y2 - y1

    x1 = x1 - S.bmaporgx
    y1 = y1 - S.bmaporgy
    xt1 = x1 // 2 ^ MAPBLOCKSHIFT
    yt1 = y1 // 2 ^ MAPBLOCKSHIFT

    x2 = x2 - S.bmaporgx
    y2 = y2 - S.bmaporgy
    xt2 = x2 // 2 ^ MAPBLOCKSHIFT
    yt2 = y2 // 2 ^ MAPBLOCKSHIFT

    if xt2 > xt1 then
        mapxstep = 1
        partial = FRACUNIT - bit32.band(x1 // 2 ^ MAPBTOFRAC, FRACUNIT_MASK)
        ystep = m_fixed.FixedDiv(y2 - y1, math.abs(x2 - x1))
    elseif xt2 < xt1 then
        mapxstep = -1
        partial = bit32.band(x1 // 2 ^ MAPBTOFRAC, FRACUNIT_MASK)
        ystep = m_fixed.FixedDiv(y2 - y1, math.abs(x2 - x1))
    else
        mapxstep = 0
        partial = FRACUNIT
        ystep = 256 * FRACUNIT
    end

    yintercept = (y1 // 2 ^ MAPBTOFRAC) + m_fixed.FixedMul(partial, ystep)

    if yt2 > yt1 then
        mapystep = 1
        partial = FRACUNIT - bit32.band(y1 // 2 ^ MAPBTOFRAC, FRACUNIT_MASK)
        xstep = m_fixed.FixedDiv(x2 - x1, math.abs(y2 - y1))
    elseif yt2 < yt1 then
        mapystep = -1
        partial = bit32.band(y1 // 2 ^ MAPBTOFRAC, FRACUNIT_MASK)
        xstep = m_fixed.FixedDiv(x2 - x1, math.abs(y2 - y1))
    else
        mapystep = 0
        partial = FRACUNIT
        xstep = 256 * FRACUNIT
    end
    xintercept = (x1 // 2 ^ MAPBTOFRAC) + m_fixed.FixedMul(partial, xstep)

    -- Step through map blocks.
    -- Count is present to prevent a round off error from skipping the break.
    mapx = xt1
    mapy = yt1

    for count = 0, 63 do
        if bit32.band(flags, 1) ~= 0 then -- PT_ADDLINES
            if not p_maputl.P_BlockLinesIterator(mapx, mapy, p_maputl.PIT_AddLineIntercepts) then
                return false -- early out
            end
        end

        if bit32.band(flags, 2) ~= 0 then -- PT_ADDTHINGS
            if not p_maputl.P_BlockThingsIterator(mapx, mapy, p_maputl.PIT_AddThingIntercepts) then
                return false -- early out
            end
        end

        if mapx == xt2 and mapy == yt2 then
            break
        end

        if yintercept // FRACUNIT == mapy then
            yintercept = yintercept + ystep
            mapx = mapx + mapxstep
        elseif xintercept // FRACUNIT == mapx then
            xintercept = xintercept + xstep
            mapy = mapy + mapystep
        end
    end

    -- go through the sorted list
    return p_maputl.P_TraverseIntercepts(trav, FRACUNIT)
end

return p_maputl
end)()

p_plats = (function()
local p_plats = {}

local FRACUNIT = m_fixed.FRACUNIT
local TICRATE = doomtype.TICRATE
local PLATWAIT = 3
local PLATSPEED = FRACUNIT
local MAXPLATS = 30

-- plat_e (p_spec.h).
p_plats.up = 0
p_plats.down = 1
p_plats.waiting = 2
p_plats.in_stasis = 3

-- plattype_e (p_spec.h).
p_plats.perpetualRaise = 0
p_plats.downWaitUpStay = 1
p_plats.raiseAndChange = 2
p_plats.raiseToNearestAndChange = 3
p_plats.blazeDWUS = 4

-- Active plat list (C: plat_t* activeplats[MAXPLATS]).
p_plats.activeplats = {}
for _ = 1, MAXPLATS do
    table.insert(p_plats.activeplats, nil)
end

-- ---------------------------------------------------------------------------
-- T_PlatRaise
-- Move a plat up and down.
-- ---------------------------------------------------------------------------

function p_plats.T_PlatRaise(plat)
    local res

    if plat.status == p_plats.up then
        res = p_floor.T_MovePlane(plat.sector, plat.speed, plat.high,
            plat.crush, 0, 1)

        if plat.type == p_plats.raiseAndChange
            or plat.type == p_plats.raiseToNearestAndChange then
            if bit32.band(doomstat.leveltime, 7) == 0 then
                s_sound.S_StartSound(plat.sector.soundorg, sounds.sfxenum.sfx_stnmov)
            end
        end

        if res == p_floor.crushed and not plat.crush then
            plat.count = plat.wait
            plat.status = p_plats.down
            s_sound.S_StartSound(plat.sector.soundorg, sounds.sfxenum.sfx_pstart)
        else
            if res == p_floor.pastdest then
                plat.count = plat.wait
                plat.status = p_plats.waiting
                s_sound.S_StartSound(plat.sector.soundorg, sounds.sfxenum.sfx_pstop)

                if plat.type == p_plats.blazeDWUS
                    or plat.type == p_plats.downWaitUpStay
                    or plat.type == p_plats.raiseAndChange
                    or plat.type == p_plats.raiseToNearestAndChange then
                    p_plats.P_RemoveActivePlat(plat)
                end
            end
        end
    elseif plat.status == p_plats.down then
        res = p_floor.T_MovePlane(plat.sector, plat.speed, plat.low,
            false, 0, -1)

        if res == p_floor.pastdest then
            plat.count = plat.wait
            plat.status = p_plats.waiting
            s_sound.S_StartSound(plat.sector.soundorg, sounds.sfxenum.sfx_pstop)
        end
    elseif plat.status == p_plats.waiting then
        plat.count = plat.count - 1
        if plat.count == 0 then
            if plat.sector.floorheight == plat.low then
                plat.status = p_plats.up
            else
                plat.status = p_plats.down
            end
            s_sound.S_StartSound(plat.sector.soundorg, sounds.sfxenum.sfx_pstart)
        end
        -- fallthrough to in_stasis in C: both are no-ops
    elseif plat.status == p_plats.in_stasis then
        -- in stasis
    end
end

-- ---------------------------------------------------------------------------
-- EV_DoPlat
-- Do Platforms. "amount" is only used for SOME platforms.
-- ---------------------------------------------------------------------------

function p_plats.EV_DoPlat(line, type, amount)
    local plat
    local secnum
    local rtn
    local sec

    secnum = -1
    rtn = 0

    -- Activate all <type> plats that are in_stasis
    if type == p_plats.perpetualRaise then
        p_plats.P_ActivateInStasis(line.tag)
    end

    while true do
        secnum = p_spec.P_FindSectorFromLineTag(line, secnum)
        if secnum < 0 then
            break
        end

        sec = r_state.sectors[secnum + 1]

        if sec.specialdata then
            -- continue
        else
            -- Find lowest & highest floors around sector
            rtn = 1
            plat = {}
            p_tick.P_AddThinker(plat)

            plat.type = type
            plat.sector = sec
            plat.sector.specialdata = plat
            plat.thinkfunc = p_plats.T_PlatRaise
            plat.crush = false
            plat.tag = line.tag

            if type == p_plats.raiseToNearestAndChange then
                plat.speed = PLATSPEED // 2
                sec.floorpic = r_state.sides[line.sidenum[1] + 1].sector.floorpic
                plat.high = p_spec.P_FindNextHighestFloor(sec, sec.floorheight)
                plat.wait = 0
                plat.status = p_plats.up
                -- NO MORE DAMAGE, IF APPLICABLE
                sec.special = 0

                s_sound.S_StartSound(sec.soundorg, sounds.sfxenum.sfx_stnmov)
            elseif type == p_plats.raiseAndChange then
                plat.speed = PLATSPEED // 2
                sec.floorpic = r_state.sides[line.sidenum[1] + 1].sector.floorpic
                plat.high = sec.floorheight + amount * FRACUNIT
                plat.wait = 0
                plat.status = p_plats.up

                s_sound.S_StartSound(sec.soundorg, sounds.sfxenum.sfx_stnmov)
            elseif type == p_plats.downWaitUpStay then
                plat.speed = PLATSPEED * 4
                plat.low = p_spec.P_FindLowestFloorSurrounding(sec)

                if plat.low > sec.floorheight then
                    plat.low = sec.floorheight
                end

                plat.high = sec.floorheight
                plat.wait = TICRATE * PLATWAIT
                plat.status = p_plats.down
                s_sound.S_StartSound(sec.soundorg, sounds.sfxenum.sfx_pstart)
            elseif type == p_plats.blazeDWUS then
                plat.speed = PLATSPEED * 8
                plat.low = p_spec.P_FindLowestFloorSurrounding(sec)

                if plat.low > sec.floorheight then
                    plat.low = sec.floorheight
                end

                plat.high = sec.floorheight
                plat.wait = TICRATE * PLATWAIT
                plat.status = p_plats.down
                s_sound.S_StartSound(sec.soundorg, sounds.sfxenum.sfx_pstart)
            elseif type == p_plats.perpetualRaise then
                plat.speed = PLATSPEED
                plat.low = p_spec.P_FindLowestFloorSurrounding(sec)

                if plat.low > sec.floorheight then
                    plat.low = sec.floorheight
                end

                plat.high = p_spec.P_FindHighestFloorSurrounding(sec)

                if plat.high < sec.floorheight then
                    plat.high = sec.floorheight
                end

                plat.wait = TICRATE * PLATWAIT
                plat.status = bit32.band(m_random.P_Random(), 1)

                s_sound.S_StartSound(sec.soundorg, sounds.sfxenum.sfx_pstart)
            end
            p_plats.P_AddActivePlat(plat)
        end
    end
    return rtn
end

-- ---------------------------------------------------------------------------
-- P_ActivateInStasis
-- ---------------------------------------------------------------------------

function p_plats.P_ActivateInStasis(tag)
    for i = 1, MAXPLATS do
        local plat = p_plats.activeplats[i]
        if plat and plat.tag == tag and plat.status == p_plats.in_stasis then
            plat.status = plat.oldstatus
            plat.thinkfunc = p_plats.T_PlatRaise
        end
    end
end

-- ---------------------------------------------------------------------------
-- EV_StopPlat
-- ---------------------------------------------------------------------------

function p_plats.EV_StopPlat(line)
    for j = 1, MAXPLATS do
        local plat = p_plats.activeplats[j]
        if plat and plat.status ~= p_plats.in_stasis and plat.tag == line.tag then
            plat.oldstatus = plat.status
            plat.status = p_plats.in_stasis
            plat.thinkfunc = nil -- NULL action (in stasis)
        end
    end
end

-- ---------------------------------------------------------------------------
-- P_AddActivePlat
-- ---------------------------------------------------------------------------

function p_plats.P_AddActivePlat(plat)
    for i = 1, MAXPLATS do
        if p_plats.activeplats[i] == nil then
            p_plats.activeplats[i] = plat
            return
        end
    end
    i_system.I_Error("P_AddActivePlat: no more plats!")
end

-- ---------------------------------------------------------------------------
-- P_RemoveActivePlat
-- ---------------------------------------------------------------------------

function p_plats.P_RemoveActivePlat(plat)
    for i = 1, MAXPLATS do
        if plat == p_plats.activeplats[i] then
            p_plats.activeplats[i].sector.specialdata = nil
            p_tick.P_RemoveThinker(p_plats.activeplats[i])
            p_plats.activeplats[i] = nil
            return
        end
    end
    i_system.I_Error("P_RemoveActivePlat: can't find plat!")
end

return p_plats
end)()

p_pspr = (function()
local p_pspr = {}

local FRACUNIT = m_fixed.FRACUNIT
local FINEANGLES = doomtype.FINEANGLES
local FINEMASK = doomtype.FINEMASK
local ANG90 = doomtype.ANG90
local ANG180 = doomtype.ANG180

local LOWERSPEED = FRACUNIT * 6
local RAISESPEED = FRACUNIT * 6
local WEAPONBOTTOM = 128 * FRACUNIT
local WEAPONTOP = 32 * FRACUNIT
local MELEERANGE = 64 * FRACUNIT
local MISSILERANGE = 32 * 64 * FRACUNIT

local NUMPSPRITES = 2

-- ---------------------------------------------------------------------------
-- Psprite action registry (acp2: player, psp).
-- ---------------------------------------------------------------------------

local pspr_actions = {}
local warned_pspr = {}

function p_pspr.registerPsprAction(name, fn)
    pspr_actions[name] = fn
end

local function getPsprAction(name)
    if name == nil then
        return nil
    end
    local fn = pspr_actions[name]
    if fn == nil and not warned_pspr[name] then
        warned_pspr[name] = true
        print(string.format("p_pspr: psprite action %s not yet ported; no-op", name))
    end
    return fn
end

-- ---------------------------------------------------------------------------
-- P_SetPsprite
-- ---------------------------------------------------------------------------

function p_pspr.P_SetPsprite(player, position, stnum)
    local psp
    local state

    psp = player.psprites[position + 1]

    while true do
        if stnum == 0 then -- S_NULL
            -- object removed itself
            psp.state = nil
            break
        end

        state = info.states[stnum + 1]
        psp.state = state
        psp.tics = state.tics -- could be 0

        if state.misc1 ~= 0 then
            -- coordinate set
            psp.sx = state.misc1 * FRACUNIT -- << FRACBITS
            psp.sy = state.misc2 * FRACUNIT
        end

        -- Call action routine. Modified handling.
        local fn = getPsprAction(state.action)
        if fn then
            fn(player, psp)
            if not psp.state then
                break
            end
        end

        stnum = psp.state.nextstate

        if psp.tics ~= 0 then
            break
        end
    end
    -- an initial state of 0 could cycle through
end

-- ---------------------------------------------------------------------------
-- P_CalcSwing
-- ---------------------------------------------------------------------------

p_pspr.swingx = 0
p_pspr.swingy = 0

function p_pspr.P_CalcSwing(player)
    local swing
    local angle

    swing = player.bob

    angle = bit32.band(FINEANGLES // 70 * doomstat.leveltime, FINEMASK)
    p_pspr.swingx = m_fixed.FixedMul(swing, tables.finesine[angle + 1])

    angle = bit32.band(FINEANGLES // 70 * doomstat.leveltime + FINEANGLES // 2, FINEMASK)
    p_pspr.swingy = -m_fixed.FixedMul(p_pspr.swingx, tables.finesine[angle + 1])
end

-- ---------------------------------------------------------------------------
-- P_BringUpWeapon
-- Starts bringing the pending weapon up from the bottom of the screen.
-- ---------------------------------------------------------------------------

function p_pspr.P_BringUpWeapon(player)
    local newstate
    local weaponinfo = d_items.weaponinfo

    if player.pendingweapon == doomdef.wp_nochange then
        player.pendingweapon = player.readyweapon
    end

    if player.pendingweapon == doomdef.wp_chainsaw then
        s_sound.S_StartSound(player.mo, sounds.sfxenum.sfx_sawup)
    end

    newstate = weaponinfo[player.pendingweapon + 1].upstate

    player.pendingweapon = doomdef.wp_nochange
    player.psprites[1].sy = WEAPONBOTTOM -- ps_weapon = 0

    p_pspr.P_SetPsprite(player, 0, newstate)
end

-- ---------------------------------------------------------------------------
-- P_CheckAmmo
-- Returns true if there is enough ammo to shoot.
-- If not, selects the next weapon to use.
-- ---------------------------------------------------------------------------

function p_pspr.P_CheckAmmo(player)
    local ammo
    local count
    local weaponinfo = d_items.weaponinfo

    ammo = weaponinfo[player.readyweapon + 1].ammo

    -- Minimal amount for one shot varies.
    if player.readyweapon == doomdef.wp_bfg then
        count = deh_misc.deh_bfg_cells_per_shot
    elseif player.readyweapon == doomdef.wp_supershotgun then
        count = 2 -- Double barrel.
    else
        count = 1 -- Regular.
    end

    -- Some do not need ammunition anyway.
    -- Return if current ammunition sufficient.
    if ammo == doomdef.am_noammo or player.ammo[ammo + 1] >= count then
        return true
    end

    -- Out of ammo, pick a weapon to change to.
    -- Preferences are set here.
    while true do
        if player.weaponowned[doomdef.wp_plasma + 1]
            and player.ammo[doomdef.am_cell + 1] ~= 0
            and doomstat.gamemode ~= 0 then -- shareware
            player.pendingweapon = doomdef.wp_plasma
        elseif player.weaponowned[doomdef.wp_supershotgun + 1]
            and player.ammo[doomdef.am_shell + 1] > 2
            and doomstat.gamemode == 2 then -- commercial
            player.pendingweapon = doomdef.wp_supershotgun
        elseif player.weaponowned[doomdef.wp_chaingun + 1]
            and player.ammo[doomdef.am_clip + 1] ~= 0 then
            player.pendingweapon = doomdef.wp_chaingun
        elseif player.weaponowned[doomdef.wp_shotgun + 1]
            and player.ammo[doomdef.am_shell + 1] ~= 0 then
            player.pendingweapon = doomdef.wp_shotgun
        elseif player.ammo[doomdef.am_clip + 1] ~= 0 then
            player.pendingweapon = doomdef.wp_pistol
        elseif player.weaponowned[doomdef.wp_chainsaw + 1] then
            player.pendingweapon = doomdef.wp_chainsaw
        elseif player.weaponowned[doomdef.wp_missile + 1]
            and player.ammo[doomdef.am_misl + 1] ~= 0 then
            player.pendingweapon = doomdef.wp_missile
        elseif player.weaponowned[doomdef.wp_bfg + 1]
            and player.ammo[doomdef.am_cell + 1] > 40
            and doomstat.gamemode ~= 0 then -- shareware
            player.pendingweapon = doomdef.wp_bfg
        else
            -- If everything fails.
            player.pendingweapon = doomdef.wp_fist
        end

        if player.pendingweapon ~= doomdef.wp_nochange then
            break
        end
    end

    -- Now set appropriate weapon overlay.
    p_pspr.P_SetPsprite(player, 0, -- ps_weapon
        weaponinfo[player.readyweapon + 1].downstate)

    return false
end

-- ---------------------------------------------------------------------------
-- P_FireWeapon
-- ---------------------------------------------------------------------------

function p_pspr.P_FireWeapon(player)
    local newstate
    local weaponinfo = d_items.weaponinfo

    if not p_pspr.P_CheckAmmo(player) then
        return
    end

    p_mobj.P_SetMobjState(player.mo, info.statenum.S_PLAY_ATK1)
    newstate = weaponinfo[player.readyweapon + 1].atkstate
    p_pspr.P_SetPsprite(player, 0, newstate) -- ps_weapon
    p_enemy.P_NoiseAlert(player.mo, player.mo)
end

-- ---------------------------------------------------------------------------
-- P_DropWeapon
-- Player died, so put the weapon away.
-- ---------------------------------------------------------------------------

function p_pspr.P_DropWeapon(player)
    p_pspr.P_SetPsprite(player, 0, -- ps_weapon
        d_items.weaponinfo[player.readyweapon + 1].downstate)
end

-- ---------------------------------------------------------------------------
-- A_WeaponReady
-- The player can fire the weapon or change to another weapon at this time.
-- ---------------------------------------------------------------------------

function p_pspr.A_WeaponReady(player, psp)
    local newstate
    local angle

    -- get out of attack state
    if player.mo.state == info.states[info.statenum.S_PLAY_ATK1 + 1]
        or player.mo.state == info.states[info.statenum.S_PLAY_ATK2 + 1] then
        p_mobj.P_SetMobjState(player.mo, info.statenum.S_PLAY)
    end

    if player.readyweapon == doomdef.wp_chainsaw
        and psp.state == info.states[info.statenum.S_SAW + 1] then
        s_sound.S_StartSound(player.mo, sounds.sfxenum.sfx_sawidl)
    end

    -- check for change; if player is dead, put the weapon away
    if player.pendingweapon ~= doomdef.wp_nochange or player.health == 0 then
        -- change weapon (pending weapon should already be validated)
        newstate = d_items.weaponinfo[player.readyweapon + 1].downstate
        p_pspr.P_SetPsprite(player, 0, newstate)
        return
    end

    -- check for fire
    -- the missile launcher and bfg do not auto fire
    if bit32.band(player.cmd.buttons, 1) ~= 0 then -- BT_ATTACK
        if not player.attackdown
            or (player.readyweapon ~= doomdef.wp_missile
                and player.readyweapon ~= doomdef.wp_bfg) then
            player.attackdown = true
            p_pspr.P_FireWeapon(player)
            return
        end
    else
        player.attackdown = false
    end

    -- bob the weapon based on movement speed
    angle = bit32.band(128 * doomstat.leveltime, FINEMASK)
    psp.sx = FRACUNIT + m_fixed.FixedMul(player.bob, tables.finesine[angle + 1])
    angle = bit32.band(angle, FINEANGLES // 2 - 1)
    psp.sy = WEAPONTOP + m_fixed.FixedMul(player.bob, tables.finesine[angle + 1])
end

-- ---------------------------------------------------------------------------
-- A_ReFire
-- The player can re-fire the weapon without lowering it entirely.
-- ---------------------------------------------------------------------------

function p_pspr.A_ReFire(player, psp)
    -- check for fire
    -- (if a weaponchange is pending, let it go through instead)
    if bit32.band(player.cmd.buttons, 1) ~= 0 -- BT_ATTACK
        and player.pendingweapon == doomdef.wp_nochange
        and player.health ~= 0 then
        player.refire = player.refire + 1
        p_pspr.P_FireWeapon(player)
    else
        player.refire = 0
        p_pspr.P_CheckAmmo(player)
    end
end

-- A_CheckReload.
function p_pspr.A_CheckReload(player, psp)
    p_pspr.P_CheckAmmo(player)
end

-- ---------------------------------------------------------------------------
-- A_Lower
-- Lowers current weapon, and changes weapon at bottom.
-- ---------------------------------------------------------------------------

function p_pspr.A_Lower(player, psp)
    psp.sy = psp.sy + LOWERSPEED

    -- Is already down.
    if psp.sy < WEAPONBOTTOM then
        return
    end

    -- Player is dead.
    if player.playerstate == 1 then -- PST_DEAD
        psp.sy = WEAPONBOTTOM

        -- don't bring weapon back up
        return
    end

    -- The old weapon has been lowered off the screen, so change the weapon
    -- and start raising it.
    if player.health == 0 then
        -- Player is dead, so keep the weapon off screen.
        p_pspr.P_SetPsprite(player, 0, 0) -- S_NULL
        return
    end

    player.readyweapon = player.pendingweapon

    p_pspr.P_BringUpWeapon(player)
end

-- ---------------------------------------------------------------------------
-- A_Raise
-- ---------------------------------------------------------------------------

function p_pspr.A_Raise(player, psp)
    local newstate

    psp.sy = psp.sy - RAISESPEED

    if psp.sy > WEAPONTOP then
        return
    end

    psp.sy = WEAPONTOP

    -- The weapon has been raised all the way, so change to the ready state.
    newstate = d_items.weaponinfo[player.readyweapon + 1].readystate

    p_pspr.P_SetPsprite(player, 0, newstate)
end

-- ---------------------------------------------------------------------------
-- A_GunFlash
-- ---------------------------------------------------------------------------

function p_pspr.A_GunFlash(player, psp)
    p_mobj.P_SetMobjState(player.mo, info.statenum.S_PLAY_ATK2)
    p_pspr.P_SetPsprite(player, 1, -- ps_flash
        d_items.weaponinfo[player.readyweapon + 1].flashstate)
end

-- ---------------------------------------------------------------------------
-- WEAPON ATTACKS
-- ---------------------------------------------------------------------------

-- A_Punch.
function p_pspr.A_Punch(player, psp)
    local angle
    local damage
    local slope

    damage = (m_random.P_Random() % 10 + 1) * 2 -- <<1

    if player.powers[doomdef.pw_strength + 1] ~= 0 then
        damage = damage * 10
    end

    angle = player.mo.angle
    angle = (angle + doomtype.lshift32(
        m_random.P_Random() - m_random.P_Random(), 18)) % 0x100000000
    slope = p_map.P_AimLineAttack(player.mo, angle, MELEERANGE)
    p_map.P_LineAttack(player.mo, angle, MELEERANGE, slope, damage)

    -- turn to face target
    if p_map.linetarget then
        s_sound.S_StartSound(player.mo, sounds.sfxenum.sfx_punch)
        player.mo.angle = r_main.R_PointToAngle2(player.mo.x, player.mo.y,
            p_map.linetarget.x, p_map.linetarget.y) % 0x100000000
    end
end

-- A_Saw.
function p_pspr.A_Saw(player, psp)
    local angle
    local damage
    local slope

    damage = 2 * (m_random.P_Random() % 10 + 1)
    angle = player.mo.angle
    angle = (angle + doomtype.lshift32(
        m_random.P_Random() - m_random.P_Random(), 18)) % 0x100000000

    -- use meleerange + 1 so the puff doesn't skip the flash
    slope = p_map.P_AimLineAttack(player.mo, angle, MELEERANGE + 1)
    p_map.P_LineAttack(player.mo, angle, MELEERANGE + 1, slope, damage)

    if not p_map.linetarget then
        s_sound.S_StartSound(player.mo, sounds.sfxenum.sfx_sawful)
        return
    end
    s_sound.S_StartSound(player.mo, sounds.sfxenum.sfx_sawhit)

    -- turn to face target
    angle = r_main.R_PointToAngle2(player.mo.x, player.mo.y,
        p_map.linetarget.x, p_map.linetarget.y) % 0x100000000
    local delta = (angle - player.mo.angle) % 0x100000000
    local signed_delta = doomtype.u32_to_s32(delta)
    if delta > ANG180 then
        if signed_delta < -(ANG90 // 20) then
            player.mo.angle = (angle + ANG90 // 21) % 0x100000000
        else
            player.mo.angle = (player.mo.angle - ANG90 // 20) % 0x100000000
        end
    else
        if delta > ANG90 // 20 then
            player.mo.angle = (angle - ANG90 // 21) % 0x100000000
        else
            player.mo.angle = (player.mo.angle + ANG90 // 20) % 0x100000000
        end
    end
    player.mo.flags = bit32.bor(player.mo.flags, p_mobj.MF_JUSTATTACKED)
end

-- Doom does not check the bounds of the ammo array. As a result, it is
-- possible to use an ammo type > 4 that overflows into the maxammo array
-- and affects that instead (dehacked emulation). Keep the C behavior.

local function DecreaseAmmo(player, ammonum, amount)
    if ammonum < doomdef.NUMAMMO then
        player.ammo[ammonum + 1] = player.ammo[ammonum + 1] - amount
    else
        player.maxammo[ammonum - doomdef.NUMAMMO + 1] =
            player.maxammo[ammonum - doomdef.NUMAMMO + 1] - amount
    end
end

-- A_FireMissile.
function p_pspr.A_FireMissile(player, psp)
    DecreaseAmmo(player, d_items.weaponinfo[player.readyweapon + 1].ammo, 1)
    p_mobj.P_SpawnPlayerMissile(player.mo, info.mobjtype.MT_ROCKET)
end

-- A_FireBFG.
function p_pspr.A_FireBFG(player, psp)
    DecreaseAmmo(player, d_items.weaponinfo[player.readyweapon + 1].ammo,
        deh_misc.deh_bfg_cells_per_shot)
    p_mobj.P_SpawnPlayerMissile(player.mo, info.mobjtype.MT_BFG)
end

-- A_FirePlasma.
function p_pspr.A_FirePlasma(player, psp)
    DecreaseAmmo(player, d_items.weaponinfo[player.readyweapon + 1].ammo, 1)

    p_pspr.P_SetPsprite(player, 1, -- ps_flash
        d_items.weaponinfo[player.readyweapon + 1].flashstate
        + bit32.band(m_random.P_Random(), 1))

    p_mobj.P_SpawnPlayerMissile(player.mo, info.mobjtype.MT_PLASMA)
end

-- ---------------------------------------------------------------------------
-- P_BulletSlope
-- Sets a slope so a near miss is at approximately the height of the
-- intended target.
-- ---------------------------------------------------------------------------

p_pspr.bulletslope = 0

function p_pspr.P_BulletSlope(mo)
    local an

    -- see which target is to be aimed at
    an = mo.angle
    p_pspr.bulletslope = p_map.P_AimLineAttack(mo, an, 16 * 64 * FRACUNIT)

    if not p_map.linetarget then
        an = (an + 2 ^ 26) % 0x100000000 -- (1<<26)
        p_pspr.bulletslope = p_map.P_AimLineAttack(mo, an, 16 * 64 * FRACUNIT)
        if not p_map.linetarget then
            an = (an - 2 ^ 27) % 0x100000000 -- (2<<26)
            p_pspr.bulletslope = p_map.P_AimLineAttack(mo, an, 16 * 64 * FRACUNIT)
        end
    end
end

-- P_GunShot.
function p_pspr.P_GunShot(mo, accurate)
    local angle
    local damage

    damage = 5 * (m_random.P_Random() % 3 + 1)
    angle = mo.angle

    if not accurate then
        angle = (angle + doomtype.lshift32(
            m_random.P_Random() - m_random.P_Random(), 18)) % 0x100000000
    end

    p_map.P_LineAttack(mo, angle, MISSILERANGE, p_pspr.bulletslope, damage)
end

-- A_FirePistol.
function p_pspr.A_FirePistol(player, psp)
    s_sound.S_StartSound(player.mo, sounds.sfxenum.sfx_pistol)

    p_mobj.P_SetMobjState(player.mo, info.statenum.S_PLAY_ATK2)
    DecreaseAmmo(player, d_items.weaponinfo[player.readyweapon + 1].ammo, 1)

    p_pspr.P_SetPsprite(player, 1, -- ps_flash
        d_items.weaponinfo[player.readyweapon + 1].flashstate)

    p_pspr.P_BulletSlope(player.mo)
    p_pspr.P_GunShot(player.mo, not (player.refire ~= 0))
end

-- A_FireShotgun.
function p_pspr.A_FireShotgun(player, psp)
    local i

    s_sound.S_StartSound(player.mo, sounds.sfxenum.sfx_shotgn)
    p_mobj.P_SetMobjState(player.mo, info.statenum.S_PLAY_ATK2)

    DecreaseAmmo(player, d_items.weaponinfo[player.readyweapon + 1].ammo, 1)

    p_pspr.P_SetPsprite(player, 1, -- ps_flash
        d_items.weaponinfo[player.readyweapon + 1].flashstate)

    p_pspr.P_BulletSlope(player.mo)

    for i = 0, 6 do
        p_pspr.P_GunShot(player.mo, false)
    end
end

-- A_FireShotgun2.
function p_pspr.A_FireShotgun2(player, psp)
    local i
    local angle
    local damage

    s_sound.S_StartSound(player.mo, sounds.sfxenum.sfx_dshtgn)
    p_mobj.P_SetMobjState(player.mo, info.statenum.S_PLAY_ATK2)

    DecreaseAmmo(player, d_items.weaponinfo[player.readyweapon + 1].ammo, 2)

    p_pspr.P_SetPsprite(player, 1, -- ps_flash
        d_items.weaponinfo[player.readyweapon + 1].flashstate)

    p_pspr.P_BulletSlope(player.mo)

    for i = 0, 19 do
        damage = 5 * (m_random.P_Random() % 3 + 1)
        angle = player.mo.angle
        angle = (angle + doomtype.lshift32(
            m_random.P_Random() - m_random.P_Random(), 19)) % 0x100000000
        p_map.P_LineAttack(player.mo, angle, MISSILERANGE,
            p_pspr.bulletslope + doomtype.lshift32(
                m_random.P_Random() - m_random.P_Random(), 5), damage)
    end
end

-- A_FireCGun.
function p_pspr.A_FireCGun(player, psp)
    s_sound.S_StartSound(player.mo, sounds.sfxenum.sfx_pistol)

    if player.ammo[d_items.weaponinfo[player.readyweapon + 1].ammo + 1] == 0 then
        return
    end

    p_mobj.P_SetMobjState(player.mo, info.statenum.S_PLAY_ATK2)
    DecreaseAmmo(player, d_items.weaponinfo[player.readyweapon + 1].ammo, 1)

    p_pspr.P_SetPsprite(player, 1, -- ps_flash
        d_items.weaponinfo[player.readyweapon + 1].flashstate
        + (p_mobj.stateIndex(psp.state) - info.statenum.S_CHAIN1))

    p_pspr.P_BulletSlope(player.mo)

    p_pspr.P_GunShot(player.mo, not (player.refire ~= 0))
end

-- A_Light0 / A_Light1 / A_Light2.
function p_pspr.A_Light0(player, psp)
    player.extralight = 0
end

function p_pspr.A_Light1(player, psp)
    player.extralight = 1
end

function p_pspr.A_Light2(player, psp)
    player.extralight = 2
end

-- A_BFGsound.
function p_pspr.A_BFGsound(player, psp)
    s_sound.S_StartSound(player.mo, sounds.sfxenum.sfx_bfg)
end

-- ---------------------------------------------------------------------------
-- A_BFGSpray
-- Spawn a BFG explosion on every monster in view.
-- (mobj action, acp1: registered into p_mobj's registry below.)
-- ---------------------------------------------------------------------------

function p_pspr.A_BFGSpray(mo)
    local i
    local j
    local damage
    local an

    -- offset angles from its attack angle
    for i = 0, 39 do
        an = (mo.angle - ANG90 // 2 + ANG90 // 40 * i) % 0x100000000

        -- mo.target is the originator (player) of the missile
        p_map.P_AimLineAttack(mo.target, an, 16 * 64 * FRACUNIT)

        if not p_map.linetarget then
            -- continue
        else
            p_mobj.P_SpawnMobj(p_map.linetarget.x,
                p_map.linetarget.y,
                p_map.linetarget.z + (p_map.linetarget.height // 4), -- >>2
                info.mobjtype.MT_EXTRABFG)

            damage = 0
            for j = 0, 14 do
                damage = damage + (bit32.band(m_random.P_Random(), 7) + 1)
            end

            p_inter.P_DamageMobj(p_map.linetarget, mo.target, mo.target, damage)
        end
    end
end

-- ---------------------------------------------------------------------------
-- P_SetupPsprites
-- Called at start of level for each player.
-- ---------------------------------------------------------------------------

function p_pspr.P_SetupPsprites(player)
    local i

    -- remove all psprites
    for i = 1, NUMPSPRITES do
        player.psprites[i].state = nil
    end

    -- spawn the gun
    player.pendingweapon = player.readyweapon
    p_pspr.P_BringUpWeapon(player)
end

-- ---------------------------------------------------------------------------
-- P_MovePsprites
-- Called every tic by player thinking routine.
-- ---------------------------------------------------------------------------

function p_pspr.P_MovePsprites(player)
    local i
    local psp
    local state

    for i = 1, NUMPSPRITES do
        psp = player.psprites[i]
        state = psp.state

        -- a null state means not active
        if state then
            -- drop tic count and possibly change state

            -- a -1 tic count never changes
            if psp.tics ~= -1 then
                psp.tics = psp.tics - 1
                if psp.tics == 0 then
                    p_pspr.P_SetPsprite(player, i - 1, psp.state.nextstate)
                end
            end
        end
    end

    player.psprites[2].sx = player.psprites[1].sx -- ps_flash = player ps_weapon
    player.psprites[2].sy = player.psprites[1].sy
end

-- ---------------------------------------------------------------------------
-- Register the psprite actions.
-- ---------------------------------------------------------------------------

p_pspr.registerPsprAction("A_WeaponReady", p_pspr.A_WeaponReady)
p_pspr.registerPsprAction("A_Lower", p_pspr.A_Lower)
p_pspr.registerPsprAction("A_Raise", p_pspr.A_Raise)
p_pspr.registerPsprAction("A_ReFire", p_pspr.A_ReFire)
p_pspr.registerPsprAction("A_CheckReload", p_pspr.A_CheckReload)
p_pspr.registerPsprAction("A_GunFlash", p_pspr.A_GunFlash)
p_pspr.registerPsprAction("A_Punch", p_pspr.A_Punch)
p_pspr.registerPsprAction("A_Saw", p_pspr.A_Saw)
p_pspr.registerPsprAction("A_FireMissile", p_pspr.A_FireMissile)
p_pspr.registerPsprAction("A_FireBFG", p_pspr.A_FireBFG)
p_pspr.registerPsprAction("A_FirePlasma", p_pspr.A_FirePlasma)
p_pspr.registerPsprAction("A_FirePistol", p_pspr.A_FirePistol)
p_pspr.registerPsprAction("A_FireShotgun", p_pspr.A_FireShotgun)
p_pspr.registerPsprAction("A_FireShotgun2", p_pspr.A_FireShotgun2)
p_pspr.registerPsprAction("A_FireCGun", p_pspr.A_FireCGun)
p_pspr.registerPsprAction("A_Light0", p_pspr.A_Light0)
p_pspr.registerPsprAction("A_Light1", p_pspr.A_Light1)
p_pspr.registerPsprAction("A_Light2", p_pspr.A_Light2)
p_pspr.registerPsprAction("A_BFGsound", p_pspr.A_BFGsound)

-- A_BFGSpray is a mobj action (acp1).
p_mobj.registerMobjAction("A_BFGSpray", p_pspr.A_BFGSpray)

return p_pspr
end)()

p_setup = (function()
local p_setup = {}

-- Map lump order (doomdata.h ML_*).
local ML_THINGS = 1
local ML_LINEDEFS = 2
local ML_SIDEDEFS = 3
local ML_VERTEXES = 4
local ML_SEGS = 5
local ML_SSECTORS = 6
local ML_NODES = 7
local ML_SECTORS = 8
local ML_REJECT = 9
local ML_BLOCKMAP = 10

local ML_TWOSIDED = 4

local ST_VERTICAL = 0
local ST_HORIZONTAL = 1
local ST_POSITIVE = 2
local ST_NEGATIVE = 3

local MAPBLOCKSHIFT = 23 -- FRACBITS+7
local MAXRADIUS = 32 * m_fixed.FRACUNIT

-- Read an 8-byte lump/texture name from a buffer, stripping trailing NULs.
local function read_name(buf, off)
    local name = ""
    for i = 0, 7 do
        local c = buffer.readu8(buf, off + i)
        if c == 0 then
            break
        end
        name = name .. string.char(c)
    end
    return name
end

-- ---------------------------------------------------------------------------
-- P_LoadVertexes
-- ---------------------------------------------------------------------------

local function P_LoadVertexes(lump)
    r_state.numvertexes = w_wad.W_LumpLength(lump) // 4 -- mapvertex_t
    r_state.vertexes = {}

    local data = w_wad.W_CacheLumpNum(lump, z_zone.PU_STATIC)
    local db = data.buffer
    local dofs = data.offset

    for i = 0, r_state.numvertexes - 1 do
        r_state.vertexes[i + 1] = {
            x = buffer.readi16(db, dofs + i * 4) * m_fixed.FRACUNIT,
            y = buffer.readi16(db, dofs + i * 4 + 2) * m_fixed.FRACUNIT,
        }
    end
end

-- ---------------------------------------------------------------------------
-- P_LoadSectors
-- ---------------------------------------------------------------------------

local function P_LoadSectors(lump)
    r_state.numsectors = w_wad.W_LumpLength(lump) // 26 -- mapsector_t
    r_state.sectors = {}

    local data = w_wad.W_CacheLumpNum(lump, z_zone.PU_STATIC)
    local db = data.buffer
    local dofs = data.offset

    for i = 0, r_state.numsectors - 1 do
        local so = dofs + i * 26
        local sector = {
            index = i, -- sector number (C: sectors[i] - sectors; used by P_CheckSight / REJECT)
            floorheight = buffer.readi16(db, so) * m_fixed.FRACUNIT,
            ceilingheight = buffer.readi16(db, so + 2) * m_fixed.FRACUNIT,
            floorpic = r_data.R_FlatNumForName(read_name(db, so + 4)),
            ceilingpic = r_data.R_FlatNumForName(read_name(db, so + 12)),
            lightlevel = buffer.readi16(db, so + 20),
            special = buffer.readi16(db, so + 22),
            tag = buffer.readi16(db, so + 24),
            soundtraversed = 0,
            soundtarget = nil,
            blockbox = { 0, 0, 0, 0 },
            soundorg = { thinker = nil, x = 0, y = 0, z = 0 },
            validcount = 0,
            thinglist = nil,
            specialdata = nil,
            linecount = 0,
            lines = {},
        }
        r_state.sectors[i + 1] = sector
    end
end

-- ---------------------------------------------------------------------------
-- P_LoadSideDefs
-- ---------------------------------------------------------------------------

local function P_LoadSideDefs(lump)
    r_state.numsides = w_wad.W_LumpLength(lump) // 30 -- mapsidedef_t
    r_state.sides = {}

    local data = w_wad.W_CacheLumpNum(lump, z_zone.PU_STATIC)
    local db = data.buffer
    local dofs = data.offset

    for i = 0, r_state.numsides - 1 do
        local so = dofs + i * 30
        local side = {
            textureoffset = buffer.readi16(db, so) * m_fixed.FRACUNIT,
            rowoffset = buffer.readi16(db, so + 2) * m_fixed.FRACUNIT,
            toptexture = r_data.R_TextureNumForName(read_name(db, so + 4)),
            bottomtexture = r_data.R_TextureNumForName(read_name(db, so + 12)),
            midtexture = r_data.R_TextureNumForName(read_name(db, so + 20)),
            sector = r_state.sectors[buffer.readi16(db, so + 28) + 1],
        }
        r_state.sides[i + 1] = side
    end
end

-- ---------------------------------------------------------------------------
-- P_LoadLineDefs
-- ---------------------------------------------------------------------------

local function P_LoadLineDefs(lump)
    r_state.numlines = w_wad.W_LumpLength(lump) // 14 -- maplinedef_t
    r_state.lines = {}

    local data = w_wad.W_CacheLumpNum(lump, z_zone.PU_STATIC)
    local db = data.buffer
    local dofs = data.offset

    for i = 0, r_state.numlines - 1 do
        local lo = dofs + i * 14
        local v1 = r_state.vertexes[buffer.readi16(db, lo) + 1]
        local v2 = r_state.vertexes[buffer.readi16(db, lo + 2) + 1]
        local dx = v2.x - v1.x
        local dy = v2.y - v1.y

        local slopetype
        if dx == 0 then
            slopetype = ST_VERTICAL
        elseif dy == 0 then
            slopetype = ST_HORIZONTAL
        else
            if m_fixed.FixedDiv(dy, dx) > 0 then
                slopetype = ST_POSITIVE
            else
                slopetype = ST_NEGATIVE
            end
        end

        -- bbox is 1-based: BOXTOP=1, BOXBOTTOM=2, BOXLEFT=3, BOXRIGHT=4.
        local bbox = { 0, 0, 0, 0 }
        if v1.x < v2.x then
            bbox[3] = v1.x -- BOXLEFT
            bbox[4] = v2.x -- BOXRIGHT
        else
            bbox[3] = v2.x
            bbox[4] = v1.x
        end
        if v1.y < v2.y then
            bbox[2] = v1.y -- BOXBOTTOM
            bbox[1] = v2.y -- BOXTOP
        else
            bbox[2] = v2.y
            bbox[1] = v1.y
        end

        local line = {
            index = i,
            v1 = v1,
            v2 = v2,
            dx = dx,
            dy = dy,
            flags = buffer.readi16(db, lo + 4),
            special = buffer.readi16(db, lo + 6),
            tag = buffer.readi16(db, lo + 8),
            sidenum = {
                buffer.readi16(db, lo + 10),
                buffer.readi16(db, lo + 12),
            },
            bbox = bbox,
            slopetype = slopetype,
            frontsector = nil,
            backsector = nil,
            validcount = 0,
            specialdata = nil,
        }

        if line.sidenum[1] ~= -1 then
            line.frontsector = r_state.sides[line.sidenum[1] + 1].sector
        end
        if line.sidenum[2] ~= -1 then
            line.backsector = r_state.sides[line.sidenum[2] + 1].sector
        end

        r_state.lines[i + 1] = line
    end
end

-- ---------------------------------------------------------------------------
-- P_LoadSubsectors
-- ---------------------------------------------------------------------------

local function P_LoadSubsectors(lump)
    r_state.numsubsectors = w_wad.W_LumpLength(lump) // 4 -- mapsubsector_t
    r_state.subsectors = {}

    local data = w_wad.W_CacheLumpNum(lump, z_zone.PU_STATIC)
    local db = data.buffer
    local dofs = data.offset

    for i = 0, r_state.numsubsectors - 1 do
        r_state.subsectors[i + 1] = {
            sector = nil,
            numlines = buffer.readi16(db, dofs + i * 4),
            firstline = buffer.readi16(db, dofs + i * 4 + 2),
        }
    end
end

-- ---------------------------------------------------------------------------
-- P_LoadNodes
-- ---------------------------------------------------------------------------

local function P_LoadNodes(lump)
    r_state.numnodes = w_wad.W_LumpLength(lump) // 28 -- mapnode_t
    r_state.nodes = {}

    local data = w_wad.W_CacheLumpNum(lump, z_zone.PU_STATIC)
    local db = data.buffer
    local dofs = data.offset

    for i = 0, r_state.numnodes - 1 do
        local no = dofs + i * 28
        local bbox = { { 0, 0, 0, 0 }, { 0, 0, 0, 0 } }
        for j = 0, 1 do
            for k = 0, 3 do
                bbox[j + 1][k + 1] =
                    buffer.readi16(db, no + 8 + j * 8 + k * 2) * m_fixed.FRACUNIT
            end
        end

        r_state.nodes[i + 1] = {
            x = buffer.readi16(db, no) * m_fixed.FRACUNIT,
            y = buffer.readi16(db, no + 2) * m_fixed.FRACUNIT,
            dx = buffer.readi16(db, no + 4) * m_fixed.FRACUNIT,
            dy = buffer.readi16(db, no + 6) * m_fixed.FRACUNIT,
            bbox = bbox,
            children = {
                buffer.readu16(db, no + 24),
                buffer.readu16(db, no + 26),
            },
        }
    end
end

-- ---------------------------------------------------------------------------
-- P_LoadSegs
-- ---------------------------------------------------------------------------

local function P_LoadSegs(lump)
    r_state.numsegs = w_wad.W_LumpLength(lump) // 12 -- mapseg_t
    r_state.segs = {}

    local data = w_wad.W_CacheLumpNum(lump, z_zone.PU_STATIC)
    local db = data.buffer
    local dofs = data.offset

    -- GetSectorAtNullAddress: a zeroed sector for "glass hack" windows.
    local null_sector = {
        floorheight = 0, ceilingheight = 0, floorpic = 0, ceilingpic = 0,
        lightlevel = 0, special = 0, tag = 0, thinglist = nil,
    }

    for i = 0, r_state.numsegs - 1 do
        local so = dofs + i * 12
        local linedef = r_state.lines[buffer.readi16(db, so + 6) + 1]
        local side = buffer.readi16(db, so + 8)

        local seg = {
            v1 = r_state.vertexes[buffer.readi16(db, so) + 1],
            v2 = r_state.vertexes[buffer.readi16(db, so + 2) + 1],
            angle = (buffer.readi16(db, so + 4) * m_fixed.FRACUNIT) % 0x100000000,
            offset = buffer.readi16(db, so + 10) * m_fixed.FRACUNIT,
            sidedef = r_state.sides[linedef.sidenum[side + 1] + 1],
            linedef = linedef,
            frontsector = r_state.sides[linedef.sidenum[side + 1] + 1].sector,
            backsector = nil,
        }

        if bit32.band(linedef.flags, ML_TWOSIDED) ~= 0 then
            local sidenum = linedef.sidenum[(side == 0) and 2 or 1]
            if sidenum < 0 or sidenum >= r_state.numsides then
                seg.backsector = null_sector
            else
                seg.backsector = r_state.sides[sidenum + 1].sector
            end
        end

        r_state.segs[i + 1] = seg
    end
end

-- ---------------------------------------------------------------------------
-- P_LoadBlockMap
-- ---------------------------------------------------------------------------

local function P_LoadBlockMap(lump)
    local S = r_state
    local data = w_wad.W_CacheLumpNum(lump, z_zone.PU_LEVEL)
    local db = data.buffer
    local dofs = data.offset
    local count = data.size // 2

    -- Swap all short integers to native byte ordering (little-endian reads
    -- are already native) and store as a Lua array of shorts. Read as signed
    -- I16: the header orgs are signed shorts and the block lists end with -1.
    S.blockmaplump = {}
    for i = 0, count - 1 do
        S.blockmaplump[i + 1] = buffer.readi16(db, dofs + i * 2)
    end
    S.blockmap = 4 -- offsets in blockmap are from blockmaplump+4

    -- Read the header.
    S.bmaporgx = S.blockmaplump[1] * m_fixed.FRACUNIT -- << FRACBITS
    S.bmaporgy = S.blockmaplump[2] * m_fixed.FRACUNIT
    S.bmapwidth = S.blockmaplump[3]
    S.bmapheight = S.blockmaplump[4]

    -- Clear out mobj chains.
    S.blocklinks = {}
    local nblocks = S.bmapwidth * S.bmapheight
    for _ = 1, nblocks do
        table.insert(S.blocklinks, nil)
    end
end

-- ---------------------------------------------------------------------------
-- P_LoadReject
-- ---------------------------------------------------------------------------

-- Total number of lines in the level (C: static int totallines, set by
-- P_GroupLines and used to size the REJECT pad).
local totallines = 0

-- Pad the REJECT lump with extra data when the lump is too small, to
-- simulate a REJECT buffer overflow in Vanilla Doom.
local function PadRejectArray(buf, start, len)
    local i
    local rejectpad = {
        ((totallines * 4 + 3) // 4 * 4) + 24, -- Size ((x & ~3) + 24)
        0, -- Part of z_zone block header
        50, -- PU_LEVEL
        0x1d4a11, -- DOOM_CONST_ZONEID
    }

    local dest = start
    for i = 1, len do
        if i <= 16 then -- sizeof(rejectpad)
            local byte_num = (i - 1) % 4
            local v = rejectpad[(i - 1) // 4 + 1]
            buffer.writeu8(buf, dest, bit32.rshift(v, byte_num * 8) % 0x100)
        else
            break
        end
        dest = dest + 1
    end

    -- We only have a limited pad size. Print a warning if the REJECT lump is
    -- too small.
    if len > 16 then
        print(string.format(
            "PadRejectArray: REJECT lump too short to pad! (%i > %i)", len, 16))

        local padvalue
        if m_argv.M_CheckParm("-reject_pad_with_ff") ~= 0 then
            padvalue = 0xff
        else
            padvalue = 0xf00 -- memset with 0xf00 fills bytes with 0x00
        end

        buffer.fill(buf, start + 16, len - 16, padvalue % 0x100)
    end
end

local function P_LoadReject(lumpnum)
    local minlength
    local lumplen

    -- Calculate the size that the REJECT lump *should* be.
    minlength = (r_state.numsectors * r_state.numsectors + 7) // 8

    lumplen = w_wad.W_LumpLength(lumpnum)

    if lumplen >= minlength then
        r_state.rejectmatrix = w_wad.W_CacheLumpNum(lumpnum, z_zone.PU_LEVEL)
    else
        local buf = z_zone.Z_Malloc(minlength, z_zone.PU_LEVEL, nil)
        w_wad.W_ReadLump(lumpnum, buf, 0)
        PadRejectArray(buf, lumplen, minlength - lumplen)
        r_state.rejectmatrix = { buffer = buf, offset = 0, size = minlength }
    end
end

-- ---------------------------------------------------------------------------
-- P_LoadThings
-- ---------------------------------------------------------------------------

local function P_LoadThings(lump)
    local data = w_wad.W_CacheLumpNum(lump, z_zone.PU_STATIC)
    local db = data.buffer
    local dofs = data.offset
    local numthings = data.size // 10 -- mapthing_t

    for i = 0, numthings - 1 do
        local spawn = true

        -- Do not spawn cool, new monsters if !commercial.
        if doomstat.gamemode ~= d_mode.commercial then
            local t = buffer.readi16(db, dofs + i * 10 + 6)
            if t == 68 -- Arachnotron
                or t == 64 -- Archvile
                or t == 88 -- Boss Brain
                or t == 89 -- Boss Shooter
                or t == 69 -- Hell Knight
                or t == 67 -- Mancubus
                or t == 71 -- Pain Elemental
                or t == 65 -- Former Human Commando
                or t == 66 -- Revenant
                or t == 84 -- Wolf SS
            then
                spawn = false
            end
        end
        if not spawn then
            break
        end

        -- Do spawn all other stuff.
        local spawnthing = {
            x = buffer.readi16(db, dofs + i * 10),
            y = buffer.readi16(db, dofs + i * 10 + 2),
            angle = buffer.readi16(db, dofs + i * 10 + 4),
            type = buffer.readi16(db, dofs + i * 10 + 6),
            options = buffer.readi16(db, dofs + i * 10 + 8),
        }

        p_mobj.P_SpawnMapThing(spawnthing)
    end
end

-- ---------------------------------------------------------------------------
-- P_GroupLines: build sector line lists, subsector sector numbers, and
-- sector bounding boxes.
-- ---------------------------------------------------------------------------

local function P_GroupLines()
    -- Look up sector number for each subsector.
    for i = 1, r_state.numsubsectors do
        local ss = r_state.subsectors[i]
        ss.sector = r_state.segs[ss.firstline + 1].sidedef.sector
    end

    -- Count number of lines in each sector.
    totallines = 0
    for i = 1, r_state.numlines do
        local li = r_state.lines[i]
        totallines = totallines + 1
        if li.frontsector ~= nil then
            li.frontsector.linecount = li.frontsector.linecount + 1
        end

        if li.backsector ~= nil and li.backsector ~= li.frontsector then
            li.backsector.linecount = li.backsector.linecount + 1
            totallines = totallines + 1
        end
    end

    -- Assign lines to sectors (per-sector lists; the C uses a single shared
    -- linebuffer with cursor arithmetic, which is equivalent).
    for i = 1, r_state.numlines do
        local li = r_state.lines[i]
        if li.frontsector ~= nil then
            table.insert(li.frontsector.lines, li)
        end
        if li.backsector ~= nil and li.frontsector ~= li.backsector then
            table.insert(li.backsector.lines, li)
        end
    end

    -- Generate bounding boxes for sectors.
    for i = 1, r_state.numsectors do
        local sector = r_state.sectors[i]
        local bbox = { 0, 0, 0, 0 }
        m_bbox.M_ClearBox(bbox)

        for _, li in ipairs(sector.lines) do
            m_bbox.M_AddToBox(bbox, li.v1.x, li.v1.y)
            m_bbox.M_AddToBox(bbox, li.v2.x, li.v2.y)
        end

        -- Set the degenmobj_t to the middle of the bounding box.
        sector.soundorg.x = (bbox[4] + bbox[3]) // 2 -- (BOXRIGHT+BOXLEFT)/2
        sector.soundorg.y = (bbox[1] + bbox[2]) // 2 -- (BOXTOP+BOXBOTTOM)/2

        -- Adjust bounding box to map blocks.
        local block = (bbox[1] - r_state.bmaporgy + MAXRADIUS) // 2 ^ MAPBLOCKSHIFT -- BOXTOP
        if block >= r_state.bmapheight then
            block = r_state.bmapheight - 1
        end
        sector.blockbox[m_bbox.BOXTOP] = block

        block = (bbox[2] - r_state.bmaporgy - MAXRADIUS) // 2 ^ MAPBLOCKSHIFT -- BOXBOTTOM
        if block < 0 then
            block = 0
        end
        sector.blockbox[m_bbox.BOXBOTTOM] = block

        block = (bbox[4] - r_state.bmaporgx + MAXRADIUS) // 2 ^ MAPBLOCKSHIFT -- BOXRIGHT
        if block >= r_state.bmapwidth then
            block = r_state.bmapwidth - 1
        end
        sector.blockbox[m_bbox.BOXRIGHT] = block

        block = (bbox[3] - r_state.bmaporgx - MAXRADIUS) // 2 ^ MAPBLOCKSHIFT -- BOXLEFT
        if block < 0 then
            block = 0
        end
        sector.blockbox[m_bbox.BOXLEFT] = block
    end
end

-- ---------------------------------------------------------------------------
-- Sky setup (mirrors G_DoLoadLevel / G_InitNew in g_game.c).
-- ---------------------------------------------------------------------------

local function P_SetupSky()
    r_state.skyflatnum = r_data.R_FlatNumForName(deh_str.DEH_String("F_SKY1"))

    local skytexturename
    if doomstat.gamemode == d_mode.commercial
        and (doomstat.gameversion == d_mode.exe_final2
            or doomstat.gameversion == d_mode.exe_chex) then
        -- The "Sky never changes in Doom II" bug was fixed in the id
        -- Anthology version of doom2.exe for Final Doom.
        if doomstat.gamemap < 12 then
            skytexturename = "SKY1"
        elseif doomstat.gamemap < 21 then
            skytexturename = "SKY2"
        else
            skytexturename = "SKY3"
        end
    else
        if doomstat.gameepisode == 1 then
            skytexturename = "SKY1"
        elseif doomstat.gameepisode == 2 then
            skytexturename = "SKY2"
        elseif doomstat.gameepisode == 3 then
            skytexturename = "SKY3"
        else -- Special Edition sky.
            skytexturename = "SKY4"
        end
    end

    r_state.skytexture = r_data.R_TextureNumForName(
        deh_str.DEH_String(skytexturename))
end

-- ---------------------------------------------------------------------------
-- P_SetupLevel
-- ---------------------------------------------------------------------------

function p_setup.P_SetupLevel(episode, map, playermask, skill)
    local players = doomstat.players

    -- Reset intermission stats.
    doomstat.totalkills = 0
    doomstat.totalitems = 0
    doomstat.totalsecret = 0
    if doomstat.wminfo ~= nil then
        doomstat.wminfo.maxfrags = 0
        doomstat.wminfo.partime = 180
    end
    for i = 0, 4 - 1 do -- MAXPLAYERS
        if players[i + 1] ~= nil then
            players[i + 1].killcount = 0
            players[i + 1].secretcount = 0
            players[i + 1].itemcount = 0
        end
    end

    -- Initial height of PointOfView will be set by player think.
    if players[doomstat.consoleplayer + 1] ~= nil then
        players[doomstat.consoleplayer + 1].viewz = 1
    end

    -- Make sure all sounds are stopped before Z_FreeTags.
    s_sound.S_Start()

    z_zone.Z_FreeTags(z_zone.PU_LEVEL, z_zone.PU_PURGELEVEL - 1)
    p_tick.P_InitThinkers()

    -- Find map name.
    local lumpname
    if doomstat.gamemode == d_mode.commercial then
        if map < 10 then
            lumpname = string.format("map0%i", map)
        else
            lumpname = string.format("map%i", map)
        end
    else
        lumpname = string.format("E%iM%i", episode, map)
    end

    local lumpnum = w_wad.W_GetNumForName(lumpname)

    doomstat.leveltime = 0

    -- Note: most of this ordering is important.
    P_LoadBlockMap(lumpnum + ML_BLOCKMAP)
    P_LoadVertexes(lumpnum + ML_VERTEXES)
    P_LoadSectors(lumpnum + ML_SECTORS)
    P_LoadSideDefs(lumpnum + ML_SIDEDEFS)

    P_LoadLineDefs(lumpnum + ML_LINEDEFS)
    P_LoadSubsectors(lumpnum + ML_SSECTORS)
    P_LoadNodes(lumpnum + ML_NODES)
    P_LoadSegs(lumpnum + ML_SEGS)

    P_GroupLines()
    P_LoadReject(lumpnum + ML_REJECT)

    P_SetupSky()

    doomstat.bodyqueslot = 0
    doomstat.deathmatch_p = 1
    P_LoadThings(lumpnum + ML_THINGS)

    -- If deathmatch, randomly spawn the active players (multiplayer cut in
    -- v1; kept for parity).
    if doomstat.deathmatch ~= 0 then
        for i = 0, 4 - 1 do -- MAXPLAYERS
            if doomstat.playeringame[i + 1] then
                if players[i + 1] ~= nil then
                    players[i + 1].mo = nil
                end
                g_game.G_DeathMatchSpawnPlayer(i)
            end
        end
    end

    -- Clear special respawning que.
    p_mobj.iquehead = 0
    p_mobj.iquetail = 0

    -- Set up world state (sector specials; Phase 4c stub).
    p_spec.P_SpawnSpecials()

    -- Build subsector connect matrix (unused).

    -- Preload graphics.
    if doomstat.precache then
        r_data.R_PrecacheLevel()
    end
end

-- ---------------------------------------------------------------------------
-- P_Init
-- ---------------------------------------------------------------------------

function p_setup.P_Init()
    p_spec.P_InitSwitchList()
    p_spec.P_InitPicAnims()
    r_things.R_InitSprites(info.sprnames)
end

return p_setup
end)()

p_spec = (function()
local p_spec = {}

local FRACUNIT = m_fixed.FRACUNIT
local TICRATE = doomtype.TICRATE

local MAXANIMS = 32
local MAXLINEANIMS = 64
local MAXBUTTONS = 16

-- ---------------------------------------------------------------------------
-- anim_t / animdef_t (p_spec.c).
-- ---------------------------------------------------------------------------

-- animdefs: { istexture, endname, startname, speed }.
local animdefs = {
    { false, "NUKAGE3", "NUKAGE1", 8 },
    { false, "FWATER4", "FWATER1", 8 },
    { false, "SWATER4", "SWATER1", 8 },
    { false, "LAVA4", "LAVA1", 8 },
    { false, "BLOOD3", "BLOOD1", 8 },

    -- DOOM II flat animations.
    { false, "RROCK08", "RROCK05", 8 },
    { false, "SLIME04", "SLIME01", 8 },
    { false, "SLIME08", "SLIME05", 8 },
    { false, "SLIME12", "SLIME09", 8 },

    { true, "BLODGR4", "BLODGR1", 8 },
    { true, "SLADRIP3", "SLADRIP1", 8 },

    { true, "BLODRIP4", "BLODRIP1", 8 },
    { true, "FIREWALL", "FIREWALA", 8 },
    { true, "GSTFONT3", "GSTFONT1", 8 },
    { true, "FIRELAVA", "FIRELAV3", 8 },
    { true, "FIREMAG3", "FIREMAG1", 8 },
    { true, "FIREBLU2", "FIREBLU1", 8 },
    { true, "ROCKRED3", "ROCKRED1", 8 },

    { true, "BFALL4", "BFALL1", 8 },
    { true, "SFALL4", "SFALL1", 8 },
    { true, "WFALL4", "WFALL1", 8 },
    { true, "DBRAIN4", "DBRAIN1", 8 },

    { -1, "", "", 0 }, -- terminator
}

p_spec.anims = {}
for _ = 1, MAXANIMS do
    table.insert(p_spec.anims, {
        istexture = false, picnum = 0, basepic = 0, numpics = 0, speed = 0,
    })
end
p_spec.lastsanim = 1 -- C: anim_t* lastanim (1-based index into anims)

-- Line specials (p_spec.c).
p_spec.numlinespecials = 0
p_spec.linespeciallist = {}
for _ = 1, MAXLINEANIMS do
    table.insert(p_spec.linespeciallist, nil)
end

-- Level timer (-TIMER option).
p_spec.levelTimer = false
p_spec.levelTimeCount = 0

-- ---------------------------------------------------------------------------
-- P_InitSwitchList
-- (implemented in p_switch.luau; the C defines it in p_switch.c and
-- p_setup calls it via p_spec.h)
-- ---------------------------------------------------------------------------

function p_spec.P_InitSwitchList()
    p_switch.P_InitSwitchList()
end

-- ---------------------------------------------------------------------------
-- P_InitPicAnims
-- ---------------------------------------------------------------------------

function p_spec.P_InitPicAnims()
    -- Init animation
    p_spec.lastsanim = 1
    for i = 0, MAXANIMS - 1 do
        -- animdefs is a positional list: { istexture, endname, startname, speed }
        local ad = animdefs[i + 1]
        if ad[1] == -1 then
            break
        end

        local startname = deh_str.DEH_String(ad[3])
        local endname = deh_str.DEH_String(ad[2])

        local anim = p_spec.anims[p_spec.lastsanim]

        if ad[1] ~= 0 then
            -- different episode ?
            if r_data.R_CheckTextureNumForName(startname) == -1 then
                -- continue
            else
                anim.picnum = r_data.R_TextureNumForName(endname)
                anim.basepic = r_data.R_TextureNumForName(startname)
                anim.istexture = true
                anim.numpics = anim.picnum - anim.basepic + 1

                if anim.numpics < 2 then
                    i_system.I_Error("P_InitPicAnims: bad cycle from %s to %s",
                        startname, endname)
                end

                anim.speed = ad[4]
                p_spec.lastsanim = p_spec.lastsanim + 1
            end
        else
            if w_wad.W_CheckNumForName(startname) == -1 then
                -- continue
            else
                anim.picnum = r_data.R_FlatNumForName(endname)
                anim.basepic = r_data.R_FlatNumForName(startname)
                anim.istexture = false
                anim.numpics = anim.picnum - anim.basepic + 1

                if anim.numpics < 2 then
                    i_system.I_Error("P_InitPicAnims: bad cycle from %s to %s",
                        startname, endname)
                end

                anim.speed = ad[4]
                p_spec.lastsanim = p_spec.lastsanim + 1
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- UTILITIES
-- ---------------------------------------------------------------------------

-- getSide: return the side_t for the given sector/line/side.
function p_spec.getSide(currentSector, line, side)
    local lines = r_state.sectors[currentSector + 1].lines
    return r_state.sides[lines[line + 1].sidenum[side + 1] + 1]
end

-- getSector: return the sector_t for the given sector/line/side.
function p_spec.getSector(currentSector, line, side)
    local lines = r_state.sectors[currentSector + 1].lines
    return r_state.sides[lines[line + 1].sidenum[side + 1] + 1].sector
end

-- twoSided: tell whether the line is two-sided or not.
function p_spec.twoSided(sector, line)
    local flags = r_state.sectors[sector + 1].lines[line + 1].flags
    return bit32.band(flags, 4) -- ML_TWOSIDED
end

-- getNextSector: return sector_t of sector next to current.
-- NULL if not two-sided line.
function p_spec.getNextSector(line, sec)
    if bit32.band(line.flags, 4) == 0 then -- ML_TWOSIDED
        return nil
    end

    if line.frontsector == sec then
        return line.backsector
    end

    return line.frontsector
end

-- ---------------------------------------------------------------------------
-- P_FindLowestFloorSurrounding
-- FIND LOWEST FLOOR HEIGHT IN SURROUNDING SECTORS
-- ---------------------------------------------------------------------------

function p_spec.P_FindLowestFloorSurrounding(sec)
    local check
    local other
    local floor = sec.floorheight

    for i = 0, sec.linecount - 1 do
        check = sec.lines[i + 1]
        other = p_spec.getNextSector(check, sec)

        if other and other.floorheight < floor then
            floor = other.floorheight
        end
    end
    return floor
end

-- ---------------------------------------------------------------------------
-- P_FindHighestFloorSurrounding
-- FIND HIGHEST FLOOR HEIGHT IN SURROUNDING SECTORS
-- ---------------------------------------------------------------------------

function p_spec.P_FindHighestFloorSurrounding(sec)
    local check
    local other
    local floor = -500 * FRACUNIT

    for i = 0, sec.linecount - 1 do
        check = sec.lines[i + 1]
        other = p_spec.getNextSector(check, sec)

        if other and other.floorheight > floor then
            floor = other.floorheight
        end
    end
    return floor
end

-- ---------------------------------------------------------------------------
-- P_FindNextHighestFloor
-- FIND NEXT HIGHEST FLOOR IN SURROUNDING SECTORS
-- Note: this should be doable w/o a fixed array.
-- (Vanilla overflow emulation; 20 adjoining sectors max.)
-- ---------------------------------------------------------------------------

local MAX_ADJOINING_SECTORS = 20

function p_spec.P_FindNextHighestFloor(sec, currentheight)
    local h
    local min
    local check
    local other
    local height = currentheight
    local heightlist = {}

    h = 0
    for i = 0, sec.linecount - 1 do
        check = sec.lines[i + 1]
        other = p_spec.getNextSector(check, sec)

        if other and other.floorheight > height then
            -- Emulation of memory (stack) overflow
            if h == MAX_ADJOINING_SECTORS + 1 then
                height = other.floorheight
            elseif h == MAX_ADJOINING_SECTORS + 2 then
                -- Fatal overflow: game crashes at 22 textures
                i_system.I_Error("Sector with more than 22 adjoining sectors. "
                    .. "Vanilla will crash here")
            end

            heightlist[h + 1] = other.floorheight
            h = h + 1
        end
    end

    -- Find lowest height in list
    if h == 0 then
        return currentheight
    end

    min = heightlist[1]

    for i = 2, h do
        if heightlist[i] < min then
            min = heightlist[i]
        end
    end

    return min
end

-- ---------------------------------------------------------------------------
-- P_FindLowestCeilingSurrounding
-- FIND LOWEST CEILING IN THE SURROUNDING SECTORS
-- ---------------------------------------------------------------------------

function p_spec.P_FindLowestCeilingSurrounding(sec)
    local check
    local other
    local height = 2147483647 -- INT_MAX

    for i = 0, sec.linecount - 1 do
        check = sec.lines[i + 1]
        other = p_spec.getNextSector(check, sec)

        if other and other.ceilingheight < height then
            height = other.ceilingheight
        end
    end
    return height
end

-- ---------------------------------------------------------------------------
-- P_FindHighestCeilingSurrounding
-- FIND HIGHEST CEILING IN THE SURROUNDING SECTORS
-- ---------------------------------------------------------------------------

function p_spec.P_FindHighestCeilingSurrounding(sec)
    local check
    local other
    local height = 0

    for i = 0, sec.linecount - 1 do
        check = sec.lines[i + 1]
        other = p_spec.getNextSector(check, sec)

        if other and other.ceilingheight > height then
            height = other.ceilingheight
        end
    end
    return height
end

-- ---------------------------------------------------------------------------
-- P_FindSectorFromLineTag
-- RETURN NEXT SECTOR # THAT LINE TAG REFERS TO
-- ---------------------------------------------------------------------------

function p_spec.P_FindSectorFromLineTag(line, start)
    for i = start + 1, r_state.numsectors - 1 do
        if r_state.sectors[i + 1].tag == line.tag then
            return i
        end
    end

    return -1
end

-- ---------------------------------------------------------------------------
-- P_FindMinSurroundingLight
-- Find minimum light from an adjacent sector.
-- ---------------------------------------------------------------------------

function p_spec.P_FindMinSurroundingLight(sector, max)
    local min
    local line
    local check

    min = max
    for i = 0, sector.linecount - 1 do
        line = sector.lines[i + 1]
        check = p_spec.getNextSector(line, sector)

        if check and check.lightlevel < min then
            min = check.lightlevel
        end
    end
    return min
end

-- ---------------------------------------------------------------------------
-- EVENTS
-- ---------------------------------------------------------------------------

-- P_CrossSpecialLine - TRIGGER
-- Called every time a thing origin is about to cross a line with a non 0
-- special.
function p_spec.P_CrossSpecialLine(linenum, side, thing)
    local line
    local ok

    line = r_state.lines[linenum + 1]

    -- Triggers that other things can activate
    if not thing.player then
        -- Things that should NOT trigger specials...
        local ttype = thing.type
        if ttype == info.mobjtype.MT_ROCKET
            or ttype == info.mobjtype.MT_PLASMA
            or ttype == info.mobjtype.MT_BFG
            or ttype == info.mobjtype.MT_TROOPSHOT
            or ttype == info.mobjtype.MT_HEADSHOT
            or ttype == info.mobjtype.MT_BRUISERSHOT then
            return
        end

        ok = 0
        local sp = line.special
        if sp == 39 -- TELEPORT TRIGGER
            or sp == 97 -- TELEPORT RETRIGGER
            or sp == 125 -- TELEPORT MONSTERONLY TRIGGER
            or sp == 126 -- TELEPORT MONSTERONLY RETRIGGER
            or sp == 4 -- RAISE DOOR
            or sp == 10 -- PLAT DOWN-WAIT-UP-STAY TRIGGER
            or sp == 88 then -- PLAT DOWN-WAIT-UP-STAY RETRIGGER
            ok = 1
        end
        if ok == 0 then
            return
        end
    end

    -- Note: could use some const's here.
    local sp = line.special

    -- TRIGGERS.
    -- All from here to RETRIGGERS.
    if sp == 2 then
        -- Open Door
        p_doors.EV_DoDoor(line, p_doors.vld_open)
        line.special = 0
    elseif sp == 3 then
        -- Close Door
        p_doors.EV_DoDoor(line, p_doors.vld_close)
        line.special = 0
    elseif sp == 4 then
        -- Raise Door
        p_doors.EV_DoDoor(line, p_doors.vld_normal)
        line.special = 0
    elseif sp == 5 then
        -- Raise Floor
        p_floor.EV_DoFloor(line, p_floor.raiseFloor)
        line.special = 0
    elseif sp == 6 then
        -- Fast Ceiling Crush & Raise
        p_ceiling.EV_DoCeiling(line, p_ceiling.fastCrushAndRaise)
        line.special = 0
    elseif sp == 8 then
        -- Build Stairs
        p_floor.EV_BuildStairs(line, p_floor.build8)
        line.special = 0
    elseif sp == 10 then
        -- PlatDownWaitUp
        p_plats.EV_DoPlat(line, p_plats.downWaitUpStay, 0)
        line.special = 0
    elseif sp == 12 then
        -- Light Turn On - brightest near
        p_lights.EV_LightTurnOn(line, 0)
        line.special = 0
    elseif sp == 13 then
        -- Light Turn On 255
        p_lights.EV_LightTurnOn(line, 255)
        line.special = 0
    elseif sp == 16 then
        -- Close Door 30
        p_doors.EV_DoDoor(line, p_doors.vld_close30ThenOpen)
        line.special = 0
    elseif sp == 17 then
        -- Start Light Strobing
        p_lights.EV_StartLightStrobing(line)
        line.special = 0
    elseif sp == 19 then
        -- Lower Floor
        p_floor.EV_DoFloor(line, p_floor.lowerFloor)
        line.special = 0
    elseif sp == 22 then
        -- Raise floor to nearest height and change texture
        p_plats.EV_DoPlat(line, p_plats.raiseToNearestAndChange, 0)
        line.special = 0
    elseif sp == 25 then
        -- Ceiling Crush and Raise
        p_ceiling.EV_DoCeiling(line, p_ceiling.crushAndRaise)
        line.special = 0
    elseif sp == 30 then
        -- Raise floor to shortest texture height
        -- on either side of lines.
        p_floor.EV_DoFloor(line, p_floor.raiseToTexture)
        line.special = 0
    elseif sp == 35 then
        -- Lights Very Dark
        p_lights.EV_LightTurnOn(line, 35)
        line.special = 0
    elseif sp == 36 then
        -- Lower Floor (TURBO)
        p_floor.EV_DoFloor(line, p_floor.turboLower)
        line.special = 0
    elseif sp == 37 then
        -- LowerAndChange
        p_floor.EV_DoFloor(line, p_floor.lowerAndChange)
        line.special = 0
    elseif sp == 38 then
        -- Lower Floor To Lowest
        p_floor.EV_DoFloor(line, p_floor.lowerFloorToLowest)
        line.special = 0
    elseif sp == 39 then
        -- TELEPORT!
        p_telept.EV_Teleport(line, side, thing)
        line.special = 0
    elseif sp == 40 then
        -- RaiseCeilingLowerFloor
        p_ceiling.EV_DoCeiling(line, p_ceiling.raiseToHighest)
        p_floor.EV_DoFloor(line, p_floor.lowerFloorToLowest)
        line.special = 0
    elseif sp == 44 then
        -- Ceiling Crush
        p_ceiling.EV_DoCeiling(line, p_ceiling.lowerAndCrush)
        line.special = 0
    elseif sp == 52 then
        -- EXIT!
        g_game.G_ExitLevel()
    elseif sp == 53 then
        -- Perpetual Platform Raise
        p_plats.EV_DoPlat(line, p_plats.perpetualRaise, 0)
        line.special = 0
    elseif sp == 54 then
        -- Platform Stop
        p_plats.EV_StopPlat(line)
        line.special = 0
    elseif sp == 56 then
        -- Raise Floor Crush
        p_floor.EV_DoFloor(line, p_floor.raiseFloorCrush)
        line.special = 0
    elseif sp == 57 then
        -- Ceiling Crush Stop
        p_ceiling.EV_CeilingCrushStop(line)
        line.special = 0
    elseif sp == 58 then
        -- Raise Floor 24
        p_floor.EV_DoFloor(line, p_floor.raiseFloor24)
        line.special = 0
    elseif sp == 59 then
        -- Raise Floor 24 And Change
        p_floor.EV_DoFloor(line, p_floor.raiseFloor24AndChange)
        line.special = 0
    elseif sp == 104 then
        -- Turn lights off in sector(tag)
        p_lights.EV_TurnTagLightsOff(line)
        line.special = 0
    elseif sp == 108 then
        -- Blazing Door Raise (faster than TURBO!)
        p_doors.EV_DoDoor(line, p_doors.vld_blazeRaise)
        line.special = 0
    elseif sp == 109 then
        -- Blazing Door Open (faster than TURBO!)
        p_doors.EV_DoDoor(line, p_doors.vld_blazeOpen)
        line.special = 0
    elseif sp == 100 then
        -- Build Stairs Turbo 16
        p_floor.EV_BuildStairs(line, p_floor.turbo16)
        line.special = 0
    elseif sp == 110 then
        -- Blazing Door Close (faster than TURBO!)
        p_doors.EV_DoDoor(line, p_doors.vld_blazeClose)
        line.special = 0
    elseif sp == 119 then
        -- Raise floor to nearest surr. floor
        p_floor.EV_DoFloor(line, p_floor.raiseFloorToNearest)
        line.special = 0
    elseif sp == 121 then
        -- Blazing PlatDownWaitUpStay
        p_plats.EV_DoPlat(line, p_plats.blazeDWUS, 0)
        line.special = 0
    elseif sp == 124 then
        -- Secret EXIT
        g_game.G_SecretExitLevel()
    elseif sp == 125 then
        -- TELEPORT MonsterONLY
        if not thing.player then
            p_telept.EV_Teleport(line, side, thing)
            line.special = 0
        end
    elseif sp == 130 then
        -- Raise Floor Turbo
        p_floor.EV_DoFloor(line, p_floor.raiseFloorTurbo)
        line.special = 0
    elseif sp == 141 then
        -- Silent Ceiling Crush & Raise
        p_ceiling.EV_DoCeiling(line, p_ceiling.silentCrushAndRaise)
        line.special = 0

    -- RETRIGGERS.  All from here till end.
    elseif sp == 72 then
        -- Ceiling Crush
        p_ceiling.EV_DoCeiling(line, p_ceiling.lowerAndCrush)
    elseif sp == 73 then
        -- Ceiling Crush and Raise
        p_ceiling.EV_DoCeiling(line, p_ceiling.crushAndRaise)
    elseif sp == 74 then
        -- Ceiling Crush Stop
        p_ceiling.EV_CeilingCrushStop(line)
    elseif sp == 75 then
        -- Close Door
        p_doors.EV_DoDoor(line, p_doors.vld_close)
    elseif sp == 76 then
        -- Close Door 30
        p_doors.EV_DoDoor(line, p_doors.vld_close30ThenOpen)
    elseif sp == 77 then
        -- Fast Ceiling Crush & Raise
        p_ceiling.EV_DoCeiling(line, p_ceiling.fastCrushAndRaise)
    elseif sp == 79 then
        -- Lights Very Dark
        p_lights.EV_LightTurnOn(line, 35)
    elseif sp == 80 then
        -- Light Turn On - brightest near
        p_lights.EV_LightTurnOn(line, 0)
    elseif sp == 81 then
        -- Light Turn On 255
        p_lights.EV_LightTurnOn(line, 255)
    elseif sp == 82 then
        -- Lower Floor To Lowest
        p_floor.EV_DoFloor(line, p_floor.lowerFloorToLowest)
    elseif sp == 83 then
        -- Lower Floor
        p_floor.EV_DoFloor(line, p_floor.lowerFloor)
    elseif sp == 84 then
        -- LowerAndChange
        p_floor.EV_DoFloor(line, p_floor.lowerAndChange)
    elseif sp == 86 then
        -- Open Door
        p_doors.EV_DoDoor(line, p_doors.vld_open)
    elseif sp == 87 then
        -- Perpetual Platform Raise
        p_plats.EV_DoPlat(line, p_plats.perpetualRaise, 0)
    elseif sp == 88 then
        -- PlatDownWaitUp
        p_plats.EV_DoPlat(line, p_plats.downWaitUpStay, 0)
    elseif sp == 89 then
        -- Platform Stop
        p_plats.EV_StopPlat(line)
    elseif sp == 90 then
        -- Raise Door
        p_doors.EV_DoDoor(line, p_doors.vld_normal)
    elseif sp == 91 then
        -- Raise Floor
        p_floor.EV_DoFloor(line, p_floor.raiseFloor)
    elseif sp == 92 then
        -- Raise Floor 24
        p_floor.EV_DoFloor(line, p_floor.raiseFloor24)
    elseif sp == 93 then
        -- Raise Floor 24 And Change
        p_floor.EV_DoFloor(line, p_floor.raiseFloor24AndChange)
    elseif sp == 94 then
        -- Raise Floor Crush
        p_floor.EV_DoFloor(line, p_floor.raiseFloorCrush)
    elseif sp == 95 then
        -- Raise floor to nearest height and change texture.
        p_plats.EV_DoPlat(line, p_plats.raiseToNearestAndChange, 0)
    elseif sp == 96 then
        -- Raise floor to shortest texture height
        -- on either side of lines.
        p_floor.EV_DoFloor(line, p_floor.raiseToTexture)
    elseif sp == 97 then
        -- TELEPORT!
        p_telept.EV_Teleport(line, side, thing)
    elseif sp == 98 then
        -- Lower Floor (TURBO)
        p_floor.EV_DoFloor(line, p_floor.turboLower)
    elseif sp == 105 then
        -- Blazing Door Raise (faster than TURBO!)
        p_doors.EV_DoDoor(line, p_doors.vld_blazeRaise)
    elseif sp == 106 then
        -- Blazing Door Open (faster than TURBO!)
        p_doors.EV_DoDoor(line, p_doors.vld_blazeOpen)
    elseif sp == 107 then
        -- Blazing Door Close (faster than TURBO!)
        p_doors.EV_DoDoor(line, p_doors.vld_blazeClose)
    elseif sp == 120 then
        -- Blazing PlatDownWaitUpStay.
        p_plats.EV_DoPlat(line, p_plats.blazeDWUS, 0)
    elseif sp == 126 then
        -- TELEPORT MonsterONLY.
        if not thing.player then
            p_telept.EV_Teleport(line, side, thing)
        end
    elseif sp == 128 then
        -- Raise To Nearest Floor
        p_floor.EV_DoFloor(line, p_floor.raiseFloorToNearest)
    elseif sp == 129 then
        -- Raise Floor Turbo
        p_floor.EV_DoFloor(line, p_floor.raiseFloorTurbo)
    end
end

-- ---------------------------------------------------------------------------
-- P_ShootSpecialLine - IMPACT SPECIALS
-- Called when a thing shoots a special line.
-- ---------------------------------------------------------------------------

function p_spec.P_ShootSpecialLine(thing, line)
    local ok

    -- Impacts that other things can activate.
    if not thing.player then
        ok = 0
        if line.special == 46 then
            -- OPEN DOOR IMPACT
            ok = 1
        end
        if ok == 0 then
            return
        end
    end

    if line.special == 24 then
        -- RAISE FLOOR
        p_floor.EV_DoFloor(line, p_floor.raiseFloor)
        p_switch.P_ChangeSwitchTexture(line, 0)
    elseif line.special == 46 then
        -- OPEN DOOR
        p_doors.EV_DoDoor(line, p_doors.vld_open)
        p_switch.P_ChangeSwitchTexture(line, 1)
    elseif line.special == 47 then
        -- RAISE FLOOR NEAR AND CHANGE
        p_plats.EV_DoPlat(line, p_plats.raiseToNearestAndChange, 0)
        p_switch.P_ChangeSwitchTexture(line, 0)
    end
end

-- ---------------------------------------------------------------------------
-- P_PlayerInSpecialSector
-- Called every tic frame that the player origin is in a special sector.
-- ---------------------------------------------------------------------------

function p_spec.P_PlayerInSpecialSector(player)
    local sector

    sector = player.mo.subsector.sector

    -- Falling, not all the way down yet?
    if player.mo.z ~= sector.floorheight then
        return
    end

    -- Has hitten ground.

    if sector.special == 5 then
        -- HELLSLIME DAMAGE
        if player.powers[doomdef.pw_ironfeet + 1] == 0 then
            if bit32.band(doomstat.leveltime, 0x1f) == 0 then
                p_inter.P_DamageMobj(player.mo, nil, nil, 10)
            end
        end
    elseif sector.special == 7 then
        -- NUKAGE DAMAGE
        if player.powers[doomdef.pw_ironfeet + 1] == 0 then
            if bit32.band(doomstat.leveltime, 0x1f) == 0 then
                p_inter.P_DamageMobj(player.mo, nil, nil, 5)
            end
        end
    elseif sector.special == 16 or sector.special == 4 then
        -- SUPER HELLSLIME DAMAGE / STROBE HURT
        if player.powers[doomdef.pw_ironfeet + 1] == 0
            or m_random.P_Random() < 5 then
            if bit32.band(doomstat.leveltime, 0x1f) == 0 then
                p_inter.P_DamageMobj(player.mo, nil, nil, 20)
            end
        end
    elseif sector.special == 9 then
        -- SECRET SECTOR
        player.secretcount = player.secretcount + 1
        sector.special = 0
    elseif sector.special == 11 then
        -- EXIT SUPER DAMAGE! (for E1M8 finale)
        player.cheats = bit32.band(player.cheats, bit32.bnot(2)) -- CF_GODMODE

        if bit32.band(doomstat.leveltime, 0x1f) == 0 then
            p_inter.P_DamageMobj(player.mo, nil, nil, 20)
        end

        if player.health <= 10 then
            g_game.G_ExitLevel()
        end
    else
        i_system.I_Error("P_PlayerInSpecialSector: unknown special %i",
            sector.special)
    end
end

-- ---------------------------------------------------------------------------
-- P_UpdateSpecials
-- Animate planes, scroll walls, etc.
-- ---------------------------------------------------------------------------

function p_spec.P_UpdateSpecials()
    local anim
    local pic
    local line

    -- LEVEL TIMER
    if p_spec.levelTimer == true then
        p_spec.levelTimeCount = p_spec.levelTimeCount - 1
        if p_spec.levelTimeCount == 0 then
            g_game.G_ExitLevel()
        end
    end

    -- ANIMATE FLATS AND TEXTURES GLOBALLY
    for ai = 1, p_spec.lastsanim - 1 do
        anim = p_spec.anims[ai]
        for i = anim.basepic, anim.basepic + anim.numpics - 1 do
            pic = anim.basepic
                + (doomtype.truncdiv(doomstat.leveltime, anim.speed) + i) % anim.numpics
            if anim.istexture then
                r_state.texturetranslation[i + 1] = pic
            else
                r_state.flattranslation[i + 1] = pic
            end
        end
    end

    -- ANIMATE LINE SPECIALS
    for i = 0, p_spec.numlinespecials - 1 do
        line = p_spec.linespeciallist[i + 1]
        if line.special == 48 then
            -- EFFECT FIRSTCOL SCROLL +
            r_state.sides[line.sidenum[1] + 1].textureoffset =
                r_state.sides[line.sidenum[1] + 1].textureoffset + FRACUNIT
        end
    end

    -- DO BUTTONS
    for i = 1, MAXBUTTONS do
        local button = p_switch.buttonlist[i]
        if button.btimer ~= 0 then
            button.btimer = button.btimer - 1
            if button.btimer == 0 then
                local sides = r_state.sides[button.line.sidenum[1] + 1]
                if button.where == 0 then -- top
                    sides.toptexture = button.btexture
                elseif button.where == 1 then -- middle
                    sides.midtexture = button.btexture
                elseif button.where == 2 then -- bottom
                    sides.bottomtexture = button.btexture
                end
                s_sound.S_StartSound(button.soundorg, sounds.sfxenum.sfx_swtchn)
                button.line = nil
                button.where = 0
                button.btexture = 0
                button.btimer = 0
                button.soundorg = nil
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- EVENTS (P_UseSpecialLine is implemented in p_switch.luau)
-- ---------------------------------------------------------------------------

function p_spec.P_UseSpecialLine(thing, line, side)
    return p_switch.P_UseSpecialLine(thing, line, side)
end

-- ---------------------------------------------------------------------------
-- Donut overrun emulation (from PrBoom+, entryway).
-- ---------------------------------------------------------------------------

local DONUT_FLOORHEIGHT_DEFAULT = 0x00000000
local DONUT_FLOORPIC_DEFAULT = 0x16

local donut_first = true
local donut_tmp_s3_floorheight = 0
local donut_tmp_s3_floorpic = 0

local function DonutOverrun(s3_floorheight, s3_floorpic, line, pillar_sector)
    if donut_first then
        local p

        -- This is the first time we have had an overrun.
        donut_first = false

        -- Default values
        donut_tmp_s3_floorheight = DONUT_FLOORHEIGHT_DEFAULT
        donut_tmp_s3_floorpic = DONUT_FLOORPIC_DEFAULT

        -- -donut <x> <y>: use the specified magic values when emulating
        -- behavior caused by memory overruns from improperly constructed
        -- donuts.
        p = m_argv.M_CheckParmWithArgs("-donut", 2)

        if p > 0 then
            local v
            donut_tmp_s3_floorheight = 0
            v, _ = m_misc.M_StrToInt(m_argv.myargv[p + 1])
            donut_tmp_s3_floorheight = v
            v, _ = m_misc.M_StrToInt(m_argv.myargv[p + 2])
            donut_tmp_s3_floorpic = v

            if donut_tmp_s3_floorpic >= r_state.numflats then
                print(string.format(
                    "DonutOverrun: The second parameter for \"-donut\" "
                    .. "switch should be greater than 0 and less than number "
                    .. "of flats (%d). Using default value (%d) instead.",
                    r_state.numflats, DONUT_FLOORPIC_DEFAULT))
                donut_tmp_s3_floorpic = DONUT_FLOORPIC_DEFAULT
            end
        end
    end

    s3_floorheight.value = donut_tmp_s3_floorheight
    s3_floorpic.value = donut_tmp_s3_floorpic
end

-- ---------------------------------------------------------------------------
-- EV_DoDonut
-- Special Stuff that can not be categorized.
-- ---------------------------------------------------------------------------

function p_spec.EV_DoDonut(line)
    local s1
    local s2
    local s3
    local secnum
    local rtn
    local floor
    local s3_floorheight
    local s3_floorpic

    secnum = -1
    rtn = 0
    while true do
        secnum = p_spec.P_FindSectorFromLineTag(line, secnum)
        if secnum < 0 then
            break
        end

        s1 = r_state.sectors[secnum + 1]

        -- ALREADY MOVING?  IF SO, KEEP GOING...
        if s1.specialdata then
            -- continue
        else
            rtn = 1
            s2 = p_spec.getNextSector(s1.lines[1], s1)

            -- Vanilla Doom does not check if the linedef is one sided. The
            -- game does not crash, but reads invalid memory and causes the
            -- sector floor to move "down" to some unknown height. Print a
            -- warning and return.
            if s2 == nil then
                print("EV_DoDonut: linedef had no second sidedef! "
                    .. "Unexpected behavior may occur in Vanilla Doom.")
                break
            end

            for i = 0, s2.linecount - 1 do
                s3 = s2.lines[i + 1].backsector

                if s3 ~= s1 then
                    if s3 == nil then
                        -- e6y: s3 is NULL, so s3->floorheight is an int at
                        -- 0000:0000, s3->floorpic a short at 0000:0008.
                        print("EV_DoDonut: WARNING: emulating buffer overrun "
                            .. "due to NULL back sector. Unexpected behavior "
                            .. "may occur in Vanilla Doom.")

                        local h = { value = 0 }
                        local pic = { value = 0 }
                        DonutOverrun(h, pic, line, s1)
                        s3_floorheight = h.value
                        s3_floorpic = pic.value
                    else
                        s3_floorheight = s3.floorheight
                        s3_floorpic = s3.floorpic
                    end

                    -- Spawn rising slime
                    floor = {}
                    p_tick.P_AddThinker(floor)
                    s2.specialdata = floor
                    floor.thinkfunc = p_floor.T_MoveFloor
                    floor.type = p_floor.donutRaise
                    floor.crush = false
                    floor.direction = 1
                    floor.sector = s2
                    floor.speed = FRACUNIT // 2 -- FLOORSPEED/2
                    floor.texture = s3_floorpic
                    floor.newspecial = 0
                    floor.floordestheight = s3_floorheight

                    -- Spawn lowering donut-hole
                    floor = {}
                    p_tick.P_AddThinker(floor)
                    s1.specialdata = floor
                    floor.thinkfunc = p_floor.T_MoveFloor
                    floor.type = p_floor.lowerFloor
                    floor.crush = false
                    floor.direction = -1
                    floor.sector = s1
                    floor.speed = FRACUNIT // 2 -- FLOORSPEED/2
                    floor.floordestheight = s3_floorheight
                    break
                end
            end
        end
    end
    return rtn
end

-- ---------------------------------------------------------------------------
-- SPECIAL SPAWNING
-- ---------------------------------------------------------------------------

-- P_SpawnSpecials
-- After the map has been loaded, scan for specials that spawn thinkers.
function p_spec.P_SpawnSpecials()
    local sector

    -- See if -TIMER was specified.
    if doomstat.timelimit > 0 and doomstat.deathmatch ~= 0 then
        p_spec.levelTimer = true
        p_spec.levelTimeCount = doomstat.timelimit * 60 * TICRATE
    else
        p_spec.levelTimer = false
    end

    -- Init special SECTORs.
    for i = 1, r_state.numsectors do
        sector = r_state.sectors[i]
        if sector.special == 0 then
            -- continue
        elseif sector.special == 1 then
            -- FLICKERING LIGHTS
            p_lights.P_SpawnLightFlash(sector)
        elseif sector.special == 2 then
            -- STROBE FAST
            p_lights.P_SpawnStrobeFlash(sector, 15, 0) -- FASTDARK
        elseif sector.special == 3 then
            -- STROBE SLOW
            p_lights.P_SpawnStrobeFlash(sector, 35, 0) -- SLOWDARK
        elseif sector.special == 4 then
            -- STROBE FAST/DEATH SLIME
            p_lights.P_SpawnStrobeFlash(sector, 15, 0) -- FASTDARK
            sector.special = 4
        elseif sector.special == 8 then
            -- GLOWING LIGHT
            p_lights.P_SpawnGlowingLight(sector)
        elseif sector.special == 9 then
            -- SECRET SECTOR
            doomstat.totalsecret = doomstat.totalsecret + 1
        elseif sector.special == 10 then
            -- DOOR CLOSE IN 30 SECONDS
            p_doors.P_SpawnDoorCloseIn30(sector)
        elseif sector.special == 12 then
            -- SYNC STROBE SLOW
            p_lights.P_SpawnStrobeFlash(sector, 35, 1) -- SLOWDARK
        elseif sector.special == 13 then
            -- SYNC STROBE FAST
            p_lights.P_SpawnStrobeFlash(sector, 15, 1) -- FASTDARK
        elseif sector.special == 14 then
            -- DOOR RAISE IN 5 MINUTES
            p_doors.P_SpawnDoorRaiseIn5Mins(sector, i - 1)
        elseif sector.special == 17 then
            p_lights.P_SpawnFireFlicker(sector)
        end
    end

    -- Init line EFFECTs
    p_spec.numlinespecials = 0
    for i = 0, r_state.numlines - 1 do
        if r_state.lines[i + 1].special == 48 then
            if p_spec.numlinespecials >= MAXLINEANIMS then
                i_system.I_Error("Too many scrolling wall linedefs! "
                    .. "(Vanilla limit is 64)")
            end
            -- EFFECT FIRSTCOL SCROLL+
            p_spec.linespeciallist[p_spec.numlinespecials + 1] = r_state.lines[i + 1]
            p_spec.numlinespecials = p_spec.numlinespecials + 1
        end
    end

    -- Init other misc stuff
    for i = 1, 30 do -- MAXCEILINGS
        p_ceiling.activeceilings[i] = nil
    end

    for i = 1, 30 do -- MAXPLATS
        p_plats.activeplats[i] = nil
    end

    for i = 1, MAXBUTTONS do
        local button = p_switch.buttonlist[i]
        button.line = nil
        button.where = 0
        button.btexture = 0
        button.btimer = 0
        button.soundorg = nil
    end

    -- UNUSED: no horizontal sliders.
    -- P_InitSlidingDoorFrames();
end

return p_spec
end)()

p_switch = (function()
local p_switch = {}

local MAXSWITCHES = 50
local MAXBUTTONS = 16
local BUTTONTIME = 35

-- bwhere_e (p_spec.h).
local top = 0
local middle = 1
local bottom = 2

-- alphSwitchList: { name1, name2, episode } (p_switch.c).
local alphSwitchList = {
    -- Doom shareware episode 1 switches
    { "SW1BRCOM", "SW2BRCOM", 1 },
    { "SW1BRN1", "SW2BRN1", 1 },
    { "SW1BRN2", "SW2BRN2", 1 },
    { "SW1BRNGN", "SW2BRNGN", 1 },
    { "SW1BROWN", "SW2BROWN", 1 },
    { "SW1COMM", "SW2COMM", 1 },
    { "SW1COMP", "SW2COMP", 1 },
    { "SW1DIRT", "SW2DIRT", 1 },
    { "SW1EXIT", "SW2EXIT", 1 },
    { "SW1GRAY", "SW2GRAY", 1 },
    { "SW1GRAY1", "SW2GRAY1", 1 },
    { "SW1METAL", "SW2METAL", 1 },
    { "SW1PIPE", "SW2PIPE", 1 },
    { "SW1SLAD", "SW2SLAD", 1 },
    { "SW1STARG", "SW2STARG", 1 },
    { "SW1STON1", "SW2STON1", 1 },
    { "SW1STON2", "SW2STON2", 1 },
    { "SW1STONE", "SW2STONE", 1 },
    { "SW1STRTN", "SW2STRTN", 1 },

    -- Doom registered episodes 2&3 switches
    { "SW1BLUE", "SW2BLUE", 2 },
    { "SW1CMT", "SW2CMT", 2 },
    { "SW1GARG", "SW2GARG", 2 },
    { "SW1GSTON", "SW2GSTON", 2 },
    { "SW1HOT", "SW2HOT", 2 },
    { "SW1LION", "SW2LION", 2 },
    { "SW1SATYR", "SW2SATYR", 2 },
    { "SW1SKIN", "SW2SKIN", 2 },
    { "SW1VINE", "SW2VINE", 2 },
    { "SW1WOOD", "SW2WOOD", 2 },

    -- Doom II switches
    { "SW1PANEL", "SW2PANEL", 3 },
    { "SW1ROCK", "SW2ROCK", 3 },
    { "SW1MET2", "SW2MET2", 3 },
    { "SW1WDMET", "SW2WDMET", 3 },
    { "SW1BRIK", "SW2BRIK", 3 },
    { "SW1MOD1", "SW2MOD1", 3 },
    { "SW1ZIM", "SW2ZIM", 3 },
    { "SW1STON6", "SW2STON6", 3 },
    { "SW1TEK", "SW2TEK", 3 },
    { "SW1MARB", "SW2MARB", 3 },
    { "SW1SKULL", "SW2SKULL", 3 },

    { "", "", 0 }, -- terminator
}

-- switchlist[MAXSWITCHES * 2] (C int array; 1-based here).
p_switch.switchlist = {}
for _ = 1, MAXSWITCHES * 2 do
    table.insert(p_switch.switchlist, 0)
end
p_switch.numswitches = 0

-- buttonlist[MAXBUTTONS] (C button_t array).
p_switch.buttonlist = {}
for _ = 1, MAXBUTTONS do
    table.insert(p_switch.buttonlist, {
        line = nil, where = top, btexture = 0, btimer = 0, soundorg = nil,
    })
end

-- ---------------------------------------------------------------------------
-- P_InitSwitchList
-- Only called at game initialization.
-- ---------------------------------------------------------------------------

function p_switch.P_InitSwitchList()
    local index
    local episode

    episode = 1

    if doomstat.gamemode == d_mode.registered or doomstat.gamemode == d_mode.retail then
        episode = 2
    elseif doomstat.gamemode == d_mode.commercial then
        episode = 3
    end

    index = 0
    for i, entry in ipairs(alphSwitchList) do
        -- The C switchlist_t is { name1, name2, episode }; the port keeps it
        -- as a positional list, so read by index.
        if entry[3] == 0 then
            p_switch.numswitches = index // 2
            p_switch.switchlist[index + 1] = -1
            break
        end

        if entry[3] <= episode then
            p_switch.switchlist[index + 1] =
                r_data.R_TextureNumForName(deh_str.DEH_String(entry[1]))
            index = index + 1
            p_switch.switchlist[index + 1] =
                r_data.R_TextureNumForName(deh_str.DEH_String(entry[2]))
            index = index + 1
        end
    end
end

-- ---------------------------------------------------------------------------
-- P_StartButton
-- Start a button counting down till it turns off.
-- ---------------------------------------------------------------------------

function p_switch.P_StartButton(line, w, texture, time)
    -- See if button is already pressed
    for i = 1, MAXBUTTONS do
        if p_switch.buttonlist[i].btimer ~= 0
            and p_switch.buttonlist[i].line == line then
            return
        end
    end

    for i = 1, MAXBUTTONS do
        if p_switch.buttonlist[i].btimer == 0 then
            p_switch.buttonlist[i].line = line
            p_switch.buttonlist[i].where = w
            p_switch.buttonlist[i].btexture = texture
            p_switch.buttonlist[i].btimer = time
            p_switch.buttonlist[i].soundorg = line.frontsector.soundorg
            return
        end
    end

    i_system.I_Error("P_StartButton: no button slots left!")
end

-- ---------------------------------------------------------------------------
-- P_ChangeSwitchTexture
-- Function that changes wall texture. Tell it if switch is ok to use again
-- (1=yes, it's a button).
-- ---------------------------------------------------------------------------

function p_switch.P_ChangeSwitchTexture(line, useAgain)
    local texTop
    local texMid
    local texBot
    local sound

    if useAgain == 0 then
        line.special = 0
    end

    texTop = r_state.sides[line.sidenum[1] + 1].toptexture
    texMid = r_state.sides[line.sidenum[1] + 1].midtexture
    texBot = r_state.sides[line.sidenum[1] + 1].bottomtexture

    sound = sounds.sfxenum.sfx_swtchn

    -- EXIT SWITCH?
    if line.special == 11 then
        sound = sounds.sfxenum.sfx_swtchx
    end

    for i = 0, p_switch.numswitches * 2 - 1 do
        if p_switch.switchlist[i + 1] == texTop then
            s_sound.S_StartSound(nil, sound)
            r_state.sides[line.sidenum[1] + 1].toptexture =
                p_switch.switchlist[bit32.bxor(i, 1) + 1]

            if useAgain ~= 0 then
                p_switch.P_StartButton(line, top, p_switch.switchlist[i + 1], BUTTONTIME)
            end
            return
        elseif p_switch.switchlist[i + 1] == texMid then
            s_sound.S_StartSound(nil, sound)
            r_state.sides[line.sidenum[1] + 1].midtexture =
                p_switch.switchlist[bit32.bxor(i, 1) + 1]

            if useAgain ~= 0 then
                p_switch.P_StartButton(line, middle, p_switch.switchlist[i + 1], BUTTONTIME)
            end
            return
        elseif p_switch.switchlist[i + 1] == texBot then
            s_sound.S_StartSound(nil, sound)
            r_state.sides[line.sidenum[1] + 1].bottomtexture =
                p_switch.switchlist[bit32.bxor(i, 1) + 1]

            if useAgain ~= 0 then
                p_switch.P_StartButton(line, bottom, p_switch.switchlist[i + 1], BUTTONTIME)
            end
            return
        end
    end
end

-- ---------------------------------------------------------------------------
-- P_UseSpecialLine
-- Called when a thing uses a special line.
-- Only the front sides of lines are usable.
-- ---------------------------------------------------------------------------

function p_switch.P_UseSpecialLine(thing, line, side)

    -- Err...
    -- Use the back sides of VERY SPECIAL lines...
    if side ~= 0 then
        if line.special ~= 124 then
            -- Sliding door open&close (UNUSED)
            return false
        end
    end

    -- Switches that other things can activate.
    if not thing.player then
        -- never open secret doors
        if bit32.band(line.flags, 256) ~= 0 then -- ML_SECRET
            return false
        end

        if line.special == 1 -- MANUAL DOOR RAISE
            or line.special == 32 -- MANUAL BLUE
            or line.special == 33 -- MANUAL RED
            or line.special == 34 then -- MANUAL YELLOW
            -- ok
        else
            return false
        end
    end

    -- do something
    local sp = line.special

    -- MANUALS
    if sp == 1 -- Vertical Door
        or sp == 26 -- Blue Door/Locked
        or sp == 27 -- Yellow Door /Locked
        or sp == 28 -- Red Door /Locked
        or sp == 31 -- Manual door open
        or sp == 32 -- Blue locked door open
        or sp == 33 -- Red locked door open
        or sp == 34 -- Yellow locked door open
        or sp == 117 -- Blazing door raise
        or sp == 118 then -- Blazing door open
        p_doors.EV_VerticalDoor(line, thing)

    -- SWITCHES
    elseif sp == 7 then
        -- Build Stairs
        if p_floor.EV_BuildStairs(line, p_floor.build8) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 9 then
        -- Change Donut
        if p_spec.EV_DoDonut(line) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 11 then
        -- Exit level
        p_switch.P_ChangeSwitchTexture(line, 0)
        g_game.G_ExitLevel()
    elseif sp == 14 then
        -- Raise Floor 32 and change texture
        if p_plats.EV_DoPlat(line, p_plats.raiseAndChange, 32) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 15 then
        -- Raise Floor 24 and change texture
        if p_plats.EV_DoPlat(line, p_plats.raiseAndChange, 24) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 18 then
        -- Raise Floor to next highest floor
        if p_floor.EV_DoFloor(line, p_floor.raiseFloorToNearest) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 20 then
        -- Raise Plat next highest floor and change texture
        if p_plats.EV_DoPlat(line, p_plats.raiseToNearestAndChange, 0) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 21 then
        -- PlatDownWaitUpStay
        if p_plats.EV_DoPlat(line, p_plats.downWaitUpStay, 0) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 23 then
        -- Lower Floor to Lowest
        if p_floor.EV_DoFloor(line, p_floor.lowerFloorToLowest) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 29 then
        -- Raise Door
        if p_doors.EV_DoDoor(line, p_doors.vld_normal) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 41 then
        -- Lower Ceiling to Floor
        if p_ceilng.EV_DoCeiling(line, p_ceilng.lowerToFloor) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 71 then
        -- Turbo Lower Floor
        if p_floor.EV_DoFloor(line, p_floor.turboLower) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 49 then
        -- Ceiling Crush And Raise
        if p_ceilng.EV_DoCeiling(line, p_ceilng.crushAndRaise) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 50 then
        -- Close Door
        if p_doors.EV_DoDoor(line, p_doors.vld_close) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 51 then
        -- Secret EXIT
        p_switch.P_ChangeSwitchTexture(line, 0)
        g_game.G_SecretExitLevel()
    elseif sp == 55 then
        -- Raise Floor Crush
        if p_floor.EV_DoFloor(line, p_floor.raiseFloorCrush) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 101 then
        -- Raise Floor
        if p_floor.EV_DoFloor(line, p_floor.raiseFloor) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 102 then
        -- Lower Floor to Surrounding floor height
        if p_floor.EV_DoFloor(line, p_floor.lowerFloor) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 103 then
        -- Open Door
        if p_doors.EV_DoDoor(line, p_doors.vld_open) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 111 then
        -- Blazing Door Raise (faster than TURBO!)
        if p_doors.EV_DoDoor(line, p_doors.vld_blazeRaise) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 112 then
        -- Blazing Door Open (faster than TURBO!)
        if p_doors.EV_DoDoor(line, p_doors.vld_blazeOpen) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 113 then
        -- Blazing Door Close (faster than TURBO!)
        if p_doors.EV_DoDoor(line, p_doors.vld_blazeClose) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 122 then
        -- Blazing PlatDownWaitUpStay
        if p_plats.EV_DoPlat(line, p_plats.blazeDWUS, 0) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 127 then
        -- Build Stairs Turbo 16
        if p_floor.EV_BuildStairs(line, p_floor.turbo16) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 131 then
        -- Raise Floor Turbo
        if p_floor.EV_DoFloor(line, p_floor.raiseFloorTurbo) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 133 or sp == 135 or sp == 137 then
        -- BlzOpenDoor BLUE / RED / YELLOW
        if p_doors.EV_DoLockedDoor(line, p_doors.vld_blazeOpen, thing) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end
    elseif sp == 140 then
        -- Raise Floor 512
        if p_floor.EV_DoFloor(line, p_floor.raiseFloor512) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 0)
        end

    -- BUTTONS
    elseif sp == 42 then
        -- Close Door
        if p_doors.EV_DoDoor(line, p_doors.vld_close) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 43 then
        -- Lower Ceiling to Floor
        if p_ceilng.EV_DoCeiling(line, p_ceilng.lowerToFloor) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 45 then
        -- Lower Floor to Surrounding floor height
        if p_floor.EV_DoFloor(line, p_floor.lowerFloor) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 60 then
        -- Lower Floor to Lowest
        if p_floor.EV_DoFloor(line, p_floor.lowerFloorToLowest) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 61 then
        -- Open Door
        if p_doors.EV_DoDoor(line, p_doors.vld_open) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 62 then
        -- PlatDownWaitUpStay
        if p_plats.EV_DoPlat(line, p_plats.downWaitUpStay, 1) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 63 then
        -- Raise Door
        if p_doors.EV_DoDoor(line, p_doors.vld_normal) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 64 then
        -- Raise Floor to ceiling
        if p_floor.EV_DoFloor(line, p_floor.raiseFloor) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 66 then
        -- Raise Floor 24 and change texture
        if p_plats.EV_DoPlat(line, p_plats.raiseAndChange, 24) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 67 then
        -- Raise Floor 32 and change texture
        if p_plats.EV_DoPlat(line, p_plats.raiseAndChange, 32) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 65 then
        -- Raise Floor Crush
        if p_floor.EV_DoFloor(line, p_floor.raiseFloorCrush) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 68 then
        -- Raise Plat to next highest floor and change texture
        if p_plats.EV_DoPlat(line, p_plats.raiseToNearestAndChange, 0) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 69 then
        -- Raise Floor to next highest floor
        if p_floor.EV_DoFloor(line, p_floor.raiseFloorToNearest) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 70 then
        -- Turbo Lower Floor
        if p_floor.EV_DoFloor(line, p_floor.turboLower) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 114 then
        -- Blazing Door Raise (faster than TURBO!)
        if p_doors.EV_DoDoor(line, p_doors.vld_blazeRaise) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 115 then
        -- Blazing Door Open (faster than TURBO!)
        if p_doors.EV_DoDoor(line, p_doors.vld_blazeOpen) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 116 then
        -- Blazing Door Close (faster than TURBO!)
        if p_doors.EV_DoDoor(line, p_doors.vld_blazeClose) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 123 then
        -- Blazing PlatDownWaitUpStay
        if p_plats.EV_DoPlat(line, p_plats.blazeDWUS, 0) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 132 then
        -- Raise Floor Turbo
        if p_floor.EV_DoFloor(line, p_floor.raiseFloorTurbo) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 99 or sp == 134 or sp == 136 then
        -- BlzOpenDoor BLUE / RED / YELLOW
        if p_doors.EV_DoLockedDoor(line, p_doors.vld_blazeOpen, thing) ~= 0 then
            p_switch.P_ChangeSwitchTexture(line, 1)
        end
    elseif sp == 138 then
        -- Light Turn On
        p_lights.EV_LightTurnOn(line, 255)
        p_switch.P_ChangeSwitchTexture(line, 1)
    elseif sp == 139 then
        -- Light Turn Off
        p_lights.EV_LightTurnOn(line, 35)
        p_switch.P_ChangeSwitchTexture(line, 1)
    end

    return true
end

return p_switch
end)()

p_telept = (function()
local p_telept = {}

-- ---------------------------------------------------------------------------
-- EV_Teleport
-- ---------------------------------------------------------------------------

function p_telept.EV_Teleport(line, side, thing)
    local tag
    local m
    local fog
    local an
    local sector
    local oldx
    local oldy
    local oldz

    -- don't teleport missiles
    if bit32.band(thing.flags, p_mobj.MF_MISSILE) ~= 0 then
        return 0
    end

    -- Don't teleport if hit back of line,
    -- so you can get out of teleporter.
    if side == 1 then
        return 0
    end

    tag = line.tag
    for i = 1, r_state.numsectors do
        if r_state.sectors[i].tag == tag then
            -- The C scans the thinker list for a MT_TELEPORTMAN mobj in this
            -- sector; on success it returns 1, on a failed P_TeleportMove it
            -- returns 0. Use an explicit status tracked through the early
            -- exit scanner.
            local status = nil -- nil = no teleportman yet; "done" / "failed"

            p_tick.scanThinkers(function(thinker)
                if thinker.thinkfunc ~= p_mobj.P_MobjThinker then
                    return true
                end

                m = thinker

                -- not a teleportman
                if m.type ~= info.mobjtype.MT_TELEPORTMAN then
                    return true
                end

                sector = m.subsector.sector
                -- wrong sector
                if sector.index ~= i - 1 then
                    return true
                end

                oldx = thing.x
                oldy = thing.y
                oldz = thing.z

                if not p_map.P_TeleportMove(thing, m.x, m.y) then
                    status = "failed"
                    return false
                end

                -- The first Final Doom executable does not set thing->z
                -- when teleporting. This quirk is unique to this version.
                if doomstat.gameversion ~= d_mode.exe_final then
                    thing.z = thing.floorz
                end

                if thing.player then
                    thing.player.viewz = thing.z + thing.player.viewheight
                end

                -- spawn teleport fog at source and destination
                fog = p_mobj.P_SpawnMobj(oldx, oldy, oldz, info.mobjtype.MT_TFOG)
                s_sound.S_StartSound(fog, sounds.sfxenum.sfx_telept)
                an = bit32.rshift(m.angle, 19) -- ANGLETOFINESHIFT
                fog = p_mobj.P_SpawnMobj(
                    m.x + 20 * tables.finesine[an + 1 + 2048], -- finecosine[an]
                    m.y + 20 * tables.finesine[an + 1],
                    thing.z, info.mobjtype.MT_TFOG)

                -- emit sound, where?
                s_sound.S_StartSound(fog, sounds.sfxenum.sfx_telept)

                -- don't move for a bit
                if thing.player then
                    thing.reactiontime = 18
                end

                thing.angle = m.angle
                thing.momx = 0
                thing.momy = 0
                thing.momz = 0

                status = "done"
                return false
            end)

            if status == "done" then
                return 1
            elseif status == "failed" then
                return 0
            end
            -- no teleportman in this sector: keep scanning other sectors
        end
    end
    return 0
end

return p_telept
end)()

p_tick = (function() 
local p_tick = {}

-- Both the head and tail of the thinker list (thinkercap). The port uses a
-- sentinel table with prev/next pointing at itself.
local thinkercap = { prev = nil, next = nil }
thinkercap.prev = thinkercap
thinkercap.next = thinkercap

-- P_InitThinkers.
function p_tick.P_InitThinkers()
    thinkercap.prev = thinkercap
    thinkercap.next = thinkercap
end

-- P_AddThinker: adds a new thinker at the end of the list. In the C the
-- thinker_t is embedded at offset 0 of the mobj; in the port the list links
-- and think function live directly on the mobj table (`prev`/`next`/
-- `thinkfunc`), so the list node is the mobj itself.
function p_tick.P_AddThinker(thinker)
    thinkercap.prev.next = thinker
    thinker.next = thinkercap
    thinker.prev = thinkercap.prev
    thinkercap.prev = thinker
end

-- P_RemoveThinker: deallocation is lazy -- it will not actually be freed
-- until its thinking turn comes up.
function p_tick.P_RemoveThinker(thinker)
    thinker.thinkfunc = -1 -- actionf_v(-1) marker
end

-- P_RunThinkers.
function p_tick.P_RunThinkers()
    local currentthinker = thinkercap.next

    while currentthinker ~= thinkercap do
        if currentthinker.thinkfunc == -1 then
            -- time to remove it
            currentthinker.next.prev = currentthinker.prev
            currentthinker.prev.next = currentthinker.next
        else
            if currentthinker.thinkfunc then
                currentthinker.thinkfunc(currentthinker)
            end
        end
        currentthinker = currentthinker.next
    end
end

-- Iterate the live thinker list (used by R_PrecacheLevel; the C walks the
-- same thinkercap list). func receives each mobj/thinker table.
function p_tick.iterateThinkers(func)
    local t = thinkercap.next
    while t ~= thinkercap do
        func(t)
        t = t.next
    end
end

-- Scan the live thinker list with early exit: func returns false to stop.
-- Returns true if every thinker was visited. (Used by EV_Teleport, which
-- needs the C's `return 1` the moment a teleportman accepts the teleport.)
function p_tick.scanThinkers(func)
    local t = thinkercap.next
    while t ~= thinkercap do
        if not func(t) then
            return false
        end
        t = t.next
    end
    return true
end

-- P_Ticker.
function p_tick.P_Ticker()
    local i

    -- run the tic
    if doomstat.paused then
        return
    end

    -- pause if in menu and at least one tic has been run
    if not doomstat.netgame
        and doomstat.menuactive
        and not doomstat.demoplayback
        and doomstat.players[doomstat.consoleplayer + 1] ~= nil
        and doomstat.players[doomstat.consoleplayer + 1].viewz ~= 1 then
        return
    end

    for i = 1, doomtype.MAXPLAYERS do
        if doomstat.playeringame[i] then
            p_user.P_PlayerThink(doomstat.players[i])
        end
    end

    p_tick.P_RunThinkers()
    p_spec.P_UpdateSpecials()
    p_mobj.P_RespawnSpecials()

    -- for par times
    doomstat.leveltime = doomstat.leveltime + 1
end

return p_tick
end)()

p_user = (function() 
local p_user = {}

local FRACUNIT = m_fixed.FRACUNIT
local VIEWHEIGHT = 41 * FRACUNIT
local FINEANGLES = doomtype.FINEANGLES
local FINEMASK = doomtype.FINEMASK
local ANG90 = doomtype.ANG90
local ANG180 = doomtype.ANG180
local ANG5 = ANG90 // 18 -- ANG90/18 (C integer division)

-- Index of the special effects (INVUL inverse) map.
local INVERSECOLORMAP = 32

-- 16 pixels of bob.
local MAXBOB = 0x100000

-- ---------------------------------------------------------------------------
-- P_Thrust
-- Moves the given origin along a given angle.
-- ---------------------------------------------------------------------------

function p_user.P_Thrust(player, angle, move)
    angle = bit32.rshift(angle, 19) -- ANGLETOFINESHIFT

    player.mo.momx = player.mo.momx + m_fixed.FixedMul(move,
        tables.finesine[angle + 1 + 2048]) -- finecosine[angle]
    player.mo.momy = player.mo.momy + m_fixed.FixedMul(move,
        tables.finesine[angle + 1])
end

-- ---------------------------------------------------------------------------
-- P_CalcHeight
-- Calculate the walking / running height adjustment.
-- ---------------------------------------------------------------------------

p_user.onground = false

function p_user.P_CalcHeight(player)
    local angle
    local bob

    -- Regular movement bobbing (needs to be calculated for gun swing even
    -- if not on ground).
    player.bob = m_fixed.FixedMul(player.mo.momx, player.mo.momx)
        + m_fixed.FixedMul(player.mo.momy, player.mo.momy)

    player.bob = player.bob // 4 -- >>2

    if player.bob > MAXBOB then
        player.bob = MAXBOB
    end

    if bit32.band(player.cheats, 4) ~= 0 -- CF_NOMOMENTUM
        or not p_user.onground then
        player.viewz = player.mo.z + VIEWHEIGHT

        if player.mo.ceilingz - 4 * FRACUNIT < player.viewz then
            player.viewz = player.mo.ceilingz - 4 * FRACUNIT
        end

        player.viewz = player.mo.z + player.viewheight
        return
    end

    angle = bit32.band(FINEANGLES // 20 * doomstat.leveltime, FINEMASK)
    bob = m_fixed.FixedMul(player.bob // 2, tables.finesine[angle + 1])

    -- move viewheight
    if player.playerstate == 0 then -- PST_LIVE
        player.viewheight = player.viewheight + player.deltaviewheight

        if player.viewheight > VIEWHEIGHT then
            player.viewheight = VIEWHEIGHT
            player.deltaviewheight = 0
        end

        if player.viewheight < VIEWHEIGHT // 2 then
            player.viewheight = VIEWHEIGHT // 2
            if player.deltaviewheight <= 0 then
                player.deltaviewheight = 1
            end
        end

        if player.deltaviewheight ~= 0 then
            player.deltaviewheight = player.deltaviewheight + FRACUNIT // 4
            if player.deltaviewheight == 0 then
                player.deltaviewheight = 1
            end
        end
    end
    player.viewz = player.mo.z + player.viewheight + bob

    if player.viewz > player.mo.ceilingz - 4 * FRACUNIT then
        player.viewz = player.mo.ceilingz - 4 * FRACUNIT
    end
end

-- ---------------------------------------------------------------------------
-- P_MovePlayer
-- ---------------------------------------------------------------------------

function p_user.P_MovePlayer(player)
    local cmd = player.cmd

    player.mo.angle = (player.mo.angle
        + doomtype.lshift32(cmd.angleturn, 16)) % 0x100000000

    -- Do not let the player control movement if not onground.
    p_user.onground = player.mo.z <= player.mo.floorz

    if cmd.forwardmove ~= 0 and p_user.onground then
        p_user.P_Thrust(player, player.mo.angle, cmd.forwardmove * 2048)
    end

    if cmd.sidemove ~= 0 and p_user.onground then
        p_user.P_Thrust(player,
            (player.mo.angle - ANG90) % 0x100000000, cmd.sidemove * 2048)
    end

    if (cmd.forwardmove ~= 0 or cmd.sidemove ~= 0)
        and player.mo.state == info.states[info.statenum.S_PLAY + 1] then
        p_mobj.P_SetMobjState(player.mo, info.statenum.S_PLAY_RUN1)
    end
end

-- ---------------------------------------------------------------------------
-- P_DeathThink
-- Fall on your face when dying. Decrease POV height to floor height.
-- ---------------------------------------------------------------------------

function p_user.P_DeathThink(player)
    local angle
    local delta

    p_pspr.P_MovePsprites(player)

    -- fall to the ground
    if player.viewheight > 6 * FRACUNIT then
        player.viewheight = player.viewheight - FRACUNIT
    end

    if player.viewheight < 6 * FRACUNIT then
        player.viewheight = 6 * FRACUNIT
    end

    player.deltaviewheight = 0
    p_user.onground = player.mo.z <= player.mo.floorz
    p_user.P_CalcHeight(player)

    if player.attacker and player.attacker ~= player.mo then
        angle = r_main.R_PointToAngle2(player.mo.x, player.mo.y,
            player.attacker.x, player.attacker.y)

        delta = (angle - player.mo.angle) % 0x100000000

        if delta < ANG5 or delta > (0x100000000 - ANG5) then
            -- Looking at killer, so fade damage flash down.
            player.mo.angle = angle

            if player.damagecount ~= 0 then
                player.damagecount = player.damagecount - 1
            end
        elseif delta < ANG180 then
            player.mo.angle = (player.mo.angle + ANG5) % 0x100000000
        else
            player.mo.angle = (player.mo.angle - ANG5) % 0x100000000
        end
    elseif player.damagecount ~= 0 then
        player.damagecount = player.damagecount - 1
    end

    if bit32.band(player.cmd.buttons, 2) ~= 0 then -- BT_USE
        player.playerstate = 2 -- PST_REBORN
    end
end

-- ---------------------------------------------------------------------------
-- P_PlayerThink
-- ---------------------------------------------------------------------------

function p_user.P_PlayerThink(player)
    local cmd
    local newweapon

    -- fixme: do this in the cheat code
    if bit32.band(player.cheats, 1) ~= 0 then -- CF_NOCLIP
        player.mo.flags = bit32.bor(player.mo.flags, p_mobj.MF_NOCLIP)
    else
        player.mo.flags = bit32.band(player.mo.flags,
            bit32.bnot(p_mobj.MF_NOCLIP))
    end

    -- chain saw run forward
    cmd = player.cmd
    if bit32.band(player.mo.flags, p_mobj.MF_JUSTATTACKED) ~= 0 then
        cmd.angleturn = 0
        cmd.forwardmove = 0xc800 // 512 -- 100
        cmd.sidemove = 0
        player.mo.flags = bit32.band(player.mo.flags,
            bit32.bnot(p_mobj.MF_JUSTATTACKED))
    end

    if player.playerstate == 1 then -- PST_DEAD
        p_user.P_DeathThink(player)
        return
    end

    -- Move around.
    -- Reactiontime is used to prevent movement for a bit after a teleport.
    if player.mo.reactiontime ~= 0 then
        player.mo.reactiontime = player.mo.reactiontime - 1
    else
        p_user.P_MovePlayer(player)
    end

    p_user.P_CalcHeight(player)

    if player.mo.subsector and player.mo.subsector.sector.special ~= 0 then
        p_spec.P_PlayerInSpecialSector(player)
    end

    -- Check for weapon change.

    -- A special event has no other buttons.
    if bit32.band(cmd.buttons, 128) ~= 0 then -- BT_SPECIAL
        cmd.buttons = 0
    end

    if bit32.band(cmd.buttons, 4) ~= 0 then -- BT_CHANGE
        -- The actual changing of the weapon is done when the weapon psprite
        -- can do it (read: not in the middle of an attack).
        newweapon = bit32.rshift(bit32.band(cmd.buttons, 56), 3) -- BT_WEAPONMASK>>BT_WEAPONSHIFT

        if newweapon == doomdef.wp_fist
            and player.weaponowned[doomdef.wp_chainsaw + 1]
            and not (player.readyweapon == doomdef.wp_chainsaw
                and player.powers[doomdef.pw_strength + 1] ~= 0) then
            newweapon = doomdef.wp_chainsaw
        end

        if doomstat.gamemode == 2 -- commercial
            and newweapon == doomdef.wp_shotgun
            and player.weaponowned[doomdef.wp_supershotgun + 1]
            and player.readyweapon ~= doomdef.wp_supershotgun then
            newweapon = doomdef.wp_supershotgun
        end

        if player.weaponowned[newweapon + 1]
            and newweapon ~= player.readyweapon then
            -- Do not go to plasma or BFG in shareware, even if cheated.
            if (newweapon ~= doomdef.wp_plasma
                and newweapon ~= doomdef.wp_bfg)
                or doomstat.gamemode ~= 0 then -- shareware
                player.pendingweapon = newweapon
            end
        end
    end

    -- check for use
    if bit32.band(cmd.buttons, 2) ~= 0 then -- BT_USE
        if not player.usedown then
            p_map.P_UseLines(player)
            player.usedown = true
        end
    else
        player.usedown = false
    end

    -- cycle psprites
    p_pspr.P_MovePsprites(player)

    -- Counters, time dependend power ups.

    -- Strength counts up to diminish fade.
    if player.powers[doomdef.pw_strength + 1] ~= 0 then
        player.powers[doomdef.pw_strength + 1] =
            player.powers[doomdef.pw_strength + 1] + 1
    end

    if player.powers[doomdef.pw_invulnerability + 1] ~= 0 then
        player.powers[doomdef.pw_invulnerability + 1] =
            player.powers[doomdef.pw_invulnerability + 1] - 1
    end

    if player.powers[doomdef.pw_invisibility + 1] ~= 0 then
        player.powers[doomdef.pw_invisibility + 1] =
            player.powers[doomdef.pw_invisibility + 1] - 1
        if player.powers[doomdef.pw_invisibility + 1] == 0 then
            player.mo.flags = bit32.band(player.mo.flags,
                bit32.bnot(p_mobj.MF_SHADOW))
        end
    end

    if player.powers[doomdef.pw_infrared + 1] ~= 0 then
        player.powers[doomdef.pw_infrared + 1] =
            player.powers[doomdef.pw_infrared + 1] - 1
    end

    if player.powers[doomdef.pw_ironfeet + 1] ~= 0 then
        player.powers[doomdef.pw_ironfeet + 1] =
            player.powers[doomdef.pw_ironfeet + 1] - 1
    end

    if player.damagecount ~= 0 then
        player.damagecount = player.damagecount - 1
    end

    if player.bonuscount ~= 0 then
        player.bonuscount = player.bonuscount - 1
    end

    -- Handling colormaps.
    if player.powers[doomdef.pw_invulnerability + 1] ~= 0 then
        if player.powers[doomdef.pw_invulnerability + 1] > 4 * 32
            or bit32.band(player.powers[doomdef.pw_invulnerability + 1], 8) ~= 0 then
            player.fixedcolormap = INVERSECOLORMAP
        else
            player.fixedcolormap = 0
        end
    elseif player.powers[doomdef.pw_infrared + 1] ~= 0 then
        if player.powers[doomdef.pw_infrared + 1] > 4 * 32
            or bit32.band(player.powers[doomdef.pw_infrared + 1], 8) ~= 0 then
            -- almost full bright
            player.fixedcolormap = 1
        else
            player.fixedcolormap = 0
        end
    else
        player.fixedcolormap = 0
    end
end

return p_user
end)()

r_bsp = (function()
local r_bsp = {}

local SCREENWIDTH = 320
local ANG90 = 0x40000000
local ANG180 = 0x80000000

local NF_SUBSECTOR = 0x8000
local MAXDRAWSEGS = 256
local MAXSEGS = 32

-- checkcoord[12][4] (0-based rows, C r_bsp.c).
local checkcoord = {
    { 3, 0, 2, 1 },
    { 3, 0, 2, 0 },
    { 3, 1, 2, 0 },
    { 0, 0, 0, 0 },
    { 2, 0, 2, 1 },
    { 0, 0, 0, 0 },
    { 3, 1, 3, 0 },
    { 0, 0, 0, 0 },
    { 2, 0, 3, 1 },
    { 2, 1, 3, 1 },
    { 2, 1, 3, 0 },
    { 0, 0, 0, 0 },
}

-- ---------------------------------------------------------------------------
-- R_ClearDrawSegs
-- ---------------------------------------------------------------------------

function r_bsp.R_ClearDrawSegs()
    r_state.ds_p = 1
end

-- ---------------------------------------------------------------------------
-- R_ClipSolidWallSegment
-- ---------------------------------------------------------------------------

function r_bsp.R_ClipSolidWallSegment(first, last)
    local S = r_state

    -- Find the first range that touches the range (adjacent pixels are
    -- touching).
    local start_idx = 1
    while S.solidsegs[start_idx].last < first - 1 do
        start_idx = start_idx + 1
    end

    if first < S.solidsegs[start_idx].first then
        if last < S.solidsegs[start_idx].first - 1 then
            -- Post is entirely visible (above start), so insert a new
            -- clippost.
            r_segs.R_StoreWallRange(first, last)

            local next_idx = S.newend
            S.newend = S.newend + 1

            while next_idx ~= start_idx do
                -- C: *next = *(next-1) copies struct values.
                S.solidsegs[next_idx].first = S.solidsegs[next_idx - 1].first
                S.solidsegs[next_idx].last = S.solidsegs[next_idx - 1].last
                next_idx = next_idx - 1
            end
            S.solidsegs[next_idx].first = first
            S.solidsegs[next_idx].last = last
            return
        end

        -- There is a fragment above *start.
        r_segs.R_StoreWallRange(first, S.solidsegs[start_idx].first - 1)
        -- Now adjust the clip size.
        S.solidsegs[start_idx].first = first
    end

    -- Bottom contained in start?
    if last <= S.solidsegs[start_idx].last then
        return
    end

    local next_idx = start_idx
    local crunched = false
    while last >= S.solidsegs[next_idx + 1].first - 1 do
        -- There is a fragment between two posts.
        r_segs.R_StoreWallRange(S.solidsegs[next_idx].last + 1,
            S.solidsegs[next_idx + 1].first - 1)
        next_idx = next_idx + 1

        if last <= S.solidsegs[next_idx].last then
            -- Bottom is contained in next. Adjust the clip size.
            S.solidsegs[start_idx].last = S.solidsegs[next_idx].last
            crunched = true
            break
        end
    end

    if not crunched then
        -- There is a fragment after *next.
        r_segs.R_StoreWallRange(S.solidsegs[next_idx].last + 1, last)
        -- Adjust the clip size.
        S.solidsegs[start_idx].last = last
    end

    -- Remove start+1 to next from the clip list, because start now covers
    -- their area.
    if next_idx == start_idx then
        -- Post just extended past the bottom of one post.
        return
    end

    -- C: while (next++ != newend) { *++start = *next; } newend = start+1;
    local si = start_idx
    local ni = next_idx
    while true do
        if ni == S.newend then
            break
        end
        ni = ni + 1
        si = si + 1
        -- C copies struct values.
        S.solidsegs[si].first = S.solidsegs[ni].first
        S.solidsegs[si].last = S.solidsegs[ni].last
    end
    S.newend = si + 1
end

-- ---------------------------------------------------------------------------
-- R_ClipPassWallSegment
-- ---------------------------------------------------------------------------

function r_bsp.R_ClipPassWallSegment(first, last)
    local S = r_state

    -- Find the first range that touches the range (adjacent pixels are
    -- touching).
    local start_idx = 1
    while S.solidsegs[start_idx].last < first - 1 do
        start_idx = start_idx + 1
    end

    if first < S.solidsegs[start_idx].first then
        if last < S.solidsegs[start_idx].first - 1 then
            -- Post is entirely visible (above start).
            r_segs.R_StoreWallRange(first, last)
            return
        end

        -- There is a fragment above *start.
        r_segs.R_StoreWallRange(first, S.solidsegs[start_idx].first - 1)
    end

    -- Bottom contained in start?
    if last <= S.solidsegs[start_idx].last then
        return
    end

    while last >= S.solidsegs[start_idx + 1].first - 1 do
        -- There is a fragment between two posts.
        r_segs.R_StoreWallRange(S.solidsegs[start_idx].last + 1,
            S.solidsegs[start_idx + 1].first - 1)
        start_idx = start_idx + 1

        if last <= S.solidsegs[start_idx].last then
            return
        end
    end

    -- There is a fragment after *next.
    r_segs.R_StoreWallRange(S.solidsegs[start_idx].last + 1, last)
end

-- ---------------------------------------------------------------------------
-- R_ClearClipSegs
-- ---------------------------------------------------------------------------

function r_bsp.R_ClearClipSegs()
    local S = r_state
    S.solidsegs[1].first = -0x7fffffff -- INT_MIN + 1
    S.solidsegs[1].last = -1
    S.solidsegs[2].first = S.viewwidth
    S.solidsegs[2].last = 0x7fffffff
    S.newend = 3
end

-- ---------------------------------------------------------------------------
-- R_AddLine
-- ---------------------------------------------------------------------------

function r_bsp.R_AddLine(line)
    local S = r_state

    S.curline = line

    -- OPTIMIZE: quickly reject orthogonal back sides.
    local angle1 = r_main.R_PointToAngle(line.v1.x, line.v1.y)
    local angle2 = r_main.R_PointToAngle(line.v2.x, line.v2.y)

    -- Clip to view edges. OPTIMIZE: make constant out of 2*clipangle
    -- (FIELDOFVIEW).
    local span = (angle1 - angle2) % 0x100000000

    -- Back side? I.e. backface culling?
    if span >= ANG180 then
        return
    end

    -- Global angle needed by segcalc.
    S.rw_angle1 = angle1
    angle1 = (angle1 - S.viewangle) % 0x100000000
    angle2 = (angle2 - S.viewangle) % 0x100000000

    local tspan = (angle1 + S.clipangle) % 0x100000000
    if tspan > (2 * S.clipangle) % 0x100000000 then
        tspan = (tspan - (2 * S.clipangle) % 0x100000000) % 0x100000000

        -- Totally off the left edge?
        if tspan >= span then
            return
        end

        angle1 = S.clipangle
    end

    tspan = (S.clipangle - angle2) % 0x100000000
    if tspan > (2 * S.clipangle) % 0x100000000 then
        tspan = (tspan - (2 * S.clipangle) % 0x100000000) % 0x100000000

        -- Totally off the left edge?
        if tspan >= span then
            return
        end

        angle2 = (0x100000000 - S.clipangle) % 0x100000000
    end

    -- The seg is in the view range, but not necessarily visible.
    local a1 = bit32.rshift((angle1 + ANG90) % 0x100000000, 19)
    local a2 = bit32.rshift((angle2 + ANG90) % 0x100000000, 19)
    local x1 = S.viewangletox[a1 + 1]
    local x2 = S.viewangletox[a2 + 1]

    -- Does not cross a pixel?
    if x1 == x2 then
        return
    end

    S.backsector = line.backsector

    -- Single sided line?
    if S.backsector == nil then
        r_bsp.R_ClipSolidWallSegment(x1, x2 - 1)
        return
    end

    -- Closed door.
    if S.backsector.ceilingheight <= S.frontsector.floorheight
        or S.backsector.floorheight >= S.frontsector.ceilingheight then
        r_bsp.R_ClipSolidWallSegment(x1, x2 - 1)
        return
    end

    -- Window.
    if S.backsector.ceilingheight ~= S.frontsector.ceilingheight
        or S.backsector.floorheight ~= S.frontsector.floorheight then
        r_bsp.R_ClipPassWallSegment(x1, x2 - 1)
        return
    end

    -- Reject empty lines used for triggers and special events. Identical
    -- floor and ceiling on both sides, identical light levels on both sides,
    -- and no middle texture.
    if S.backsector.ceilingpic == S.frontsector.ceilingpic
        and S.backsector.floorpic == S.frontsector.floorpic
        and S.backsector.lightlevel == S.frontsector.lightlevel
        and S.curline.sidedef.midtexture == 0 then
        return
    end

    r_bsp.R_ClipPassWallSegment(x1, x2 - 1)
end

-- ---------------------------------------------------------------------------
-- R_CheckBBox
-- ---------------------------------------------------------------------------

function r_bsp.R_CheckBBox(bspcoord)
    local S = r_state

    -- Find the corners of the box that define the edges from the current
    -- viewpoint. bbox is 1-based: BOXTOP=1, BOXBOTTOM=2, BOXLEFT=3,
    -- BOXRIGHT=4 (m_bbox.lua).
    local boxx, boxy
    if S.viewx <= bspcoord[3] then -- BOXLEFT
        boxx = 0
    elseif S.viewx < bspcoord[4] then -- BOXRIGHT
        boxx = 1
    else
        boxx = 2
    end

    if S.viewy >= bspcoord[1] then -- BOXTOP
        boxy = 0
    elseif S.viewy > bspcoord[2] then -- BOXBOTTOM
        boxy = 1
    else
        boxy = 2
    end

    local boxpos = boxy * 4 + boxx
    if boxpos == 5 then
        return true
    end

    local x1 = bspcoord[checkcoord[boxpos + 1][1] + 1]
    local y1 = bspcoord[checkcoord[boxpos + 1][2] + 1]
    local x2 = bspcoord[checkcoord[boxpos + 1][3] + 1]
    local y2 = bspcoord[checkcoord[boxpos + 1][4] + 1]

    -- Check clip list for an open space.
    local angle1 = (r_main.R_PointToAngle(x1, y1) - S.viewangle) % 0x100000000
    local angle2 = (r_main.R_PointToAngle(x2, y2) - S.viewangle) % 0x100000000

    local span = (angle1 - angle2) % 0x100000000

    -- Sitting on a line?
    if span >= ANG180 then
        return true
    end

    local tspan = (angle1 + S.clipangle) % 0x100000000
    if tspan > (2 * S.clipangle) % 0x100000000 then
        tspan = (tspan - (2 * S.clipangle) % 0x100000000) % 0x100000000

        -- Totally off the left edge?
        if tspan >= span then
            return false
        end

        angle1 = S.clipangle
    end

    tspan = (S.clipangle - angle2) % 0x100000000
    if tspan > (2 * S.clipangle) % 0x100000000 then
        tspan = (tspan - (2 * S.clipangle) % 0x100000000) % 0x100000000

        -- Totally off the left edge?
        if tspan >= span then
            return false
        end

        angle2 = (0x100000000 - S.clipangle) % 0x100000000
    end

    -- Find the first clippost that touches the source post (adjacent pixels
    -- are touching).
    local a1 = bit32.rshift((angle1 + ANG90) % 0x100000000, 19)
    local a2 = bit32.rshift((angle2 + ANG90) % 0x100000000, 19)
    local sx1 = S.viewangletox[a1 + 1]
    local sx2 = S.viewangletox[a2 + 1]

    -- Does not cross a pixel.
    if sx1 == sx2 then
        return false
    end
    sx2 = sx2 - 1

    local start_idx = 1
    while S.solidsegs[start_idx].last < sx2 do
        start_idx = start_idx + 1
    end

    if sx1 >= S.solidsegs[start_idx].first
        and sx2 <= S.solidsegs[start_idx].last then
        -- The clippost contains the new span.
        return false
    end

    return true
end

-- ---------------------------------------------------------------------------
-- R_Subsector
-- ---------------------------------------------------------------------------

function r_bsp.R_Subsector(num)
    local S = r_state

    S.sscount = S.sscount + 1

    local sub = S.subsectors[num + 1]
    S.frontsector = sub.sector
    local count = sub.numlines
    local line = S.segs[sub.firstline + 1]

    if S.frontsector.floorheight < S.viewz then
        S.floorplane = r_plane.R_FindPlane(S.frontsector.floorheight,
            S.frontsector.floorpic, S.frontsector.lightlevel)
    else
        S.floorplane = nil
    end

    if S.frontsector.ceilingheight > S.viewz
        or S.frontsector.ceilingpic == S.skyflatnum then
        S.ceilingplane = r_plane.R_FindPlane(S.frontsector.ceilingheight,
            S.frontsector.ceilingpic, S.frontsector.lightlevel)
    else
        S.ceilingplane = nil
    end

    r_things.R_AddSprites(S.frontsector)

    for i = 1, count do
        r_bsp.R_AddLine(S.segs[sub.firstline + i])
    end
end

-- ---------------------------------------------------------------------------
-- R_RenderBSPNode
-- ---------------------------------------------------------------------------

function r_bsp.R_RenderBSPNode(bspnum)
    local S = r_state

    -- Found a subsector?
    if bit32.band(bspnum % 0x100000000, NF_SUBSECTOR) ~= 0 then
        if bspnum == -1 then
            r_bsp.R_Subsector(0)
        else
            r_bsp.R_Subsector(bit32.band(bspnum, bit32.bnot(NF_SUBSECTOR)))
        end
        return
    end

    local bsp = S.nodes[bspnum + 1]

    -- Decide which side the view point is on.
    local side = r_main.R_PointOnSide(S.viewx, S.viewy, bsp)

    -- Recursively divide front space.
    r_bsp.R_RenderBSPNode(bsp.children[side + 1])

    -- Possibly divide back space.
    if r_bsp.R_CheckBBox(bsp.bbox[2 - side]) then
        r_bsp.R_RenderBSPNode(bsp.children[2 - side])
    end
end

return r_bsp
end)()

r_data = (function() 
local r_data = {}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- Read an 8-byte lump/texture name from a buffer, stripping trailing NULs
-- (mirrors the C memcpy of the 8-byte name + strncasecmp stopping at NUL).
local function read_name(buf, off)
    local name = ""
    for i = 0, 7 do
        local c = buffer.readu8(buf, off + i)
        if c == 0 then
            break
        end
        name = name .. string.char(c)
    end
    return name
end

-- Compare an 8-byte stored name against a requested name, case-insensitive,
-- stopping at NUL in either (mirrors strncasecmp(a, b, 8)).
local function name_matches(stored, name)
    for i = 1, 8 do
        local sc = string.byte(stored, i)
        local nc = string.byte(name, i)
        if sc == nil or nc == nil or sc == 0 or nc == 0 then
            return true
        end
        local su = sc >= 97 and sc <= 122 and (sc - 32) or sc
        local nu = nc >= 97 and nc <= 122 and (nc - 32) or nc
        if su ~= nu then
            return false
        end
    end
    return true
end

-- ---------------------------------------------------------------------------
-- R_DrawColumnInCache: clip and draw a column from a patch into a cached
-- post. `patch` is a { buffer, offset } pointing at the column topdelta.
-- The composite column at cacheBuf[cacheOfs] receives raw pixel data.
-- ---------------------------------------------------------------------------

function r_data.R_DrawColumnInCache(patch, cacheBuf, cacheOfs, originy, cacheheight)
    local pb = patch.buffer
    local po = patch.offset

    while buffer.readu8(pb, po) ~= 0xff do
        local length = buffer.readu8(pb, po + 1)
        local position = originy + buffer.readu8(pb, po)

        if position < 0 then
            length = length + position
            position = 0
        end

        if position + length > cacheheight then
            length = cacheheight - position
        end

        if length > 0 then
            buffer.copy(cacheBuf, cacheOfs + position, pb, po + 3, length)
        end

        po = po + buffer.readu8(pb, po + 1) + 4
    end
end

-- ---------------------------------------------------------------------------
-- R_GenerateLookup: count the columns covered by more than one patch and
-- fill in the lump/offset directory (single-patch columns point into the
-- patch lumps; multi-patch columns use the composite block).
-- ---------------------------------------------------------------------------

function r_data.R_GenerateLookup(texnum)
    local texture = r_state.textures[texnum + 1]

    r_state.texturecomposite[texnum + 1] = nil
    r_state.texturecompositesize[texnum + 1] = 0

    local collump = r_state.texturecolumnlump[texnum + 1]
    local colofs = r_state.texturecolumnofs[texnum + 1]

    -- patchcount[1..width]
    local patchcount = {}
    for _ = 1, texture.width do
        table.insert(patchcount, 0)
    end

    for _, patch in ipairs(texture.patches) do
        local realpatch = w_wad.W_CacheLumpNum(patch.patch, z_zone.PU_CACHE)
        local pb = realpatch.buffer
        local po = realpatch.offset
        local x1 = patch.originx
        local x2 = x1 + buffer.readi16(pb, po)

        local x
        if x1 < 0 then
            x = 0
        else
            x = x1
        end
        if x2 > texture.width then
            x2 = texture.width
        end

        while x < x2 do
            patchcount[x + 1] = patchcount[x + 1] + 1
            collump[x + 1] = patch.patch
            colofs[x + 1] = buffer.readi32(pb, po + 8 + (x - x1) * 4) + 3
            x = x + 1
        end
    end

    for x = 0, texture.width - 1 do
        if patchcount[x + 1] == 0 then
            print(string.format(
                "R_GenerateLookup: column without a patch (%s)",
                texture.name))
            return
        end

        if patchcount[x + 1] > 1 then
            -- Use the cached composite block.
            collump[x + 1] = -1
            colofs[x + 1] = r_state.texturecompositesize[texnum + 1]

            if r_state.texturecompositesize[texnum + 1] > 0x10000 - texture.height then
                i_system.I_Error("R_GenerateLookup: texture %i is >64k", texnum)
            end

            r_state.texturecompositesize[texnum + 1] =
                r_state.texturecompositesize[texnum + 1] + texture.height
        end
    end
end

-- ---------------------------------------------------------------------------
-- R_GenerateComposite: build the composite texture from the patches, caching
-- each column into the allocated block.
-- ---------------------------------------------------------------------------

function r_data.R_GenerateComposite(texnum)
    local texture = r_state.textures[texnum + 1]

    local block = z_zone.Z_Malloc(
        r_state.texturecompositesize[texnum + 1], z_zone.PU_STATIC, nil)
    r_state.texturecomposite[texnum + 1] = block

    local collump = r_state.texturecolumnlump[texnum + 1]
    local colofs = r_state.texturecolumnofs[texnum + 1]

    for _, patch in ipairs(texture.patches) do
        local realpatch = w_wad.W_CacheLumpNum(patch.patch, z_zone.PU_CACHE)
        local pb = realpatch.buffer
        local po = realpatch.offset
        local x1 = patch.originx
        local x2 = x1 + buffer.readi16(pb, po)

        local x
        if x1 < 0 then
            x = 0
        else
            x = x1
        end
        if x2 > texture.width then
            x2 = texture.width
        end

        while x < x2 do
            -- Column does not have multiple patches?
            if collump[x + 1] >= 0 then
                x = x + 1
                -- continue
            else
                local patchcol = {
                    buffer = pb,
                    offset = po + buffer.readi32(pb, po + 8 + (x - x1) * 4),
                }
                r_data.R_DrawColumnInCache(
                    patchcol, block, colofs[x + 1],
                    patch.originy, texture.height)
                x = x + 1
            end
        end
    end

    -- Now that the texture has been built in column cache, it is purgable
    -- from zone memory.
    z_zone.Z_ChangeTag(block, z_zone.PU_CACHE)
end

-- ---------------------------------------------------------------------------
-- R_GetColumn: return a { buffer, offset } pointing at the pixel data of
-- column `col` of texture `tex`.
-- ---------------------------------------------------------------------------

function r_data.R_GetColumn(tex, col)
    col = col % (r_state.texturewidthmask[tex + 1] + 1)

    local lump = r_state.texturecolumnlump[tex + 1][col + 1]
    local ofs = r_state.texturecolumnofs[tex + 1][col + 1]

    if lump > 0 then
        local view = w_wad.W_CacheLumpNum(lump, z_zone.PU_CACHE)
        return { buffer = view.buffer, offset = view.offset + ofs }
    end

    if r_state.texturecomposite[tex + 1] == nil then
        r_data.R_GenerateComposite(tex)
    end

    return { buffer = r_state.texturecomposite[tex + 1], offset = ofs }
end

-- ---------------------------------------------------------------------------
-- GenerateTextureHashTable: build the hash chains, appending at the end so
-- earlier textures in the array win (matches the C comment).
-- ---------------------------------------------------------------------------

local function GenerateTextureHashTable()
    r_state.textures_hashtable = {}
    for _ = 1, r_state.numtextures do
        table.insert(r_state.textures_hashtable, nil)
    end

    for i = 1, r_state.numtextures do
        local texture = r_state.textures[i]
        texture.index = i - 1

        local key = w_wad.W_LumpNameHash(texture.name) % r_state.numtextures
        local rover = r_state.textures_hashtable[key + 1]

        texture.next = nil

        if rover == nil then
            r_state.textures_hashtable[key + 1] = texture
        else
            -- walk to the end of the chain
            while rover.next ~= nil do
                rover = rover.next
            end
            rover.next = texture
        end
    end
end

-- ---------------------------------------------------------------------------
-- R_InitTextures
-- ---------------------------------------------------------------------------

function r_data.R_InitTextures()
    -- Load the patch names from pnames.lmp.
    local pnames = w_wad.W_CacheLumpName(deh_str.DEH_String("PNAMES"), z_zone.PU_STATIC)
    local nummappatches = buffer.readi32(pnames.buffer, pnames.offset)
    local patchlookup = {}

    for i = 0, nummappatches - 1 do
        local name = read_name(pnames.buffer, pnames.offset + 4 + i * 8)
        patchlookup[i + 1] = w_wad.W_CheckNumForName(name)
    end

    -- Load the map texture definitions from textures.lmp.
    local maptex1 = w_wad.W_CacheLumpName(deh_str.DEH_String("TEXTURE1"), z_zone.PU_STATIC)
    local numtextures1 = buffer.readi32(maptex1.buffer, maptex1.offset)
    local maxoff = w_wad.W_LumpLength(w_wad.W_GetNumForName(deh_str.DEH_String("TEXTURE1")))

    local maptex2 = nil
    local numtextures2 = 0
    local maxoff2 = 0
    if w_wad.W_CheckNumForName(deh_str.DEH_String("TEXTURE2")) ~= -1 then
        maptex2 = w_wad.W_CacheLumpName(deh_str.DEH_String("TEXTURE2"), z_zone.PU_STATIC)
        numtextures2 = buffer.readi32(maptex2.buffer, maptex2.offset)
        maxoff2 = w_wad.W_LumpLength(w_wad.W_GetNumForName(deh_str.DEH_String("TEXTURE2")))
    end

    r_state.numtextures = numtextures1 + numtextures2

    r_state.textures = {}
    r_state.texturecolumnlump = {}
    r_state.texturecolumnofs = {}
    r_state.texturecomposite = {}
    r_state.texturecompositesize = {}
    r_state.texturewidthmask = {}
    r_state.textureheight = {}

    -- maptex is the current texture lump view; directory is the 4-byte
    -- offset table that follows the count.
    local maptex = maptex1
    local maxoff_cur = maxoff
    local directory_ofs = maptex.offset + 4

    for i = 0, r_state.numtextures - 1 do
        if bit32.band(i, 63) == 0 then
            print(".")
        end

        if i == numtextures1 then
            -- Start looking in the second texture file.
            maptex = maptex2
            maxoff_cur = maxoff2
            directory_ofs = maptex.offset + 4
        end

        local offset = buffer.readi32(maptex.buffer, directory_ofs)
        directory_ofs = directory_ofs + 4

        if offset > maxoff_cur then
            i_system.I_Error("R_InitTextures: bad texture directory")
        end

        local mtexture_ofs = maptex.offset + offset
        local mb = maptex.buffer

        -- maptexture_t layout:
        --   name[8] (0), masked int (8), width short (12), height short (14),
        --   obsolete int (16), patchcount short (20), patches[1] (22).
        local texture = {
            name = read_name(mb, mtexture_ofs + 0),
            width = buffer.readi16(mb, mtexture_ofs + 12),
            height = buffer.readi16(mb, mtexture_ofs + 14),
            patchcount = buffer.readi16(mb, mtexture_ofs + 20),
            index = 0,
            next = nil,
            patches = {},
        }

        for j = 0, texture.patchcount - 1 do
            -- mappatch_t: originx(2) originy(2) patch(2) stepdir(2)
            -- colormap(2) => starts at mtexture_ofs + 22 + j*10
            local mp = mtexture_ofs + 22 + j * 10
            local patch = {
                originx = buffer.readi16(mb, mp),
                originy = buffer.readi16(mb, mp + 2),
                patch = patchlookup[buffer.readi16(mb, mp + 4) + 1],
            }
            if patch.patch == -1 then
                i_system.I_Error("R_InitTextures: Missing patch in texture %s",
                    texture.name)
            end
            table.insert(texture.patches, patch)
        end

        r_state.textures[i + 1] = texture

        r_state.texturecolumnlump[i + 1] = {}
        r_state.texturecolumnofs[i + 1] = {}
        for _ = 1, texture.width do
            table.insert(r_state.texturecolumnlump[i + 1], 0)
            table.insert(r_state.texturecolumnofs[i + 1], 0)
        end

        -- texturewidthmask: highest power-of-2 <= width, minus 1.
        local j = 1
        while j * 2 <= texture.width do
            j = j * 2
        end
        r_state.texturewidthmask[i + 1] = j - 1
        r_state.textureheight[i + 1] = texture.height * m_fixed.FRACUNIT
    end

    -- Precalculate whatever possible.
    for i = 0, r_state.numtextures - 1 do
        r_data.R_GenerateLookup(i)
    end

    -- Create translation table for global animation.
    r_state.texturetranslation = {}
    for i = 0, r_state.numtextures - 1 do
        r_state.texturetranslation[i + 1] = i
    end

    GenerateTextureHashTable()
end

-- ---------------------------------------------------------------------------
-- R_InitFlats
-- ---------------------------------------------------------------------------

function r_data.R_InitFlats()
    r_state.firstflat = w_wad.W_GetNumForName(deh_str.DEH_String("F_START")) + 1
    r_state.lastflat = w_wad.W_GetNumForName(deh_str.DEH_String("F_END")) - 1
    r_state.numflats = r_state.lastflat - r_state.firstflat + 1

    -- Create translation table for global animation.
    r_state.flattranslation = {}
    for i = 0, r_state.numflats - 1 do
        r_state.flattranslation[i + 1] = i
    end
end

-- ---------------------------------------------------------------------------
-- R_InitSpriteLumps
-- ---------------------------------------------------------------------------

function r_data.R_InitSpriteLumps()
    r_state.firstspritelump = w_wad.W_GetNumForName(deh_str.DEH_String("S_START")) + 1
    r_state.lastspritelump = w_wad.W_GetNumForName(deh_str.DEH_String("S_END")) - 1
    r_state.numspritelumps = r_state.lastspritelump - r_state.firstspritelump + 1

    r_state.spritewidth = {}
    r_state.spriteoffset = {}
    r_state.spritetopoffset = {}

    for i = 0, r_state.numspritelumps - 1 do
        if bit32.band(i, 63) == 0 then
            print(".")
        end

        local patch = w_wad.W_CacheLumpNum(r_state.firstspritelump + i, z_zone.PU_CACHE)
        local pb = patch.buffer
        local po = patch.offset
        r_state.spritewidth[i + 1] = buffer.readi16(pb, po) * m_fixed.FRACUNIT
        r_state.spriteoffset[i + 1] = buffer.readi16(pb, po + 4) * m_fixed.FRACUNIT
        r_state.spritetopoffset[i + 1] = buffer.readi16(pb, po + 6) * m_fixed.FRACUNIT
    end
end

-- ---------------------------------------------------------------------------
-- R_InitColormaps
-- ---------------------------------------------------------------------------

function r_data.R_InitColormaps()
    local lump = w_wad.W_GetNumForName(deh_str.DEH_String("COLORMAP"))
    r_state.colormaps = w_wad.W_CacheLumpNum(lump, z_zone.PU_STATIC)
end

-- ---------------------------------------------------------------------------
-- R_InitData
-- ---------------------------------------------------------------------------

function r_data.R_InitData()
    r_data.R_InitTextures()
    print(".")
    r_data.R_InitFlats()
    print(".")
    r_data.R_InitSpriteLumps()
    print(".")
    r_data.R_InitColormaps()
end

-- ---------------------------------------------------------------------------
-- R_FlatNumForName
-- ---------------------------------------------------------------------------

function r_data.R_FlatNumForName(name)
    local i = w_wad.W_CheckNumForName(name)
    if i == -1 then
        i_system.I_Error("R_FlatNumForName: %s not found", name)
    end
    return i - r_state.firstflat
end

-- ---------------------------------------------------------------------------
-- R_CheckTextureNumForName / R_TextureNumForName
-- ---------------------------------------------------------------------------

function r_data.R_CheckTextureNumForName(name)
    -- "NoTexture" marker.
    if string.sub(name, 1, 1) == "-" then
        return 0
    end

    local key = w_wad.W_LumpNameHash(name) % r_state.numtextures
    local texture = r_state.textures_hashtable[key + 1]

    while texture ~= nil do
        if name_matches(texture.name, name) then
            return texture.index
        end
        texture = texture.next
    end

    return -1
end

function r_data.R_TextureNumForName(name)
    local i = r_data.R_CheckTextureNumForName(name)
    if i == -1 then
        i_system.I_Error("R_TextureNumForName: %s not found", name)
    end
    return i
end

-- ---------------------------------------------------------------------------
-- R_PrecacheLevel
-- ---------------------------------------------------------------------------

function r_data.R_PrecacheLevel()

    if doomstat.demoplayback then
        return
    end

    -- Precache flats.
    local flatpresent = {}
    for _ = 1, r_state.numflats do
        table.insert(flatpresent, 0)
    end

    for _, sector in ipairs(r_state.sectors) do
        flatpresent[sector.floorpic + 1] = 1
        flatpresent[sector.ceilingpic + 1] = 1
    end

    for i = 0, r_state.numflats - 1 do
        if flatpresent[i + 1] ~= 0 then
            local lump = r_state.firstflat + i
            w_wad.W_CacheLumpNum(lump, z_zone.PU_CACHE)
        end
    end

    -- Precache textures.
    local texturepresent = {}
    for _ = 1, r_state.numtextures do
        table.insert(texturepresent, 0)
    end

    for _, side in ipairs(r_state.sides) do
        texturepresent[side.toptexture + 1] = 1
        texturepresent[side.midtexture + 1] = 1
        texturepresent[side.bottomtexture + 1] = 1
    end

    -- Sky texture is always present.
    texturepresent[r_state.skytexture + 1] = 1

    for i = 0, r_state.numtextures - 1 do
        if texturepresent[i + 1] ~= 0 then
            local texture = r_state.textures[i + 1]
            for _, patch in ipairs(texture.patches) do
                w_wad.W_CacheLumpNum(patch.patch, z_zone.PU_CACHE)
            end
        end
    end

    -- Precache sprites: the C scans the thinker list for mobjs with
    -- P_MobjThinker and marks their sprite numbers. Phase 4b links things
    -- into sectors / the thinker list, so this loop is now live.
    local spritepresent = {}
    for _ = 1, r_state.numsprites do
        table.insert(spritepresent, 0)
    end

    p_tick.iterateThinkers(function(mobj)
        if mobj.thinkfunc == -1 then
            return -- lazily-removed thinker
        end
        if mobj.sprite ~= nil then
            spritepresent[mobj.sprite + 1] = 1
        end
    end)

    for i = 0, r_state.numsprites - 1 do
        if spritepresent[i + 1] ~= 0 then
            local spr = r_state.sprites[i + 1]
            if spr.numframes > 0 then
                for j = 0, spr.numframes - 1 do
                    local sf = spr.spriteframes[j + 1]
                    for k = 0, 7 do
                        local lump = r_state.firstspritelump + sf.lump[k + 1]
                        w_wad.W_CacheLumpNum(lump, z_zone.PU_CACHE)
                    end
                end
            end
        end
    end
end

return r_data
end)()

r_plane = (function()
local r_plane = {}

local SCREENWIDTH = 320
local SCREENHEIGHT = 200
local MAXVISPLANES = 128
local MAXOPENINGS = SCREENWIDTH * 64

-- Preallocate the visplane/openings arrays (the C allocates them statically).
local function alloc_visplanes()
    r_state.visplanes = {}
    for _ = 1, MAXVISPLANES do
        local pl = {
            height = 0,
            picnum = 0,
            lightlevel = 0,
            minx = 0,
            maxx = 0,
            top = {},
            bottom = {},
        }
        for _ = 1, SCREENWIDTH + 2 do
            table.insert(pl.top, 0)
            table.insert(pl.bottom, 0)
        end
        table.insert(r_state.visplanes, pl)
    end
end

local function alloc_openings()
    r_state.openings = {}
    for _ = 1, MAXOPENINGS do
        table.insert(r_state.openings, 0)
    end
end

-- R_InitPlanes: only at game startup. The C body is empty ("Doh!").
function r_plane.R_InitPlanes()
    alloc_visplanes()
    alloc_openings()
end

-- ---------------------------------------------------------------------------
-- R_MapPlane
-- ---------------------------------------------------------------------------

function r_plane.R_MapPlane(y, x1, x2)
    local S = r_state

    if S.planeheight ~= S.cachedheight[y + 1] then
        S.cachedheight[y + 1] = S.planeheight
        local distance = m_fixed.FixedMul(S.planeheight, S.yslope[y + 1])
        S.cacheddistance[y + 1] = distance
        S.ds_xstep = m_fixed.FixedMul(distance, S.basexscale)
        S.cachedxstep[y + 1] = S.ds_xstep
        S.ds_ystep = m_fixed.FixedMul(distance, S.baseyscale)
        S.cachedystep[y + 1] = S.ds_ystep
    else
        local distance = S.cacheddistance[y + 1]
        S.ds_xstep = S.cachedxstep[y + 1]
        S.ds_ystep = S.cachedystep[y + 1]
    end

    local length = m_fixed.FixedMul(S.cacheddistance[y + 1], S.distscale[x1 + 1])

    local angle = bit32.rshift((S.viewangle + S.xtoviewangle[x1 + 1]) % 0x100000000,
        doomtype.ANGLETOFINESHIFT)

    S.ds_xfrac = (S.viewx + m_fixed.FixedMul(tables.finesine[angle + 2049], length)) % 0x100000000
    S.ds_yfrac = (-S.viewy - m_fixed.FixedMul(tables.finesine[angle + 1], length)) % 0x100000000

    if S.fixedcolormap ~= 0 then
        S.ds_colormap = S.fixedcolormap
    else
        local index = S.cacheddistance[y + 1] // 2 ^ 20 -- >> LIGHTZSHIFT
        if index >= 128 then -- MAXLIGHTZ
            index = 127
        end
        S.ds_colormap = S.planezlight[index + 1]
    end

    S.ds_y = y
    S.ds_x1 = x1
    S.ds_x2 = x2

    -- High or low detail.
    S.spanfunc()
end

-- ---------------------------------------------------------------------------
-- R_ClearPlanes
-- ---------------------------------------------------------------------------

function r_plane.R_ClearPlanes()
    local S = r_state

    -- Opening / clipping determination.
    for i = 0, S.viewwidth - 1 do
        S.floorclip[i + 1] = S.viewheight
        S.ceilingclip[i + 1] = -1
    end

    S.lastvisplane = 1
    S.lastopening = 1

    -- Texture calculation: C memsets cachedheight to 0 (keeps the array).
    for i = 1, 200 do
        S.cachedheight[i] = 0
    end

    -- Left to right mapping.
    local angle = bit32.rshift((S.viewangle - 0x40000000) % 0x100000000, 19)

    -- Scale will be unit scale at SCREENWIDTH/2 distance.
    S.basexscale = m_fixed.FixedDiv(tables.finesine[angle + 2049], S.centerxfrac)
    S.baseyscale = -m_fixed.FixedDiv(tables.finesine[angle + 1], S.centerxfrac)
end

-- ---------------------------------------------------------------------------
-- R_FindPlane
-- ---------------------------------------------------------------------------

function r_plane.R_FindPlane(height, picnum, lightlevel)
    local S = r_state

    if picnum == S.skyflatnum then
        height = 0 -- all skies map together
        lightlevel = 0
    end

    local found = nil
    for i = 1, S.lastvisplane - 1 do
        local check = S.visplanes[i]
        if height == check.height
            and picnum == check.picnum
            and lightlevel == check.lightlevel then
            found = check
            break
        end
    end

    if found ~= nil then
        return found
    end

    if S.lastvisplane - 1 == MAXVISPLANES then
        i_system.I_Error("R_FindPlane: no more visplanes")
    end

    local check = S.visplanes[S.lastvisplane]
    S.lastvisplane = S.lastvisplane + 1

    check.height = height
    check.picnum = picnum
    check.lightlevel = lightlevel
    check.minx = SCREENWIDTH
    check.maxx = -1

    -- memset(check->top, 0xff, sizeof(check->top)): real columns only.
    for i = 2, SCREENWIDTH + 1 do
        check.top[i] = 0xff
    end

    return check
end

-- ---------------------------------------------------------------------------
-- R_CheckPlane
-- ---------------------------------------------------------------------------

function r_plane.R_CheckPlane(pl, start, stop)
    local S = r_state

    local intrl, intrh, unionl, unionh

    if start < pl.minx then
        intrl = pl.minx
        unionl = start
    else
        unionl = pl.minx
        intrl = start
    end

    if stop > pl.maxx then
        intrh = pl.maxx
        unionh = stop
    else
        unionh = pl.maxx
        intrh = stop
    end

    local x = intrl
    while x <= intrh do
        if pl.top[x + 2] ~= 0xff then
            break
        end
        x = x + 1
    end

    if x > intrh then
        pl.minx = unionl
        pl.maxx = unionh

        -- Use the same one.
        return pl
    end

    -- Make a new visplane.
    local newpl = S.visplanes[S.lastvisplane]
    S.lastvisplane = S.lastvisplane + 1
    newpl.height = pl.height
    newpl.picnum = pl.picnum
    newpl.lightlevel = pl.lightlevel

    newpl.minx = start
    newpl.maxx = stop

    for i = 2, SCREENWIDTH + 1 do
        newpl.top[i] = 0xff
    end

    return newpl
end

-- ---------------------------------------------------------------------------
-- R_MakeSpans
-- ---------------------------------------------------------------------------

function r_plane.R_MakeSpans(x, t1, b1, t2, b2)
    local S = r_state

    while t1 < t2 and t1 <= b1 do
        r_plane.R_MapPlane(t1, S.spanstart[t1 + 1], x - 1)
        t1 = t1 + 1
    end
    while b1 > b2 and b1 >= t1 do
        r_plane.R_MapPlane(b1, S.spanstart[b1 + 1], x - 1)
        b1 = b1 - 1
    end

    while t2 < t1 and t2 <= b2 do
        S.spanstart[t2 + 1] = x
        t2 = t2 + 1
    end
    while b2 > b1 and b2 >= t2 do
        S.spanstart[b2 + 1] = x
        b2 = b2 - 1
    end
end

-- ---------------------------------------------------------------------------
-- R_DrawPlanes
-- ---------------------------------------------------------------------------

function r_plane.R_DrawPlanes()
    local S = r_state

    for i = 1, S.lastvisplane - 1 do
        local pl = S.visplanes[i]

        if pl.minx > pl.maxx then
            -- continue
        else
            -- Sky flat.
            if pl.picnum == S.skyflatnum then
                S.dc_iscale = S.pspriteiscale // 2 ^ S.detailshift

                -- Sky is always drawn full bright, i.e. colormaps[0] is used.
                -- Because of this hack, the sky is not affected by the INVUL
                -- inverse mapping.
                S.dc_colormap = S.colormaps.offset
                S.dc_texturemid = S.skytexturemid

                for x = pl.minx, pl.maxx do
                    S.dc_yl = pl.top[x + 2]
                    S.dc_yh = pl.bottom[x + 2]

                    if S.dc_yl <= S.dc_yh then
                        local angle = bit32.rshift(
                            (S.viewangle + S.xtoviewangle[x + 1]) % 0x100000000,
                            22) -- ANGLETOSKYSHIFT
                        S.dc_x = x
                        S.dc_source = r_data.R_GetColumn(S.skytexture, angle)
                        S.colfunc()
                    end
                end
            else
                -- Regular flat.
                local lumpnum = S.firstflat + S.flattranslation[pl.picnum + 1]
                S.ds_source = w_wad.W_CacheLumpNum(lumpnum, z_zone.PU_STATIC)

                S.planeheight = math.abs(pl.height - S.viewz)
                local light = (pl.lightlevel // 16) + S.extralight -- >> LIGHTSEGSHIFT

                if light >= 16 then -- LIGHTLEVELS
                    light = 15
                end
                if light < 0 then
                    light = 0
                end

                S.planezlight = S.zlight[light + 1]

                -- C: pl->top[pl->maxx+1] = 0xff; pl->top[pl->minx-1] = 0xff;
                pl.top[pl.maxx + 3] = 0xff
                pl.top[pl.minx + 1] = 0xff

                local stop = pl.maxx + 1

                for x = pl.minx, stop do
                    r_plane.R_MakeSpans(x,
                        pl.top[x + 1], pl.bottom[x + 1], -- C top[x-1], bottom[x-1]
                        pl.top[x + 2], pl.bottom[x + 2]) -- C top[x], bottom[x]
                end

                w_wad.W_ReleaseLumpNum(lumpnum)
            end
        end
    end
end

return r_plane
end)()

r_main = (function()
local r_main = {}

local SCREENWIDTH = 320
local SCREENHEIGHT = 200

local FIELDOFVIEW = 2048
local ANG90 = 0x40000000
local ANG180 = 0x80000000
local ANG270 = 0xc0000000

local LIGHTLEVELS = 16
local NUMCOLORMAPS = 32
local MAXLIGHTSCALE = 48
local MAXLIGHTZ = 128
local DISTMAP = 2

local NF_SUBSECTOR = 0x8000

-- Wrap a value to signed 32-bit (C int assignment semantics).
local function s32(x)
    -- return doomtype.u32_to_s32(x % 0x100000000)
    return doomtype.u32_to_s32(x)
end

-- ---------------------------------------------------------------------------
-- R_AddPointToBox
-- ---------------------------------------------------------------------------

function r_main.R_AddPointToBox(x, y, box)
    if x < box[3] then -- BOXLEFT
        box[3] = x
    elseif x > box[4] then -- BOXRIGHT
        box[4] = x
    end
    if y < box[2] then -- BOXBOTTOM
        box[2] = y
    elseif y > box[1] then -- BOXTOP
        box[1] = y
    end
end

-- ---------------------------------------------------------------------------
-- R_PointOnSide / R_PointOnSegSide
-- ---------------------------------------------------------------------------

function r_main.R_PointOnSide(x, y, node)
    local node_dx = node.dx
    local node_dy = node.dy

    if node_dx == 0 then
        if x <= node.x then
            return node_dy > 0 and 1 or 0
        end
        return node_dy < 0 and 1 or 0
    end
    if node_dy == 0 then
        if y <= node.y then
            return node_dx < 0 and 1 or 0
        end
        return node_dx > 0 and 1 or 0
    end

    -- C int subtraction wraps to 32-bit before the sign-bit trick.
    -- local dx = doomtype.u32_to_s32((x - node.x) % 0x100000000)
    -- local dy = doomtype.u32_to_s32((y - node.y) % 0x100000000)
    local dx = doomtype.u32_to_s32(x - node.x)
    local dy = doomtype.u32_to_s32(y - node.y)

    -- Try to quickly decide by looking at sign bits.
    -- if bit32.band(bit32.bxor(node_dy % 0x100000000, node_dx % 0x100000000,
    --     dx % 0x100000000, dy % 0x100000000), 0x80000000) ~= 0 then
    --     if bit32.band(bit32.bxor(node_dy % 0x100000000, dx % 0x100000000),
    --         0x80000000) ~= 0 then
    if bit32.band(bit32.bxor(node_dy, node_dx,
        dx, dy), 0x80000000) ~= 0 then
        if bit32.band(bit32.bxor(node_dy, dx),
            0x80000000) ~= 0 then
            -- (left is negative)
            return 1
        end
        return 0
    end

    local left = m_fixed.FixedMul(node_dy // 65536, dx) -- node->dy >> FRACBITS
    local right = m_fixed.FixedMul(dy, node_dx // 65536)

    if right < left then
        -- Front side.
        return 0
    end
    -- Back side.
    return 1
end

function r_main.R_PointOnSegSide(x, y, line)
    local lx = line.v1.x
    local ly = line.v1.y

    local ldx = line.v2.x - lx
    local ldy = line.v2.y - ly

    if ldx == 0 then
        if x <= lx then
            return ldy > 0 and 1 or 0
        end
        return ldy < 0 and 1 or 0
    end
    if ldy == 0 then
        if y <= ly then
            return ldx < 0 and 1 or 0
        end
        return ldx > 0 and 1 or 0
    end

    -- local dx = doomtype.u32_to_s32((x - lx) % 0x100000000)
    -- local dy = doomtype.u32_to_s32((y - ly) % 0x100000000)
    local dx = doomtype.u32_to_s32(x - lx)
    local dy = doomtype.u32_to_s32(y - ly)

    -- if bit32.band(bit32.bxor(ldy % 0x100000000, ldx % 0x100000000,
    --     dx % 0x100000000, dy % 0x100000000), 0x80000000) ~= 0 then
    --     if bit32.band(bit32.bxor(ldy % 0x100000000, dx % 0x100000000),
    --         0x80000000) ~= 0 then
    if bit32.band(bit32.bxor(ldy, ldx,
        dx, dy), 0x80000000) ~= 0 then
        if bit32.band(bit32.bxor(ldy, dx),
            0x80000000) ~= 0 then
            return 1
        end
        return 0
    end

    local left = m_fixed.FixedMul(ldy // 65536, dx)
    local right = m_fixed.FixedMul(dy, ldx // 65536)

    if right < left then
        return 0
    end
    return 1
end

-- ---------------------------------------------------------------------------
-- R_PointToAngle
-- ---------------------------------------------------------------------------

function r_main.R_PointToAngle(x, y)
    local S = r_state
    x = x - S.viewx
    y = y - S.viewy

    if x == 0 and y == 0 then
        return 0
    end

    if x >= 0 then
        -- x >= 0
        if y >= 0 then
            -- y >= 0
            if x > y then
                -- octant 0
                return tables.tantoangle[tables.SlopeDiv(y, x) + 1]
            else
                -- octant 1
                return (ANG90 - 1 - tables.tantoangle[tables.SlopeDiv(x, y) + 1]) % 0x100000000
            end
        else
            -- y < 0
            y = -y
            if x > y then
                -- octant 8
                return (-tables.tantoangle[tables.SlopeDiv(y, x) + 1]) % 0x100000000
            else
                -- octant 7
                return (ANG270 + tables.tantoangle[tables.SlopeDiv(x, y) + 1]) % 0x100000000
            end
        end
    else
        -- x < 0
        x = -x
        if y >= 0 then
            -- y >= 0
            if x > y then
                -- octant 3
                return (ANG180 - 1 - tables.tantoangle[tables.SlopeDiv(y, x) + 1]) % 0x100000000
            else
                -- octant 2
                return (ANG90 + tables.tantoangle[tables.SlopeDiv(x, y) + 1]) % 0x100000000
            end
        else
            -- y < 0
            y = -y
            if x > y then
                -- octant 4
                return (ANG180 + tables.tantoangle[tables.SlopeDiv(y, x) + 1]) % 0x100000000
            else
                -- octant 5
                return (ANG270 - 1 - tables.tantoangle[tables.SlopeDiv(x, y) + 1]) % 0x100000000
            end
        end
    end
    return 0
end

function r_main.R_PointToAngle2(x1, y1, x2, y2)
    r_state.viewx = x1
    r_state.viewy = y1
    return r_main.R_PointToAngle(x2, y2)
end

-- ---------------------------------------------------------------------------
-- R_PointToDist
-- ---------------------------------------------------------------------------

function r_main.R_PointToDist(x, y)
    local S = r_state

    -- local dx = math.abs(doomtype.u32_to_s32((x - S.viewx) % 0x100000000))
    -- local dy = math.abs(doomtype.u32_to_s32((y - S.viewy) % 0x100000000))
    local dx = math.abs(doomtype.u32_to_s32(x - S.viewx))
    local dy = math.abs(doomtype.u32_to_s32(y - S.viewy))

    if dy > dx then
        local temp = dx
        dx = dy
        dy = temp
    end

    -- Fix crashes in udm1.wad.
    local frac
    if dx ~= 0 then
        frac = m_fixed.FixedDiv(dy, dx)
    else
        frac = 0
    end

    -- DBITS = FRACBITS - SLOPEBITS = 5.
    local angle = bit32.rshift(
        (tables.tantoangle[frac // 32 + 1] + ANG90) % 0x100000000, 19)

    -- Use as cosine.
    return m_fixed.FixedDiv(dx, tables.finesine[angle + 1])
end

-- ---------------------------------------------------------------------------
-- R_InitPointToAngle / R_InitTables (no-ops: tables come from tables.c)
-- ---------------------------------------------------------------------------

function r_main.R_InitPointToAngle()
end

function r_main.R_InitTables()
end

-- ---------------------------------------------------------------------------
-- R_ScaleFromGlobalAngle
-- ---------------------------------------------------------------------------

function r_main.R_ScaleFromGlobalAngle(visangle)
    local S = r_state

    local anglea = (ANG90 + (visangle - S.viewangle)) % 0x100000000
    local angleb = (ANG90 + (visangle - S.rw_normalangle)) % 0x100000000

    -- Both sines are always positive.
    local sinea = tables.finesine[bit32.rshift(anglea, 19) + 1]
    local sineb = tables.finesine[bit32.rshift(angleb, 19) + 1]

    local num = doomtype.lshift32(m_fixed.FixedMul(S.projection, sineb), S.detailshift)
    local den = m_fixed.FixedMul(S.rw_distance, sinea)

    if den > num // 65536 then
        local scale = m_fixed.FixedDiv(num, den)

        if scale > 64 * 65536 then -- 64*FRACUNIT
            scale = 64 * 65536
        elseif scale < 256 then
            scale = 256
        end

        return scale
    end

    return 64 * 65536
end

-- ---------------------------------------------------------------------------
-- R_InitTextureMapping
-- ---------------------------------------------------------------------------

function r_main.R_InitTextureMapping()
    local S = r_state

    -- Use tangent table to generate viewangletox: viewangletox will give the
    -- next greatest x after the view angle. Calc focallength so
    -- FIELDOFVIEW angles covers SCREENWIDTH.
    local focallength = m_fixed.FixedDiv(S.centerxfrac,
        tables.finetangent[3073]) -- FINEANGLES/4 + FIELDOFVIEW/2

    for i = 0, 4095 do -- FINEANGLES/2
        local t
        local ft = tables.finetangent[i + 1]
        if ft > 2 * 65536 then -- FRACUNIT*2
            t = -1
        elseif ft < -2 * 65536 then
            t = S.viewwidth + 1
        else
            t = m_fixed.FixedMul(ft, focallength)
            t = (S.centerxfrac - t + 65535) // 65536 -- (..+FRACUNIT-1)>>FRACBITS

            if t < -1 then
                t = -1
            elseif t > S.viewwidth + 1 then
                t = S.viewwidth + 1
            end
        end
        S.viewangletox[i + 1] = t
    end

    -- Scan viewangletox[] to generate xtoviewangle[]: xtoviewangle will give
    -- the smallest view angle that maps to x.
    for x = 0, S.viewwidth do
        local i = 0
        while S.viewangletox[i + 1] > x do
            i = i + 1
        end
        S.xtoviewangle[x + 1] = (i * 2 ^ 19 - ANG90) % 0x100000000
    end

    -- Take out the fencepost cases from viewangletox.
    for i = 0, 4095 do
        local t = m_fixed.FixedMul(tables.finetangent[i + 1], focallength)
        t = S.centerx - t

        if S.viewangletox[i + 1] == -1 then
            S.viewangletox[i + 1] = 0
        elseif S.viewangletox[i + 1] == S.viewwidth + 1 then
            S.viewangletox[i + 1] = S.viewwidth
        end
    end

    S.clipangle = S.xtoviewangle[1]
end

-- ---------------------------------------------------------------------------
-- R_InitLightTables
-- ---------------------------------------------------------------------------

function r_main.R_InitLightTables()
    local S = r_state

    -- Calculate the light levels to use for each level / distance
    -- combination.
    for i = 0, LIGHTLEVELS - 1 do
        local startmap = ((LIGHTLEVELS - 1 - i) * 2) * NUMCOLORMAPS // LIGHTLEVELS
        S.zlight[i + 1] = {}
        for j = 0, MAXLIGHTZ - 1 do
            local scale = m_fixed.FixedDiv(SCREENWIDTH // 2 * 65536,
                (j + 1) * 2 ^ 20) -- (j+1)<<LIGHTZSHIFT
            scale = scale // 2 ^ 12 -- >>= LIGHTSCALESHIFT

            local level = startmap - scale // DISTMAP

            if level < 0 then
                level = 0
            end
            if level >= NUMCOLORMAPS then
                level = NUMCOLORMAPS - 1
            end

            S.zlight[i + 1][j + 1] = S.colormaps.offset + level * 256
        end
    end
end

-- ---------------------------------------------------------------------------
-- R_SetViewSize
-- ---------------------------------------------------------------------------

function r_main.R_SetViewSize(blocks, detail)
    r_state.setsizeneeded = true
    r_state.setblocks = blocks
    r_state.setdetail = detail
end

-- ---------------------------------------------------------------------------
-- R_ExecuteSetViewSize
-- ---------------------------------------------------------------------------

function r_main.R_ExecuteSetViewSize()
    local S = r_state

    S.setsizeneeded = false

    if S.setblocks == 11 then
        S.scaledviewwidth = SCREENWIDTH
        S.viewheight = SCREENHEIGHT
    else
        S.scaledviewwidth = S.setblocks * 32
        S.viewheight = bit32.band(S.setblocks * 168 // 10, bit32.bnot(7))
    end

    S.detailshift = S.setdetail
    S.viewwidth = S.scaledviewwidth // 2 ^ S.detailshift

    S.centery = S.viewheight // 2
    S.centerx = S.viewwidth // 2
    S.centerxfrac = S.centerx * 65536
    S.centeryfrac = S.centery * 65536
    S.projection = S.centerxfrac

    if S.detailshift == 0 then
        S.colfunc = r_draw.R_DrawColumn
        S.basecolfunc = r_draw.R_DrawColumn
        S.fuzzcolfunc = r_draw.R_DrawFuzzColumn
        S.transcolfunc = r_draw.R_DrawTranslatedColumn
        S.spanfunc = r_draw.R_DrawSpan
    else
        S.colfunc = r_draw.R_DrawColumnLow
        S.basecolfunc = r_draw.R_DrawColumnLow
        S.fuzzcolfunc = r_draw.R_DrawFuzzColumnLow
        S.transcolfunc = r_draw.R_DrawTranslatedColumnLow
        S.spanfunc = r_draw.R_DrawSpanLow
    end

    r_draw.R_InitBuffer(S.scaledviewwidth, S.viewheight)

    r_main.R_InitTextureMapping()

    -- Psprite scales.
    S.pspritescale = 65536 * S.viewwidth // SCREENWIDTH -- FRACUNIT*viewwidth/SCREENWIDTH
    S.pspriteiscale = 65536 * SCREENWIDTH // S.viewwidth -- FRACUNIT*SCREENWIDTH/viewwidth

    -- Thing clipping.
    for i = 0, S.viewwidth - 1 do
        S.screenheightarray[i + 1] = S.viewheight
    end

    -- Planes.
    for i = 0, S.viewheight - 1 do
        local dy = ((i - S.viewheight // 2) * 65536) + 32768
        dy = math.abs(dy)
        S.yslope[i + 1] = m_fixed.FixedDiv(
            ((S.viewwidth * 2 ^ S.detailshift) // 2) * 65536, dy)
    end

    for i = 0, S.viewwidth - 1 do
        local cosadj = math.abs(tables.finesine[
            bit32.rshift(S.xtoviewangle[i + 1], 19) + 2049])
        S.distscale[i + 1] = m_fixed.FixedDiv(65536, cosadj)
    end

    -- Calculate the light levels to use for each level / scale combination.
    for i = 0, LIGHTLEVELS - 1 do
        local startmap = ((LIGHTLEVELS - 1 - i) * 2) * NUMCOLORMAPS // LIGHTLEVELS
        S.scalelight[i + 1] = {}
        for j = 0, MAXLIGHTSCALE - 1 do
            local level = startmap - (j * SCREENWIDTH) // S.scaledviewwidth // DISTMAP

            if level < 0 then
                level = 0
            end
            if level >= NUMCOLORMAPS then
                level = NUMCOLORMAPS - 1
            end

            S.scalelight[i + 1][j + 1] = S.colormaps.offset + level * 256
        end
    end
end

-- ---------------------------------------------------------------------------
-- R_Init
-- ---------------------------------------------------------------------------

function r_main.R_Init()
    r_data.R_InitData()
    print(".")
    r_main.R_InitPointToAngle()
    print(".")
    r_main.R_InitTables()
    -- Viewwidth / viewheight / detailLevel are set by the defaults.
    print(".")

    r_main.R_SetViewSize(doomstat.screenblocks, doomstat.detailLevel)
    r_plane.R_InitPlanes()
    print(".")
    r_main.R_InitLightTables()
    print(".")
    r_sky.R_InitSkyMap()
    r_draw.R_InitTranslationTables()
    print(".")

    r_state.framecount = 0
end

-- ---------------------------------------------------------------------------
-- R_PointInSubsector
-- ---------------------------------------------------------------------------

function r_main.R_PointInSubsector(x, y)
    local S = r_state

    -- Single subsector is a special case.
    if S.numnodes == 0 then
        return S.subsectors[1]
    end

    local nodenum = S.numnodes - 1

    while bit32.band(nodenum % 0x100000000, NF_SUBSECTOR) == 0 do
        local node = S.nodes[nodenum + 1]
        local side = r_main.R_PointOnSide(x, y, node)
        nodenum = node.children[side + 1]
    end

    return S.subsectors[bit32.band(nodenum, bit32.bnot(NF_SUBSECTOR)) + 1]
end

-- ---------------------------------------------------------------------------
-- R_SetupFrame
-- ---------------------------------------------------------------------------

function r_main.R_SetupFrame(player)
    local S = r_state

    S.viewplayer = player
    S.viewx = player.mo.x
    S.viewy = player.mo.y
    S.viewangle = (player.mo.angle + S.viewangleoffset) % 0x100000000
    S.extralight = player.extralight

    S.viewz = player.viewz

    S.viewsin = tables.finesine[bit32.rshift(S.viewangle, 19) + 1]
    S.viewcos = tables.finesine[bit32.rshift(S.viewangle, 19) + 2049]

    S.sscount = 0

    if player.fixedcolormap ~= 0 then
        S.fixedcolormap = S.colormaps.offset + player.fixedcolormap * 256

        S.walllights = S.scalelightfixed
        for i = 1, MAXLIGHTSCALE do
            S.scalelightfixed[i] = S.fixedcolormap
        end
    else
        S.fixedcolormap = 0
    end

    S.framecount = S.framecount + 1
    S.validcount = S.validcount + 1
end

-- ---------------------------------------------------------------------------
-- R_RenderPlayerView
-- ---------------------------------------------------------------------------

function r_main.R_RenderPlayerView(player)
    r_main.R_SetupFrame(player)

    -- Clear buffers.
    r_bsp.R_ClearClipSegs()
    r_bsp.R_ClearDrawSegs()
    r_plane.R_ClearPlanes()
    r_things.R_ClearSprites()

    -- Check for new console commands.
    d_loop.NetUpdate()

    -- The head node is the last node output.
    r_bsp.R_RenderBSPNode(r_state.numnodes - 1)

    -- Check for new console commands.
    d_loop.NetUpdate()

    r_plane.R_DrawPlanes()

    -- Check for new console commands.
    d_loop.NetUpdate()

    r_things.R_DrawMasked()

    -- Check for new console commands.
    d_loop.NetUpdate()
end

return r_main
end)()

r_segs = (function()
local r_segs = {}

-- r_segs.h constants.
local HEIGHTBITS = 12
local HEIGHTUNIT = 2 ^ HEIGHTBITS

local SHRT_MAX = 32767
local INT_MAX = 2147483647
local INT_MIN = -2147483648

local LIGHTLEVELS = 16
local LIGHTSEGSHIFT = 4
local MAXLIGHTSCALE = 48
local LIGHTSCALESHIFT = 12

local ANG90 = 0x40000000
local ANG180 = 0x80000000

local ML_DONTPEGBOTTOM = 16
local ML_DONTPEGTOP = 8

local SIL_NONE = 0
local SIL_BOTTOM = 1
local SIL_TOP = 2
local SIL_BOTH = 3

-- Wrap a value to signed 32-bit (C int assignment semantics).
local function s32(x)
    return doomtype.u32_to_s32(x % 0x100000000)
end

-- ---------------------------------------------------------------------------
-- R_RenderMaskedSegRange
-- ---------------------------------------------------------------------------

function r_segs.R_RenderMaskedSegRange(ds, x1, x2)
    local S = r_state

    -- Calculate light table. Use different light tables for horizontal /
    -- vertical / diagonal. OPTIMIZE: get rid of LIGHTSEGSHIFT globally.
    S.curline = ds.curline
    S.frontsector = S.curline.frontsector
    S.backsector = S.curline.backsector
    local texnum = S.texturetranslation[S.curline.sidedef.midtexture + 1]

    local lightnum = (S.frontsector.lightlevel // LIGHTSEGSHIFT) + S.extralight

    if S.curline.v1.y == S.curline.v2.y then
        lightnum = lightnum - 1
    elseif S.curline.v1.x == S.curline.v2.x then
        lightnum = lightnum + 1
    end

    if lightnum < 0 then
        S.walllights = S.scalelight[1]
    elseif lightnum >= LIGHTLEVELS then
        S.walllights = S.scalelight[LIGHTLEVELS]
    else
        S.walllights = S.scalelight[lightnum + 1]
    end

    local maskedtexturecol = ds.maskedtexturecol

    S.rw_scalestep = ds.scalestep
    S.spryscale = ds.scale1 + (x1 - ds.x1) * S.rw_scalestep
    S.mfloorclip = ds.sprbottomclip
    S.mceilingclip = ds.sprtopclip

    -- Find positioning.
    if bit32.band(S.curline.linedef.flags, ML_DONTPEGBOTTOM) ~= 0 then
        S.dc_texturemid = S.frontsector.floorheight > S.backsector.floorheight
            and S.frontsector.floorheight or S.backsector.floorheight
        S.dc_texturemid = S.dc_texturemid + S.textureheight[texnum + 1] - S.viewz
    else
        S.dc_texturemid = S.frontsector.ceilingheight < S.backsector.ceilingheight
            and S.frontsector.ceilingheight or S.backsector.ceilingheight
        S.dc_texturemid = S.dc_texturemid - S.viewz
    end
    S.dc_texturemid = s32(S.dc_texturemid + S.curline.sidedef.rowoffset)

    if S.fixedcolormap ~= 0 then
        S.dc_colormap = S.fixedcolormap
    end

    -- Draw the columns.
    for dc_x = x1, x2 do
        -- Calculate lighting.
        if maskedtexturecol[dc_x + 1] ~= SHRT_MAX then
            if S.fixedcolormap == 0 then
                local index = S.spryscale // 2 ^ LIGHTSCALESHIFT -- >> LIGHTSCALESHIFT
                if index >= MAXLIGHTSCALE then
                    index = MAXLIGHTSCALE - 1
                end
                S.dc_colormap = S.walllights[index + 1]
            end

            S.sprtopscreen = S.centeryfrac - m_fixed.FixedMul(S.dc_texturemid, S.spryscale)
            S.dc_iscale = 0xffffffff // (S.spryscale % 0x100000000)

            -- Draw the texture.
            local col = r_data.R_GetColumn(texnum, maskedtexturecol[dc_x + 1])
            col.offset = col.offset - 3
            r_things.R_DrawMaskedColumn(col)
            maskedtexturecol[dc_x + 1] = SHRT_MAX
        end
        S.spryscale = S.spryscale + S.rw_scalestep
    end
end

-- ---------------------------------------------------------------------------
-- R_RenderSegLoop
-- ---------------------------------------------------------------------------

function r_segs.R_RenderSegLoop()
    local S = r_state

    while S.rw_x < S.rw_stopx do
        -- Mark floor / ceiling areas.
        local yl = (S.topfrac + HEIGHTUNIT - 1) // HEIGHTUNIT -- >> HEIGHTBITS

        -- No space above wall?
        if yl < S.ceilingclip[S.rw_x + 1] + 1 then
            yl = S.ceilingclip[S.rw_x + 1] + 1
        end

        if S.markceiling then
            local top = S.ceilingclip[S.rw_x + 1] + 1
            local bottom = yl - 1

            if bottom >= S.floorclip[S.rw_x + 1] then
                bottom = S.floorclip[S.rw_x + 1] - 1
            end

            if top <= bottom then
                S.ceilingplane.top[S.rw_x + 2] = top
                S.ceilingplane.bottom[S.rw_x + 2] = bottom
            end
        end

        local yh = S.bottomfrac // HEIGHTUNIT -- >> HEIGHTBITS

        if yh >= S.floorclip[S.rw_x + 1] then
            yh = S.floorclip[S.rw_x + 1] - 1
        end

        if S.markfloor then
            local top = yh + 1
            local bottom = S.floorclip[S.rw_x + 1] - 1
            if top <= S.ceilingclip[S.rw_x + 1] then
                top = S.ceilingclip[S.rw_x + 1] + 1
            end
            if top <= bottom then
                S.floorplane.top[S.rw_x + 2] = top
                S.floorplane.bottom[S.rw_x + 2] = bottom
            end
        end

        -- Texturecolumn and lighting are independent of wall tiers.
        local texturecolumn = 0
        if S.segtextured then
            -- Calculate texture offset.
            local angle = bit32.rshift(
                (S.rw_centerangle + S.xtoviewangle[S.rw_x + 1]) % 0x100000000,
                19) -- ANGLETOFINESHIFT
            texturecolumn = S.rw_offset - m_fixed.FixedMul(tables.finetangent[angle + 1], S.rw_distance)
            texturecolumn = texturecolumn // 65536 -- >> FRACBITS

            -- Calculate lighting.
            local index = S.rw_scale // 2 ^ LIGHTSCALESHIFT -- >> LIGHTSCALESHIFT
            if index >= MAXLIGHTSCALE then
                index = MAXLIGHTSCALE - 1
            end

            S.dc_colormap = S.walllights[index + 1]
            S.dc_x = S.rw_x
            S.dc_iscale = 0xffffffff // (S.rw_scale % 0x100000000)
        end

        -- Draw the wall tiers.
        if S.midtexture ~= 0 then
            -- Single sided line.
            S.dc_yl = yl
            S.dc_yh = yh
            S.dc_texturemid = S.rw_midtexturemid
            S.dc_source = r_data.R_GetColumn(S.midtexture, texturecolumn)
            S.colfunc()
            S.ceilingclip[S.rw_x + 1] = S.viewheight
            S.floorclip[S.rw_x + 1] = -1
        else
            -- Two sided line.
            if S.toptexture ~= 0 then
                -- Top wall.
                local mid = S.pixhigh // HEIGHTUNIT -- >> HEIGHTBITS
                S.pixhigh = S.pixhigh + S.pixhighstep

                if mid >= S.floorclip[S.rw_x + 1] then
                    mid = S.floorclip[S.rw_x + 1] - 1
                end

                if mid >= yl then
                    S.dc_yl = yl
                    S.dc_yh = mid
                    S.dc_texturemid = S.rw_toptexturemid
                    S.dc_source = r_data.R_GetColumn(S.toptexture, texturecolumn)
                    S.colfunc()
                    S.ceilingclip[S.rw_x + 1] = mid
                else
                    S.ceilingclip[S.rw_x + 1] = yl - 1
                end
            else
                -- No top wall.
                if S.markceiling then
                    S.ceilingclip[S.rw_x + 1] = yl - 1
                end
            end

            if S.bottomtexture ~= 0 then
                -- Bottom wall.
                local mid = (S.pixlow + HEIGHTUNIT - 1) // HEIGHTUNIT -- >> HEIGHTBITS
                S.pixlow = S.pixlow + S.pixlowstep

                -- No space above wall?
                if mid <= S.ceilingclip[S.rw_x + 1] then
                    mid = S.ceilingclip[S.rw_x + 1] + 1
                end

                if mid <= yh then
                    S.dc_yl = mid
                    S.dc_yh = yh
                    S.dc_texturemid = S.rw_bottomtexturemid
                    S.dc_source = r_data.R_GetColumn(S.bottomtexture, texturecolumn)
                    S.colfunc()
                    S.floorclip[S.rw_x + 1] = mid
                else
                    S.floorclip[S.rw_x + 1] = yh + 1
                end
            else
                -- No bottom wall.
                if S.markfloor then
                    S.floorclip[S.rw_x + 1] = yh + 1
                end
            end

            if S.maskedtexture then
                -- Save texturecol for backdrawing of masked mid texture.
                S.maskedtexturecol[S.rw_x + 1] = texturecolumn
            end
        end

        S.rw_scale = S.rw_scale + S.rw_scalestep
        S.topfrac = S.topfrac + S.topstep
        S.bottomfrac = S.bottomfrac + S.bottomstep
        S.rw_x = S.rw_x + 1
    end
end

-- ---------------------------------------------------------------------------
-- R_StoreWallRange
-- ---------------------------------------------------------------------------

function r_segs.R_StoreWallRange(start, stop)
    local S = r_state

    -- Don't overflow and crash.
    if S.ds_p == 257 then -- MAXDRAWSEGS + 1 (1-based next-free)
        return
    end

    S.sidedef = S.curline.sidedef
    S.linedef = S.curline.linedef

    -- Mark the segment as visible for the automap.
    S.linedef.flags = bit32.bor(S.linedef.flags, 256) -- ML_MAPPED

    -- Calculate rw_distance for scale calculation.
    S.rw_normalangle = (S.curline.angle + ANG90) % 0x100000000

    local offsetangle = math.abs(doomtype.u32_to_s32(
        (S.rw_normalangle - S.rw_angle1) % 0x100000000))
    if offsetangle > ANG90 then
        offsetangle = ANG90
    end

    local distangle = ANG90 - offsetangle
    local hyp = r_main.R_PointToDist(S.curline.v1.x, S.curline.v1.y)
    local sineval = tables.finesine[bit32.rshift(distangle, 19) + 1]
    S.rw_distance = m_fixed.FixedMul(hyp, sineval)

    local ds = S.drawsegs[S.ds_p]
    ds.x1 = start
    ds.x2 = stop
    ds.curline = S.curline
    S.rw_x = start
    S.rw_stopx = stop + 1

    -- Calculate scale at both ends and step.
    ds.scale1 = r_main.R_ScaleFromGlobalAngle(
        (S.viewangle + S.xtoviewangle[start + 1]) % 0x100000000)
    S.rw_scale = ds.scale1

    if stop > start then
        ds.scale2 = r_main.R_ScaleFromGlobalAngle(
            (S.viewangle + S.xtoviewangle[stop + 1]) % 0x100000000)
        ds.scalestep = doomtype.truncdiv(
            doomtype.u32_to_s32((ds.scale2 - S.rw_scale) % 0x100000000),
            stop - start)
        S.rw_scalestep = ds.scalestep
    else
        ds.scale2 = ds.scale1
    end

    -- Calculate texture boundaries and decide if floor/ceiling marks are
    -- needed.
    S.worldtop = S.frontsector.ceilingheight - S.viewz
    S.worldbottom = S.frontsector.floorheight - S.viewz

    S.midtexture = 0
    S.toptexture = 0
    S.bottomtexture = 0
    S.maskedtexture = false
    ds.maskedtexturecol = nil
    S.maskedtexturecol = nil

    if S.backsector == nil then
        -- Single sided line.
        S.midtexture = S.texturetranslation[S.sidedef.midtexture + 1]
        -- A single sided line is terminal, so it must mark ends.
        S.markfloor = true
        S.markceiling = true

        if bit32.band(S.linedef.flags, ML_DONTPEGBOTTOM) ~= 0 then
            -- Bottom of texture at bottom.
            local vtop = S.frontsector.floorheight + S.textureheight[S.sidedef.midtexture + 1]
            S.rw_midtexturemid = vtop - S.viewz
        else
            -- Top of texture at top.
            S.rw_midtexturemid = S.worldtop
        end
        S.rw_midtexturemid = s32(S.rw_midtexturemid + S.sidedef.rowoffset)

        ds.silhouette = SIL_BOTH
        ds.sprtopclip = S.screenheightarray
        ds.sprbottomclip = S.negonearray
        ds.bsilheight = INT_MAX
        ds.tsilheight = INT_MIN
    else
        -- Two sided line.
        ds.sprtopclip = nil
        ds.sprbottomclip = nil
        ds.silhouette = SIL_NONE

        if S.frontsector.floorheight > S.backsector.floorheight then
            ds.silhouette = SIL_BOTTOM
            ds.bsilheight = S.frontsector.floorheight
        elseif S.backsector.floorheight > S.viewz then
            ds.silhouette = SIL_BOTTOM
            ds.bsilheight = INT_MAX
        end

        if S.frontsector.ceilingheight < S.backsector.ceilingheight then
            ds.silhouette = bit32.bor(ds.silhouette, SIL_TOP)
            ds.tsilheight = S.frontsector.ceilingheight
        elseif S.backsector.ceilingheight < S.viewz then
            ds.silhouette = bit32.bor(ds.silhouette, SIL_TOP)
            ds.tsilheight = INT_MIN
        end

        if S.backsector.ceilingheight <= S.frontsector.floorheight then
            ds.sprbottomclip = S.negonearray
            ds.bsilheight = INT_MAX
            ds.silhouette = bit32.bor(ds.silhouette, SIL_BOTTOM)
        end

        if S.backsector.floorheight >= S.frontsector.ceilingheight then
            ds.sprtopclip = S.screenheightarray
            ds.tsilheight = INT_MIN
            ds.silhouette = bit32.bor(ds.silhouette, SIL_TOP)
        end

        S.worldhigh = S.backsector.ceilingheight - S.viewz
        S.worldlow = S.backsector.floorheight - S.viewz

        -- Hack to allow height changes in outdoor areas.
        if S.frontsector.ceilingpic == S.skyflatnum
            and S.backsector.ceilingpic == S.skyflatnum then
            S.worldtop = S.worldhigh
        end

        if S.worldlow ~= S.worldbottom
            or S.backsector.floorpic ~= S.frontsector.floorpic
            or S.backsector.lightlevel ~= S.frontsector.lightlevel then
            S.markfloor = true
        else
            -- Same plane on both sides.
            S.markfloor = false
        end

        if S.worldhigh ~= S.worldtop
            or S.backsector.ceilingpic ~= S.frontsector.ceilingpic
            or S.backsector.lightlevel ~= S.frontsector.lightlevel then
            S.markceiling = true
        else
            -- Same plane on both sides.
            S.markceiling = false
        end

        -- Closed door.
        if S.backsector.ceilingheight <= S.frontsector.floorheight
            or S.backsector.floorheight >= S.frontsector.ceilingheight then
            S.markceiling = true
            S.markfloor = true
        end

        if S.worldhigh < S.worldtop then
            -- Top texture.
            S.toptexture = S.texturetranslation[S.sidedef.toptexture + 1]
            if bit32.band(S.linedef.flags, ML_DONTPEGTOP) ~= 0 then
                -- Top of texture at top.
                S.rw_toptexturemid = S.worldtop
            else
                -- Bottom of texture.
                local vtop = S.backsector.ceilingheight + S.textureheight[S.sidedef.toptexture + 1]
                S.rw_toptexturemid = vtop - S.viewz
            end
        end

        if S.worldlow > S.worldbottom then
            -- Bottom texture.
            S.bottomtexture = S.texturetranslation[S.sidedef.bottomtexture + 1]
            if bit32.band(S.linedef.flags, ML_DONTPEGBOTTOM) ~= 0 then
                -- Bottom of texture at bottom; top of texture at top.
                S.rw_bottomtexturemid = S.worldtop
            else
                -- Top of texture at top.
                S.rw_bottomtexturemid = S.worldlow
            end
        end
        S.rw_toptexturemid = s32(S.rw_toptexturemid + S.sidedef.rowoffset)
        S.rw_bottomtexturemid = s32(S.rw_bottomtexturemid + S.sidedef.rowoffset)

        -- Allocate space for masked texture tables.
        if S.sidedef.midtexture ~= 0 then
            -- Masked midtexture.
            S.maskedtexture = true
            ds.maskedtexturecol = {}
            S.maskedtexturecol = ds.maskedtexturecol
            S.lastopening = S.lastopening + (S.rw_stopx - S.rw_x)
        end
    end

    -- Calculate rw_offset (only needed for textured lines).
    S.segtextured = S.midtexture ~= 0
        or S.toptexture ~= 0
        or S.bottomtexture ~= 0
        or S.maskedtexture

    if S.segtextured then
        local offdiff = (S.rw_normalangle - S.rw_angle1) % 0x100000000
        local offsetangle2 = offdiff
        if offsetangle2 > ANG180 then
            offsetangle2 = 0x100000000 - offsetangle2
        end
        if offsetangle2 > ANG90 then
            offsetangle2 = ANG90
        end

        local sineval2 = tables.finesine[bit32.rshift(offsetangle2, 19) + 1]
        S.rw_offset = m_fixed.FixedMul(hyp, sineval2)

        if offdiff < ANG180 then
            S.rw_offset = -S.rw_offset
        end

        S.rw_offset = s32(S.rw_offset + S.sidedef.textureoffset + S.curline.offset)
        S.rw_centerangle = (ANG90 + S.viewangle - S.rw_normalangle) % 0x100000000

        -- Calculate light table; use different light tables for horizontal /
        -- vertical / diagonal. OPTIMIZE: get rid of LIGHTSEGSHIFT globally.
        if S.fixedcolormap == 0 then
            local lightnum = (S.frontsector.lightlevel // LIGHTSEGSHIFT) + S.extralight

            if S.curline.v1.y == S.curline.v2.y then
                lightnum = lightnum - 1
            elseif S.curline.v1.x == S.curline.v2.x then
                lightnum = lightnum + 1
            end

            if lightnum < 0 then
                S.walllights = S.scalelight[1]
            elseif lightnum >= LIGHTLEVELS then
                S.walllights = S.scalelight[LIGHTLEVELS]
            else
                S.walllights = S.scalelight[lightnum + 1]
            end
        end
    end

    -- If a floor/ceiling plane is on the wrong side of the view plane, it is
    -- definitely invisible and doesn't need to be marked.
    if S.frontsector.floorheight >= S.viewz then
        -- Above view plane.
        S.markfloor = false
    end

    if S.frontsector.ceilingheight <= S.viewz
        and S.frontsector.ceilingpic ~= S.skyflatnum then
        -- Below view plane.
        S.markceiling = false
    end

    -- Calculate incremental stepping values for texture edges.
    S.worldtop = S.worldtop // 16 -- >>= 4
    S.worldbottom = S.worldbottom // 16

    S.topstep = -m_fixed.FixedMul(S.rw_scalestep, S.worldtop)
    S.topfrac = (S.centeryfrac // 16) - m_fixed.FixedMul(S.worldtop, S.rw_scale)

    S.bottomstep = -m_fixed.FixedMul(S.rw_scalestep, S.worldbottom)
    S.bottomfrac = (S.centeryfrac // 16) - m_fixed.FixedMul(S.worldbottom, S.rw_scale)

    if S.backsector ~= nil then
        S.worldhigh = S.worldhigh // 16
        S.worldlow = S.worldlow // 16

        if S.worldhigh < S.worldtop then
            S.pixhigh = (S.centeryfrac // 16) - m_fixed.FixedMul(S.worldhigh, S.rw_scale)
            S.pixhighstep = -m_fixed.FixedMul(S.rw_scalestep, S.worldhigh)
        end

        if S.worldlow > S.worldbottom then
            S.pixlow = (S.centeryfrac // 16) - m_fixed.FixedMul(S.worldlow, S.rw_scale)
            S.pixlowstep = -m_fixed.FixedMul(S.rw_scalestep, S.worldlow)
        end
    end

    -- Render it.
    if S.markceiling then
        S.ceilingplane = r_plane.R_CheckPlane(S.ceilingplane, S.rw_x, S.rw_stopx - 1)
    end

    if S.markfloor then
        S.floorplane = r_plane.R_CheckPlane(S.floorplane, S.rw_x, S.rw_stopx - 1)
    end

    r_segs.R_RenderSegLoop()

    -- Save sprite clipping info.
    if (bit32.band(ds.silhouette, SIL_TOP) ~= 0 or S.maskedtexture)
        and ds.sprtopclip == nil then
        ds.sprtopclip = {}
        for x = start, S.rw_stopx - 1 do
            ds.sprtopclip[x + 1] = S.ceilingclip[x + 1]
        end
        S.lastopening = S.lastopening + (S.rw_stopx - start)
    end

    if (bit32.band(ds.silhouette, SIL_BOTTOM) ~= 0 or S.maskedtexture)
        and ds.sprbottomclip == nil then
        ds.sprbottomclip = {}
        for x = start, S.rw_stopx - 1 do
            ds.sprbottomclip[x + 1] = S.floorclip[x + 1]
        end
        S.lastopening = S.lastopening + (S.rw_stopx - start)
    end

    if S.maskedtexture and bit32.band(ds.silhouette, SIL_TOP) == 0 then
        ds.silhouette = bit32.bor(ds.silhouette, SIL_TOP)
        ds.tsilheight = INT_MIN
    end
    if S.maskedtexture and bit32.band(ds.silhouette, SIL_BOTTOM) == 0 then
        ds.silhouette = bit32.bor(ds.silhouette, SIL_BOTTOM)
        ds.bsilheight = INT_MAX
    end

    S.ds_p = S.ds_p + 1
end

return r_segs
end)()

r_things = (function()
local r_things = {}

local SCREENWIDTH = 320

local MINZ = m_fixed.FRACUNIT * 4
local BASEYCENTER = 100

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

local MAXFRAMES = 29

-- sprtemp[1..29]: the spriteframe scratch used while scanning a sprite name.
local sprtemp = {}
local function clear_sprtemp()
    sprtemp = {}
    for _ = 1, MAXFRAMES do
        local sf = {
            rotate = -1, -- -1 = no frames found, 0 = rot=0 only, 1 = rotations
            lump = {},
            flip = {},
        }
        for r = 1, 8 do
            sf.lump[r] = -1
            sf.flip[r] = 0
        end
        table.insert(sprtemp, sf)
    end
end

local maxframe = -1
local spritename = ""

-- Case-insensitive prefix compare (strncasecmp up to n).
local function name_matches_n(stored, name, n)
    for i = 1, n do
        local sc = string.byte(stored, i)
        local nc = string.byte(name, i)
        if sc == nil or nc == nil or sc == 0 or nc == 0 then
            return true
        end
        local su = sc >= 97 and sc <= 122 and (sc - 32) or sc
        local nu = nc >= 97 and nc <= 122 and (nc - 32) or nc
        if su ~= nu then
            return false
        end
    end
    return true
end

-- ---------------------------------------------------------------------------
-- R_InstallSpriteLump
-- ---------------------------------------------------------------------------

local function R_InstallSpriteLump(lump, frame, rotation, flipped)
    if frame >= 29 or rotation > 8 then
        i_system.I_Error("R_InstallSpriteLump: Bad frame characters in lump %i", lump)
    end

    if frame > maxframe then
        maxframe = frame
    end

    if rotation == 0 then
        -- The lump should be used for all rotations.
        if sprtemp[frame + 1].rotate == 0 then
            i_system.I_Error("R_InitSprites: Sprite %s frame %c has multip rot=0 lump",
                spritename, string.char(string.byte("A") + frame))
        end
        if sprtemp[frame + 1].rotate == 1 then
            i_system.I_Error("R_InitSprites: Sprite %s frame %c has rotations and a rot=0 lump",
                spritename, string.char(string.byte("A") + frame))
        end

        sprtemp[frame + 1].rotate = 0
        for r = 1, 8 do
            sprtemp[frame + 1].lump[r] = lump - r_state.firstspritelump
            sprtemp[frame + 1].flip[r] = flipped and 1 or 0
        end
        return
    end

    -- The lump is only used for one rotation.
    if sprtemp[frame + 1].rotate == 0 then
        i_system.I_Error("R_InitSprites: Sprite %s frame %c has rotations and a rot=0 lump",
            spritename, string.char(string.byte("A") + frame))
    end

    sprtemp[frame + 1].rotate = 1

    -- Make 0 based.
    rotation = rotation - 1
    if sprtemp[frame + 1].lump[rotation + 1] ~= -1 then
        i_system.I_Error("R_InitSprites: Sprite %s : %c : %c has two lumps mapped to it",
            spritename, string.char(string.byte("A") + frame),
            string.char(string.byte("1") + rotation))
    end

    sprtemp[frame + 1].lump[rotation + 1] = lump - r_state.firstspritelump
    sprtemp[frame + 1].flip[rotation + 1] = flipped and 1 or 0
end

-- ---------------------------------------------------------------------------
-- R_InitSpriteDefs
-- ---------------------------------------------------------------------------

local function R_InitSpriteDefs(namelist)
    local numnames = #namelist
    r_state.numsprites = numnames

    if r_state.numsprites == 0 then
        return
    end

    r_state.sprites = {}

    local start = r_state.firstspritelump - 1
    local lend = r_state.lastspritelump + 1

    for i = 1, r_state.numsprites do
        spritename = deh_str.DEH_String(namelist[i])
        clear_sprtemp()

        maxframe = -1

        -- Scan the lumps, filling in the frames for whatever is found.
        for l = start + 1, lend - 1 do
            local lname = w_wad.W_LumpName(l)
            if name_matches_n(lname, spritename, 4) then
                local frame = string.byte(lname, 5) - string.byte("A")
                local rotation = string.byte(lname, 6) - string.byte("0")

                local patched
                if doomstat.modifiedgame then
                    patched = w_wad.W_GetNumForName(lname)
                else
                    patched = l
                end

                R_InstallSpriteLump(patched, frame, rotation, false)

                if string.byte(lname, 7) ~= nil and string.byte(lname, 7) ~= 0 then
                    frame = string.byte(lname, 7) - string.byte("A")
                    rotation = string.byte(lname, 8) - string.byte("0")
                    R_InstallSpriteLump(l, frame, rotation, true)
                end
            end
        end

        -- Check the frames that were found for completeness.
        if maxframe == -1 then
            r_state.sprites[i] = { numframes = 0, spriteframes = nil }
            -- continue
        else
            maxframe = maxframe + 1

            for frame = 0, maxframe - 1 do
                local rot = sprtemp[frame + 1].rotate
                if rot == -1 then
                    -- No rotations were found for that frame at all.
                    i_system.I_Error("R_InitSprites: No patches found for %s frame %c",
                        spritename, string.char(string.byte("A") + frame))
                elseif rot == 1 then
                    -- Must have all 8 frames.
                    for rotation = 0, 7 do
                        if sprtemp[frame + 1].lump[rotation + 1] == -1 then
                            i_system.I_Error("R_InitSprites: Sprite %s frame %c is missing rotations",
                                spritename, string.char(string.byte("A") + frame))
                        end
                    end
                end
            end

            -- Allocate space for the frames present and copy sprtemp to it.
            r_state.sprites[i] = {
                numframes = maxframe,
                spriteframes = {},
            }
            for f = 0, maxframe - 1 do
                local src = sprtemp[f + 1]
                local dst = {
                    rotate = src.rotate ~= -1,
                    lump = {},
                    flip = {},
                }
                for r = 1, 8 do
                    dst.lump[r] = src.lump[r]
                    dst.flip[r] = src.flip[r]
                end
                table.insert(r_state.sprites[i].spriteframes, dst)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- R_InitSprites
-- ---------------------------------------------------------------------------

function r_things.R_InitSprites(namelist)
    r_state.negonearray = {}
    for i = 0, SCREENWIDTH - 1 do
        r_state.negonearray[i + 1] = -1
    end

    R_InitSpriteDefs(namelist)
end

-- ---------------------------------------------------------------------------
-- R_ClearSprites / R_NewVisSprite
-- ---------------------------------------------------------------------------

function r_things.R_ClearSprites()
    r_state.vissprite_p = 1
end

-- The overflow vissprite (used when the vissprite array is full).
local overflowsprite = {
    prev = nil, next = nil, x1 = 0, x2 = 0, gx = 0, gy = 0, gz = 0, gzt = 0,
    startfrac = 0, scale = 0, xiscale = 0, texturemid = 0, patch = 0,
    colormap = 0, mobjflags = 0,
}

function r_things.R_NewVisSprite()
    local S = r_state
    if S.vissprite_p == 129 then -- MAXVISSPRITES + 1
        return overflowsprite
    end

    local result = S.vissprite_p
    S.vissprite_p = S.vissprite_p + 1
    return S.vissprites[result]
end

-- ---------------------------------------------------------------------------
-- R_DrawMaskedColumn
-- ---------------------------------------------------------------------------

function r_things.R_DrawMaskedColumn(column)
    local S = r_state
    local basetexturemid = S.dc_texturemid

    local cb = column.buffer
    local co = column.offset

    while buffer.readu8(cb, co) ~= 0xff do
        -- Calculate unclipped screen coordinates for post.
        local topscreen = S.sprtopscreen + S.spryscale * buffer.readu8(cb, co)
        local bottomscreen = topscreen + S.spryscale * buffer.readu8(cb, co + 1)

        S.dc_yl = (topscreen + 65535) // 65536 -- (topscreen+FRACUNIT-1)>>FRACBITS
        S.dc_yh = (bottomscreen - 1) // 65536

        if S.dc_yh >= S.mfloorclip[S.dc_x + 1] then -- TODO: attempt to compare nil <= number
            S.dc_yh = S.mfloorclip[S.dc_x + 1] - 1
        end
        if S.dc_yl <= S.mceilingclip[S.dc_x + 1] then
            S.dc_yl = S.mceilingclip[S.dc_x + 1] + 1
        end

        if S.dc_yl <= S.dc_yh then
            S.dc_source = { buffer = cb, offset = co + 3 }
            S.dc_texturemid = basetexturemid - (buffer.readu8(cb, co) * 65536)
            -- Drawn by either R_DrawColumn or (SHADOW) R_DrawFuzzColumn.
            S.colfunc()
        end

        co = co + buffer.readu8(cb, co + 1) + 4
    end

    S.dc_texturemid = basetexturemid
end

-- ---------------------------------------------------------------------------
-- R_DrawVisSprite
-- ---------------------------------------------------------------------------

function r_things.R_DrawVisSprite(vis, x1, x2)
    local S = r_state

    local patch = w_wad.W_CacheLumpNum(vis.patch + S.firstspritelump, z_zone.PU_CACHE)
    local pb = patch.buffer
    local po = patch.offset

    S.dc_colormap = vis.colormap

    if S.dc_colormap == 0 or S.dc_colormap == nil then
        -- NULL colormap = shadow draw.
        S.colfunc = S.fuzzcolfunc
    elseif bit32.band(vis.mobjflags, 0xc000000) ~= 0 then -- MF_TRANSLATION
        S.colfunc = S.transcolfunc
        S.dc_translation = S.translationtables.offset - 256
            + bit32.rshift(bit32.band(vis.mobjflags, 0xc000000), 18)
    end

    S.dc_iscale = math.abs(vis.xiscale) // 2 ^ S.detailshift
    S.dc_texturemid = vis.texturemid
    local frac = vis.startfrac
    S.spryscale = vis.scale
    S.sprtopscreen = S.centeryfrac - m_fixed.FixedMul(S.dc_texturemid, S.spryscale)

    for dc_x = vis.x1, vis.x2 do
        S.dc_x = dc_x -- C sets the dc_x global in this loop; needed by R_DrawMaskedColumn
        local texturecolumn = frac // 65536 -- >> FRACBITS
        local column = { buffer = pb, offset = po + buffer.readi32(pb, po + 8 + texturecolumn * 4) }
        r_things.R_DrawMaskedColumn(column)
        frac = frac + vis.xiscale
    end

    S.colfunc = S.basecolfunc
end

-- ---------------------------------------------------------------------------
-- R_ProjectSprite
-- ---------------------------------------------------------------------------

function r_things.R_ProjectSprite(thing)
    local S = r_state
    local m_fixed_ = m_fixed

    -- Transform the origin point.
    local tr_x = thing.x - S.viewx
    local tr_y = thing.y - S.viewy

    local gxt = m_fixed_.FixedMul(tr_x, S.viewcos)
    local gyt = -m_fixed_.FixedMul(tr_y, S.viewsin)

    local tz = gxt - gyt

    -- Thing is behind view plane?
    if tz < MINZ then
        return
    end

    local xscale = m_fixed_.FixedDiv(S.projection, tz)

    gxt = -m_fixed_.FixedMul(tr_x, S.viewsin)
    gyt = m_fixed_.FixedMul(tr_y, S.viewcos)
    local tx = -(gyt + gxt)

    -- Too far off the side?
    if math.abs(tx) > doomtype.lshift32(tz, 2) then
        return
    end

    local sprdef = S.sprites[thing.sprite + 1]
    local sprframe = sprdef.spriteframes[bit32.band(thing.frame, 0x7fff) + 1]

    local lump
    local flip = false

    if sprframe.rotate then
        -- Choose a different rotation based on player view.
        local ang = r_main.R_PointToAngle(thing.x, thing.y)
        local rot = bit32.rshift(
            (ang - thing.angle + 0x90000000) % 0x100000000, 29)
        lump = sprframe.lump[rot + 1]
        flip = sprframe.flip[rot + 1] ~= 0
    else
        -- Use single rotation for all views.
        lump = sprframe.lump[1]
        flip = sprframe.flip[1] ~= 0
    end

    -- Calculate edges of the shape.
    tx = tx - S.spriteoffset[lump + 1]
    local x1 = (S.centerxfrac + m_fixed_.FixedMul(tx, xscale)) // 65536

    -- Off the right side?
    if x1 > S.viewwidth then
        return
    end

    tx = tx + S.spritewidth[lump + 1]
    local x2 = ((S.centerxfrac + m_fixed_.FixedMul(tx, xscale)) // 65536) - 1

    -- Off the left side.
    if x2 < 0 then
        return
    end

    -- Store information in a vissprite.
    local vis = r_things.R_NewVisSprite()
    vis.mobjflags = thing.flags
    vis.scale = xscale * 2 ^ S.detailshift
    vis.gx = thing.x
    vis.gy = thing.y
    vis.gz = thing.z
    vis.gzt = thing.z + S.spritetopoffset[lump + 1]
    vis.texturemid = vis.gzt - S.viewz
    vis.x1 = x1 < 0 and 0 or x1
    vis.x2 = x2 >= S.viewwidth and S.viewwidth - 1 or x2

    local iscale = m_fixed_.FixedDiv(m_fixed_.FRACUNIT, xscale)

    if flip then
        vis.startfrac = S.spritewidth[lump + 1] - 1
        vis.xiscale = -iscale
    else
        vis.startfrac = 0
        vis.xiscale = iscale
    end

    if vis.x1 > x1 then
        vis.startfrac = vis.startfrac + vis.xiscale * (vis.x1 - x1)
    end
    vis.patch = lump

    -- Get light level.
    if bit32.band(thing.flags, 0x40000) ~= 0 then -- MF_SHADOW
        -- Shadow draw.
        vis.colormap = 0
    elseif S.fixedcolormap ~= 0 then
        -- Fixed map.
        vis.colormap = S.fixedcolormap
    elseif bit32.band(thing.frame, 0x8000) ~= 0 then -- FF_FULLBRIGHT
        -- Full bright.
        vis.colormap = S.colormaps.offset
    else
        -- Diminished light.
        local index = xscale // 2 ^ (12 - S.detailshift) -- >> LIGHTSCALESHIFT-detailshift
        if index >= 48 then -- MAXLIGHTSCALE
            index = 47
        end
        vis.colormap = S.spritelights[index + 1]
    end
end

-- ---------------------------------------------------------------------------
-- R_AddSprites
-- ---------------------------------------------------------------------------

function r_things.R_AddSprites(sec)
    local S = r_state

    -- BSP is traversed by subsector. A sector might have been split into
    -- several subsectors during BSP building, so check whether it's already
    -- added.
    if sec.validcount == S.validcount then
        return
    end

    -- Well, now it will be done.
    sec.validcount = S.validcount

    local lightnum = (sec.lightlevel // 16) + S.extralight -- >> LIGHTSEGSHIFT

    if lightnum < 0 then
        S.spritelights = S.scalelight[1]
    elseif lightnum >= 16 then -- LIGHTLEVELS
        S.spritelights = S.scalelight[16]
    else
        S.spritelights = S.scalelight[lightnum + 1]
    end

    -- Handle all things in sector.
    local thing = sec.thinglist
    while thing ~= nil do
        r_things.R_ProjectSprite(thing)
        thing = thing.snext
    end
end

-- ---------------------------------------------------------------------------
-- R_DrawPSprite / R_DrawPlayerSprites
-- ---------------------------------------------------------------------------

function r_things.R_DrawPSprite(psp)
    local S = r_state
    local m_fixed_ = m_fixed

    -- Decide which patch to use.
    local sprdef = S.sprites[psp.state.sprite + 1]
    local sprframe = sprdef.spriteframes[bit32.band(psp.state.frame, 0x7fff) + 1]

    local lump = sprframe.lump[1]
    local flip = sprframe.flip[1] ~= 0

    -- Calculate edges of the shape.
    local tx = psp.sx - 160 * m_fixed_.FRACUNIT

    tx = tx - S.spriteoffset[lump + 1]
    local x1 = (S.centerxfrac + m_fixed_.FixedMul(tx, S.pspritescale)) // 65536

    -- Off the right side.
    if x1 > S.viewwidth then
        return
    end

    tx = tx + S.spritewidth[lump + 1]
    local x2 = ((S.centerxfrac + m_fixed_.FixedMul(tx, S.pspritescale)) // 65536) - 1

    -- Off the left side.
    if x2 < 0 then
        return
    end

    -- Store information in a vissprite.
    local vis = {
        mobjflags = 0,
        texturemid = (BASEYCENTER * m_fixed_.FRACUNIT) + m_fixed_.FRACUNIT // 2
            - (psp.sy - S.spritetopoffset[lump + 1]),
        x1 = x1 < 0 and 0 or x1,
        x2 = x2 >= S.viewwidth and S.viewwidth - 1 or x2,
        scale = S.pspritescale * 2 ^ S.detailshift,
    }

    if flip then
        vis.xiscale = -S.pspriteiscale
        vis.startfrac = S.spritewidth[lump + 1] - 1
    else
        vis.xiscale = S.pspriteiscale
        vis.startfrac = 0
    end

    if vis.x1 > x1 then
        vis.startfrac = vis.startfrac + vis.xiscale * (vis.x1 - x1)
    end

    vis.patch = lump

    local player = S.viewplayer
    if player.powers[3] > 4 * 32 -- pw_invisibility
        or bit32.band(player.powers[3], 8) ~= 0 then
        -- Shadow draw.
        vis.colormap = 0
    elseif S.fixedcolormap ~= 0 then
        -- Fixed color.
        vis.colormap = S.fixedcolormap
    elseif bit32.band(psp.state.frame, 0x8000) ~= 0 then -- FF_FULLBRIGHT
        -- Full bright.
        vis.colormap = S.colormaps.offset
    else
        -- Local light.
        vis.colormap = S.spritelights[48] -- MAXLIGHTSCALE
    end

    r_things.R_DrawVisSprite(vis, vis.x1, vis.x2)
end

function r_things.R_DrawPlayerSprites()
    local S = r_state
    local player = S.viewplayer

    if player == nil or player.mo == nil then
        return
    end

    -- Get light level.
    local lightlevel = 0
    if player.mo.subsector ~= nil then
        lightlevel = player.mo.subsector.sector.lightlevel
    end
    local lightnum = (lightlevel // 16) + S.extralight
    if lightnum < 0 then
        S.spritelights = S.scalelight[1]
    elseif lightnum >= 16 then
        S.spritelights = S.scalelight[16]
    else
        S.spritelights = S.scalelight[lightnum + 1]
    end

    -- Clip to screen bounds.
    S.mfloorclip = S.screenheightarray
    S.mceilingclip = S.negonearray

    -- Add all active psprites.
    for i = 1, 2 do -- NUMPSPRITES
        local psp = player.psprites[i]
        if psp ~= nil and psp.state ~= nil then
            r_things.R_DrawPSprite(psp)
        end
    end
end

-- ---------------------------------------------------------------------------
-- R_SortVisSprites
-- ---------------------------------------------------------------------------

function r_things.R_SortVisSprites()
    local S = r_state

    local count = S.vissprite_p - 1

    -- Sentinel nodes.
    local unsorted = { next = nil, prev = nil }
    unsorted.next = unsorted
    unsorted.prev = unsorted

    local head = { next = nil, prev = nil }
    head.next = head
    head.prev = head
    S.vsprsortedhead = head

    if count == 0 then
        return
    end

    for i = 1, count do
        local ds = S.vissprites[i]
        ds.next = S.vissprites[i + 1]
        ds.prev = S.vissprites[i - 1]
    end

    S.vissprites[1].prev = unsorted
    unsorted.next = S.vissprites[1]
    S.vissprites[count].next = unsorted
    unsorted.prev = S.vissprites[count]

    -- Pull the vissprites out by scale.
    for _ = 1, count do
        local bestscale = 2147483647 -- INT_MAX
        local best = unsorted.next

        local ds = unsorted.next
        while ds ~= unsorted do
            if ds.scale < bestscale then
                bestscale = ds.scale
                best = ds
            end
            ds = ds.next
        end

        -- Remove best from the unsorted list.
        best.next.prev = best.prev
        best.prev.next = best.next

        -- Prepend best to the sorted head list.
        best.next = head
        best.prev = head.prev
        head.prev.next = best
        head.prev = best
    end
end

-- ---------------------------------------------------------------------------
-- R_DrawSprite
-- ---------------------------------------------------------------------------

local clipbot = {}
local cliptop = {}

function r_things.R_DrawSprite(spr)
    local S = r_state

    for x = spr.x1, spr.x2 do
        clipbot[x + 1] = -2
        cliptop[x + 1] = -2
    end

    -- Scan drawsegs from end to start for obscuring segs. The first drawseg
    -- that has a greater scale is the clip seg.
    for dsi = S.ds_p - 1, 1, -1 do
        local ds = S.drawsegs[dsi]

        -- Determine if the drawseg obscures the sprite.
        if ds.x1 > spr.x2
            or ds.x2 < spr.x1
            or (ds.silhouette == 0 and ds.maskedtexturecol == nil) then
            -- Does not cover sprite.
            -- continue
        else
            local r1 = ds.x1 < spr.x1 and spr.x1 or ds.x1
            local r2 = ds.x2 > spr.x2 and spr.x2 or ds.x2

            local lowscale
            local scale
            if ds.scale1 > ds.scale2 then
                lowscale = ds.scale2
                scale = ds.scale1
            else
                lowscale = ds.scale1
                scale = ds.scale2
            end

            if scale < spr.scale
                or (lowscale < spr.scale
                    and not r_main.R_PointOnSegSide(spr.gx, spr.gy, ds.curline)) then
                -- Masked mid texture?
                if ds.maskedtexturecol ~= nil then
                    r_segs.R_RenderMaskedSegRange(ds, r1, r2)
                end
                -- Seg is behind sprite.
                -- continue
            else
                -- Clip this piece of the sprite.
                local silhouette = ds.silhouette

                if spr.gz >= ds.bsilheight then
                    silhouette = bit32.band(silhouette, bit32.bnot(1)) -- ~SIL_BOTTOM
                end
                if spr.gzt <= ds.tsilheight then
                    silhouette = bit32.band(silhouette, bit32.bnot(2)) -- ~SIL_TOP
                end

                if silhouette == 1 then
                    -- Bottom sil.
                    for x = r1, r2 do
                        if clipbot[x + 1] == -2 then
                            clipbot[x + 1] = ds.sprbottomclip[x + 1]
                        end
                    end
                elseif silhouette == 2 then
                    -- Top sil.
                    for x = r1, r2 do
                        if cliptop[x + 1] == -2 then
                            cliptop[x + 1] = ds.sprtopclip[x + 1]
                        end
                    end
                elseif silhouette == 3 then
                    -- Both.
                    for x = r1, r2 do
                        if clipbot[x + 1] == -2 then
                            clipbot[x + 1] = ds.sprbottomclip[x + 1]
                        end
                        if cliptop[x + 1] == -2 then
                            cliptop[x + 1] = ds.sprtopclip[x + 1]
                        end
                    end
                end
            end
        end
    end

    -- All clipping has been performed, so draw the sprite.

    -- Check for unclipped columns.
    for x = spr.x1, spr.x2 do
        if clipbot[x + 1] == -2 then
            clipbot[x + 1] = S.viewheight
        end
        if cliptop[x + 1] == -2 then
            cliptop[x + 1] = -1
        end
    end

    S.mfloorclip = clipbot
    S.mceilingclip = cliptop
    r_things.R_DrawVisSprite(spr, spr.x1, spr.x2)
end

-- ---------------------------------------------------------------------------
-- R_DrawMasked
-- ---------------------------------------------------------------------------

function r_things.R_DrawMasked()
    local S = r_state

    r_things.R_SortVisSprites()

    if S.vissprite_p > 1 then
        -- Draw all vissprites back to front.
        local spr = S.vsprsortedhead.next
        while spr ~= S.vsprsortedhead do
            r_things.R_DrawSprite(spr)
            spr = spr.next
        end
    end

    -- Render any remaining masked mid textures.
    for dsi = S.ds_p - 1, 1, -1 do
        local ds = S.drawsegs[dsi]
        if ds.maskedtexturecol ~= nil then
            r_segs.R_RenderMaskedSegRange(ds, ds.x1, ds.x2)
        end
    end

    -- Draw the psprites on top of everything, but not on side views.
    if S.viewangleoffset == 0 then
        r_things.R_DrawPlayerSprites()
    end
end

return r_things
end)()

st_stuff = (function()
local st_stuff = {}

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

local SCREENWIDTH = 320
local SCREENHEIGHT = 200
local TICRATE = doomtype.TICRATE

-- Palette indices.
local STARTREDPALS = 1
local STARTBONUSPALS = 9
local NUMREDPALS = 8
local NUMBONUSPALS = 4
-- Radiation suit, green shift.
local RADIATIONPAL = 13

-- Location of status bar.
local ST_X = 0
local ST_X2 = 104

local ST_FX = 143
local ST_FY = 169

-- Number of status faces.
local ST_NUMPAINFACES = 5
local ST_NUMSTRAIGHTFACES = 3
local ST_NUMTURNFACES = 2
local ST_NUMSPECIALFACES = 3

local ST_FACESTRIDE = ST_NUMSTRAIGHTFACES + ST_NUMTURNFACES + ST_NUMSPECIALFACES -- 8

local ST_NUMEXTRAFACES = 2

local ST_NUMFACES = ST_FACESTRIDE * ST_NUMPAINFACES + ST_NUMEXTRAFACES -- 42

local ST_TURNOFFSET = ST_NUMSTRAIGHTFACES -- 3
local ST_OUCHOFFSET = ST_TURNOFFSET + ST_NUMTURNFACES -- 5
local ST_EVILGRINOFFSET = ST_OUCHOFFSET + 1 -- 6
local ST_RAMPAGEOFFSET = ST_EVILGRINOFFSET + 1 -- 7
local ST_GODFACE = ST_NUMPAINFACES * ST_FACESTRIDE -- 40
local ST_DEADFACE = ST_GODFACE + 1 -- 41

local ST_FACESX = 143
local ST_FACESY = 168

local ST_EVILGRINCOUNT = 2 * TICRATE
local ST_STRAIGHTFACECOUNT = TICRATE // 2
local ST_TURNCOUNT = 1 * TICRATE
local ST_OUCHCOUNT = 1 * TICRATE
local ST_RAMPAGEDELAY = 2 * TICRATE

local ST_MUCHPAIN = 20

-- AMMO number pos.
local ST_AMMOWIDTH = 3
local ST_AMMOX = 44
local ST_AMMOY = 171

-- HEALTH number pos.
local ST_HEALTHWIDTH = 3
local ST_HEALTHX = 90
local ST_HEALTHY = 171

-- Weapon pos.
local ST_ARMSX = 111
local ST_ARMSY = 172
local ST_ARMSBGX = 104
local ST_ARMSBGY = 168
local ST_ARMSXSPACE = 12
local ST_ARMSYSPACE = 10

-- Frags pos.
local ST_FRAGSX = 138
local ST_FRAGSY = 171
local ST_FRAGSWIDTH = 2

-- ARMOR number pos.
local ST_ARMORWIDTH = 3
local ST_ARMORX = 221
local ST_ARMORY = 171

-- Key icon positions.
local ST_KEY0WIDTH = 8
local ST_KEY0HEIGHT = 5
local ST_KEY0X = 239
local ST_KEY0Y = 171
local ST_KEY1X = 239
local ST_KEY1Y = 181
local ST_KEY2X = 239
local ST_KEY2Y = 191

-- Ammunition counter.
local ST_AMMO0WIDTH = 3
local ST_AMMO0HEIGHT = 6
local ST_AMMO0X = 288
local ST_AMMO0Y = 173
local ST_AMMO1X = 288
local ST_AMMO1Y = 179
local ST_AMMO2X = 288
local ST_AMMO2Y = 191
local ST_AMMO3X = 288
local ST_AMMO3Y = 185

-- Indicate maximum ammunition.
local ST_MAXAMMO0WIDTH = 3
local ST_MAXAMMO0HEIGHT = 5
local ST_MAXAMMO0X = 314
local ST_MAXAMMO0Y = 173
local ST_MAXAMMO1X = 314
local ST_MAXAMMO1Y = 179
local ST_MAXAMMO2X = 314
local ST_MAXAMMO2Y = 191
local ST_MAXAMMO3X = 314
local ST_MAXAMMO3Y = 185

-- Weapon icon positions.
local ST_WEAPON0X = 110
local ST_WEAPON0Y = 172
local ST_WEAPON1X = 122
local ST_WEAPON1Y = 172
local ST_WEAPON2X = 134
local ST_WEAPON2Y = 172
local ST_WEAPON3X = 110
local ST_WEAPON3Y = 181
local ST_WEAPON4X = 122
local ST_WEAPON4Y = 181
local ST_WEAPON5X = 134
local ST_WEAPON5Y = 181

-- WPNS title.
local ST_WPNSX = 109
local ST_WPNSY = 191

-- DETH title.
local ST_DETHX = 109
local ST_DETHY = 191

-- Incoming messages window location (UNUSED).
local ST_MSGTEXTX = 0
local ST_MSGTEXTY = 0
local ST_MSGWIDTH = 52
local ST_MSGHEIGHT = 1

local ST_OUTTEXTX = 0
local ST_OUTTEXTY = 6
local ST_OUTWIDTH = 52
local ST_OUTHEIGHT = 1

-- Automap message header (am_map.h).
-- AM_MSGHEADER = ('a'<<24)+('m'<<16); AM_MSGENTERED = |('e'<<8);
-- AM_MSGEXITED = |('x'<<8).
local AM_MSGHEADER = 0x616d0000
local AM_MSGENTERED = 0x616d6500
local AM_MSGEXITED = 0x616d7800

-- ---------------------------------------------------------------------------
-- State (C statics)
-- ---------------------------------------------------------------------------

local plyr = nil -- main player in game
local st_firsttime = false -- ST_Start() has just been called
local lu_palette = 0 -- lump number for PLAYPAL
local st_clock = 0 -- used for timing
local st_msgcounter = 0 -- used for making messages go away
local st_chatstate = 0 -- StartChatState (chat is cut in v1)
local st_gamestate = 1 -- FirstPersonState
local st_statusbaron = false -- whether left-side main status bar is active
local st_chat = false -- whether status bar chat is active
local st_oldchat = false -- value of st_chat before message popped up
local st_cursoron = false -- whether chat window has the cursor on
local st_notdeathmatch = false -- !deathmatch
local st_armson = false -- !deathmatch && st_statusbaron
local st_fragson = false -- !deathmatch
local sbar = nil -- main bar left
local tallnum = {} -- 0-9, tall numbers
local tallpercent = nil -- tall % sign
local shortnum = {} -- 0-9, short, yellow (,different!) numbers
local keys = {} -- 3 key-cards, 3 skulls
local faces = {} -- face status patches
local faceback = nil -- face background
local armsbg = nil -- main bar right
local arms = {} -- weapon ownership patches [6][2]
local w_ready = {} -- ready-weapon widget
local w_frags = {} -- frags widget (deathmatch only)
local w_health = {} -- health widget
local w_armsbg = {} -- arms background
local w_arms = {} -- weapon ownership widgets [6]
local w_faces = {} -- face status widget
local w_keyboxes = {} -- keycard widgets [3]
local w_armor = {} -- armor widget
local w_ammo = {} -- ammo widgets [4]
local w_maxammo = {} -- max ammo widgets [4]

local st_fragscount = 0 -- number of frags so far in deathmatch
local st_oldhealth = -1 -- used to use appopriately pained face
local oldweaponsowned = {} -- used for evil grin
local st_facecount = 0 -- count until face changes
local st_faceindex = 0 -- current face index, used by w_faces
local keyboxes = { -1, -1, -1 } -- holds key-type for each key box on bar
local st_randomnumber = 0 -- a random number per tick
local st_palette = 0
local st_stopped = true

-- Cheat sequences.
local cheat_mus = m_cheat.CHEAT("idmus", 2)
local cheat_god = m_cheat.CHEAT("iddqd", 0)
local cheat_ammo = m_cheat.CHEAT("idkfa", 0)
local cheat_ammonokey = m_cheat.CHEAT("idfa", 0)
local cheat_noclip = m_cheat.CHEAT("idspispopd", 0)
local cheat_commercial_noclip = m_cheat.CHEAT("idclip", 0)

local cheat_powerup = {
    m_cheat.CHEAT("idbeholdv", 0),
    m_cheat.CHEAT("idbeholds", 0),
    m_cheat.CHEAT("idbeholdi", 0),
    m_cheat.CHEAT("idbeholdr", 0),
    m_cheat.CHEAT("idbeholda", 0),
    m_cheat.CHEAT("idbeholdl", 0),
    m_cheat.CHEAT("idbehold", 0),
}

local cheat_choppers = m_cheat.CHEAT("idchoppers", 0)
local cheat_clev = m_cheat.CHEAT("idclev", 2)
local cheat_mypos = m_cheat.CHEAT("idmypos", 0)

-- ---------------------------------------------------------------------------
-- ST_refreshBackground
-- ---------------------------------------------------------------------------

function st_stuff.ST_refreshBackground()
    if st_statusbaron then
        v_video.V_UseBuffer(st_lib.st_backing_screen)

        v_video.V_DrawPatch(ST_X, 0, sbar)

        if doomstat.netgame then
            v_video.V_DrawPatch(ST_FX, 0, faceback)
        end

        v_video.V_RestoreBuffer()

        v_video.V_CopyRect(ST_X, 0,
            { buffer = st_lib.st_backing_screen, offset = 0 },
            st_lib.ST_WIDTH, st_lib.ST_HEIGHT, ST_X, st_lib.ST_Y)
    end
end

-- ---------------------------------------------------------------------------
-- ST_Responder
-- ---------------------------------------------------------------------------

function st_stuff.ST_Responder(ev)
    local i

    -- Filter automap on/off.
    if ev.type == 1 -- ev_keyup
        and bit32.band(ev.data1, 0xffff0000) == AM_MSGHEADER then
        if ev.data1 == AM_MSGENTERED then
            st_gamestate = 0 -- AutomapState
            st_firsttime = true
        elseif ev.data1 == AM_MSGEXITED then
            st_gamestate = 1 -- FirstPersonState
        end
    elseif ev.type == 0 then -- ev_keydown
        if not doomstat.netgame and doomstat.gameskill ~= d_mode.sk_nightmare then
            -- 'dqd' cheat for toggleable god mode.
            if m_cheat.cht_CheckCheat(cheat_god, ev.data2) then
                plyr.cheats = bit32.bxor(plyr.cheats, 2) -- CF_GODMODE
                if bit32.band(plyr.cheats, 2) ~= 0 then
                    if plyr.mo then
                        plyr.mo.health = 100
                    end
                    plyr.health = deh_misc.deh_god_mode_health
                    plyr.message = deh_str.DEH_String(dstrings.STSTR_DQDON)
                else
                    plyr.message = deh_str.DEH_String(dstrings.STSTR_DQDOFF)
                end
            -- 'fa' cheat for killer fucking arsenal.
            elseif m_cheat.cht_CheckCheat(cheat_ammonokey, ev.data2) then
                plyr.armorpoints = deh_misc.deh_idfa_armor
                plyr.armortype = deh_misc.deh_idfa_armor_class

                for i = 0, doomdef.NUMWEAPONS - 1 do
                    plyr.weaponowned[i + 1] = true
                end
                for i = 0, doomdef.NUMAMMO - 1 do
                    plyr.ammo[i + 1] = plyr.maxammo[i + 1]
                end

                plyr.message = deh_str.DEH_String(dstrings.STSTR_FAADDED)
            -- 'kfa' cheat for key full ammo.
            elseif m_cheat.cht_CheckCheat(cheat_ammo, ev.data2) then
                plyr.armorpoints = deh_misc.deh_idkfa_armor
                plyr.armortype = deh_misc.deh_idkfa_armor_class

                for i = 0, doomdef.NUMWEAPONS - 1 do
                    plyr.weaponowned[i + 1] = true
                end
                for i = 0, doomdef.NUMAMMO - 1 do
                    plyr.ammo[i + 1] = plyr.maxammo[i + 1]
                end
                for i = 0, doomdef.NUMCARDS - 1 do
                    plyr.cards[i + 1] = true
                end

                plyr.message = deh_str.DEH_String(dstrings.STSTR_KFAADDED)
            -- 'mus' cheat for changing music.
            elseif m_cheat.cht_CheckCheat(cheat_mus, ev.data2) then
                local buf = m_cheat.cht_GetParam(cheat_mus)

                plyr.message = deh_str.DEH_String(dstrings.STSTR_MUS)

                -- Note: The original v1.9 had a bug that tried to play back
                -- the Doom II music regardless of gamemode. This was fixed
                -- in the Ultimate Doom executable so that it would work for
                -- the Doom 1 music as well.
                if doomstat.gamemode == d_mode.commercial
                    or doomstat.gameversion < d_mode.exe_ultimate then
                    local musnum = sounds.musicenum.mus_runnin
                        + (string.byte(buf, 1) - 48) * 10
                        + string.byte(buf, 2) - 48 - 1
                    if ((string.byte(buf, 1) - 48) * 10 + string.byte(buf, 2) - 48) > 35 then
                        plyr.message = deh_str.DEH_String(dstrings.STSTR_NOMUS)
                    else
                        s_sound.S_ChangeMusic(musnum, 1)
                    end
                else
                    local musnum = sounds.musicenum.mus_e1m1
                        + (string.byte(buf, 1) - 49) * 9
                        + string.byte(buf, 2) - 49
                    if ((string.byte(buf, 1) - 49) * 9 + string.byte(buf, 2) - 49) > 31 then
                        plyr.message = deh_str.DEH_String(dstrings.STSTR_NOMUS)
                    else
                        s_sound.S_ChangeMusic(musnum, 1)
                    end
                end
            end
            -- logical_gamemission (doomstat.h macro): pack_chex/pack_hacx
            -- fold back to doom/doom2.
            local gamemission = doomstat.gamemission
            if gamemission == d_mode.pack_chex then
                gamemission = d_mode.doom
            elseif gamemission == d_mode.pack_hacx then
                gamemission = d_mode.doom2
            end
            if (gamemission == d_mode.doom
                    and m_cheat.cht_CheckCheat(cheat_noclip, ev.data2))
                or (gamemission ~= d_mode.doom
                    and m_cheat.cht_CheckCheat(cheat_commercial_noclip, ev.data2)) then
                -- Noclip cheat. For Doom 1, use the idspipsopd cheat; for
                -- all others, use idclip.
                plyr.cheats = bit32.bxor(plyr.cheats, 1) -- CF_NOCLIP

                if bit32.band(plyr.cheats, 1) ~= 0 then
                    plyr.message = deh_str.DEH_String(dstrings.STSTR_NCON)
                else
                    plyr.message = deh_str.DEH_String(dstrings.STSTR_NCOFF)
                end
            end

            -- 'behold?' power-up cheats.
            for i = 0, 5 do
                if m_cheat.cht_CheckCheat(cheat_powerup[i + 1], ev.data2) then
                    if not plyr.powers[i + 1] then
                        p_inter.P_GivePower(plyr, i)
                    elseif i ~= doomdef.pw_strength then
                        plyr.powers[i + 1] = 1
                    else
                        plyr.powers[i + 1] = 0
                    end
                    plyr.message = deh_str.DEH_String(dstrings.STSTR_BEHOLDX)
                end
            end

            -- 'behold' power-up menu.
            if m_cheat.cht_CheckCheat(cheat_powerup[7], ev.data2) then
                plyr.message = deh_str.DEH_String(dstrings.STSTR_BEHOLD)
            -- 'choppers' invulnerability & chainsaw.
            elseif m_cheat.cht_CheckCheat(cheat_choppers, ev.data2) then
                plyr.weaponowned[doomdef.wp_chainsaw + 1] = true
                plyr.powers[doomdef.pw_invulnerability + 1] = true
                plyr.message = deh_str.DEH_String(dstrings.STSTR_CHOPPERS)
            -- 'mypos' for player position.
            elseif m_cheat.cht_CheckCheat(cheat_mypos, ev.data2) then
                local mo = doomstat.players[doomstat.consoleplayer + 1].mo
                plyr.message = m_misc.M_snprintf("ang=0x%x;x,y=(0x%x,0x%x)",
                    mo.angle, mo.x, mo.y)
            end
        end

        -- 'clev' change-level cheat.
        if not doomstat.netgame and m_cheat.cht_CheckCheat(cheat_clev, ev.data2) then
            local buf = m_cheat.cht_GetParam(cheat_clev)
            local epsd
            local map

            if doomstat.gamemode == d_mode.commercial then
                epsd = 1
                map = (string.byte(buf, 1) - 48) * 10 + string.byte(buf, 2) - 48
            else
                epsd = string.byte(buf, 1) - 48
                map = string.byte(buf, 2) - 48
            end

            -- Chex.exe always warps to episode 1.
            if doomstat.gameversion == d_mode.exe_chex then
                epsd = 1
            end

            -- Catch invalid maps.
            if epsd < 1 then
                return false
            end
            if map < 1 then
                return false
            end

            -- Ohmygod - this is not going to work.
            if doomstat.gamemode == d_mode.retail
                and (epsd > 4 or map > 9) then
                return false
            end
            if doomstat.gamemode == d_mode.registered
                and (epsd > 3 or map > 9) then
                return false
            end
            if doomstat.gamemode == d_mode.shareware
                and (epsd > 1 or map > 9) then
                return false
            end

            -- The source release has this check as map > 34. However,
            -- Vanilla Doom allows IDCLEV up to MAP40 even though it normally
            -- crashes.
            if doomstat.gamemode == d_mode.commercial
                and (epsd > 1 or map > 40) then
                return false
            end

            -- So be it.
            plyr.message = deh_str.DEH_String(dstrings.STSTR_CLEV)
            g_game.G_DeferedInitNew(doomstat.gameskill, epsd, map)
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- ST_calcPainOffset
-- ---------------------------------------------------------------------------

local lastcalc = 0
local oldhealth = -1

function st_stuff.ST_calcPainOffset()
    local health = plyr.health > 100 and 100 or plyr.health

    if health ~= oldhealth then
        lastcalc = ST_FACESTRIDE * (((100 - health) * ST_NUMPAINFACES) // 101)
        oldhealth = health
    end
    return lastcalc
end

-- ---------------------------------------------------------------------------
-- ST_updateFaceWidget
-- ---------------------------------------------------------------------------

local lastattackdown = -1
local priority = 0

function st_stuff.ST_updateFaceWidget()
    local i
    local badguyangle
    local diffang
    local doevilgrin

    if priority < 10 then
        -- Dead.
        if not plyr.health then
            priority = 9
            st_faceindex = ST_DEADFACE
            st_facecount = 1
        end
    end

    if priority < 9 then
        if plyr.bonuscount then
            -- Picking up bonus.
            doevilgrin = false

            for i = 0, doomdef.NUMWEAPONS - 1 do
                if oldweaponsowned[i + 1] ~= plyr.weaponowned[i + 1] then
                    doevilgrin = true
                    oldweaponsowned[i + 1] = plyr.weaponowned[i + 1]
                end
            end
            if doevilgrin then
                -- Evil grin if just picked up weapon.
                priority = 8
                st_facecount = ST_EVILGRINCOUNT
                st_faceindex = st_stuff.ST_calcPainOffset() + ST_EVILGRINOFFSET
            end
        end
    end

    if priority < 8 then
        if plyr.damagecount
            and plyr.attacker
            and plyr.attacker ~= plyr.mo then
            -- Being attacked.
            priority = 7

            if plyr.health - st_oldhealth > ST_MUCHPAIN then
                st_facecount = ST_TURNCOUNT
                st_faceindex = st_stuff.ST_calcPainOffset() + ST_OUCHOFFSET
            else
                badguyangle = r_main.R_PointToAngle2(plyr.mo.x, plyr.mo.y,
                    plyr.attacker.x, plyr.attacker.y)

                if badguyangle > plyr.mo.angle then
                    -- Whether right or left.
                    diffang = (badguyangle - plyr.mo.angle) % 0x100000000
                    i = diffang > 0x80000000 -- ANG180
                else
                    -- Whether left or right.
                    diffang = (plyr.mo.angle - badguyangle) % 0x100000000
                    i = diffang <= 0x80000000 -- ANG180
                end

                st_facecount = ST_TURNCOUNT
                st_faceindex = st_stuff.ST_calcPainOffset()

                if diffang < 0x20000000 then -- ANG45
                    -- Head-on.
                    st_faceindex = st_faceindex + ST_RAMPAGEOFFSET
                elseif i then
                    -- Turn face right.
                    st_faceindex = st_faceindex + ST_TURNOFFSET
                else
                    -- Turn face left.
                    st_faceindex = st_faceindex + ST_TURNOFFSET + 1
                end
            end
        end
    end

    if priority < 7 then
        -- Getting hurt because of your own damn stupidity.
        if plyr.damagecount then
            if plyr.health - st_oldhealth > ST_MUCHPAIN then
                priority = 7
                st_facecount = ST_TURNCOUNT
                st_faceindex = st_stuff.ST_calcPainOffset() + ST_OUCHOFFSET
            else
                priority = 6
                st_facecount = ST_TURNCOUNT
                st_faceindex = st_stuff.ST_calcPainOffset() + ST_RAMPAGEOFFSET
            end
        end
    end

    if priority < 6 then
        -- Rapid firing.
        if plyr.attackdown then
            if lastattackdown == -1 then
                lastattackdown = ST_RAMPAGEDELAY
            else
                lastattackdown = lastattackdown - 1
                if lastattackdown == 0 then
                    priority = 5
                    st_faceindex = st_stuff.ST_calcPainOffset() + ST_RAMPAGEOFFSET
                    st_facecount = 1
                    lastattackdown = 1
                end
            end
        else
            lastattackdown = -1
        end
    end

    if priority < 5 then
        -- Invulnerability.
        if bit32.band(plyr.cheats, 2) ~= 0 -- CF_GODMODE
            or plyr.powers[doomdef.pw_invulnerability + 1] then
            priority = 4
            st_faceindex = ST_GODFACE
            st_facecount = 1
        end
    end

    -- Look left or look right if the facecount has timed out.
    if st_facecount == 0 then
        st_faceindex = st_stuff.ST_calcPainOffset() + (st_randomnumber % 3)
        st_facecount = ST_STRAIGHTFACECOUNT
        priority = 0
    end

    st_facecount = st_facecount - 1
end

-- ---------------------------------------------------------------------------
-- ST_updateWidgets
-- ---------------------------------------------------------------------------

function st_stuff.ST_updateWidgets()
    local i
    local largeammo = 1994 -- means "n/a"

    -- Must redirect the ready-weapon ammo pointer if the ready weapon has
    -- changed. The getter reads the current weapon's ammo slot each call.
    w_ready.num = function()
        local wi = d_items.weaponinfo[plyr.readyweapon + 1]
        if wi.ammo == doomdef.am_noammo then
            return largeammo
        end
        return plyr.ammo[wi.ammo + 1]
    end
    w_ready.data = plyr.readyweapon

    -- Update keycard multiple widgets. The C stores 0-based card indices
    -- in keyboxes[].
    for i = 0, 2 do
        keyboxes[i + 1] = plyr.cards[i + 1] and i or -1
        if plyr.cards[i + 4] then -- cards[i+3] (0-based)
            keyboxes[i + 1] = i + 3
        end
    end

    -- Refresh everything if this is him coming back to life.
    st_stuff.ST_updateFaceWidget()

    -- Used by the w_armsbg widget.
    st_notdeathmatch = not doomstat.deathmatch

    -- Used by w_arms[] widgets.
    st_armson = st_statusbaron and not doomstat.deathmatch

    -- Used by w_frags widget.
    st_fragson = doomstat.deathmatch ~= 0 and st_statusbaron
    st_fragscount = 0

    for i = 0, doomtype.MAXPLAYERS - 1 do
        if i ~= doomstat.consoleplayer then
            st_fragscount = st_fragscount + plyr.frags[i + 1]
        else
            st_fragscount = st_fragscount - plyr.frags[i + 1]
        end
    end

    -- Get rid of chat window if up because of message.
    st_msgcounter = st_msgcounter - 1
    if st_msgcounter == 0 then
        st_chat = st_oldchat
    end
end

-- ---------------------------------------------------------------------------
-- ST_Ticker
-- ---------------------------------------------------------------------------

function st_stuff.ST_Ticker()
    st_clock = st_clock + 1
    st_randomnumber = m_random.M_Random()
    st_stuff.ST_updateWidgets()
    st_oldhealth = plyr.health
end

-- ---------------------------------------------------------------------------
-- ST_doPaletteStuff
-- ---------------------------------------------------------------------------

function st_stuff.ST_doPaletteStuff()
    local palette
    local pal
    local cnt
    local bzc

    cnt = plyr.damagecount

    if plyr.powers[doomdef.pw_strength + 1] then
        -- Slowly fade the berzerk out.
        bzc = 12 - (plyr.powers[doomdef.pw_strength + 1] // 64)
        if bzc > cnt then
            cnt = bzc
        end
    end

    if cnt then
        palette = (cnt + 7) // 8

        if palette >= NUMREDPALS then
            palette = NUMREDPALS - 1
        end

        palette = palette + STARTREDPALS
    elseif plyr.bonuscount then
        palette = (plyr.bonuscount + 7) // 8

        if palette >= NUMBONUSPALS then
            palette = NUMBONUSPALS - 1
        end

        palette = palette + STARTBONUSPALS
    elseif plyr.powers[doomdef.pw_ironfeet + 1] > 4 * 32
        or bit32.band(plyr.powers[doomdef.pw_ironfeet + 1], 8) ~= 0 then
        palette = RADIATIONPAL
    else
        palette = 0
    end

    -- In Chex Quest, the player never sees red. Instead, the radiation suit
    -- palette is used to tint the screen green, as though the player is
    -- being covered in goo by an attacking flemoid.
    if doomstat.gameversion == d_mode.exe_chex
        and palette >= STARTREDPALS
        and palette < STARTREDPALS + NUMREDPALS then
        palette = RADIATIONPAL
    end

    if palette ~= st_palette then
        st_palette = palette
        pal = w_wad.W_CacheLumpNum(lu_palette, z_zone.PU_CACHE)
        i_video.I_SetPalette(pal.buffer, pal.offset + palette * 768)
    end
end

-- ---------------------------------------------------------------------------
-- ST_drawWidgets / ST_doRefresh / ST_diffDraw / ST_Drawer
-- ---------------------------------------------------------------------------

function st_stuff.ST_drawWidgets(refresh)
    local i

    -- Used by w_arms[] widgets.
    st_armson = st_statusbaron and not doomstat.deathmatch

    -- Used by w_frags widget.
    st_fragson = doomstat.deathmatch ~= 0 and st_statusbaron

    st_lib.STlib_updateNum(w_ready, refresh)

    for i = 0, 3 do
        st_lib.STlib_updateNum(w_ammo[i + 1], refresh)
        st_lib.STlib_updateNum(w_maxammo[i + 1], refresh)
    end

    st_lib.STlib_updatePercent(w_health, refresh)
    st_lib.STlib_updatePercent(w_armor, refresh)
    st_lib.STlib_updateBinIcon(w_armsbg, refresh)

    for i = 0, 5 do
        st_lib.STlib_updateMultIcon(w_arms[i + 1], refresh)
    end

    st_lib.STlib_updateMultIcon(w_faces, refresh)

    for i = 0, 2 do
        st_lib.STlib_updateMultIcon(w_keyboxes[i + 1], refresh)
    end

    st_lib.STlib_updateNum(w_frags, refresh)
end

function st_stuff.ST_doRefresh()
    st_firsttime = false

    -- Draw status bar background to off-screen buff.
    st_stuff.ST_refreshBackground()

    -- And refresh all widgets.
    st_stuff.ST_drawWidgets(true)
end

function st_stuff.ST_diffDraw()
    -- Update all widgets.
    st_stuff.ST_drawWidgets(false)
end

function st_stuff.ST_Drawer(fullscreen, refresh)
    st_statusbaron = (not fullscreen) or doomstat.automapactive
    st_firsttime = st_firsttime or refresh

    -- Do red-/gold-shifts from damage/items.
    st_stuff.ST_doPaletteStuff()

    -- If just after ST_Start(), refresh all.
    if st_firsttime then
        st_stuff.ST_doRefresh()
    else
        -- Otherwise, update as little as possible.
        st_stuff.ST_diffDraw()
    end
end

-- ---------------------------------------------------------------------------
-- ST_loadUnloadGraphics
-- ---------------------------------------------------------------------------

local function ST_loadCallback(lumpname)
    return w_wad.W_CacheLumpName(lumpname, z_zone.PU_STATIC)
end

local function ST_unloadCallback(lumpname)
    w_wad.W_ReleaseLumpName(lumpname)
    return nil
end

-- Iterates through all graphics to be loaded or unloaded, along with the
-- variable they use, invoking the specified callback function.
local function ST_loadUnloadGraphics(callback)
    local i, j
    local facenum
    local namebuf

    -- Load the numbers, tall and short.
    for i = 0, 9 do
        namebuf = deh_str.DEH_snprintf("STTNUM%d", i)
        tallnum[i + 1] = callback(namebuf)

        namebuf = deh_str.DEH_snprintf("STYSNUM%d", i)
        shortnum[i + 1] = callback(namebuf)
    end

    -- Load percent key. (Note: why not load STMINUS here, too?)
    tallpercent = callback(deh_str.DEH_String("STTPRCNT"))

    -- Key cards.
    for i = 0, doomdef.NUMCARDS - 1 do
        namebuf = deh_str.DEH_snprintf("STKEYS%d", i)
        keys[i + 1] = callback(namebuf)
    end

    -- Arms background.
    armsbg = callback(deh_str.DEH_String("STARMS"))

    -- Arms ownership widgets.
    for i = 0, 5 do
        namebuf = deh_str.DEH_snprintf("STGNUM%d", i + 2)

        -- Gray #.
        arms[i + 1] = {}
        arms[i + 1][1] = callback(namebuf)

        -- Yellow #.
        arms[i + 1][2] = shortnum[i + 3]
    end

    -- Face backgrounds for different color players.
    namebuf = deh_str.DEH_snprintf("STFB%d", doomstat.consoleplayer)
    faceback = callback(namebuf)

    -- Status bar background bits.
    sbar = callback(deh_str.DEH_String("STBAR"))

    -- Face states.
    facenum = 0
    for i = 0, ST_NUMPAINFACES - 1 do
        for j = 0, ST_NUMSTRAIGHTFACES - 1 do
            namebuf = deh_str.DEH_snprintf("STFST%d%d", i, j)
            faces[facenum + 1] = callback(namebuf)
            facenum = facenum + 1
        end
        namebuf = deh_str.DEH_snprintf("STFTR%d0", i) -- turn right
        faces[facenum + 1] = callback(namebuf)
        facenum = facenum + 1
        namebuf = deh_str.DEH_snprintf("STFTL%d0", i) -- turn left
        faces[facenum + 1] = callback(namebuf)
        facenum = facenum + 1
        namebuf = deh_str.DEH_snprintf("STFOUCH%d", i) -- ouch!
        faces[facenum + 1] = callback(namebuf)
        facenum = facenum + 1
        namebuf = deh_str.DEH_snprintf("STFEVL%d", i) -- evil grin ;)
        faces[facenum + 1] = callback(namebuf)
        facenum = facenum + 1
        namebuf = deh_str.DEH_snprintf("STFKILL%d", i) -- pissed off
        faces[facenum + 1] = callback(namebuf)
        facenum = facenum + 1
    end

    faces[facenum + 1] = callback(deh_str.DEH_String("STFGOD0"))
    facenum = facenum + 1
    faces[facenum + 1] = callback(deh_str.DEH_String("STFDEAD0"))
end

function st_stuff.ST_loadGraphics()
    ST_loadUnloadGraphics(ST_loadCallback)
end

function st_stuff.ST_loadData()
    lu_palette = w_wad.W_GetNumForName(deh_str.DEH_String("PLAYPAL"))
    st_stuff.ST_loadGraphics()
end

function st_stuff.ST_unloadGraphics()
    ST_loadUnloadGraphics(ST_unloadCallback)
end

function st_stuff.ST_unloadData()
    st_stuff.ST_unloadGraphics()
end

-- ---------------------------------------------------------------------------
-- ST_initData
-- ---------------------------------------------------------------------------

function st_stuff.ST_initData()
    local i

    st_firsttime = true
    plyr = doomstat.players[doomstat.consoleplayer + 1]

    st_clock = 0
    st_chatstate = 0 -- StartChatState
    st_gamestate = 1 -- FirstPersonState

    st_statusbaron = true
    st_oldchat = false
    st_chat = false
    st_cursoron = false

    st_faceindex = 0
    st_palette = -1

    st_oldhealth = -1

    for i = 0, doomdef.NUMWEAPONS - 1 do
        oldweaponsowned[i + 1] = plyr.weaponowned[i + 1]
    end

    for i = 0, 2 do
        keyboxes[i + 1] = -1
    end

    st_lib.STlib_init()
end

-- ---------------------------------------------------------------------------
-- ST_createWidgets
-- ---------------------------------------------------------------------------

function st_stuff.ST_createWidgets()
    local i

    -- Ready weapon ammo.
    st_lib.STlib_initNum(w_ready, ST_AMMOX, ST_AMMOY, tallnum,
        function()
            local wi = d_items.weaponinfo[plyr.readyweapon + 1]
            if wi.ammo == doomdef.am_noammo then
                return 1994
            end
            return plyr.ammo[wi.ammo + 1]
        end,
        function() return st_statusbaron end,
        ST_AMMOWIDTH)

    -- The last weapon type.
    w_ready.data = plyr.readyweapon

    -- Health percentage.
    st_lib.STlib_initPercent(w_health, ST_HEALTHX, ST_HEALTHY, tallnum,
        function() return plyr.health end,
        function() return st_statusbaron end,
        tallpercent)

    -- Arms background.
    st_lib.STlib_initBinIcon(w_armsbg, ST_ARMSBGX, ST_ARMSBGY, armsbg,
        function() return st_notdeathmatch end,
        function() return st_statusbaron end)

    -- Weapons owned.
    for i = 0, 5 do
        local slot = i + 1
        w_arms[slot] = {}
        st_lib.STlib_initMultIcon(w_arms[slot],
            ST_ARMSX + (i % 3) * ST_ARMSXSPACE,
            ST_ARMSY + (i // 3) * ST_ARMSYSPACE,
            arms[slot],
            function() return (plyr.weaponowned[slot + 1] and 1) or 0 end,
            function() return st_armson end)
    end

    -- Frags sum.
    st_lib.STlib_initNum(w_frags, ST_FRAGSX, ST_FRAGSY, tallnum,
        function() return st_fragscount end,
        function() return st_fragson end,
        ST_FRAGSWIDTH)

    -- Faces.
    st_lib.STlib_initMultIcon(w_faces, ST_FACESX, ST_FACESY, faces,
        function() return st_faceindex end,
        function() return st_statusbaron end)

    -- Armor percentage - should be colored later.
    st_lib.STlib_initPercent(w_armor, ST_ARMORX, ST_ARMORY, tallnum,
        function() return plyr.armorpoints end,
        function() return st_statusbaron end,
        tallpercent)

    -- Keyboxes 0-2.
    for i = 0, 2 do
        local kx, ky
        if i == 0 then
            kx = ST_KEY0X
            ky = ST_KEY0Y
        elseif i == 1 then
            kx = ST_KEY1X
            ky = ST_KEY1Y
        else
            kx = ST_KEY2X
            ky = ST_KEY2Y
        end
        w_keyboxes[i + 1] = {}
        st_lib.STlib_initMultIcon(w_keyboxes[i + 1], kx, ky, keys,
            function() return keyboxes[i + 1] end,
            function() return st_statusbaron end)
    end

    -- Ammo count (all four kinds).
    local ammo_x = { ST_AMMO0X, ST_AMMO1X, ST_AMMO2X, ST_AMMO3X }
    local ammo_y = { ST_AMMO0Y, ST_AMMO1Y, ST_AMMO2Y, ST_AMMO3Y }
    for i = 0, 3 do
        w_ammo[i + 1] = {}
        st_lib.STlib_initNum(w_ammo[i + 1], ammo_x[i + 1], ammo_y[i + 1],
            shortnum,
            function() return plyr.ammo[i + 1] end,
            function() return st_statusbaron end,
            ST_AMMO0WIDTH)
    end

    -- Max ammo count (all four kinds).
    local maxammo_x = { ST_MAXAMMO0X, ST_MAXAMMO1X, ST_MAXAMMO2X, ST_MAXAMMO3X }
    local maxammo_y = { ST_MAXAMMO0Y, ST_MAXAMMO1Y, ST_MAXAMMO2Y, ST_MAXAMMO3Y }
    for i = 0, 3 do
        w_maxammo[i + 1] = {}
        st_lib.STlib_initNum(w_maxammo[i + 1], maxammo_x[i + 1], maxammo_y[i + 1],
            shortnum,
            function() return plyr.maxammo[i + 1] end,
            function() return st_statusbaron end,
            ST_MAXAMMO0WIDTH)
    end
end

-- ---------------------------------------------------------------------------
-- ST_Start / ST_Stop / ST_Init
-- ---------------------------------------------------------------------------

function st_stuff.ST_Start()
    if not st_stopped then
        st_stuff.ST_Stop()
    end

    st_stuff.ST_initData()
    st_stuff.ST_createWidgets()
    st_stopped = false
end

function st_stuff.ST_Stop()
    if st_stopped then
        return
    end

    local pal = w_wad.W_CacheLumpNum(lu_palette, z_zone.PU_CACHE)
    i_video.I_SetPalette(pal.buffer, pal.offset)

    st_stopped = true
end

function st_stuff.ST_Init()
    st_stuff.ST_loadData()
    st_lib.st_backing_screen = z_zone.Z_Malloc(
        st_lib.ST_WIDTH * st_lib.ST_HEIGHT, z_zone.PU_STATIC, nil)
end

return st_stuff
end)()

wi_stuff = (function() 
local wi_stuff = {}

local SCREENWIDTH = 320
local SCREENHEIGHT = 200
local TICRATE = doomtype.TICRATE

-- The intermission state (stateenum_t).
local NoState = -1
local StatCount = 0
local ShowNextLoc = 1

local NUMEPISODES = 4
local NUMMAPS = 9

-- GLOBAL LOCATIONS
local WI_TITLEY = 2
local WI_SPACINGY = 33

-- SINGLE-PLAYER STUFF
local SP_STATSX = 50
local SP_STATSY = 50
local SP_TIMEX = 16
local SP_TIMEY = SCREENHEIGHT - 32

-- NET GAME STUFF
local NG_STATSY = 50

-- DEATHMATCH STUFF
local DM_MATRIXX = 42
local DM_MATRIXY = 68
local DM_SPACINGX = 40
local DM_TOTALSX = 269
local DM_KILLERSX = 10
local DM_KILLERSY = 100
local DM_VICTIMSX = 5
local DM_VICTIMSY = 50

-- animenum_t
local ANIM_ALWAYS = 0
local ANIM_RANDOM = 1
local ANIM_LEVEL = 2

-- State for single-player.
local SP_KILLS = 0
local SP_ITEMS = 2
local SP_SECRET = 4
local SP_FRAGS = 6
local SP_TIME = 8
local SP_PAR = SP_TIME
local SP_PAUSE = 1

-- In seconds.
local SHOWNEXTLOCDELAY = 4

-- ---------------------------------------------------------------------------
-- Level locations for episode maps.
-- ---------------------------------------------------------------------------

local lnodes = {
    -- Episode 0 World Map.
    {
        { 185, 164 }, -- level 0
        { 148, 143 }, -- level 1
        { 69, 122 },  -- level 2
        { 209, 102 }, -- level 3
        { 116, 89 },  -- level 4
        { 166, 55 },  -- level 5
        { 71, 56 },   -- level 6
        { 135, 29 },  -- level 7
        { 71, 24 },   -- level 8
    },
    -- Episode 1 World Map.
    {
        { 254, 25 },
        { 97, 50 },
        { 188, 64 },
        { 128, 78 },
        { 214, 92 },
        { 133, 130 },
        { 208, 136 },
        { 148, 140 },
        { 235, 158 },
    },
    -- Episode 2 World Map.
    {
        { 156, 168 },
        { 48, 154 },
        { 174, 95 },
        { 265, 75 },
        { 130, 48 },
        { 279, 23 },
        { 198, 48 },
        { 140, 25 },
        { 281, 136 },
    },
    -- Episode 3 is not used by the intermission (epsd > 2 handled).
    {},
}

-- ---------------------------------------------------------------------------
-- Animation locations for episodes 0..2.
-- ---------------------------------------------------------------------------

local function ANIM(type, period, nanims, x, y, nexttic)
    return {
        type = type, period = period, nanims = nanims,
        loc = { x = x, y = y },
        data1 = nexttic, data2 = 0,
        p = { nil, nil, nil },
        nexttic = 0, lastdrawn = 0, ctr = 0, state = 0,
    }
end

local epsd0animinfo = {
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 224, 104, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 184, 160, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 112, 136, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 72, 112, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 88, 96, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 64, 48, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 192, 40, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 136, 16, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 80, 16, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 64, 24, 0),
}

local epsd1animinfo = {
    ANIM(ANIM_LEVEL, TICRATE // 3, 1, 128, 136, 1),
    ANIM(ANIM_LEVEL, TICRATE // 3, 1, 128, 136, 2),
    ANIM(ANIM_LEVEL, TICRATE // 3, 1, 128, 136, 3),
    ANIM(ANIM_LEVEL, TICRATE // 3, 1, 128, 136, 4),
    ANIM(ANIM_LEVEL, TICRATE // 3, 1, 128, 136, 5),
    ANIM(ANIM_LEVEL, TICRATE // 3, 1, 128, 136, 6),
    ANIM(ANIM_LEVEL, TICRATE // 3, 1, 128, 136, 7),
    ANIM(ANIM_LEVEL, TICRATE // 3, 3, 192, 144, 8),
    ANIM(ANIM_LEVEL, TICRATE // 3, 1, 128, 136, 8),
}

local epsd2animinfo = {
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 104, 168, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 40, 136, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 160, 96, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 104, 80, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 3, 3, 120, 32, 0),
    ANIM(ANIM_ALWAYS, TICRATE // 4, 3, 40, 0, 0),
}

local NUMANIMS = {
    #epsd0animinfo,
    #epsd1animinfo,
    #epsd2animinfo,
    0,
}

local anims = {
    epsd0animinfo,
    epsd1animinfo,
    epsd2animinfo,
    {},
}

-- ---------------------------------------------------------------------------
-- State (C statics)
-- ---------------------------------------------------------------------------

local acceleratestage = 0 -- used to accelerate or skip a stage
local me = 0 -- wbs->pnum
local state = NoState -- specifies current state
local wbs = nil -- contains information passed into intermission
local plrs = nil -- wbs->plyr[]
local cnt = 0 -- used for general timing
local bcnt = 0 -- used for timing of background animation
local firstrefresh = 1 -- signals to refresh everything for one frame
local cnt_kills = {}
local cnt_items = {}
local cnt_secret = {}
local cnt_time = 0
local cnt_par = 0
local cnt_pause = 0
local NUMCMAPS = 0 -- # of commercial levels

-- Graphics.
local yah = { nil, nil, nil } -- "You Are Here" graphic
local splat = { nil, nil } -- splat
local percent = nil -- % graphic
local colon = nil -- : graphic
local num = {} -- 0-9 graphic
local wiminus = nil -- minus sign
local finished = nil -- "Finished!" graphic
local entering = nil -- "Entering" graphic
local sp_secret = nil -- "secret"
local kills = nil -- "Kills"
local secret = nil -- "Scrt"
local items = nil -- "Items"
local frags = nil -- "Frags"
local timepatch = nil -- "Time sucks."
local par = nil
local sucks = nil
local killers = nil -- "killers"
local victims = nil -- "victims"
local total = nil -- "Total"
local star = nil -- your face
local bstar = nil -- your dead face
local p = {} -- "red P[1..MAXPLAYERS]"
local bp = {} -- "gray P[1..MAXPLAYERS]"
local lnames = nil -- name graphics of each level
local background = nil -- buffer storing the backdrop

-- Deathmatch / netgame stats.
local dm_state = 0
local dm_frags = {}
local dm_totals = {}
local cnt_frags = {}
local dofrags = 0
local ng_state = 0
local sp_state = 0

local snl_pointeron = false

local function patch_short(patch, off)
    return buffer.readi16(patch.buffer, patch.offset + off)
end

-- ---------------------------------------------------------------------------
-- WI_slamBackground
-- ---------------------------------------------------------------------------

local function WI_slamBackground()
    v_video.V_DrawPatch(0, 0, background)
end

-- The ticker is used to detect keys because of timing issues in netgames.
function wi_stuff.WI_Responder(ev)
    return false
end

-- Draws "<Levelname> Finished!"
local function WI_drawLF()
    local y = WI_TITLEY

    if doomstat.gamemode ~= d_mode.commercial or wbs.last < NUMCMAPS then
        -- Draw <LevelName>.
        v_video.V_DrawPatch((SCREENWIDTH - patch_short(lnames[wbs.last + 1], 0)) // 2,
            y, lnames[wbs.last + 1])

        -- Draw "Finished!".
        y = y + (5 * patch_short(lnames[wbs.last + 1], 2)) // 4

        v_video.V_DrawPatch((SCREENWIDTH - patch_short(finished, 0)) // 2, y, finished)
    elseif wbs.last == NUMCMAPS then
        -- MAP33 - nothing is displayed!
    elseif wbs.last > NUMCMAPS then
        -- > MAP33. Doom bombs out here with a Bad V_DrawPatch error. This
        -- deliberately triggers a V_DrawPatch error (as the C reads into
        -- random bits of memory). Build a 320x200 fake patch: 4 shorts
        -- (8 bytes) + 8 ints (32 bytes) = 40 bytes.
        local tb = buffer.create(40)
        buffer.writei16(tb, 0, SCREENWIDTH)
        buffer.writei16(tb, 2, SCREENHEIGHT)
        buffer.writei16(tb, 4, 1)
        buffer.writei16(tb, 6, 1)
        for _ = 0, 7 do
            buffer.writei32(tb, 8 + _ * 4, 0)
        end
        v_video.V_DrawPatch(0, y, { buffer = tb, offset = 0 })
    end
end

-- Draws "Entering <LevelName>".
local function WI_drawEL()
    local y = WI_TITLEY

    -- Draw "Entering".
    v_video.V_DrawPatch((SCREENWIDTH - patch_short(entering, 0)) // 2, y, entering)

    -- Draw level.
    y = y + (5 * patch_short(lnames[wbs.next + 1], 2)) // 4

    v_video.V_DrawPatch((SCREENWIDTH - patch_short(lnames[wbs.next + 1], 0)) // 2,
        y, lnames[wbs.next + 1])
end

local function WI_drawOnLnode(n, c)
    local i = 0
    local left
    local top
    local right
    local bottom
    local fits = false

    repeat
        left = lnodes[wbs.epsd + 1][n + 1][1] - patch_short(c[i + 1], 4)
        top = lnodes[wbs.epsd + 1][n + 1][2] - patch_short(c[i + 1], 6)
        right = left + patch_short(c[i + 1], 0)
        bottom = top + patch_short(c[i + 1], 2)

        if left >= 0
            and right < SCREENWIDTH
            and top >= 0
            and bottom < SCREENHEIGHT then
            fits = true
        else
            i = i + 1
        end
    until fits or i == 2 or c[i + 1] == nil

    if fits and i < 2 then
        v_video.V_DrawPatch(lnodes[wbs.epsd + 1][n + 1][1],
            lnodes[wbs.epsd + 1][n + 1][2], c[i + 1])
    else
        -- DEBUG
        print(string.format("Could not place patch on level %d", n + 1))
    end
end

-- ---------------------------------------------------------------------------
-- Animated background
-- ---------------------------------------------------------------------------

local function WI_initAnimatedBack()
    local i
    local a

    if doomstat.gamemode == d_mode.commercial then
        return
    end
    if wbs.epsd > 2 then
        return
    end

    for i = 1, NUMANIMS[wbs.epsd + 1] do
        a = anims[wbs.epsd + 1][i]

        -- Init variables.
        a.ctr = -1

        -- Specify the next time to draw it.
        if a.type == ANIM_ALWAYS then
            a.nexttic = bcnt + 1 + (m_random.M_Random() % a.period)
        elseif a.type == ANIM_RANDOM then
            a.nexttic = bcnt + 1 + a.data2 + (m_random.M_Random() % a.data1)
        elseif a.type == ANIM_LEVEL then
            a.nexttic = bcnt + 1
        end
    end
end

local function WI_updateAnimatedBack()
    local i
    local a

    if doomstat.gamemode == d_mode.commercial then
        return
    end
    if wbs.epsd > 2 then
        return
    end

    for i = 1, NUMANIMS[wbs.epsd + 1] do
        a = anims[wbs.epsd + 1][i]

        if bcnt == a.nexttic then
            if a.type == ANIM_ALWAYS then
                a.ctr = a.ctr + 1
                if a.ctr >= a.nanims then
                    a.ctr = 0
                end
                a.nexttic = bcnt + a.period
            elseif a.type == ANIM_RANDOM then
                a.ctr = a.ctr + 1
                if a.ctr == a.nanims then
                    a.ctr = -1
                    a.nexttic = bcnt + a.data2 + (m_random.M_Random() % a.data1)
                else
                    a.nexttic = bcnt + a.period
                end
            elseif a.type == ANIM_LEVEL then
                -- Gawd-awful hack for level anims.
                if not (state == StatCount and i - 1 == 7)
                    and wbs.next == a.data1 then
                    a.ctr = a.ctr + 1
                    if a.ctr == a.nanims then
                        a.ctr = a.ctr - 1
                    end
                    a.nexttic = bcnt + a.period
                end
            end
        end
    end
end

local function WI_drawAnimatedBack()
    local i
    local a

    if doomstat.gamemode == d_mode.commercial then
        return
    end
    if wbs.epsd > 2 then
        return
    end

    for i = 1, NUMANIMS[wbs.epsd + 1] do
        a = anims[wbs.epsd + 1][i]
        if a.ctr >= 0 then
            v_video.V_DrawPatch(a.loc.x, a.loc.y, a.p[a.ctr + 1])
        end
    end
end

-- ---------------------------------------------------------------------------
-- WI_drawNum / WI_drawPercent / WI_drawTime
-- ---------------------------------------------------------------------------

-- Draws a number. If digits > 0, use that many digits minimum, otherwise
-- only use as many as necessary. Returns the new x position.
local function WI_drawNum(x, y, n, digits)
    local fontwidth = patch_short(num[1], 0)
    local neg
    local temp

    if digits < 0 then
        if n == 0 then
            -- Make variable-length zeros 1 digit long.
            digits = 1
        else
            -- Figure out # of digits in #.
            digits = 0
            temp = n
            while temp ~= 0 do
                temp = doomtype.truncdiv(temp, 10)
                digits = digits + 1
            end
        end
    end

    neg = n < 0
    if neg then
        n = -n
    end

    -- If non-number, do not draw it.
    if n == 1994 then
        return 0
    end

    -- Draw the new number.
    while digits > 0 do
        digits = digits - 1
        x = x - fontwidth
        v_video.V_DrawPatch(x, y, num[n % 10 + 1])
        n = n // 10
    end

    -- Draw a minus sign if necessary.
    if neg then
        x = x - 8
        v_video.V_DrawPatch(x, y, wiminus)
    end

    return x
end

local function WI_drawPercent(x, y, p)
    if p < 0 then
        return
    end

    v_video.V_DrawPatch(x, y, percent)
    WI_drawNum(x, y, p, -1)
end

-- Display level completion time and par, or "sucks" message if overflow.
local function WI_drawTime(x, y, t)
    local div
    local n

    if t < 0 then
        return
    end

    if t <= 61 * 59 then
        div = 1

        repeat
            n = (t // div) % 60
            x = WI_drawNum(x, y, n, 2) - patch_short(colon, 0)
            div = div * 60

            -- Draw.
            if div == 60 or t // div ~= 0 then
                v_video.V_DrawPatch(x, y, colon)
            end
        until t // div == 0
    else
        -- "sucks".
        v_video.V_DrawPatch(x - patch_short(sucks, 0), y, sucks)
    end
end

-- ---------------------------------------------------------------------------
-- WI_End / NoState / ShowNextLoc
-- ---------------------------------------------------------------------------

function wi_stuff.WI_End()
    wi_stuff.WI_unloadData()
end

local function WI_initNoState()
    state = NoState
    acceleratestage = 0
    cnt = 10
end

local function WI_updateNoState()
    WI_updateAnimatedBack()

    cnt = cnt - 1
    if cnt == 0 then
        -- Don't call WI_End yet. G_WorldDone doesn't immediately change
        -- gamestate, so WI_Drawer is still going to get run until that
        -- happens. If we do that after WI_End (which unloads all the
        -- graphics), we're in trouble.
        g_game.G_WorldDone()
    end
end

local function WI_initShowNextLoc()
    state = ShowNextLoc
    acceleratestage = 0
    cnt = SHOWNEXTLOCDELAY * TICRATE

    WI_initAnimatedBack()
end

local function WI_updateShowNextLoc()
    WI_updateAnimatedBack()

    cnt = cnt - 1
    if cnt == 0 or acceleratestage ~= 0 then
        WI_initNoState()
    else
        snl_pointeron = (cnt % 32) < 20
    end
end

local function WI_drawShowNextLoc()
    local i
    local last

    WI_slamBackground()

    -- Draw animated background.
    WI_drawAnimatedBack()

    if doomstat.gamemode ~= d_mode.commercial then
        if wbs.epsd > 2 then
            WI_drawEL()
            return
        end

        last = (wbs.last == 8) and (wbs.next - 1) or wbs.last

        -- Draw a splat on taken cities.
        for i = 0, last do
            WI_drawOnLnode(i, splat)
        end

        -- Splat the secret level?
        if wbs.didsecret then
            WI_drawOnLnode(8, splat)
        end

        -- Draw flashing ptr.
        if snl_pointeron then
            WI_drawOnLnode(wbs.next, yah)
        end
    end

    -- Draws which level you are entering.
    if doomstat.gamemode ~= d_mode.commercial or wbs.next ~= 30 then
        WI_drawEL()
    end
end

local function WI_drawNoState()
    snl_pointeron = true
    WI_drawShowNextLoc()
end

local function WI_fragSum(playernum)
    local i
    local frags_ = 0

    for i = 0, doomtype.MAXPLAYERS - 1 do
        if doomstat.playeringame[i + 1] and i ~= playernum then
            frags_ = frags_ + plrs[playernum + 1].frags[i + 1]
        end
    end

    -- JDC hack - negative frags.
    frags_ = frags_ - plrs[playernum + 1].frags[playernum + 1]

    return frags_
end

-- ---------------------------------------------------------------------------
-- Deathmatch stats (dead code in v1; kept for parity)
-- ---------------------------------------------------------------------------

local function WI_initDeathmatchStats()
    local i
    local j

    state = StatCount
    acceleratestage = 0
    dm_state = 1

    cnt_pause = TICRATE

    for i = 0, doomtype.MAXPLAYERS - 1 do
        if doomstat.playeringame[i + 1] then
            dm_frags[i + 1] = {}
            for j = 0, doomtype.MAXPLAYERS - 1 do
                if doomstat.playeringame[j + 1] then
                    dm_frags[i + 1][j + 1] = 0
                end
            end
            dm_totals[i + 1] = 0
        end
    end

    WI_initAnimatedBack()
end

local function WI_updateDeathmatchStats()
    local i
    local j
    local stillticking

    WI_updateAnimatedBack()

    if acceleratestage ~= 0 and dm_state ~= 4 then
        acceleratestage = 0

        for i = 0, doomtype.MAXPLAYERS - 1 do
            if doomstat.playeringame[i + 1] then
                for j = 0, doomtype.MAXPLAYERS - 1 do
                    if doomstat.playeringame[j + 1] then
                        dm_frags[i + 1][j + 1] = plrs[i + 1].frags[j + 1]
                    end
                end
                dm_totals[i + 1] = WI_fragSum(i)
            end
        end

        s_sound.S_StartSound(0, 0)
        dm_state = 4
    end

    if dm_state == 2 then
        stillticking = false

        for i = 0, doomtype.MAXPLAYERS - 1 do
            if doomstat.playeringame[i + 1] then
                for j = 0, doomtype.MAXPLAYERS - 1 do
                    if doomstat.playeringame[j + 1]
                        and dm_frags[i + 1][j + 1] ~= plrs[i + 1].frags[j + 1] then
                        if plrs[i + 1].frags[j + 1] < 0 then
                            dm_frags[i + 1][j + 1] = dm_frags[i + 1][j + 1] - 1
                        else
                            dm_frags[i + 1][j + 1] = dm_frags[i + 1][j + 1] + 1
                        end

                        if dm_frags[i + 1][j + 1] > 99 then
                            dm_frags[i + 1][j + 1] = 99
                        end
                        if dm_frags[i + 1][j + 1] < -99 then
                            dm_frags[i + 1][j + 1] = -99
                        end

                        stillticking = true
                    end
                end
                dm_totals[i + 1] = WI_fragSum(i)

                if dm_totals[i + 1] > 99 then
                    dm_totals[i + 1] = 99
                end
                if dm_totals[i + 1] < -99 then
                    dm_totals[i + 1] = -99
                end
            end
        end
        if not stillticking then
            s_sound.S_StartSound(0, 0)
            dm_state = dm_state + 1
        end
    elseif dm_state == 4 then
        if acceleratestage ~= 0 then
            s_sound.S_StartSound(0, 0)
            if doomstat.gamemode == d_mode.commercial then
                WI_initNoState()
            else
                WI_initShowNextLoc()
            end
        end
    elseif bit32.band(dm_state, 1) ~= 0 then
        cnt_pause = cnt_pause - 1
        if cnt_pause == 0 then
            dm_state = dm_state + 1
            cnt_pause = TICRATE
        end
    end
end

local function WI_drawDeathmatchStats()
    local i
    local j
    local x
    local y
    local w

    WI_slamBackground()

    -- Draw animated background.
    WI_drawAnimatedBack()
    WI_drawLF()

    -- Draw stat titles (top line).
    v_video.V_DrawPatch(DM_TOTALSX - patch_short(total, 0) // 2,
        DM_MATRIXY - WI_SPACINGY + 10, total)

    v_video.V_DrawPatch(DM_KILLERSX, DM_KILLERSY, killers)
    v_video.V_DrawPatch(DM_VICTIMSX, DM_VICTIMSY, victims)

    -- Draw P?
    x = DM_MATRIXX + DM_SPACINGX
    y = DM_MATRIXY

    for i = 0, doomtype.MAXPLAYERS - 1 do
        if doomstat.playeringame[i + 1] then
            v_video.V_DrawPatch(x - patch_short(p[i + 1], 0) // 2,
                DM_MATRIXY - WI_SPACINGY, p[i + 1])

            v_video.V_DrawPatch(DM_MATRIXX - patch_short(p[i + 1], 0) // 2,
                y, p[i + 1])

            if i == me then
                v_video.V_DrawPatch(x - patch_short(p[i + 1], 0) // 2,
                    DM_MATRIXY - WI_SPACINGY, bstar)

                v_video.V_DrawPatch(DM_MATRIXX - patch_short(p[i + 1], 0) // 2,
                    y, star)
            end
        end
        x = x + DM_SPACINGX
        y = y + WI_SPACINGY
    end

    -- Draw stats.
    y = DM_MATRIXY + 10
    w = patch_short(num[1], 0)

    for i = 0, doomtype.MAXPLAYERS - 1 do
        x = DM_MATRIXX + DM_SPACINGX

        if doomstat.playeringame[i + 1] then
            for j = 0, doomtype.MAXPLAYERS - 1 do
                if doomstat.playeringame[j + 1] then
                    WI_drawNum(x + w, y, dm_frags[i + 1][j + 1], 2)
                end
                x = x + DM_SPACINGX
            end
            WI_drawNum(DM_TOTALSX + w, y, dm_totals[i + 1], 2)
        end
        y = y + WI_SPACINGY
    end
end

-- ---------------------------------------------------------------------------
-- Netgame stats (dead code in v1; kept for parity)
-- ---------------------------------------------------------------------------

local function WI_initNetgameStats()
    local i

    state = StatCount
    acceleratestage = 0
    ng_state = 1

    cnt_pause = TICRATE

    for i = 0, doomtype.MAXPLAYERS - 1 do
        if not doomstat.playeringame[i + 1] then
            -- continue
        else
            cnt_kills[i + 1] = 0
            cnt_items[i + 1] = 0
            cnt_secret[i + 1] = 0
            cnt_frags[i + 1] = 0
            dofrags = dofrags + WI_fragSum(i)
        end
    end

    dofrags = dofrags ~= 0 and 1 or 0

    WI_initAnimatedBack()
end

local function WI_updateNetgameStats()
    local i
    local fsum
    local stillticking

    WI_updateAnimatedBack()

    if acceleratestage ~= 0 and ng_state ~= 10 then
        acceleratestage = 0

        for i = 0, doomtype.MAXPLAYERS - 1 do
            if doomstat.playeringame[i + 1] then
                cnt_kills[i + 1] = (plrs[i + 1].skills * 100) // wbs.maxkills
                cnt_items[i + 1] = (plrs[i + 1].sitems * 100) // wbs.maxitems
                cnt_secret[i + 1] = (plrs[i + 1].ssecret * 100) // wbs.maxsecret

                if dofrags ~= 0 then
                    cnt_frags[i + 1] = WI_fragSum(i)
                end
            end
        end
        s_sound.S_StartSound(0, 0)
        ng_state = 10
    end

    if ng_state == 2 then
        stillticking = false

        for i = 0, doomtype.MAXPLAYERS - 1 do
            if doomstat.playeringame[i + 1] then
                cnt_kills[i + 1] = cnt_kills[i + 1] + 2

                if cnt_kills[i + 1] >= (plrs[i + 1].skills * 100) // wbs.maxkills then
                    cnt_kills[i + 1] = (plrs[i + 1].skills * 100) // wbs.maxkills
                else
                    stillticking = true
                end
            end
        end

        if not stillticking then
            s_sound.S_StartSound(0, 0)
            ng_state = ng_state + 1
        end
    elseif ng_state == 4 then
        stillticking = false

        for i = 0, doomtype.MAXPLAYERS - 1 do
            if doomstat.playeringame[i + 1] then
                cnt_items[i + 1] = cnt_items[i + 1] + 2
                if cnt_items[i + 1] >= (plrs[i + 1].sitems * 100) // wbs.maxitems then
                    cnt_items[i + 1] = (plrs[i + 1].sitems * 100) // wbs.maxitems
                else
                    stillticking = true
                end
            end
        end
        if not stillticking then
            s_sound.S_StartSound(0, 0)
            ng_state = ng_state + 1
        end
    elseif ng_state == 6 then
        stillticking = false

        for i = 0, doomtype.MAXPLAYERS - 1 do
            if doomstat.playeringame[i + 1] then
                cnt_secret[i + 1] = cnt_secret[i + 1] + 2

                if cnt_secret[i + 1] >= (plrs[i + 1].ssecret * 100) // wbs.maxsecret then
                    cnt_secret[i + 1] = (plrs[i + 1].ssecret * 100) // wbs.maxsecret
                else
                    stillticking = true
                end
            end
        end

        if not stillticking then
            s_sound.S_StartSound(0, 0)
            ng_state = ng_state + 1 + 2 * (1 - dofrags)
        end
    elseif ng_state == 8 then
        stillticking = false

        for i = 0, doomtype.MAXPLAYERS - 1 do
            if doomstat.playeringame[i + 1] then
                cnt_frags[i + 1] = cnt_frags[i + 1] + 1

                fsum = WI_fragSum(i)
                if cnt_frags[i + 1] >= fsum then
                    cnt_frags[i + 1] = fsum
                else
                    stillticking = true
                end
            end
        end

        if not stillticking then
            s_sound.S_StartSound(0, 0)
            ng_state = ng_state + 1
        end
    elseif ng_state == 10 then
        if acceleratestage ~= 0 then
            s_sound.S_StartSound(0, 0)
            if doomstat.gamemode == d_mode.commercial then
                WI_initNoState()
            else
                WI_initShowNextLoc()
            end
        end
    elseif bit32.band(ng_state, 1) ~= 0 then
        cnt_pause = cnt_pause - 1
        if cnt_pause == 0 then
            ng_state = ng_state + 1
            cnt_pause = TICRATE
        end
    end
end

local NG_SPACINGX = 64

local function NG_STATSX()
    return 32 + patch_short(star, 0) // 2 + 32 * (1 - dofrags)
end

local function WI_drawNetgameStats()
    local i
    local x
    local y
    local pwidth = patch_short(percent, 0)

    WI_slamBackground()

    -- Draw animated background.
    WI_drawAnimatedBack()

    WI_drawLF()

    -- Draw stat titles (top line).
    v_video.V_DrawPatch(NG_STATSX() + NG_SPACINGX - patch_short(kills, 0),
        NG_STATSY, kills)

    v_video.V_DrawPatch(NG_STATSX() + 2 * NG_SPACINGX - patch_short(items, 0),
        NG_STATSY, items)

    v_video.V_DrawPatch(NG_STATSX() + 3 * NG_SPACINGX - patch_short(secret, 0),
        NG_STATSY, secret)

    if dofrags ~= 0 then
        v_video.V_DrawPatch(NG_STATSX() + 4 * NG_SPACINGX - patch_short(frags, 0),
            NG_STATSY, frags)
    end

    -- Draw stats.
    y = NG_STATSY + patch_short(kills, 2)

    for i = 0, doomtype.MAXPLAYERS - 1 do
        if doomstat.playeringame[i + 1] then
            x = NG_STATSX()
            v_video.V_DrawPatch(x - patch_short(p[i + 1], 0), y, p[i + 1])

            if i == me then
                v_video.V_DrawPatch(x - patch_short(p[i + 1], 0), y, star)
            end

            x = x + NG_SPACINGX
            WI_drawPercent(x - pwidth, y + 10, cnt_kills[i + 1])
            x = x + NG_SPACINGX
            WI_drawPercent(x - pwidth, y + 10, cnt_items[i + 1])
            x = x + NG_SPACINGX
            WI_drawPercent(x - pwidth, y + 10, cnt_secret[i + 1])
            x = x + NG_SPACINGX

            if dofrags ~= 0 then
                WI_drawNum(x, y + 10, cnt_frags[i + 1], -1)
            end

            y = y + WI_SPACINGY
        end
    end
end

-- ---------------------------------------------------------------------------
-- Single-player stats
-- ---------------------------------------------------------------------------

local function WI_initStats()
    state = StatCount
    acceleratestage = 0
    sp_state = 1
    cnt_kills[1] = -1
    cnt_items[1] = -1
    cnt_secret[1] = -1
    cnt_time = -1
    cnt_par = -1
    cnt_pause = TICRATE

    WI_initAnimatedBack()
end

local function WI_updateStats()
    WI_updateAnimatedBack()

    if acceleratestage ~= 0 and sp_state ~= 10 then
        acceleratestage = 0
        cnt_kills[1] = (plrs[me + 1].skills * 100) // wbs.maxkills
        cnt_items[1] = (plrs[me + 1].sitems * 100) // wbs.maxitems
        cnt_secret[1] = (plrs[me + 1].ssecret * 100) // wbs.maxsecret
        cnt_time = plrs[me + 1].stime // TICRATE
        cnt_par = wbs.partime // TICRATE
        s_sound.S_StartSound(0, 0)
        sp_state = 10
    end

    if sp_state == 2 then
        cnt_kills[1] = cnt_kills[1] + 2

        if cnt_kills[1] >= (plrs[me + 1].skills * 100) // wbs.maxkills then
            cnt_kills[1] = (plrs[me + 1].skills * 100) // wbs.maxkills
            s_sound.S_StartSound(0, 0)
            sp_state = sp_state + 1
        end
    elseif sp_state == 4 then
        cnt_items[1] = cnt_items[1] + 2

        if cnt_items[1] >= (plrs[me + 1].sitems * 100) // wbs.maxitems then
            cnt_items[1] = (plrs[me + 1].sitems * 100) // wbs.maxitems
            s_sound.S_StartSound(0, 0)
            sp_state = sp_state + 1
        end
    elseif sp_state == 6 then
        cnt_secret[1] = cnt_secret[1] + 2

        if cnt_secret[1] >= (plrs[me + 1].ssecret * 100) // wbs.maxsecret then
            cnt_secret[1] = (plrs[me + 1].ssecret * 100) // wbs.maxsecret
            s_sound.S_StartSound(0, 0)
            sp_state = sp_state + 1
        end
    elseif sp_state == 8 then
        cnt_time = cnt_time + 3

        if cnt_time >= plrs[me + 1].stime // TICRATE then
            cnt_time = plrs[me + 1].stime // TICRATE
        end

        cnt_par = cnt_par + 3

        if cnt_par >= wbs.partime // TICRATE then
            cnt_par = wbs.partime // TICRATE

            if cnt_time >= plrs[me + 1].stime // TICRATE then
                s_sound.S_StartSound(0, 0)
                sp_state = sp_state + 1
            end
        end
    elseif sp_state == 10 then
        if acceleratestage ~= 0 then
            s_sound.S_StartSound(0, 0)
            if doomstat.gamemode == d_mode.commercial then
                WI_initNoState()
            else
                WI_initShowNextLoc()
            end
        end
    elseif bit32.band(sp_state, 1) ~= 0 then
        cnt_pause = cnt_pause - 1
        if cnt_pause == 0 then
            sp_state = sp_state + 1
            cnt_pause = TICRATE
        end
    end
end

local function WI_drawStats()
    -- Line height.
    local lh = (3 * patch_short(num[1], 2)) // 2

    WI_slamBackground()

    -- Draw animated background.
    WI_drawAnimatedBack()

    WI_drawLF()

    v_video.V_DrawPatch(SP_STATSX, SP_STATSY, kills)
    WI_drawPercent(SCREENWIDTH - SP_STATSX, SP_STATSY, cnt_kills[1])

    v_video.V_DrawPatch(SP_STATSX, SP_STATSY + lh, items)
    WI_drawPercent(SCREENWIDTH - SP_STATSX, SP_STATSY + lh, cnt_items[1])

    v_video.V_DrawPatch(SP_STATSX, SP_STATSY + 2 * lh, sp_secret)
    WI_drawPercent(SCREENWIDTH - SP_STATSX, SP_STATSY + 2 * lh, cnt_secret[1])

    v_video.V_DrawPatch(SP_TIMEX, SP_TIMEY, timepatch)
    WI_drawTime(SCREENWIDTH // 2 - SP_TIMEX, SP_TIMEY, cnt_time)

    if wbs.epsd < 3 then
        v_video.V_DrawPatch(SCREENWIDTH // 2 + SP_TIMEX, SP_TIMEY, par)
        WI_drawTime(SCREENWIDTH - SP_TIMEX, SP_TIMEY, cnt_par)
    end
end

-- ---------------------------------------------------------------------------
-- WI_checkForAccelerate
-- ---------------------------------------------------------------------------

local function WI_checkForAccelerate()
    local i
    local player

    -- Check for button presses to skip delays.
    for i = 1, doomtype.MAXPLAYERS do
        player = doomstat.players[i]
        if doomstat.playeringame[i] then
            if bit32.band(player.cmd.buttons, 1) ~= 0 then -- BT_ATTACK
                if not player.attackdown then
                    acceleratestage = 1
                end
                player.attackdown = true
            else
                player.attackdown = false
            end
            if bit32.band(player.cmd.buttons, 2) ~= 0 then -- BT_USE
                if not player.usedown then
                    acceleratestage = 1
                end
                player.usedown = true
            else
                player.usedown = false
            end
        end
    end
end

-- Updates stuff each tick.
function wi_stuff.WI_Ticker()
    -- Counter for general background animation.
    bcnt = bcnt + 1

    if bcnt == 1 then
        -- Intermission music.
        if doomstat.gamemode == d_mode.commercial then
            s_sound.S_ChangeMusic(0, true)
        else
            s_sound.S_ChangeMusic(0, true)
        end
    end

    WI_checkForAccelerate()

    if state == StatCount then
        if doomstat.deathmatch ~= 0 then
            WI_updateDeathmatchStats()
        elseif doomstat.netgame then
            WI_updateNetgameStats()
        else
            WI_updateStats()
        end
    elseif state == ShowNextLoc then
        WI_updateShowNextLoc()
    elseif state == NoState then
        WI_updateNoState()
    end
end

-- ---------------------------------------------------------------------------
-- WI_loadUnloadData
-- ---------------------------------------------------------------------------

local function WI_loadCallback(name)
    return w_wad.W_CacheLumpName(name, z_zone.PU_STATIC)
end

local function WI_unloadCallback(name)
    w_wad.W_ReleaseLumpName(name)
    return nil
end

-- Common load/unload function. Iterates over all the graphics lumps to be
-- loaded/unloaded into memory.
local function WI_loadUnloadData(callback)
    local i, j
    local name
    local a

    if doomstat.gamemode == d_mode.commercial then
        for i = 0, NUMCMAPS - 1 do
            name = deh_str.DEH_snprintf("CWILV%02d", i)
            lnames[i + 1] = callback(name)
        end
    else
        for i = 0, NUMMAPS - 1 do
            name = deh_str.DEH_snprintf("WILV%d%d", wbs.epsd, i)
            lnames[i + 1] = callback(name)
        end

        -- You are here.
        yah[1] = callback(deh_str.DEH_String("WIURH0"))
        -- You are here (alt.).
        yah[2] = callback(deh_str.DEH_String("WIURH1"))

        -- Splat.
        splat[1] = callback(deh_str.DEH_String("WISPLAT"))

        if wbs.epsd < 3 then
            for j = 1, NUMANIMS[wbs.epsd + 1] do
                a = anims[wbs.epsd + 1][j]
                for i = 0, a.nanims - 1 do
                    -- MONDO HACK!
                    if wbs.epsd ~= 1 or j - 1 ~= 8 then
                        -- Animations.
                        name = deh_str.DEH_snprintf("WIA%d%02d%02d", wbs.epsd, j - 1, i)
                        a.p[i + 1] = callback(name)
                    else
                        -- HACK ALERT!
                        a.p[i + 1] = anims[2][5].p[i + 1] -- anims[1][4].p[i] (0-based)
                    end
                end
            end
        end
    end

    -- More hacks on minus sign.
    wiminus = callback(deh_str.DEH_String("WIMINUS"))

    for i = 0, 9 do
        -- Numbers 0-9.
        name = deh_str.DEH_snprintf("WINUM%d", i)
        num[i + 1] = callback(name)
    end

    -- Percent sign.
    percent = callback(deh_str.DEH_String("WIPCNT"))

    -- "finished".
    finished = callback(deh_str.DEH_String("WIF"))

    -- "entering".
    entering = callback(deh_str.DEH_String("WIENTER"))

    -- "kills".
    kills = callback(deh_str.DEH_String("WIOSTK"))

    -- "scrt".
    secret = callback(deh_str.DEH_String("WIOSTS"))

    -- "secret".
    sp_secret = callback(deh_str.DEH_String("WISCRT2"))

    -- French wad uses WIOBJ (?).
    if w_wad.W_CheckNumForName(deh_str.DEH_String("WIOBJ")) >= 0 then
        -- "items".
        if doomstat.netgame and doomstat.deathmatch == 0 then
            items = callback(deh_str.DEH_String("WIOBJ"))
        else
            items = callback(deh_str.DEH_String("WIOSTI"))
        end
    else
        items = callback(deh_str.DEH_String("WIOSTI"))
    end

    -- "frgs".
    frags = callback(deh_str.DEH_String("WIFRGS"))

    -- ":".
    colon = callback(deh_str.DEH_String("WICOLON"))

    -- "time".
    timepatch = callback(deh_str.DEH_String("WITIME"))

    -- "sucks".
    sucks = callback(deh_str.DEH_String("WISUCKS"))

    -- "par".
    par = callback(deh_str.DEH_String("WIPAR"))

    -- "killers" (vertical).
    killers = callback(deh_str.DEH_String("WIKILRS"))

    -- "victims" (horiz).
    victims = callback(deh_str.DEH_String("WIVCTMS"))

    -- "total".
    total = callback(deh_str.DEH_String("WIMSTT"))

    for i = 0, doomtype.MAXPLAYERS - 1 do
        -- "1,2,3,4".
        name = deh_str.DEH_snprintf("STPB%d", i)
        p[i + 1] = callback(name)

        -- "1,2,3,4".
        name = deh_str.DEH_snprintf("WIBP%d", i + 1)
        bp[i + 1] = callback(name)
    end

    -- Background image.
    if doomstat.gamemode == d_mode.commercial then
        name = deh_str.DEH_String("INTERPIC")
    elseif doomstat.gamemode == d_mode.retail and wbs.epsd == 3 then
        name = deh_str.DEH_String("INTERPIC")
    else
        name = deh_str.DEH_snprintf("WIMAP%d", wbs.epsd)
    end

    -- Draw backdrop and save to a temporary buffer.
    background = callback(name)
end

function wi_stuff.WI_loadData()
    if doomstat.gamemode == d_mode.commercial then
        NUMCMAPS = 32
        lnames = {}
        for _ = 1, NUMCMAPS do
            table.insert(lnames, nil)
        end
    else
        lnames = {}
        for _ = 1, NUMMAPS do
            table.insert(lnames, nil)
        end
    end

    WI_loadUnloadData(WI_loadCallback)

    -- These two graphics are special cased because we're sharing them with
    -- the status bar code.

    -- Your face.
    star = w_wad.W_CacheLumpName(deh_str.DEH_String("STFST01"), z_zone.PU_STATIC)

    -- Dead face.
    bstar = w_wad.W_CacheLumpName(deh_str.DEH_String("STFDEAD0"), z_zone.PU_STATIC)
end

function wi_stuff.WI_unloadData()
    WI_loadUnloadData(WI_unloadCallback)

    -- We do not free these lumps as they are shared with the status bar code.
end

-- ---------------------------------------------------------------------------
-- WI_Drawer
-- ---------------------------------------------------------------------------

function wi_stuff.WI_Drawer()
    if state == StatCount then
        if doomstat.deathmatch ~= 0 then
            WI_drawDeathmatchStats()
        elseif doomstat.netgame then
            WI_drawNetgameStats()
        else
            WI_drawStats()
        end
    elseif state == ShowNextLoc then
        WI_drawShowNextLoc()
    elseif state == NoState then
        WI_drawNoState()
    end
end

-- ---------------------------------------------------------------------------
-- WI_initVariables
-- ---------------------------------------------------------------------------

local function WI_initVariables(wbstartstruct)
    wbs = wbstartstruct

    acceleratestage = 0
    cnt = 0
    bcnt = 0
    firstrefresh = 1
    me = wbs.pnum
    plrs = wbs.plyr

    if not wbs.maxkills then
        wbs.maxkills = 1
    end
    if not wbs.maxitems then
        wbs.maxitems = 1
    end
    if not wbs.maxsecret then
        wbs.maxsecret = 1
    end

    -- (RANGECHECKING is not ported.)
    if doomstat.gamemode ~= d_mode.retail then
        if wbs.epsd > 2 then
            wbs.epsd = wbs.epsd - 3
        end
    end
end

function wi_stuff.WI_Start(wbstartstruct)
    WI_initVariables(wbstartstruct)
    wi_stuff.WI_loadData()

    if doomstat.deathmatch ~= 0 then
        WI_initDeathmatchStats()
    elseif doomstat.netgame then
        WI_initNetgameStats()
    else
        WI_initStats()
    end
end

return wi_stuff
end)()

d_main = (function() 
local d_main = {}

-- ---------------------------------------------------------------------------
-- Globals (d_main.c)
-- ---------------------------------------------------------------------------

-- If true, the main game loop has started.
d_main.main_loop_started = false

d_main.iwadfile = "iwad"     -- the SetWAD-provided IWAD (no filesystem)
d_main.savegamedir = ""

d_main.wadfile = ""          -- primary wad file (unused in port)
d_main.mapdir = ""           -- directory of development maps
d_main.show_endoom = 1

-- Store demo, do not accept any inputs.
d_main.storedemo = false

-- ---------------------------------------------------------------------------
-- D_ProcessEvents: send all the events of the given timestamp down the
-- responder chain. (Menu / game responders are Phase 4 stubs, so events are
-- drained and dropped in Phase 2.)
-- ---------------------------------------------------------------------------

function d_main.D_ProcessEvents()
    if d_main.storedemo then
        return
    end

    while true do
        local ev = d_event.D_PopEvent()
        if ev == nil then
            break
        end
        if m_menu.M_Responder(ev) then
            -- menu ate the event
        else
            g_game.G_Responder(ev)
        end
    end
end

-- ---------------------------------------------------------------------------
-- D_Display: draw the current display. Phase 3 wires the software renderer
-- (R_ExecuteSetViewSize / R_RenderPlayerView / R_FillBackScreen /
-- R_DrawViewBorder); the HUD / status bar / automap / menus are Phase 4.
-- ---------------------------------------------------------------------------

local display_oldgamestate = -1

-- C statics in D_Display.
local viewactivestate = false
local menuactivestate = false
local inhelpscreensstate = false
local fullscreen = false
local borderdrawcount = 0

function d_main.D_Display()
    local SCREENWIDTH = 320
    local SCREENHEIGHT = 200

    if doomstat.nodrawers then
        return -- for comparative timing / profiling
    end

    local redrawsbar = false

    -- Change the view size if needed.
    if r_state.setsizeneeded then
        r_main.R_ExecuteSetViewSize()
        display_oldgamestate = -1 -- force background redraw
        borderdrawcount = 3
    end

    -- Save the current screen if about to wipe.
    local wipe
    if doomstat.gamestate ~= doomstat.wipegamestate then
        wipe = true
        f_wipe.wipe_StartScreen(0, 0, SCREENWIDTH, SCREENHEIGHT)
    else
        wipe = false
    end

    if doomstat.gamestate == doomdef.GS_LEVEL and d_loop.gametic ~= 0 then
        hu_stuff.HU_Erase()
    end

    -- Do buffered drawing.
    if doomstat.gamestate == doomdef.GS_LEVEL then
        if d_loop.gametic ~= 0 then
            if doomstat.automapactive then
                am_map.AM_Drawer()
            end
            if wipe or (r_state.viewheight ~= 200 and fullscreen) then
                redrawsbar = true
            end
            if inhelpscreensstate and not m_menu.inhelpscreens then
                redrawsbar = true -- just put away the help screen
            end
            st_stuff.ST_Drawer(r_state.viewheight == 200, redrawsbar)
            fullscreen = r_state.viewheight == 200
        end
    elseif doomstat.gamestate == doomdef.GS_INTERMISSION then
        wi_stuff.WI_Drawer()
    elseif doomstat.gamestate == doomdef.GS_FINALE then
        f_finale.F_Drawer()
    elseif doomstat.gamestate == doomdef.GS_DEMOSCREEN then
        d_main.D_PageDrawer()
    end

    -- Draw buffered stuff to screen.
    i_video.I_UpdateNoBlit()

    -- Draw the view directly.
    if doomstat.gamestate == doomdef.GS_LEVEL
        and not doomstat.automapactive
        and d_loop.gametic ~= 0 then
        local player = doomstat.players[doomstat.displayplayer + 1]
        if player ~= nil and player.mo ~= nil then
            r_main.R_RenderPlayerView(player)
        end
    end

    if doomstat.gamestate == doomdef.GS_LEVEL and d_loop.gametic ~= 0 then
        hu_stuff.HU_Drawer()
    end

    -- Clean up border stuff: set the palette when the gamestate changes to
    -- a non-level state (so the title screens use the correct palette).
    if doomstat.gamestate ~= display_oldgamestate
        and doomstat.gamestate ~= doomdef.GS_LEVEL then
        local playpal = w_wad.W_CacheLumpName(deh_str.DEH_String("PLAYPAL"), z_zone.PU_CACHE)
        i_video.I_SetPalette(playpal.buffer, playpal.offset)
    end

    -- See if the border needs to be initially drawn.
    if doomstat.gamestate == doomdef.GS_LEVEL
        and display_oldgamestate ~= doomdef.GS_LEVEL then
        viewactivestate = false -- view was not active
        r_draw.R_FillBackScreen() -- draw the pattern into the back screen
    end

    -- See if the border needs to be updated to the screen.
    if doomstat.gamestate == doomdef.GS_LEVEL
        and not doomstat.automapactive
        and r_state.scaledviewwidth ~= 320 then
        if doomstat.menuactive or menuactivestate or not viewactivestate then
            borderdrawcount = 3
        end
        if borderdrawcount > 0 then
            r_draw.R_DrawViewBorder() -- erase old menu stuff
            borderdrawcount = borderdrawcount - 1
        end
    end

    if doomstat.testcontrols then
        -- Box showing current mouse speed.
        v_video.V_DrawMouseSpeedBox(doomstat.testcontrols_mousespeed)
    end

    menuactivestate = doomstat.menuactive
    viewactivestate = doomstat.viewactive
    inhelpscreensstate = m_menu.inhelpscreens
    display_oldgamestate = doomstat.gamestate
    doomstat.wipegamestate = doomstat.gamestate

    -- Draw pause pic.
    if doomstat.paused then
        local y
        if doomstat.automapactive then
            y = 4
        else
            y = r_state.viewwindowy + 4
        end
        v_video.V_DrawPatchDirect(
            r_state.viewwindowx + (r_state.scaledviewwidth - 68) // 2, y,
            w_wad.W_CacheLumpName(deh_str.DEH_String("M_PAUSE"), z_zone.PU_CACHE))
    end

    -- Menus go directly to the screen.
    m_menu.M_Drawer() -- menu is drawn even on top of everything
    d_loop.NetUpdate() -- send out any new accumulation

    -- Normal update.
    if not wipe then
        i_video.I_FinishUpdate() -- page flip or blit buffer
        return
    end

    -- Wipe update.
    f_wipe.wipe_EndScreen(0, 0, SCREENWIDTH, SCREENHEIGHT)

    local wipestart = i_timer.I_GetTime() - 1

    while true do
        local nowtime
        local tics
        repeat
            nowtime = i_timer.I_GetTime()
            tics = nowtime - wipestart
            i_timer.I_Sleep(1)
        until tics > 0

        wipestart = nowtime
        local done = f_wipe.wipe_ScreenWipe(f_wipe.wipe_Melt,
            0, 0, SCREENWIDTH, SCREENHEIGHT, tics)
        i_video.I_UpdateNoBlit()
        m_menu.M_Drawer() -- menu is drawn even on top of wipes
        i_video.I_FinishUpdate() -- page flip or blit buffer
        if done ~= 0 then
            break
        end
    end
end

-- ---------------------------------------------------------------------------
-- D_BindVariables: add configuration file variable bindings.
-- ---------------------------------------------------------------------------

function d_main.D_BindVariables()
    m_controls.M_ApplyPlatformDefaults()

    i_video.I_BindVideoVariables()
    -- i_joystick / i_sound variable bindings: deferred (v1).

    m_controls.M_BindBaseControls()
    m_controls.M_BindWeaponControls()
    m_controls.M_BindMapControls()
    m_controls.M_BindMenuControls()
    m_controls.M_BindChatControls(doomtype.MAXPLAYERS)

    -- Multiplayer chat macros (deferred).
    m_config.M_BindVariable("mouse_sensitivity", doomstat, "mouseSensitivity", m_config.DEFAULT_INT)
    m_config.M_BindVariable("sfx_volume", doomstat, "sfxVolume", m_config.DEFAULT_INT)
    m_config.M_BindVariable("music_volume", doomstat, "musicVolume", m_config.DEFAULT_INT)
    m_config.M_BindVariable("show_messages", doomstat, "showMessages", m_config.DEFAULT_INT)
    m_config.M_BindVariable("screenblocks", doomstat, "screenblocks", m_config.DEFAULT_INT)
    m_config.M_BindVariable("detaillevel", doomstat, "detailLevel", m_config.DEFAULT_INT)
    m_config.M_BindVariable("snd_channels", doomstat, "snd_channels", m_config.DEFAULT_INT)
    m_config.M_BindVariable("vanilla_savegame_limit", doomstat, "vanilla_savegame_limit", m_config.DEFAULT_INT)
    m_config.M_BindVariable("vanilla_demo_limit", doomstat, "vanilla_demo_limit", m_config.DEFAULT_INT)
    m_config.M_BindVariable("show_endoom", d_main, "show_endoom", m_config.DEFAULT_INT)
    -- Mouse options (i_video.c); used by V_DrawMouseSpeedBox.
    m_config.M_BindVariable("usemouse", i_video, "usemouse", m_config.DEFAULT_INT)
    m_config.M_BindVariable("mouse_acceleration", i_video, "mouse_acceleration", m_config.DEFAULT_FLOAT)
    m_config.M_BindVariable("mouse_threshold", i_video, "mouse_threshold", m_config.DEFAULT_INT)
end

-- D_GrabMouseCallback: determines whether to grab the mouse pointer
-- (Phase 4: used by i_video; stub for now).
function d_main.D_GrabMouseCallback()
    return doomstat.gamestate == doomdef.GS_LEVEL
        and not doomstat.demoplayback
        and not d_main.advancedemo
        and not doomstat.menuactive
        and not doomstat.paused
end

-- ---------------------------------------------------------------------------
-- doomgeneric_Tick: frame-synchronous main loop, called by DoomGeneric.Tick.
-- ---------------------------------------------------------------------------

function d_main.doomgeneric_Tick()
    i_video.I_StartFrame()

    d_loop.TryRunTics() -- will run at least one tic

    s_sound.S_UpdateSounds(nil) -- Phase 6: positional sounds

    -- Update display, next frame, with current state.
    if i_video.screenvisible then
        d_main.D_Display()
    end
end

-- ---------------------------------------------------------------------------
-- D_DoomLoop: the main loop (called at the end of D_DoomMain; the host then
-- calls doomgeneric_Tick each frame).
-- ---------------------------------------------------------------------------

function d_main.D_DoomLoop()
    -- Phase 4: if bfgedition && (demorecording || ga_playdemo || netgame) warn.
    -- Phase 4: if demorecording then G_BeginRecording().

    d_main.main_loop_started = true

    d_loop.TryRunTics()

    i_video.I_SetWindowTitle(doomstat.gamedescription)
    i_video.I_GraphicsCheckCommandLine()
    i_video.I_SetGrabMouseCallback(d_main.D_GrabMouseCallback)
    i_video.I_InitGraphics()
    i_video.I_EnableLoadingDisk()

    v_video.V_RestoreBuffer()
    r_main.R_ExecuteSetViewSize()

    d_loop.D_StartGameLoop()

    if doomstat.testcontrols then
        doomstat.wipegamestate = doomstat.gamestate
    end

    d_main.doomgeneric_Tick()
end

-- ---------------------------------------------------------------------------
-- Demo loop (title screens / intro demos)
-- ---------------------------------------------------------------------------

d_main.demosequence = 0
d_main.pagetic = 0
d_main.pagename = "TITLEPIC"
d_main.advancedemo = false

-- D_PageTicker: handles timing for the warped projection.
function d_main.D_PageTicker()
    d_main.pagetic = d_main.pagetic - 1
    if d_main.pagetic < 0 then
        d_main.D_AdvanceDemo()
    end
end

-- D_PageDrawer.
function d_main.D_PageDrawer()
    v_video.V_DrawPatch(0, 0,
        w_wad.W_CacheLumpName(d_main.pagename, z_zone.PU_CACHE))
end

-- D_AdvanceDemo: called after each demo or intro demosequence finishes.
function d_main.D_AdvanceDemo()
    d_main.advancedemo = true
end

-- D_DoAdvanceDemo: cycles through the demo sequences.
function d_main.D_DoAdvanceDemo()
    local players = doomstat.players
    if players[doomstat.consoleplayer + 1] ~= nil then
        players[doomstat.consoleplayer + 1].playerstate = 0 -- PST_LIVE; not reborn
    end
    d_main.advancedemo = false
    doomstat.usergame = false -- no save / end game here
    doomstat.paused = false
    g_game.paused = false
    g_game.gameaction = doomdef.ga_nothing

    -- The Ultimate Doom executable changed the demo sequence to add a DEMO4
    -- demo; Final Doom was based on Ultimate, so also includes this change.
    if doomstat.gameversion == d_mode.exe_ultimate
        or doomstat.gameversion == d_mode.exe_final then
        d_main.demosequence = (d_main.demosequence + 1) % 7
    else
        d_main.demosequence = (d_main.demosequence + 1) % 6
    end

    local gamemode = doomstat.gamemode
    if d_main.demosequence == 0 then
        if gamemode == d_mode.commercial then
            d_main.pagetic = doomtype.TICRATE * 11
        else
            d_main.pagetic = 170
        end
        doomstat.gamestate = doomdef.GS_DEMOSCREEN
        d_main.pagename = "TITLEPIC"
        if gamemode == d_mode.commercial then
            s_sound.S_StartMusic(0) -- mus_dm2ttl
        else
            s_sound.S_StartMusic(1) -- mus_intro
        end
    elseif d_main.demosequence == 1 then
        g_game.G_DeferedPlayDemo("demo1")
    elseif d_main.demosequence == 2 then
        d_main.pagetic = 200
        doomstat.gamestate = doomdef.GS_DEMOSCREEN
        d_main.pagename = "CREDIT"
    elseif d_main.demosequence == 3 then
        g_game.G_DeferedPlayDemo("demo2")
    elseif d_main.demosequence == 4 then
        doomstat.gamestate = doomdef.GS_DEMOSCREEN
        if gamemode == d_mode.commercial then
            d_main.pagetic = doomtype.TICRATE * 11
            d_main.pagename = "TITLEPIC"
            s_sound.S_StartMusic(0) -- mus_dm2ttl
        else
            d_main.pagetic = 200
            if gamemode == d_mode.retail then
                d_main.pagename = "CREDIT"
            else
                d_main.pagename = "HELP2"
            end
        end
    elseif d_main.demosequence == 5 then
        g_game.G_DeferedPlayDemo("demo3")
    else -- THE DEFINITIVE DOOM Special Edition demo
        g_game.G_DeferedPlayDemo("demo4")
    end

    -- The Doom 3: BFG Edition version of doom2.wad does not have a TITLEPIC
    -- lump. Use INTERPIC instead as a workaround.
    if doomstat.bfgedition
        and d_main.pagename == "TITLEPIC"
        and w_wad.W_CheckNumForName("titlepic") < 0 then
        d_main.pagename = "INTERPIC"
    end
end

-- D_StartTitle.
function d_main.D_StartTitle()
    g_game.gameaction = doomdef.ga_nothing
    d_main.demosequence = -1
    d_main.D_AdvanceDemo()
end

-- ---------------------------------------------------------------------------
-- Game identification
-- ---------------------------------------------------------------------------

-- logical_gamemission: gamemission with pack_chex/pack_hacx folded back to
-- doom/doom2 (doomstat.h macro).
local function logical_gamemission()
    if doomstat.gamemission == d_mode.pack_chex then
        return d_mode.doom
    elseif doomstat.gamemission == d_mode.pack_hacx then
        return d_mode.doom2
    end
    return doomstat.gamemission
end

-- SetMissionForPackName.
local function SetMissionForPackName(pack_name)
    local packs = {
        { name = "doom2",    mission = d_mode.doom2 },
        { name = "tnt",      mission = d_mode.pack_tnt },
        { name = "plutonia", mission = d_mode.pack_plut },
    }
    for _, p in ipairs(packs) do
        if string.lower(pack_name) == p.name then
            doomstat.gamemission = p.mission
            return
        end
    end

    print("Valid mission packs are:")
    for _, p in ipairs(packs) do
        print("\t" .. p.name)
    end
    i_system.I_Error("Unknown mission pack name: %s", pack_name)
end

-- D_IdentifyVersion: find out what version of Doom is playing. In this port
-- the IWAD is identified by lump contents (no filesystem / -iwad search).
function d_main.D_IdentifyVersion()
    -- gamemission is set up by D_FindIWAD. In the port D_FindIWAD leaves it
    -- as 'none' (no filename to identify by), so identify by contents.
    if doomstat.gamemission == d_mode.none then
        -- The C scans lumpinfo[i].name for "MAP01"/"E1M1"; the port uses the
        -- WAD hash-table lookup (W_CheckNumForName), which is equivalent.
        if w_wad.W_CheckNumForName("MAP01") >= 0 then
            doomstat.gamemission = d_mode.doom2
        elseif w_wad.W_CheckNumForName("E1M1") >= 0 then
            doomstat.gamemission = d_mode.doom
        end

        if doomstat.gamemission == d_mode.none then
            -- Still no idea. I don't think this is going to work.
            i_system.I_Error("Unknown or invalid IWAD file.")
        end
    end

    -- Make sure gamemode is set up correctly.
    if logical_gamemission() == d_mode.doom then
        -- Doom 1. But which version?
        if w_wad.W_CheckNumForName("E4M1") > 0 then
            -- Ultimate Doom.
            doomstat.gamemode = d_mode.retail
        elseif w_wad.W_CheckNumForName("E3M1") > 0 then
            doomstat.gamemode = d_mode.registered
        else
            doomstat.gamemode = d_mode.shareware
        end
    else
        -- Doom 2 of some kind.
        doomstat.gamemode = d_mode.commercial

        -- We can manually override the gamemission with -pack.
        local p = m_argv.M_CheckParmWithArgs("-pack", 1)
        if p > 0 then
            SetMissionForPackName(m_argv.myargv[p + 1])
        end
    end
end

-- D_SetGameDescription.
function d_main.D_SetGameDescription()
    local is_freedoom = w_wad.W_CheckNumForName("FREEDOOM") >= 0
    local is_freedm = w_wad.W_CheckNumForName("FREEDM") >= 0

    doomstat.gamedescription = "Unknown"

    if logical_gamemission() == d_mode.doom then
        -- Doom 1. But which version?
        if is_freedoom then
            doomstat.gamedescription = "Freedoom: Phase 1"
        elseif doomstat.gamemode == d_mode.retail then
            doomstat.gamedescription = "The Ultimate DOOM"
        elseif doomstat.gamemode == d_mode.registered then
            doomstat.gamedescription = "DOOM Registered"
        elseif doomstat.gamemode == d_mode.shareware then
            doomstat.gamedescription = "DOOM Shareware"
        end
    else
        -- Doom 2 of some kind. But which mission?
        if is_freedoom then
            if is_freedm then
                doomstat.gamedescription = "FreeDM"
            else
                doomstat.gamedescription = "Freedoom: Phase 2"
            end
        elseif logical_gamemission() == d_mode.doom2 then
            doomstat.gamedescription = "DOOM 2: Hell on Earth"
        elseif logical_gamemission() == d_mode.pack_plut then
            doomstat.gamedescription = "DOOM 2: Plutonia Experiment"
        elseif logical_gamemission() == d_mode.pack_tnt then
            doomstat.gamedescription = "DOOM 2: TNT - Evilution"
        end
    end
end

-- PrintDehackedBanners: prints a message only if it has been modified by
-- dehacked. DeHacked is disabled in v1, so this prints nothing.
function d_main.PrintDehackedBanners()
end

-- Game versions table (d_main.c gameversions[]).
local gameversions = {
    { description = "Doom 1.666",          cmdline = "1.666",    version = d_mode.exe_doom_1_666 },
    { description = "Doom 1.7/1.7a",       cmdline = "1.7",      version = d_mode.exe_doom_1_7 },
    { description = "Doom 1.8",            cmdline = "1.8",      version = d_mode.exe_doom_1_8 },
    { description = "Doom 1.9",            cmdline = "1.9",      version = d_mode.exe_doom_1_9 },
    { description = "Hacx",                cmdline = "hacx",     version = d_mode.exe_hacx },
    { description = "Ultimate Doom",       cmdline = "ultimate", version = d_mode.exe_ultimate },
    { description = "Final Doom",          cmdline = "final",    version = d_mode.exe_final },
    { description = "Final Doom (alt)",    cmdline = "final2",   version = d_mode.exe_final2 },
    { description = "Chex Quest",          cmdline = "chex",     version = d_mode.exe_chex },
}

-- InitGameVersion: initialize the game version.
local function InitGameVersion()
    local p = m_argv.M_CheckParmWithArgs("-gameversion", 1)

    if p ~= 0 then
        local found = false
        for _, gv in ipairs(gameversions) do
            if m_argv.myargv[p + 1] == gv.cmdline then
                doomstat.gameversion = gv.version
                found = true
                break
            end
        end

        if not found then
            print("Supported game versions:")
            for _, gv in ipairs(gameversions) do
                print(string.format("\t%s (%s)", gv.cmdline, gv.description))
            end
            i_system.I_Error("Unknown game version '%s'", m_argv.myargv[p + 1])
        end
    else
        -- Determine automatically.
        if doomstat.gamemission == d_mode.pack_chex then
            doomstat.gameversion = d_mode.exe_chex
        elseif doomstat.gamemission == d_mode.pack_hacx then
            doomstat.gameversion = d_mode.exe_hacx
        elseif doomstat.gamemode == d_mode.shareware
            or doomstat.gamemode == d_mode.registered then
            doomstat.gameversion = d_mode.exe_doom_1_9
        elseif doomstat.gamemode == d_mode.retail then
            doomstat.gameversion = d_mode.exe_ultimate
        elseif doomstat.gamemode == d_mode.commercial then
            if doomstat.gamemission == d_mode.doom2 then
                doomstat.gameversion = d_mode.exe_doom_1_9
            else
                doomstat.gameversion = d_mode.exe_final
            end
        end
    end

    -- The original exe does not support retail (4th episode).
    if doomstat.gameversion < d_mode.exe_ultimate
        and doomstat.gamemode == d_mode.retail then
        doomstat.gamemode = d_mode.registered
    end

    -- EXEs prior to the Final Doom exes do not support Final Doom.
    if doomstat.gameversion < d_mode.exe_final
        and doomstat.gamemode == d_mode.commercial
        and (doomstat.gamemission == d_mode.pack_tnt
            or doomstat.gamemission == d_mode.pack_plut) then
        doomstat.gamemission = d_mode.doom2
    end
end

-- PrintGameVersion.
local function PrintGameVersion()
    for _, gv in ipairs(gameversions) do
        if gv.version == doomstat.gameversion then
            print(string.format("Emulating the behavior of the '%s' executable.",
                gv.description))
            break
        end
    end
end

-- D_Endoom: displays the ENDOOM screen at exit. i_endoom is cut in v1, so
-- this is a no-op (kept for the I_AtExit registration).
function d_main.D_Endoom()
end

-- ---------------------------------------------------------------------------
-- D_DoomMain: startup sequence.
-- ---------------------------------------------------------------------------

function d_main.D_DoomMain()
    i_system.I_AtExit(d_main.D_Endoom, false)

    -- Print banner.
    i_system.I_PrintBanner("Doom Generic 0.1") -- PACKAGE_STRING

    print("Z_Init: Init zone memory allocation daemon.")
    z_zone.Z_Init()

    -- The host must supply the IWAD via DoomGeneric.SetWAD before Create.
    if w_wad.W_NumLumps() == 0 then
        i_system.I_Error(
            "DoomGeneric: no WAD loaded; call DoomGeneric.SetWAD(wadBuffer) before Create")
    end

    --!
    -- Disable monsters.
    doomstat.nomonsters = m_argv.M_CheckParm("-nomonsters") ~= 0

    --!
    -- Monsters respawn after being killed.
    doomstat.respawnparm = m_argv.M_CheckParm("-respawn") ~= 0

    --!
    -- Monsters move faster.
    doomstat.fastparm = m_argv.M_CheckParm("-fast") ~= 0

    --!
    -- Developer mode.
    doomstat.devparm = m_argv.M_CheckParm("-devparm") ~= 0

    i_video.I_DisplayFPSDots(doomstat.devparm)

    --!
    -- Start a deathmatch game.
    if m_argv.M_CheckParm("-deathmatch") ~= 0 then
        doomstat.deathmatch = 1
    end

    --!
    -- Start a deathmatch 2.0 game.
    if m_argv.M_CheckParm("-altdeath") ~= 0 then
        doomstat.deathmatch = 2
    end

    if doomstat.devparm then
        print("Development mode ON.") -- D_DEVSTR
    end

    -- Find which dir to use for config files (no filesystem in v1).
    m_config.M_SetConfigDir(nil)

    --!
    -- Turbo mode: the player's speed is multiplied by x%.
    local p = m_argv.M_CheckParm("-turbo")
    if p ~= 0 then
        local scale = 200
        if p < m_argv.myargc - 1 then
            scale = tonumber(m_argv.myargv[p + 1]) or 200
        end
        if scale < 10 then
            scale = 10
        end
        if scale > 400 then
            scale = 400
        end
        print(string.format("turbo scale: %i%%", scale))
        -- Scale the movement arrays (C d_main.c: forwardmove/sidemove).
        -- C integer division truncates toward zero; values are positive,
        -- so `//` (floor) matches.
        for i = 1, 2 do
            g_game.forwardmove[i] = g_game.forwardmove[i] * scale // 100
            g_game.sidemove[i] = g_game.sidemove[i] * scale // 100
        end
    end

    -- Init subsystems.
    print("V_Init: allocate screens.")
    v_video.V_Init()

    -- Load configuration files before initialising other subsystems.
    print("M_LoadDefaults: Load system defaults.")
    m_config.M_SetConfigFilenames("default.cfg", "doom.cfg")
    d_main.D_BindVariables()
    m_config.M_LoadDefaults()

    -- Save configuration at exit.
    i_system.I_AtExit(m_config.M_SaveDefaults, false)

    -- Find main IWAD file and load it. In this port the IWAD is already
    -- loaded by DoomGeneric.SetWAD; D_FindIWAD acknowledges it.
    d_main.iwadfile = d_iwad.D_FindIWAD(d_iwad.IWAD_MASK_DOOM, nil)

    doomstat.modifiedgame = false

    print("W_Init: Init WADfiles.")
    -- D_AddFile(iwadfile) is a no-op: the WAD is already in memory.

    w_wad.W_CheckCorrectIWAD(d_mode.doom)

    -- Now that we've loaded the IWAD, we can figure out what gamemission
    -- we're playing and which version of Vanilla Doom we need to emulate.
    d_main.D_IdentifyVersion()
    InitGameVersion()

    -- Doom 3: BFG Edition includes modified IWADs identifiable by an
    -- additional DMENUPIC lump.
    if w_wad.W_CheckNumForName("dmenupic") >= 0 then
        print("BFG Edition: Using workarounds as needed.")
        doomstat.bfgedition = true

        -- BFG Edition changes secret level names (DEH_AddStringReplacement
        -- calls are no-ops in v1) and reuses M_GDHIGH (workaround noted in
        -- the C source; the menu graphics are Phase 4).
    end

    -- Load PWAD files: deferred (v1).
    -- W_ParseCommandLine() is a no-op; modifiedgame stays false.

    --!
    -- Play back the demo named demo.lmp. (Recording/playback is Phase 4;
    -- here we only parse the parameter and record the name.)
    p = m_argv.M_CheckParmWithArgs("-playdemo", 1)
    if p == 0 then
        p = m_argv.M_CheckParmWithArgs("-timedemo", 1)
    end

    local demolumpname = nil
    if p ~= 0 then
        -- With Vanilla you have to specify the file without extension, but
        -- make that optional.
        local file
        if m_misc.M_StringEndsWith(m_argv.myargv[p + 1], ".lmp") then
            file = m_argv.myargv[p + 1]
        else
            file = string.format("%s.lmp", m_argv.myargv[p + 1])
        end

        -- D_AddFile(file) would load the demo lump from disk; in this port
        -- there is no filesystem, so "-playdemo demo1" uses the built-in
        -- demo lumps. Strip a trailing .lmp so "demo1.lmp" also resolves.
        demolumpname = m_argv.myargv[p + 1]
        if m_misc.M_StringEndsWith(demolumpname, ".lmp") then
            demolumpname = string.sub(demolumpname, 1, #demolumpname - 4)
        end

        print(string.format("Playing demo %s.", file))
    end

    i_system.I_AtExit(g_game.G_CheckDemoStatus, true)

    -- Generate the WAD hash table.
    w_wad.W_GenerateHashTable()

    -- Set the gamedescription string.
    d_main.D_SetGameDescription()

    -- Savegame directory (no filesystem in v1; returns "").
    d_main.savegamedir = m_config.M_GetSaveGameDir(
        d_iwad.D_SaveGameIWADName(doomstat.gamemission))

    -- Check for -file in shareware: PWADs deferred, so modifiedgame is false
    -- and these checks are skipped.

    if w_wad.W_CheckNumForName("SS_START") >= 0
        or w_wad.W_CheckNumForName("FF_END") >= 0 then
        i_system.I_PrintDivider()
        print(" WARNING: The loaded WAD file contains modified sprites or")
        print(" floor textures.  You may want to use the '-merge' command")
        print(" line option instead of '-file'.")
    end

    i_system.I_PrintStartupBanner(doomstat.gamedescription)
    d_main.PrintDehackedBanners()

    -- Freedoom's IWADs are Boom-compatible, which usually don't work in
    -- Vanilla (though FreeDM is okay).
    if w_wad.W_CheckNumForName("FREEDOOM") >= 0
        and w_wad.W_CheckNumForName("FREEDM") < 0 then
        print(" WARNING: You are playing using one of the Freedoom IWAD")
        print(" files, which might not work in this port. See this page")
        print(" for more information on how to play using Freedoom:")
        print("   http://www.chocolate-doom.org/wiki/index.php/Freedoom")
        i_system.I_PrintDivider()
    end

    print("I_Init: Setting up machine state.")
    i_video.I_CheckIsScreensaver()
    i_timer.I_InitTimer()
    -- I_InitJoystick / I_InitSound(true) / I_InitMusic: deferred (v1).

    -- Initial netgame startup. Multiplayer is cut; single-player only.
    d_net.D_ConnectNetGame()

    -- Get skill / episode / map from parms.
    doomstat.startskill = d_mode.sk_medium
    doomstat.startepisode = 1
    doomstat.startmap = 1
    doomstat.autostart = false

    --!
    -- Set the game skill, 1-5 (0 disables all monsters).
    p = m_argv.M_CheckParmWithArgs("-skill", 1)
    if p ~= 0 then
        doomstat.startskill = string.byte(m_argv.myargv[p + 1]) - string.byte("1")
        doomstat.autostart = true
    end

    --!
    -- Start playing on episode n (1-4).
    p = m_argv.M_CheckParmWithArgs("-episode", 1)
    if p ~= 0 then
        doomstat.startepisode = string.byte(m_argv.myargv[p + 1]) - string.byte("0")
        doomstat.startmap = 1
        doomstat.autostart = true
    end

    doomstat.timelimit = 0

    --!
    -- For multiplayer games: exit each level after n minutes.
    p = m_argv.M_CheckParmWithArgs("-timer", 1)
    if p ~= 0 then
        doomstat.timelimit = tonumber(m_argv.myargv[p + 1]) or 0
    end

    --!
    -- Austin Virtual Gaming: end levels after 20 minutes.
    p = m_argv.M_CheckParm("-avg")
    if p ~= 0 then
        doomstat.timelimit = 20
    end

    --!
    -- Start a game immediately, warping to ExMy (Doom 1) or MAPxy (Doom 2).
    p = m_argv.M_CheckParmWithArgs("-warp", 1)
    if p ~= 0 then
        if doomstat.gamemode == d_mode.commercial then
            doomstat.startmap = tonumber(m_argv.myargv[p + 1]) or 1
        else
            doomstat.startepisode = string.byte(m_argv.myargv[p + 1]) - string.byte("0")
            if p + 2 < m_argv.myargc then
                doomstat.startmap = string.byte(m_argv.myargv[p + 2]) - string.byte("0")
            else
                doomstat.startmap = 1
            end
        end
        doomstat.autostart = true
    end

    -- Undocumented: invoked by setup to test the controls.
    p = m_argv.M_CheckParm("-testcontrols")
    if p > 0 then
        doomstat.startepisode = 1
        doomstat.startmap = 1
        doomstat.autostart = true
        doomstat.testcontrols = true
    end

    -- Check for load game parameter.
    p = m_argv.M_CheckParmWithArgs("-loadgame", 1)
    if p ~= 0 then
        doomstat.startloadgame = tonumber(m_argv.myargv[p + 1]) or 0
    else
        doomstat.startloadgame = -1
    end

    print("M_Init: Init miscellaneous info.")
    m_menu.M_Init()

    print("R_Init: Init DOOM refresh daemon - ")
    r_main.R_Init()

    print("\nP_Init: Init Playloop state.")
    p_setup.P_Init()

    print("S_Init: Setting up sound.")
    s_sound.S_Init(doomstat.sfxVolume * 8, doomstat.musicVolume * 8)

    print("D_CheckNetGame: Checking network game status.")
    d_net.D_CheckNetGame()

    PrintGameVersion()

    print("HU_Init: Setting up heads up display.")
    hu_stuff.HU_Init()

    print("ST_Init: Init status bar.")
    st_stuff.ST_Init()

    -- If Doom II without a MAP01 lump, this is a store demo.
    if doomstat.gamemode == d_mode.commercial
        and w_wad.W_CheckNumForName("map01") < 0 then
        d_main.storedemo = true
    end

    -- -record: deferred (Phase 4).

    p = m_argv.M_CheckParmWithArgs("-playdemo", 1)
    if p ~= 0 then
        doomstat.singledemo = true -- quit after one demo
        g_game.G_DeferedPlayDemo(demolumpname)
        d_main.D_DoomLoop()
        return
    end

    p = m_argv.M_CheckParmWithArgs("-timedemo", 1)
    if p ~= 0 then
        g_game.G_TimeDemo(demolumpname)
        d_main.D_DoomLoop()
        return
    end

    if doomstat.startloadgame >= 0 then
        -- G_LoadGame: deferred (Phase 4).
    end

    if g_game.gameaction ~= doomdef.ga_loadgame then
        if doomstat.autostart or doomstat.netgame then
            g_game.G_InitNew(doomstat.startskill, doomstat.startepisode,
                doomstat.startmap)
        else
            d_main.D_StartTitle() -- start up intro loop
        end
    end

    d_main.D_DoomLoop()
end

return d_main
end)()

return {platform = platform, doomgeneric = doomgeneric, doomtype = doomtype}