local SBAI = require("SBAI")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveContainItem"], "Act")

LuaUserData.RegisterType("Barotrauma.AIObjectiveMoveItem")

---@class Barotrauma.AIObjectiveMoveItem: Barotrauma.AIObjectiveDecontainItem

---@param namespace Namespace
---@param options table
return function(namespace, options)
    local AIObjectiveMoveItem = LuaUserData.CreateStatic("Barotrauma.AIObjectiveMoveItem")

    ---@type table<Barotrauma.Character,Types.Timer>
    local characterData = setmetatable({}, {
        ---@param t table<Barotrauma.Character,Types.Timer>
        ---@param k Barotrauma.Character
        __index = function(t, k)
            t[k] = Types.Timer.new(options["timeBetween"])
            return t[k]
        end
    })

    util.RegisterClear(characterData, util.CLEAR_REG.ROUND_END + util.CLEAR_REG.CHARACTER_DEATH)
    local generateFullItemPredicate

    do
        local Pickable = Components.Pickable

        ---@param refillerTag Barotrauma.Identifier
        ---@return fun(_:Barotrauma.Character, item:Barotrauma.Item)
        function generateFullItemPredicate(refillerTag)
            if refillerTag == "" then
                return function(_, item)
                    if item.ConditionPercentage > 0 then
                        local container = item.Container
                        
                        return not container or
                            not (
                                container.GetComponent(Pickable) and
                                util.IsSpecifiedContainer(container, item)
                            )
                    end
                end
            else
                return function(_, item)
                    local container = item.Container

                    return item.IsFullCondition and
                        container and
                        container.HasTag(refillerTag)
                end
            end
        end
    end

    for loadType, itemTag, containableTag, refillerTag, isFungible in util.Variator({
        {"BatteryCells", "mobilebattery", "mobilebattery", "batterycellrecharger", true},
        {"OxygenTanks", "refillableoxygensource", "oxygensource", "oxygentankrefiller", true},
        {"WeldingFuel", "weldingtoolfuel", "weldingtoolfuel", "", false},
        {"Ammunition", "handheldammo", "handheldammo", "", false}
    })
    do --[[@cast loadType string]] --[[@cast itemTag Barotrauma.Identifier]] --[[@cast containableTag Barotrauma.Identifier]] --[[@cast refillerTag Barotrauma.Identifier]] --[[@cast isFungible boolean]]
        local section = options[loadType]
        local minimumCondition
        local minimumEquippedCondition
        local targetItemPredicate
        local fullItemPredicate
    
        if not section.enable then goto continue1 end

        minimumCondition = section["minimumCondition"]
        minimumEquippedCondition = section["minimumEquippedCondition"]
        
        do
            local Pickable = Components.Pickable

            ---@param character Barotrauma.Character
            ---@param item Barotrauma.Item
            ---@return boolean
            function targetItemPredicate(character, item)
                local container = item.Container
                
                return container and
                    container.GetComponent(Pickable) and
                    util.IsSpecifiedContainer(container, refillerTag == "" and item or containableTag)
                    and (
                        not character.HasEquippedItem(container) or
                        item.ConditionPercentage <= minimumEquippedCondition
                    )
            end
        end

        fullItemPredicate = generateFullItemPredicate(refillerTag)

        namespace = namespace + loadType

        for objectiveType, fullObjectiveType, objId, specifierFunction in util.Variator({
            {"Idle", "Barotrauma.AIObjectiveIdle", "idle", util.True},
            {"Wait", "Barotrauma.AIObjectiveGoTo", "go to", function(instance) return instance.IsWaitOrder end}
        })
        do --[[@cast objectiveType string]] --[[@cast fullObjectiveType Barotrauma.Identifier]] --[[@cast specifierFunction fun(instance:Barotrauma.AIObjective):boolean]]
            section = options[objectiveType]

            local onlyAtFriendlyOutposts
            
            if not section.enable then goto continue2 end

            onlyAtFriendlyOutposts = section["OnlyAtFriendlyOutposts"]

            namespace = namespace + objectiveType

            LuaUserData.MakeFieldAccessible(Descriptors[fullObjectiveType], "subObjectives")

            do
                local ItemContainer = Components.ItemContainer

                SBAI.Hook.Patch(namespace(), fullObjectiveType, "Act",
                ---@param instance Barotrauma.AIObjectiveMoveItem
                ---@param ptable Barotrauma.LuaCsHook.ParameterTable
                function(instance, ptable)
                    local character = instance.character --[[@type Barotrauma.Character]]
                    
                    if  character.Submarine ~= nil and
                        character.Submarine.Info.IsPlayer
                    then
                        local characterDataInstance = characterData[character]
                        
                        if characterDataInstance:Update(ptable["deltaTime"]) then
                            if  not characterDataInstance["moveItemObjective"] and
                                specifierFunction(instance) and
                                not onlyAtFriendlyOutposts or (
                                    Level.IsLoadedFriendlyOutpost and
                                    character.IsOnPlayerTeam and
                                    not character.IsFriendlyNPCTurnedHostile
                                )
                            then
                                
                                local targetItem = util.FindItem(character, character.Inventory.FindAllItems(nil, true), itemTag, {0, minimumCondition}, targetItemPredicate)
                                targetItem = targetItem or util.FindItem(character, character.Inventory.FindAllItems(nil, true), itemTag, {0, minimumCondition},
                                function(c, i)
                                    if i.Container then
                                        return targetItemPredicate(c, i)
                                    end
                                    return true
                                end)
                                
                                local targetContainer = targetItem and targetItem.Container or nil --[[@type Barotrauma.Item?]]
                                local closestFullItem = targetItem and util.GetClosest(character.WorldPosition, util.FindItems(character, util.ItemGroup[itemTag], nil, nil,
                                function(c, i)
                                    if  isFungible and (
                                            targetContainer and
                                            targetContainer.GetComponent(ItemContainer).CanBeContained(i) or
                                            not targetContainer
                                        ) or
                                        not isFungible and
                                        i.Prefab.Identifier == targetItem.Prefab.Identifier
                                    then
                                        return fullItemPredicate(c, i)
                                    end
                                        return false
                                end)) or nil --[[@type Barotrauma.Item?]]
                                
                                if targetContainer and closestFullItem then
                                    local closestFullItemContainer = closestFullItem.Container
                                    local originalClosestFullItemContainer = closestFullItemContainer and closestFullItemContainer.GetComponent(ItemContainer) or nil --[[@type Barotrauma.Items.Components.ItemContainer]]
                                    
                                    ptable.PreventExecution = true

                                    characterDataInstance["index"] = targetContainer.OwnInventory.FindIndex(targetItem)
                                    
                                    ---@return Barotrauma.AIObjectiveMoveItem
                                    ---@nodiscard
                                    local function constructor()
                                        local objective = AIObjectiveMoveItem(character, closestFullItem, instance.objectiveManager, nil, targetContainer.GetComponent(ItemContainer), instance.PriorityModifier)
                                        
                                        objective.Equip = false
                                        objective.RemoveExistingWhenNecessary = true
                                        objective.RemoveExistingMax = 1

                                        return objective
                                    end
                                    ---@param objective Barotrauma.AIObjectiveMoveItem
                                    ---@return fun()
                                    local function onCompletedGenerator(objective)
                                        ---@type fun()
                                        local function onCompleted()
                                            if  refillerTag == "" and
                                                targetItem.ConditionPercentage > 0 and
                                                not closestFullItem.IsFullCondition then
                                                targetContainer.OwnInventory.TryPutItem(targetItem, characterDataInstance["index"], false, true, character, true, true)
                                            end
                                            if originalClosestFullItemContainer then
                                                originalClosestFullItemContainer.Inventory.TryPutItem(targetItem, character, nil, true, false)
                                            end

                                            characterDataInstance["moveItemObjective"] = nil
                                            characterDataInstance["index"] = nil
                                            instance.RemoveSubObjective(AIObjectiveMoveItem, objective)
                                        end
                                        return onCompleted
                                    end

                                    ---@param objective Barotrauma.AIObjectiveMoveItem
                                    ---@return fun()
                                    local function onAbandonGenerator(objective)
                                        ---@type fun()
                                        local function onAbandon()
                                            characterDataInstance["moveItemObjective"] = nil
                                            characterDataInstance["index"] = nil
                                            instance.RemoveSubObjective(AIObjectiveMoveItem, objective)
                                        end
                                        return onAbandon
                                    end

                                    local moveItemObjective --[[@type Barotrauma.AIObjectiveMoveItem]]

                                    for objective in instance.subObjectives do --[[@cast objective Barotrauma.AIObjective]]
                                        if objective.Identifier.Equals("move item") then
                                            moveItemObjective = objective
                                            break
                                        end
                                    end
                                    _, characterDataInstance["moveItemObjective"] = util.TryAddSubObjective(instance, moveItemObjective, constructor, onCompletedGenerator, onAbandonGenerator)
                                end
                            end
                        end
                    end
                end, Hook.HookMethodType.Before)
            end

            SBAI.Hook.Patch((namespace + objectiveType)(), "Barotrauma.AIObjectiveContainItem", "Act",
            ---@param instance Barotrauma.AIObjectiveContainItem
            ---@param _ Barotrauma.LuaCsHook.ParameterTable
            function(instance, _)
                if  not instance.TargetSlot and
                    instance.SourceObjective and
                    instance.SourceObjective.SourceObjective and
                    instance.SourceObjective.SourceObjective.Identifier.Equals(objId)
                then
                    local character = instance.SourceObjective.SourceObjective.character
                        
                    for k, _ in pairs(characterData) do
                        if k == character then
                            local index = characterData[character]["index"]

                            if index then
                                instance.TargetSlot = index
                                instance.AllowDangerousPressure = false
                                instance.AllowToFindDivingGear = false
                            end
                            break
                        end
                    end
                end
            end, Hook.HookMethodType.Before)
            namespace = -namespace
            ::continue2::
        end
        namespace = -namespace
    ::continue1::
    end
end