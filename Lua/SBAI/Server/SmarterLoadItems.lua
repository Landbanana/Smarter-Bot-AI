SBAI = require("SBAI")

do
    local LuaUserData = LuaUserData
    local descriptor --[[@type MoonSharp.Interpreter.Interop.IUserDataDescriptor]]

    LuaUserData.RegisterType("Barotrauma.AIObjectiveMoveItem")

    descriptor = SBAI.LuaUserData.RegisterType("Barotrauma.AIObjectiveLoadItems")
    LuaUserData.MakePropertyAccessible(descriptor, "TargetContainerTags")
    -- LuaUserData.MakePropertyAccessible(descriptor, "TargetCondition")
    -- LuaUserData.MakePropertyAccessible(descriptor, "TargetContainerTags")
    -- descriptor = Descriptors["Barotrauma.AIObjective"]
    -- LuaUserData.MakeMethodAccessible(descriptor, "CanEquip")

    descriptor = LuaUserData.RegisterType("Barotrauma.AIObjectiveLoadItem")
    LuaUserData.MakeMethodAccessible(descriptor, "CanEquip")
    -- LuaUserData.MakeMethodAccessible(descriptor, "GetPriority")
    -- LuaUserData.MakeMethodAccessible(descriptor, "IgnoreTargetItem")
    LuaUserData.MakeMethodAccessible(descriptor, "IsValidContainable")
    -- LuaUserData.MakePropertyAccessible(descriptor, "AllValidContainableItemIdentifiers")
    -- LuaUserData.MakePropertyAccessible(descriptor, "IsCompleted")
    -- LuaUserData.MakePropertyAccessible(descriptor, "ValidContainableItemIdentifiers")
    LuaUserData.MakePropertyAccessible(descriptor, "TargetContainerTags")
    LuaUserData.MakePropertyAccessible(descriptor, "Container")
    LuaUserData.MakePropertyAccessible(descriptor, "ItemContainer")
    -- LuaUserData.MakeFieldAccessible(descriptor, "abandonGetItemDialogueIdentifier")
    -- LuaUserData.MakeFieldAccessible(descriptor, "moveItemObjective")
    LuaUserData.MakeFieldAccessible(descriptor, "targetItem")
    -- LuaUserData.MakeFieldAccessible(descriptor, "itemIndex")
    LuaUserData.MakeFieldAccessible(descriptor, "ignoredItems")
    -- LuaUserData.MakeFieldAccessible(descriptor, "subObjectives")

    -- descriptor = Descriptors["Barotrauma.AIObjectiveContainItem"]
    -- LuaUserData.MakeFieldAccessible(descriptor, "item")
    -- LuaUserData.MakeMethodAccessible(descriptor, "CheckObjectiveState")

    -- descriptor = Descriptors["Barotrauma.Items.Components.ItemContainer"]
    -- LuaUserData.MakeFieldAccessible(descriptor, "slotRestrictions")
    -- LuaUserData.RegisterType("Barotrauma.Items.Components.ItemContainer+SlotRestrictions")

    -- descriptor = Descriptors["Barotrauma.ItemInventory"]
    -- LuaUserData.MakeFieldAccessible(descriptor, "slots")
end

local AIObjectiveLoadItems = LuaUserData.CreateStatic("Barotrauma.AIObjectiveLoadItems")

local function StaticFindItem(newItem)
    return  SBAI.util.ParentItemsHaveDontTakeItemsTag(newItem) or
        newItem.ConditionIncreasedRecently
end

---@param namespace Namespace
---@param options table<string,any>
return function(namespace, options)
for loadType, itemTag, containableTag, refillerTag in SBAI.util.Variator({
            {"BatteryCells", "mobilebattery", "mobilebattery", "batterycellrecharger"},
            {"OxygenTanks", "refillableoxygensource", "oxygensource", "oxygentankrefiller"}
        })
do --[[@cast loadType string]] --[[@cast itemTag string]] --[[@cast containableTag string]] --[[@cast refillerTag string]]
    local section = options[loadType]
    local minimumCondition

    if not section.enable then goto continue end

    minimumCondition = section["minimumCondition"]

    namespace = namespace + loadType

    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveLoadItem", "IsValidContainable",
    ---@param instance Barotrauma.AIObjective
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function(instance, ptable)
        if instance.TargetContainerTags[1] == refillerTag then
            ptable.PreventExecution = true
            return SBAI.util.MatchItem(instance.character, ptable["item"], nil, nil,
            ---@param character Barotrauma.Character
            ---@param item Barotrauma.Item
            ---@return boolean
            function(character, item)
                if SBAI.util.ValsContain(instance.ignoredItems, item) or SBAI.util.ParentItemsHaveDontTakeItemsTag(item) then
                    return false
                end

                --local destContainer = instance.Container

                if not character.HasItem(item) and not instance.CanEquip(item, false) then
                    local container = item.Container

                    return not item.IsFullCondition and
                        not item.ConditionIncreasedRecently and
                        not (
                            container and
                            container.HasTag(refillerTag) and
                            SBAI.util.PoweredItemHasNeededPower(container)
                        )

                    -- if item.IsFullCondition then
                    --     return not destContainer.HasTag(refillerTag) and
                    --         container.HasTag(refillerTag) and
                    --         SBAI.util.IsSpecifiedContainer(destContainer, containableTag)
                    --         --maybe add something here to check if destContainer already has a full battery
                    -- elseif item.ConditionPercentage <= minimumCondition then
                    --     return destContainer.HasTag(refillerTag)
                    -- end
                end
                return true
            end)
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
                ptable.PreventExecution = true

                item = SBAI.util.FindItem(character, SBAI.itemGroup[itemTag], nil, {0, minimumCondition},
                ---@param _ Barotrauma.Character
                ---@param newItem Barotrauma.Item
                ---@return boolean
                function(_, newItem)
                    if  SBAI.util.ValsContain(instance.ignoredItems, newItem) or
                        newItem.ConditionPercentage >= minimumCondition or
                        StaticFindItem(newItem)
                    then
                        return false
                    end

                    local container = newItem.Container

                    return  not (
                            container and
                            container.HasTag(refillerTag) and
                            SBAI.util.PoweredItemHasNeededPower(container)
                        )
                end)
                
                if item == nil then
                    instance.Abandon = true
                end
                instance.targetItem = item
            end
        end
    end, Hook.HookMethodType.Before)
-- cut off
                --     local targetItem --[[@type Barotrauma.Item?]]
                --     local targetContainer --[[@type Barotrauma.Item|Barotrauma.Items.Components.ItemContainer?]]
                --     local container = item.Container --[[@type Barotrauma.Item?]]
                    
                --     if container and SBAI.util.IsSpecifiedContainer(container, containableTag) then
                --         local potentialContainer = SBAI.util.GetClosest(item.WorldPosition, SBAI.util.FindSpecificContainers(character, SBAI.itemGroup[refillerTag], containableTag, nil, 100, nil, true, RefillerPredicate)) --[[@type Barotrauma.Item]]
                        
                --         if potentialContainer then
                --             targetItem = SBAI.util.FindItem(character, potentialContainer.OwnInventory.FindAllItems(nil, false), itemTag, 100) --[[@type Barotrauma.Item]]
                --             targetContainer = item.Container
                --         end
                --     else
                --         targetItem = item
                --         for hasEmptySlots in {true, false} do
                --             targetContainer = SBAI.util.GetClosest(item.WorldPosition, SBAI.util.FindSpecificContainers(character, SBAI.itemGroup[refillerTag], containableTag, nil, nil, hasEmptySlots, true, RefillerPredicate))
                --             if targetContainer then break end
                --         end
                --     end

                --     if targetItem and targetContainer then
                --         instance.targetItem = targetItem
                --         --instance.targetContainer = targetContainer.GetComponent(Components.ItemContainer)
                --     end
                
                --     instance.objectiveManager.GetObjective(AIObjectiveIdle).wander(ptable["deltaTime"])
                -- end

            --     if not instance.moveItemObjective and not (targetItem and targetContainer) then
            --         instance.IgnoreTargetItem()
            --         instance.Reset()
            --         return
            --     end

            --     if targetItem and targetContainer then
            --         targetContainer = targetContainer.GetComponent(Components.ItemContainer)

            --         ---@return Barotrauma.AIObjectiveMoveItem
            --         ---@nodiscard
            --         local function constructor()
            --             local objective = AIObjectiveMoveItem(character, targetItem, instance.objectiveManager, nil, targetContainer, instance.PriorityModifier)

            --             objective.AbandonGetItemDialogueIdentifier = instance.abandonGetItemDialogueIdentifier
            --             objective.DropIfFails = true
            --             objective.Equip = true
            --             objective.RemoveExistingMax = 1
            --             objective.RemoveExistingWhenNecessary = true
            --             return objective
            --         end
                        
            --         ---@param objective Barotrauma.AIObjective
            --         ---@return fun()
            --         ---@nodiscard
            --         local function onCompletedGenerator(objective)
            --             return function()
            --                 --instance.character.AIController.HandleRelocation(instance.targetItem)
            --                 instance.IsCompleted = true
            --                 instance.RemoveSubObjective(AIObjectiveMoveItem, objective)
            --             end
            --         end

            --         ---@param objective Barotrauma.AIObjective
            --         ---@return fun()
            --         ---@nodiscard
            --         local function onAbandonGenerator(objective)
            --             return function()
            --                 instance.IgnoreTargetItem()
            --                 instance.Reset()
            --             end
            --         end
            --         _, instance.moveItemObjective = SBAI.util.TryAddSubObjective(instance, instance.moveItemObjective, constructor, onCompletedGenerator, onAbandonGenerator)
            --     end
            -- end
            
    --     end
    -- end, Hook.HookMethodType.Before)

    -- SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveLoadItem", "get_ItemContainer",
    -- ---@param instance Barotrauma.AIObjectiveLoadItem
    -- ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    -- function(instance, ptable)
    --     if instance.TargetContainerTags[1] == refillerTag then
    --         local item = instance.targetItem

    --         if item then
    --             local character = instance.character --[[@type Barotrauma.Character]]
    --             local moveItemObjective = instance.moveItemObjective --[[@type Barotrauma.AIObjectiveMoveItem]]
    --             local originalInventory = ptable.OriginalReturnValue.Inventory --[[@type Barotrauma.ItemInventory]]

    --             if  moveItemObjective then
    --                 if  not originalInventory.CanBePut(item) and
    --                     not SBAI.util.FindItem(character, originalInventory.FindAllItems(nil, false), itemTag, 100)
    --                 then
    --                     moveItemObjective.Abandon = true
    --                 end
    --             else
    --                 local container = item.Container --[[@type Barotrauma.Item?]]
    --                 local targetItem --[[@type Barotrauma.Item?]]
    --                 local targetContainer --[[@type Barotrauma.Item|Barotrauma.Items.Components.ItemContainer?]]
                    
    --                 if container and SBAI.util.IsSpecifiedContainer(container, containableTag) then
    --                     local potentialContainer = SBAI.util.GetClosest(item.WorldPosition, SBAI.util.FindSpecificContainers(character, SBAI.itemGroup[refillerTag], containableTag, nil, 100, nil, true, RefillerPredicate)) --[[@type Barotrauma.Item]]
                        
    --                     if potentialContainer then
    --                         targetItem = SBAI.util.FindItem(character, potentialContainer.OwnInventory.FindAllItems(nil, false), itemTag, 100) --[[@type Barotrauma.Item]]
    --                         targetContainer = item.Container
    --                     end
    --                 else
    --                     targetItem = item
    --                     for hasEmptySlots in {true, false} do
    --                         targetContainer = SBAI.util.GetClosest(item.WorldPosition, SBAI.util.FindSpecificContainers(character, SBAI.itemGroup[refillerTag], containableTag, nil, nil, hasEmptySlots, true, RefillerPredicate))
    --                         if targetContainer then break end
    --                     end
    --                 end

    --                 if targetItem and targetContainer then
    --                     ptable.PreventExecution = true

    --                     instance.targetItem = targetItem
    --                     return targetContainer.GetComponent(Components.ItemContainer)
    --                 end
    --             end
    --         end
    --     end
    -- end, Hook.HookMethodType.After)

    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveMoveItem", ".ctor", {"Barotrauma.Character", "Barotrauma.Item", "Barotrauma.AIObjectiveManager", "Barotrauma.Items.Components.ItemContainer", "Barotrauma.Items.Components.ItemContainer", "System.Single"},
    ---@param instance Barotrauma.AIObjectiveMoveItem
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function(instance, ptable)
        local destContainer = ptable["targetContainer"] --[[@type Barotrauma.Items.Components.ItemContainer?]]
        
        if  not ptable["sourceContainer"] and
            destContainer
        then
            local character = ptable["character"] --[[@type Barotrauma.Character]]
            local humanAIController = character.AIController
            local loadItemsOrder = humanAIController.ObjectiveManager.GetOrder(AIObjectiveLoadItems) --[[@type Barotrauma.AIObjectiveLoadItems?]]

            if  loadItemsOrder and
                loadItemsOrder.TargetContainerTags[1] == refillerTag
            then --[[@cast destContainer -nil]]
                local item = ptable["targetItem"] --[[@type Barotrauma.Item]]
                local container = item.Container
                
                if  container and
                    not container.HasTag(refillerTag) and
                    SBAI.util.IsSpecifiedContainer(container, containableTag)
                then
                    local fullItem = SBAI.util.FindItem(character, destContainer.Inventory.FindAllItems(), itemTag, 100) --[[@type Barotrauma.Item]]
                    local targetContainer = container.GetComponent(Components.ItemContainer) --[[@type Barotrauma.Items.Components.ItemContainer]]

                    if fullItem and targetContainer then
                        ptable["targetContainer"] = targetContainer
                        ptable["targetItem"] = fullItem
                    else
                        instance.Abandon = true
                    end
                end
            end
        end
    end, Hook.HookMethodType.Before)

    -- SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveLoadItem", "GetPriority",
    -- ---@param instance Barotrauma.AIObjective
    -- ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    -- function(instance, ptable)
    --     if instance.TargetContainerTags[1] == refillerTag then
    --         local moveItemObjective = instance.moveItemObjective --[[@type Barotrauma.AIObjectiveMoveItem]]

    --         ptable["Contaienr"]
    --     end
    -- end, Hook.HookMethodType.Before)

    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveContainItem", "Act",
    ---@param instance Barotrauma.AIObjectiveContainItem
    ---@param _ Barotrauma.LuaCsHook.ParameterTable
    function(instance, _)
        if  not instance.TargetSlot and
            instance.RemoveExistingPredicate
        then
            local sourceObjective = instance.SourceObjective

            if sourceObjective then
                sourceObjective = sourceObjective.SourceObjective
                
                if  sourceObjective and
                    sourceObjective.Identifier == "load item" and
                    sourceObjective.TargetContainerTags[1] == refillerTag
                then
                    local index = SBAI.util.GetSpecificSlot(instance.container.Item, containableTag)

                    if index then
                        instance.TargetSlot = index
                        instance.RemoveExistingPredicate = nil
                        instance.AllowDangerousPressure = false
                        instance.AllowToFindDivingGear = false
                    end
                end
            end
        end
    end, Hook.HookMethodType.Before)

    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveLoadItems", "ItemMatchesTargetCondition",
    ---@param _ Barotrauma.AIObjectiveLoadItems
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function(_, ptable)
        local item = ptable["item"]

        if item and item.HasTag(itemTag) then
            local container = item.container

            ptable.PreventExecution = true

            return item.Container ~= nil and
                SBAI.util.IsSpecifiedContainer(container, itemTag) and
                not container.HasTag(refillerTag) and
                item.ConditionPercentage >= minimumCondition or
                item.IsFullCondition
        end
    end, Hook.HookMethodType.Before)

    -- SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveLoadItem", "GetPriority",
    -- ---@param instance Barotrauma.AIObjective
    -- ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    -- function(instance, ptable)
    --     if instance.TargetContainerTags[1] == refillerTag then
    --         if  not instance.IsAllowed then
    --             instance.HandleDisallowed()
    --             return Priority
    --         elseif not AIObjectiveLoadItems.IsValidTarget(instance.Container, instance.character, nil, instance.TargetItemCondition) then
    --             instance.Priority = 0
    --         elseif instance.targetItem == nil then
    --             instance.Priority = 0
    --         else
    --             local dist = 0.0
    --             local function AddDistance(startPos, targetPos)
    --                 local yDist = math.Abs(startPos.Y - targetPos.Y)
                    
    --                 if yDist > 100 then dist = yDist + yDist end
    --                 dist = dist + math.Abs(instance.character.WorldPosition.X - targetPos.X)
    --             end

    --             local distanceFactor = instance.GetDistanceFactor(instance.targetItem.WorldPosition, nil, 5, 5000, 0.9, 0)

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
    --                 if instance.moveItemObjective and instance.targetItem.Container ~= instance.Container then
    --                     if not instance.IsValidContainable(instance.targetItem) then
    --                         instance.moveItemObjective.Abandon = true
    --                     elseif not instance.ItemContainer.Inventory.CanBePut(instance.targetItem) then
    --                         for item in instance.ItemContainer.Inventory.AllItems do
    --                             --item.endNone instance.ItemMatchesTargetCondition(TargetItemCondition
    --                         end
    --                     end

    --                     instance.moveItemObjective.Abandon = true

    --                     if instance.ItemContainer.Inventory.IsFull() then
    --                         Priority = Priority/4
    --                     end
    --                 end
    --             return Priority
    --         end
    --     end
    -- end, Hook.HookMethodType.Before)
::continue::
end
end