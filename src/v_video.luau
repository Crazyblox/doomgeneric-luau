--!native
--!optimize 2
local i_video = require("./i_video")
local m_bbox = require("./m_bbox")
local i_system = require("./i_system")

local v_video = {}

local SCREENWIDTH = 320
local SCREENHEIGHT = 200

-- The screen buffer that the v_video.c code draws to. Set by V_UseBuffer;
-- V_RestoreBuffer points it back at i_video.I_VideoBuffer.
local dest_screen = nil

-- Blending tables (Heretic/Strife only). Not used by Doom; kept as nil.
v_video.tinttable = nil
v_video.xlatab = nil

-- Update box (only tracked when drawing to I_VideoBuffer).
v_video.dirtybox = { 0, 0, 0, 0 }

-- Patch clip callback (Chocolate Strife). Unused in this port.
v_video.patchclip_callback = nil

-- ---------------------------------------------------------------------------
-- Patch header accessors (little-endian).
-- ---------------------------------------------------------------------------

local function patch_short(patch, off)
    return buffer.readi16(patch.buffer, patch.offset + off)
end

local function patch_long(patch, off)
    return buffer.readi32(patch.buffer, patch.offset + off)
end

-- ---------------------------------------------------------------------------
-- V_MarkRect
-- ---------------------------------------------------------------------------

function v_video.V_MarkRect(x, y, width, height)
    -- If we are temporarily using an alternate screen, do not affect the
    -- update box.
    if dest_screen == i_video.I_VideoBuffer then
        m_bbox.M_AddToBox(v_video.dirtybox, x, y)
        m_bbox.M_AddToBox(v_video.dirtybox, x + width - 1, y + height - 1)
    end
end

-- ---------------------------------------------------------------------------
-- V_CopyRect
-- ---------------------------------------------------------------------------

function v_video.V_CopyRect(srcx, srcy, source, width, height, destx, desty)
    if srcx < 0 or srcx + width > SCREENWIDTH
        or srcy < 0 or srcy + height > SCREENHEIGHT
        or destx < 0 or destx + width > SCREENWIDTH
        or desty < 0 or desty + height > SCREENHEIGHT then
        i_system.I_Error("Bad V_CopyRect")
    end

    v_video.V_MarkRect(destx, desty, width, height)

    -- Source here is a (buffer, byte-offset) pair: { buffer, offset }.
    -- dest_screen is the target buffer; dest is a byte offset into it.
    local src_buf = source.buffer
    local src = source.offset + SCREENWIDTH * srcy + srcx
    local dest = SCREENWIDTH * desty + destx

    for _ = 1, height do
        buffer.copy(dest_screen, dest, src_buf, src, width)
        src = src + SCREENWIDTH
        dest = dest + SCREENWIDTH
    end
end

-- V_SetPatchClipCallback: unused in this port.
function v_video.V_SetPatchClipCallback(func)
    v_video.patchclip_callback = func
end

-- ---------------------------------------------------------------------------
-- V_DrawPatch
-- Masks a column based masked pic to the screen.
-- ---------------------------------------------------------------------------

function v_video.V_DrawPatch(x, y, patch)
    y = y - patch_short(patch, 6) -- topoffset
    x = x - patch_short(patch, 4) -- leftoffset

    if v_video.patchclip_callback ~= nil then
        if not v_video.patchclip_callback(patch, x, y) then
            return
        end
    end

    local width = patch_short(patch, 0)
    local height = patch_short(patch, 2)
    if x < 0 or x + width > SCREENWIDTH
        or y < 0 or y + height > SCREENHEIGHT then
        i_system.I_Error(
            "Bad V_DrawPatch x=%i y=%i patch.width=%i patch.height=%i topoffset=%i leftoffset=%i",
            x, y, width, height, patch_short(patch, 6), patch_short(patch, 4))
    end

    v_video.V_MarkRect(x, y, width, height)

    local buf = patch.buffer
    local base = patch.offset
    local desttop = y * SCREENWIDTH + x

    for col = 0, width - 1 do
        -- column = (byte *)patch + LONG(patch->columnofs[col])
        local column = base + patch_long(patch, 8 + col * 4)

        -- step through the posts in a column
        while buffer.readu8(buf, column) ~= 0xff do
            local source = column + 3
            local dest = desttop + buffer.readu8(buf, column) * SCREENWIDTH
            local count = buffer.readu8(buf, column + 1)

            while count > 0 do
                buffer.writeu8(dest_screen, dest, buffer.readu8(buf, source))
                dest = dest + SCREENWIDTH
                source = source + 1
                count = count - 1
            end
            column = column + buffer.readu8(buf, column + 1) + 4
        end
        desttop = desttop + 1
    end
end

-- ---------------------------------------------------------------------------
-- V_DrawPatchFlipped
-- Masks a column based masked pic to the screen, flipped horizontally.
-- ---------------------------------------------------------------------------

function v_video.V_DrawPatchFlipped(x, y, patch)
    y = y - patch_short(patch, 6) -- topoffset
    x = x - patch_short(patch, 4) -- leftoffset

    if v_video.patchclip_callback ~= nil then
        if not v_video.patchclip_callback(patch, x, y) then
            return
        end
    end

    local width = patch_short(patch, 0)
    local height = patch_short(patch, 2)
    if x < 0 or x + width > SCREENWIDTH
        or y < 0 or y + height > SCREENHEIGHT then
        i_system.I_Error("Bad V_DrawPatchFlipped")
    end

    v_video.V_MarkRect(x, y, width, height)

    local buf = patch.buffer
    local base = patch.offset
    local desttop = y * SCREENWIDTH + x

    for col = 0, width - 1 do
        -- column = (byte *)patch + LONG(patch->columnofs[w-1-col])
        local column = base + patch_long(patch, 8 + (width - 1 - col) * 4)

        while buffer.readu8(buf, column) ~= 0xff do
            local source = column + 3
            local dest = desttop + buffer.readu8(buf, column) * SCREENWIDTH
            local count = buffer.readu8(buf, column + 1)

            while count > 0 do
                buffer.writeu8(dest_screen, dest, buffer.readu8(buf, source))
                dest = dest + SCREENWIDTH
                source = source + 1
                count = count - 1
            end
            column = column + buffer.readu8(buf, column + 1) + 4
        end
        desttop = desttop + 1
    end
end

-- V_DrawPatchDirect: draws directly to the screen (same as V_DrawPatch).
function v_video.V_DrawPatchDirect(x, y, patch)
    v_video.V_DrawPatch(x, y, patch)
end

-- ---------------------------------------------------------------------------
-- Translucent / shadowed patches (Heretic/Strife). Not used by Doom; the
-- tinttable path is kept for parity but tinttable is nil in this port.
-- ---------------------------------------------------------------------------

local function draw_tl_patch(x, y, patch, table_name)
    y = y - patch_short(patch, 6)
    x = x - patch_short(patch, 4)

    local width = patch_short(patch, 0)
    local height = patch_short(patch, 2)
    if x < 0 or x + width > SCREENWIDTH
        or y < 0 or y + height > SCREENHEIGHT then
        i_system.I_Error("Bad V_DrawTLPatch")
    end

    local buf = patch.buffer
    local base = patch.offset
    local desttop = y * SCREENWIDTH + x

    for col = 0, width - 1 do
        local column = base + patch_long(patch, 8 + col * 4)

        while buffer.readu8(buf, column) ~= 0xff do
            local source = column + 3
            local dest = desttop + buffer.readu8(buf, column) * SCREENWIDTH
            local count = buffer.readu8(buf, column + 1)

            while count > 0 do
                local src = buffer.readu8(buf, source)
                buffer.writeu8(dest_screen, dest,
                    v_video.tinttable[bit32.lshift(buffer.readu8(dest_screen, dest), 8) + src + 1])
                dest = dest + SCREENWIDTH
                source = source + 1
                count = count - 1
            end
            column = column + buffer.readu8(buf, column + 1) + 4
        end
        desttop = desttop + 1
    end
end

function v_video.V_DrawTLPatch(x, y, patch)
    draw_tl_patch(x, y, patch, "tinttable")
end

function v_video.V_DrawAltTLPatch(x, y, patch)
    draw_tl_patch(x, y, patch, "tinttable")
end

function v_video.V_DrawXlaPatch(x, y, patch)
    y = y - patch_short(patch, 6)
    x = x - patch_short(patch, 4)

    if v_video.patchclip_callback ~= nil then
        if not v_video.patchclip_callback(patch, x, y) then
            return
        end
    end

    local width = patch_short(patch, 0)
    local height = patch_short(patch, 2)
    if x < 0 or x + width > SCREENWIDTH
        or y < 0 or y + height > SCREENHEIGHT then
        i_system.I_Error("Bad V_DrawXlaPatch")
    end

    local buf = patch.buffer
    local base = patch.offset
    local desttop = y * SCREENWIDTH + x

    for col = 0, width - 1 do
        local column = base + patch_long(patch, 8 + col * 4)

        while buffer.readu8(buf, column) ~= 0xff do
            local source = column + 3
            local dest = desttop + buffer.readu8(buf, column) * SCREENWIDTH
            local count = buffer.readu8(buf, column + 1)

            while count > 0 do
                local src = buffer.readu8(buf, source)
                buffer.writeu8(dest_screen, dest,
                    v_video.xlatab[buffer.readu8(dest_screen, dest) + bit32.lshift(src, 8) + 1])
                source = source + 1
                dest = dest + SCREENWIDTH
                count = count - 1
            end
            column = column + buffer.readu8(buf, column + 1) + 4
        end
        desttop = desttop + 1
    end
end

function v_video.V_DrawShadowedPatch(x, y, patch)
    y = y - patch_short(patch, 6)
    x = x - patch_short(patch, 4)

    local width = patch_short(patch, 0)
    local height = patch_short(patch, 2)
    if x < 0 or x + width > SCREENWIDTH
        or y < 0 or y + height > SCREENHEIGHT then
        i_system.I_Error("Bad V_DrawShadowedPatch")
    end

    local buf = patch.buffer
    local base = patch.offset
    local desttop = y * SCREENWIDTH + x
    local desttop2 = (y + 2) * SCREENWIDTH + x + 2

    for col = 0, width - 1 do
        local column = base + patch_long(patch, 8 + col * 4)

        while buffer.readu8(buf, column) ~= 0xff do
            local source = column + 3
            local dest = desttop + buffer.readu8(buf, column) * SCREENWIDTH
            local dest2 = desttop2 + buffer.readu8(buf, column) * SCREENWIDTH
            local count = buffer.readu8(buf, column + 1)

            while count > 0 do
                buffer.writeu8(dest_screen, dest2,
                    v_video.tinttable[bit32.lshift(buffer.readu8(dest_screen, dest2), 8) + 1])
                dest2 = dest2 + SCREENWIDTH
                buffer.writeu8(dest_screen, dest, buffer.readu8(buf, source))
                dest = dest + SCREENWIDTH
                source = source + 1
                count = count - 1
            end
            column = column + buffer.readu8(buf, column + 1) + 4
        end
        desttop = desttop + 1
        desttop2 = desttop2 + 1
    end
end

-- V_LoadTintTable / V_LoadXlaTable (Heretic/Strife).
function v_video.V_LoadTintTable()
    v_video.tinttable = i_video.I_VideoBuffer -- placeholder; not used by Doom
end

function v_video.V_LoadXlaTable()
    v_video.xlatab = i_video.I_VideoBuffer
end

-- ---------------------------------------------------------------------------
-- V_DrawBlock: draw a linear block of pixels into the view buffer.
-- ---------------------------------------------------------------------------

function v_video.V_DrawBlock(x, y, width, height, src)
    if x < 0 or x + width > SCREENWIDTH
        or y < 0 or y + height > SCREENHEIGHT then
        i_system.I_Error("Bad V_DrawBlock")
    end

    v_video.V_MarkRect(x, y, width, height)

    local dest = y * SCREENWIDTH + x
    local src_buf = src.buffer
    local src_off = src.offset

    for _ = 1, height do
        buffer.copy(dest_screen, dest, src_buf, src_off, width)
        src_off = src_off + width
        dest = dest + SCREENWIDTH
    end
end

-- ---------------------------------------------------------------------------
-- Filled box / line drawing primitives (used by menus / HUD later).
-- ---------------------------------------------------------------------------

function v_video.V_DrawFilledBox(x, y, w, h, c)
    local buf = SCREENWIDTH * y + x
    for _ = 1, h do
        local b = buf
        for _ = 1, w do
            buffer.writeu8(dest_screen, b, c)
            b = b + 1
        end
        buf = buf + SCREENWIDTH
    end
end

function v_video.V_DrawHorizLine(x, y, w, c)
    local buf = SCREENWIDTH * y + x
    for _ = 1, w do
        buffer.writeu8(dest_screen, buf, c)
        buf = buf + 1
    end
end

function v_video.V_DrawVertLine(x, y, h, c)
    local buf = SCREENWIDTH * y + x
    for _ = 1, h do
        buffer.writeu8(dest_screen, buf, c)
        buf = buf + SCREENWIDTH
    end
end

function v_video.V_DrawBox(x, y, w, h, c)
    v_video.V_DrawHorizLine(x, y, w, c)
    v_video.V_DrawHorizLine(x, y + h - 1, w, c)
    v_video.V_DrawVertLine(x, y, h, c)
    v_video.V_DrawVertLine(x + w - 1, y, h, c)
end

-- V_DrawRawScreen: blit a raw 320x200 lump directly to the screen.
function v_video.V_DrawRawScreen(raw)
    buffer.copy(dest_screen, 0, raw.buffer, raw.offset,
        SCREENWIDTH * SCREENHEIGHT)
end

-- ---------------------------------------------------------------------------
-- V_DrawMouseSpeedBox: box showing the current mouse speed (testcontrols).
-- Mirrors the C v_video.c. `usemouse` defaults to 0 in this port (no mouse
-- is wired), so the box is normally not drawn.
-- ---------------------------------------------------------------------------

local MOUSE_SPEED_BOX_WIDTH = 120
local MOUSE_SPEED_BOX_HEIGHT = 9

function v_video.V_DrawMouseSpeedBox(speed)
    local bgcolor, bordercolor, red, black, white, yellow
    local box_x, box_y
    local original_speed
    local redline_x
    local linelen

    -- Get palette indices for colors for widget. These depend on the
    -- palette of the game being played.
    bgcolor = i_video.I_GetPaletteIndex(0x77, 0x77, 0x77)
    bordercolor = i_video.I_GetPaletteIndex(0x55, 0x55, 0x55)
    red = i_video.I_GetPaletteIndex(0xff, 0x00, 0x00)
    black = i_video.I_GetPaletteIndex(0x00, 0x00, 0x00)
    yellow = i_video.I_GetPaletteIndex(0xff, 0xff, 0x00)
    white = i_video.I_GetPaletteIndex(0xff, 0xff, 0xff)

    -- If the mouse is turned off or acceleration is turned off, don't draw
    -- the box at all.
    if i_video.usemouse == 0
        or math.abs(i_video.mouse_acceleration - 1) < 0.01 then
        return
    end

    -- Calculate box position.
    box_x = SCREENWIDTH - MOUSE_SPEED_BOX_WIDTH - 10
    box_y = 15

    v_video.V_DrawFilledBox(box_x, box_y,
        MOUSE_SPEED_BOX_WIDTH, MOUSE_SPEED_BOX_HEIGHT, bgcolor)
    v_video.V_DrawBox(box_x, box_y,
        MOUSE_SPEED_BOX_WIDTH, MOUSE_SPEED_BOX_HEIGHT, bordercolor)

    -- Calculate the position of the red line. This is 1/3 of the way along
    -- the box.
    redline_x = MOUSE_SPEED_BOX_WIDTH // 3

    -- Undo acceleration and get back the original mouse speed.
    if speed < i_video.mouse_threshold then
        original_speed = speed
    else
        original_speed = speed - i_video.mouse_threshold
        original_speed = math.floor(original_speed / i_video.mouse_acceleration)
        original_speed = original_speed + i_video.mouse_threshold
    end

    -- Calculate line length.
    linelen = (original_speed * redline_x) // i_video.mouse_threshold

    -- Draw horizontal "thermometer".
    if linelen > MOUSE_SPEED_BOX_WIDTH - 1 then
        linelen = MOUSE_SPEED_BOX_WIDTH - 1
    end

    v_video.V_DrawHorizLine(box_x + 1, box_y + 4, MOUSE_SPEED_BOX_WIDTH - 2, black)

    if linelen < redline_x then
        v_video.V_DrawHorizLine(box_x + 1, box_y + MOUSE_SPEED_BOX_HEIGHT // 2,
            linelen, white)
    else
        v_video.V_DrawHorizLine(box_x + 1, box_y + MOUSE_SPEED_BOX_HEIGHT // 2,
            redline_x, white)
        v_video.V_DrawHorizLine(box_x + redline_x, box_y + MOUSE_SPEED_BOX_HEIGHT // 2,
            linelen - redline_x, yellow)
    end

    -- Draw red line.
    v_video.V_DrawVertLine(box_x + redline_x, box_y + 1,
        MOUSE_SPEED_BOX_HEIGHT - 2, red)
end

-- ---------------------------------------------------------------------------
-- Buffer management
-- ---------------------------------------------------------------------------

-- V_Init: no-op (screens handled in the upper layers).
function v_video.V_Init()
end

-- V_UseBuffer: set the buffer that drawing code targets.
function v_video.V_UseBuffer(buffer)
    dest_screen = buffer
end

-- V_RestoreBuffer: restore the drawing target to the i_video screen buffer.
function v_video.V_RestoreBuffer()
    dest_screen = i_video.I_VideoBuffer
end

-- V_GetScreenBuffer (port helper): current drawing target.
function v_video.V_GetScreenBuffer()
    return dest_screen
end

return v_video