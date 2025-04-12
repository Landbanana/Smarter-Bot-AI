SBAI = require("SBAI")
local util = require("SBAI.Shared.util")

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveContainItem"], "Act")
LuaUserData.RegisterType("Barotrauma.AIObjectiveMoveItem")

local startTimeBetween = SBAI.Config.defaults.START_TIME_BETWEEN

---@type table<AIObjective,{timer:number, moveItemObjective:Barotrauma.AIObjectiveMoveItem?}>
local allInstanceData = setmetatable({}, {
    ---@param t table<AIObjective,{timer:number, moveItemObjective:Barotrauma.AIObjectiveMoveItem?}>
    ---@param k Barotrauma.AIObjective
    __index = function(t, k)
        t[k] = {timer=startTimeBetween, moveItemObjective=nil}
        return t[k]
    end,
    ---@param t table<AIObjective,{timer:number, moveItemObjective:Barotrauma.AIObjectiveMoveItem?}>
    ---@param k Barotrauma.AIObjective
    ---@param v {timer:number, moveItemObjective:Barotrauma.AIObjectiveMoveItem?}
    __newindex = function(t, k, v)
        if rawget(t, k) == nil then
            local function removeInstanceFunction()
                t[k] = nil
            end
            k.Deselected.add(removeInstanceFunction)
        end
        rawset(t, k, v)
    end
})

---@param namespace Namespace
---@param options table
return function(namespace, options)
    local LuaUserData = LuaUserData
    local timeBetween = options["timeBetween"] --[[@type number]]
    
    ---@param minimumEquippedCondition number
    ---@return fun(character:Barotrauma.Character, item:Barotrauma.Item):boolean
    ---@nodiscard
    local function GenerateEquippedConditionTest(minimumEquippedCondition)
        return function(character, item)
            return  item.Container == nil or
                    not character.HasEquippedItem(item.Container) or
                    item.ConditionPercentage <= minimumEquippedCondition
        end
    end
    
    ---@param character Barotrauma.Character
    ---@return boolean
    local function OnlyAtFriendlyOutposts(character)
        return  Level.IsLoadedFriendlyOutpost and
                character.IsOnPlayerTeam and
                not character.IsFriendlyNPCTurnedHostile
    end

    local replenishTypeToTargetItemTag = {
        ["BatteryCells"]="mobilebattery",
        ["OxygenTanks"]="refillableoxygensource"
    }

    local objectiveTypeToObjectiveFullType = {
        ["Idle"]="Barotrauma.AIObjectiveIdle",
        ["Wait"]="Barotrauma.AIObjectiveGoTo"
    }

    ---@type table<string,fun(instance:Barotrauma.AIObjective):boolean>
    local specifierFunctions = {
        ["Idle"]=util.True,
        ---@param instance Barotrauma.AIObjectiveGoTo
        ---@return boolean
        ["Wait"]=function(instance)
            return instance.IsWaitOrder
        end
    }

    local AIObjectiveMoveItem = LuaUserData.CreateStatic("Barotrauma.AIObjectiveMoveItem")

    local selectedReplenish = {} --[[@type table<string,{targetItemTag:Barotrauma.Identifier, targetContainableItemTag:Barotrauma.Identifier, refillerTag:Barotrauma.Identifier, minimumCondition:number, MinimumEquippedConditionTest:fun(character?:Barotrauma.Character, item:Barotrauma.Item):boolean}>]]
    local hasSelectedObjectives = false --[[@type boolean]]
    local hasSelectedReplenish = false --[[@type boolean]]

    for _, replenishType in pairs({"BatteryCells", "OxygenTanks"}) do
        local section = options[replenishType]
        
        if section.enable then
            local targetItemTag = replenishTypeToTargetItemTag[replenishType]

            hasSelectedReplenish = true
            selectedReplenish[replenishType]={
                targetItemTag=targetItemTag,
                targetContainableItemTag=util.convert.ItemTagToContainableItemTag[targetItemTag],
                refillerTag=util.convert.ItemTagToRefillerTag[targetItemTag],
                minimumCondition=section["minimumCondition"],
                MinimumEquippedConditionTest=GenerateEquippedConditionTest(section["minimumEquippedCondition"])
            }
        end
    end

    for objectiveType in {"Idle", "Wait"} do
        hasSelectedObjectives = true
        if not hasSelectedReplenish then break end
        
        local section = options[objectiveType]
        local objectiveFullType, specifierFunction, onlyAtFriendlyOutposts
        
        if not section.enable then goto continue end
        
        objectiveFullType = objectiveTypeToObjectiveFullType[objectiveType]
        specifierFunction = specifierFunctions[objectiveType]
        onlyAtFriendlyOutposts = section["OnlyAtFriendlyOutposts"] and OnlyAtFriendlyOutposts or util.True

        LuaUserData.MakeFieldAccessible(Descriptors[objectiveFullType], "subObjectives")
        
        SBAI.Hook.Patch(namespace(), objectiveFullType, "Act",
        ---@param instance Barotrauma.AIObjective
        ---@param ptable Barotrauma.LuaCsHook.ParameterTable
        function(instance, ptable)
            local character = instance.character --[[@type Barotrauma.Character]]
            
            if  character.Submarine ~= nil and
                character.Submarine.Info.IsPlayer
            then
                local instanceData = allInstanceData[instance]
                
                if instanceData.timer <= 0 then
                    instanceData.timer = util.AddNoise(timeBetween, 0.1)
                    
                    if  instanceData.moveItemObjective == nil and
                        specifierFunction(instance) and
                        onlyAtFriendlyOutposts(character)
                    then
                        local itemList = character.Inventory.FindAllItems(nil, true) --[=[@type Barotrauma.Item[]]=]
                        local i = 0 --[[@type integer]]
                        local potentialItems = {} --[=[@type Barotrauma.Item[]]=]
                        local potentialFullItems = {} --[=[@type Barotrauma.Item[]]=]
                        local targetItem = nil --[[@type Barotrauma.Item]]
                        
                        for _, replenishData in pairs(selectedReplenish) do
                            local potentialItem = util.FindItem(character, itemList, replenishData.targetItemTag, {0, replenishData.minimumCondition}, replenishData.MinimumEquippedConditionTest)
                            
                            if potentialItem ~= nil then
                                local potentialContainer = util.GetClosest(character.WorldPosition, util.FindSpecificContainers(character, SBAI.itemGroup[replenishData.refillerTag], replenishData.targetContainableItemTag, nil, 100, nil, true)) --[[@type Barotrauma.Item]]
                                
                                if potentialContainer ~= nil then
                                    local potentialFullItem = util.FindItem(character, potentialContainer.OwnInventory.FindAllItems(nil, false), replenishData.targetItemTag, 100) --[[@type Barotrauma.Item]]
                                    
                                    if potentialFullItem ~= nil then
                                        i = i + 1
                                        potentialItems[i] = potentialItem
                                        potentialFullItems[i] = potentialFullItem
                                    end
                                end
                            end
                        end

                        local closestFullItem = util.GetClosest(character.WorldPosition, potentialFullItems) --[[@type Barotrauma.Item]]
                        
                        for n, item in ipairs(potentialFullItems) do
                            if closestFullItem == item then
                                targetItem = potentialItems[n]
                            end
                        end
                        
                        if targetItem ~= nil and closestFullItem ~= nil then
                            local targetContainer = targetItem.Container --[[@type Barotrauma.Item]]
                            
                            ptable.PreventExecution = true

                            if closestFullItem == nil or targetContainer == nil then
                                local hasMoveItemSubObjective = false

                                for objective in instance.subObjectives do
                                    if LuaUserData.IsTargetType(objective, "Barotrauma.AIObjectiveMoveItem") then
                                        hasMoveItemSubObjective = true
                                        break
                                    end
                                end
                                if not hasMoveItemSubObjective then return end
                            end

                            if closestFullItem ~= nil and targetContainer ~= nil then
                                
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

                                        instanceData.moveItemObjective = nil
                                        instance.RemoveSubObjective(AIObjectiveMoveItem, objective)
                                    end
                                    return onCompleted
                                end

                                ---@param objective Barotrauma.AIObjectiveMoveItem
                                ---@return fun()
                                local function onAbandonGenerator(objective)
                                    ---@type fun()
                                    local function onAbandon()
                                        instanceData.moveItemObjective = nil
                                        instance.RemoveSubObjective(AIObjectiveMoveItem, objective)
                                    end
                                    return onAbandon
                                end

                                local AIObjectiveMoveItem

                                for objective in instance.subObjectives do
                                    if LuaUserData.IsTargetType(objective, "Barotrauma.AIObjectiveMoveItem") then
                                        AIObjectiveMoveItem = objective
                                        break
                                    end
                                end
                                _, AIObjectiveMoveItem = util.TryAddSubObjective(instance, AIObjectiveMoveItem, constructor, onCompletedGenerator, onAbandonGenerator)
                            end
                        end
                    end
                else
                    instanceData.timer = instanceData.timer - ptable["deltaTime"]
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
                LuaUserData.IsTargetType(instance.SourceObjective.SourceObjective, objectiveFullType)
            then
                local baseObjective = instance.SourceObjective.SourceObjective
                    
                for k, _ in pairs(allInstanceData) do
                    if k == baseObjective then
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
        ::continue::
    end

    -- hopefully prevent any memory leaks
    if hasSelectedObjectives and hasSelectedReplenish then
        SBAI.Hook.Add("roundEnd", namespace(),
        function()
            util.ClearTable(allInstanceData)
        end)
    end
end,
function()
    util.ClearTable(allInstanceData)
end