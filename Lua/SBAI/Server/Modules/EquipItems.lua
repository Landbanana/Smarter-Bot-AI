local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

---@param self Types.Module
---@param option string
---@param timeBetween number
local function activateCrewLoadout(self, option, timeBetween)
    self:AddCommonModule("SBAI.Server.CommonModules.AIObjectiveExpansion")
    self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")

    local allLoadoutData = util.StringToLoadout(option)
    local allCharacterData = Types.AllTimedCharacterData.new(self, timeBetween)
    
    do
        local newAllLoadoutData = {} --[[@type table<Barotrauma.Identifier, Barotrauma.Identifier[]>]]

        for jobIdAndLoadoutData in allLoadoutData do
            local jobId, loadoutData = next(jobIdAndLoadoutData)

            newAllLoadoutData[jobId] = loadoutData
        end
        allLoadoutData = newAllLoadoutData
    end

    local checkInventory do
        local tryCreateGetItemObj do
            local AIObjectiveGetItem = AIObjectiveGetItem
            local GETITEM = Constants.ID_OBJECTIVE_BASE.GETITEM
            local None = InvSlotType.None

            local Partial5 = util.functools.Partial5

            ---@param character Barotrauma.Character
            ---@param characterData Types.TimedCharacterData
            ---@param curObj Barotrauma.AIObjectiveIdle
            ---@param itemId Barotrauma.Identifier
            ---@param targetInvSlotType Barotrauma.InvSlotType|integer
            ---@return boolean
            function tryCreateGetItemObj(character, characterData, curObj, itemId, targetInvSlotType)
                if itemId == Identifier.Empty then return false end
                local function constructor()
                    local getItemObj = AIObjectiveGetItem(character, itemId, curObj.objectiveManager, true, true)

                    getItemObj.AllowStealing = false
                    getItemObj.AllowDangerousPressure = false
                    getItemObj.AllowToFindDivingGear = false

                    if targetInvSlotType ~= None then
                        getItemObj.EquipSlotType = targetInvSlotType
                    end

                    local cleanup = Partial5(curObj.SBAI_cleanupSubObj, curObj, getItemObj, AIObjectiveGetItem, characterData, "getItemObj")

                    -- local function cleanup()
                    --     return curObj:SBAI_cleanupSubObj(getItemObj, AIObjectiveGetItem, characterData, "getItemObj")
                    -- end
                    
                    getItemObj.Abandoned.add(cleanup)
                    getItemObj.Completed.add(
                        function()
                            if targetInvSlotType ~= None then
                                character.Inventory.TryPutItem(getItemObj.TargetItem, character, {targetInvSlotType}, true, true)
                            end

                            return cleanup()
                        end
                    )
                    return getItemObj
                end
                return curObj:SBAI_tryAddSubObjective(characterData, "getItemObj", GETITEM, false, true, constructor)
            end
        end
            
        local ipairs = ipairs
        local yield = coroutine.yield

        local D_HUMAN_INV_N_ANY = Constants.D_HUMAN_INV_N_ANY
        local None = InvSlotType.None

        local limbSlots = {
            InvSlotType.LeftHand,
            InvSlotType.RightHand,
            InvSlotType.Bag,
            InvSlotType.OuterClothes,
            InvSlotType.InnerClothes,
            InvSlotType.Head,
            InvSlotType.Headset
        }

        ---@param loadoutData Iterable<Barotrauma.Identifier>
        ---@param character Barotrauma.Character
        ---@param characterData Types.TimedCharacterData
        ---@param curObj Barotrauma.AIObjectiveIdle
        function checkInventory(loadoutData, character, characterData, curObj)
            yield()
            local itemSlots = setmetatable({}, { --[[@type table<Barotrauma.Identifier, Barotrauma.InvSlotType|integer>]]
                __index = function(t, k)
                    local v = None

                    t[k] = v
                    return v
                end
            })
            
            for i, itemId in ipairs(loadoutData) do
                itemSlots[itemId] = itemSlots[itemId] + (limbSlots[i - D_HUMAN_INV_N_ANY] or None)
            end
            
            yield()
            for itemId in loadoutData do
                local invSlotType = itemSlots[itemId]
                local unspecifiedSlotType = invSlotType == None

                ---@param instance Barotrauma.CharacterInventory
                ---@param item Barotrauma.Item
                ---@return boolean
                local function p(instance, item)
                    return item.Prefab.Identifier == itemId and
                        (unspecifiedSlotType or
                        instance.IsInLimbSlot(item, invSlotType))
                end

                if not character.inventory:SBAI_hasAnyItem(unspecifiedSlotType, p) then
                    yield(tryCreateGetItemObj(character, characterData, curObj, itemId, invSlotType))
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