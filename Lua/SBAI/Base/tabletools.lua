---@class Tabletools
local Tabletools = {}

do
    local next = next

    ---@param t table
    function Tabletools.clear(t)
        for k in next, t do
            t[k] = nil
        end
    end
end

---@generic T
---@param t T[]
---@return T[]
function Tabletools.iclear(t)
    for i=1,#t do
        t[i] = nil
    end
    return t
end

do
    local next = next

    ---@generic T:table, O:table
    ---@param t T
    ---@param out? O
    ---@return T|O
    function Tabletools.copy(t, out)
        out = out or {}
        for k, v in next, t do
            out[k] = v
        end
        return out
    end
end

---@generic T
---@param t T[]
---@return T[]
function Tabletools.icopy(t)
    local out = {}

    for i=1,#t do
        out[i] = t[i]
    end
    return out
end


Tabletools.autoMt1 = {
    __index=function(t, k)
        local out = {}

        t[k] = out
        return out
    end
}

do
    local autoMt1 = Tabletools.autoMt1

    local setmetatable = setmetatable

    Tabletools.autoMt2 = {
        __index=function(t, k)
            local out = setmetatable({}, autoMt1)

            t[k] = out
            return out
        end
    }
end


do


    local type = type
    local next = next

    ---@param onEnter fun(k:any, t:table, ...:any...)
    ---@param onExit fun(k:any, t:table, ...:any...)
    ---@param onValue fun(k:any, v:any, ...:any...)
    ---@param t table
    local function traverse(onEnter, onExit, onValue, t, ...)
        for k, v in next, t do
            if type(v) == "table" then
                onEnter(k, v, ...)
                traverse(onEnter, onExit, onValue, v, ...)
                onExit(k, v, ...)
            else
                onValue(k, v, ...)
            end
        end
    end
    Tabletools.traverse = traverse
end

---@return table
---@nodiscard
function Tabletools.new()
    return {}
end

do
    local setmetatable = setmetatable

    ---@param mt metatable
    ---@return fun():(table)
    ---@nodiscard
    function Tabletools.newWithMtFactory(mt)
        return function()
            return setmetatable({}, mt)
        end
    end
end

do
    ---@generic T, K:keyof T
    ---@param t T
    ---@param k K
    ---@return std.RawGet<T, K>
    ---@nodiscard
    function Tabletools.index(t, k)
        return t[k]
    end
end

do
    local getmetatable = debug.getmetatable
    local match = string.match
    local setmetatable = setmetatable

    local tostring = tostring

    ---@param t table
    ---@return string
    ---@nodiscard
    function Tabletools.topointer(t)
        local mt = getmetatable(t)

        setmetatable(t, nil)

        local p = match(tostring(t), "(%x+)$") ---@cast p -?

        setmetatable(t, mt)
        return p
    end
end

return Tabletools