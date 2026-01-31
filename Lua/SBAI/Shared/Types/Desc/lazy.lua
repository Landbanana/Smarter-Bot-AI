---@namespace Desc

---@class Lazy<C:Object>: Property<C>
---@field public cls Lazy<C>
---@field public super Property<C>
---@field protected __new fun<S:Lazy<C>>(self:S, ctor:fun():(table), ...:any):(S)
---@field package ctor fun():(table)
---@overload fun<S:Lazy<C>>(ctor:fun():(table), ...):(S)
Types.Desc.Lazy = Types.new--[[@<Lazy<C>, Property<C>>]]("Desc.Lazy", "Desc.Property")

local DescLazy = Types.Desc.Lazy

function DescLazy:__new(ctor, ...)
    local obj = DescLazy.super.__new(self, nil, nil, nil, ...)

    obj.ctor = ctor
    return obj
end

do
    local rawset = rawset

    ---@nodiscard
    function DescLazy:get(cls, obj)
        local out = self.ctor()

        rawset(obj, self.name, out)
        return out
    end
end

return Types.Desc.Lazy