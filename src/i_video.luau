--!native
--!optimize 2
local doomtype = require("./doomtype")
local z_zone = require("./z_zone")
local tables = require("./tables")
local platform = require("./platform")
local i_input = require("./i_input")
local i_video = {}

i_video.SCREENWIDTH = doomtype.SCREENWIDTH
i_video.SCREENHEIGHT = doomtype.SCREENHEIGHT

-- The screen buffer; this is modified to draw things to the screen.
i_video.I_VideoBuffer = nil

-- Gamma correction level to use.
i_video.usegamma = 0

-- Mouse options (i_video.c globals). `usemouse` defaults to 0 in this
-- port (no mouse is wired), so the testcontrols mouse-speed box is off.
i_video.usemouse = 0
i_video.mouse_acceleration = 2.0
i_video.mouse_threshold = 10

-- Flag indicating whether the screen is currently visible.
i_video.screenvisible = false

-- The 32bpp framebuffer the host displays. Allocated by DoomGeneric.Create
-- and injected here to avoid a module cycle.
local DG_ScreenBuffer = nil

-- Set the output framebuffer (called by DoomGeneric.Create).
function i_video.SetScreenBuffer(buf)
    DG_ScreenBuffer = buf
end

-- Current palette, gamma-corrected: colors[i] = { r, g, b }.
local colors = {}

-- Precomputed RGBA8888 packing for each palette index.
-- Packed little-endian u32 = (A<<24)|(B<<16)|(G<<8)|R  => bytes [R,G,B,A].
-- The C's colors[] array is zero-initialized and only filled by I_SetPalette;
-- a level that starts before any palette change (e.g. -playdemo) renders
-- with the default palette, so seed the LUT with black (A=255, RGB=0).
local rgba_pack = {}
for i = 0, 255 do
    rgba_pack[i] = 255 * 2 ^ 24 -- black, opaque
end

-- I_InitGraphics: allocate the 8-bit video buffer and mark screen visible.
function i_video.I_InitGraphics()
    i_video.I_VideoBuffer = z_zone.Z_Malloc(
        i_video.SCREENWIDTH * i_video.SCREENHEIGHT, z_zone.PU_STATIC, nil)
    i_video.screenvisible = true
end

function i_video.I_ShutdownGraphics()
    i_video.I_VideoBuffer = nil
    i_video.screenvisible = false
end

function i_video.I_StartFrame()
end

-- I_StartTic: called once per tic by the main loop (d_loop.BuildNewTic).
-- The C i_video.c I_StartTic calls I_GetEvent() to drain the platform key
-- queue into Doom events. (Phase 4d wires the input path; the other
-- per-frame hooks I_StartFrame/I_UpdateNoBlit are no-ops in this port.)
function i_video.I_StartTic()
    i_input.I_GetEvent()
end

function i_video.I_UpdateNoBlit()
end

-- I_SetPalette: read 256 RGB entries from `paletteBuf` at `offset` and apply
-- the gamma table. (C: colors[i] = gammatable[usegamma][*palette++]; a = 0.)
function i_video.I_SetPalette(paletteBuf, offset)
    offset = offset or 0
    local gamma = tables.gammatable[i_video.usegamma + 1]

    for i = 0, 255 do
        local base = offset + i * 3
        local r = gamma[buffer.readu8(paletteBuf, base) + 1]
        local g = gamma[buffer.readu8(paletteBuf, base + 1) + 1]
        local b = gamma[buffer.readu8(paletteBuf, base + 2) + 1]
        colors[i] = { r = r, g = g, b = b }

        -- Pack RGBA8888 little-endian: bytes [R, G, B, A=255].
        -- Plain arithmetic is exact (< 2^32) and matches the bitwise OR;
        -- kept as arithmetic so it runs on pre-bitwise-operator Luau too.
        rgba_pack[i] = 255 * 2 ^ 24 + b * 2 ^ 16 + g * 2 ^ 8 + r
    end
end

-- Given an RGB value, find the closest matching palette index.
function i_video.I_GetPaletteIndex(r, g, b)
    local best = 0
    local best_diff = math.huge
    for i = 0, 255 do
        local c = colors[i]
        local diff = (r - c.r) * (r - c.r)
            + (g - c.g) * (g - c.g)
            + (b - c.b) * (b - c.b)
        if diff < best_diff then
            best = i
            best_diff = diff
        end
        if diff == 0 then
            break
        end
    end
    return best
end

-- I_FinishUpdate: convert I_VideoBuffer (320x200 8-bit) to DG_ScreenBuffer
-- (DOOMGENERIC_RESX x DOOMGENERIC_RESY RGBA8888) and draw the frame.
function i_video.I_FinishUpdate()
    local resx = doomtype.DOOMGENERIC_RESX
    local resy = doomtype.DOOMGENERIC_RESY

    -- Auto-scaling factor (C integer division).
    local fb_scaling = resx // i_video.SCREENWIDTH
    if resy // i_video.SCREENHEIGHT < fb_scaling then
        fb_scaling = resy // i_video.SCREENHEIGHT
    end
    if fb_scaling < 1 then
        fb_scaling = 1
    end

    -- Offsets in bytes in case the framebuffer is bigger than DOOM.
    local y_offset = ((resy - i_video.SCREENHEIGHT * fb_scaling) * 4) // 2
    local x_offset = ((resx - i_video.SCREENWIDTH * fb_scaling) * 4) // 2
    -- (x_offset_end = (resx - SCREENWIDTH*fb_scaling)*4 - x_offset is the
    -- right-edge padding; the buffer is zero-filled so nothing is written
    -- there, matching C for the default 640x400.)

    local in_buf = i_video.I_VideoBuffer
    local out_buf = DG_ScreenBuffer
    local row_bytes = i_video.SCREENWIDTH * fb_scaling * 4
    local out_pitch = resx * 4

    for y = 0, i_video.SCREENHEIGHT - 1 do
        local src_row = y * i_video.SCREENWIDTH
        local dst_row = y_offset + y * fb_scaling * out_pitch + x_offset

        -- Horizontal scaling: write fb_scaling u32 copies per source pixel.
        for x = 0, i_video.SCREENWIDTH - 1 do
            local pack = rgba_pack[buffer.readu8(in_buf, src_row + x)]
            local p = dst_row + x * fb_scaling * 4
            for k = 0, fb_scaling - 1 do
                buffer.writeu32(out_buf, p + k * 4, pack)
            end
        end

        -- Vertical scaling: duplicate the row fb_scaling times.
        for k = 1, fb_scaling - 1 do
            local dst2 = dst_row + k * out_pitch
            buffer.copy(out_buf, dst2, out_buf, dst_row, row_bytes)
        end

        -- x_offset_end is the right-edge padding; the buffer is zero-filled
        -- so nothing needs to be written there (matches C for 640x400).
        -- (kept as a named value for parity with the C offsets math)
    end

    platform.DrawFrame()
end

-- I_ReadScreen: copy the 8-bit video buffer.
function i_video.I_ReadScreen(scr)
    buffer.copy(scr, 0, i_video.I_VideoBuffer, 0,
        i_video.SCREENWIDTH * i_video.SCREENHEIGHT)
end

function i_video.I_BeginRead()
end

function i_video.I_EndRead()
end

function i_video.I_SetWindowTitle(title)
    platform.SetWindowTitle(title)
end

function i_video.I_GraphicsCheckCommandLine()
end

function i_video.I_SetGrabMouseCallback()
end

function i_video.I_EnableLoadingDisk()
end

function i_video.I_BindVideoVariables()
end

function i_video.I_DisplayFPSDots()
end

function i_video.I_CheckIsScreensaver()
end

function i_video.I_InitWindowTitle()
end

function i_video.I_InitWindowIcon()
end

return i_video