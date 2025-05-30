local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

---@param self Types.Module
local function activate(self)
    self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")

    local deepdivingId = Identifier("lightdiving")
    local lightdivingId = Identifier("deepdiving")
    local Wearable = Components.Wearable
    
    local Any = util.itertools.Any
    local FilterList = util.itertools.FilterList
    local HasFlag = util.mathtools.HasFlag
    local Contains = util.itertools.Contains

    local clothesSlotTypes = {InvSlotType.Head, InvSlotType.InnerClothes, InvSlotType.OuterClothes, InvSlotType.Headset}
    local allCharacterData = Types.AllTimedCharacterData.new(self)

    self:AddPatch("Barotrauma.AIObjectiveIdle", "Act", nil,
    function(instance, ptable)
        local character = instance.character --[[@type Barotrauma.Character]]
        
        if  character.IsHuman and
            allCharacterData:Get(character):Update(ptable["deltaTime"])
        then
            local inventory = character.Inventory --[[@type Barotrauma.CharacterInventory]]
            local filteredClothesSlotTypes = 0

            for slotType in FilterList(clothesSlotTypes, function(slotType) return not inventory.GetItemInLimbSlot(slotType) end) do
                filteredClothesSlotTypes = filteredClothesSlotTypes + slotType
            end

            if filteredClothesSlotTypes == 0 then return end

            ---@param slot Barotrauma.InvSlotType
            ---@return boolean
            local function testSlot(slot)
                return HasFlag(filteredClothesSlotTypes, slot)
            end

            for item in inventory:SBAI_findAllItems(nil, true,
                function(item)
                    return item.GetComponent(Wearable) ~= nil and
                        not item.HasTag(lightdivingId) and
                        not item.HasTag(deepdivingId) and
                        not Contains(character.HeldItems, item) and
                        Any(item.AllowedSlots, testSlot)
                end) do
                for v in FilterList(item.AllowedSlots, testSlot) do
                    if inventory.TryPutItem(item, character, {v}, true, true) then
                        return character.OnWearablesChanged()
                    end
                end
            end
        end
    end, Hook.HookMethodType.Before)
end

return Types.Module.new(activate)