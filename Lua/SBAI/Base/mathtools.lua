---@class Mathtools
local Mathtools = {}

do
    local huge = math.huge
    
    local _max = math.max
    local _min = math.min

    ---@param v number
    ---@param min? number
    ---@param max? number
    ---@return number
    ---@nodiscard
    function Mathtools.clamp(v, min, max)
        return _max((min or (-huge)), _min((max or huge), v))
    end
end

---@source https://stackoverflow.com/a/58411671
---@param v number
---@return integer
---@nodiscard
function Mathtools.round(v)
    return (v + (2^52 + 2^51) - (2^52 + 2^51)) ---@as integer
end

do
    local round = Mathtools.round
    local tonumber = tonumber

    ---@param v? any
    ---@return integer?
    ---@nodiscard
    function Mathtools.tointeger(v)
        v = tonumber(v)
        if v == nil then
            return nil
        else
            return round(v)
        end
    end
end

do
    ---@param v number
    ---@return -1|1
    ---@nodiscard
    function Mathtools.sgn(v)
        return (v < 0) and -1 or 1
    end
end

do
    local abs = math.abs
    local ceil = math.ceil
    local log = math.log
    local sgn = Mathtools.sgn

    ---@param v number
    ---@return integer
    function Mathtools.bitSize(v)
        return ceil(log( abs(v) + (sgn(v) + 1)/2, 2))
    end
end

do
    local band = bit32.band

    function Mathtools.hasFlag(bitFlag, flag)
        return band(bitFlag, flag) == flag
    end
end

return Mathtools