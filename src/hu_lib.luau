--!native
--!optimize 2
local doomstat = require("./doomstat")
local v_video = require("./v_video")
local r_state = require("./r_state")
local r_draw = require("./r_draw")
local hu_lib = {}

local SCREENWIDTH = 320

hu_lib.HU_CHARERASE = 0x7f -- KEY_BACKSPACE

hu_lib.HU_MAXLINES = 4
hu_lib.HU_MAXLINELENGTH = 80

-- ---------------------------------------------------------------------------
-- Textline widget
-- ---------------------------------------------------------------------------

function hu_lib.HUlib_clearTextLine(t)
    t.l = ""
    t.len = 0
    t.needsupdate = true
end

function hu_lib.HUlib_initTextLine(t, x, y, f, sc)
    t.x = x
    t.y = y
    t.f = f
    t.sc = sc
    hu_lib.HUlib_clearTextLine(t)
end

-- Returns success.
function hu_lib.HUlib_addCharToTextLine(t, ch)
    if t.len == hu_lib.HU_MAXLINELENGTH then
        return false
    end
    t.l = t.l .. string.char(ch)
    t.len = t.len + 1
    t.needsupdate = 4
    return true
end

-- Returns success.
function hu_lib.HUlib_delCharFromTextLine(t)
    if t.len == 0 then
        return false
    end
    t.l = string.sub(t.l, 1, t.len - 1)
    t.len = t.len - 1
    t.needsupdate = 4
    return true
end

local function patch_short(patch, off)
    return buffer.readi16(patch.buffer, patch.offset + off)
end

-- HUlib_drawTextLine: draw the text, optionally with a cursor.
function hu_lib.HUlib_drawTextLine(l, drawcursor)

    -- Draw the new stuff.
    local x = l.x
    for i = 1, l.len do
        local c = string.byte(string.upper(l.l), i)
        if c ~= 32 -- ' '
            and c >= l.sc
            and c <= 95 then -- '_'
            local glyph = l.f[c - l.sc + 1]
            local w = patch_short(glyph, 0)
            if x + w > SCREENWIDTH then
                break
            end
            v_video.V_DrawPatchDirect(x, l.y, glyph)
            x = x + w
        else
            x = x + 4
            if x >= SCREENWIDTH then
                break
            end
        end
    end

    -- Draw the cursor if requested.
    if drawcursor then
        local cursor = l.f[95 - l.sc + 1] -- '_' - sc
        if cursor ~= nil and x + patch_short(cursor, 0) <= SCREENWIDTH then
            v_video.V_DrawPatchDirect(x, l.y, cursor)
        end
    end
end

-- HUlib_eraseTextLine: erase the text line (only when not in automap and the
-- screen is reduced, and the text must need updating).
function hu_lib.HUlib_eraseTextLine(l)
    local automapactive = doomstat.automapactive
    local viewwindowx = r_state.viewwindowx

    if not automapactive
        and viewwindowx ~= 0
        and l.needsupdate ~= 0 then
        local lh = patch_short(l.f[1], 2) + 1
        local y = l.y
        local yoffset = y * SCREENWIDTH
        while y < l.y + lh do
            if y < r_state.viewwindowy
                or y >= r_state.viewwindowy + r_state.viewheight then
                r_draw.R_VideoErase(yoffset, SCREENWIDTH) -- erase entire line
            else
                r_draw.R_VideoErase(yoffset, viewwindowx) -- erase left border
                r_draw.R_VideoErase(yoffset + viewwindowx + r_state.viewwidth,
                    viewwindowx) -- erase right border
            end
            y = y + 1
            yoffset = yoffset + SCREENWIDTH
        end
    end

    if l.needsupdate ~= 0 then
        l.needsupdate = l.needsupdate - 1
    end
end

-- ---------------------------------------------------------------------------
-- Scrolling text window widget
-- ---------------------------------------------------------------------------

function hu_lib.HUlib_initSText(s, x, y, h, font, startchar, on)
    s.h = h
    s.on = on
    s.laston = true
    s.cl = 0
    s.l = {}
    for i = 1, h do
        local line = {}
        hu_lib.HUlib_initTextLine(line, x, y - (i - 1) * (patch_short(font[1], 2) + 1),
            font, startchar)
        s.l[i] = line
    end
end

function hu_lib.HUlib_addLineToSText(s)
    -- Add a clear line.
    s.cl = s.cl + 1
    if s.cl == s.h then
        s.cl = 0
    end
    hu_lib.HUlib_clearTextLine(s.l[s.cl + 1])

    -- Everything needs updating.
    for i = 1, s.h do
        s.l[i].needsupdate = 4
    end
end

function hu_lib.HUlib_addMessageToSText(s, prefix, msg)
    hu_lib.HUlib_addLineToSText(s)
    if prefix ~= nil then
        for i = 1, #prefix do
            hu_lib.HUlib_addCharToTextLine(s.l[s.cl + 1], string.byte(prefix, i))
        end
    end
    if msg ~= nil then
        for i = 1, #msg do
            hu_lib.HUlib_addCharToTextLine(s.l[s.cl + 1], string.byte(msg, i))
        end
    end
end

function hu_lib.HUlib_drawSText(s)
    if not s.on() then
        return -- if not on, don't draw
    end

    -- Draw everything.
    for i = 1, s.h do
        local idx = s.cl - (i - 1)
        if idx < 0 then
            idx = idx + s.h -- handle queue of lines
        end
        hu_lib.HUlib_drawTextLine(s.l[idx + 1], false) -- no cursor, please
    end
end

function hu_lib.HUlib_eraseSText(s)
    for i = 1, s.h do
        if s.laston and not s.on() then
            s.l[i].needsupdate = 4
        end
        hu_lib.HUlib_eraseTextLine(s.l[i])
    end
    s.laston = s.on()
end

-- ---------------------------------------------------------------------------
-- Input text line widget
-- ---------------------------------------------------------------------------

function hu_lib.HUlib_initIText(it, x, y, font, startchar, on)
    it.lm = 0 -- default left margin is start of text
    it.on = on
    it.laston = true
    it.l = {}
    hu_lib.HUlib_initTextLine(it.l, x, y, font, startchar)
end

-- The following deletion routines adhere to the left margin restriction.
function hu_lib.HUlib_delCharFromIText(it)
    if it.l.len ~= it.lm then
        hu_lib.HUlib_delCharFromTextLine(it.l)
    end
end

function hu_lib.HUlib_eraseLineFromIText(it)
    while it.lm ~= it.l.len do
        hu_lib.HUlib_delCharFromTextLine(it.l)
    end
end

-- Resets left margin as well.
function hu_lib.HUlib_resetIText(it)
    it.lm = 0
    hu_lib.HUlib_clearTextLine(it.l)
end

function hu_lib.HUlib_addPrefixToIText(it, str)
    for i = 1, #str do
        hu_lib.HUlib_addCharToTextLine(it.l, string.byte(str, i))
    end
    it.lm = it.l.len
end

-- Wrapper function for handling general keyed input.
-- Returns true if it ate the key.
function hu_lib.HUlib_keyInIText(it, ch)
    ch = string.byte(string.upper(string.char(ch)))
    if ch >= 32 and ch <= 95 then -- ' '..'_'
        hu_lib.HUlib_addCharToTextLine(it.l, ch)
    elseif ch == 0x7f then -- KEY_BACKSPACE
        hu_lib.HUlib_delCharFromIText(it)
    elseif ch ~= 13 then -- KEY_ENTER
        return false -- did not eat key
    end
    return true -- ate the key
end

function hu_lib.HUlib_drawIText(it)
    if not it.on() then
        return
    end
    hu_lib.HUlib_drawTextLine(it.l, true) -- draw the line w/ cursor
end

function hu_lib.HUlib_eraseIText(it)
    if it.laston and not it.on() then
        it.l.needsupdate = 4
    end
    hu_lib.HUlib_eraseTextLine(it.l)
    it.laston = it.on()
end

-- HUlib_init: no-op.
function hu_lib.HUlib_init()
end

return hu_lib