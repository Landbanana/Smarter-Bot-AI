local SBAI = require("SBAI")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")
local LuaUserData = LuaUserData

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveContainItem"], "Act")
LuaUserData.RegisterType("Barotrauma.AIObjectiveMoveItem")

---@class Barotrauma.AIObjectiveMoveItem: Barotrauma.AIObjectiveDecontainItem

---@param namespace Namespace
---@param options table
return function(namespace, options)
    ---@type table<Barotrauma.Character,Types.Timer>
    local characterData = setmetatable(util.RoundEndTemp:Add(namespace), {
        ---@param t table<Barotrauma.Character,Types.Timer>
        ---@param k Barotrauma.Character
        __index = function(t, k)
            t[k] = Types.Timer:new(options["timeBetween"])
            return t[k]
        end
    })

    util.ClearTableKeyOnCharacterDeath(characterData, namespace(), SBAI.Hook.Add)

    local AIObjectiveMoveItem = LuaUserData.CreateStatic("Barotrauma.AIObjectiveMoveItem")

    for loadType, itemTag, containableTag, refillerTag in util.Variator({
        {"BatteryCells", "mobilebattery", "mobilebattery", "batterycellrecharger"},
        {"OxygenTanks", "refillableoxygensource", "oxygensource", "oxygentankrefiller"}
    })
    do --[[@cast loadType string]] --[[@cast itemTag string]] --[[@cast containableTag string]] --[[@cast refillerTag string]]
        local section = options[loadType]
        local minimumCondition
        local minimumEquippedConditionTest
    
        if not section.enable then goto continue1 end

        minimumCondition = section["minimumCondition"]
        minimumEquippedConditionTest = function(character, item)
            return  not item.Container or
                    not character.HasEquippedItem(item.Container) or
                    item.ConditionPercentage <= section["minimumCondition"]
        end

        namespace = namespace + loadType

        for objectiveType, fullObjectiveType, specifierFunction in util.Variator({
            {"Idle", "Barotrauma.AIObjectiveIdle", util.True},
            {"Wait", "Barotrauma.AIObjectiveGoTo", function(instance) return instance.IsWaitOrder end}
        })
        do --[[@cast objectiveType string]] --[[@cast fullObjectiveType string]] --[[@cast specifierFunction fun(instance:Barotrauma.AIObjective):boolean]]
            section = options[objectiveType]
            local onlyAtFriendlyOutposts
            
            if not section.enable then goto continue2 end

            onlyAtFriendlyOutposts = section["OnlyAtFriendlyOutposts"]

            namespace = namespace + objectiveType

            LuaUserData.MakeFieldAccessible(Descriptors[fullObjectiveType], "subObjectives")

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
                            local itemList = character.Inventory.FindAllItems(nil, true) --[=[@type Barotrauma.Item[]]=]
                            local i = 0 --[[@type integer]]
                            local potentialItems = {} --[=[@type Barotrauma.Item[]]=]
                            local potentialFullItems = {} --[=[@type Barotrauma.Item[]]=]
                            local targetItem --[[@type Barotrauma.Item]]
                            local potentialItem = util.FindItem(character, itemList, itemTag, {0, minimumCondition}, minimumEquippedConditionTest)
                            
                            if potentialItem then
                                local potentialContainer = util.GetClosest(character.WorldPosition, util.FindSpecificContainers(character, util.ItemGroup[refillerTag], containableTag, nil, 100, nil, true)) --[[@type Barotrauma.Item]]
                                
                                if potentialContainer then
                                    local potentialFullItem = util.FindItem(character, potentialContainer.OwnInventory.FindAllItems(nil, false), itemTag, 100) --[[@type Barotrauma.Item]]
                                    
                                    if potentialFullItem then
                                        i = i + 1
                                        potentialItems[i] = potentialItem
                                        potentialFullItems[i] = potentialFullItem
                                    end
                                end
                            end

                            local closestFullItem = util.GetClosest(character.WorldPosition, potentialFullItems) --[[@type Barotrauma.Item]]
                            
                            for n, item in ipairs(potentialFullItems) do
                                if closestFullItem == item then
                                    targetItem = potentialItems[n]
                                end
                            end
                            
                            if targetItem and closestFullItem then
                                local targetContainer = targetItem.Container --[[@type Barotrauma.Item]]
                                
                                ptable.PreventExecution = true

                                if not (closestFullItem and targetContainer) then
                                    local hasMoveItemSubObjective = false

                                    for objective in instance.subObjectives do
                                        if LuaUserData.IsTargetType(objective, "Barotrauma.AIObjectiveMoveItem") then
                                            hasMoveItemSubObjective = true
                                            break
                                        end
                                    end
                                    if not hasMoveItemSubObjective then return end
                                end

                                if closestFullItem and targetContainer then
                                    local originalClosestFullItemContainer = closestFullItem.Container.GetComponent(Components.ItemContainer) --[[@type Barotrauma.Items.Components.ItemContainer]]
                                    
                                    ---@return Barotrauma.AIObjectiveMoveItem
                                    ---@nodiscard
                                    local function constructor()
                                        local objective = AIObjectiveMoveItem(character, closestFullItem, instance.objectiveManager, nil, targetContainer.GetComponent(Components.ItemContainer), instance.PriorityModifier)
                                        
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
                                            originalClosestFullItemContainer.Inventory.TryPutItem(targetItem, character, nil, true, true)

                                            characterDataInstance["moveItemObjective"] = nil
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
                                            instance.RemoveSubObjective(AIObjectiveMoveItem, objective)
                                        end
                                        return onAbandon
                                    end

                                    local moveItemObjective --[[@type Barotrauma.AIObjectiveMoveItem]]

                                    for objective in instance.subObjectives do
                                        if LuaUserData.IsTargetType(objective, "Barotrauma.AIObjectiveMoveItem") then
                                            moveItemObjective = objective
                                            break
                                        end
                                    end
                                    _, characterDataInstance["moveItemObjective"] = util.TryAddSubObjective(instance, moveItemObjective, constructor, onCompletedGenerator, onAbandonGenerator)
                                end
                            end
                        end
                    end
                end
            end, Hook.HookMethodType.Before)

            SBAI.Hook.Patch((namespace + objectiveType)(), "Barotrauma.AIObjectiveContainItem", "Act",
            ---@param instance Barotrauma.AIObjectiveContainItem
            ---@param _ Barotrauma.LuaCsHook.ParameterTable
            function(instance, _)
                if  not instance.TargetSlot and
                    instance.SourceObjective and
                    instance.SourceObjective.SourceObjective and
                    LuaUserData.IsTargetType(instance.SourceObjective.SourceObjective, fullObjectiveType)
                then
                    local character = instance.SourceObjective.SourceObjective.character
                        
                    for k, _ in pairs(characterData) do
                        if k == character then
                            local index = util.GetSpecificSlot(instance.container.Item, instance.SourceObjective.TargetItem)

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