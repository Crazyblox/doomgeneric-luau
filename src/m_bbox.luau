--!native
--!optimize 2
local m_bbox = {}

m_bbox.BOXTOP = 1
m_bbox.BOXBOTTOM = 2
m_bbox.BOXLEFT = 3
m_bbox.BOXRIGHT = 4

-- M_ClearBox: reset the box to an empty (inverted) state.
function m_bbox.M_ClearBox(box)
    box[m_bbox.BOXTOP] = -2147483648 -- INT_MIN
    box[m_bbox.BOXRIGHT] = -2147483648
    box[m_bbox.BOXBOTTOM] = 2147483647 -- INT_MAX
    box[m_bbox.BOXLEFT] = 2147483647
end

function m_bbox.M_AddToBox(box, x, y)
    if x < box[m_bbox.BOXLEFT] then
        box[m_bbox.BOXLEFT] = x
    elseif x > box[m_bbox.BOXRIGHT] then
        box[m_bbox.BOXRIGHT] = x
    end
    if y < box[m_bbox.BOXBOTTOM] then
        box[m_bbox.BOXBOTTOM] = y
    elseif y > box[m_bbox.BOXTOP] then
        box[m_bbox.BOXTOP] = y
    end
end

return m_bbox