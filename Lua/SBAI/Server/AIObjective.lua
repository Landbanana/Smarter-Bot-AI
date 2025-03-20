local SBAI = require "SBAI"
local SBAIUtils = require "SBAI.SBAIUtils"
local ItemGroup = require "SBAI.Server.ItemGroup"

local Namespace = SBAI.Namespace.."AIObjective."

LuaUserData.RegisterType("Barotrauma.AIObjectiveDeconstructItem")

local AIObjectiveLoadItems_Descriptor = LuaUserData.RegisterType("Barotrauma.AIObjectiveLoadItems")
local AIObjectiveLoadItems_Static = LuaUserData.CreateStatic("Barotrauma.AIObjectiveLoadItems")
LuaUserData.MakeMethodAccessible(AIObjectiveLoadItems_Descriptor, "GetList")
LuaUserData.MakePropertyAccessible(AIObjectiveLoadItems_Descriptor, "TargetCondition")
LuaUserData.MakePropertyAccessible(AIObjectiveLoadItems_Descriptor, "TargetContainerTags")

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
LuaUserData.MakeFieldAccessible(AIObjectiveLoadItem_Descriptor, "decontainObjective")
LuaUserData.MakeFieldAccessible(AIObjectiveLoadItem_Descriptor, "targetItem")
LuaUserData.MakeFieldAccessible(AIObjectiveLoadItem_Descriptor, "itemIndex")
LuaUserData.MakeFieldAccessible(AIObjectiveLoadItem_Descriptor, "ignoredItems")
LuaUserData.MakeFieldAccessible(AIObjectiveLoadItem_Descriptor, "subObjectives")

local Inventory_Descriptor = LuaUserData.RegisterType("Barotrauma.ItemInventory")
LuaUserData.MakeFieldAccessible(Inventory_Descriptor, "slots")

-- Deconstruct Items: Deconstruct only within the sub if deconstructor is within sub, with optimized calls to get all deconstructors in map
local playerSubmarineHasDeconstructor = nil

Hook.Add("roundEnd", Namespace.."Reset", function()
    -- bought a new sub, some mod adds deployable deconstructors, etc.
    playerSubmarineHasDeconstructor = nil --[[@type boolean|nil]]
end)

ItemGroup.Register("deconstructor")

Hook.Patch(Namespace.."UseShipDeconstructorIfAvailable", "Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor",
function(instance, ptable)
    local deconstructor --[[@type Barotrauma.Items.Components.Deconstructor]]
    local closestDeconstructor = nil --[[@type Barotrauma.Items.Components.Deconstructor|nil]]
    local bestDistFactor = 0.0 --[[@type System.Single]]
    local distFactor --[[@type System.Single]]

    ptable.PreventExecution = true

    if playerSubmarineHasDeconstructor == nil then
        local i, deconstructorItem = next(ItemGroup.List["deconstructor"], nil)

        while i and not playerSubmarineHasDeconstructor do
            playerSubmarineHasDeconstructor = deconstructorItem.InPlayerSubmarine
            i, deconstructorItem = next(ItemGroup.List["deconstructor"], i)
        end
    end

    for _, deconstructorItem in ipairs(ItemGroup.List["deconstructor"]) do
        if deconstructorItem == nil then goto continue end
        if playerSubmarineHasDeconstructor and not deconstructorItem.InPlayerSubmarine then goto continue end
        deconstructor = deconstructorItem.GetComponent(Components.Deconstructor) --[[@type Barotrauma.Items.Components.Deconstructor]]
        if not deconstructor.InputContainer.Inventory.CanBePut(instance.Item) then goto continue end
        if not deconstructorItem.HasAccess(instance.character) then goto continue end

        distFactor = AIObjective.GetDistanceFactor(instance.Item.WorldPosition, deconstructorItem.WorldPosition, 0.2)
        if distFactor > bestDistFactor then
            closestDeconstructor = deconstructor
            bestDistFactor = distFactor
        end
        ::continue::
    end
    return closestDeconstructor
end, Hook["HookMethodType"].Before)

-- Fight Intruders: Prevent attacking any handcuffed people, regardless of being knocked down
Hook.Patch(Namespace.."PreventAttackingHandcuffed", "Barotrauma.AIObjectiveFightIntruders", "IsValidTarget", {"Barotrauma.Character"},
function(_, ptable)
    return ptable.ReturnValue and not ptable["target"].IsHandcuffed
end, Hook["HookMethodType"].After)

-- Operate Weapons: Prevent attacking handcuffed people
Hook.Patch(Namespace.."PreventAttackingHandcuffed", "Barotrauma.AIObjectiveCombat", "GetPriority",
function(instance, _)
    if instance.Enemy.IsHandcuffed then return 0 end
end, Hook["HookMethodType"].Before)

-- Load Items
-- Recharge Batteries: Replace batteries in "charged" tools (flashlight, handheld sonar, etc.) with full batteries from charging docks

local AIObjectiveLoadItemsRefillerToGeneralItemTag = {}
AIObjectiveLoadItemsRefillerToGeneralItemTag["batterycellrecharger"] = "mobilebattery"
AIObjectiveLoadItemsRefillerToGeneralItemTag["oxygentankrefiller"] = "oxygensource"

local AIObjectiveLoadItem_RefillerToItemTag = {}
AIObjectiveLoadItem_RefillerToItemTag["batterycellrecharger"] = "mobilebattery"
AIObjectiveLoadItem_RefillerToItemTag["oxygentankrefiller"] = "refillableoxygensource"

local AIObjectiveLoadItem_MinimumCondition = {} --[[@type table<string, number>]]
SBAI.AIObjectiveLoadItem_DefaultMinimumCondition = 90.0 --[[@type number]]

for refillerTagString, itemTagString in pairs(AIObjectiveLoadItem_RefillerToItemTag) do
    ItemGroup.Register(refillerTagString)
    ItemGroup.Register(itemTagString)
    AIObjectiveLoadItem_MinimumCondition[itemTagString] = SBAI.AIObjectiveLoadItem_DefaultMinimumCondition
end

---@type fun(item:Barotrauma.Item, tagString:string, minimumCondition:number?):boolean
local function AIObjectiveLoadItem_ItemMatchesTargetCondition(item, tagString, minimumCondition)
    return  item.Container ~= nil and SBAIUtils.IsSpecifiedContainer(item.Container, item) and
            item.ConditionPercentage >= (minimumCondition or AIObjectiveLoadItem_MinimumCondition[tagString])
            or item.IsFullCondition
end

Hook.Patch(Namespace.."RechargeBatteryCells", "Barotrauma.AIObjectiveLoadItems", "ItemMatchesTargetCondition",
function(_, ptable)
    for tagString, minimumCondition in pairs(AIObjectiveLoadItem_MinimumCondition) do
        if ptable["item"].HasTag(Identifier(tagString)) then
            ptable.PreventExecution = true
            
            return AIObjectiveLoadItem_ItemMatchesTargetCondition(ptable["item"], tagString, minimumCondition)
        end
    end
end, Hook["HookMethodType"].Before)

---@type fun(objective:Barotrauma.AIObjectiveLoadItem, item:Barotrauma.Item, tagString:string):boolean
local function AIObjectiveLoadItem_IsValidContainable(objective, item, tagString)
    local character = objective.character --[[@type Barotrauma.Character]]

    if  item == nil or
        not item.HasTag(Identifier(tagString)) or
        item.Removed then
            return false
    end

    for v in objective.ignoredItems do
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
        not character.HasItem(item) and not objective.CanEquip(item, false) or
        not objective.ItemContainer.CanBeContained(item) or
        AIObjectiveLoadItem_ItemMatchesTargetCondition(item, tagString) or
        item.ConditionIncreasedRecently then
            return false
    end
    return true
end

---@type fun(instance:Barotrauma.AIObjective, objective:AIObjective, constructor:fun():(Barotrauma.AIObjective), onCompletedGenerator:fun(Barotrauma.AIObjective), onAbandonGenerator:fun(Barotrauma.AIObjective)):boolean
local function AIObjective_TryAddSubObjective(instance, objective, constructor, onCompletedGenerator, onAbandonGenerator)
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

---@type fun(character:Barotrauma.Character, item:Barotrauma.Item, refillerTagString:string):Barotrauma.Item, Barotrauma.Items.Components.ItemContainer
local function AIObjectiveLoadItem_GetTargets(character, item, refillerTagString)
    ---@type Barotrauma.Item[]
    local refillers = {}
    local closestRefiller = nil --[[@type Barotrauma.Item|nil]]
    local bestDistFactor = 0.0 --[[@type System.Single]]
    local distFactor --[[@type System.Single]]
    local targetItem = nil --[[@type Barotrauma.Item]]
    local targetContainer = nil --[[@type Barotrauma.Items.Components.ItemContainer]]
    local targetItemTag = AIObjectiveLoadItem_RefillerToItemTag[refillerTagString]

    for _, refiller in ipairs(ItemGroup.List[refillerTagString]) do
        if AIObjectiveLoadItems_Static.IsValidTarget(refiller, character) then table.insert(refillers, refiller) end
    end
    
    if item.Container == nil or not SBAIUtils.IsSpecifiedContainer(item.Container, item) then
        local firstTry = false --[[@type boolean]]

        repeat
            firstTry = not firstTry

            for _, refiller in ipairs(refillers) do
                if firstTry and refiller.OwnInventory.IsFull() then goto continue1 end
                
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
                        if newItem ~= nil and newItem.HasTag(Identifier(targetItemTag)) and newItem.IsFullCondition then
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

Hook.Patch(Namespace.."RechargeBatteryCells", "Barotrauma.AIObjectiveLoadItem", "IsValidContainable",
function(instance, ptable)
    for refillerTagString, itemTagString in pairs(AIObjectiveLoadItem_RefillerToItemTag) do
        if instance.TargetContainerTags[1] == Identifier(refillerTagString) then
            ptable.PreventExecution = true

            return AIObjectiveLoadItem_IsValidContainable(instance, ptable["item"], itemTagString)
        end
    end
end, Hook["HookMethodType"].Before)

---@type fun(item:Barotrauma.Item):System.Single
local function AIObjectiveLoadItem_Act_GetPriority(item)
    return MathUtils.InverseLerp(100.0, 0.0, item.ConditionPercentage)
end

---@type fun(objective:Barotrauma.AIObjectiveLoadItem, tagString:string):Barotrauma.Item
local function AIObjectiveLoadItem_FindItem(objective, tagString)
    for _, item in ipairs(ItemGroup.List[tagString]) do
        if item ~= nil and AIObjectiveLoadItem_IsValidContainable(objective, item, tagString) then
            return item
        end
    end
    return nil
end

Hook.Patch(Namespace.."RechargeBatteryCells", "Barotrauma.AIObjectiveLoadItem", "Act",
function(instance, ptable)
    for refillerTagString, itemTagString in pairs(AIObjectiveLoadItem_RefillerToItemTag) do
        if instance.TargetContainerTags[1] == Identifier(refillerTagString) then
            local item = instance.targetItem --[[@type Barotrauma.Item]]

            ptable.PreventExecution = true

            if item == nil then
                item = AIObjectiveLoadItem_FindItem(instance, itemTagString)
                if item == nil then
                    instance.Abandon = true
                end
                instance.targetItem = item
                instance.objectiveManager.GetObjective(AIObjectiveIdle).wander(ptable["deltaTime"])
            else
                local targetItem, targetContainer = AIObjectiveLoadItem_GetTargets(instance.character, item, refillerTagString)
                if instance.decontainObjective == nil and targetItem == nil and targetContainer == nil then
                    instance.IgnoreTargetItem()
                    instance.Reset()
                    return
                end
                if targetItem ~= nil and targetContainer ~= nil then
                    ---@type fun():AIObjectiveDecontainItem
                    local function constructor()
                        local objective = AIObjectiveDecontainItem(instance.character, targetItem, instance.objectiveManager, nil, targetContainer, instance.PriorityModifier)
                        --objective.AbandonGetItemDialogueCondition = function() return instance.IsValidContainable(instance.targetItem) end
                        --objective.AbandonGetItemDialogueIdentifier = instance.abandonGetItemDialogueIdentifier
                        objective.Equip = true
                        objective.RemoveExistingWhenNecessary = true
                        --RemoveExistingPredicate = function(item) return true end
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
                    
                    AIObjective_TryAddSubObjective(instance, decontainObjectiveRef, constructor, onCompletedGenerator, onAbandonGenerator)
                    instance.decontainObjective = decontainObjectiveRef[1]
                end
            end
        end
    end
end, Hook["HookMethodType"].Before)

---@type fun(itemContainer:Barotrauma.Items.Components.ItemContainer, generalItemTag:Barotrauma.Identifier):integer
local function AIObjectiveContainItem_GetTargetSlot(itemContainer, generalItemTag)
    local index = 0

    for s in itemContainer.slotRestrictions do
        if s.ContainableItems ~= nil and s.MatchesItem(generalItemTag) and s.MaxStackSize == 1 then
            return index
        end
        index = index + 1
    end
    return -1
end

Hook.Patch(Namespace.."RechargeBatteryCells", "Barotrauma.AIObjectiveContainItem", "Act",
function(instance, ptable)
    for refillerTagString, generalItemTagString in pairs(AIObjectiveLoadItemsRefillerToGeneralItemTag) do
        if  instance.TargetSlot == nil and
            instance.SourceObjective ~= nil and
            instance.SourceObjective.SourceObjective ~= nil and
            LuaUserData.IsTargetType(instance.SourceObjective.SourceObjective, "Barotrauma.AIObjectiveLoadItem") and
            instance.SourceObjective.SourceObjective.TargetContainerTags[1] == Identifier(refillerTagString) then
                local index = AIObjectiveContainItem_GetTargetSlot(instance.container, Identifier(generalItemTagString))
                if index > -1 then instance.TargetSlot = index end
        end
    end
end, Hook["HookMethodType"].Before)