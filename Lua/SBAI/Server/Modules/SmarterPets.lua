local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.RegisterType("Barotrauma.AITargetMemory")

LuaUserData.RegisterType("Barotrauma.PetBehavior+Food")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.PetBehavior"], "foods")

--LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.EnemyAIController"], "currentTargetMemory")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.EnemyAIController"], "currentTargetingParams")
--LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.EnemyAIController"], "GetTargetMemory")
--LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.EnemyAIController"], "SelectedAiTarget")

LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.ItemPrefab"], "PreferredContainers")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Item"], "_cleanableItems")

---@param self Types.Module
---@param options table
local function activateEatFoodInInventory(self, options)
    self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")
    
    local AIState = self:RegisterEnumTable("Barotrauma.AIState")

    local Eat = AIState.Eat
    -- local Follow = AIState.Follow
    -- local Protect = options["overrideProtectOwner"] and AIState.Protect or nil
    
    local Filter = util.itertools.FilterList
    local ToList = util.itertools.ToList
    
    local allPetData = Types.TimedCharacterData.new(self, options["timeBetween"])
    local foodItemTags = Types.Set.new()
    local checkState = Types.Set.new()
    
    checkState:Add(AIState.Idle)
    checkState:Add(AIState.Follow)
    if options["overrideProtectOwner"] then checkState:Add(AIState.Protect) end

    do
        local Any = util.itertools.Any
        local Contains = util.itertools.Contains
        local xPath = util.xPath

        ---@type table<Barotrauma.Identifier,boolean>
        local checkedTags = setmetatable({}, {
            __index=function(t, k)
                t[k] = Any(ItemPrefab.Prefabs,
                    ---@param prefab Barotrauma.ItemPrefab
                    function(prefab)
                        return Contains(prefab.Tags, k) or
                            prefab.Identifier == k
                    end)
                return t[k]
            end
        })

        for prefab in CharacterPrefab.Prefabs do
            local xElement = prefab.ConfigElement

            for petElement in Filter(xPath(xElement, "ai/petbehavior"),
                function(petElement)
                    return petElement.GetAttributeFloat("hungerincreaserate", 0.25) > 0.0
                end) do
                for eatElement in xPath(petElement, "eat") do --[[@cast eatElement Barotrauma.ContentXElement]]
                    local tag = eatElement.GetAttributeIdentifier("tag")

                    if checkedTags[tag] then
                        foodItemTags:Add(tag)
                    end
                end
            end
        end
    end

    ---@param pet Barotrauma.Character
    ---@param petbehavior Barotrauma.PetBehavior
    ---@return Barotrauma.Item?
    ---@return Barotrauma.CharacterParams.TargetParams?
    local function findFood(pet, petbehavior)
        local inventory = pet.Inventory

        if inventory then
            local bestItem = nil
            local bestTargetParams = nil
            local highestPriority = 0.0

            ---@type Barotrauma.PetBehavior.Food[]
            local foods = ToList(Filter(petbehavior.foods,
                function(food)
                    return foodItemTags[food.Tag] and
                        food.TargetParams
                end))

            if #foods <= 0 then goto done end

            for item in Filter(inventory.GetAllItems(false),
                function(item)
                    return item.AiTarget ~= nil
                end) do
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
                                    goto done
                                end
                            end
                        end
                    end
                end
            end
            ::done::
            return bestItem, bestTargetParams
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
            local eatTarget = petData["eatTarget"] --[[@type Barotrauma.Item]]

            if  eatTarget or
                petData.timer:UpdateClock()
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
                petData["eatTarget"] = eatTarget
            end
        end
    end, Hook.HookMethodType.After)
end

---@param self Types.Module
---@param options table
local function activateBotsPlayWhenIdle(self, options)
    self:AddCommonModule("SBAI.Server.CommonModules.AIObjectiveExpansion")
    local mod = self:AddCommonModule("SBAI.Server.CommonModules.ModifyObjectiveProperties")
    local ModMainObjProp = mod.ModMainObjProp --[[@type fun(mainObjId:Barotrauma.Identifier, mainObjSuffix:string, subObjId:Barotrauma.Identifier, propertyName:string, value:any)]]

    local Character = Character
    local idleObjId = Identifier("idle")
    local PET_PLAY = Constants.ID_ORDER.PET_PLAY
    local Sad = self:RegisterEnumTable("Barotrauma.PetBehavior+StatusIndicatorType").Sad --[[@type Barotrauma.PetBehavior.StatusIndicatorType]]

    local Filter = util.itertools.FilterList
    local GetClosest = util.GetClosest
    local ToList = util.itertools.ToList

    local allCharacterData = Types.TimedCharacterData.new(self, options["timeBetween"])

    self:AddPatch("Barotrauma.AIObjectiveIdle", "Act", nil,
    function(instance, ptable)
        local character = instance.character
        local characterData = allCharacterData:Get(character)

        if  characterData.timer:Update(ptable["deltaTime"])
            and not characterData["petplayObj"]
        then
            local submarine = character.Submarine
            
            ---@type Barotrauma.Character
            local closestSadPet = GetClosest(character.WorldPosition, ToList(Filter(Character.CharacterList,
                function(pet)
                    return pet.IsPet and
                        pet.AIController.PetBehavior.GetCurrentStatusIndicatorType() == Sad and
                        submarine == pet.Submarine and
                        character.IsOnFriendlyTeam(pet) and
                        character.CanSeeTarget(pet, nil, true, false)
                end)))

            if closestSadPet then
                local function constructor()
                    local objective = AIObjectiveGoTo(closestSadPet, character, character.AIController.ObjectiveManager, false, false, 1, 50.0)
                    
                    objective.AllowGoingOutside = false
                    objective.DebugLogWhenFails = false
                    objective.IgnoreIfTargetDead = true
                    objective.SpeakIfFails = false

                    local petbehavior = closestSadPet.AIController.PetBehavior --[[@type Barotrauma.PetBehavior]]
                    local unhappyThreshold = petbehavior.UnhappyThreshold

                    function objective.AbortCondition()
                        return petbehavior.Happiness > unhappyThreshold
                    end

                    objective.Completed.add(
                    function()
                        closestSadPet.AIController.PetBehavior.Play(character)
                        return instance:SBAI_cleanupSubObj(objective, AIObjectiveGoTo, characterData, "petplayObj")
                    end)
                    objective.Abandoned.add(function() return instance:SBAI_cleanupSubObj(objective, AIObjectiveGoTo, characterData, "petplayObj") end)
                    return objective
                end

                ptable.PreventExecution = instance:SBAI_tryAddSubObjective(characterData, "petplayObj", PET_PLAY, true, true, constructor)
            end
        end
    end, Hook.HookMethodType.Before)

    ModMainObjProp(IDLE, "Idle", PET_PLAY, "ConcurrentObjectives", true)
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
        for xSubElement in xPath(prefab.ConfigElement, "ai/petbehavior/itemproduction/item") do --[[@cast xSubElement Barotrauma.ContentXElement]]
            if xSubElement then
                local itemId = xSubElement.GetAttributeIdentifier("identifier")

                if itemId.Value ~= "" then
                    petItemIds:Add(itemId)
                end
            end
        end
    end

    for id in next, petItemIds do
        local prefab = GetItemPrefab(id)

        if prefab then
            local xElement = prefab.ConfigElement

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

        for id in next, petItemIds do
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
                Item._cleanableItems.Add(item)
            end
        end
    end)
end

---@param self Types.Module
local function activate(self)
    self:DoOption("EatFoodInInventory", activateEatFoodInInventory)
    self:DoOption("BotsPlayWhenIdle", activateBotsPlayWhenIdle)
    self:DoOption("CleanableProduce", activateCleanableProduce)

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
            for id in next, petItemIds do
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