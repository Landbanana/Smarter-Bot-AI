local Types = require("SBAI.Shared.types")

local function activateCrewLoadout(self)
    self:AddCommonModule("SBAI.Server.CommonModules.ItemPrefabExpansion")
end

---@param self Types.Module
local function activate(self)
    self:DoOption("CrewLoadout", activateCrewLoadout)
end

return Types.Module.new(activate)