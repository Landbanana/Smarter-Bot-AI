local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

---@param self Types.Module
local function activate(self)
    self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")

    local deepdivingId = Identifier("lightdiving")
    local lightdivingId = Identifier("deepdiving")
    local Wearable = Components.Wearable
    
    local Any = util.itertools.Any
    local Contains = util.itertools.Contains
    local HasFlag = util.mathtools.HasFlag
    local Partial1 = util.functools.Partial1

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

            for slotType in clothesSlotTypes do
                if not inventory.GetItemInLimbSlot(slotType) then
                    filteredClothesSlotTypes = filteredClothesSlotTypes + slotType
                end
            end

            if filteredClothesSlotTypes == 0 then return end

            ---@type fun(slot:Barotrauma.InvSlotType):boolean
            local testSlot = Partial1(HasFlag, filteredClothesSlotTypes)

            for item in inventory:SBAI_findAllItems(nil, true,
                function(item)
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

return Types.Module.new(activate)