local SBAI = require("SBAI")
local util = require("SBAI.Shared.util")

local LuaUserData = LuaUserData

do
    local descriptor --[[@type MoonSharp.Interpreter.Interop.IUserDataDescriptor]]

    LuaUserData.RegisterType("Barotrauma.AIObjectiveMoveItem")

    ---@class Barotrauma.AIObjectiveMoveItem: Barotrauma.AIObjectiveDecontainItem

    descriptor = LuaUserData.RegisterType("Barotrauma.AIObjectiveLoadItems")
    LuaUserData.MakePropertyAccessible(descriptor, "TargetContainerTags")

    ---@class Barotrauma.AIObjectiveLoadItems: Barotrauma.AIObjectiveLoop*1Barotrauma*Item
    ---@field TargetContainerTags System.Collections.Immutable.ImmutableArray*1Barotrauma*Identifier

    descriptor = LuaUserData.RegisterType("Barotrauma.AIObjectiveLoadItem")
    LuaUserData.MakeMethodAccessible(descriptor, "CanEquip")
    LuaUserData.MakeMethodAccessible(descriptor, "IsValidContainable")
    LuaUserData.MakePropertyAccessible(descriptor, "TargetContainerTags")
    LuaUserData.MakePropertyAccessible(descriptor, "Container")
    LuaUserData.MakePropertyAccessible(descriptor, "ItemContainer")
    LuaUserData.MakeFieldAccessible(descriptor, "targetItem")
    LuaUserData.MakeFieldAccessible(descriptor, "ignoredItems")

    LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.AIObjectiveContainItem"], "item")

    ---@class Barotrauma.AIObjectiveLoadItem: Barotrauma.AIObjective
    ---@field IsValidContainable fun(item:Barotrauma.Item):System.Boolean
    ---@field Container Barotrauma.Item
    ---@field ItemContainer Barotrauma.Items.Components.ItemContainer
    ---@field TargetContainerTags System.Collections.Immutable.ImmutableArray*1Barotrauma*Identifier
    ---@field targetItem Barotrauma.Item
    ---@field ignoredItems System.Collections.Generic.HashSet*1Barotrauma*Item
end

---@param namespace Namespace
---@param options table<string,any>
return function(namespace, options)
    local AIObjectiveLoadItems = LuaUserData.CreateStatic("Barotrauma.AIObjectiveLoadItems")

    local function StaticFindItem(newItem)
        return  util.ParentItemsHaveDontTakeItemsTag(newItem) or
            newItem.ConditionIncreasedRecently
    end

for loadType, itemTag, containableTag, refillerTag in util.Variator({
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
    ---@param instance Barotrauma.AIObjectiveLoadItem
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function(instance, ptable)
        if instance.TargetContainerTags[1] == refillerTag then

            ptable.PreventExecution = true

            return util.MatchItem(instance.character, ptable["item"], nil, nil,
            ---@param character Barotrauma.Character
            ---@param item Barotrauma.Item
            ---@return boolean
            function(character, item)
                if  util.ValsContain(instance.ignoredItems, item) or
                    util.ParentItemsHaveDontTakeItemsTag(item)
                then
                    return false
                end

                local container = item.container

                if  container and
                    container.HasTag(refillerTag) and
                    util.PoweredItemHasNeededPower(container)
                then
                    return false
                end

                if  not item.IsFullCondition and
                    not item.ConditionIncreasedRecently and (
                        character.HasItem(item) or
                        instance.CanEquip(item, false)
                    )
                then
                    return true
                end
            end)
        end
    end, Hook.HookMethodType.Before)

    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveLoadItem", "Act",
    ---@param instance Barotrauma.AIObjectiveLoadItem
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function(instance, ptable)
        if instance.TargetContainerTags[1] == refillerTag then
            local character = instance.character --[[@type Barotrauma.Character]]
            local item = instance.targetItem --[[@type Barotrauma.Item]]
            
            if item == nil then
                ptable.PreventExecution = true

                item = util.FindItem(character, util.ItemGroup[itemTag], nil, {0, minimumCondition},
                ---@param _ Barotrauma.Character
                ---@param newItem Barotrauma.Item
                ---@return boolean
                function(_, newItem)
                    if  util.ValsContain(instance.ignoredItems, newItem) or
                        newItem.ConditionPercentage >= minimumCondition or
                        StaticFindItem(newItem)
                    then
                        return false
                    end

                    local container = newItem.Container

                    return  not (
                            container and
                            container.HasTag(refillerTag) and
                            util.PoweredItemHasNeededPower(container)
                        )
                end)
                
                if item == nil then
                    instance.Abandon = true
                end

                instance.targetItem = item
                instance.objectiveManager.GetObjective(AIObjectiveIdle).Wander(ptable["deltaTime"])
            end
        end
    end, Hook.HookMethodType.Before)

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
                    util.IsSpecifiedContainer(container, containableTag)
                then
                    local fullItem = util.FindItem(character, destContainer.Inventory.FindAllItems(), itemTag, 100) --[[@type Barotrauma.Item]]
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

    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveContainItem", "Act",
    ---@param instance Barotrauma.AIObjectiveContainItem
    ---@param _ Barotrauma.LuaCsHook.ParameterTable
    function(instance, _)
        if  not instance.TargetSlot and
            instance.RemoveExistingPredicate and
            instance.item and
            instance.item.IsFullCondition
        then
            local sourceObjective = instance.SourceObjective

            if sourceObjective then
                sourceObjective = sourceObjective.SourceObjective --[[@cast sourceObjective Barotrauma.AIObjective]]
                if  sourceObjective and
                    sourceObjective.Identifier.Equals("load item") and
                    sourceObjective.TargetContainerTags[1] == refillerTag
                then
                    local index = util.GetSpecificSlot(instance.container, containableTag)

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
        local item = ptable["item"] --[[@type Barotrauma.Item]]
        
        if item and item.HasTag(itemTag) then

            ptable.PreventExecution = true

            return item.IsFullCondition
        end
    end, Hook.HookMethodType.Before)
::continue::
end
end