local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

-- Force Equip Module
-- When a character receives a Force Equip order, they will go pick up the target item
-- and equip it permanently (won't unequip it until the player manually removes it)

local FORCEEQUIP = Constants.ID_ORDER.FORCEEQUIP
local orderCategoryPrefix = Constants.ID_ORDER.SBAICATEGORY.Value.."_"

-- Table to track items that should not be unequipped
-- Key: Character, Value: Set of Items that are force-equipped
local forceEquippedItems = nil --[[@type table<Barotrauma.Character, Set<Barotrauma.Item>>]]

-- Table to track which items characters should pick up
local pendingForceEquip = nil --[[@type table<Barotrauma.Character, Barotrauma.Item>]]

---@param self Types.Module
local function activate(self)
    self:AddCommonModule("SBAI.Server.CommonModules.AIObjectiveExpansion")
    self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")

    -- Initialize the force-equipped items tracking table
    forceEquippedItems = self:RegisterTable(nil, "ROUND_END") --[[@type table<Barotrauma.Character, Set<Barotrauma.Item>>]]
    pendingForceEquip = self:RegisterTable(nil, "ROUND_END") --[[@type table<Barotrauma.Character, Barotrauma.Item>]]

    local new = Types.Set.new
    local AIObjectiveGoTo = AIObjectiveGoTo
    local Wearable = Components.Wearable
    local Holdable = Components.Holdable

    -- Helper function to get or create the force-equipped set for a character
    ---@param character Barotrauma.Character
    ---@return Set<Barotrauma.Item>
    local function getForceEquippedSet(character)
        local set = forceEquippedItems[character]
        if not set then
            set = new()
            forceEquippedItems[character] = set
        end
        return set
    end

    -- Helper function to find the best slot for an item
    ---@param item Barotrauma.Item
    ---@param character Barotrauma.Character
    ---@return boolean
    local function tryEquipItem(item, character)
        local inventory = character.Inventory
        
        -- Try to equip in allowed slots
        for slot in item.AllowedSlots do
            if inventory.TryPutItem(item, character, {slot}, true, true) then
                return true
            end
        end
        
        -- Fallback: try any slot
        if inventory.TryPutItem(item, character, nil, true, true) then
            return true
        end
        
        return false
    end

    -- Patch to create the objective when a Force Equip order is received
    self:AddPatch("Barotrauma.AIObjectiveManager", "CreateObjective", nil,
    function(instance, ptable)
        local order = ptable["order"] --[[@type Barotrauma.Order]]
        
        if order.Identifier == FORCEEQUIP then
            local targetItem = order.TargetEntity --[[@type Barotrauma.Item]]
            local character = instance.character --[[@type Barotrauma.Character]]
            
            if not targetItem or not character then
                return nil
            end
            
            ptable.PreventExecution = true
            
            -- Store the pending item
            pendingForceEquip[character] = targetItem
            
            -- Create a GoTo objective to go to the item's location
            local goToObj = AIObjectiveGoTo(targetItem, character, instance, false, false, 100)
            
            if goToObj then
                goToObj.Identifier = FORCEEQUIP
                
                -- When the character arrives, pick up and equip the item
                goToObj.Completed.add(function()
                    local itemToEquip = pendingForceEquip[character]
                    pendingForceEquip[character] = nil
                    
                    if itemToEquip and itemToEquip.body then
                        -- Pick up the item
                        if character.CanInteractWith(itemToEquip, false, true) then
                            if tryEquipItem(itemToEquip, character) then
                                local forceSet = getForceEquippedSet(character)
                                forceSet:Add(itemToEquip)
                            end
                        end
                    end
                end)
                
                goToObj.Abandoned.add(function()
                    pendingForceEquip[character] = nil
                end)
            end
            
            return goToObj
        end
    end, Hook.HookMethodType.Before)

    -- Patch to prevent unequipping force-equipped items by bots
    self:AddPatch("Barotrauma.Character", "Unequip", nil,
    function(instance, ptable)
        local item = ptable["item"] --[[@type Barotrauma.Item]]
        
        if item and instance.IsBot then
            local forceSet = forceEquippedItems[instance]
            if forceSet and forceSet[item] then
                -- Prevent unequipping force-equipped items
                ptable.PreventExecution = true
                return false
            end
        end
    end, Hook.HookMethodType.Before)

    -- Patch to prevent dropping force-equipped items by bots
    self:AddPatch("Barotrauma.Item", "Drop", nil,
    function(instance, ptable)
        local dropper = ptable["dropper"] --[[@type Barotrauma.Character]]
        
        if dropper and dropper.IsBot then
            local forceSet = forceEquippedItems[dropper]
            if forceSet and forceSet[instance] then
                -- Prevent dropping force-equipped items
                ptable.PreventExecution = true
                return
            end
        end
    end, Hook.HookMethodType.Before)

    -- Clean up when an item is removed from the game
    self:AddHook("item.removed", function(item)
        for character, set in next, forceEquippedItems do
            if set[item] then
                set:Remove(item)
            end
        end
    end)

    -- Clean up when a character is removed
    self:AddHook("character.removed", function(character)
        forceEquippedItems[character] = nil
    end)
end

---@param self Types.Module
local function deactivate(self)
    forceEquippedItems = nil
end

return Types.Module.new(activate, deactivate)
