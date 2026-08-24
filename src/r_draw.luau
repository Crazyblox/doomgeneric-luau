--!native
--!optimize 2
local deh_str = require("./deh_str")
local doomstat = require("./doomstat")
local r_state = require("./r_state")
local v_video = require("./v_video")
local i_video = require("./i_video")
local z_zone = require("./z_zone")
local w_wad = require("./w_wad")

local r_draw = {}

local SCREENWIDTH = 320
local SCREENHEIGHT = 200
local SBARHEIGHT = 32

local MAXWIDTH = 1120
local MAXHEIGHT = 832

-- Backing buffer containing the bezel drawn around the screen and the
-- surrounding background.
local background_buffer = nil

-- ---------------------------------------------------------------------------
-- R_DrawColumn
-- ---------------------------------------------------------------------------

function r_draw.R_DrawColumn()
    local S = r_state
    local count = S.dc_yh - S.dc_yl

    -- Zero length, column does not exceed a pixel.
    if count < 0 then
        return
    end

    local dest = S.ylookup[S.dc_yl + 1] + S.columnofs[S.dc_x + 1]

    local fracstep = S.dc_iscale
    local frac = S.dc_texturemid + (S.dc_yl - S.centery) * fracstep

    local src = S.dc_source
    local src_buf = src.buffer
    local src_off = src.offset
    local cmap = S.dc_colormap
    local cmap_buf = S.colormaps.buffer
    local target = i_video.I_VideoBuffer

    -- C do { ... } while (count--);  => count+1 iterations.
    local n = count + 1
    for _ = 1, n do
        -- Re-map color indices from the wall texture column using the
        -- lighting/special-effects LUT.
        local idx = (frac // 65536) % 128
        buffer.writeu8(target, dest,
            buffer.readu8(cmap_buf, cmap + buffer.readu8(src_buf, src_off + idx)))
        dest = dest + SCREENWIDTH
        frac = frac + fracstep
    end
end

-- ---------------------------------------------------------------------------
-- R_DrawColumnLow (blocky/low detail mode)
-- ---------------------------------------------------------------------------

function r_draw.R_DrawColumnLow()
    local S = r_state
    local count = S.dc_yh - S.dc_yl

    if count < 0 then
        return
    end

    -- Blocky mode, need to multiply by 2.
    local x = S.dc_x * 2

    local dest = S.ylookup[S.dc_yl + 1] + S.columnofs[x + 1]
    local dest2 = S.ylookup[S.dc_yl + 1] + S.columnofs[x + 2]

    local fracstep = S.dc_iscale
    local frac = S.dc_texturemid + (S.dc_yl - S.centery) * fracstep

    local src = S.dc_source
    local src_buf = src.buffer
    local src_off = src.offset
    local cmap = S.dc_colormap
    local cmap_buf = S.colormaps.buffer
    local target = i_video.I_VideoBuffer

    local n = count + 1
    for _ = 1, n do
        -- Hack. Does not work correctly.
        local val = buffer.readu8(cmap_buf,
            cmap + buffer.readu8(src_buf, src_off + ((frac // 65536) % 128)))
        buffer.writeu8(target, dest2, val)
        buffer.writeu8(target, dest, val)
        dest = dest + SCREENWIDTH
        dest2 = dest2 + SCREENWIDTH
        frac = frac + fracstep
    end
end

-- ---------------------------------------------------------------------------
-- Spectre / invisibility (fuzz effect)
-- ---------------------------------------------------------------------------

local FUZZTABLE = 50
local FUZZOFF = SCREENWIDTH

local fuzzoffset = {
    FUZZOFF, -FUZZOFF, FUZZOFF, -FUZZOFF, FUZZOFF, FUZZOFF, -FUZZOFF,
    FUZZOFF, FUZZOFF, -FUZZOFF, FUZZOFF, FUZZOFF, FUZZOFF, -FUZZOFF,
    FUZZOFF, FUZZOFF, FUZZOFF, -FUZZOFF, -FUZZOFF, -FUZZOFF, -FUZZOFF,
    FUZZOFF, -FUZZOFF, -FUZZOFF, FUZZOFF, FUZZOFF, FUZZOFF, FUZZOFF, -FUZZOFF,
    FUZZOFF, -FUZZOFF, FUZZOFF, FUZZOFF, -FUZZOFF, -FUZZOFF, FUZZOFF,
    FUZZOFF, -FUZZOFF, -FUZZOFF, -FUZZOFF, -FUZZOFF, FUZZOFF, FUZZOFF,
    FUZZOFF, FUZZOFF, -FUZZOFF, FUZZOFF, FUZZOFF, -FUZZOFF, FUZZOFF,
}

local fuzzpos = 0

-- Framebuffer postprocessing: creates a fuzzy image by copying pixels from
-- adjacent ones to left and right, using the all-black colormap #6.
function r_draw.R_DrawFuzzColumn()
    local S = r_state

    -- Adjust borders. Low...
    if S.dc_yl == 0 then
        S.dc_yl = 1
    end

    -- .. and high.
    if S.dc_yh == S.viewheight - 1 then
        S.dc_yh = S.viewheight - 2
    end

    local count = S.dc_yh - S.dc_yl

    if count < 0 then
        return
    end

    local dest = S.ylookup[S.dc_yl + 1] + S.columnofs[S.dc_x + 1]

    local fracstep = S.dc_iscale
    local frac = S.dc_texturemid + (S.dc_yl - S.centery) * fracstep

    local cmap = S.colormaps.offset + 6 * 256
    local cmap_buf = S.colormaps.buffer
    local target = i_video.I_VideoBuffer

    local n = count + 1
    for _ = 1, n do
        -- Lookup framebuffer, and retrieve a pixel that is either one column
        -- left or right of the current one. Add index from colormap to index.
        buffer.writeu8(target, dest,
            buffer.readu8(cmap_buf,
                cmap + buffer.readu8(target, dest + fuzzoffset[fuzzpos + 1])))

        -- Clamp table lookup index.
        fuzzpos = fuzzpos + 1
        if fuzzpos == FUZZTABLE then
            fuzzpos = 0
        end

        dest = dest + SCREENWIDTH
        frac = frac + fracstep
    end
end

function r_draw.R_DrawFuzzColumnLow()
    local S = r_state

    if S.dc_yl == 0 then
        S.dc_yl = 1
    end

    if S.dc_yh == S.viewheight - 1 then
        S.dc_yh = S.viewheight - 2
    end

    local count = S.dc_yh - S.dc_yl

    if count < 0 then
        return
    end

    -- Low detail mode, need to multiply by 2.
    local x = S.dc_x * 2

    local dest = S.ylookup[S.dc_yl + 1] + S.columnofs[x + 1]
    local dest2 = S.ylookup[S.dc_yl + 1] + S.columnofs[x + 2]

    local fracstep = S.dc_iscale
    local frac = S.dc_texturemid + (S.dc_yl - S.centery) * fracstep

    local cmap = S.colormaps.offset + 6 * 256
    local cmap_buf = S.colormaps.buffer
    local target = i_video.I_VideoBuffer

    local n = count + 1
    for _ = 1, n do
        local val = buffer.readu8(cmap_buf,
            cmap + buffer.readu8(target, dest + fuzzoffset[fuzzpos + 1]))
        buffer.writeu8(target, dest2, val)
        buffer.writeu8(target, dest, val)

        fuzzpos = fuzzpos + 1
        if fuzzpos == FUZZTABLE then
            fuzzpos = 0
        end

        dest = dest + SCREENWIDTH
        dest2 = dest2 + SCREENWIDTH
        frac = frac + fracstep
    end
end

-- ---------------------------------------------------------------------------
-- R_DrawTranslatedColumn (player sprite color-ramp translation)
-- ---------------------------------------------------------------------------

function r_draw.R_DrawTranslatedColumn()
    local S = r_state
    local count = S.dc_yh - S.dc_yl

    if count < 0 then
        return
    end

    local dest = S.ylookup[S.dc_yl + 1] + S.columnofs[S.dc_x + 1]

    local fracstep = S.dc_iscale
    local frac = S.dc_texturemid + (S.dc_yl - S.centery) * fracstep

    local src = S.dc_source
    local src_buf = src.buffer
    local src_off = src.offset
    local cmap = S.dc_colormap
    local cmap_buf = S.colormaps.buffer
    local trans = S.dc_translation
    local trans_buf = S.translationtables.buffer
    local target = i_video.I_VideoBuffer

    local n = count + 1
    for _ = 1, n do
        -- Translation tables map certain color ramps to others (PLAY sprites).
        local sval = buffer.readu8(src_buf, src_off + ((frac // 65536) % 128))
        buffer.writeu8(target, dest,
            buffer.readu8(cmap_buf, cmap + buffer.readu8(trans_buf, trans + sval)))
        dest = dest + SCREENWIDTH
        frac = frac + fracstep
    end
end

function r_draw.R_DrawTranslatedColumnLow()
    local S = r_state
    local count = S.dc_yh - S.dc_yl

    if count < 0 then
        return
    end

    local x = S.dc_x * 2

    local dest = S.ylookup[S.dc_yl + 1] + S.columnofs[x + 1]
    local dest2 = S.ylookup[S.dc_yl + 1] + S.columnofs[x + 2]

    local fracstep = S.dc_iscale
    local frac = S.dc_texturemid + (S.dc_yl - S.centery) * fracstep

    local src = S.dc_source
    local src_buf = src.buffer
    local src_off = src.offset
    local cmap = S.dc_colormap
    local cmap_buf = S.colormaps.buffer
    local trans = S.dc_translation
    local trans_buf = S.translationtables.buffer
    local target = i_video.I_VideoBuffer

    local n = count + 1
    for _ = 1, n do
        local sval = buffer.readu8(src_buf, src_off + ((frac // 65536) % 128))
        local val = buffer.readu8(cmap_buf, cmap + buffer.readu8(trans_buf, trans + sval))
        buffer.writeu8(target, dest2, val)
        buffer.writeu8(target, dest, val)
        dest = dest + SCREENWIDTH
        dest2 = dest2 + SCREENWIDTH
        frac = frac + fracstep
    end
end

-- ---------------------------------------------------------------------------
-- R_InitTranslationTables
-- ---------------------------------------------------------------------------

function r_draw.R_InitTranslationTables()
    local buf = z_zone.Z_Malloc(256 * 3, z_zone.PU_STATIC, nil)
    r_state.translationtables = { buffer = buf, offset = 0 }

    -- Translate just the 16 green colors.
    for i = 0, 255 do
        if i >= 0x70 and i <= 0x7f then
            -- Map green ramp to gray, brown, red.
            buffer.writeu8(buf, i, 0x60 + bit32.band(i, 0xf))
            buffer.writeu8(buf, i + 256, 0x40 + bit32.band(i, 0xf))
            buffer.writeu8(buf, i + 512, 0x20 + bit32.band(i, 0xf))
        else
            -- Keep all other colors as is.
            local v = i
            buffer.writeu8(buf, i, v)
            buffer.writeu8(buf, i + 256, v)
            buffer.writeu8(buf, i + 512, v)
        end
    end
end

-- ---------------------------------------------------------------------------
-- R_DrawSpan
-- ---------------------------------------------------------------------------

function r_draw.R_DrawSpan()
    local S = r_state

    -- Pack position and step variables into a single 32-bit integer, with x
    -- in the top 16 bits and y in the bottom 16 bits. For each 16-bit part,
    -- the top 6 bits are the integer part and the bottom 10 bits are the
    -- fractional part of the pixel position.
    local position = bit32.bor(
        -- bit32.band(bit32.lshift(S.ds_xfrac % 0x100000000, 10), 0xffff0000),
        -- bit32.band(bit32.rshift(S.ds_yfrac % 0x100000000, 6), 0x0000ffff))
        bit32.band(bit32.lshift(S.ds_xfrac, 10), 0xffff0000),
        bit32.band(bit32.rshift(S.ds_yfrac, 6), 0x0000ffff))
    local step = bit32.bor(
        -- bit32.band(bit32.lshift(S.ds_xstep % 0x100000000, 10), 0xffff0000),
        -- bit32.band(bit32.rshift(S.ds_ystep % 0x100000000, 6), 0x0000ffff))
        bit32.band(bit32.lshift(S.ds_xstep, 10), 0xffff0000),
        bit32.band(bit32.rshift(S.ds_ystep, 6), 0x0000ffff))

    local dest = S.ylookup[S.ds_y + 1] + S.columnofs[S.ds_x1 + 1]

    -- We do not check for zero spans here.
    local count = S.ds_x2 - S.ds_x1

    local src = S.ds_source
    local src_buf = src.buffer
    local src_off = src.offset
    local cmap = S.ds_colormap
    local cmap_buf = S.colormaps.buffer
    local target = i_video.I_VideoBuffer

    local n = count + 1
    for _ = 1, n do
        -- Calculate current texture index in u,v.
        local ytemp = bit32.band(bit32.rshift(position, 4), 0x0fc0)
        local xtemp = bit32.rshift(position, 26)
        local spot = bit32.bor(xtemp, ytemp)

        -- Lookup pixel from flat texture tile, re-index using light/colormap.
        buffer.writeu8(target, dest,
            buffer.readu8(cmap_buf, cmap + buffer.readu8(src_buf, src_off + spot)))

        position = (position + step) % 0x100000000
        dest = dest + 1
    end
end

-- ---------------------------------------------------------------------------
-- R_DrawSpanLow
-- ---------------------------------------------------------------------------

function r_draw.R_DrawSpanLow()
    local S = r_state

    local position = bit32.bor(
        -- bit32.band(bit32.lshift(S.ds_xfrac % 0x100000000, 10), 0xffff0000),
        -- bit32.band(bit32.rshift(S.ds_yfrac % 0x100000000, 6), 0x0000ffff))
        bit32.band(bit32.lshift(S.ds_xfrac, 10), 0xffff0000),
        bit32.band(bit32.rshift(S.ds_yfrac, 6), 0x0000ffff))
    local step = bit32.bor(
        -- bit32.band(bit32.lshift(S.ds_xstep % 0x100000000, 10), 0xffff0000),
        -- bit32.band(bit32.rshift(S.ds_ystep % 0x100000000, 6), 0x0000ffff))
        bit32.band(bit32.lshift(S.ds_xstep, 10), 0xffff0000),
        bit32.band(bit32.rshift(S.ds_ystep, 6), 0x0000ffff))

    local count = S.ds_x2 - S.ds_x1

    -- Blocky mode, need to multiply by 2.
    local x1 = S.ds_x1 * 2

    local dest = S.ylookup[S.ds_y + 1] + S.columnofs[x1 + 1]

    local src = S.ds_source
    local src_buf = src.buffer
    local src_off = src.offset
    local cmap = S.ds_colormap
    local cmap_buf = S.colormaps.buffer
    local target = i_video.I_VideoBuffer

    local n = count + 1
    for _ = 1, n do
        local ytemp = bit32.band(bit32.rshift(position, 4), 0x0fc0)
        local xtemp = bit32.rshift(position, 26)
        local spot = bit32.bor(xtemp, ytemp)

        -- Lowres/blocky mode does it twice, while scale is adjusted
        -- appropriately.
        local val = buffer.readu8(cmap_buf, cmap + buffer.readu8(src_buf, src_off + spot))
        buffer.writeu8(target, dest, val)
        buffer.writeu8(target, dest + 1, val)

        position = (position + step) % 0x100000000
        dest = dest + 2
    end
end

-- ---------------------------------------------------------------------------
-- R_InitBuffer: build the ylookup/columnofs framebuffer offset LUTs.
-- ---------------------------------------------------------------------------

function r_draw.R_InitBuffer(width, height)
    local S = r_state

    -- Handle resize, e.g. smaller view windows with border and/or status bar.
    S.viewwindowx = (SCREENWIDTH - width) // 2

    -- Column offset, for windows.
    for i = 0, width - 1 do
        S.columnofs[i + 1] = S.viewwindowx + i
    end

    -- Same with base row offset.
    if width == SCREENWIDTH then
        S.viewwindowy = 0
    else
        S.viewwindowy = (SCREENHEIGHT - SBARHEIGHT - height) // 2
    end

    -- Precalculate all row offsets (byte offsets into I_VideoBuffer).
    for i = 0, height - 1 do
        S.ylookup[i + 1] = (i + S.viewwindowy) * SCREENWIDTH
    end

    S.viewimage = i_video.I_VideoBuffer
end

-- ---------------------------------------------------------------------------
-- R_FillBackScreen / R_VideoErase / R_DrawViewBorder
-- ---------------------------------------------------------------------------

function r_draw.R_FillBackScreen()
    local S = r_state

    -- If we are running full screen, there is no need to do any of this, and
    -- the background buffer can be freed if it was previously in use.
    if S.scaledviewwidth == SCREENWIDTH then
        if background_buffer ~= nil then
            background_buffer = nil
        end
        return
    end

    -- Allocate the background buffer if necessary.
    if background_buffer == nil then
        background_buffer = z_zone.Z_Malloc(
            SCREENWIDTH * (SCREENHEIGHT - SBARHEIGHT), z_zone.PU_STATIC, nil)
    end

    local name
    if doomstat.gamemode == 2 then -- commercial
        name = deh_str.DEH_String("GRNROCK")
    else
        name = deh_str.DEH_String("FLOOR7_2")
    end

    local src = w_wad.W_CacheLumpName(name, z_zone.PU_CACHE)
    local dest = 0

    for y = 0, SCREENHEIGHT - SBARHEIGHT - 1 do
        for x = 0, SCREENWIDTH // 64 - 1 do
            buffer.copy(background_buffer, dest, src.buffer, src.offset + bit32.band(y, 63) * 64, 64)
            dest = dest + 64
        end

        if bit32.band(SCREENWIDTH, 63) ~= 0 then
            buffer.copy(background_buffer, dest,
                src.buffer, src.offset + bit32.band(y, 63) * 64,
                bit32.band(SCREENWIDTH, 63))
            dest = dest + bit32.band(SCREENWIDTH, 63)
        end
    end

    -- Draw screen and bezel; this is done to a separate screen buffer.
    v_video.V_UseBuffer(background_buffer)

    local patch = w_wad.W_CacheLumpName(deh_str.DEH_String("brdr_t"), z_zone.PU_CACHE)
    for x = 0, S.scaledviewwidth - 1, 8 do
        v_video.V_DrawPatch(S.viewwindowx + x, S.viewwindowy - 8, patch)
    end
    patch = w_wad.W_CacheLumpName(deh_str.DEH_String("brdr_b"), z_zone.PU_CACHE)
    for x = 0, S.scaledviewwidth - 1, 8 do
        v_video.V_DrawPatch(S.viewwindowx + x, S.viewwindowy + S.viewheight, patch)
    end
    patch = w_wad.W_CacheLumpName(deh_str.DEH_String("brdr_l"), z_zone.PU_CACHE)
    for y = 0, S.viewheight - 1, 8 do
        v_video.V_DrawPatch(S.viewwindowx - 8, S.viewwindowy + y, patch)
    end
    patch = w_wad.W_CacheLumpName(deh_str.DEH_String("brdr_r"), z_zone.PU_CACHE)
    for y = 0, S.viewheight - 1, 8 do
        v_video.V_DrawPatch(S.viewwindowx + S.scaledviewwidth, S.viewwindowy + y, patch)
    end

    -- Draw beveled edge.
    v_video.V_DrawPatch(S.viewwindowx - 8, S.viewwindowy - 8,
        w_wad.W_CacheLumpName(deh_str.DEH_String("brdr_tl"), z_zone.PU_CACHE))
    v_video.V_DrawPatch(S.viewwindowx + S.scaledviewwidth, S.viewwindowy - 8,
        w_wad.W_CacheLumpName(deh_str.DEH_String("brdr_tr"), z_zone.PU_CACHE))
    v_video.V_DrawPatch(S.viewwindowx - 8, S.viewwindowy + S.viewheight,
        w_wad.W_CacheLumpName(deh_str.DEH_String("brdr_bl"), z_zone.PU_CACHE))
    v_video.V_DrawPatch(S.viewwindowx + S.scaledviewwidth, S.viewwindowy + S.viewheight,
        w_wad.W_CacheLumpName(deh_str.DEH_String("brdr_br"), z_zone.PU_CACHE))

    v_video.V_RestoreBuffer()
end

-- Copy a screen buffer region from the background buffer.
function r_draw.R_VideoErase(ofs, count)
    if background_buffer ~= nil then
        buffer.copy(i_video.I_VideoBuffer, ofs, background_buffer, ofs, count)
    end
end

-- Draws the border around the view for different size windows.
function r_draw.R_DrawViewBorder()
    local S = r_state

    if S.scaledviewwidth == SCREENWIDTH then
        return
    end

    local top = ((SCREENHEIGHT - SBARHEIGHT) - S.viewheight) // 2
    local side = (SCREENWIDTH - S.scaledviewwidth) // 2

    -- Copy top and one line of left side.
    r_draw.R_VideoErase(0, top * SCREENWIDTH + side)

    -- Copy one line of right side and bottom.
    local ofs = (S.viewheight + top) * SCREENWIDTH - side
    r_draw.R_VideoErase(ofs, top * SCREENWIDTH + side)

    -- Copy sides using wraparound.
    ofs = top * SCREENWIDTH + SCREENWIDTH - side
    side = side * 2

    for i = 1, S.viewheight - 1 do
        r_draw.R_VideoErase(ofs, side)
        ofs = ofs + SCREENWIDTH
    end

    v_video.V_MarkRect(0, 0, SCREENWIDTH, SCREENHEIGHT - SBARHEIGHT)
end

return r_draw