local SBAI = require("SBAI")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

---@param slotTypes InvSlotType[]
---@return fun(character?:Barotrauma.Character, item?:Barotrauma.Item):boolean
local function GenerateWearableArmorPredicate(slotTypes)
    ---@param character? Barotrauma.Character
    ---@param item? Barotrauma.Item
    ---@return boolean
    return function(character, item)
        local wearable = item.GetComponent(Components.Wearable)
        
        if  wearable == nil or
            item.HasTag("lightdiving") or
            item.HasTag("deepdiving")
        then
            return false
        end

        for slot in slotTypes do
            if util.ValsContain(item.AllowedSlots, slot) then
                return true
            end
        end
        return false
    end
end

---@param namespace Namespace
---@param options table
return function(namespace, options)
    local clothesSlotTypes = {InvSlotType.Head, InvSlotType.InnerClothes, InvSlotType.OuterClothes}

    ---@type table<Barotrauma.Character,Types.Timer>
    local characterData = setmetatable(util.RoundEndTemp:Add(namespace()), {
        ---@param t table<Barotrauma.Character,Types.Timer>
        ---@param k Barotrauma.Character
        __index = function(t, k)
            t[k] = Types.Timer:new(options["timeBetween"])
            return t[k]
        end
    })

    util.ClearTableKeyOnCharacterDeath(characterData, namespace(), SBAI.Hook.Add)
    
    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveIdle", "Act",
    ---@param instance Barotrauma.AIObjectiveIdle
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function(instance, ptable)
        local character = instance.character --[[@type Barotrauma.Character]]
        
        if characterData[character]:Update(ptable["deltaTime"]) then
            local inventory = character.Inventory --[[@type Barotrauma.CharacterInventory]]
            local filteredClothesSlotTypes = {} --[=[@type Barotrauma.InvSlotType[]]=]

            for slotType in clothesSlotTypes do --[[@cast slotType Barotrauma.InvSlotType]]
                if inventory.GetItemInLimbSlot(slotType) == nil then
                    table.insert(filteredClothesSlotTypes, slotType)
                end
            end
            
            if #filteredClothesSlotTypes <= 0 then return end

            local wearables = util.FindItems(character, inventory.FindAllItems(nil, true), nil, nil, GenerateWearableArmorPredicate(filteredClothesSlotTypes))
            
            for _, slotType in ipairs(filteredClothesSlotTypes) do
                for _, item in ipairs(wearables) do
                    if inventory.TryPutItem(item, character, {slotType}, true, true) then
                        break
                    end
                end
            end
        end
    end, Hook.HookMethodType.Before)
end