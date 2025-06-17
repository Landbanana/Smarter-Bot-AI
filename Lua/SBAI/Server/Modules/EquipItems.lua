local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

---@param self Types.Module
---@param option string
---@param timeBetween number
local function activateCrewLoadout(self, option, timeBetween)
    self:AddCommonModule("SBAI.Server.CommonModules.AIObjectiveExpansion")
    self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")
    self:AddCommonModule("SBAI.Server.CommonModules.ItemExpansion")
    self:AddCommonModule("SBAI.Server.CommonModules.ItemPrefabExpansion")

    local allLoadoutData = util.StringToAllLoadout(option, true)
    local allCharacterData = Types.AllTimedCharacterData.new(self, timeBetween)

    local checkInventory do
        local tryCreateGetItemObj do
            local AIObjectiveGetItem = AIObjectiveGetItem
            local GETITEM = Constants.ID_OBJECTIVE_BASE.GETITEM
            local None = InvSlotType.None

            local Partial6 = util.functools.Partial6

            ---@param character Barotrauma.Character
            ---@param characterData Types.TimedCharacterData
            ---@param curObj Barotrauma.AIObjectiveIdle
            ---@param itemId Iterable<Barotrauma.Identifier>
            ---@param slotData Set<Barotrauma.InvSlotType|integer>
            ---@param targetQuality integer
            ---@return boolean
            function tryCreateGetItemObj(character, characterData, curObj, itemId, slotData, targetQuality)
                local function constructor()
                    local getItemObj = AIObjectiveGetItem(character, itemId, curObj.objectiveManager, true, true)

                    getItemObj.AllowStealing = false
                    getItemObj.AllowDangerousPressure = false
                    getItemObj.AllowToFindDivingGear = false

                    -- if targetInvSlotType ~= None then
                    --     getItemObj.EquipSlotType = targetInvSlotType
                    -- end

                    characterData.targetQuality = targetQuality

                    local cleanup = Partial6(curObj.SBAI_cleanupSubObj, curObj, getItemObj, AIObjectiveGetItem, characterData, "getItemObj", "targetQuality")

                    -- local function cleanup()
                    --     return curObj:SBAI_cleanupSubObj(getItemObj, AIObjectiveGetItem, characterData, "getItemObj")
                    -- end
                    
                    getItemObj.Abandoned.add(cleanup)
                    getItemObj.Completed.add(
                    function()
                        local newItem = getItemObj.TargetItem
                        local inventory = character.Inventory

                        if not inventory.TryPutItem(newItem, character, slotData:ToList(), true, true) then
                            for slotType in slotData do
                                local presentItem = character.GetEquippedItem(nil, slotType)
                                
                                if  presentItem and
                                    presentItem ~= newItem
                                then
                                    character.Unequip(presentItem)
                                    if character.GetEquippedItem(nil, slotType) ~= newItem then
                                        presentItem.Drop(character, true)
                                        presentItem:SBAI_cleanup(character)
                                    end
                                end
                                if inventory.TryPutItem(newItem, character, {slotType}, true, true) then
                                    break
                                end
                            end
                        end
                        return cleanup()
                    end)
                    return getItemObj
                end
                return curObj:SBAI_tryAddSubObjective(characterData, "getItemObj", GETITEM, false, true, constructor)
            end
        end
        
        local CreateBuilder = util.itertools.CreateBuilder
        local ipairs = ipairs
        local new = Types.Set.new
        local next = next
        local setmetatable = setmetatable
        local type = type
        local yield = coroutine.yield

        local Any = InvSlotType.Any
        local D_CREW_LOADOUT_SLOTS = Constants.D_CREW_LOADOUT_SLOTS
        local D_HUMAN_INV_N_ANY = Constants.D_HUMAN_INV_N_ANY
        local D_HUMAN_INV_N = Constants.D_HUMAN_INV_N
        local None = InvSlotType.None
        local Normal = Constants.Quality.Normal

        local limbSlots = {}

        for i=1,D_HUMAN_INV_N - D_HUMAN_INV_N_ANY,1 do
            limbSlots[i] = D_CREW_LOADOUT_SLOTS[i + D_HUMAN_INV_N_ANY]
        end

        local itemSlot_mt = {
            __index=function(t, k)
                local set = new()

                t[k] = set
                return set
            end
        }

        ---@param loadoutData Iterable<ItemData>
        ---@param character Barotrauma.Character
        ---@param characterData Types.TimedCharacterData
        ---@param curObj Barotrauma.AIObjectiveIdle
        function checkInventory(loadoutData, character, characterData, curObj)
            yield()
            -- local itemSlots = setmetatable({}, { --[[@type table<ItemData, Barotrauma.InvSlotType|integer>]]
            --     __index = function(t, k)
            --         local v = None

            --         t[k] = v
            --         return v
            --     end
            -- })
            
            -- for i, itemData in ipairs(loadoutData) do
            --     itemSlots[itemData] = itemSlots[itemData] + (limbSlots[i - D_HUMAN_INV_N_ANY] or None)
            -- end

            local itemSlots = setmetatable({}, itemSlot_mt) --[[@type table<ItemData, Set<Barotrauma.InvSlotType|integer>>]]

            for i, itemData in ipairs(loadoutData) do
                if  itemData.itemPrefab or
                    itemData.itemIds
                then
                    itemSlots[itemData]:Add(D_CREW_LOADOUT_SLOTS[i])
                end
            end

            yield()
            do
                local checkedPrefabs = new()

                for itemData in loadoutData do
                    local itemPrefab = itemData.itemPrefab

                    if itemPrefab and
                        not checkedPrefabs[itemPrefab]
                    then
                        local slotData = itemSlots[itemData]
                        local reg, comp = itemPrefab:SBAI_getInvSlots()
                        local slotDataCombos = new()
                        local comboMatches

                        checkedPrefabs:Add(itemPrefab)

                        for comboType, slotTypes in next, comp do
                            comboMatches = true

                            for slotType in slotTypes do
                                if not slotData[slotType] then
                                    comboMatches = false
                                    break
                                end
                            end
                            if comboMatches then
                                slotDataCombos:Add(comboMatches)
                            end
                        end
                        slotData:Update(slotDataCombos)
                    end
                end
            end
            
            yield()
            for itemData in loadoutData do
                local idOrTags do
                    local itemPrefab = itemData.itemPrefab
                    local itemIds = itemData.itemIds

                    if itemPrefab then
                        idOrTags = {itemPrefab.Identifier}
                    elseif itemIds then
                        local builder

                        idOrTags, builder = CreateBuilder()

                        for id, v in next, itemIds do
                            if v then builder(id) end
                        end
                    end
                end

                if idOrTags then
                    local slotData = itemSlots[itemData]
                    local quality = itemData.minQuality or Normal

                    ---@param inventory Barotrauma.CharacterInventory
                    ---@param item Barotrauma.Item
                    ---@return boolean
                    local function p(inventory, item)
                        if  item.HasIdentifierOrTags(idOrTags) and
                            quality <= item.Quality
                        then
                            for slotType in slotData do
                                if inventory.IsInLimbSlot(item, slotType) then
                                    return true
                                end
                            end
                        end
                        return false
                    end

                    if not character.Inventory:SBAI_hasAnyItem(slotData[Any], p) then
                        yield(tryCreateGetItemObj(character, characterData, curObj, idOrTags, slotData, quality))
                    end
                end
            end
            --characterData.coOngoing = nil
        end
    end
        
    local pwrap = util.cotools.pwrap

    self:AddPatch("Barotrauma.AIObjectiveIdle", "Act", nil,
    function(instance, ptable)
        local character = instance.character
        
        if  character.IsOnPlayerTeam and
            character.IsInFriendlySub
        then
            local loadoutData = allLoadoutData[character.JobIdentifier]

            if loadoutData then
                local characterData = allCharacterData:Get(character)
                local coOngoing = characterData.coOngoing --[[@type (fun())?]]
                
                if coOngoing then
                    coOngoing()
                elseif characterData:Update(ptable["deltaTime"]) and
                    not characterData.getItemObj
                then
                    instance.Deselected.add(
                    function()
                        characterData.coOngoing = nil
                    end)
                    coOngoing = pwrap(checkInventory, characterData, "coOngoing")
                    coOngoing(loadoutData, character, characterData, instance)
                end
            end
        end
    end, Hook.HookMethodType.Before)

    self:AddPatch("Barotrauma.AIObjectiveGetItem", "CheckItem", nil,
    function(instance, ptable)
        if ptable.ReturnValue == true then
            local characterData = allCharacterData[instance.character]
            
            if characterData then
                local targetQuality = characterData.targetQuality

                ptable.ReturnValue = targetQuality == nil or targetQuality <= ptable["item"].Quality
            end
        end
    end, Hook.HookMethodType.After)
end

---@param self Types.Module
---@param options table
---@param timeBetween number
local function activateReEquipArmor(self, options, timeBetween)
    self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")

    local deepdivingId = Identifier("lightdiving")
    local lightdivingId = Identifier("deepdiving")
    local Wearable = Components.Wearable
    
    local Any = util.itertools.Any
    local Contains = util.itertools.Contains
    local HasFlag = util.mathtools.HasFlag
    local Partial1 = util.functools.Partial1

    local clothesSlotTypes = {InvSlotType.Head, InvSlotType.InnerClothes, InvSlotType.OuterClothes, InvSlotType.Headset}
    local allCharacterData = Types.AllTimedCharacterData.new(self, timeBetween)

    self:AddPatch("Barotrauma.AIObjectiveIdle", "Act", nil,
    function(instance, ptable)
        
        local character = instance.character --[[@type Barotrauma.Character]]
        
        if  allCharacterData:Get(character):Update(ptable["deltaTime"]) then
            local inventory = character.Inventory --[[@type Barotrauma.CharacterInventory]]
            local filteredClothesSlotTypes = 0

            for slotType in clothesSlotTypes do
                if not inventory.GetItemInLimbSlot(slotType) then
                    filteredClothesSlotTypes = filteredClothesSlotTypes + slotType
                end
            end

            if filteredClothesSlotTypes == 0 then return end

            ---@type fun(slot:Barotrauma.InvSlotType):boolean
            local testSlot = Partial1(HasFlag, filteredClothesSlotTypes)

            for item in inventory:SBAI_findAllItems(nil, true,
                function(inventroy, item)
                    return item.GetComponent(Wearable) ~= nil and
                        not item.HasTag(lightdivingId) and
                        not item.HasTag(deepdivingId) and
                        not Contains(character.HeldItems, item) and
                        Any(item.AllowedSlots, testSlot)
                end) do
                for slot in item.AllowedSlots do
                    if  testSlot(slot) and
                        inventory.TryPutItem(item, character, {slot}, true, true)
                    then
                        return character.OnWearablesChanged()
                    end
                end
            end
        end
    end, Hook.HookMethodType.Before)
end

---@param self Types.Module
local function activate(self)
    local options = self.options
    local timeBetween = options["timeBetween"]

    self:DoOption("CrewLoadout", activateCrewLoadout, timeBetween)
    self:DoOption("reEquipArmor", activateReEquipArmor, timeBetween)
end

return Types.Module.new(activate)