local SBAI = require("SBAI")

local descriptor = SBAI.LuaUserData.RegisterType("Barotrauma.AIObjectiveLoadItems")
SBAI.LuaUserData.MakePropertyAccessible(descriptor, "TargetCondition")
SBAI.LuaUserData.MakePropertyAccessible(descriptor, "TargetContainerTags")

descriptor = SBAI.LuaUserData.RegisterType("Barotrauma.AIObjectiveLoadItem")
SBAI.LuaUserData.MakeMethodAccessible(descriptor, "CanEquip")
SBAI.LuaUserData.MakeMethodAccessible(descriptor, "IgnoreTargetItem")
SBAI.LuaUserData.MakeMethodAccessible(descriptor, "IsValidContainable")
SBAI.LuaUserData.MakePropertyAccessible(descriptor, "AllValidContainableItemIdentifiers")
SBAI.LuaUserData.MakePropertyAccessible(descriptor, "IsCompleted")
SBAI.LuaUserData.MakePropertyAccessible(descriptor, "ValidContainableItemIdentifiers")
SBAI.LuaUserData.MakePropertyAccessible(descriptor, "TargetContainerTags")
SBAI.LuaUserData.MakePropertyAccessible(descriptor, "Container")
SBAI.LuaUserData.MakePropertyAccessible(descriptor, "ItemContainer")
SBAI.LuaUserData.MakeFieldAccessible(descriptor, "abandonGetItemDialogueIdentifier")
SBAI.LuaUserData.MakeFieldAccessible(descriptor, "decontainObjective")
SBAI.LuaUserData.MakeFieldAccessible(descriptor, "targetItem")
SBAI.LuaUserData.MakeFieldAccessible(descriptor, "itemIndex")
SBAI.LuaUserData.MakeFieldAccessible(descriptor, "ignoredItems")
SBAI.LuaUserData.MakeFieldAccessible(descriptor, "subObjectives")

descriptor = Descriptors["Barotrauma.AIObjectiveContainItem"]
SBAI.LuaUserData.MakeFieldAccessible(descriptor, "item")
SBAI.LuaUserData.MakeMethodAccessible(descriptor, "CheckObjectiveState")

descriptor = Descriptors["Barotrauma.Items.Components.ItemContainer"]
SBAI.LuaUserData.MakeFieldAccessible(descriptor, "slotRestrictions")
SBAI.LuaUserData.RegisterType("Barotrauma.Items.Components.ItemContainer+SlotRestrictions")

descriptor = Descriptors["Barotrauma.ItemInventory"]
LuaUserData.MakeFieldAccessible(descriptor, "slots")

---@param namespace Namespace
---@param options table
return function(namespace, options)
    local AIObjectiveLoadItems = LuaUserData.CreateStatic("Barotrauma.AIObjectiveLoadItems")

    local loadTypeToTargetItemTag = {
        ["BatteryCells"]="mobilebattery",
        ["OxygenTanks"]="refillableoxygensource"
    }

    local function RefillerPredicate(character, item)
        return AIObjectiveLoadItems.IsValidTarget(item, character)
    end

    ---@param objective Barotrauma.AIObjective
    ---@param minimumCondition number
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
            
            if  not character.HasItem(item) and not objective.CanEquip(item, false) or
                not objective.ItemContainer.CanBeContained(item) or (
                    item.Container ~= nil and
                    SBAI.util.IsSpecifiedContainer(item.Container, item) and
                    item.ConditionPercentage >= minimumCondition or
                    item.IsFullCondition
                ) and
                item.ConditionIncreasedRecently
                    then
                return false
            end
            return true
        end
    end

    for _, loadType in pairs({"BatteryCells", "OxygenTanks"}) do
        local section = options[loadType]
        local targetItemTag, targetContainableItemTag, refillerTag, minimumCondition
        
        if not section.enable then goto continue end

        namespace = namespace + loadType

        targetItemTag = loadTypeToTargetItemTag[loadType]
        targetContainableItemTag = SBAI.util.convert.ItemTagToContainableItemTag[targetItemTag]
        refillerTag = SBAI.util.convert.ItemTagToRefillerTag[targetItemTag]
        minimumCondition = section["minimumCondition"] --[[@type number]]

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

                ptable.PreventExecution = true

                if item == nil then
                    item = SBAI.util.FindItem(character, SBAI.itemGroup[targetItemTag], targetItemTag, {0, minimumCondition}, GenerateItemPredicate(instance, minimumCondition))
                    if item == nil then
                        instance.Abandon = true
                    end
                    instance.targetItem = item
                    instance.objectiveManager.GetObjective(AIObjectiveIdle).wander(ptable["deltaTime"])
                else
                    local targetItem = nil --[[@type Barotrauma.Item?]]
                    local targetContainer = nil --[[@type Barotrauma.Item|Barotrauma.Items.Components.ItemContainer?]]
                    local container = item.Container --[[@type Barotrauma.Item?]]

                    if container and SBAI.util.IsSpecifiedContainer(container, item) then
                        local potentialContainer = SBAI.util.GetClosest(item.WorldPosition, SBAI.util.FindSpecificContainers(character, SBAI.itemGroup[refillerTag], targetContainableItemTag, nil, 100, nil, true, RefillerPredicate)) --[[@type Barotrauma.Item]]
                        
                        if potentialContainer then
                            targetItem = SBAI.util.FindItem(character, potentialContainer.OwnInventory.FindAllItems(nil, false), targetItemTag, 100) --[[@type Barotrauma.Item]]
                            targetContainer = item.Container
                        end
                    else
                        targetItem = item
                        for _, hasEmptySlots in pairs({true, false}) do
                            targetContainer = SBAI.util.GetClosest(item.WorldPosition, SBAI.util.FindSpecificContainers(character, SBAI.itemGroup[refillerTag], targetContainableItemTag, nil, nil, hasEmptySlots, true, RefillerPredicate))
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
                                instance.IsCompleted = true
                                instance.RemoveSubObjective(AIObjectiveDecontainItem, objective)
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

                        local decontainObjectiveRef = {instance.decontainObjective}

                        SBAI.util.TryAddSubObjective(instance, decontainObjectiveRef, constructor, onCompletedGenerator, onAbandonGenerator)
                        instance.decontainObjective = decontainObjectiveRef[1]
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
                local index = SBAI.util.GetSpecificSlot(instance.container.Item, targetContainableItemTag)

                if index then
                    instance.TargetSlot = index
                    instance.AllowDangerousPressure = false
                    instance.AllowToFindDivingGear = false
                end
            end
        end, Hook.HookMethodType.Before)

        namespace = -namespace
        ::continue::
    end
end