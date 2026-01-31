---@namespace Desc

---@class Readonly<C:Object>: Property<C>
---@field public cls Readonly<C>
---@field public super Property<C>
---@field protected __new fun<S:Readonly<C>>(self:S, default:any, ...:any):(S)
---@overload fun<S:Readonly<C>>(default:any, ...:any):(S)
Types.Desc.Readonly = Types.new--[[@<Readonly<C>, Property<C>>]]("Desc.Readonly", "Desc.Property", {
    get = Types.Desc.Property.getT;
})

local DescReadonly = Types.Desc.Readonly

---@nodiscard
function DescReadonly:__new(default, ...)
    return DescReadonly.super.__new(self, default, nil, nil, ...)
end

function DescReadonly:set(cls, obj, v)
    if self:getT(cls, obj) == nil then
        return self:setT(cls, obj, v)
    else
        return self:setF(cls, obj, v)
    end
end

return Types.Desc.Readonly