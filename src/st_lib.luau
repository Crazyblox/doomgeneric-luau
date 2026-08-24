--!native
--!optimize 2
local deh_str = require("./deh_str")
local z_zone = require("./z_zone")
local w_wad = require("./w_wad")
local i_system = require("./i_system")
local v_video = require("./v_video")
local st_lib = {}

local SCREENWIDTH = 320
local SCREENHEIGHT = 200

st_lib.ST_WIDTH = SCREENWIDTH
st_lib.ST_HEIGHT = 32
st_lib.ST_Y = SCREENHEIGHT - st_lib.ST_HEIGHT -- 168

-- The backing screen for the status bar (C: byte *st_backing_screen).
st_lib.st_backing_screen = nil

-- Hack display negative frags. Loads and stores the stminus lump.
local sttminus = nil

local function patch_short(patch, off)
    return buffer.readi16(patch.buffer, patch.offset + off)
end

-- STlib_init
function st_lib.STlib_init()
    sttminus = w_wad.W_CacheLumpName(deh_str.DEH_String("STTMINUS"), z_zone.PU_STATIC)
end

-- ---------------------------------------------------------------------------
-- Number widget
-- ---------------------------------------------------------------------------

function st_lib.STlib_initNum(n, x, y, pl, num, on, width)
    n.x = x
    n.y = y
    n.oldnum = 0
    n.width = width
    n.num = num
    n.on = on
    n.p = pl
    n.data = 0
end

-- A fairly efficient way to draw a number based on differences from the
-- old number. (Note: worth the trouble?)
function st_lib.STlib_drawNum(n, refresh)
    local numdigits = n.width
    local num = n.num()
    local w = patch_short(n.p[1], 0)
    local h = patch_short(n.p[1], 2)
    local x = n.x
    local neg

    n.oldnum = n.num()

    neg = num < 0
    if neg then
        if numdigits == 2 and num < -9 then
            num = -9
        elseif numdigits == 3 and num < -99 then
            num = -99
        end
        num = -num
    end

    -- Clear the area.
    x = n.x - numdigits * w
    if n.y - st_lib.ST_Y < 0 then
        i_system.I_Error("drawNum: n->y - ST_Y < 0")
    end

    v_video.V_CopyRect(x, n.y - st_lib.ST_Y,
        { buffer = st_lib.st_backing_screen, offset = 0 },
        w * numdigits, h, x, n.y)

    -- If non-number, do not draw it.
    if num == 1994 then
        return
    end

    x = n.x

    -- In the special case of 0, you draw 0.
    if num == 0 then
        v_video.V_DrawPatch(x - w, n.y, n.p[1])
    end

    -- Draw the new number.
    while num ~= 0 and numdigits > 0 do
        numdigits = numdigits - 1
        x = x - w
        v_video.V_DrawPatch(x, n.y, n.p[num % 10 + 1])
        num = num // 10
    end

    -- Draw a minus sign if necessary.
    if neg then
        v_video.V_DrawPatch(x - 8, n.y, sttminus)
    end
end

function st_lib.STlib_updateNum(n, refresh)
    if n.on() then
        st_lib.STlib_drawNum(n, refresh)
    end
end

-- ---------------------------------------------------------------------------
-- Percent widget
-- ---------------------------------------------------------------------------

function st_lib.STlib_initPercent(p, x, y, pl, num, on, percent)
    p.n = {}
    st_lib.STlib_initNum(p.n, x, y, pl, num, on, 3)
    p.p = percent
end

function st_lib.STlib_updatePercent(per, refresh)
    if refresh and per.n.on() then
        v_video.V_DrawPatch(per.n.x, per.n.y, per.p)
    end
    st_lib.STlib_updateNum(per.n, refresh)
end

-- ---------------------------------------------------------------------------
-- Multiple Icon widget
-- ---------------------------------------------------------------------------

function st_lib.STlib_initMultIcon(i, x, y, il, inum, on)
    i.x = x
    i.y = y
    i.oldinum = -1
    i.inum = inum
    i.on = on
    i.p = il
    i.data = 0
end

function st_lib.STlib_updateMultIcon(mi, refresh)
    local inum = mi.inum()
    if mi.on() and (mi.oldinum ~= inum or refresh) and inum ~= -1 then
        if mi.oldinum ~= -1 then
            local old = mi.p[mi.oldinum + 1]
            local x = mi.x - patch_short(old, 4) -- leftoffset
            local y = mi.y - patch_short(old, 6) -- topoffset
            local w = patch_short(old, 0)
            local h = patch_short(old, 2)

            if y - st_lib.ST_Y < 0 then
                i_system.I_Error("updateMultIcon: y - ST_Y < 0")
            end

            v_video.V_CopyRect(x, y - st_lib.ST_Y,
                { buffer = st_lib.st_backing_screen, offset = 0 },
                w, h, x, y)
        end
        v_video.V_DrawPatch(mi.x, mi.y, mi.p[inum + 1])
        mi.oldinum = inum
    end
end

-- ---------------------------------------------------------------------------
-- Binary Icon widget
-- ---------------------------------------------------------------------------

function st_lib.STlib_initBinIcon(b, x, y, i, val, on)
    b.x = x
    b.y = y
    b.oldval = false
    b.val = val
    b.on = on
    b.p = i
    b.data = 0
end

function st_lib.STlib_updateBinIcon(bi, refresh)
    local val = bi.val()
    if bi.on() and (bi.oldval ~= val or refresh) then
        local x = bi.x - patch_short(bi.p, 4)
        local y = bi.y - patch_short(bi.p, 6)
        local w = patch_short(bi.p, 0)
        local h = patch_short(bi.p, 2)

        if y - st_lib.ST_Y < 0 then
            i_system.I_Error("updateBinIcon: y - ST_Y < 0")
        end

        if val then
            v_video.V_DrawPatch(bi.x, bi.y, bi.p)
        else
            v_video.V_CopyRect(x, y - st_lib.ST_Y,
                { buffer = st_lib.st_backing_screen, offset = 0 },
                w, h, x, y)
        end
        bi.oldval = val
    end
end

return st_lib