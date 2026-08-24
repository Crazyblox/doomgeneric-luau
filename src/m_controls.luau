--!native
--!optimize 2
local doomkeys = require("./doomkeys")
local m_config = require("./m_config")
local m_controls = {}

-- ---------------------------------------------------------------------------
-- Keyboard controls (Doom)
-- ---------------------------------------------------------------------------

m_controls.key_right = doomkeys.KEY_RIGHTARROW
m_controls.key_left = doomkeys.KEY_LEFTARROW
m_controls.key_up = doomkeys.KEY_UPARROW
m_controls.key_down = doomkeys.KEY_DOWNARROW
m_controls.key_strafeleft = doomkeys.KEY_STRAFE_L
m_controls.key_straferight = doomkeys.KEY_STRAFE_R
m_controls.key_fire = doomkeys.KEY_FIRE
m_controls.key_use = doomkeys.KEY_USE
m_controls.key_strafe = doomkeys.KEY_RALT
m_controls.key_speed = doomkeys.KEY_RSHIFT

-- Heretic keyboard controls.
m_controls.key_flyup = doomkeys.KEY_PGUP
m_controls.key_flydown = doomkeys.KEY_INS
m_controls.key_flycenter = doomkeys.KEY_HOME
m_controls.key_lookup = doomkeys.KEY_PGDN
m_controls.key_lookdown = doomkeys.KEY_DEL
m_controls.key_lookcenter = doomkeys.KEY_END
m_controls.key_invleft = string.byte("[")
m_controls.key_invright = string.byte("]")
m_controls.key_useartifact = doomkeys.KEY_ENTER

-- Hexen key controls.
m_controls.key_jump = string.byte("/")
m_controls.key_arti_all = doomkeys.KEY_BACKSPACE
m_controls.key_arti_health = string.byte("\\")
m_controls.key_arti_poisonbag = string.byte("0")
m_controls.key_arti_blastradius = string.byte("9")
m_controls.key_arti_teleport = string.byte("8")
m_controls.key_arti_teleportother = string.byte("7")
m_controls.key_arti_egg = string.byte("6")
m_controls.key_arti_invulnerability = string.byte("5")

-- Strife key controls.
m_controls.key_usehealth = string.byte("h")
m_controls.key_invquery = string.byte("q")
m_controls.key_mission = string.byte("w")
m_controls.key_invpop = string.byte("z")
m_controls.key_invkey = string.byte("k")
m_controls.key_invhome = doomkeys.KEY_HOME
m_controls.key_invend = doomkeys.KEY_END
m_controls.key_invuse = doomkeys.KEY_ENTER
m_controls.key_invdrop = doomkeys.KEY_BACKSPACE

-- ---------------------------------------------------------------------------
-- Mouse controls
-- ---------------------------------------------------------------------------

m_controls.mousebfire = 0
m_controls.mousebstrafe = 1
m_controls.mousebforward = 2
m_controls.mousebjump = -1
m_controls.mousebstrafeleft = -1
m_controls.mousebstraferight = -1
m_controls.mousebbackward = -1
m_controls.mousebuse = -1
m_controls.mousebprevweapon = -1
m_controls.mousebnextweapon = -1

-- ---------------------------------------------------------------------------
-- General keys
-- ---------------------------------------------------------------------------

m_controls.key_message_refresh = doomkeys.KEY_ENTER
m_controls.key_pause = doomkeys.KEY_PAUSE
m_controls.key_demo_quit = string.byte("q")
m_controls.key_spy = doomkeys.KEY_F12

-- Multiplayer chat keys.
m_controls.key_multi_msg = string.byte("t")
m_controls.key_multi_msgplayer = {}

-- Weapon selection keys.
m_controls.key_weapon1 = string.byte("1")
m_controls.key_weapon2 = string.byte("2")
m_controls.key_weapon3 = string.byte("3")
m_controls.key_weapon4 = string.byte("4")
m_controls.key_weapon5 = string.byte("5")
m_controls.key_weapon6 = string.byte("6")
m_controls.key_weapon7 = string.byte("7")
m_controls.key_weapon8 = string.byte("8")
m_controls.key_prevweapon = 0
m_controls.key_nextweapon = 0

-- Map control keys.
m_controls.key_map_north = doomkeys.KEY_UPARROW
m_controls.key_map_south = doomkeys.KEY_DOWNARROW
m_controls.key_map_east = doomkeys.KEY_RIGHTARROW
m_controls.key_map_west = doomkeys.KEY_LEFTARROW
m_controls.key_map_zoomin = string.byte("=")
m_controls.key_map_zoomout = string.byte("-")
m_controls.key_map_toggle = doomkeys.KEY_TAB
m_controls.key_map_maxzoom = string.byte("0")
m_controls.key_map_follow = string.byte("f")
m_controls.key_map_grid = string.byte("g")
m_controls.key_map_mark = string.byte("m")
m_controls.key_map_clearmark = string.byte("c")

-- Menu keys.
m_controls.key_menu_activate = doomkeys.KEY_ESCAPE
m_controls.key_menu_up = doomkeys.KEY_UPARROW
m_controls.key_menu_down = doomkeys.KEY_DOWNARROW
m_controls.key_menu_left = doomkeys.KEY_LEFTARROW
m_controls.key_menu_right = doomkeys.KEY_RIGHTARROW
m_controls.key_menu_back = doomkeys.KEY_BACKSPACE
m_controls.key_menu_forward = doomkeys.KEY_ENTER
m_controls.key_menu_confirm = string.byte("y")
m_controls.key_menu_abort = string.byte("n")
m_controls.key_menu_help = doomkeys.KEY_F1
m_controls.key_menu_save = doomkeys.KEY_F2
m_controls.key_menu_load = doomkeys.KEY_F3
m_controls.key_menu_volume = doomkeys.KEY_F4
m_controls.key_menu_detail = doomkeys.KEY_F5
m_controls.key_menu_qsave = doomkeys.KEY_F6
m_controls.key_menu_endgame = doomkeys.KEY_F7
m_controls.key_menu_messages = doomkeys.KEY_F8
m_controls.key_menu_qload = doomkeys.KEY_F9
m_controls.key_menu_quit = doomkeys.KEY_F10
m_controls.key_menu_gamma = doomkeys.KEY_F11
m_controls.key_menu_incscreen = doomkeys.KEY_EQUALS
m_controls.key_menu_decscreen = doomkeys.KEY_MINUS
m_controls.key_menu_screenshot = 0

-- ---------------------------------------------------------------------------
-- Joystick controls
-- ---------------------------------------------------------------------------

m_controls.joybfire = 0
m_controls.joybstrafe = 1
m_controls.joybuse = 3
m_controls.joybspeed = 2
m_controls.joybstrafeleft = -1
m_controls.joybstraferight = -1
m_controls.joybjump = -1
m_controls.joybprevweapon = -1
m_controls.joybnextweapon = -1
m_controls.joybmenu = -1

-- Double-click "use" behaviour.
m_controls.dclick_use = 1

-- ---------------------------------------------------------------------------
-- Bind all of the common controls used by Doom and all other games.
-- ---------------------------------------------------------------------------

local function bind_key(name, field)
    m_config.M_BindVariable(name, m_controls, field, m_config.DEFAULT_KEY)
end

local function bind_int(name, field)
    m_config.M_BindVariable(name, m_controls, field, m_config.DEFAULT_INT)
end

function m_controls.M_BindBaseControls()
    bind_key("key_right", "key_right")
    bind_key("key_left", "key_left")
    bind_key("key_up", "key_up")
    bind_key("key_down", "key_down")
    bind_key("key_strafeleft", "key_strafeleft")
    bind_key("key_straferight", "key_straferight")
    bind_key("key_fire", "key_fire")
    bind_key("key_use", "key_use")
    bind_key("key_strafe", "key_strafe")
    bind_key("key_speed", "key_speed")

    bind_int("mouseb_fire", "mousebfire")
    bind_int("mouseb_strafe", "mousebstrafe")
    bind_int("mouseb_forward", "mousebforward")

    bind_int("joyb_fire", "joybfire")
    bind_int("joyb_strafe", "joybstrafe")
    bind_int("joyb_use", "joybuse")
    bind_int("joyb_speed", "joybspeed")
    bind_int("joyb_menu_activate", "joybmenu")

    -- Extra controls that are not in the Vanilla versions:
    bind_int("joyb_strafeleft", "joybstrafeleft")
    bind_int("joyb_straferight", "joybstraferight")
    bind_int("mouseb_strafeleft", "mousebstrafeleft")
    bind_int("mouseb_straferight", "mousebstraferight")
    bind_int("mouseb_use", "mousebuse")
    bind_int("mouseb_backward", "mousebbackward")
    bind_int("dclick_use", "dclick_use")
    bind_key("key_pause", "key_pause")
    bind_key("key_message_refresh", "key_message_refresh")
end

function m_controls.M_BindHereticControls()
    bind_key("key_flyup", "key_flyup")
    bind_key("key_flydown", "key_flydown")
    bind_key("key_flycenter", "key_flycenter")
    bind_key("key_lookup", "key_lookup")
    bind_key("key_lookdown", "key_lookdown")
    bind_key("key_lookcenter", "key_lookcenter")
    bind_key("key_invleft", "key_invleft")
    bind_key("key_invright", "key_invright")
    bind_key("key_useartifact", "key_useartifact")
end

function m_controls.M_BindHexenControls()
    bind_key("key_jump", "key_jump")
    bind_int("mouseb_jump", "mousebjump")
    bind_int("joyb_jump", "joybjump")
    bind_key("key_arti_all", "key_arti_all")
    bind_key("key_arti_health", "key_arti_health")
    bind_key("key_arti_poisonbag", "key_arti_poisonbag")
    bind_key("key_arti_blastradius", "key_arti_blastradius")
    bind_key("key_arti_teleport", "key_arti_teleport")
    bind_key("key_arti_teleportother", "key_arti_teleportother")
    bind_key("key_arti_egg", "key_arti_egg")
    bind_key("key_arti_invulnerability", "key_arti_invulnerability")
end

function m_controls.M_BindStrifeControls()
    -- These keys are shared with Heretic/Hexen but have different defaults.
    m_controls.key_jump = string.byte("a")
    m_controls.key_lookup = doomkeys.KEY_PGUP
    m_controls.key_lookdown = doomkeys.KEY_PGDN
    m_controls.key_invleft = doomkeys.KEY_INS
    m_controls.key_invright = doomkeys.KEY_DEL

    bind_key("key_jump", "key_jump")
    bind_key("key_lookUp", "key_lookup")
    bind_key("key_lookDown", "key_lookdown")
    bind_key("key_invLeft", "key_invleft")
    bind_key("key_invRight", "key_invright")

    -- Custom Strife-only keys.
    bind_key("key_useHealth", "key_usehealth")
    bind_key("key_invquery", "key_invquery")
    bind_key("key_mission", "key_mission")
    bind_key("key_invPop", "key_invpop")
    bind_key("key_invKey", "key_invkey")
    bind_key("key_invHome", "key_invhome")
    bind_key("key_invEnd", "key_invend")
    bind_key("key_invUse", "key_invuse")
    bind_key("key_invDrop", "key_invdrop")

    -- Strife also supports jump on mouse and joystick.
    bind_int("mouseb_jump", "mousebjump")
    bind_int("joyb_jump", "joybjump")
end

function m_controls.M_BindWeaponControls()
    bind_key("key_weapon1", "key_weapon1")
    bind_key("key_weapon2", "key_weapon2")
    bind_key("key_weapon3", "key_weapon3")
    bind_key("key_weapon4", "key_weapon4")
    bind_key("key_weapon5", "key_weapon5")
    bind_key("key_weapon6", "key_weapon6")
    bind_key("key_weapon7", "key_weapon7")
    bind_key("key_weapon8", "key_weapon8")
    bind_key("key_prevweapon", "key_prevweapon")
    bind_key("key_nextweapon", "key_nextweapon")
    bind_int("joyb_prevweapon", "joybprevweapon")
    bind_int("joyb_nextweapon", "joybnextweapon")
    bind_int("mouseb_prevweapon", "mousebprevweapon")
    bind_int("mouseb_nextweapon", "mousebnextweapon")
end

function m_controls.M_BindMapControls()
    bind_key("key_map_north", "key_map_north")
    bind_key("key_map_south", "key_map_south")
    bind_key("key_map_east", "key_map_east")
    bind_key("key_map_west", "key_map_west")
    bind_key("key_map_zoomin", "key_map_zoomin")
    bind_key("key_map_zoomout", "key_map_zoomout")
    bind_key("key_map_toggle", "key_map_toggle")
    bind_key("key_map_maxzoom", "key_map_maxzoom")
    bind_key("key_map_follow", "key_map_follow")
    bind_key("key_map_grid", "key_map_grid")
    bind_key("key_map_mark", "key_map_mark")
    bind_key("key_map_clearmark", "key_map_clearmark")
end

function m_controls.M_BindMenuControls()
    bind_key("key_menu_activate", "key_menu_activate")
    bind_key("key_menu_up", "key_menu_up")
    bind_key("key_menu_down", "key_menu_down")
    bind_key("key_menu_left", "key_menu_left")
    bind_key("key_menu_right", "key_menu_right")
    bind_key("key_menu_back", "key_menu_back")
    bind_key("key_menu_forward", "key_menu_forward")
    bind_key("key_menu_confirm", "key_menu_confirm")
    bind_key("key_menu_abort", "key_menu_abort")
    bind_key("key_menu_help", "key_menu_help")
    bind_key("key_menu_save", "key_menu_save")
    bind_key("key_menu_load", "key_menu_load")
    bind_key("key_menu_volume", "key_menu_volume")
    bind_key("key_menu_detail", "key_menu_detail")
    bind_key("key_menu_qsave", "key_menu_qsave")
    bind_key("key_menu_endgame", "key_menu_endgame")
    bind_key("key_menu_messages", "key_menu_messages")
    bind_key("key_menu_qload", "key_menu_qload")
    bind_key("key_menu_quit", "key_menu_quit")
    bind_key("key_menu_gamma", "key_menu_gamma")
    bind_key("key_menu_incscreen", "key_menu_incscreen")
    bind_key("key_menu_decscreen", "key_menu_decscreen")
    bind_key("key_menu_screenshot", "key_menu_screenshot")
    bind_key("key_demo_quit", "key_demo_quit")
    bind_key("key_spy", "key_spy")
end

function m_controls.M_BindChatControls(num_players)
    bind_key("key_multi_msg", "key_multi_msg")
    for i = 0, num_players - 1 do
        local name = string.format("key_multi_msgplayer%i", i + 1)
        m_config.M_BindVariable(name, m_controls.key_multi_msgplayer,
            i + 1, m_config.DEFAULT_KEY)
    end
end

-- M_ApplyPlatformDefaults: no-op (add platform-specific patches here).
function m_controls.M_ApplyPlatformDefaults()
end

return m_controls