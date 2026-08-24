--!native
--!optimize 2
local doomtype = require("./doomtype")
local m_fixed = {}

m_fixed.FRACBITS = doomtype.FRACBITS
m_fixed.FRACUNIT = doomtype.FRACUNIT

--[[
local b = buffer.create(4)
local function i32(x: number)
    buffer.writei32(b, 0, x);
    return buffer.readi32(b, 0)
end

-- fixedmul
-- Performs multiplication on 2 numbers.
-- Returns quantized value [i16.u16]
function m_fixed.FixedMul(x: number, y: number)
  return i32(x * (y / 0x10000))
end

-- fixeddiv
-- Perform division on 2 numbers.
-- Returns quantized value [i16.u16]
local INT_MIN = -0x80000000
local INT_MAX =  0x7FFFFFFF
function m_fixed.FixedDiv(x: number, y: number)
  if (math.abs(x) // 0x4000) >= math.abs(y) then
    return (x < 0) ~= (y < 0) and INT_MIN or INT_MAX
  end

  return i32((x * 0x10000) / y)
end
]]

-- C: return ((int64_t) a * (int64_t) b) >> FRACBITS;  (cast to int32)
function m_fixed.FixedMul(a, b)
    -- signed high 16 bits (arithmetic shift >> 16), unsigned low 16 bits.
    local ah = math.floor(a / 65536)
    local al = a % 65536
    local bh = math.floor(b / 65536)
    local bl = b % 65536

    -- (product >> 16) mod 2^32:
    --   ah*bh*2^16 + ah*bl + al*bh + (al*bl)>>16
    local sum = ah * bh * 65536 + ah * bl + al * bh + math.floor(al * bl / 65536)
    return doomtype.u32_to_s32(sum)
end

-- C: FixedDiv with saturation guard, then truncating int64 division.
--
--   if ((abs(a) >> 14) >= abs(b))
--       return (a ^ b) < 0 ? INT_MIN : INT_MAX;
--   else
--       return (fixed_t)(((int64_t) a << 16) / b);
function m_fixed.FixedDiv(a, b)
    local absa = a < 0 and -a or a
    local absb = b < 0 and -b or b

    if math.floor(absa / 16384) >= absb then
        if (a < 0) ~= (b < 0) then
            return -2147483648 -- INT_MIN
        end
        return 2147483647 -- INT_MAX
    end

    local q = doomtype.truncdiv(a * 65536, b)
    -- return doomtype.u32_to_s32(q % 0x100000000)
    return doomtype.u32_to_s32(q)
end

return m_fixed