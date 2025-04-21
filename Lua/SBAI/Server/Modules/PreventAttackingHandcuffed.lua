local Types = require("SBAI.Shared.types")

LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.AIObjectiveCombat"], "TargetEliminated")

---@param self Types.Module
local function activate(self)
    self:AddPatch("Barotrauma.AIObjectiveCombat", "get_TargetEliminated", nil,
    function(instance, ptable)
        return ptable.ReturnValue or (instance.character.IsOnPlayerTeam and instance.Enemy.IsHandcuffed)
    end, Hook.HookMethodType.Before)
end

return Types.Module.new(activate)