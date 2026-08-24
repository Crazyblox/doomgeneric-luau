--!native
--!optimize 2
local doomtype = require("./doomtype")
local m_fixed = require("./m_fixed")
local r_state = require("./r_state")
local p_sight = {}

-- ---------------------------------------------------------------------------
-- Globals (p_sight.c externs).
-- ---------------------------------------------------------------------------

p_sight.sightzstart = 0 -- eye z of looker
p_sight.topslope = 0
p_sight.bottomslope = 0 -- slopes to top and bottom of target

p_sight.strace = { x = 0, y = 0, dx = 0, dy = 0 } -- divline_t from t1 to t2
p_sight.t2x = 0
p_sight.t2y = 0

p_sight.sightcounts = { 0, 0 }

local NF_SUBSECTOR = 0x8000

-- ---------------------------------------------------------------------------
-- P_DivlineSide
-- Returns side 0 (front), 1 (back), or 2 (on).
-- ---------------------------------------------------------------------------

function p_sight.P_DivlineSide(x, y, node)
    local dx
    local dy
    local left
    local right

    if node.dx == 0 then
        if x == node.x then
            return 2
        end
        if x <= node.x then
            return node.dy > 0 and 1 or 0
        end
        return node.dy < 0 and 1 or 0
    end

    if node.dy == 0 then
        -- (The C compares x == node->y here; preserved verbatim.)
        if x == node.y then
            return 2
        end
        if y <= node.y then
            return node.dx < 0 and 1 or 0
        end
        return node.dx > 0 and 1 or 0
    end

    dx = x - node.x
    dy = y - node.y

    left = doomtype.u32_to_s32(doomtype.rshift32(node.dy, 16)
        * doomtype.rshift32(dx, 16))
    right = doomtype.u32_to_s32(doomtype.rshift32(dy, 16)
        * doomtype.rshift32(node.dx, 16))

    if right < left then
        return 0 -- front side
    end
    if left == right then
        return 2
    end
    return 1 -- back side
end

-- ---------------------------------------------------------------------------
-- P_InterceptVector2
-- Returns the fractional intercept point along the first divline.
-- This is only called by P_CrossSubsector.
-- ---------------------------------------------------------------------------

function p_sight.P_InterceptVector2(v2, v1)
    local frac
    local num
    local den

    den = m_fixed.FixedMul(v1.dy // 256, v2.dx) -- v1->dy>>8
        - m_fixed.FixedMul(v1.dx // 256, v2.dy)

    if den == 0 then
        return 0 -- parallel
    end

    num = m_fixed.FixedMul((v1.x - v2.x) // 256, v1.dy)
        + m_fixed.FixedMul((v2.y - v1.y) // 256, v1.dx)
    frac = m_fixed.FixedDiv(num, den)

    return frac
end

-- ---------------------------------------------------------------------------
-- P_CrossSubsector
-- Returns true if strace crosses the given subsector successfully.
-- ---------------------------------------------------------------------------

function p_sight.P_CrossSubsector(num)
    local S = r_state
    local line
    local s1
    local s2
    local count
    local sub
    local front
    local back
    local opentop
    local openbottom
    local divl
    local v1
    local v2
    local frac
    local slope

    sub = S.subsectors[num + 1]

    -- check lines
    count = sub.numlines
    for segi = 0, count - 1 do
        local seg = S.segs[sub.firstline + segi + 1]
        line = seg.linedef

        -- already checked other side?
        if line.validcount ~= S.validcount then
            line.validcount = S.validcount

            v1 = line.v1
            v2 = line.v2
            s1 = p_sight.P_DivlineSide(v1.x, v1.y, p_sight.strace)
            s2 = p_sight.P_DivlineSide(v2.x, v2.y, p_sight.strace)

            -- line isn't crossed?
            if s1 ~= s2 then
                divl = { x = v1.x, y = v1.y, dx = v2.x - v1.x, dy = v2.y - v1.y }
                s1 = p_sight.P_DivlineSide(p_sight.strace.x, p_sight.strace.y, divl)
                s2 = p_sight.P_DivlineSide(p_sight.t2x, p_sight.t2y, divl)

                -- line isn't crossed?
                if s1 ~= s2 then
                    -- Backsector may be NULL if this is an "impassible
                    -- glass" hack line.
                    if line.backsector == nil then
                        return false
                    end

                    -- stop because it is not two sided anyway
                    -- might do this after updating validcount?
                    if bit32.band(line.flags, 4) == 0 then -- ML_TWOSIDED
                        return false
                    end

                    -- crosses a two sided line
                    front = seg.frontsector
                    back = seg.backsector

                    -- no wall to block sight with?
                    if front.floorheight ~= back.floorheight
                        or front.ceilingheight ~= back.ceilingheight then
                        -- possible occluder
                        -- because of ceiling height differences
                        if front.ceilingheight < back.ceilingheight then
                            opentop = front.ceilingheight
                        else
                            opentop = back.ceilingheight
                        end

                        -- because of floor height differences
                        if front.floorheight > back.floorheight then
                            openbottom = front.floorheight
                        else
                            openbottom = back.floorheight
                        end

                        -- quick test for totally closed doors
                        if openbottom >= opentop then
                            return false -- stop
                        end

                        frac = p_sight.P_InterceptVector2(p_sight.strace, divl)

                        if front.floorheight ~= back.floorheight then
                            slope = m_fixed.FixedDiv(openbottom - p_sight.sightzstart, frac)
                            if slope > p_sight.bottomslope then
                                p_sight.bottomslope = slope
                            end
                        end

                        if front.ceilingheight ~= back.ceilingheight then
                            slope = m_fixed.FixedDiv(opentop - p_sight.sightzstart, frac)
                            if slope < p_sight.topslope then
                                p_sight.topslope = slope
                            end
                        end

                        if p_sight.topslope <= p_sight.bottomslope then
                            return false -- stop
                        end
                    end
                end
            end
        end
    end
    -- passed the subsector ok
    return true
end

-- ---------------------------------------------------------------------------
-- P_CrossBSPNode
-- Returns true if strace crosses the given node successfully.
-- ---------------------------------------------------------------------------

function p_sight.P_CrossBSPNode(bspnum)
    local S = r_state
    local bsp
    local side

    if bit32.band(bspnum, NF_SUBSECTOR) ~= 0 then
        if bspnum == -1 then
            return p_sight.P_CrossSubsector(0)
        end
        return p_sight.P_CrossSubsector(bit32.band(bspnum, bit32.bnot(NF_SUBSECTOR)))
    end

    bsp = S.nodes[bspnum + 1]

    -- decide which side the start point is on
    side = p_sight.P_DivlineSide(p_sight.strace.x, p_sight.strace.y, bsp)
    if side == 2 then
        side = 0 -- an "on" should cross both sides
    end

    -- cross the starting side
    if not p_sight.P_CrossBSPNode(bsp.children[side + 1]) then
        return false
    end

    -- the partition plane is crossed here
    if side == p_sight.P_DivlineSide(p_sight.t2x, p_sight.t2y, bsp) then
        -- the line doesn't touch the other side
        return true
    end

    -- cross the ending side
    return p_sight.P_CrossBSPNode(bsp.children[bit32.bxor(side, 1) + 1])
end

-- ---------------------------------------------------------------------------
-- P_CheckSight
-- Returns true if a straight line between t1 and t2 is unobstructed.
-- Uses REJECT.
-- ---------------------------------------------------------------------------

function p_sight.P_CheckSight(t1, t2)
    local S = r_state
    local s1
    local s2
    local pnum
    local bytenum
    local bitnum

    -- First check for trivial rejection.

    -- Determine subsector entries in REJECT table.
    s1 = t1.subsector.sector.index
    s2 = t2.subsector.sector.index
    pnum = s1 * S.numsectors + s2
    bytenum = pnum // 8 -- >>3
    bitnum = bit32.lshift(1, bit32.band(pnum, 7))

    -- Check in REJECT table.
    if bit32.band(buffer.readu8(S.rejectmatrix.buffer, S.rejectmatrix.offset + bytenum), bitnum) ~= 0 then
        p_sight.sightcounts[1] = p_sight.sightcounts[1] + 1 -- [0]

        -- can't possibly be connected
        return false
    end

    -- An unobstructed LOS is possible.
    -- Now look from eyes of t1 to any part of t2.
    p_sight.sightcounts[2] = p_sight.sightcounts[2] + 1 -- [1]

    S.validcount = S.validcount + 1

    p_sight.sightzstart = t1.z + t1.height - (t1.height // 4) -- >>2
    p_sight.topslope = (t2.z + t2.height) - p_sight.sightzstart
    p_sight.bottomslope = t2.z - p_sight.sightzstart

    p_sight.strace.x = t1.x
    p_sight.strace.y = t1.y
    p_sight.t2x = t2.x
    p_sight.t2y = t2.y
    p_sight.strace.dx = t2.x - t1.x
    p_sight.strace.dy = t2.y - t1.y

    -- the head node is the last node output
    return p_sight.P_CrossBSPNode(S.numnodes - 1)
end

return p_sight