local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

---@param self Types.Module
local function activate(self)
    local deepdivingId = Identifier("lightdiving")
    local lightdivingId = Identifier("deepdiving")
    local Wearable = Components.Wearable
        
    local Any = util.itertools.Any
    local band = bit32.band
    local FindItems = util.FindItems
    local Contains = util.itertools.Contains

    local clothesSlotTypes = {InvSlotType.Head, InvSlotType.InnerClothes, InvSlotType.OuterClothes}
    local allCharacterData = Types.TimedCharacterData.new(self)

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

            ---@param slot Barotrauma.InvSlotType
            ---@return boolean
            local function testSlot(slot)
                return band(filteredClothesSlotTypes, slot) == slot
            end
            
            local wearables = FindItems(character, inventory.FindAllItems(nil, true), nil, nil,
            function(character, item)
                return item.GetComponent(Wearable) ~= nil and
                    not item.HasTag(lightdivingId) and
                    not item.HasTag(deepdivingId) and
                    not Contains(character.HeldItems, item) and
                    Any(item.AllowedSlots, testSlot)
            end)

            for item in wearables do --[[@cast item Barotrauma.Item]]
                for v in item.AllowedSlots do
                    if testSlot(v) then
                        if inventory.TryPutItem(item, character, {v}, true, true) then
                            return character.OnWearablesChanged()
                        end
                    end
                end
            end
        end
    end, Hook.HookMethodType.Before)
end

return Types.Module.new(activate)