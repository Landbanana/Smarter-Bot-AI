---@namespace Config

---@class (partial) OptionInt
local ConfigOptionInt = Types.Config.OptionInt

local GUIHelper = Types.GUIHelper

ConfigOptionInt:_makeNumberInput("Int")

return ConfigOptionInt