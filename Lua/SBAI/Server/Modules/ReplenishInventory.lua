local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveContainItem"], "Act")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.AIObjectiveIdle"], "subObjectives")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.AIObjectiveGoTo"], "subObjectives")

--LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Inventory"], "slots")

LuaUserData.RegisterType("Barotrauma.Items.Components.ItemContainer+SlotRestrictions")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.ItemContainer"], "slotRestrictions")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Inventory"], "slots")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.ItemInventory"], "slots")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CharacterInventory"], "slots")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Inventory"], "TrySwapping")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.ItemInventory"], "TrySwapping")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CharacterInventory"], "TrySwapping")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.AIObjectiveContainItem"], "getItemObjective")

LuaUserData.RegisterType("Barotrauma.AIObjectiveMoveItem")

local activateGenericItem

do
    local ActionType = ActionType
    local Identifier = Identifier
    local Prefabs = ItemPrefab.Prefabs

    local new = Types.Set.new
    local unpack = table.unpack
    local xGetItemTags = util.xGetItemTags
    local xGetStatusEffectTargetType = util.xGetStatusEffectTargetType
    local xGetStatusEffectTargets = util.xGetStatusEffectTargets
    local xPath2 = util.xPath2

    local targetActionTypes = new()
    
    targetActionTypes:Add(ActionType.OnUse)
    targetActionTypes:Add(ActionType.OnActive)
    targetActionTypes:Add(ActionType.OnWearing)
    
    ---@param prefab Barotrauma.ItemPrefab
    ---@param targetIds Types.Set<Barotrauma.Identifier>
    ---@param specificTargetTags Types.Set<Barotrauma.Identifier>
    ---@param targetTag Barotrauma.Identifier
    ---@return boolean
    local function isPrefabUtilizer(prefab, targetIds, specificTargetTags, targetTag)
        local isUtilizer = false
        local xElement = prefab.ConfigElement.Element
        local containedTags = new()
        local seSpecial = new()

        if prefab:SBAI_hasCategory("Wrecked") then return false end
        
        for contElement in xPath2(xElement, "//ItemContainer//Containable") do
            local attr = contElement.Attribute("blameequipperfordeath")

            if attr then
                for tag in xGetItemTags(contElement) do
                    if specificTargetTags[tag] then
                        return false
                    end
                end
            else
                for tag in xGetItemTags(contElement) do
                    if  tag == targetTag or
                        targetIds[tag] or
                        specificTargetTags[tag]
                    then
                        containedTags:Add(tag)
                        for seElement in xPath2(contElement, "//StatusEffect") do
                            seSpecial:Add(seElement)
                        end
                    end
                end
            end
        end
        if containedTags:IsEmpty() then return false end

        for seElement in xPath2(xElement, "//StatusEffect") do
            if xGetStatusEffectTargetType(seElement) == "Contained" then
                local utilizedTags = new()
                local seUtilizedTags = xGetStatusEffectTargets(seElement)

                if seSpecial[seElement] then
                    utilizedTags:Add(targetTag)
                elseif seUtilizedTags then
                    for tag in seUtilizedTags do
                        if  tag == targetTag or
                            targetIds[tag] or
                            specificTargetTags[tag]
                        then
                            utilizedTags:Add(tag)
                        end
                    end
                else
                    for riElement in xPath2(seElement, "//RequiredItem|//RequiredItems") do
                        for tag in xGetItemTags(riElement) do
                            if containedTags[tag] then
                                utilizedTags:Add(tag)
                            end
                        end
                    end
                end
                if not utilizedTags:IsEmpty() then
                    for exElement in xPath2(seElement, "//Explosion") do
                        return false
                    end

                    local attr = seElement.Attribute("Condition")
                    if attr then
                        if tonumber(attr.Value) < 0 then
                            isUtilizer = true
                        end
                    end
                end
            end
        end
        return isUtilizer
    end
    
    ---@type table<string,fun(self:Types.Module, options:table, targetIds:Types.Set<Barotrauma.Identifier>, specificTargetTags:Types.Set<Barotrauma.Identifier>, targetTag:Barotrauma.Identifier, rechargerTag:Barotrauma.Identifier):((table<Barotrauma.Identifier,Barotrauma.Identifier>|Types.Set<Barotrauma.Identifier>), number, number)>
    local sectionNameToActivate = {
        Ammunition=function(self, options, targetIds, specificTargetTags, targetTag, rechargerTag)
            local utilizerIds = {}

            for prefab in Prefabs do
                
                if not prefab:SBAI_hasCategory("Weapon") then goto continue end

                do
                    local xElement = prefab.ConfigElement.Element
                    local containedTags = new()

                    for contElement in xPath2(xElement, "//ItemContainer//Containable") do
                        
                        for tag in xGetItemTags(contElement) do
                            if specificTargetTags[tag] then
                                containedTags:Add(tag)
                            end
                        end
                    end
                    if containedTags:IsEmpty() then goto continue end

                    

                    local utilizedTags = new()
                    
                    for rwElement in xPath2(xElement, "//RangedWeapon") do
                        for riElement in xPath2(rwElement, "//RequiredItem|//RequiredItems") do
                            for tag in xGetItemTags(riElement) do
                                if containedTags[tag] then
                                    utilizedTags:Add(tag)
                                end
                            end
                        end
                    end
                    if utilizedTags:IsEmpty() then goto continue end

                    utilizerIds[prefab.Identifier] = utilizedTags
                end
                ::continue::
            end

            -- for id, utilizedTags in next, utilizerIds do
            --     print("--"..id.Value.."--")
            --     for utilizedId in next, utilizedTags do
            --         print(utilizedId)
            --     end
            -- end
            return utilizerIds, options["minimumCondition"], options["minimumEquippedCondition"]
        end,
        BatteryCells=function(self, options, targetIds, specificTargetTags, targetTag, rechargerTag)
            local utilizerIds = new()

            for prefab in Prefabs do
                if  not prefab:SBAI_hasCategory("Wrecked")
                    and not prefab:SBAI_hasTag(rechargerTag)
                    and isPrefabUtilizer(prefab, targetIds, specificTargetTags, targetTag)
                then
                    utilizerIds:Add(prefab.Identifier)
                end
            end

            -- for id in next, utilizerIds do
            --     print(id)
            -- end

            return utilizerIds, options["minimumCondition"], options["minimumEquippedCondition"]
        end,
        OxygenTanks=function(self, options, targetIds, specificTargetTags, targetTag, rechargerTag)
            local utilizerIds = new()

            for prefab in Prefabs do
                if  not prefab:SBAI_hasCategory("Wrecked")
                    and not prefab:SBAI_hasTag(rechargerTag)
                    and isPrefabUtilizer(prefab, targetIds, specificTargetTags, targetTag)
                then
                    utilizerIds:Add(prefab.Identifier)
                end
            end

            -- for id in next, utilizerIds do
            --     print(id)
            -- end
            
            return utilizerIds, options["minimumCondition"], options["minimumEquippedCondition"]
        end,
        WeldingFuel=function(self, options, targetIds, specificTargetTags, targetTag, rechargerTag)
            local utilizerIds = new()

            for prefab in Prefabs do
                if not prefab:SBAI_hasCategory("Wrecked") then
                    local id = prefab.Identifier

                    if isPrefabUtilizer(prefab, targetIds, specificTargetTags, targetTag) then
                        utilizerIds:Add(id)
                    end
                end
            end

            -- for id in next, utilizerIds do
            --     print(id)
            -- end

            return utilizerIds, options["minimumCondition"], options["minimumEquippedCondition"]
        end
    }

    local sectionNameToInfo = {
        ["Ammunition"]={Identifier("handheldammo")},
        ["BatteryCells"]={Identifier("loadable"), Identifier("batterycellrecharger")},
        ["OxygenTanks"]={Identifier("refillableoxygensource"), Identifier("oxygentankrefiller")},
        ["WeldingFuel"]={Identifier("weldingtoolfuel")}
    }

    local commonIds = new(Constants.ID_COMMON)

    ---@param self Types.Module
    function activateGenericItem(self, options, idMap)
        local sectionName = self:GetSection()

        -- print("----"..sectionName.."----")
        local targetTag, rechargerTag = unpack(sectionNameToInfo[sectionName])
        local targetIds = new()
        local specificTargetTags = new()

        for prefab in Prefabs do
            if prefab:SBAI_hasTag(targetTag) then
                targetIds:Add(prefab.Identifier)
                for tag in prefab.Tags do
                    if  not commonIds[tag] and
                        tag ~= targetTag
                    then
                        specificTargetTags:Add(tag)
                    end
                end
            end
        end

        local success, utilizerIds, minimumCondition, minimumEquippedCondition = self:DoOption(nil, sectionNameToActivate[sectionName], targetIds, specificTargetTags, targetTag, rechargerTag)

        if success then
            idMap[sectionName] = {
                targetTag=targetTag,
                rechargerTag=rechargerTag,
                targetIds=targetIds,
                specificTargetTags=specificTargetTags,
                utilizerIds=utilizerIds,
                minimumCondition=minimumCondition,
                minimumEquippedCondition=minimumEquippedCondition
            }
        end
    end
end

local sharedPatch

local allCharacterData
local getNextTarget
local objPredicateData

do
    local AIObjectiveCleanupItem = AIObjectiveCleanupItem
    local AIObjectiveContainItem = AIObjectiveContainItem
    local GOTO = Constants.ID_OBJECTIVE_BASE.GOTO
    local REPLENISH_CLEAN = Constants.ID_OBJECTIVE.REPLENISHCLEAN
    local REPLENISH = Constants.ID_OBJECTIVE.REPLENISH

    ---@param instance Barotrauma.AIObjectiveIdle|Barotrauma.AIObjectiveGoTo
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function sharedPatch(instance, ptable)
        local character = instance.character
        local submarine = character.Submarine

        if  instance.Identifier ~= GOTO and
            submarine and
            submarine.Info.IsPlayer
        then
            local characterData = allCharacterData:Get(character)
            
            if  characterData:Update(ptable["deltaTime"]) and
                not characterData.containItemObj and
                not characterData.cleanupItemObj and
                getNextTarget(characterData, character) and
                objPredicateData[instance.Identifier](instance, character)
            then
                local targetItem = characterData.targetItem --[[@type Barotrauma.Item]]
                local targetContainer = characterData.targetContainer --[[@type Barotrauma.Items.Components.ItemContainer]]
                local targetSlot = characterData.targetSlot --[[@type integer]]
                local curSection = characterData.curSection --[[@type table]]
                
                local targetTags = curSection.utilizerIds[targetContainer.Item.Prefab.Identifier]

                targetTags = next(targetTags == true and curSection.specificTargetTags or targetTags)
                
                local function constructor()
                    local objective = AIObjectiveContainItem(character, targetTags, targetContainer, instance.objectiveManager)

                    objective.Identifier = REPLENISH
                    
                    objective.AllowDangerousPressure = false
                    objective.AllowStealing = false
                    objective.AllowToFindDivingGear = false
                    --objective.ConditionLevel = 100.0
                    objective.Equip = false
                    --objective.MoveWholeStack = true
                    --objective.RemoveEmpty = true
                    objective.RemoveExistingWhenNecessary = true
                    objective.TargetSlot = targetSlot
                    --objective.ItemCount = math.max(1, targetContainer.GetMaxStackSize(targetSlot) - #targetContainer.Inventory.slots[targetSlot + 1].Items)

                    do
                        local slot = targetContainer.Inventory.slots[targetSlot + 1]
                        local maxStackSize = targetContainer.GetMaxStackSize(targetSlot)

                        function objective:AbortCondition()
                            return maxStackSize <= #slot.Items and
                                slot.Items[1].IsFullCondition and
                                characterData.replenishCleanObj == nil
                        end
                    end

                    -- if curSection.rechargerTag ~= nil then
                    --     objective.ConditionLevel = 100.0
                    -- else
                    --     objective.ConditionLevel = 15
                    -- end

                    local function cleanup()
                        return instance:SBAI_cleanupSubObj(objective, AIObjectiveContainItem, characterData, "containItemObj", "targetItem", "targetContainer", "targetSlot", "curSection")
                    end
                    objective.Completed.add(
                        function()
                            if targetItem then
                                local inventory = targetItem.ParentInventory

                                if  inventory == character.Inventory or
                                    inventory == nil
                                then
                                    
                                    local function constructor()
                                        local subObjective = AIObjectiveCleanupItem(targetItem, character, objective.objectiveManager)

                                        local function cleanup()
                                            return instance:SBAI_cleanupSubObj(subObjective, AIObjectiveCleanupItem, characterData, "replenishCleanObj")
                                        end

                                        subObjective.Completed.add(cleanup)
                                        subObjective.Abandoned.add(cleanup)

                                        return subObjective
                                    end
                                    instance:SBAI_tryAddSubObjective(characterData, "replenishCleanObj", REPLENISH_CLEAN, false, true, constructor)
                                end
                            end
                            return cleanup()
                        end
                    )
                    objective.Abandoned.add(cleanup)
                    -- function()
                    --     if targetItem then
                    --         local inventory = targetItem.ParentInventory

                    --         if  inventory == targetContainer.Inventory and
                    --             not targetItem.IsFullCondition
                    --         then
                    --             local subObjective = objective.getItemObjective
                                
                    --             if subObjective then
                    --                 local itemToContain = subObjective.TargetItem
                                    
                    --                 if itemToContain then
                    --                     inventory.TryPutItem(itemToContain, targetSlot, true, true, character, true, true)
                    --                 end
                    --             end
                    --         end
                    --     end
                    --     return cleanup()
                    -- end)
                    return objective
                end
                
                ptable.PreventExecution = instance:SBAI_tryAddSubObjective(characterData, "containItemObj", REPLENISH, true, false, constructor)
            end
        end
    end
end

local getTargetItem

do
    local ItemContainer = Components.ItemContainer

    local GetSpecificSlots = util.GetSpecificSlots

    ---@param fillEmpty boolean
    ---@param character Barotrauma.Character
    ---@param idMapData table
    function getTargetItem(fillEmpty, character, idMapData)
        local inventory =  character.Inventory
        local utilizerIds = idMapData.utilizerIds --[[@type Types.Set<Barotrauma.Identifier>]]
        local targetTags = idMapData.targetIds:Union(idMapData.specificTargetTags) --[[@type Types.Set<Barotrauma.Identifier>]]
        local minimumCondition = idMapData.minimumCondition --[[@type number]]
        local minimumEquippedCondition = idMapData.minimumEquippedCondition --[[@type number]]
        
        targetTags:Add(idMapData.targetTag)

        for container in inventory:SBAI_findAllItems(nil, true,
            function(container)
                return utilizerIds[container.Prefab.Identifier] ~= nil
            end) do
            local minCon = character.HasEquippedItem(container) and minimumEquippedCondition or minimumCondition
            local validSlots = GetSpecificSlots(container, targetTags)
            local itemContainer = container.GetComponent(ItemContainer) --[[@type Barotrauma.Items.Components.ItemContainer]]
            local contInventory = itemContainer.Inventory

            
            
            for s in validSlots do
                local curItem = container.OwnInventory.GetItemAt(s)
                local maxStack = itemContainer.GetMaxStackSize(s)

                if curItem then
                    if maxStack > 1 then
                        if #contInventory.slots[s + 1].Items / maxStack * 100 < minCon then
                            return curItem, itemContainer, s
                        end
                    end
                    if  curItem.ConditionPercentage < minCon then
                        return curItem, itemContainer, s
                    end
                elseif fillEmpty then
                    return nil, itemContainer, s
                end
            
            end
        end
        return nil, nil, -1
    end
end

---@param obj Barotrauma.AIObjectiveIdle|Barotrauma.AIObjectiveGoTo
---@param character Barotrauma.Character
---@return boolean
local function checkFriendlyOutpost(obj, character)
    return Level.IsLoadedFriendlyOutpost and
        character.IsOnPlayerTeam and
        not character.IsFriendlyNPCTurnedHostile
end

local activateGenericObj

do
    local IDLE = Constants.ID_OBJECTIVE_BASE.IDLE
    local REPLENISH = Constants.ID_OBJECTIVE.REPLENISH
    local REPLENISH_CLEAN = Constants.ID_OBJECTIVE.REPLENISHCLEAN

    local Partial1 = util.functools.Partial1

    ---@param self Types.Module
    ---@param options table
    ---@param idMap table
    ---@param timeBetween number
    ---@param forceSameItemType boolean
    ---@param forceGEQQuality boolean
    ---@param fillEmpty boolean
    function activateGenericObj(self, options, idMap, timeBetween, forceSameItemType, forceGEQQuality, fillEmpty)
        if not allCharacterData then
            objPredicateData = {}

            do
                local oldGetTargetItem = getTargetItem

                ---@type fun(character:Barotrauma.Character, idMapData:table):(Barotrauma.Item|nil, Barotrauma.Item.T|nil, integer)
                getTargetItem = Partial1(oldGetTargetItem, fillEmpty)
            end

            function getNextTarget(characterData, character)
                local sectionName, idMapData = next(idMap, characterData.lastSectionName)

                if sectionName == nil then
                    sectionName, idMapData = next(idMap)
                end

                characterData.lastSectionName = sectionName

                local targetItem, targetContainer, targetSlot = getTargetItem(character, idMapData)

                if targetContainer then
                    characterData.targetItem = targetItem
                    characterData.targetContainer = targetContainer
                    characterData.targetSlot = targetSlot
                    characterData.curSection = idMap[sectionName]
                    return true
                end
                return false
            end

            allCharacterData = Types.AllTimedCharacterData.new(self, timeBetween, nil, nil)
                -- ---@param characterData Types.CoTimedCharacterData
                -- local function(characterData)
                --     for sectionName, idMapData in next, idMap do
                --         local targetItem, targetContainer, targetSlot = getTargetItem(characterData.character, idMapData)

                --         if targetContainer then
                --             characterData.targetItem = targetItem
                --             characterData.targetContainer = targetContainer
                --             characterData.targetSlot = targetSlot
                --             characterData.curSection = idMap[sectionName]
                --             yield(true)
                --         else
                --             yield(false)
                --         end
                --     end
                --     yield(nil)
                -- end

            ---@param instance Barotrauma.AIObjectiveContainItem|Barotrauma.AIObjectiveGetItem
            ---@param ptable Barotrauma.LuaCsHook.ParameterTable
            ---@return boolean
            local function filterHelper(instance, ptable)
                if ptable.ReturnValue then
                    local item = ptable["item"] --[[@type Barotrauma.Item]]
                    local characterData = allCharacterData:Get(instance.character)
                    local targetItem = characterData.targetItem --[[@type Barotrauma.Item]]
                    
                    if  not targetItem or
                        (not forceSameItemType or
                        targetItem.Prefab.Identifier == item.Prefab.Identifier) and
                        (not forceGEQQuality or
                        targetItem.Quality <= item.Quality)
                    then
                        local container = item.Container
                        
                        if container ~= nil then
                            local curSection = characterData.curSection
                            local rechargerTag = curSection.rechargerTag

                            return not curSection.utilizerIds[container.Prefab.Identifier] and
                                (rechargerTag == nil or
                                (item.IsFullCondition and
                                container.HasTag(rechargerTag)))
                        end
                        return true
                    end
                end
                return false
            end

            do
                local AIObjectiveIdle = AIObjectiveIdle

                self:AddPatch("Barotrauma.AIObjectiveGetItem", "CheckItem", nil,
                function(instance, ptable)
                    local curSubObj = instance.objectiveManager.GetObjective(AIObjectiveIdle).CurrentSubObjective

                    if  curSubObj and
                        curSubObj.Identifier == REPLENISH
                    then
                        return filterHelper(instance, ptable)
                    end
                end, Hook.HookMethodType.After)
            end

            do
                self:AddPatch("Barotrauma.AIObjectiveContainItem", "CheckItem", nil,
                function(instance, ptable)
                    if instance.Identifier == REPLENISH then
                        return filterHelper(instance, ptable)
                    end
                end, Hook.HookMethodType.After)
            end

            do
                local AIObjectiveCleanupItem = AIObjectiveCleanupItem

                self:AddPatch("Barotrauma.AIObjectiveContainItem", "<Act>b__75_5", nil,
                function(instance, ptable)
                    if instance.Identifier == REPLENISH then
                        local itemToContain = instance.getItemObjective.TargetItem

                        if itemToContain then
                            local character = instance.character
                            local inventory = itemToContain.ParentInventory

                            if inventory == character.Inventory then
                                local utilizerInventory = instance.container.Inventory
                                local targetSlot = instance.TargetSlot
                                local targetSlotItem = utilizerInventory.slots[targetSlot + 1]
                                local targetItem = targetSlotItem.Items[1] --[[@type Barotrauma.Item]]
                                
                                if targetItem then
                                    if not targetItem.Combine(itemToContain, character) then
                                        if  targetItem.ConditionPercentage < itemToContain.ConditionPercentage or
                                            #targetSlotItem.Items < #inventory.slots[inventory.FindIndex(itemToContain) + 1].Items
                                        then
                                            if utilizerInventory.TrySwapping(targetSlot, itemToContain, character, true, true) then
                                                targetItem, itemToContain = itemToContain, targetItem
                                            end
                                        end
                                    end
                                end

                                if  itemToContain and
                                    not itemToContain.Removed
                                then
                                    local characterData = allCharacterData[character]

                                    local function constructor()
                                        local subObjective = AIObjectiveCleanupItem(itemToContain, character, instance.objectiveManager)

                                        local function cleanup()
                                            return instance:SBAI_cleanupSubObj(subObjective, AIObjectiveCleanupItem, characterData, "replenishCleanObj")
                                        end
                                        subObjective.Completed.add(cleanup)
                                        subObjective.Abandoned.add(cleanup)
                                        return subObjective
                                    end
                                    instance:SBAI_tryAddSubObjective(characterData, "replenishCleanObj", REPLENISH_CLEAN, false, false, constructor)
                                end
                            end
                        end
                    end
                end, Hook.HookMethodType.Before)
            end
        end

        local onlyAtFriendlyOutposts = options["onlyAtFriendlyOutposts"] --[[@type boolean]]
        local sectionName = self:GetSection():upper()

        do
            local ID = Constants.ID_OBJECTIVE_BASE[sectionName]
            local pred  --[[@type fun(instance:Barotrauma.AIObjectiveIdle|Barotrauma.AIObjectiveGoTo, character:Barotrauma.Character):boolean]]

            if ID == IDLE then
                if onlyAtFriendlyOutposts then
                    pred = checkFriendlyOutpost
                else
                    pred = util.True
                end
            else
                if onlyAtFriendlyOutposts then
                    ---@param instance Barotrauma.AIObjectiveIdle|Barotrauma.AIObjectiveGoTo
                    ---@param character Barotrauma.Character
                    ---@return boolean
                    function pred(instance, character)
                        return instance:SBAI_isAtWaitObjective() and
                            checkFriendlyOutpost(instance, character)
                    end
                else
                    ---@param instance Barotrauma.AIObjectiveIdle|Barotrauma.AIObjectiveGoTo
                    ---@param character Barotrauma.Character
                    ---@return boolean
                    function pred(instance, character)
                        return instance:SBAI_isAtWaitObjective()
                    end
                end
            end
            objPredicateData[ID]=pred
        end

        self:AddPatch(Constants.TYPE_OBJECTIVE_BASE[sectionName], "Act", nil, sharedPatch, Hook.HookMethodType.Before)
    end
end

local activate

do
    local IDLE = Constants.ID_OBJECTIVE_BASE.IDLE
    local REPLENISH = Constants.ID_OBJECTIVE.REPLENISH
    local WAIT = Constants.ID_OBJECTIVE_BASE.WAIT

    local Any = util.itertools.Any

    ---@param self Types.Module
    function activate(self)
        self:AddCommonModule("SBAI.Server.CommonModules.AIObjectiveExpansion")
        self:AddCommonModule("SBAI.Server.CommonModules.ItemPrefabExpansion")

        local idMap = {}
        local options = self.options

        self:DoOption("Ammunition", activateGenericItem, idMap)
        self:DoOption("BatteryCells", activateGenericItem, idMap)
        self:DoOption("OxygenTanks", activateGenericItem, idMap)
        self:DoOption("WeldingFuel", activateGenericItem, idMap)

        if Any(idMap) then
            self:AddCommonModule("SBAI.Server.CommonModules.AIObjectiveExpansion")
            self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")
            local ModObjProp = self:AddCommonModule("SBAI.Server.CommonModules.ModifyObjectiveProperties") --[[@type fun(propertyName:string, objId:Barotrauma.Identifier, subObjId:Barotrauma.Identifier, value:any)]]

            --ModObjProp("ConcurrentObjectives", IDLE, REPLENISH, true)
            --ModObjProp("ConcurrentObjectives", WAIT, REPLENISH, true)

            local timeBetween = options["timeBetween"]
            local fillEmpty = options["fillEmpty"]
            local forceSameItemType = options["forceSameItemType"]
            local forceQualityGEQ = options["forceQualityGEQ"]
            
            self:DoOption("Idle", activateGenericObj, idMap, timeBetween, forceSameItemType, forceQualityGEQ, fillEmpty)
            self:DoOption("Wait", activateGenericObj, idMap, timeBetween, forceSameItemType, forceQualityGEQ, fillEmpty)
        end
    end
end

return Types.Module.new(activate, deactivate)