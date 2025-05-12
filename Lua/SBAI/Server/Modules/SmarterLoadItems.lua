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
    --LuaUserData.MakeMethodAccessible(descriptor, "IsValidContainable")
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

local activateLoadType

do
    local insert = table.insert

    ---@enum (key) LOAD_TYPE_DATA
    local LOAD_TYPE_DATA = {
        BatteryCells=util.AsIdentifiers("mobilebattery", "mobilebattery", "batterycellrecharger"),
        OxygenTanks=util.AsIdentifiers("refillableoxygensource", "oxygensource", "oxygentankrefiller")
    }

    ---@type {[1]:Barotrauma.Identifier, [2]:Barotrauma.Identifier, [3]:Barotrauma.Identifier, [4]:Barotrauma.Identifier, [5]:integer}
    local activeLoadData = {}
    local addedPatches = false
    local addPatches --[[@type fun(self:Types.Module)]]

    ---@param self Types.Module
    ---@param options table
    function activateLoadType(self, options)
        local loadType = self.namespace.stack[#self.namespace.stack]
        local loadTypeData = LOAD_TYPE_DATA[loadType]

        insert(activeLoadData, {Identifier(loadType), loadTypeData[1], loadTypeData[2], loadTypeData[3], options["minimumCondition"]})
        if not addedPatches then return addPatches(self) end
    end

    ---@param self Types.Module
    function addPatches(self)
        local ItemContainer = Components.ItemContainer
        local loadItemsId = Identifier("loaditems")

        local Contains = util.itertools.Contains
        local FindItem = util.FindItem
        local GetSpecificSlot = util.GetSpecificSlot
        local IsSpecifiedContainer = util.IsSpecifiedContainer
        local MatchItem = util.MatchItem
        local ParentItemsHaveDontTakeItemsTag = util.ParentItemsHaveDontTakeItemsTag
        local PoweredItemHasNeededPower = util.PoweredItemHasNeededPower
        local unpack = table.unpack

        addedPatches = true

        self:AddPatch("Barotrauma.AIObjectiveLoadItem", "IsValidContainable", nil,
        function(instance, ptable)
            for loadData in activeLoadData do
                local refillerTag = loadData[4] --[[@type Barotrauma.Identififer]]

                if Contains(instance.TargetContainerTags, refillerTag) then
                    ptable.PreventExecution = true

                    return MatchItem(instance.character, ptable["item"], nil, nil,
                    function(character, item)
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
                    end)
                end
            end
        end, Hook.HookMethodType.Before)

        self:AddPatch("Barotrauma.AIObjectiveLoadItem", "Act", nil,
        function(instance, ptable)
            for loadData in activeLoadData do 
                local _, itemTag, _, refillerTag, minimumCondition = unpack(loadData) --[[@type Barotrauma.Identifier, Barotrauma.Identifier, Barotrauma.Identifier, Barotrauma.Identifier, integer]]

                if Contains(instance.TargetContainerTags, refillerTag) then
                    local character = instance.character --[[@type Barotrauma.Character]]
                    local item = instance.targetItem --[[@type Barotrauma.Item]]
                    
                    if item == nil then
                        ptable.PreventExecution = true

                        item = FindItem(character, util.ItemGroup[itemTag.Value], nil, {0, minimumCondition},
                        function(character, item)
                            if  Contains(instance.ignoredItems, item) or
                                item.ConditionPercentage >= minimumCondition or
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
                        end)
                        
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
                    curObj.Identifier == loadItemsId
                then --[[@cast curObj Barotrauma.AIObjectiveLoadItems]]
                    for loadData in activeLoadData do
                        local _, itemTag, containableTag, refillerTag, _ = unpack(loadData) --[[@type Barotrauma.Identifier, Barotrauma.Identifier, Barotrauma.Identifier, Barotrauma.Identifier, integer]]

                        if Contains(curObj.TargetContainerTags, refillerTag) then --[[@cast destContainer -nil]]
                            local item = ptable["targetItem"] --[[@type Barotrauma.Item]]
                            local container = item.Container
                            
                            if  container and
                                not container.HasTag(refillerTag) and
                                IsSpecifiedContainer(container, containableTag.Value)
                            then
                                local fullItem = FindItem(ptable["character"], destContainer.Inventory.GetAllItems(true), itemTag, 100) --[[@type Barotrauma.Item]]
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

        self:AddPatch("Barotrauma.AIObjectiveContainItem", ".ctor",
        {"Barotrauma.Character", "Barotrauma.Item", "Barotrauma.Items.Components.ItemContainer", "Barotrauma.AIObjectiveManager", "System.Single"},
        function(instance, ptable)
            local curObj = ptable["objectiveManager"].CurrentObjective --[[@type Barotrauma.AIObjective?]]

            if  curObj and
                curObj.Identifier == loadItemsId
            then --[[@cast curObj Barotrauma.AIObjectiveLoadItems]]
                if ptable["item"].IsFullCondition then
                    for loadData in activeLoadData do
                        local _, _, containableTag, refillerTag, _ = unpack(loadData) --[[@type Barotrauma.Identifier, Barotrauma.Identifier, Barotrauma.Identifier, Barotrauma.Identifier, integer]]

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

        self:AddPatch("Barotrauma.AIObjectiveLoadItems", "ItemMatchesTargetCondition", nil,
        function(instance, ptable)
            local item = ptable["item"] --[[@type Barotrauma.Item]]

            if item then
                for loadData in activeLoadData do
                    local _, itemTag, _, refillerTag, _ = unpack(loadData) --[[@type Barotrauma.Identifier, Barotrauma.Identifier, Barotrauma.Identifier, Barotrauma.Identifier, integer]]
                
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
end

---@param self Types.Module
local function activate(self)
    self:DoOption("BatteryCells", activateLoadType)
    self:DoOption("OxygenTanks", activateLoadType)
end

return Types.Module.new(activate)