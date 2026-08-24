--!native
--!optimize 2
local doomtype = require("./doomtype")
local doomdef = {}

-- gamestate_t
doomdef.GS_LEVEL = 0
doomdef.GS_INTERMISSION = 1
doomdef.GS_FINALE = 2
doomdef.GS_DEMOSCREEN = 3

-- gameaction_t
doomdef.ga_nothing = 0
doomdef.ga_loadlevel = 1
doomdef.ga_newgame = 2
doomdef.ga_loadgame = 3
doomdef.ga_savegame = 4
doomdef.ga_playdemo = 5
doomdef.ga_completed = 6
doomdef.ga_victory = 7
doomdef.ga_worlddone = 8
doomdef.ga_screenshot = 9

-- Skill flags (MTF_*).
doomdef.MTF_EASY = 1
doomdef.MTF_NORMAL = 2
doomdef.MTF_HARD = 4
doomdef.MTF_AMBUSH = 8

-- card_t (key cards).
doomdef.it_bluecard = 0
doomdef.it_yellowcard = 1
doomdef.it_redcard = 2
doomdef.it_blueskull = 3
doomdef.it_yellowskull = 4
doomdef.it_redskull = 5
doomdef.NUMCARDS = 6

-- weapontype_t.
doomdef.wp_fist = 0
doomdef.wp_pistol = 1
doomdef.wp_shotgun = 2
doomdef.wp_chaingun = 3
doomdef.wp_missile = 4
doomdef.wp_plasma = 5
doomdef.wp_bfg = 6
doomdef.wp_chainsaw = 7
doomdef.wp_supershotgun = 8
doomdef.NUMWEAPONS = 9
doomdef.wp_nochange = 10

-- ammotype_t.
doomdef.am_clip = 0
doomdef.am_shell = 1
doomdef.am_cell = 2
doomdef.am_misl = 3
doomdef.NUMAMMO = 4
doomdef.am_noammo = 5

-- powertype_t.
doomdef.pw_invulnerability = 0
doomdef.pw_strength = 1
doomdef.pw_invisibility = 2
doomdef.pw_ironfeet = 3
doomdef.pw_allmap = 4
doomdef.pw_infrared = 5
doomdef.NUMPOWERS = 6

-- powerduration_t.
doomdef.INVULNTICS = 30 * doomtype.TICRATE
doomdef.INVISTICS = 60 * doomtype.TICRATE
doomdef.INFRATICS = 120 * doomtype.TICRATE
doomdef.IRONTICS = 60 * doomtype.TICRATE

return doomdef