---@namespace Desc

---@class ClassProperty<C:Object>: Property<C>
---@field public cls ClassProperty<C>
---@field public super Property<C>
---@field public get fun(self, cls:C, obj:C):(any)
---@field public set fun(self, cls:C, obj:C, v:any)
---@field protected _default? any
---@field protected __new fun<S:ClassProperty<C>>(self:S, default:any, getter:fun(self:S, cls:C, obj:C):(any), setter:fun(self:S, cls:C, obj:C, v:any), ...:any):(S)
---@field protected _get fun(self, cls:C):(any)
---@field protected _set fun(self, cls:C, v:any)
---@overload fun<S:ClassProperty<C>>(default:any, getter:fun(self:S, cls:C, obj:C):(any), setter:fun(self:S, cls:C, obj:C, v:any), ...:any):(S)
Types.Desc.ClassProperty = Types.new--[[@<ClassProperty<C>, Property<C>>]]("Desc.ClassProperty", "Desc.Property")

local DescClassProperty = Types.Desc.ClassProperty

---@nodiscard
function DescClassProperty:__new(default, getter, setter, ...)
    local obj = DescClassProperty.super.__new(self, ...)

    obj._default = default
    obj._get = getter
    obj._set = setter
    return obj
end

---@nodiscard
function DescClassProperty:get(cls, obj)
    return self:_get(cls)
end

function DescClassProperty:set(cls, obj, v)
    return self._set(self, cls, v)
end

---@nodiscard
function DescClassProperty:_get(cls)
    return cls[self._pname]
end

function DescClassProperty:_set(cls, v)
    cls[self._pname] = v
end

return Types.Desc.ClassProperty