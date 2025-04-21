local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

local Wearable = Components.Wearable
local ValsContain = util.ValsContain

local function staticPredicate(character, item)
    return item.GetComponent(Wearable) == nil or
        item.HasTag("lightdiving") or
        item.HasTag("deepdiving") or
        ValsContain(character.HeldItems, item)
end

local function checkSlots(item, slotTypes)
    for slot in slotTypes do --[[@cast slot Barotrauma.InvSlotType]]
        if ValsContain(item.AllowedSlots, slot) then
            return true
        end
    end
    return false
end

---@param slotTypes InvSlotType[]
---@return fun(character?:Barotrauma.Character, item?:Barotrauma.Item):boolean
local function generateWearableArmorPredicate(slotTypes)
    ---@param character? Barotrauma.Character
    ---@param item? Barotrauma.Item
    ---@return boolean
    return function(character, item)
        return not staticPredicate(character, item) and checkSlots(item, slotTypes)
    end
end

---@param self Types.Module
local function activate(self)
    local clothesSlotTypes = {InvSlotType.Head, InvSlotType.InnerClothes, InvSlotType.OuterClothes}
    local characterData

    do
        local Timer = Types.Timer
        local timeBetween = self.options["timeBetween"]

        ---@type table<Barotrauma.Character,Types.Timer>
        characterData = setmetatable(self:RegisterTable("ROUND_END", "CHARACTER_DEATH"), {
            ---@param t table<Barotrauma.Character,Types.Timer>
            ---@param k Barotrauma.Character
            __index = function(t, k)
                t[k] = Timer.new(timeBetween)
                return t[k]
            end
        })
    end

    local FindItems = util.FindItems
    
    self:AddPatch("Barotrauma.AIObjectiveIdle", "Act", nil,
    function(instance, ptable)
        local character = instance.character --[[@type Barotrauma.Character]]
        
        if  character.IsHuman and
            characterData[character]:Update(ptable["deltaTime"])
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

            local wearables = FindItems(character, inventory.FindAllItems(nil, true), nil, nil, generateWearableArmorPredicate(filteredClothesSlotTypes))

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