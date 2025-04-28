local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

local wearableArmorPredicate --[[@type fun(slotTypes:integer, character:Barotrauma.Character, item:Barotrauma.Item):boolean]]

do
    local deepdivingId = Identifier("lightdiving")
    local lightdivingId = Identifier("deepdiving")
    local Wearable = Components.Wearable

    local band = bit32.band
    local Contains = util.itertools.Contains
    
    ---@param slotTypes integer
    ---@param character Barotrauma.Character
    ---@param item Barotrauma.Item
    ---@return boolean
    function wearableArmorPredicate(slotTypes, character, item)
        if  item.GetComponent(Wearable) or
            not item.HasTag(lightdivingId) or
            not item.HasTag(deepdivingId) or
            not Contains(character.HeldItems, item)
        then
            for v in item.AllowedSlots do
                if band(slotTypes, v) == v then
                    return true
                end
            end
        end
        return false
    end
end

---@param self Types.Module
local function activate(self)
    local clothesSlotTypes = {InvSlotType.Head, InvSlotType.InnerClothes, InvSlotType.OuterClothes}
    local allCharacterData = Types.TimedCharacterData.new(self)

    local band = bit32.band
    local FindItems = util.FindItems
    local Partial1 = util.functools.Partial1

    self:AddPatch("Barotrauma.AIObjectiveIdle", "Act", nil,
    function(instance, ptable)
        local character = instance.character --[[@type Barotrauma.Character]]
        
        if  character.IsHuman and
            allCharacterData:Get(character).timer:Update(ptable["deltaTime"])
        then
            local inventory = character.Inventory --[[@type Barotrauma.CharacterInventory]]
            local filteredClothesSlotTypes = 0

            for slotType in clothesSlotTypes do --[[@cast slotType Barotrauma.InvSlotType]]
                if not inventory.GetItemInLimbSlot(slotType) then
                    filteredClothesSlotTypes = filteredClothesSlotTypes + slotType
                end
            end

            if filteredClothesSlotTypes == 0 then return end
            
            local wearables = FindItems(character, inventory.GetAllItems(true), nil, nil, Partial1(wearableArmorPredicate, filteredClothesSlotTypes))

            for item in wearables do --[[@cast item Barotrauma.Item]]
                for v in item.AllowedSlots do
                    if band(filteredClothesSlotTypes, v) == v then
                        if inventory.TryPutItem(item, character, {v}, true, true) then return end
                    end
                end
            end
        end
    end, Hook.HookMethodType.Before)
end

return Types.Module.new(activate)