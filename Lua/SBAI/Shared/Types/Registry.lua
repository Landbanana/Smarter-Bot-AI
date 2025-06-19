---@class Registry<T>: {constructor:fun(self:Registry<T>, typeName:string):T}, {[string]:T}
---@field private constructor function
local Registry = {}
Registry.__index = Registry

---@generic T
---@param self Registry<T>
---@param typeName string
---@return T
function Registry:index(typeName)
    local out = self.constructor(typeName)

    self[typeName] = out
    return out
end

---@public
---@generic T
---@param self Registry<T>
---@param typeName `T`
---@return T
function Registry:Get(typeName)
    return self[typeName] or self:index(typeName)
end

do
    local setmetatable = setmetatable

    ---@generic T
    ---@param constructor fun(self:Registry<T>, typeName:`T`):T}
    ---@return Registry<T>
    function Registry.new(constructor)
        return setmetatable({constructor=constructor}, Registry)
    end
end

return Registry