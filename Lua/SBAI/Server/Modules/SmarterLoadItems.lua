local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

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

local allSections = {
    ["BatteryCells"]={"mobilebattery", "mobilebattery", "batterycellrecharger"},
    ["OxygenTanks"]={"refillableoxygensource", "oxygensource", "oxygentankrefiller"}
}

---@param options any
---@return {[1]:string, [2]:string, [3]:string, [4]:number}[]
local function getSections(options)
    local sections = {}
    local i = 0

    for loadType, loadData in pairs(allSections) do
        local section = options[loadType]
        
        if section.enable then
            local itemTag, containableTag, refillerTag = table.unpack(loadData)
            local minCon = section["minimumCondition"]

            i = i + 1
            sections[i] = {itemTag, containableTag, refillerTag, minCon}
        end
    end
    return sections
end

local generateIsValidContainablePredicate
local generateLoadItemActPredicate

do
    local ParentItemsHaveDontTakeItemsTag = util.ParentItemsHaveDontTakeItemsTag
    local PoweredItemHasNeededPower = util.PoweredItemHasNeededPower
    local Contains = util.itertools.Contains

    ---@param instance Barotrauma.AIObjectiveLoadItem
    ---@param refillerTag string
    ---@return fun(character:Barotrauma.Character, item:Barotrauma.Item):boolean
    function generateIsValidContainablePredicate(instance, refillerTag)
        return function(character, item)
            if  Contains(instance.ignoredItems, item) or
                ParentItemsHaveDontTakeItemsTag(item)
            then
                return false
            end

            local container = item.container

            if  container and
                container.HasTag(refillerTag) and
                PoweredItemHasNeededPower(container)
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
            return false
        end
    end

    ---@param instance Barotrauma.AIObjectiveLoadItem
    ---@param refillerTag string
    ---@param minCon number
    ---@return fun(character:Barotrauma.Character, item:Barotrauma.Item):boolean
    function generateLoadItemActPredicate(instance, refillerTag, minCon)
        ---@param character Barotrauma.Character
        ---@param item Barotrauma.Item
        ---@return boolean
        return function(character, item)
            if  Contains(instance.ignoredItems, item) or
                item.ConditionPercentage >= minCon or
                ParentItemsHaveDontTakeItemsTag(item) or
                item.ConditionIncreasedRecently
            then
                return false
            end

            local container = item.Container

            return  not (
                    container and
                    container.HasTag(refillerTag) and
                    PoweredItemHasNeededPower(container)
                )
        end
    end
end

---@param self Types.Module
local function activate(self)
    local allLoadData = getSections(self.options)

    if #allLoadData <= 0 then return end

    local ItemContainer = Components.ItemContainer

    local unpack = table.unpack
    local FindItem = util.FindItem
    local IsSpecifiedContainer = util.IsSpecifiedContainer
    local MatchItem = util.MatchItem
    local PoweredItemHasNeededPower = util.PoweredItemHasNeededPower
    local Contains = util.itertools.Contains

    self:AddPatch("Barotrauma.AIObjectiveLoadItem", "IsValidContainable", nil,
    function(instance, ptable)
        for loadData in allLoadData do
            local refillerTag = loadData[3]

            if Contains(instance.TargetContainerTags, refillerTag) then

                ptable.PreventExecution = true

                return MatchItem(instance.character, ptable["item"], nil, nil, generateIsValidContainablePredicate(instance, refillerTag))
            end
        end
    end, Hook.HookMethodType.Before)

    self:AddPatch("Barotrauma.AIObjectiveLoadItem", "Act", nil,
    function(instance, ptable)
        for loadData in allLoadData do
            local itemTag, _, refillerTag, minCon = unpack(loadData)

            if Contains(instance.TargetContainerTags, refillerTag) then
                local character = instance.character --[[@type Barotrauma.Character]]
                local item = instance.targetItem --[[@type Barotrauma.Item]]
                
                if item == nil then
                    ptable.PreventExecution = true

                    item = FindItem(character, util.ItemGroup[itemTag], nil, {0, minCon}, generateLoadItemActPredicate(instance, refillerTag, minCon))
                    
                    if item == nil then
                        instance.Abandon = true
                    end

                    instance.targetItem = item
                    instance.objectiveManager.GetObjective(AIObjectiveIdle).Wander(ptable["deltaTime"])
                end
                break
            end
        end
    end, Hook.HookMethodType.Before)

    self:AddPatch("Barotrauma.AIObjectiveMoveItem", ".ctor",
    {"Barotrauma.Character", "Barotrauma.Item", "Barotrauma.AIObjectiveManager", "Barotrauma.Items.Components.ItemContainer", "Barotrauma.Items.Components.ItemContainer", "System.Single"},
    function(instance, ptable)
        local destContainer = ptable["targetContainer"] --[[@type Barotrauma.Items.Components.ItemContainer?]]
        
        if  not ptable["sourceContainer"] and
            destContainer
        then
            local curObj = ptable["objectiveManager"].CurrentObjective --[[@type Barotrauma.AIObjective?]]

            if  curObj and
                curObj.Identifier.Equals("loaditems")
            then --[[@cast curObj Barotrauma.AIObjectiveLoadItems]]
                
            
                for loadData in allLoadData do
                    local itemTag, containableTag, refillerTag, _ = unpack(loadData)

                    if Contains(curObj.TargetContainerTags, refillerTag) then --[[@cast destContainer -nil]]
                        local item = ptable["targetItem"] --[[@type Barotrauma.Item]]
                        local container = item.Container
                        
                        if  container and
                            not container.HasTag(refillerTag) and
                            IsSpecifiedContainer(container, containableTag)
                        then
                            local fullItem = FindItem(ptable["character"], destContainer.Inventory.FindAllItems(), itemTag, 100) --[[@type Barotrauma.Item]]
                            local targetContainer = container.GetComponent(ItemContainer) --[[@type Barotrauma.Items.Components.ItemContainer]]
                            
                            if fullItem and targetContainer then
                                ptable["targetContainer"] = targetContainer
                                ptable["targetItem"] = fullItem
                            else
                                instance.Abandon = true
                            end
                        end
                        break
                    end
                end
            end
        end
    end, Hook.HookMethodType.Before)

    do
        local GetSpecificSlot = util.GetSpecificSlot

        self:AddPatch("Barotrauma.AIObjectiveContainItem", ".ctor",
        {"Barotrauma.Character", "Barotrauma.Item", "Barotrauma.Items.Components.ItemContainer", "Barotrauma.AIObjectiveManager", "System.Single"},
        function(instance, ptable)
            local curObj = ptable["objectiveManager"].CurrentObjective --[[@type Barotrauma.AIObjective?]]

            if  curObj and
                curObj.Identifier.Equals("loaditems")
            then --[[@cast curObj Barotrauma.AIObjectiveLoadItems]]
                if ptable["item"].IsFullCondition then
                    for loadData in allLoadData do
                        local _, containableTag, refillerTag, _ = unpack(loadData)

                        if Contains(curObj.TargetContainerTags, refillerTag) then
                            local index = GetSpecificSlot(ptable["container"], containableTag)

                            if index then
                                instance.TargetSlot = index
                                instance.RemoveExistingPredicate = nil
                                instance.AllowDangerousPressure = false
                                instance.AllowToFindDivingGear = false
                            end
                            break
                        end
                    end
                end
            end
        end, Hook.HookMethodType.After)
    end

    self:AddPatch("Barotrauma.AIObjectiveLoadItems", "ItemMatchesTargetCondition", nil,
    function(instance, ptable)
        local item = ptable["item"] --[[@type Barotrauma.Item]]

        if item then
            for loadData in allLoadData do
                local itemTag, _, refillerTag, _ = unpack(loadData)
            
                if item.HasTag(itemTag) then
                    local container = item.Container

                    ptable.PreventExecution = true

                    if container then
                        if  container.HasTag(refillerTag) and
                            PoweredItemHasNeededPower(container)
                        then
                            return item.IsFullCondition
                        else
                            return not item.IsFullCondition
                        end
                    else
                        return item.IsFullCondition
                    end
                end
            end
        end
    end, Hook.HookMethodType.Before)
end

return Types.Module.new(activate)