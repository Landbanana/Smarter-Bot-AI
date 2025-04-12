local SBAI = require("SBAI")
local util = require("SBAI.Shared.util")

local startTimeBetween = SBAI.Config.defaults.START_TIME_BETWEEN

---@type table<AIObjectiveIdle,{timer:number}>
local allInstanceData = setmetatable({}, {
    ---@param t table<AIObjectiveIdle,{timer:number}>
    ---@param k Barotrauma.AIObjectiveIdle
    __index = function(t, k)
        t[k] = {timer=startTimeBetween}
        return t[k]
    end,
    ---@param t table<AIObjectiveIdle,{timer:number}>
    ---@param k Barotrauma.AIObjectiveIdle
    ---@param v {timer:number}
    __newindex = function(t, k, v)
        if rawget(t, k) == nil then
            local function removeInstanceFunction()
                t[k] = nil
            end
            k.Deselected.add(removeInstanceFunction)
        end
        rawset(t, k, v)
    end
})

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

return function(namespace, options)
    local timeBetween = options["timeBetween"] --[[@type number]]
    local clothesSlotTypes = {InvSlotType.Head, InvSlotType.InnerClothes, InvSlotType.OuterClothes}
    
    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveIdle", "Act",
    ---@param instance Barotrauma.AIObjectiveIdle
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function(instance, ptable)
        local instanceData = allInstanceData[instance]
        local character = instance.character --[[@type Barotrauma.Character]]
        
        if instanceData.timer <= 0 then
            instanceData.timer = util.AddNoise(timeBetween, 0.1)
            
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
        else
            instanceData.timer = instanceData.timer - ptable["deltaTime"]
        end
    end, Hook.HookMethodType.Before)

    -- hopefully prevent any memory leaks
    Hook.Add("roundEnd", namespace(),
    function()
        util.ClearTable(allInstanceData)
    end)
end,
function()
    util.ClearTable(allInstanceData)
end