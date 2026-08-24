--!native
--!optimize 2
local doomdef = require("./doomdef")
local d_mode = require("./d_mode")
local doomstat = {}

-- ------------------------
-- Command line parameters.
-- ------------------------

doomstat.nomonsters = false      -- checkparm of -nomonsters
doomstat.respawnparm = false     -- checkparm of -respawn
doomstat.fastparm = false        -- checkparm of -fast
doomstat.devparm = false         -- launched with -devparm

-- -----------------------------------------------------
-- Game Mode - identify IWAD as shareware, retail etc.
-- -----------------------------------------------------

doomstat.gamemode = d_mode.indetermined
doomstat.gamemission = d_mode.none
doomstat.gameversion = d_mode.exe_doom_1_9
doomstat.gamedescription = "Unknown"

-- If true, we're using one of the mangled BFG edition IWADs.
doomstat.bfgedition = false

-- Set if homebrew PWAD stuff has been added.
doomstat.modifiedgame = false

-- -------------------------------------------
-- Selected skill type, map etc.
-- -------------------------------------------

doomstat.startskill = d_mode.sk_medium
doomstat.startepisode = 1
doomstat.startmap = 1
doomstat.startloadgame = -1
doomstat.autostart = false

doomstat.gameskill = d_mode.sk_medium
doomstat.gameepisode = 1
doomstat.gamemap = 1

-- If non-zero, exit the level after this number of minutes.
doomstat.timelimit = 0

-- Nightmare mode flag, single player.
doomstat.respawnmonsters = false

-- Netgame? Only true if >1 player.
doomstat.netgame = false

-- 0=Cooperative; 1=Deathmatch; 2=Altdeath.
doomstat.deathmatch = 0

-- -------------------------
-- Internal parameters for sound rendering.
-- -------------------------

doomstat.sfxVolume = 8
doomstat.musicVolume = 8

doomstat.snd_MusicDevice = 0
doomstat.snd_SfxDevice = 0
doomstat.snd_DesiredMusicDevice = 0
doomstat.snd_DesiredSfxDevice = 0

-- Config-file bound values (the C defaults come from each module's
-- initialization; D_BindVariables in d_main binds these by name).
doomstat.showMessages = 1
doomstat.screenblocks = 10
doomstat.detailLevel = 0
doomstat.snd_channels = 32
doomstat.vanilla_savegame_limit = 1
doomstat.vanilla_demo_limit = 1

-- -------------------------
-- Status flags for refresh.
-- -------------------------

doomstat.statusbaractive = false
doomstat.automapactive = false
doomstat.menuactive = false
doomstat.paused = false
doomstat.viewactive = false
doomstat.nodrawers = false
doomstat.testcontrols = false
doomstat.testcontrols_mousespeed = 0

-- This one is related to the 3-screen display mode.
-- ANG90 = left side, ANG270 = right.
doomstat.viewangleoffset = 0

-- Player taking events, and displaying.
doomstat.consoleplayer = 0
doomstat.displayplayer = 0

-- -------------------------------------
-- Scores, rating.
-- -------------------------------------

doomstat.totalkills = 0
doomstat.totalitems = 0
doomstat.totalsecret = 0

doomstat.levelstarttic = 0
doomstat.leveltime = 0

-- --------------------------------------
-- DEMO playback/recording related stuff.
-- --------------------------------------

doomstat.usergame = false
doomstat.demoplayback = false
doomstat.demorecording = false
doomstat.lowres_turn = false

-- Quit after playing a demo from cmdline.
doomstat.singledemo = false

-- C static-initializes these: gamestate = 0 (GS_LEVEL), wipegamestate =
-- GS_DEMOSCREEN (see d_main.c).
doomstat.gamestate = doomdef.GS_LEVEL

-- --------------------------------------
-- Bookkeeping on players - state.
-- --------------------------------------

-- players[1..MAXPLAYERS]; filled in by later phases.
doomstat.players = {}

-- Alive? Disconnected?
doomstat.playeringame = { false, false, false, false }

-- Player spawn spots for deathmatch.
doomstat.MAX_DM_STARTS = 10
doomstat.deathmatchstarts = {}
doomstat.deathmatch_p = nil

doomstat.playerstarts = {}

-- Intermission stats.
doomstat.wminfo = nil

-- --------------------------------------
-- Internal parameters, used for engine.
-- --------------------------------------

doomstat.savegamedir = ""
doomstat.basedefault = ""
doomstat.precache = false

-- wipegamestate can be set to -1 to force a wipe on the next draw.
doomstat.wipegamestate = doomdef.GS_DEMOSCREEN

doomstat.mouseSensitivity = 5 -- C default (m_menu.c: int mouseSensitivity = 5)

doomstat.bodyqueslot = 0

doomstat.skyflatnum = 0

doomstat.rndindex = 0

doomstat.netcmds = nil

return doomstat