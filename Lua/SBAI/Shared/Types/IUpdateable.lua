---@class IUpdateable
---@field public Identifier string
---@field public Update fun(instance:IUpdateable, dt:number)
local IUpdateable = {}
IUpdateable.__index = IUpdateable

return IUpdateable