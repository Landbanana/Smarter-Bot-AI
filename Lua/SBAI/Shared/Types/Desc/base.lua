---@namespace Desc

---@class Base<C:Object>: Object
---@field public cls Base<C>
---@field public name string
---@field public update fun(self, name:string, owner:C)
---@field protected _pname string
---@field protected __new fun<S:Base<C>>(self:S, ...:any):(S)
---@overload fun<S:Base<C>>(...:any):(S)
Types.Desc.Base = Types.new--[[@<Base<C>, Object>]]("Desc.Base")

local DescBase = Types.Desc.Base

DescBase.name = "(unknown)"

-- function DescBase:__new(...)
--     return DescBase.super.__new(self, ...)
-- end

return Types.Desc.Base