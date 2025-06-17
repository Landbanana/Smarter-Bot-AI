local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

do
    local MakeFieldAccessible = LuaUserData.MakeFieldAccessible
    local MakePropertyAccessible = LuaUserData.MakePropertyAccessible
    local AutoRegisterType = util.AutoRegisterType
    local Descriptors = Descriptors

    AutoRegisterType("Barotrauma.AITargetMemory")
    AutoRegisterType("Barotrauma.PetBehavior+Food")

    --MakeFieldAccessible(Descriptors["Barotrauma.EnemyAIController"], "currentTargetMemory")
    MakeFieldAccessible(Descriptors["Barotrauma.EnemyAIController"], "currentTargetingParams")
    MakeFieldAccessible(Descriptors["Barotrauma.Item"], "_cleanableItems")
    MakeFieldAccessible(Descriptors["Barotrauma.PetBehavior"], "foods")
    
    --MakePropertyAccessible(Descriptors["Barotrauma.EnemyAIController"], "SelectedAiTarget")
    MakePropertyAccessible(Descriptors["Barotrauma.ItemPrefab"], "PreferredContainers")

    --LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.EnemyAIController"], "GetTargetMemory")
end

---@param self Types.Module
---@param options table
local function activateEatFoodInInventory(self, options)
    self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")
    self:AddCommonModule("SBAI.Server.CommonModules.XElementExpansion")
    
    local AIState = self:RegisterEnumTable("Barotrauma.AIState")

    local Eat = AIState.Eat
    
    local FilterList = util.itertools.FilterList
    
    local allPetData = Types.AllTimedCharacterData.new(self, options["timeBetween"])
    local foodItemTags = Types.Set.new()
    local checkState = Types.Set.new()

    local overrideProtectOwner = options["overrideProtectOwner"]
    
    checkState:Add(AIState.Idle)
    checkState:Add(AIState.Follow)
    if overrideProtectOwner then checkState:Add(AIState.Protect) end

    do
        local CharacterPrefabs = CharacterPrefab.Prefabs
        local ItemPrefabs = ItemPrefab.Prefabs

        local Any = util.itertools.Any
        local Contains = util.itertools.Contains
        local xPath = util.xPath

        ---@type table<Barotrauma.Identifier,boolean>
        local checkedTags = setmetatable({}, {
            __index=function(t, k)
                local out = Any(ItemPrefabs,
                    ---@param prefab Barotrauma.ItemPrefab
                    function(prefab)
                        return Contains(prefab.Tags, k) or
                            prefab.Identifier == k
                    end)
                
                t[k] = out
                return out
            end
        })

        for prefab in CharacterPrefabs do
            local xElement = prefab.ConfigElement.Element

            for petElement in FilterList(xPath(xElement, "ai/petbehavior"),
                function(petElement)
                    return petElement.GetAttributeFloat("hungerincreaserate", 0.25) > 0.0
                end) do
                for eatElement in xPath(petElement, "eat") do
                    local tag = eatElement.GetAttributeIdentifier("tag")

                    if checkedTags[tag] then
                        foodItemTags:Add(tag)
                    end
                end
            end
        end
    end

    local findFood

    do
        ---@param inventory Barotrauma.Inventory
        ---@param item Barotrauma.Item
        ---@return boolean
        local function itemHasAITarget(inventory, item)
            return item.AiTarget ~= nil
        end

        ---@param pet Barotrauma.Character
        ---@param petbehavior Barotrauma.PetBehavior
        ---@return Barotrauma.Item?
        ---@return Barotrauma.CharacterParams.TargetParams?
        function findFood(pet, petbehavior)
            local inventory = pet.Inventory

            if inventory then
                local bestItem
                local bestTargetParams
                local foods = {}
                local i = 0

                for food in petbehavior.foods do
                    if  foodItemTags[food.Tag] and
                        food.TargetParams
                    then
                        i = i + 1
                        foods[i] = food
                    end
                end
                if i <= 0 then goto skip end

                do
                    local highestPriority = 0.0

                    for item in inventory:SBAI_findAllItems(false, false, itemHasAITarget) do
                        for food in foods do
                            local tag = food.Tag

                            if  (item.HasTag(tag) or
                                item.Prefab.Identifier == tag)
                            then
                                local targetParams = food.TargetParams

                                if targetParams then
                                    local priority = food.Priority

                                    if priority > highestPriority then
                                        bestItem = item
                                        bestTargetParams = targetParams
                                        highestPriority = priority
                                        if priority >= 100 then
                                            goto skip
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                ::skip::
                return bestItem, bestTargetParams
            end
        end
    end

    -- ---@type {[Barotrauma.AIState]: fun(petbehavior:Barotrauma.PetBehavior):(Barotrauma.Item?, Barotrauma.CharacterParams.TargetParams?)}
    -- local checkState = {
    --     [AIState.Idle]=findFood,
    --     [AIState.Follow]=findFood,
    --     [AIState.Protect]=options["overrideProtectOwner"] and findFood or nil
    -- }
    -- if options["ignoreOwner"] then
    --     checkState[AIState.Protect] = findFood
    -- end

    

    -- ---@param instance Barotrauma.EnemyAIController
    -- ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    -- ---@param checkState boolean
    -- ---@param ... Barotrauma.AIState
    -- ---@return boolean
    -- local function updateEat(instance, ptable, checkState, ...)
    --     local petbehavior = instance.PetBehavior

    --     if petbehavior then
    --         local pet = instance.Character

    --         if allPetTimers:Get(pet).timer:UpdateClock() then
    --             if checkState[instance.State] then
    --                 local item, targetParams = findFood(petbehavior)

    --                 if  item and
    --                     targetParams
    --                 then
    --                     instance.currentTargetingParams = targetParams
    --                     instance.SelectTarget(item.AiTarget, targetParams.Priority)
    --                     instance.State = Eat
    --                     return true
    --                 end
    --             end
    --         end
    --     end
    --     return false
    -- end

    -- self:AddPatch("Barotrauma.EnemyAIController", "UpdateIdle", nil,
    -- function(instance, ptable)
    --     if updateEat(instance, ptable, false) then
    --         ptable.PreventExecution = true
    --     end
    -- end, Hook.HookMethodType.Before)

    -- self:AddPatch("Barotrauma.EnemyAIController", "UpdateFollow", nil,
    -- function(instance, ptable)
    --     if updateEat(instance, ptable, true, Follow, Protect) then
    --         ptable.PreventExecution = true
    --     end
    -- end, Hook.HookMethodType.Before)

    self:AddPatch("Barotrauma.EnemyAIController", "UpdateTargets", nil,
    function(instance, ptable)
        local petbehavior = instance.PetBehavior

        if  petbehavior and
            petbehavior.HungerIncreaseRate > 0.0
        then
            local pet = instance.Character
            local petData = allPetData:Get(pet)
            local eatTarget = petData.eatTarget --[[@type Barotrauma.Item]]

            if  eatTarget or
                petData:UpdateClock()
            then
                if checkState[instance.State] then
                    local targetParams

                    if  eatTarget and
                        not eatTarget.Removed
                    then
                        local eatTargetId = eatTarget.Prefab.Identifier

                        for food in petbehavior.foods do
                            local tag = food.Tag

                            if  foodItemTags[tag] and
                                (eatTarget.HasTag(tag) or
                                eatTargetId == tag)
                            then
                                targetParams = food.TargetParams
                                break
                            end
                        end
                    end
                    if not targetParams then
                        eatTarget, targetParams = findFood(pet, petbehavior)
                    end
                    if  eatTarget and
                        targetParams
                    then
                        -- local aiTarget = eatTarget.AiTarget

                        instance.currentTargetingParams = targetParams
                        --instance.currentTargetMemory = instance.GetTargetMemory(aiTarget, true, true)
                        --instance.SelectedAiTarget = aiTarget
                        instance.SelectTarget(eatTarget.AiTarget, targetParams.Priority)
                        instance.State = Eat
                    end
                else
                    eatTarget = nil
                end
                petData.eatTarget = eatTarget
            end
        end
    end, Hook.HookMethodType.After)
end

---@param self Types.Module
---@param options table
local function activateBotsPlayWhenIdle(self, options)
    self:AddCommonModule("SBAI.Server.CommonModules.AIObjectiveExpansion")
    
    local Character = Character
    local PETPLAY = Constants.ID_OBJECTIVE.PETPLAY

    local GetFirst = util.itertools.GetFirst
    local Partial5 = util.functools.Partial5

    local allCharacterData = Types.AllTimedCharacterData.new(self, options["timeBetween"])

    self:AddPatch("Barotrauma.AIObjectiveIdle", "Act", nil,
    function(instance, ptable)
        local character = instance.character
        local characterData = allCharacterData:Get(character)

        if  characterData:Update(ptable["deltaTime"])
            and not characterData.petplayObj
        then
            ---@type Barotrauma.Character
            local nearbyUnhappyPet = GetFirst(Character.CharacterList,
            function(pet)
                if  pet.IsPet and
                    character.IsOnFriendlyTeam(pet)
                then
                    local petBehavior = pet.AIController.PetBehavior
                        
                    if  petBehavior.PlayTimer <= 0 and
                        petBehavior.Happiness < petBehavior.HappyThreshold
                    then
                        return character.CanInteractWith(pet)
                    end
                end
            end)

            if nearbyUnhappyPet then
                local function constructor()
                    local objective = AIObjectiveGoTo(nearbyUnhappyPet, character, character.AIController.ObjectiveManager, false, false, 1, 100.0)
                    
                    objective.AllowGoingOutside = false
                    objective.DebugLogWhenFails = false
                    objective.IgnoreIfTargetDead = true
                    objective.SpeakIfFails = false

                    local petbehavior = nearbyUnhappyPet.AIController.PetBehavior --[[@type Barotrauma.PetBehavior]]
                    local happyThreshold = petbehavior.HappyThreshold

                    function objective:AbortCondition()
                        return petbehavior.Happiness > happyThreshold or
                            nearbyUnhappyPet.IsDead
                    end

                    local cleanupSubObj = Partial5(instance.SBAI_cleanupSubObj, instance, objective, AIObjectiveGoTo, characterData, "petplayObj")

                    objective.Completed.add(
                    function()
                        petbehavior.Play(character)
                        return cleanupSubObj()
                    end)
                    objective.Abandoned.add(cleanupSubObj)
                    return objective
                end 

                ptable.PreventExecution = instance:SBAI_tryAddSubObjective(characterData, "petplayObj", PETPLAY, true, false, constructor)
            end
        end
    end, Hook.HookMethodType.Before)
end

local petItemIds

---@param self Types.Module
---@param options table
local function activateCleanableProduce(self, options)
    local Item = Item

    local GetItemPrefab = ItemPrefab.GetItemPrefab
    local xPath = util.xPath

    petItemIds = Types.Set.new()

    for prefab in CharacterPrefab.Prefabs do
        for xSubElement in xPath(prefab.ConfigElement.Element, "ai/petbehavior/itemproduction/item") do
            if xSubElement then
                local itemId = xSubElement.GetAttributeIdentifier("identifier")

                if itemId.Value ~= "" then
                    petItemIds:Add(itemId)
                end
            end
        end
    end

    for id in petItemIds do
        
        local prefab = GetItemPrefab(id)

        if prefab then
            local xElement = prefab.ConfigElement.Element

            if #xPath(xElement, "PreferredContainer") > 0 then
                petItemIds:Remove(id)
            end
        end
    end

    return util.DoWithTemporaryRegistrations({
        "System.Collections.Immutable.ImmutableArray`1[[Barotrauma.PreferredContainer,"..Constants.CLR_TYPE_POSTFIX.."]]",
        "System.Collections.Generic.List`1[[Barotrauma.Item]]"
    },
    function()
        local newPrefConts = GetItemPrefab(Constants.D_PETITEM_TEMPLATE).PreferredContainers

        for id in petItemIds do
            local prefab = GetItemPrefab(id)
    
            if #prefab.PreferredContainers <= 0 then
                prefab.PreferredContainers = newPrefConts
            end
        end

        local cleanableItems = Item._cleanableItems --[[@type System.Collections.Generic.List*1Barotrauma*Item]]

        for item in Item.ItemList do --[[@cast item Barotrauma.Item]]
            if  petItemIds[item.Prefab.Identifier] and
                not cleanableItems.Contains(item)
            then
                cleanableItems.Add(item)
            end
        end
    end)
end

-- ---@param self Types.Module
-- local function activateFollowRestrictions(self)
--     self:AddPatch("Barotrauma.AITarget", "ShouldBeIgnored", nil,
--     function(instance, ptable)
--         if instance. then
--             print("yas")
--         end
--     end, Hook.HookMethodType.Before)
-- end

---@param self Types.Module
local function activate(self)
    self:DoOption("EatFoodInInventory", activateEatFoodInInventory)
    self:DoOption("BotsPlayWhenIdle", activateBotsPlayWhenIdle)
    self:DoOption("CleanableProduce", activateCleanableProduce)

    --activateFollowRestrictions(self)

    -- self:AddPatch("Barotrauma.AIObjectiveIdle", "Wander", nil,
    -- function(instance, ptable)
    --     print(instance.character.Name, ": wander")
    -- end, Hook.HookMethodType.After)
end

---@param self Types.Module
local function deactivate(self)
    if petItemIds then
        local Item = Item
        local GetItemPrefab = ItemPrefab.GetItemPrefab

        local DoWithTemporaryRegistrations = util.DoWithTemporaryRegistrations
        local sort = table.sort

        DoWithTemporaryRegistrations({"System.Collections.Immutable.ImmutableArray`1[[Barotrauma.PreferredContainer,"..Constants.CLR_TYPE_POSTFIX.."]]"},
        function()
            for id in petItemIds do
                local prefab = GetItemPrefab(id)
                local oldPrefConts = prefab.PreferredContainers
        
                if #oldPrefConts > 0 then
                    prefab.PreferredContainers = oldPrefConts.Clear()
                end
            end

            local cleanableList = Item._cleanableItems --[=[@type Barotrauma.Item[]]=]

            return DoWithTemporaryRegistrations({"System.Collections.Generic.List`1[[Barotrauma.Item]]"},
            function()
                local numIndices = 0
                local removeIndices = {} --[=[@type integer[]]=]

                for i, item in ipairs(cleanableList) do
                    if petItemIds[item.Prefab.Identifier] then
                        numIndices = numIndices + 1
                        removeIndices[numIndices] = i - 1
                    end
                end

                sort(removeIndices, function(i1, i2) return i1 > i2 end)

                for i in removeIndices do --[[@cast i integer]]
                    Item._cleanableItems.RemoveAt(i)
                end
            end)
        end)
        petItemIds = nil
    end
end

return Types.Module.new(activate, deactivate)