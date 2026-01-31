local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")

local instrumentInvSlots

do
    local InvSlotType = InvSlotType
    local ItemPrefab = ItemPrefab

    local xPath = util.xPath

    instrumentInvSlots = setmetatable({}, {
        ---@param t {[Barotrauma.Identifier]:Barotrauma.InvSlotType[]}
        ---@param k Barotrauma.Identifier
        __index=function(t, k)
            
            local slotString = xPath(ItemPrefab.Prefabs[k].ConfigElement.Element, "Holdable[@slots]")[1].GetAttributeString("slots")
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
    local PERFORM = Constants.ID_ORDER.PERFORM

    local ModObjProp

    ---@param self CommonModule
    function setupObjProperties(self)
        --if ModObjProp then return end
        ModObjProp = self:AddCommonModule("SBAI.Server.CommonModules.ModifyObjectiveProperties") --[[@type fun(propertyName:string, objId:Barotrauma.Identifier, subObjId:Barotrauma.Identifier, value:any)]]
        --ModObjProp("AllowAutomaticItemUnequipping", PERFORM, nil, false)
        ModObjProp("AllowMultipleInstances", PERFORM, nil, false)
        self:AddCommonModule("SBAI.Server.CommonModules.XElementExpansion")
    end
end

---@param self CommonModule
local function activate(self)
    setupObjProperties(self)

    local Aim = InputType.Aim
    local hornItemId = Identifier("hornitem")
    local PERFORM = Constants.ID_ORDER.PERFORM
    local RangedWeapon = Components.RangedWeapon
    local Shoot = InputType.Shoot
    --local Wait = Timer2.Wait

    local Contains = util.itertools.Contains

    self:PatchHook("Barotrauma.Items.Components.ItemComponent", "CrewAIOperate", nil,
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
                objective.Abandon = true
                -- Wait(function()  end, 1000)
            end
            -- ptable.PreventExecution = true
            return false
        end
    end, true)

    --local concurrentIds = {Identifier("idle"), Identifier("wait")}

    -- self:PatchHook("Barotrauma.AIObjective", "get_ConcurrentObjectives", nil,
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
    -- end, true)

    

      --ModObjProp(PERFORM, "OperateItem", "AllowAutomaticItemUnequipping", false)
    

    -- self:PatchHook("Barotrauma.AIObjectiveIdle", "get_AllowAutomaticItemUnequipping", nil,
    -- function(instance, ptable)
    --     if instance.Identifier == PERFORM then
    --         ptable.PreventExecution = true
    --         return false
    --     end
    -- end, true)

    -- self:PatchHook("Barotrauma.AIObjectiveOperateItem", "get_AllowAutomaticItemUnequipping", nil,
    -- function(instance, ptable)
    --     if instance.Identifier == PERFORM then
    --         ptable.PreventExecution = true
    --         return false
    --     end
    -- end, true)

    -- self:PatchHook("Barotrauma.AIObjectiveOperateItem", "get_AllowMultipleInstances", nil,
    -- function(instance, ptable)
    --     if instance.Identifier == PERFORM then
    --         ptable.PreventExecution = true
    --         return false
    --     end
    -- end, true)
end

return GetType("CommonModule").new(activate)