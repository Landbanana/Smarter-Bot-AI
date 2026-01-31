---@class (partial) Config.Base<J:Json>
---@field public draw fun(self, parent:Barotrauma.GUIComponent)
local ConfigBase = Types.Config.Base

rawset(ConfigBase, "draw", Types.AbstractFunction)




return Types.Config.Base