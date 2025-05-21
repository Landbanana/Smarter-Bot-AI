local Types = require("SBAI.Shared.types")

--LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.AIObjectiveCombat"], "TargetEliminated")

---@param self Types.Module
local function activate(self)
    local paralysisId = Identifier("paralysis")

    self:AddPatch("Barotrauma.AIObjectiveCombat", "get_TargetEliminated", nil,
    function(instance, ptable)
        if instance.character.IsOnPlayerTeam then
            local enemy = instance.Enemy

            if enemy.IsHuman then
                ptable.PreventExecution = true

                if ptable.ReturnValue or enemy.IsHandcuffed then return true end
                local paralysis = enemy.CharacterHealth.GetAffliction(paralysisId, false)
                
                return paralysis ~= nil and paralysis.Strength >= 99.0
            end
        end
    end, Hook.HookMethodType.Before)
end

return Types.Module.new(activate)