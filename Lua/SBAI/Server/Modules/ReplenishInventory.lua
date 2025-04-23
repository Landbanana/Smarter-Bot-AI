local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveContainItem"], "Act")

LuaUserData.RegisterType("Barotrauma.AIObjectiveMoveItem")

local Pickable = Components.Pickable


local allSections = {
    ["BatteryCells"] = {"mobilebattery", "mobilebattery", "batterycellrecharger", true},
    ["OxygenTanks"] = {"refillableoxygensource", "oxygensource", "oxygentankrefiller", true},
    ["WeldingFuel"] = {"weldingtoolfuel", "weldingtoolfuel", "", false},
    ["Ammunition"] = {"handheldammo", "handheldammo", "", false}
}

local generateFullItemPredicate
local generateTargetItemPredicate

do
    local IsSpecifiedContainer = util.IsSpecifiedContainer

    local function fullItemPredicateNoRefiller(character, item)
        if item.ConditionPercentage > 0 then
            local container = item.Container
            
            return not container or
                not (
                    container.GetComponent(Pickable) and
                    IsSpecifiedContainer(container, item)
                )
        end
    end

    ---@param refillerTag Barotrauma.Identifier
    ---@return fun(character:Barotrauma.Character, item:Barotrauma.Item):boolean
    function generateFullItemPredicate(refillerTag)
        if refillerTag == "" then
            return fullItemPredicateNoRefiller
        else
            return function(character, item)
                local container = item.Container
        
                return item.IsFullCondition and
                    container and
                    container.HasTag(refillerTag)
            end
        end
    end
end

do
    local IsSpecifiedContainer = util.IsSpecifiedContainer

    ---@param refillerTag string
    ---@param containableTag string
    ---@param minEqCon number
    ---@return fun(character:Barotrauma.Character, item:Barotrauma.Item)
    function generateTargetItemPredicate(refillerTag, containableTag, minEqCon)
        ---@param character Barotrauma.Character
        ---@param item Barotrauma.Item
        ---@return boolean
        return function(character, item)
            local container = item.Container
            
            return container and
                container.GetComponent(Pickable) and
                IsSpecifiedContainer(container, refillerTag == "" and item or containableTag)
                and (
                    not character.HasEquippedItem(container) or
                    item.ConditionPercentage <= minEqCon
                )
        end
    end
end

---@param options any
---@return table[]
local function getSections(options)
    local sections = {}
    local i = 0

    for loadType, loadData in pairs(allSections) do
        local section = options[loadType]
            
        if section.enable then
            local itemTag, containableTag, refillerTag, isFungible = table.unpack(loadData)
            local minCon, minEqCon = section["minimumCondition"], section["minimumEquippedCondition"]
            local fullItemPredicate = generateFullItemPredicate(refillerTag)
            local targetItemPrediate = generateTargetItemPredicate(refillerTag, containableTag, minEqCon)

            i = i + 1
            sections[i] = {itemTag, containableTag, refillerTag, isFungible, minCon, minEqCon, fullItemPredicate, targetItemPrediate}
        end
    end
    return sections
end

---@param self Types.Module
local function activate(self)
    local allLoadData = getSections(self.options)

    if #allLoadData <= 0 then return end

    local anyObjTypeEnabled = false
    local characterData --[[@type table<Barotrauma.Character,Types.Timer>]]

    do
        local Timer = Types.Timer
        local timeBetween = self.options["timeBetween"]

        ---@type table<Barotrauma.Character,Types.Timer>
        characterData = setmetatable(self:RegisterTable("ROUND_END", "CHARACTER_DEATH"), {
            ---@param t table<Barotrauma.Character,Types.Timer>
            ---@param k Barotrauma.Character
            __index = function(t, k)
                t[k] = Timer.new(timeBetween)
                return t[k]
            end
        })
    end

    local AIObjectiveMoveItem = LuaUserData.CreateStatic("Barotrauma.AIObjectiveMoveItem")
    local ItemContainer = Components.ItemContainer

    local unpack = table.unpack
    local FindItem = util.FindItem
    local FindItems = util.FindItems
    local GetClosest = util.GetClosest
    local True = util.True
    local IsWaitObjective = util.IsWaitObjective
    local TryAddSubObjective = util.TryAddSubObjective
    local Variator = util.Variator

    for objectiveType, fullObjectiveType, specifierFunction in Variator({
        {"Idle", "Barotrauma.AIObjectiveIdle", True},
        {"Wait", "Barotrauma.AIObjectiveGoTo", IsWaitObjective}
    }) do
        local section = self.options[objectiveType]
        local onlyAtFriendlyOutposts
        
        if not section.enable then goto continue end

        anyObjTypeEnabled = true
        onlyAtFriendlyOutposts = section["onlyAtFriendlyOutposts"]

        LuaUserData.MakeFieldAccessible(Descriptors[fullObjectiveType], "subObjectives")

        self:AddPatch(fullObjectiveType, "Act", nil,
        function(instance, ptable)
            local character = instance.character --[[@type Barotrauma.Character]]
            
            if  character.Submarine ~= nil and
                character.Submarine.Info.IsPlayer
            then
                local characterDataInstance = characterData[character]
                
                if characterDataInstance:Update(ptable["deltaTime"]) then
                    if  not characterDataInstance["moveItemObj"] and
                        specifierFunction(instance) and
                        not onlyAtFriendlyOutposts or (
                            Level.IsLoadedFriendlyOutpost and
                            character.IsOnPlayerTeam and
                            not character.IsFriendlyNPCTurnedHostile
                        )
                    then
                        for loadData in allLoadData do
                            local itemTag, _, refillerTag, isFungible, minCon, _, fullItemPredicate, targetItemPredicate = unpack(loadData)

                            local targetItem = FindItem(character, character.Inventory.FindAllItems(nil, true), itemTag, {0, minCon}, targetItemPredicate)
                            
                            targetItem = targetItem or FindItem(character, character.Inventory.FindAllItems(nil, true), itemTag, {0, minCon},
                            function(c, i)
                                if i.Container then
                                    return targetItemPredicate(c, i)
                                end
                                return true
                            end)
                            
                            local targetContainer = targetItem and targetItem.Container or nil --[[@type Barotrauma.Item?]]
                            local closestFullItem = targetItem and GetClosest(character.WorldPosition, FindItems(character, util.ItemGroup[itemTag], nil, nil,
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
                                        characterDataInstance["mainObj"] = nil
                                        characterDataInstance["moveItemObj"] = nil
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
                                        characterDataInstance["mainObj"] = nil
                                        characterDataInstance["moveItemObj"] = nil
                                        characterDataInstance["index"] = nil
                                        instance.RemoveSubObjective(AIObjectiveMoveItem, objective)
                                    end
                                    return onAbandon
                                end

                                local moveItemObj --[[@type Barotrauma.AIObjectiveMoveItem]]

                                for objective in instance.subObjectives do --[[@cast objective Barotrauma.AIObjective]]
                                    if objective.Identifier == "move item" then
                                        moveItemObj = objective
                                        break
                                    end
                                end
                                characterDataInstance["mainObj"] = instance
                                _, characterDataInstance["moveItemObj"] = TryAddSubObjective(instance, moveItemObj, constructor, onCompletedGenerator, onAbandonGenerator)
                            end
                        end
                    end
                end
            end
        end, Hook.HookMethodType.Before)
        ::continue::
    end
    if anyObjTypeEnabled then
        self:AddPatch("Barotrauma.AIObjectiveContainItem", ".ctor",
        {"Barotrauma.Character", "Barotrauma.Item", "Barotrauma.Items.Components.ItemContainer", "Barotrauma.AIObjectiveManager", "System.Single"},
        function(instance, ptable)
            local characterDataInstance = rawget(characterData, ptable["character"])

            if characterDataInstance then
                local mainObj = characterDataInstance["mainObj"]

                if  mainObj and
                    mainObj == ptable["objectiveManager"].CurrentObjective
                then
                    instance.TargetSlot = characterDataInstance["index"]
                    instance.AllowDangerousPressure = false
                    instance.AllowToFindDivingGear = false
                end
            end
        end, Hook.HookMethodType.After)
    end
end

return Types.Module.new(activate)