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

local AIObjectiveLoadItems = LuaUserData.CreateStatic("Barotrauma.AIObjectiveLoadItems")

---@type fun(character:Barotrauma.Character, item:Barotrauma.Item, itemTag:Barotrauma.Identifier, refillerTag:Barotrauma.Identifier):Barotrauma.Item, Barotrauma.Items.Components.ItemContainer
local function GetTargets(character, item, itemTag, refillerTag)
    ---@type Barotrauma.Item[]
    local refillers = {}
    local closestRefiller = nil --[[@type Barotrauma.Item|nil]]
    local bestDistFactor = 0.0 --[[@type System.Single]]
    local distFactor --[[@type System.Single]]
    local targetItem = nil --[[@type Barotrauma.Item]]
    local targetContainer = nil --[[@type Barotrauma.Items.Components.ItemContainer]]

    for _, refiller in ipairs(ItemGroup.List[refillerTag]) do
        if AIObjectiveLoadItems.IsValidTarget(refiller, character) then table.insert(refillers, refiller) end
    end

    if item.Container == nil or not ItemContainerExtra.IsSpecifiedContainer(item.Container, item) then
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
                        if newItem ~= nil and newItem.HasTag(itemTag) and newItem.IsFullCondition then
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

---@type fun(objective:Barotrauma.AIObjectiveLoadItem, itemTag:Barotrauma.Identifier):Barotrauma.Item
local function FindItem(objective, itemTag)
    for _, item in ipairs(ItemGroup.List[itemTag]) do
        if item ~= nil and objective.IsValidContainable(item) then
            return item
        end
    end
    return nil
end

---@param namespace string
---@param options table
return function(namespace, options)
    local prevNamespace = namespace

    for itemTag, section in pairs({
        -- Replace Batteries: Replace batteries in charged tools (flashlight, handheld sonar, etc.) with full batteries from charging docks
        ["mobilebattery"] = "LoadBatteryCells",
        -- Replace Oxygen Tanks: Replace oxygen tanks in oxygenated tools (diving mask, plasma welder, etc.) with full oxygen tanks from refillers
        ["refillableoxygensource"] = "LoadOxygenTanks"}) do
        
        local minimumCondition --[[@type number]]
    
        namespace, options = SBAI.util.CheckOptionGetNamespace(section, prevNamespace)
        if not namespace then goto continue end
    
        minimumCondition = options.minimumCondition
    
        SBAI.Hook.Patch(namespace, "Barotrauma.AIObjectiveLoadItems", "ItemMatchesTargetCondition",
        function(_, ptable)
            local item = ptable["item"]
    
            if item.HasTag(itemTag) then
                ptable.PreventExecution = true
                
                return item.Container ~= nil and
                    SBAI.util.IsSpecifiedContainer(item.Container, item) and
                    item.ConditionPercentage >= minimumCondition or
                    item.IsFullCondition
            end
        end, Hook.HookMethodType.Before)
        ::continue::
    end

    for section, itemTag, refillerTag in SBAI.util.VariableIterator({
        -- Replace Batteries: Replace batteries in charged tools (flashlight, handheld sonar, etc.) with full batteries from charging docks
        {"LoadBatteryCells", "mobilebattery", "batterycellrecharger"},
        -- Replace Oxygen Tanks: Replace oxygen tanks in oxygenated tools (diving mask, plasma welder, etc.) with full oxygen tanks from refillers
        {"LoadOxygenTanks", "refillableoxygensource", "oxygentankrefiller"}
    }) do
        namespace, _ = SBAI.util.CheckOptionGetNamespace(section, prevNamespace)
        if not namespace then goto continue end

        SBAI.Hook.Patch(namespace, "Barotrauma.AIObjectiveLoadItem", "IsValidContainable",
        function(instance, ptable)
            if instance.TargetContainerTags[1] == refillerTag then
                ptable.PreventExecution = true

                local character = instance.character --[[@type Barotrauma.Character]]
                local item = ptable["item"] --[[@type Barotrauma.Character]]

                if  item == nil or
                    not item.HasTag(itemTag) or
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
                if SBAI.LuaUserData.IsTargetType(owner, "Barotrauma.Character") and owner ~= character then return false end

                local parentItem = item.Container
                while parentItem ~= nil do
                    if parentItem.HasTag("DontTakeItems") then return false end
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
        end, Hook.HookMethodType.Before)

        SBAI.Hook.Patch(namespace, "Barotrauma.AIObjectiveLoadItem", "Act",
        function(instance, ptable)
            if instance.TargetContainerTags[1] == refillerTag then
                local item = instance.targetItem --[[@type Barotrauma.Item]]

                ptable.PreventExecution = true

                if item == nil then
                    item = FindItem(instance, itemTag)
                    if item == nil then
                        instance.Abandon = true
                    end
                    instance.targetItem = item
                    instance.objectiveManager.GetObjective(AIObjectiveIdle).wander(ptable["deltaTime"])
                else
                    local targetItem, targetContainer = GetTargets(instance.character, item, itemTag, refillerTag)

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
                                instance.IgnoreTargetItem()
                                instance.Reset()
                            end
                            return onAbandon
                        end
                        local decontainObjectiveRef = {instance.decontainObjective}

                        SBAI.util.TryAddSubObjective(instance, decontainObjectiveRef, constructor, onCompletedGenerator, onAbandonGenerator)
                        instance.decontainObjective = decontainObjectiveRef[1]
                    end
                end
            end
        end, Hook.HookMethodType.Before)
        ::continue::
    end

    for section, generalItemTag, refillerTag in SBAI.util.VariableIterator({
        -- Replace Batteries: Replace batteries in charged tools (flashlight, handheld sonar, etc.) with full batteries from charging docks
        {"LoadBatteryCells", "mobilebattery", "batterycellrecharger"},
        -- Replace Oxygen Tanks: Replace oxygen tanks in oxygenated tools (diving mask, plasma welder, etc.) with full oxygen tanks from refillers
        {"LoadOxygenTanks", "oxygensource", "oxygentankrefiller"}
    }) do
        namespace, _ = SBAI.util.CheckOptionGetNamespace(section, prevNamespace)
        if not namespace then goto continue end

        SBAI.Hook.Patch(namespace, "Barotrauma.AIObjectiveContainItem", "Act",
            function(instance, _)
                if  instance.TargetSlot == nil and
                    instance.SourceObjective ~= nil and
                    instance.SourceObjective.SourceObjective ~= nil and
                    SBAI.LuaUserData.IsTargetType(instance.SourceObjective.SourceObjective, "Barotrauma.AIObjectiveLoadItem") and
                    instance.SourceObjective.SourceObjective.TargetContainerTags[1] == refillerTag
                    then
                        local index = ItemContainerExtra.GetGeneralItemTagSlot(instance.container, generalItemTag)
                        if index > -1 then instance.TargetSlot = index end
                end
            end, Hook.HookMethodType.Before)
        ::continue::
    end
end