local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

do
    local MakeFieldAccessible = LuaUserData.MakeFieldAccessible
    --local MakeMethodAccessible = LuaUserData.MakeMethodAccessible
    local MakePropertyAccessible = LuaUserData.MakePropertyAccessible
    --local AutoRegisterType = util.AutoRegisterType
    local Descriptors = Descriptors
    --local descriptor

    MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Turret"], "tryingToCharge")
    MakePropertyAccessible(Descriptors["Barotrauma.AIObjectiveCombat"], "Mode")

    --MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Turret"], "chargeSoundChannel")
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

    local onlyPreviouslyCuffed = options["onlyPreviouslyCuffed"]
    local minHealth = options["minHealth"]

    local targetPredicate

    if onlyPreviouslyCuffed then
        local cuffedPrisoners = Types.Set.new(self:RegisterTable(nil, "ROUND_END"))

        self:AddInit(
        function()
            for c in Character.CharacterList do --[[@cast c Barotrauma.Character]]
                if  not c.IsOnPlayerTeam and
                    c.IsHandcuffed and
                    c.IsInPlayerSub
                then
                    cuffedPrisoners:Add(c)
                end
            end
        end)

        self:AddPatch("Barotrauma.Items.Components.Wearable", "Equip", nil,
        function(instance, ptable)
            local item = instance.Item

            if item.HasTag(handlockerId) then
                local character = ptable["character"] --[[@type Barotrauma.Character]]

                if  not cuffedPrisoners[character] and
                    not character.IsOnPlayerTeam and
                    character.LastAttacker.IsOnPlayerTeam and
                    character.IsHandcuffed
                then
                    cuffedPrisoners:Add(character)
                end
            end
        end, Hook.HookMethodType.After)
        
        ---@param target Barotrauma.Character
        function targetPredicate(target)
            return cuffedPrisoners[target]
        end
    else
        targetPredicate = util.True
    end

    self:AddPatch("Barotrauma.AIObjectiveFightIntruders", "ObjectiveConstructor", nil, 
    function (instance, ptable)
        local character = instance.character

        if  character.IsOnPlayerTeam and
            character.IsInPlayerSub and
            character.HealthPercentage >= minHealth
        then
            local combatObj = ptable.ReturnValue --[[@type Barotrauma.AIObjectiveCombat]]
            
            if combatObj.Mode == Offensive then
                local inventory = character.Inventory

                if  inventory:SBAI_hasAnyItem(false, function(instance, item) return item.HasTag(handlockerId) end) and
                    inventory:SBAI_hasAnyItem(false, function(instance, item) return item.HasTag(stunnerId) end)
                then
                    local target = ptable["target"] --[[@type Barotrauma.Character]]
                    
                    if  target.IsHuman and
                        target.IsInPlayerSub and
                        targetPredicate(target)
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
---@param options table
local function activatePreSpinTurrets(self, options)
    self:AddPatch("Barotrauma.Items.Components.Turret", "Update", nil,
    function(instance, ptable)
        if instance.MaxChargeTime > 0.0 then
            local user = instance.ActiveUser

            if user then
                if user.IsBot then
                    instance.tryingToCharge = true
                end
            end
        end
    end, Hook.HookMethodType.Before)
end

---@param self Types.Module
local function activate(self)
    self:DoOption("PreventAttackingHandcuffed", activatePreventAttackingHandcuffed)
    self:DoOption("ArrestHumansInPlayerSub", activateArrestHumansInPlayerSub)
    self:DoOption("PreSpinTurrets", activatePreSpinTurrets)
end

return Types.Module.new(activate)