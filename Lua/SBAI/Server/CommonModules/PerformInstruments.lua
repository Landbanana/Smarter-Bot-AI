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

local setupObjProperties

do
    local IDLE = Constants.ID_OBJECTIVE_BASE.IDLE
    local PERFORM = Constants.ID_ORDER.PERFORM
    local WAIT = Constants.ID_OBJECTIVE_BASE.WAIT

    local ModObjProp

    function setupObjProperties(self)
        if ModObjProp then return end
        ModObjProp = self:AddCommonModule("SBAI.Server.CommonModules.ModifyObjectiveProperties") --[[@type fun(propertyName:string, objId:Barotrauma.Identifier, subObjId:Barotrauma.Identifier, value:any)]]

        ModObjProp("ConcurrentObjectives", IDLE, PERFORM, true)
        ModObjProp("ConcurrentObjectives", WAIT, PERFORM, true)
        ModObjProp("AllowAutomaticItemUnequipping", IDLE, PERFORM, false)
        ModObjProp("AllowMultipleInstances", PERFORM, nil, false)
    end
end

---@param self Types.CommonModule
local function activate(self)
    setupObjProperties(self)

    local Aim = InputType.Aim
    local hornItemId = Identifier("hornitem")
    local PERFORM = Constants.ID_ORDER.PERFORM
    local RangedWeapon = Components.RangedWeapon
    local Shoot = InputType.Shoot
    local Timer = Timer

    local Contains = util.itertools.Contains

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
            
            return false
        end
    end, Hook.HookMethodType.Before)

    --local concurrentIds = {Identifier("idle"), Identifier("wait")}

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

    

      --ModObjProp(PERFORM, "OperateItem", "AllowAutomaticItemUnequipping", false)
    

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