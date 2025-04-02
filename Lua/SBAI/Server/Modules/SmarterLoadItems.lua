local HF = require("SBAI.Shared.helperfunctions")
local TryAddSubObjective, LuaUserData, Hook, ItemGroup = table.unpack(require("SBAI.Shared.redefinitions"))
local SBAI = require("SBAI.Shared.SBAI")



local descriptor = LuaUserData.RegisterType("Barotrauma.AIObjectiveLoadItems")
LuaUserData.MakePropertyAccessible(descriptor, "TargetCondition")
LuaUserData.MakePropertyAccessible(descriptor, "TargetContainerTags")

descriptor = LuaUserData.RegisterType("Barotrauma.AIObjectiveLoadItem")
LuaUserData.MakeMethodAccessible(descriptor, "CanEquip")
LuaUserData.MakeMethodAccessible(descriptor, "IgnoreTargetItem")
LuaUserData.MakeMethodAccessible(descriptor, "IsValidContainable")
LuaUserData.MakePropertyAccessible(descriptor, "AllValidContainableItemIdentifiers")
LuaUserData.MakePropertyAccessible(descriptor, "IsCompleted")
LuaUserData.MakePropertyAccessible(descriptor, "ValidContainableItemIdentifiers")
LuaUserData.MakePropertyAccessible(descriptor, "TargetContainerTags")
LuaUserData.MakePropertyAccessible(descriptor, "Container")
LuaUserData.MakePropertyAccessible(descriptor, "ItemContainer")
LuaUserData.MakeFieldAccessible(descriptor, "abandonGetItemDialogueIdentifier")
LuaUserData.MakeFieldAccessible(descriptor, "decontainObjective")
LuaUserData.MakeFieldAccessible(descriptor, "targetItem")
LuaUserData.MakeFieldAccessible(descriptor, "itemIndex")
LuaUserData.MakeFieldAccessible(descriptor, "ignoredItems")
LuaUserData.MakeFieldAccessible(descriptor, "subObjectives")

descriptor = Descriptors["Barotrauma.AIObjectiveContainItem"]
LuaUserData.MakeFieldAccessible(descriptor, "item")
LuaUserData.MakeMethodAccessible(descriptor, "CheckObjectiveState")

descriptor = Descriptors["Barotrauma.Items.Components.ItemContainer"]
LuaUserData.MakeFieldAccessible(descriptor, "slotRestrictions")
LuaUserData.RegisterType("Barotrauma.Items.Components.ItemContainer+SlotRestrictions")

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
            if HF.ListContains(objective.ignoredItems, item) then return false end

            local parentItem = item.Container
            while parentItem ~= nil do
                if parentItem.HasTag("donttakeitems") then return false end
                parentItem = parentItem.Container
            end
            
            if  not character.HasItem(item) and not objective.CanEquip(item, false) or
                not objective.ItemContainer.CanBeContained(item) or (
                    item.Container ~= nil and
                    HF.IsSpecifiedContainer(item.Container, item) and
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

    for loadType in {"BatteryCells", "OxygenTanks"} do
        local section = options[loadType]
        local targetItemTag, targetContainableItemTag, refillerTag, minimumCondition
        
        if not section.enable then goto continue end

        namespace = namespace + loadType

        targetItemTag = loadTypeToTargetItemTag[loadType]
        targetContainableItemTag = HF.convert.ItemTagToContainableItemTag[targetItemTag]
        refillerTag = HF.convert.ItemTagToRefillerTag[targetItemTag]
        minimumCondition = section["minimumCondition"] --[[@type number]]

        Hook.Patch(namespace(), "Barotrauma.AIObjectiveLoadItem", "IsValidContainable",
        ---@param instance Barotrauma.AIObjective
        ---@param ptable Barotrauma.LuaCsHook.ParameterTable
        function(instance, ptable)
            if instance.TargetContainerTags[1] == refillerTag then
                ptable.PreventExecution = true

                return HF.MatchItem(instance.character, ptable["item"], nil, nil, GenerateItemPredicate(instance, minimumCondition))
            end
        end, Hook.HookMethodType.Before)

        Hook.Patch(namespace(), "Barotrauma.AIObjectiveLoadItem", "Act",
        ---@param instance Barotrauma.AIObjective
        ---@param ptable Barotrauma.LuaCsHook.ParameterTable
        function(instance, ptable)
            if instance.TargetContainerTags[1] == refillerTag then
                local character = instance.character --[[@type Barotrauma.Character]]
                local item = instance.targetItem --[[@type Barotrauma.Item]]

                ptable.PreventExecution = true

                if item == nil then
                    item = HF.FindItem(character, ItemGroup[targetItemTag], targetItemTag, {0, minimumCondition}, GenerateItemPredicate(instance, minimumCondition))
                    if item == nil then
                        instance.Abandon = true
                    end
                    instance.targetItem = item
                    instance.objectiveManager.GetObjective(AIObjectiveIdle).wander(ptable["deltaTime"])
                else
                    local targetItem = nil --[[@type Barotrauma.Item?]]
                    local targetContainer = nil --[[@type Barotrauma.Item|Barotrauma.Items.Components.ItemContainer?]]
                    local container = item.Container --[[@type Barotrauma.Item?]]

                    if container and HF.IsSpecifiedContainer(container, item) then
                        local potentialContainer = HF.GetClosest(item.WorldPosition, HF.FindSpecificContainers(character, ItemGroup[refillerTag], targetContainableItemTag, nil, 100, nil, true, RefillerPredicate)) --[[@type Barotrauma.Item]]
                        
                        if potentialContainer then
                            targetItem = HF.FindItem(character, potentialContainer.OwnInventory.FindAllItems(nil, false), targetItemTag, 100) --[[@type Barotrauma.Item]]
                            targetContainer = item.Container
                        end
                    else
                        targetItem = item
                        for hasEmptySlots in {true, false} do
                            targetContainer = HF.GetClosest(item.WorldPosition, HF.FindSpecificContainers(character, ItemGroup[refillerTag], targetContainableItemTag, nil, nil, hasEmptySlots, true, RefillerPredicate))
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
                        _, instance.decontainObjective = Redef.TryAddSubObjective(instance, instance.decontainObjective, constructor, onCompletedGenerator, onAbandonGenerator)
                    end
                end
            end
        end, Hook.HookMethodType.Before)

        Hook.Patch(namespace(), "Barotrauma.AIObjectiveContainItem", "Act",
        ---@param instance Barotrauma.AIObjectiveContainItem
        ---@param _ Barotrauma.LuaCsHook.ParameterTable
        function(instance, _)
            if  not instance.TargetSlot and
                instance.SourceObjective and
                instance.SourceObjective.SourceObjective and
                LuaUserData.IsTargetType(instance.SourceObjective.SourceObjective, "Barotrauma.AIObjectiveLoadItem") and
                instance.SourceObjective.SourceObjective.TargetContainerTags[1] == refillerTag
            then
                local index = HF.GetSpecificSlot(instance.container.Item, targetContainableItemTag)

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