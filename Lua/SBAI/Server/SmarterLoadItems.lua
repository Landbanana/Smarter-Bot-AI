local SBAI = require("SBAI")

--local descriptor = SBAI.LuaUserData.RegisterType("Barotrauma.AIObjectiveLoadItems")
--SBAI.LuaUserData.MakePropertyAccessible(descriptor, "TargetCondition")
--SBAI.LuaUserData.MakePropertyAccessible(descriptor, "TargetContainerTags")

local descriptor = SBAI.LuaUserData.RegisterType("Barotrauma.AIObjectiveLoadItem")
SBAI.LuaUserData.MakeMethodAccessible(descriptor, "CanEquip")
--SBAI.LuaUserData.MakeMethodAccessible(descriptor, "GetPriority")
SBAI.LuaUserData.MakeMethodAccessible(descriptor, "IgnoreTargetItem")
SBAI.LuaUserData.MakeMethodAccessible(descriptor, "IsValidContainable")
--SBAI.LuaUserData.MakePropertyAccessible(descriptor, "AllValidContainableItemIdentifiers")
SBAI.LuaUserData.MakePropertyAccessible(descriptor, "IsCompleted")
--SBAI.LuaUserData.MakePropertyAccessible(descriptor, "ValidContainableItemIdentifiers")
SBAI.LuaUserData.MakePropertyAccessible(descriptor, "TargetContainerTags")
SBAI.LuaUserData.MakePropertyAccessible(descriptor, "Container")
SBAI.LuaUserData.MakePropertyAccessible(descriptor, "ItemContainer")
SBAI.LuaUserData.MakeFieldAccessible(descriptor, "abandonGetItemDialogueIdentifier")
SBAI.LuaUserData.MakeFieldAccessible(descriptor, "decontainObjective")
SBAI.LuaUserData.MakeFieldAccessible(descriptor, "targetItem")
--SBAI.LuaUserData.MakeFieldAccessible(descriptor, "itemIndex")
SBAI.LuaUserData.MakeFieldAccessible(descriptor, "ignoredItems")
--SBAI.LuaUserData.MakeFieldAccessible(descriptor, "subObjectives")

-- descriptor = Descriptors["Barotrauma.AIObjectiveContainItem"]
-- SBAI.LuaUserData.MakeFieldAccessible(descriptor, "item")
--SBAI.LuaUserData.MakeMethodAccessible(descriptor, "CheckObjectiveState")

descriptor = Descriptors["Barotrauma.Items.Components.ItemContainer"]
SBAI.LuaUserData.MakeFieldAccessible(descriptor, "slotRestrictions")
SBAI.LuaUserData.RegisterType("Barotrauma.Items.Components.ItemContainer+SlotRestrictions")

-- descriptor = Descriptors["Barotrauma.ItemInventory"]
-- LuaUserData.MakeFieldAccessible(descriptor, "slots")

local loadTypeToTargetItemTag = {
    BatteryCells="mobilebattery",
    OxygenTanks="refillableoxygensource"
}


do  for loadType , itemTag, containableTag, refillerTag in 
        SBAI.util.Variator({{"BatteryCells", loadTypeToTargetItemTag["BatteryCells"], SBAI.util.convert.ItemTagToContainableItemTag[loadTypeToTargetItemTag["BatteryCells"]], SBAI.util.convert.ItemTagToRefillerTag[loadTypeToTargetItemTag["BatteryCells"]]},
        {"OxygenTanks", loadTypeToTargetItemTag["OxygenTanks"], SBAI.util.convert.ItemTagToContainableItemTag[loadTypeToTargetItemTag["OxygenTanks"]], SBAI.util.convert.ItemTagToRefillerTag[loadTypeToTargetItemTag["OxygenTanks"]]}})
    do --[[@cast loadType string]] --[[@cast itemTag string]] --[[@cast containableTag string]] --[[@cast refillerTag string]]
        AIObjectiveLoadItems = LuaUserData.CreateStatic("Barotrauma.AIObjectiveLoadItems")
---@param namespace Namespace
---@param options table<string,any>
return function(namespace, options)
    local minimumCondition = options[loadType]["minimumCondition"]
    namespace = namespace + loadType
local function RefillerPredicate(character, item)
    return AIObjectiveLoadItems.IsValidTarget(item, character)
end
---@param objective Barotrauma.AIObjective
---@return fun(character?:Barotrauma.Character, item?:Barotrauma.Item):boolean
local function GenerateItemPredicate(objective, minimumCondition)
    ---@param character Barotrauma.Character
    ---@param item Barotrauma.Item
    ---@return boolean
    return function(character, item)
        if SBAI.util.ListContains(objective.ignoredItems, item) then return false end

        local parentItem = item.Container

        while parentItem ~= nil do
            if parentItem.HasTag("donttakeitems") then return false end
            parentItem = parentItem.Container
        end
        
        -- for i in objective.ValidContainableItemIdentifiers do
        --     if containableItemTag ~= nil then break end
        --     containableItemTag = SBAI.util.convert.ItemTagToContainableItemTag[i]
        -- end
        if  not character.HasItem(item) and not objective.CanEquip(item, false) or
            not objective.ItemContainer.CanBeContained(item) or (
                item.Container ~= nil and
                SBAI.util.IsSpecifiedContainer(item.Container, containableTag) and
                item.ConditionPercentage >= minimumCondition or
                item.IsFullCondition and not item.Container.HasTag(refillerTag)or
                item.ConditionIncreasedRecently) then
                return false
            end
        return true
    end
end

SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveLoadItem", "IsValidContainable",
---@param instance Barotrauma.AIObjective
---@param ptable Barotrauma.LuaCsHook.ParameterTable
function(instance, ptable)
    if instance.TargetContainerTags[1] == refillerTag then
        ptable.PreventExecution = true

        return SBAI.util.MatchItem(instance.character, ptable["item"], nil, nil, GenerateItemPredicate(instance, minimumCondition))
    end
end, Hook.HookMethodType.Before)

SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveLoadItem", "Act",
---@param instance Barotrauma.AIObjective
---@param ptable Barotrauma.LuaCsHook.ParameterTable
function(instance, ptable)
    if instance.TargetContainerTags[1] == refillerTag then
        local character = instance.character --[[@type Barotrauma.Character]]
        local item = instance.targetItem --[[@type Barotrauma.Item]]

        if item == nil then
            item = SBAI.util.FindItem(character, SBAI.itemGroup[itemTag], itemTag, {0, minimumCondition}, GenerateItemPredicate(instance, minimumCondition))
            if item == nil then
                instance.Abandon = true
            end
            instance.targetItem = item
            instance.objectiveManager.GetObjective(AIObjectiveIdle).wander(ptable["deltaTime"])
        else
            local targetItem --[[@type Barotrauma.Item?]]
            local targetContainer --[[@type Barotrauma.Item|Barotrauma.Items.Components.ItemContainer?]]
            local container = item.Container --[[@type Barotrauma.Item?]]

            if container and SBAI.util.IsSpecifiedContainer(container, containableTag) then
                local potentialContainer = SBAI.util.GetClosest(item.WorldPosition, SBAI.util.FindSpecificContainers(character, SBAI.itemGroup[refillerTag], containableTag, nil, 100, nil, true, RefillerPredicate)) --[[@type Barotrauma.Item]]
                
                if potentialContainer then
                    targetItem = SBAI.util.FindItem(character, potentialContainer.OwnInventory.FindAllItems(nil, false), targetItemTag, 100) --[[@type Barotrauma.Item]]
                    targetContainer = item.Container
                end
            else
                targetItem = item
                for hasEmptySlots in {true, false} do
                    targetContainer = SBAI.util.GetClosest(item.WorldPosition, SBAI.util.FindSpecificContainers(character, SBAI.itemGroup[refillerTag], containableTag, nil, nil, hasEmptySlots, true, RefillerPredicate))
                    if targetContainer then break end
                end
            end

            if not instance.decontainObjective and not (targetItem and targetContainer) then
                instance.IgnoreTargetItem()
                instance.Reset()
                return
            end

            if targetItem and targetContainer then
                targetContainer = targetContainer.GetComponent(Components.ItemContainer)

                ---@return Barotrauma.AIObjectiveDecontainItem
                ---@nodiscard
                local function constructor()
                    local objective = AIObjectiveDecontainItem(character, targetItem, instance.objectiveManager, nil, targetContainer, instance.PriorityModifier)

                    objective.AbandonGetItemDialogueIdentifier = instance.abandonGetItemDialogueIdentifier
                    objective.DropIfFails = true
                    objective.Equip = true
                    objective.RemoveExistingMax = 1
                    objective.RemoveExistingWhenNecessary = true
                    return objective
                end
                    
                ---@param objective Barotrauma.AIObjective
                ---@return fun()
                ---@nodiscard
                local function onCompletedGenerator(objective)
                    return function()
                        --instance.character.AIController.HandleRelocation(instance.targetItem)
                        instance.IsCompleted = true
                        instance.RemoveSubObjective(AIObjectiveDecontainItem, objective)
                        ptable.PreventExecution = true
                    end
                end

                ---@param objective Barotrauma.AIObjective
                ---@return fun()
                ---@nodiscard
                local function onAbandonGenerator(objective)
                    return function()
                        instance.IgnoreTargetItem()
                        instance.Reset()
                    end
                end
                _, instance.decontainObjective = SBAI.util.TryAddSubObjective(instance, instance.decontainObjective, constructor, onCompletedGenerator, onAbandonGenerator)
            end
        end
    end
end, Hook.HookMethodType.Before)

SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveContainItem", "Act",
---@param instance Barotrauma.AIObjectiveContainItem
---@param _ Barotrauma.LuaCsHook.ParameterTable
function(instance, _)
    if  not instance.TargetSlot and
        instance.SourceObjective and
        instance.SourceObjective.SourceObjective and
        SBAI.LuaUserData.IsTargetType(instance.SourceObjective.SourceObjective, "Barotrauma.AIObjectiveLoadItem") and
        instance.SourceObjective.SourceObjective.TargetContainerTags[1] == refillerTag
    then
        local index = SBAI.util.GetSpecificSlot(instance.container.Item, containableTag)

        if index then
            instance.TargetSlot = index
            instance.AllowDangerousPressure = false
            instance.AllowToFindDivingGear = false
        end
    end
end, Hook.HookMethodType.Before)

SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveLoadItems", "ItemMatchesTargetCondition",
---@param instance Barotrauma.AIObjective
---@param ptable Barotrauma.LuaCsHook.ParameterTable
function(instance, ptable)
    local item = ptable["item"]

    if item.HasTag(itemTag) then
        ptable.PreventExecution = true
        return item.Container ~= nil and
            SBAI.util.IsSpecifiedContainer(item.Container, itemTag) and
            item.ConditionPercentage >= minimumCondition or
            item.IsFullCondition
        end
    end, Hook.HookMethodType.Before)

    -- SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveLoadItem", "GetPriority",
    -- ---@param instance Barotrauma.AIObjective
    -- ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    -- function(instance, ptable)
    --         if instance.TargetContainerTags[1] == refillerTag then
    --             if  not instance.IsAllowed then
    --                 instance.HandleDisallowed()
    --                 return Priority
    --             elseif not AIObjectiveLoadItems.IsValidTarget(instance.Container, instance.character, nil, instance.TargetItemCondition) then
    --                 instance.Priority = 0
    --             elseif instance.targetItem == nil then
    --                 instance.Priority = 0
    --             else
    --             local dist = 0.0
    --             local function AddDistance(startPos, targetPos)
    --             local yDist = math.Abs(startPos.Y - targetPos.Y)
                
    --             if yDist > 100 then dist = yDist + yDist end
                
    --             dist = dist + math.Abs(instance.character.WorldPosition.X - targetPos.X)
    --             end

    --             local distanceFactor =  instance.GetDistanceFactor(instance.targetItem.WorldPosition, nil, 5, 5000, 0.9, 0)

    --             if instance.character.CurrentHull ~= instance.targetItem.CurrentHull then
    --                 AddDistance(instance.character.WorldPosition, instance.targetItem.WorldPosition)
    --             end

    --             if instance.targetItem.CurrentHull ~= instance.Container.CurrentHull then
    --                 AddDistance(instance.targetItem.WorldPosition, instance.Container.WorldPosition)
    --             end
    --                 local hasContainable = instance.character.HasItem(instance.targetItem)
    --                 local devotion = (instance.CumulatedDevotion + (hasContainable and (100 - instance.MaxDevotion) or 0))/100
    --                 local max = AIObjectiveManager.LowestOrderPriority - (hasContainable and 1 or 2)
    --                 instance.Priority = math.lerp(0, max, math.clamp(devotion + (distanceFactor * instance.PriorityModifier), 0, 1))
    --                 if instance.decontainObjective and instance.targetItem.Container ~= instance.Container then
    --                 if not instance.IsValidContainable(instance.targetItem) then
    --                     instance.decontainObjective.Abandon = true;
    --                 elseif not instance.ItemContainer.Inventory.CanBePut(instance.targetItem) then
    --                     for item in instance.ItemContainer.Inventory.AllItems do
    --                         --item.endNone instance.ItemMatchesTargetCondition(TargetItemCondition
    --                     end
    --                 end instance.decontainObjective.Abandon = true;
    --                     if instance.ItemContainer.Inventory.IsFull() then Priority = Priority/4; end
                        
    --                 end 
    --                 return Priority;
    --             end namespace = -namespace
    --         end, Hook.HookMethodType.Before)end
end
end
end