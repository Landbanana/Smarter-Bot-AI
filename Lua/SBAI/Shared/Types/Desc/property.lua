---@namespace Desc

---@class Property<C:Object>: Base<C>
---@field public cls Property<C>
---@field public super Base<C>
---@field public get fun(self, cls:C, obj:C):(any)
---@field public getF fun(self, cls:C, obj:C):(any)
---@field public getT fun(self, cls:C, obj:C):(any)
---@field public set fun(self, cls:C, obj:C, v:any)
---@field public setT fun(self, cls:C, obj:C, v:any)
---@field public setF fun(self, cls:C, obj:C, v:any)
---@field protected _default? any
---@field protected __new fun<S:Property<C>>(self:S, default:any, getter:fun(self:S, cls:C, obj:C):(any), setter:fun(self:S, cls:C, obj:C, v:any), ...:any):(S)
---@overload fun<S:Property<C>>(default:any, getter:fun(self:S, cls:C, obj:C):(any), setter:fun(self:S, cls:C, obj:C, v:any), ...:any):(S)
Types.Desc.Property = Types.new--[[@<Property<C>, Base<C>>]]("Desc.Property", "Desc.Base")

local DescProperty = Types.Desc.Property

---@nodiscard
function DescProperty:__new(default, getter, setter, ...)
    local obj = DescProperty.super.__new(self, ...)

    obj._default = default
    obj.get = getter
    obj.set = setter
    return obj
end

---@nodiscard
function DescProperty:getT(cls, obj)
    return obj[self._pname]
end

do
    local error = error

    ---@nodiscard
    function DescProperty:getF(cls, obj)
        return error(("%s.%s has no getter"):format(cls.__name, self.name))
    end
end

function DescProperty:setT(cls, obj, v)
    obj[self._pname] = v
end

do
    local error = error

    function DescProperty:setF(cls, obj, v)
        return error(("%s.%s has no setter"):format(cls.__name, self.name))
    end
end

DescProperty.get = DescProperty.getF
DescProperty.set = DescProperty.setF

function DescProperty:update(name, owner)
    local pname = ("__%s_%s"):format(self.cls.__name:gsub("%.", "_"), name)

    self.name = name
    self._pname = pname
    if self._default ~= nil then owner[pname] = self._default end
end

return Types.Desc.Property