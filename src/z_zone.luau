--!native
--!optimize 2
local z_zone = {}

-- PU - purge tags (enum).
z_zone.PU_STATIC = 1 -- static entire execution time
z_zone.PU_SOUND = 2 -- static while playing
z_zone.PU_MUSIC = 3 -- static while playing
z_zone.PU_FREE = 4 -- a free block
z_zone.PU_LEVEL = 5 -- static until level exited
z_zone.PU_LEVSPEC = 6 -- a special thinker in a level

-- Tags >= PU_PURGELEVEL are purgable whenever needed.
z_zone.PU_PURGELEVEL = 7
z_zone.PU_CACHE = 8

z_zone.PU_NUM_TAGS = 9

-- Cache registry: buffer objects keyed by tag category, for later phases
-- (texture cache, etc.). The WAD lump cache is handled in w_wad.lua via
-- views into the mapped WAD buffer, so it does not allocate here.
local cache_blocks = {}

-- Z_Init: no-op (no zone heap to set up).
function z_zone.Z_Init()
end

-- Z_Malloc: allocate a byte buffer. If `user` is a table, user[1] = result.
function z_zone.Z_Malloc(size, tag, user)
    local result = buffer.create(size)
    if user ~= nil then
        user[1] = result
    end
    cache_blocks[result] = tag
    return result
end

-- Z_Free: no-op; Lua GC handles lifetimes.
function z_zone.Z_Free(ptr)
    cache_blocks[ptr] = nil
end

-- Z_ChangeTag: advisory only in the port; update the recorded category.
function z_zone.Z_ChangeTag(ptr, tag)
    if ptr ~= nil then
        cache_blocks[ptr] = tag
    end
end

-- Z_FreeTags: drop cached blocks in [lowtag, hightag).
function z_zone.Z_FreeTags(lowtag, hightag)
    for buf, tag in pairs(cache_blocks) do
        if tag >= lowtag and tag < hightag then
            cache_blocks[buf] = nil
        end
    end
end

function z_zone.Z_DumpHeap()
end

function z_zone.Z_CheckHeap()
end

function z_zone.Z_FreeMemory()
    return 0
end

function z_zone.Z_ZoneSize()
    return 0
end

return z_zone