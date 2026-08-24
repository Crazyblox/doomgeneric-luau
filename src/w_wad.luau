--!native
--!optimize 2
local i_system = require("./i_system")
local d_mode = require("./d_mode")
local d_iwad = require("./d_iwad")
local w_wad = {}

-- ---------------------------------------------------------------------------
-- Globals
-- ---------------------------------------------------------------------------

-- The WAD buffer (raw IWAD bytes) and its length.
local wad_buffer = nil
local wad_length = 0

-- Lump directory. 1-based array of { name, position, size, next }.
-- `name` is the raw 8-byte lump name string.
local lumpinfo = {}

-- 0-based lump count (C: `unsigned int numlumps`).
local numlumps = 0

-- Hash table for fast lookups: lumphash[hash % numlumps + 1] = list of
-- 1-based lump indices (newest first, mirroring C chain prepend).
local lumphash = nil

-- ---------------------------------------------------------------------------
-- Hash function used for lump names (djb2, modded for max length 8)
-- ---------------------------------------------------------------------------

local function toupper_byte(c)
    if c >= 97 and c <= 122 then -- 'a'..'z'
        return c - 32
    end
    return c
end

function w_wad.W_LumpNameHash(s)
    local result = 5381
    for i = 1, 8 do
        local c = string.byte(s, i)
        -- C loop: `for (i = 0; i < 8 && s[i] != '\0'; ++i)` -- stop at NUL too,
        -- since stored 8-byte lump names carry NUL padding.
        if c == nil or c == 0 then
            break
        end
        -- result = ((result << 5) ^ result) ^ toupper(s[i])   (unsigned 32-bit)
        result = bit32.bxor(bit32.bxor(bit32.lshift(result, 5), result), toupper_byte(c))
    end
    return result
end

-- ---------------------------------------------------------------------------
-- Lump name comparison: C strncasecmp(lump->name, name, 8). Stops at a NUL
-- in either string; an equal prefix of the shorter string counts as a match.
-- ---------------------------------------------------------------------------

local function name_matches(stored, name)
    for i = 1, 8 do
        local sc = string.byte(stored, i)
        local nc = string.byte(name, i)
        if sc == nil or nc == nil or sc == 0 or nc == 0 then
            return true
        end
        if toupper_byte(sc) ~= toupper_byte(nc) then
            return false
        end
    end
    return true
end

-- ---------------------------------------------------------------------------
-- SetWAD: parse the WAD header + directory into the lump table
-- ---------------------------------------------------------------------------

function w_wad.SetWAD(buf)
    if buf == nil then
        i_system.I_Error("SetWAD: no WAD buffer provided")
    end

    wad_buffer = buf
    wad_length = buffer.len(buf)

    if wad_length < 12 then
        i_system.I_Error("SetWAD: buffer too small to be a WAD file")
    end

    local id = buffer.readu32(buf, 0) -- "IWAD"/"PWAD" little-endian

    if id ~= 0x44415749 and id ~= 0x44415750 then -- "IWAD" / "PWAD"
        i_system.I_Error("SetWAD: buffer doesn't have IWAD or PWAD id")
    end

    local header_numlumps = buffer.readi32(buf, 4)
    local infotableofs = buffer.readi32(buf, 8)

    if header_numlumps < 0 or infotableofs < 0 then
        i_system.I_Error("SetWAD: corrupt WAD header")
    end

    local dir_bytes = header_numlumps * 16
    if infotableofs + dir_bytes > wad_length then
        i_system.I_Error("SetWAD: WAD directory out of bounds")
    end

    -- Reset directory.
    lumpinfo = {}
    numlumps = 0

    for i = 0, header_numlumps - 1 do
        local off = infotableofs + i * 16
        local filepos = buffer.readi32(buf, off)
        local size = buffer.readi32(buf, off + 4)
        -- 8-byte lump name (may contain NUL padding). Read bytes manually so
        -- the port behaves identically under Roblox and the standalone luau
        -- binary (buffer.create does not copy from source in the latter).
        local name = ""
        for nb = 0, 7 do
            name = name .. string.char(buffer.readu8(buf, off + 8 + nb))
        end
        table.insert(lumpinfo, {
            name = name,
            position = filepos,
            size = size,
            next = 0,
        })
    end

    numlumps = header_numlumps

    -- A new WAD invalidates the hash table; regenerate.
    w_wad.W_GenerateHashTable()
end

-- AddPWAD: deferred (v1). Kept as a no-op placeholder for the interface.
function w_wad.AddPWAD()
    -- v1 scope: PWADs deferred (see PortingPlan).
end

-- W_NumLumps
function w_wad.W_NumLumps()
    return numlumps
end

-- W_LumpName: return the stored 8-byte lump name for a 0-based lump number
-- (used by R_InitSpriteDefs to scan sprite frame names).
function w_wad.W_LumpName(lump)
    if lump < 0 or lump >= numlumps then
        i_system.I_Error("W_LumpName: %i >= numlumps", lump)
    end
    return lumpinfo[lump + 1].name
end

-- ---------------------------------------------------------------------------
-- W_CheckNumForName / W_GetNumForName
-- ---------------------------------------------------------------------------

function w_wad.W_CheckNumForName(name)
    if lumphash ~= nil then
        local hash = w_wad.W_LumpNameHash(name) % numlumps
        local bucket = lumphash[hash + 1]
        if bucket ~= nil then
            for _, idx in ipairs(bucket) do
                if name_matches(lumpinfo[idx].name, name) then
                    return idx - 1 -- 0-based
                end
            end
        end
        return -1
    end

    -- No hash table yet: scan backwards so patch lump files take precedence.
    for i = numlumps, 1, -1 do
        if name_matches(lumpinfo[i].name, name) then
            return i - 1
        end
    end
    return -1
end

function w_wad.W_GetNumForName(name)
    local i = w_wad.W_CheckNumForName(name)
    if i < 0 then
        i_system.I_Error("W_GetNumForName: %s not found!", name)
    end
    return i
end

-- ---------------------------------------------------------------------------
-- Lump access
-- ---------------------------------------------------------------------------

function w_wad.W_LumpLength(lump)
    if lump < 0 or lump >= numlumps then
        i_system.I_Error("W_LumpLength: %i >= numlumps", lump)
    end
    return lumpinfo[lump + 1].size
end

-- ---------------------------------------------------------------------------
-- W_CheckCorrectIWAD: error if the loaded WAD contains a lump unique to a
-- different game type (eg. chocolate-doom -iwad hexen.wad). Mirrors the C
-- `W_CheckCorrectIWAD` in w_wad.c.
-- ---------------------------------------------------------------------------

local unique_lumps = {
    { mission = d_mode.doom,    lumpname = "POSSA1" },
    { mission = d_mode.heretic, lumpname = "IMPXA1" },
    { mission = d_mode.hexen,   lumpname = "ETTNA1" },
    { mission = d_mode.strife,  lumpname = "AGRDA1" },
}

function w_wad.W_CheckCorrectIWAD(mission)
    for _, u in ipairs(unique_lumps) do
        if mission ~= u.mission then
            local lumpnum = w_wad.W_CheckNumForName(u.lumpname)
            if lumpnum >= 0 then
                i_system.I_Error(
                    "\nYou are trying to use a %s IWAD file with the " ..
                    "%s%s binary.\nThis isn't going to work.\n" ..
                    "You probably want to use the %s%s binary.",
                    d_iwad.D_SuggestGameName(u.mission, d_mode.indetermined),
                    "doomgeneric",
                    d_mode.D_GameMissionString(mission),
                    "doomgeneric",
                    d_mode.D_GameMissionString(u.mission))
            end
        end
    end
end

-- W_ReadLump: copy the lump bytes into destBuf at destOffset.
function w_wad.W_ReadLump(lump, destBuf, destOffset)
    if lump < 0 or lump >= numlumps then
        i_system.I_Error("W_ReadLump: %i >= numlumps", lump)
    end
    local l = lumpinfo[lump + 1]
    buffer.copy(destBuf, destOffset or 0, wad_buffer, l.position, l.size)
end

-- W_CacheLumpNum: return a view { buffer, offset, size } into the mapped WAD.
-- The C function returns a pointer into the mmapped region; no copy is made.
function w_wad.W_CacheLumpNum(lump, tag)
    if lump < 0 or lump >= numlumps then
        i_system.I_Error("W_CacheLumpNum: %i >= numlumps", lump)
    end
    local l = lumpinfo[lump + 1]
    return { buffer = wad_buffer, offset = l.position, size = l.size }
end

function w_wad.W_CacheLumpName(name, tag)
    return w_wad.W_CacheLumpNum(w_wad.W_GetNumForName(name), tag)
end

-- W_ReleaseLumpNum / W_ReleaseLumpName: no-op in the mapped-file port.
function w_wad.W_ReleaseLumpNum(lump)
end

function w_wad.W_ReleaseLumpName(name)
end

-- ---------------------------------------------------------------------------
-- Hash table generation
-- ---------------------------------------------------------------------------

function w_wad.W_GenerateHashTable()
    lumphash = nil

    if numlumps > 0 then
        lumphash = {}
        for _ = 1, numlumps do
            table.insert(lumphash, nil)
        end

        for i = 1, numlumps do
            local hash = w_wad.W_LumpNameHash(lumpinfo[i].name) % numlumps
            local bucket = lumphash[hash + 1]
            if bucket == nil then
                bucket = {}
                lumphash[hash + 1] = bucket
            end
            -- Prepend so the most recently added lump wins (C chain prepend).
            table.insert(bucket, 1, i)
        end
    end
end

return w_wad