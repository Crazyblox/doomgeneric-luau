--!native
--!optimize 2
local i_video = require("./i_video")
local v_video = require("./v_video")
local m_random = require("./m_random")
local f_wipe = {}

local SCREENWIDTH = 320
local SCREENHEIGHT = 200

-- wipe numbers (C wipeno_t).
f_wipe.wipe_ColorXForm = 0
f_wipe.wipe_Melt = 1

-- When zero, stop the wipe.
local go = false

local wipe_scr_start = nil -- byte buffer snapshot of the start screen
local wipe_scr_end = nil   -- byte buffer snapshot of the end screen
local wipe_scr = nil       -- the working screen (I_VideoBuffer)

-- ---------------------------------------------------------------------------
-- Color xform wipe
-- ---------------------------------------------------------------------------

local function wipe_shittyColMajorXform(array, width, height)
    -- array is a numeric table of shorts in row-major (width columns).
    -- dest[x*height+y] = array[y*width+x]
    local dest = {}
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            dest[x * height + y + 1] = array[y * width + x + 1]
        end
    end
    return dest
end

local function wipe_initColorXForm(width, height, ticks)
    buffer.copy(wipe_scr, 0, wipe_scr_start, 0, width * height)
    return 0
end

local function wipe_doColorXForm(width, height, ticks)
    local changed = false
    local w = 0
    local e = 0

    while w < width * height do
        local wv = buffer.readu8(wipe_scr, w)
        local ev = buffer.readu8(wipe_scr_end, e)
        if wv ~= ev then
            if wv > ev then
                local newval = wv - ticks
                if newval < ev then
                    buffer.writeu8(wipe_scr, w, ev)
                else
                    buffer.writeu8(wipe_scr, w, newval)
                end
                changed = true
            elseif wv < ev then
                local newval = wv + ticks
                if newval > ev then
                    buffer.writeu8(wipe_scr, w, ev)
                else
                    buffer.writeu8(wipe_scr, w, newval)
                end
                changed = true
            end
        end
        w = w + 1
        e = e + 1
    end

    return (not changed) and 1 or 0
end

local function wipe_exitColorXForm(width, height, ticks)
    return 0
end

-- ---------------------------------------------------------------------------
-- Melt wipe
-- ---------------------------------------------------------------------------

-- Column positions (y[i] < 0 => not ready to scroll yet). The C allocates
-- width (320) ints but wipe_doMelt only uses width/2 (160) of them.
local y = {}

-- Column-major short tables for the start/end snapshots.
local start_cols = nil
local end_cols = nil

local function wipe_initMelt(width, height, ticks)
    -- Copy start screen to main screen.
    buffer.copy(wipe_scr, 0, wipe_scr_start, 0, width * height)

    -- Makes this wipe faster (in theory) to have stuff in column-major
    -- format: transform width/2 x height shorts.
    local cols = {}
    for yy = 0, height - 1 do
        for xx = 0, width // 2 - 1 do
            cols[yy * (width // 2) + xx + 1] =
                buffer.readu16(wipe_scr_start, yy * width + xx * 2)
        end
    end
    start_cols = wipe_shittyColMajorXform(cols, width // 2, height)

    cols = {}
    for yy = 0, height - 1 do
        for xx = 0, width // 2 - 1 do
            cols[yy * (width // 2) + xx + 1] =
                buffer.readu16(wipe_scr_end, yy * width + xx * 2)
        end
    end
    end_cols = wipe_shittyColMajorXform(cols, width // 2, height)

    -- Setup initial column positions.
    y = {}
    y[1] = -(m_random.M_Random() % 16)
    for i = 2, width do
        local r = (m_random.M_Random() % 3) - 1
        y[i] = y[i - 1] + r
        if y[i] > 0 then
            y[i] = 0
        elseif y[i] == -16 then
            y[i] = -15
        end
    end

    v_video.V_MarkRect(0, 0, width, height)
    return 0
end

local function wipe_doMelt(width, height, ticks)
    width = width // 2
    local done = true

    for _ = 1, ticks do
        for i = 1, width do
            if y[i] < 0 then
                y[i] = y[i] + 1
                done = false
            elseif y[i] < height then
                local dy
                if y[i] < 16 then
                    dy = y[i] + 1
                else
                    dy = 8
                end
                if y[i] + dy >= height then
                    dy = height - y[i]
                end

                -- Draw `dy` end pixels at the melt front (column i).
                local s_idx = (i - 1) * height + y[i] + 1
                local d_off = (y[i] * width + (i - 1)) * 2
                for _ = 1, dy do
                    buffer.writeu16(wipe_scr, d_off, end_cols[s_idx])
                    d_off = d_off + width * 2
                    s_idx = s_idx + 1
                end

                y[i] = y[i] + dy

                -- Draw the remaining `height - y[i]` pixels from the top of
                -- the start column (the C reads `[i*height]`, reproducing
                -- the classic melt artifact where the bottom region shows
                -- the top rows of the old screen).
                s_idx = (i - 1) * height + 1
                d_off = (y[i] * width + (i - 1)) * 2
                for _ = 1, height - y[i] do
                    buffer.writeu16(wipe_scr, d_off, start_cols[s_idx])
                    d_off = d_off + width * 2
                    s_idx = s_idx + 1
                end

                done = false
            end
        end
    end

    return done and 1 or 0
end

local function wipe_exitMelt(width, height, ticks)
    y = {}
    start_cols = nil
    end_cols = nil
    return 0
end

-- ---------------------------------------------------------------------------
-- Start / End screen
-- ---------------------------------------------------------------------------

function f_wipe.wipe_StartScreen(x, y, width, height)
    wipe_scr_start = buffer.create(SCREENWIDTH * SCREENHEIGHT)
    i_video.I_ReadScreen(wipe_scr_start)
    return 0
end

function f_wipe.wipe_EndScreen(x, y, width, height)
    wipe_scr_end = buffer.create(SCREENWIDTH * SCREENHEIGHT)
    i_video.I_ReadScreen(wipe_scr_end)
    v_video.V_DrawBlock(x, y, width, height,
        { buffer = wipe_scr_start, offset = 0 }) -- restore start scr.
    return 0
end

-- ---------------------------------------------------------------------------
-- wipe_ScreenWipe
-- ---------------------------------------------------------------------------

local wipes = {
    wipe_initColorXForm, wipe_doColorXForm, wipe_exitColorXForm,
    wipe_initMelt, wipe_doMelt, wipe_exitMelt,
}

function f_wipe.wipe_ScreenWipe(wipeno, x, y, width, height, ticks)
    local rc

    -- Initial stuff.
    if not go then
        go = true
        wipe_scr = i_video.I_VideoBuffer
        wipes[wipeno * 3 + 1](width, height, ticks)
    end

    -- Do a piece of wipe-in.
    v_video.V_MarkRect(0, 0, width, height)
    rc = wipes[wipeno * 3 + 2](width, height, ticks)

    -- Final stuff.
    if rc ~= 0 then
        go = false
        wipes[wipeno * 3 + 3](width, height, ticks)
    end

    return (not go) and 1 or 0
end

return f_wipe