local doomtype = require("./doomtype")
local doomstat = require("./doomstat")
local dstrings = require("./dstrings")
local deh_str = require("./deh_str")
local w_wad = require("./w_wad")
local z_zone = require("./z_zone")
local hu_lib = require("./hu_lib")
local d_mode = require("./d_mode")
local doomkeys = require("./doomkeys")
local m_controls = require("./m_controls")
local d_event = require("./d_event")
local hu_stuff = {}

-- Font constants.
local HU_FONTSTART = 33 -- '!'
local HU_FONTEND = 95 -- '_'
local HU_FONTSIZE = HU_FONTEND - HU_FONTSTART + 1 -- 63

local HU_MSGX = 0
local HU_MSGY = 0
local HU_MSGHEIGHT = 1 -- in lines

local HU_MSGTIMEOUT = 4 * doomtype.TICRATE -- 4*35 = 140

-- Map title line (HU_TITLE* macros). HU_TITLEY is computed at HU_Start time
-- from the loaded font height, matching the C macro use.
local HU_TITLEX = 0

-- Chat input line.
local HU_INPUTX = HU_MSGX

local function patch_short(patch, off)
    return buffer.readi16(patch.buffer, patch.offset + off)
end

-- The C's `patch_t* hu_font[HU_FONTSIZE]` array.
hu_stuff.hu_font = {}

-- Chat macros (d_englsh.h HUSTR_CHATMACRO*).
hu_stuff.chat_macros = {
    dstrings.HUSTR_CHATMACRO0,
    dstrings.HUSTR_CHATMACRO1,
    dstrings.HUSTR_CHATMACRO2,
    dstrings.HUSTR_CHATMACRO3,
    dstrings.HUSTR_CHATMACRO4,
    dstrings.HUSTR_CHATMACRO5,
    dstrings.HUSTR_CHATMACRO6,
    dstrings.HUSTR_CHATMACRO7,
    dstrings.HUSTR_CHATMACRO8,
    dstrings.HUSTR_CHATMACRO9,
}

-- Player names (d_englsh.h HUSTR_PLR*).
hu_stuff.player_names = {
    dstrings.HUSTR_PLRGREEN,
    dstrings.HUSTR_PLRINDIGO,
    dstrings.HUSTR_PLRBROWN,
    dstrings.HUSTR_PLRRED,
}

-- State (C statics).
local plr = nil
local w_title = {}
local chat_on = false
hu_stuff.chat_on = false -- exposed for m_menu (extern boolean chat_on)
local w_chat = {}
local always_off = false
local w_inputbuffer = {}
local message_on = false
hu_stuff.message_dontfuckwithme = false
local message_nottobefuckedwith = false
local w_message = {}
local message_counter = 0
local headsupactive = false

-- Circular chat character queue.
local QUEUESIZE = 128
local chatchars = {}
local head = 0
local tail = 0

-- ---------------------------------------------------------------------------
-- HU_Init / HU_Stop
-- ---------------------------------------------------------------------------

-- HU_Init: load the heads-up font (STCFN033..STCFN095).
function hu_stuff.HU_Init()
    local j = HU_FONTSTART
    for i = 1, HU_FONTSIZE do
        local buffer = deh_str.DEH_snprintf("STCFN%.3d", j)
        hu_stuff.hu_font[i] = w_wad.W_CacheLumpName(buffer, z_zone.PU_STATIC)
        j = j + 1
    end
end

function hu_stuff.HU_Stop()
    headsupactive = false
end

-- ---------------------------------------------------------------------------
-- HU_Start
-- ---------------------------------------------------------------------------

function hu_stuff.HU_Start()
    local s
    local font_height = patch_short(hu_stuff.hu_font[1], 2)

    if headsupactive then
        hu_stuff.HU_Stop()
    end

    plr = doomstat.players[doomstat.consoleplayer + 1]
    message_on = false
    hu_stuff.message_dontfuckwithme = false
    message_nottobefuckedwith = false
    chat_on = false

    -- Create the message widget.
    hu_lib.HUlib_initSText(w_message, HU_MSGX, HU_MSGY, HU_MSGHEIGHT,
        hu_stuff.hu_font, HU_FONTSTART, function() return message_on end)

    -- Create the map title widget.
    hu_lib.HUlib_initTextLine(w_title, HU_TITLEX, 167 - font_height,
        hu_stuff.hu_font, HU_FONTSTART)

    -- Logical gamemission (doomstat.h macro).
    local gamemission = doomstat.gamemission
    if gamemission == d_mode.pack_chex then
        gamemission = d_mode.doom
    elseif gamemission == d_mode.pack_hacx then
        gamemission = d_mode.doom2
    end

    if gamemission == d_mode.doom then
        s = dstrings.mapnames[(doomstat.gameepisode - 1) * 9 + doomstat.gamemap]
    elseif gamemission == d_mode.doom2 then
        s = dstrings.mapnames_commercial[doomstat.gamemap]
    elseif gamemission == d_mode.pack_plut then
        s = dstrings.mapnames_commercial[doomstat.gamemap + 32]
    elseif gamemission == d_mode.pack_tnt then
        s = dstrings.mapnames_commercial[doomstat.gamemap + 64]
    else
        s = "Unknown level"
    end

    -- Chex.exe always uses the episode 1 level title (e.g. E2M1 gives the
    -- title for E1M1).
    if doomstat.gameversion == d_mode.exe_chex then
        s = dstrings.mapnames[doomstat.gamemap]
    end

    -- Dehacked substitution to get the modified level name.
    s = deh_str.DEH_String(s)

    for i = 1, #s do
        hu_lib.HUlib_addCharToTextLine(w_title, string.byte(s, i))
    end

    -- Create the chat widget.
    hu_lib.HUlib_initIText(w_chat, HU_INPUTX, HU_MSGY + HU_MSGHEIGHT * (font_height + 1),
        hu_stuff.hu_font, HU_FONTSTART, function() return chat_on end)

    -- Create the inputbuffer widgets.
    for i = 1, doomtype.MAXPLAYERS do
        w_inputbuffer[i] = {}
        hu_lib.HUlib_initIText(w_inputbuffer[i], 0, 0, nil, 0,
            function() return always_off end)
    end

    headsupactive = true
end

-- ---------------------------------------------------------------------------
-- HU_Drawer / HU_Erase
-- ---------------------------------------------------------------------------

function hu_stuff.HU_Drawer()
    hu_lib.HUlib_drawSText(w_message)
    hu_lib.HUlib_drawIText(w_chat)
    if doomstat.automapactive then
        hu_lib.HUlib_drawTextLine(w_title, false)
    end
end

function hu_stuff.HU_Erase()
    hu_lib.HUlib_eraseSText(w_message)
    hu_lib.HUlib_eraseIText(w_chat)
    hu_lib.HUlib_eraseTextLine(w_title)
end

-- ---------------------------------------------------------------------------
-- HU_Ticker
-- ---------------------------------------------------------------------------

function hu_stuff.HU_Ticker()
    -- Tick down message counter if message is up.
    if message_counter ~= 0 then
        message_counter = message_counter - 1
        if message_counter == 0 then
            message_on = false
            message_nottobefuckedwith = false
        end
    end

    if doomstat.showMessages ~= 0 or hu_stuff.message_dontfuckwithme then
        -- Display message if necessary.
        if plr.message ~= nil
            and (not message_nottobefuckedwith or hu_stuff.message_dontfuckwithme) then
            hu_lib.HUlib_addMessageToSText(w_message, nil, plr.message)
            plr.message = nil
            message_on = true
            message_counter = HU_MSGTIMEOUT
            message_nottobefuckedwith = hu_stuff.message_dontfuckwithme
            hu_stuff.message_dontfuckwithme = false
        end
    end

    -- Check for incoming chat characters (netgame only; cut in v1).
    if doomstat.netgame then
        for i = 1, doomtype.MAXPLAYERS do
            if doomstat.playeringame[i] then
                if i ~= doomstat.consoleplayer + 1 then
                    local c = doomstat.players[i].cmd.chatchar
                    if c ~= 0 then
                        -- Chat processing is cut in v1 (netgame never on).
                        doomstat.players[i].cmd.chatchar = 0
                    end
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Chat queue
-- ---------------------------------------------------------------------------

function hu_stuff.HU_queueChatChar(c)
    if ((head + 1) % QUEUESIZE) == tail then
        plr.message = deh_str.DEH_String(dstrings.HUSTR_MSGU)
    else
        chatchars[head] = c
        head = (head + 1) % QUEUESIZE
    end
end

-- HU_dequeueChatChar: return the next character from the chat input queue.
function hu_stuff.HU_dequeueChatChar()
    local c
    if head ~= tail then
        c = chatchars[tail]
        tail = (tail + 1) % QUEUESIZE
    else
        c = 0
    end
    return c
end

-- ---------------------------------------------------------------------------
-- HU_Responder
-- ---------------------------------------------------------------------------

local altdown = false
local num_nobrainers = 0

function hu_stuff.HU_Responder(ev)
    local eatkey = false
    local i
    local numplayers = 0

    for i = 1, doomtype.MAXPLAYERS do
        if doomstat.playeringame[i] then
            numplayers = numplayers + 1
        end
    end

    if ev.data1 == doomkeys.KEY_RSHIFT then
        return false
    elseif ev.data1 == doomkeys.KEY_RALT or ev.data1 == doomkeys.KEY_LALT then
        altdown = ev.type == d_event.ev_keydown
        return false
    end

    if ev.type ~= d_event.ev_keydown then
        return false
    end

    if not chat_on then
        if ev.data1 == m_controls.key_message_refresh then
            message_on = true
            message_counter = HU_MSGTIMEOUT
            eatkey = true
        elseif doomstat.netgame and ev.data2 == m_controls.key_multi_msg then
            -- Chat is cut in v1; the C opens the chat window here.
            eatkey = false
        elseif doomstat.netgame and numplayers > 2 then
            for i = 1, doomtype.MAXPLAYERS do
                if ev.data2 == m_controls.key_multi_msgplayer[i] then
                    if doomstat.playeringame[i] and i ~= doomstat.consoleplayer + 1 then
                        eatkey = false
                        break
                    elseif i == doomstat.consoleplayer + 1 then
                        num_nobrainers = num_nobrainers + 1
                        if num_nobrainers < 3 then
                            plr.message = deh_str.DEH_String(dstrings.HUSTR_TALKTOSELF1)
                        elseif num_nobrainers < 6 then
                            plr.message = deh_str.DEH_String(dstrings.HUSTR_TALKTOSELF2)
                        elseif num_nobrainers < 9 then
                            plr.message = deh_str.DEH_String(dstrings.HUSTR_TALKTOSELF3)
                        elseif num_nobrainers < 32 then
                            plr.message = deh_str.DEH_String(dstrings.HUSTR_TALKTOSELF4)
                        else
                            plr.message = deh_str.DEH_String(dstrings.HUSTR_TALKTOSELF5)
                        end
                    end
                end
            end
        end
    else
        -- Chat is cut in v1, so the chat input path never runs.
        return false
    end

    return eatkey
end

return hu_stuff