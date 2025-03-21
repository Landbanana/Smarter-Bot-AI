local SBAIUtils = require("SBAI.SBAIUtils")
local ItemGroup = require("SBAI.Server.ItemGroup")

require("SBAI.Server.Characters.AI.Objective.AIObjectiveLoadItems")
require("SBAI.Server.Items.ItemInventory")

local AIObjectiveLoadItem_Descriptor = LuaUserData.RegisterType("Barotrauma.AIObjectiveLoadItem")
LuaUserData.MakeMethodAccessible(AIObjectiveLoadItem_Descriptor, "CanEquip")
LuaUserData.MakeMethodAccessible(AIObjectiveLoadItem_Descriptor, "IgnoreTargetItem")
LuaUserData.MakeMethodAccessible(AIObjectiveLoadItem_Descriptor, "IsValidContainable")
LuaUserData.MakePropertyAccessible(AIObjectiveLoadItem_Descriptor, "AllValidContainableItemIdentifiers")
LuaUserData.MakePropertyAccessible(AIObjectiveLoadItem_Descriptor, "IsCompleted")
LuaUserData.MakePropertyAccessible(AIObjectiveLoadItem_Descriptor, "ValidContainableItemIdentifiers")
LuaUserData.MakePropertyAccessible(AIObjectiveLoadItem_Descriptor, "TargetContainerTags")
LuaUserData.MakePropertyAccessible(AIObjectiveLoadItem_Descriptor, "Container")
LuaUserData.MakePropertyAccessible(AIObjectiveLoadItem_Descriptor, "ItemContainer")
LuaUserData.MakeFieldAccessible(AIObjectiveLoadItem_Descriptor, "abandonGetItemDialogueIdentifier")
LuaUserData.MakeFieldAccessible(AIObjectiveLoadItem_Descriptor, "decontainObjective")
LuaUserData.MakeFieldAccessible(AIObjectiveLoadItem_Descriptor, "targetItem")
LuaUserData.MakeFieldAccessible(AIObjectiveLoadItem_Descriptor, "itemIndex")
LuaUserData.MakeFieldAccessible(AIObjectiveLoadItem_Descriptor, "ignoredItems")
LuaUserData.MakeFieldAccessible(AIObjectiveLoadItem_Descriptor, "subObjectives")

local AIObjectiveLoadItem_ItemTagToGeneralItemTag = {
    ["mobilebattery"] = "mobilebattery",
    ["refillableoxygensource"] = "oxygensource"}

local AIObjectiveLoadItem_ItemTagToRefiller = {
    ["mobilebattery"] = "batterycellrecharger",
    ["refillableoxygensource"] = "oxygentankrefiller"}

local AIObjectiveLoadItems = LuaUserData.CreateStatic("Barotrauma.AIObjectiveLoadItems")

---@type fun(character:Barotrauma.Character, item:Barotrauma.Item, itemTagString:string):Barotrauma.Item, Barotrauma.Items.Components.ItemContainer
local function GetTargets(character, item, itemTagString)
    ---@type Barotrauma.Item[]
    local refillers = {}
    local closestRefiller = nil --[[@type Barotrauma.Item|nil]]
    local bestDistFactor = 0.0 --[[@type System.Single]]
    local distFactor --[[@type System.Single]]
    local targetItem = nil --[[@type Barotrauma.Item]]
    local targetContainer = nil --[[@type Barotrauma.Items.Components.ItemContainer]]

    for _, refiller in ipairs(ItemGroup.List[AIObjectiveLoadItem_ItemTagToRefiller[itemTagString]]) do
        if AIObjectiveLoadItems.IsValidTarget(refiller, character) then table.insert(refillers, refiller) end
    end
    
    if item.Container == nil or not SBAIUtils.IsSpecifiedContainer(item.Container, item) then
        local firstTry = false --[[@type boolean]]

        repeat
            firstTry = not firstTry

            for _, refiller in ipairs(refillers) do
                local powerContainer = refiller.GetComponent(Components.PowerContainer)

                if firstTry and refiller.OwnInventory.IsFull() or (powerContainer ~= nil and powerContainer.Charge <= 0.0) then goto continue1 end
                
                distFactor = AIObjective.GetDistanceFactor(item.WorldPosition, refiller.WorldPosition, 0.2)
                if distFactor > bestDistFactor then
                    
                    closestRefiller = refiller
                    bestDistFactor = distFactor
                end
                ::continue1::
            end
        until closestRefiller ~= nil or firstTry == false
        
        if closestRefiller ~= nil then
            targetItem = item
            targetContainer = closestRefiller.OwnInventory.Container
        end
    else
        local closestFullItem = nil --[[@type Barotrauma.Item|nil]]

        for _, refiller in ipairs(refillers) do
            local inventory = refiller.OwnInventory --[[@type Barotrauma.ItemInventory]]
            local fullItem = nil --[[@type Barotrauma.Item|nil]]

            if inventory.IsEmpty() then
                goto continue2
            else
                for slot in inventory.slots do
                    for newItem in slot.Items do
                        if newItem ~= nil and newItem.HasTag(Identifier(itemTagString)) and newItem.IsFullCondition then
                            fullItem = newItem
                            break
                        end
                    end
                end
            end
            if fullItem == nil then goto continue2 end

            distFactor = AIObjective.GetDistanceFactor(item.WorldPosition, refiller.WorldPosition, 0.2)
            if distFactor > bestDistFactor then
                closestFullItem = fullItem
                bestDistFactor = distFactor
            end
            ::continue2::
        end

        if closestFullItem ~= nil then
            targetItem = closestFullItem
            targetContainer = item.Container.GetComponent(Components.ItemContainer)
        end
    end
    return targetItem, targetContainer
end

---@type fun(instance:Barotrauma.AIObjective, objective:AIObjective, constructor:fun():(Barotrauma.AIObjective), onCompletedGenerator:fun(Barotrauma.AIObjective), onAbandonGenerator:fun(Barotrauma.AIObjective)):boolean
local function TryAddSubObjective(instance, objective, constructor, onCompletedGenerator, onAbandonGenerator)
    if objective[1] ~= nil then
        if not SBAIUtils.ListContains(instance.subObjectives, objective[1]) then objective[1] = nil end
        return false
    else
        objective[1] = constructor()

        if SBAIUtils.ListContains(instance.subObjectives, objective[1]) then return false end
        if instance.AllowMultipleInstances then
            objective[1].SourceObjective = this
            instance.subObjectives.Add(objective[1])
        else
            instance.AddSubObjective(objective[1])
        end
        if onCompletedGenerator ~= nil then
            objective[1].Completed.add(onCompletedGenerator(objective[1]))
        end
        if onAbandonGenerator ~= nil then
            objective[1].Abandoned.add(onAbandonGenerator(objective[1]))
        end
        return true
    end
end

---@type fun(objective:Barotrauma.AIObjectiveLoadItem, tagString:string):Barotrauma.Item
local function FindItem(objective, itemTagString)
    for _, item in ipairs(ItemGroup.List[itemTagString]) do
        if item ~= nil and objective.IsValidContainable(item) then
            return item
        end
    end
    return nil
end

for itemTagString, section in pairs({
    -- Replace Batteries: Replace batteries in charged tools (flashlight, handheld sonar, etc.) with full batteries from charging docks
    ["mobilebattery"] = "ReplaceBatteryCells",
    -- Replace Oxygen Tanks: Replace oxygen tanks in oxygenated tools (diving mask, plasma welder, etc.) with full oxygen tanks from refillers
    ["refillableoxygensource"] = "ReplaceOxygenTanks"}) do

    local generalItemTagString = AIObjectiveLoadItem_ItemTagToGeneralItemTag[itemTagString]
    local refillerTagString = AIObjectiveLoadItem_ItemTagToRefiller[itemTagString]
    
    local namespace, _ = SBAIUtils.CheckOptionGetNamespace(section)
    if not namespace then goto continue end
    
    ItemGroup.Register(refillerTagString)
    ItemGroup.Register(itemTagString)
    
    Hook.Patch(namespace, "Barotrauma.AIObjectiveLoadItem", "IsValidContainable",
    function(instance, ptable)
        if instance.TargetContainerTags[1] == Identifier(refillerTagString) then
            ptable.PreventExecution = true

            local character = instance.character --[[@type Barotrauma.Character]]
            local item = ptable["item"] --[[@type Barotrauma.Character]]

            if  item == nil or
                not item.HasTag(Identifier(itemTagString)) or
                item.Removed then
                    return false
            end

            for v in instance.ignoredItems do
                if v == item then return false end
            end

            if  item.Illegitimate == character.IsOnPlayerTeam or
                item.SpawnedInCurrentOutpost and not item.AllowStealing then
                    return false
            end

            local owner = item.GetRootInventoryOwner()
            if LuaUserData.IsTargetType(owner, "Barotrauma.Character") and owner ~= character then return false end

            local parentItem = item.Container
            while parentItem ~= nil do
                if parentItem.HasTag(Identifier("DontTakeItems")) then return false end
                parentItem = parentItem.Container
            end

            if  not item.HasAccess(character) or
                not character.HasItem(item) and not instance.CanEquip(item, false) or
                not instance.ItemContainer.CanBeContained(item) or
                AIObjectiveLoadItems.ItemMatchesTargetCondition(item, AIObjectiveLoadItems.ItemCondition.Full) or
                item.ConditionIncreasedRecently then
                    return false
            end
            return true
        end
    end, Hook["HookMethodType"].Before)

    Hook.Patch(namespace, "Barotrauma.AIObjectiveLoadItem", "Act",
    function(instance, ptable)
        if instance.TargetContainerTags[1] == Identifier(refillerTagString) then
            local item = instance.targetItem --[[@type Barotrauma.Item]]

            ptable.PreventExecution = true

            if item == nil then
                item = FindItem(instance, itemTagString)
                if item == nil then
                    instance.Abandon = true
                end
                instance.targetItem = item
                instance.objectiveManager.GetObjective(AIObjectiveIdle).wander(ptable["deltaTime"])
            else
                local targetItem, targetContainer = GetTargets(instance.character, item, itemTagString)

                if instance.decontainObjective == nil and (targetItem == nil or targetContainer == nil) then
                    instance.IgnoreTargetItem()
                    instance.Reset()
                    return
                end

                if targetItem ~= nil and targetContainer ~= nil then
                    ---@type fun():AIObjectiveDecontainItem
                    local function constructor()
                        local objective = AIObjectiveDecontainItem(instance.character, targetItem, instance.objectiveManager, nil, targetContainer, instance.PriorityModifier)
                        
                        -- objective.AbandonGetItemDialogueCondition = function() return instance.IsValidContainable(targetItem) end
                        objective.AbandonGetItemDialogueIdentifier = instance.abandonGetItemDialogueIdentifier
                        objective.Equip = true
                        objective.RemoveExistingWhenNecessary = true
                        -- if targetItem ~= item then objective.RemoveExistingPredicate = function(oldItem) return oldItem == item end end
                        objective.RemoveExistingMax = 1
                        return objective
                    end

                    ---@type fun(objective:Barotrauma.AIObjective)
                    local function onCompletedGenerator(objective)
                        ---@type fun()
                        local function onCompleted()
                            instance.IsCompleted = true
                            instance.RemoveSubObjective(AIObjectiveDecontainItem, objective)
                        end
                        return onCompleted
                    end

                    ---@type fun(objective:Barotrauma.AIObjective)
                    local function onAbandonGenerator(objective)
                        ---@type fun()
                        local function onAbandon()
                            instance.IgnoreTargetItem();
                            instance.Reset();
                        end
                        return onAbandon
                    end
                    local decontainObjectiveRef = {instance.decontainObjective}
                    
                    TryAddSubObjective(instance, decontainObjectiveRef, constructor, onCompletedGenerator, onAbandonGenerator)
                    instance.decontainObjective = decontainObjectiveRef[1]
                end
            end
        end
    end, Hook["HookMethodType"].Before)
    ::continue::
end