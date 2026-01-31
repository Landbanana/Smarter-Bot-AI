---@namespace Desc

---@class Constant<C:Object>: Readonly<C>
---@field public cls Constant<C>
---@field public super Readonly<C>
---@field public __new fun<S:Constant<C>>(self:S, default:any, ...:any):(S)
---@overload fun<S:Constant<C>>(default:any, ...:any):(S)
Types.Desc.Constant = Types.new--[[@<Constant<C>, Readonly<C>>]]("Desc.Constant", "Desc.Readonly")

local DescConstant = Types.Desc.Constant

-- ---@nodiscard
-- function DescConstant:__new(default, ...)
--     return DescConstant.super.__new(self, default, ...)
-- end

return Types.Desc.Constant