local Types = require("SBAI.Shared.types")

---@param self Types.Module
local function activate(self)
    self:AddPatch("Barotrauma.Level", "ShouldSpawnCrewInsideOutpost", nil,
    function(instance, ptable)
        ptable.PreventExecution = true
        
        return false
    end, Hook.HookMethodType.Before)
end

return Types.Module.new(activate)