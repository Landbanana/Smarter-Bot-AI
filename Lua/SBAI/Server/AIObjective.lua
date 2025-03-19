table.insert(SBAI.Namespace, "AIObjective")

local function Reset()
    -- bought a new sub, some mod adds deployable deconstructors, etc.
    SBAI.playerSubmarineHasDeconstructor = nil --[[@type boolean|nil]]
end

Hook.Add("roundEnd", SBAI.GetNamespace()..".Reset", Reset)
Reset()

LuaUserData.RegisterType("Barotrauma.AIObjectiveDeconstructItem")

local ItemContainer_Descriptor = LuaUserData.RegisterType("Barotrauma.Items.Components.ItemContainer")
LuaUserData.MakeFieldAccessible(ItemContainer_Descriptor, "slotRestrictions")
LuaUserData.RegisterType("Barotrauma.Items.Components.ItemContainer+SlotRestrictions")


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
Hook.Patch(SBAI.GetNamespace()..".UseShipDeconstructorIfAvailable", "Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor",
function(instance, ptable)
    local deconstructor --[[@type Barotrauma.Items.Components.Deconstructor]]
    local closestDeconstructor = nil --[[@type Barotrauma.Items.Components.Deconstructor|nil]]
    local bestDistFactor = 0.0 --[[@type System.Single]]
    local distFactor --[[@type System.Single]]

    ptable.PreventExecution = true

    if SBAI.playerSubmarineHasDeconstructor == nil then
        local i, deconstructorItem = next(SBAI.itemGroup["allDeconstructors"], nil)

        while i and not SBAI.playerSubmarineHasDeconstructor do
            SBAI.playerSubmarineHasDeconstructor = deconstructorItem.InPlayerSubmarine
            i, deconstructorItem = next(SBAI.itemGroup["allDeconstructors"], i)
        end
    end

    for _, deconstructorItem in ipairs(SBAI.GetUsableDeconstructors()) do
        if deconstructorItem == nil then goto continue end
        if SBAI.playerSubmarineHasDeconstructor and not deconstructorItem.InPlayerSubmarine then goto continue end
        deconstructor = deconstructorItem.GetComponentString("Deconstructor") --[[@type Barotrauma.Items.Components.Deconstructor]]
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
end, Hook['HookMethodType'].Before)

-- Fight Intruders: Prevent attacking any handcuffed people, regardless of being knocked down
Hook.Patch(SBAI.GetNamespace()..".PreventAttackingHandcuffed", "Barotrauma.AIObjectiveFightIntruders", "IsValidTarget", {"Barotrauma.Character"},
function(_, ptable)
    return ptable.ReturnValue and not ptable["target"].IsHandcuffed
end, Hook['HookMethodType'].After)

-- Operate Weapons: Prevent attacking handcuffed people
Hook.Patch(SBAI.GetNamespace()..".PreventAttackingHandcuffed", "Barotrauma.AIObjectiveCombat", "GetPriority",
function(instance, _)
    if instance.Enemy.IsHandcuffed then return 0 end
end, Hook['HookMethodType'].Before)

SBAI.minimumCharge = 90.0 --[[@type System.Single]]

-- Charge batteries
Hook.Patch(SBAI.GetNamespace()..".RechargeBatteryCells", "Barotrauma.Items.Components.ItemContainer", ".ctor",
function(instance, ptable)
    for s in instance.slotRestrictions do
        if s.MatchesItem(Identifier("mobilebattery")) and s.MaxStackSize == 1 then
            ptable["item"].AddTag("SBAICharged")
        end
    end
end, Hook["HookMethodType"].After)

---@type fun(item:Barotrauma.Item):boolean
local function ItemMatchesTargetCondition(item)
    return item.Container ~= nil and item.Container.HasTag(Identifier("SBAICharged")) and item.ConditionPercentage >= SBAI.minimumCharge or item.IsFullCondition
end

Hook.Patch(SBAI.GetNamespace()..".RechargeBatteryCells", "Barotrauma.AIObjectiveLoadItems", "ItemMatchesTargetCondition",
function(_, ptable)
    if ptable["item"].HasTag("SBAICharged") then
        ptable.PreventExecution = true

        return ItemMatchesTargetCondition(ptable["item"])
    end
end, Hook["HookMethodType"].Before)

---@type fun(objective:Barotrauma.AIObjectiveLoadItem, item:Barotrauma.Item):boolean
local function AIObjectiveLoadItem_IsValidContainable(objective, item)
    local character = objective.character --[[@type Barotrauma.Character]]

    if  item == nil or
        not item.HasTag(Identifier("mobilebattery")) or
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
        ItemMatchesTargetCondition(item) or
        item.ConditionIncreasedRecently then
            return false
    end
    return true
end

---@type fun(instance:Barotrauma.AIObjective, objective:AIObjective, constructor:fun():(Barotrauma.AIObjective), onCompletedGenerator:fun(Barotrauma.AIObjective), onAbandonGenerator:fun(Barotrauma.AIObjective)):boolean
local function AIObjective_TryAddSubObjective(instance, objective, constructor, onCompletedGenerator, onAbandonGenerator)
    if objective[1] ~= nil then
        if not SBAI.Util.ListContains(instance.subObjectives, objective[1]) then objective[1] = nil end
        return false
    else
        objective[1] = constructor()
        if SBAI.Util.ListContains(instance.subObjectives, objective[1]) then return false end
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

---@type fun(character:Barotrauma.Character, item:Barotrauma.Item):Barotrauma.Item, Barotrauma.Items.Components.ItemContainer
local function GetTargetBatteries(character, item)
    ---@type Barotrauma.Item[]
    local batterycellrechargers = {}
    local closestBatterycellrecharger = nil --[[@type Barotrauma.Item|nil]]
    local bestDistFactor = 0.0 --[[@type System.Single]]
    local distFactor --[[@type System.Single]]
    local targetItem = nil --[[@type Barotrauma.Item]]
    local targetContainer = nil --[[@type Barotrauma.Items.Components.ItemContainer]]

    for _, v in ipairs(SBAI.itemGroup["allChargers"]) do
        if AIObjectiveLoadItems_Static.IsValidTarget(v, character) then table.insert(batterycellrechargers, v) end
    end

    if item.Container == nil or not item.Container.HasTag(Identifier("SBAICharged")) then
        local firstTry = false --[[@type boolean]]

        repeat
            firstTry = not firstTry

            for _, batterycellrecharger in ipairs(batterycellrechargers) do
                if firstTry and batterycellrecharger.OwnInventory.IsFull() then goto continue1 end
                
                distFactor = AIObjective.GetDistanceFactor(item.WorldPosition, batterycellrecharger.WorldPosition, 0.2)
                if distFactor > bestDistFactor then
                    
                    closestBatterycellrecharger = batterycellrecharger
                    bestDistFactor = distFactor
                end
                ::continue1::
            end
        until closestBatterycellrecharger ~= nil or firstTry == false
        
        if closestBatterycellrecharger ~= nil then
            targetItem = item
            targetContainer = closestBatterycellrecharger.OwnInventory.Container
        end
    else
        local closestFullMobilebattery = nil --[[@type Barotrauma.Item|nil]]

        for _, batterycellrecharger in ipairs(batterycellrechargers) do
            local inventory = batterycellrecharger.OwnInventory --[[@type Barotrauma.ItemInventory]]
            local fullMobilebattery = nil --[[@type Barotrauma.Item|nil]]

            if inventory.IsEmpty() then
                goto continue2
            else
                for slot in inventory.slots do
                    for mobilebattery in slot.Items do
                        if mobilebattery ~= nil and mobilebattery.HasTag(Identifier("mobilebattery")) and mobilebattery.IsFullCondition then
                            fullMobilebattery = mobilebattery
                            break
                        end
                    end
                end
            end
            if fullMobilebattery == nil then goto continue2 end

            distFactor = AIObjective.GetDistanceFactor(item.WorldPosition, batterycellrecharger.WorldPosition, 0.2)
            if distFactor > bestDistFactor then
                closestFullMobilebattery = fullMobilebattery
                bestDistFactor = distFactor
            end
            ::continue2::
        end
        if closestFullMobilebattery ~= nil then
            targetItem = closestFullMobilebattery
            targetContainer = item.Container.GetComponent(Components.ItemContainer)
        end
    end
    return targetItem, targetContainer
end

Hook.Patch(SBAI.GetNamespace()..".RechargeBatteryCells", "Barotrauma.AIObjectiveLoadItem", "IsValidContainable",
function(instance, ptable)
    if instance.TargetContainerTags[0] == Identifier("batterycellrecharger") then
        
        ptable.PreventExecution = true

        return AIObjectiveLoadItem_IsValidContainable(instance, ptable["item"])
    end
end, Hook["HookMethodType"].Before)

---@type fun(item:Barotrauma.Item):System.Single
local function AIObjectiveLoadItem_Act_GetPriority(item)
    return MathUtils.InverseLerp(100.0, 0.0, item.ConditionPercentage)
end

---@type fun(objective:Barotrauma.AIObjectiveLoadItem):Barotrauma.Item
local function AIObjectiveLoadItem_FindItem(objective)
    for _, v in ipairs(SBAI.itemGroup["allBatteries"]) do
        if v ~= nil and AIObjectiveLoadItem_IsValidContainable(objective, v) then
            return v
        end
    end
    return nil
end

Hook.Patch(SBAI.GetNamespace()..".RechargeBatteryCells", "Barotrauma.AIObjectiveLoadItem", "Act",
function(instance, ptable)
    if instance.TargetContainerTags[0] == Identifier("batterycellrecharger") then
        local item = instance.targetItem --[[@type Barotrauma.Item]]

        ptable.PreventExecution = true

        if item == nil then
            item = AIObjectiveLoadItem_FindItem(instance)
            if item == nil then
                instance.Abandon = true
            end
            instance.targetItem = item
            instance.objectiveManager.GetObjective(AIObjectiveIdle).wander(ptable["deltaTime"])
        else
            local targetItem, targetContainer = GetTargetBatteries(instance.character, item)
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
                local decontainObjective = {instance.decontainObjective}
                AIObjective_TryAddSubObjective(instance, decontainObjective, constructor, onCompletedGenerator, onAbandonGenerator)
                instance.decontainObjective = decontainObjective[1]
            end
        end
    end
end, Hook["HookMethodType"].Before)

table.remove(SBAI.Namespace)