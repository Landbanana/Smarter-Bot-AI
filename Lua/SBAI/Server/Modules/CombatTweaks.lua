local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

do
    LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.AIObjectiveCombat"], "Mode")
end

local function activatePreventAttackingHandcuffed(self, options)
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

---@param self Types.Module
---@param options table
local function activateArrestHumansInPlayerSub(self, options)
    self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")

    local Arrest = CombatMode.Arrest
    local Offensive = CombatMode.Offensive
    local handlockerId = Identifier("handlocker")
    local stunnerId = Identifier("stunner")

    local minHealth = options["minHealth"]

    self:AddPatch("Barotrauma.AIObjectiveFightIntruders", "ObjectiveConstructor", nil,
    function(instance, ptable)
        local character = instance.character

        if  character.IsOnPlayerTeam and
            character.IsInPlayerSub and
            character.HealthPercentage >= minHealth
        then
            local combatObj = ptable.ReturnValue --[[@type Barotrauma.AIObjectiveCombat]]
            
            if combatObj.Mode == Offensive then
                local inventory = character.Inventory

                if  inventory:SBAI_hasAnyItem(false, function(item) return item.HasTag(handlockerId) end) and
                    inventory:SBAI_hasAnyItem(false, function(item) return item.HasTag(stunnerId) end)
                then
                    local target = ptable["target"] --[[@type Barotrauma.Character]]
                    
                    if  target.IsHuman and
                        target.IsInPlayerSub
                    then
                        combatObj.Mode = Arrest
                    end
                end
            end
        end
    end, Hook.HookMethodType.After)

    self:AddPatch("Barotrauma.AIObjectiveCombat", "Act", nil,
    function(instance, ptable)
        if instance.Mode == Arrest then
            local character = instance.character

            if  character.IsOnPlayerTeam and
                character.HealthPercentage < minHealth
            then
                instance.Mode = Offensive
            end
        end
    end, Hook.HookMethodType.Before)
end

---@param self Types.Module
local function activate(self)
    self:DoOption("PreventAttackingHandcuffed", activatePreventAttackingHandcuffed)
    self:DoOption("ArrestHumansInPlayerSub", activateArrestHumansInPlayerSub)
end

return Types.Module.new(activate)
