--!native
--!optimize 2
local doomtype = {}

-- ---------------------------------------------------------------------------
-- Screen sizes (i_video.h)
-- ---------------------------------------------------------------------------

doomtype.SCREENWIDTH = 320
doomtype.SCREENHEIGHT = 200

-- The generic framebuffer resolution. Overridable before requiring:
--   local doomtype = require(...); doomtype.DOOMGENERIC_RESX = 320
doomtype.DOOMGENERIC_RESX = 640
doomtype.DOOMGENERIC_RESY = 400

-- ---------------------------------------------------------------------------
-- Timing (i_timer.h)
-- ---------------------------------------------------------------------------

doomtype.TICRATE = 35

-- ---------------------------------------------------------------------------
-- Fixed point (m_fixed.h / tables.h)
-- ---------------------------------------------------------------------------

doomtype.FRACBITS = 16
doomtype.FRACUNIT = 2 ^ doomtype.FRACBITS

doomtype.FINEANGLES = 8192
doomtype.FINEMASK = doomtype.FINEANGLES - 1
doomtype.ANGLETOFINESHIFT = 19

doomtype.SLOPERANGE = 2048
doomtype.SLOPEBITS = 11
doomtype.DBITS = doomtype.FRACBITS - doomtype.SLOPEBITS

-- ---------------------------------------------------------------------------
-- Binary Angle Measurement (tables.h)
-- ---------------------------------------------------------------------------

doomtype.ANG45 = 0x20000000
doomtype.ANG90 = 0x40000000
doomtype.ANG180 = 0x80000000
doomtype.ANG270 = 0xc0000000
doomtype.ANG_MAX = 0xffffffff

doomtype.ANG1 = doomtype.ANG45 // 45
doomtype.ANG60 = doomtype.ANG180 // 3

-- Heretic code uses this definition as though it represents one degree,
-- but it is not!  This is actually ~1.40 degrees.
doomtype.ANG1_X = 0x01000000

-- ---------------------------------------------------------------------------
-- Game globals (doomdef.h)
-- ---------------------------------------------------------------------------

doomtype.MAXPLAYERS = 4

doomtype.DOOM_VERSION = 109
doomtype.DOOM_191_VERSION = 111

-- ---------------------------------------------------------------------------
-- 32-bit helpers
-- ---------------------------------------------------------------------------

-- Reinterpret an unsigned 32-bit value as a signed 32-bit value.
function doomtype.u32_to_s32(x)
    x = bit32.band(x, 0xFFFFFFFF)
    return if x >= 0x80000000 then x - 0x1_00000000 else x
    -- x = x % 0x100000000
    -- if x >= 0x80000000 then
        -- return x - 0x100000000
    -- end
    -- return x
end

-- Exact truncating integer division toward zero (C semantics), for integer
-- operands within double's exact range (|a|, |b| < 2^53).
function doomtype.truncdiv(a, b)
    local q = math.floor(a / b)
    if q * b > a then
        q = q - 1
    end
    -- q is now the exact floor of a/b.
    local r = a - q * b
    if r ~= 0 and (a < 0) ~= (b < 0) then
        -- remainder non-zero and signs differ: truncate toward zero.
        q = q + 1
    end
    return q
end

-- 32-bit left shift of a signed value, wrapped and re-signed (C `<<` on int).
function doomtype.lshift32(a, bits)
    -- return doomtype.u32_to_s32(bit32.lshift(a % 0x100000000, bits))
    return doomtype.u32_to_s32(bit32.lshift(a, bits))
end

-- 32-bit arithmetic right shift of a signed value.
-- (Luau bit32.arshift returns an unsigned pattern; re-sign it.)
function doomtype.rshift32(a, bits)
    -- return doomtype.u32_to_s32(bit32.arshift(a % 0x100000000, bits))
    return doomtype.u32_to_s32(bit32.arshift(a, bits))
end

return doomtype