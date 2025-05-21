local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

local instrumentInvSlots

do
    local InvSlotType = InvSlotType
    local ItemPrefab = ItemPrefab

    local xPath = util.xPath

    instrumentInvSlots = setmetatable({}, {
        ---@param t {[Barotrauma.Identifier]:Barotrauma.InvSlotType[]}
        ---@param k Barotrauma.Identifier
        __index=function(t, k)
            local slotString = xPath(ItemPrefab.Prefabs[k].ConfigElement, "Holdable[@slots]").GetAttributeString("slots")
            local allowedSlots = {}
            local i = 0
    
            for slotCombination in slotString:gmatch("([^,]+),?") do
                if slotCombination:lower() ~= "any" then
                    local slots = 0
                    
                    for specSlotString in slotCombination:gmatch("([^%+]+)%+?") do
                        if specSlotString:lower() == "bothhands" then
                            slots = InvSlotType.LeftHand + InvSlotType.RightHand
                        end

                        slots = slots + InvSlotType[specSlotString]
                    end
                    if slots ~= 0 then
                        i = i + 1
                        allowedSlots[i] = slots
                    end
                end
            end
            if i > 0 then
                t[k] = allowedSlots
                return allowedSlots
            end
        end
    })
end

---@param self Types.CommonModule
local function activate(self)
    local Aim = InputType.Aim
    local hornItemId = Identifier("hornitem")
    local idleObjId = Identifier("idle")
    local waitObjId = Identifier("wait")

    local PERFORM = Constants.ID_ORDER.PERFORM
    local RangedWeapon = Components.RangedWeapon
    local Shoot = InputType.Shoot
    local Timer = Timer

    local Contains = util.itertools.Contains

    local ModObjProp
    local ModMainObjProp
    
    do
        local mod = self:AddCommonModule("SBAI.Server.CommonModules.ModifyObjectiveProperties")

        ModObjProp = mod.ModObjProp --[[@type fun(objId:Barotrauma.Identifier, objSuffix:string, propertyName:string, value:any)]]
        ModMainObjProp = mod.ModMainObjProp --[[@type fun(mainObjId:Barotrauma.Identifier, mainObjSuffix:string, subObjId:Barotrauma.Identifier, propertyName:string, value:any)]]

    end

    self:AddPatch("Barotrauma.Items.Components.ItemComponent", "CrewAIOperate", nil,
    function(instance, ptable)
        local objective = ptable["objective"] --[[@type Barotrauma.AIObjective]]

        if objective.Identifier == PERFORM then
            local item = instance.Item
            local character = ptable["character"] --[[@type Barotrauma.Character]]

            character.AIController.SteeringManager.Reset()
            if  Contains(character.HeldItems, item) or
                character.Inventory.TryPutItem(item, character, instrumentInvSlots[item.Prefab.Identifier].slotTypes, true, true)
            then
                character.SetInput(Aim, false, true)
                character.SetInput(Shoot, false, true)
            end
            
            if  item.HasTag(hornItemId) and
                item.GetComponent(RangedWeapon).WasUsed
            then
                Timer.Wait(function() objective.Abandon = true end, 1000)
            end
            return true
        end
    end, Hook.HookMethodType.Before)

    -- self:AddPatch("Barotrauma.AIObjective", "get_ConcurrentObjectives", nil,
    -- function(instance, ptable)
    --     if Contains(concurrentIds, instance.Identifier) then
    --         local curSubObjective = instance.CurrentSubObjective

    --         if  curSubObjective and
    --             curSubObjective.Identifier == PERFORM
    --         then
    --             ptable.PreventExecution = true
    --             return true
    --         end
    --     end
    -- end, Hook.HookMethodType.Before)

    ModMainObjProp(idleObjId, "Idle", PERFORM, "ConcurrentObjectives", true)
    ModMainObjProp(waitObjId, "GoTo", PERFORM, "ConcurrentObjectives", true)
    ModMainObjProp(idleObjId, "Idle", PERFORM, "AllowAutomaticItemUnequipping", false)

    ModObjProp(PERFORM, "OperateItem", "AllowAutomaticItemUnequipping", false)
    ModObjProp(PERFORM, "OperateItem", "AllowMultipleInstances", false)

    -- self:AddPatch("Barotrauma.AIObjectiveIdle", "get_AllowAutomaticItemUnequipping", nil,
    -- function(instance, ptable)
    --     if instance.Identifier == PERFORM then
    --         ptable.PreventExecution = true
    --         return false
    --     end
    -- end, Hook.HookMethodType.Before)

    -- self:AddPatch("Barotrauma.AIObjectiveOperateItem", "get_AllowAutomaticItemUnequipping", nil,
    -- function(instance, ptable)
    --     if instance.Identifier == PERFORM then
    --         ptable.PreventExecution = true
    --         return false
    --     end
    -- end, Hook.HookMethodType.Before)

    -- self:AddPatch("Barotrauma.AIObjectiveOperateItem", "get_AllowMultipleInstances", nil,
    -- function(instance, ptable)
    --     if instance.Identifier == PERFORM then
    --         ptable.PreventExecution = true
    --         return false
    --     end
    -- end, Hook.HookMethodType.Before)
end

return Types.CommonModule.new(activate)