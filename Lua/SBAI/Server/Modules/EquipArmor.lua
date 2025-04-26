local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

local wearableArmorPredicate --[[@type fun(slotTypes:Barotrauma.InvSlotType, character:Barotrauma.Character, item:Barotrauma.Item):boolean]]

do
    local Wearable = Components.Wearable

    local Contains = util.itertools.Contains
    
    ---@param slotTypes Barotrauma.InvSlotType[]
    ---@param character Barotrauma.Character
    ---@param item Barotrauma.Item
    ---@return boolean
    function wearableArmorPredicate(slotTypes, character, item)
        if  item.GetComponent(Wearable) or
            not item.HasTag("lightdiving") or
            not item.HasTag("deepdiving") or
            not Contains(character.HeldItems, item)
        then
            for slot in slotTypes do --[[@cast slot Barotrauma.InvSlotType]]
                if Contains(item.AllowedSlots, slot) then
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

    local FindItems = util.FindItems
    local Partial1 = util.functools.Partial1

    self:AddPatch("Barotrauma.AIObjectiveIdle", "Act", nil,
    function(instance, ptable)
        local character = instance.character --[[@type Barotrauma.Character]]
        
        if  character.IsHuman and
            allCharacterData:Get(character).timer:Update(ptable["deltaTime"])
        then
            local inventory = character.Inventory --[[@type Barotrauma.CharacterInventory]]
            local filteredClothesSlotTypes = {} --[=[@type Barotrauma.InvSlotType[]]=]

            do
                local i = 0

                for slotType in clothesSlotTypes do --[[@cast slotType Barotrauma.InvSlotType]]
                    if not inventory.GetItemInLimbSlot(slotType) then
                        i = i + 1
                        filteredClothesSlotTypes[i] = slotType
                    end
                end

                if i <= 0 then return end
            end
            
            local wearables = FindItems(character, inventory.FindAllItems(nil, true), nil, nil, Partial1(wearableArmorPredicate, filteredClothesSlotTypes))

            for slotType in filteredClothesSlotTypes do --[[@cast slotType Barotrauma.InvSlotType]]
                for item in wearables do --[[@cast item Barotrauma.Item]]
                    if inventory.TryPutItem(item, character, {slotType}, true, true) then
                        break
                    end
                end
            end
        end
    end, Hook.HookMethodType.Before)
end

return Types.Module.new(activate)