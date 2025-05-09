local Types = require("SBAI.Shared.types")

    ---@param self Types.Module
local function activate(self)
    if Game.IsSingleplayer then
        self:AddPatch("Barotrauma.CrewManager", "UpdateConversations", nil,
        function(instance, ptable)
            ptable.PreventExecution = true
        end, Hook.HookMethodType.Before)
    end
end

return Types.Module.new(activate)