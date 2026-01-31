---@namespace Desc

---@class TiedConstant<C:Object>: Property<C>
---@field public cls TiedConstant<C>
---@field public super Property<C>
---@field protected __new fun<S:TiedConstant<C>>(self:S, getter:fun(self:S, cls:C, obj:C):(any), ...:any):(S)
---@overload fun<S:TiedConstant<C>>(getter:fun(self:S, cls:C, obj:C):(any), ...:any):(S)
Types.Desc.TiedConstant = Types.new--[[@<TiedConstant<C>, Property<C>>]]("Desc.TiedConstant", "Desc.Property")

local DescTiedConstant = Types.Desc.TiedConstant

---@nodiscard
function DescTiedConstant:__new(getter, ...)
    return DescTiedConstant.super.__new(self, nil, getter, nil, ...)
end

return Types.Desc.TiedConstant