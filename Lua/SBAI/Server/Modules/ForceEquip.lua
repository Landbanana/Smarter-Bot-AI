local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

-- Force Equip Module
-- When a character receives a Force Equip order, they will go pick up the target item
-- and equip it permanently (won't unequip it until the player manually removes it)
-- 
-- The order is NOT retained in the crew order list
-- Items are tagged with "sbai-forced" so they cannot be dropped/unequipped by NPCs
-- A player can remove the forced status by taking the item from the NPC's inventory
--
-- IMPORTANT: NPCs cannot remove forced items by ANY means:
-- - Cannot drop the item
-- - Cannot unequip the item
-- - Cannot have the item removed from inventory by AI
-- - Canceling orders does NOT affect forced items
-- Only a PLAYER can remove the forced status by manually taking the item

local FORCEEQUIP = Constants.ID_ORDER.FORCEEQUIP
local orderCategoryPrefix = Constants.ID_ORDER.SBAICATEGORY.Value.."_"

-- Tag identifier for forced items
local FORCED_TAG = Identifier("sbai-forced")

-- Table to track which items characters should pick up
local pendingForceEquip = nil --[[@type table<Barotrauma.Character, Barotrauma.Item>]]

-- Table to track the last bot owner of forced items (to detect player taking item)
local lastBotOwner = nil --[[@type table<Barotrauma.Item, Barotrauma.Character>]]

---@param self Types.Module
local function activate(self)
    self:AddCommonModule("SBAI.Server.CommonModules.AIObjectiveExpansion")
    self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")

    -- Initialize tracking tables
    pendingForceEquip = self:RegisterTable(nil, "ROUND_END") --[[@type table<Barotrauma.Character, Barotrauma.Item>]]
    lastBotOwner = self:RegisterTable(nil, "ROUND_END") --[[@type table<Barotrauma.Item, Barotrauma.Character>]]

    local AIObjectiveGoTo = AIObjectiveGoTo

    -- Helper function to check if item has the forced tag
    ---@param item Barotrauma.Item
    ---@return boolean
    local function isForcedItem(item)
        return item and item.HasTag and item.HasTag(FORCED_TAG)
    end

    -- Helper function to safely check if an entity is a bot character
    ---@param entity any
    ---@return boolean
    local function isBot(entity)
        if not entity then return false end
        -- Use pcall to safely check IsBot since it may not exist on all entity types
        local success, result = pcall(function() return entity.IsBot end)
        return success and result == true
    end

    -- Helper function to check if an entity is a player character
    ---@param entity any
    ---@return boolean
    local function isPlayer(entity)
        if not entity then return false end
        -- Check if entity is a human character that is not a bot
        local success, isHuman = pcall(function() return entity.IsHuman end)
        if not success or not isHuman then return false end
        local success2, isBot = pcall(function() return entity.IsBot end)
        return success2 and isBot == false
    end

    -- Helper function to check if an entity is a Character (human or otherwise)
    ---@param entity any
    ---@return boolean
    local function isCharacter(entity)
        if not entity then return false end
        local success, isHuman = pcall(function() return entity.IsHuman end)
        return success and isHuman ~= nil
    end

    -- Helper function to get the character owner of an item (traverses containers)
    ---@param item Barotrauma.Item
    ---@return Barotrauma.Character|nil
    local function getCharacterOwner(item)
        if not item then return nil end
        local inv = item.ParentInventory
        if not inv then return nil end
        local owner = inv.Owner
        if owner and isCharacter(owner) then
            return owner
        end
        -- If owner is not a character, check if it's an item (container) in a character's inventory
        if owner then
            local success, parentInv = pcall(function() return owner.ParentInventory end)
            if success and parentInv then
                return getCharacterOwner(owner)
            end
        end
        return nil
    end

    -- Helper function to check if the character holding an item is a bot
    ---@param item Barotrauma.Item
    ---@return boolean, Barotrauma.Character|nil
    local function isItemInBotInventory(item)
        local owner = getCharacterOwner(item)
        if isBot(owner) then
            return true, owner
        end
        return false, nil
    end

    -- Helper function to add forced tag to an item
    ---@param item Barotrauma.Item
    local function addForcedTag(item)
        if item and item.AddTag and not isForcedItem(item) then
            item.AddTag(FORCED_TAG)
        end
    end

    -- Helper function to remove forced tag from an item
    ---@param item Barotrauma.Item
    local function removeForcedTag(item)
        if item and item.RemoveTag and isForcedItem(item) then
            item.RemoveTag(FORCED_TAG)
            lastBotOwner[item] = nil
        end
    end

    -- Helper function to track the bot owner of a forced item
    ---@param item Barotrauma.Item
    ---@param bot Barotrauma.Character
    local function trackBotOwner(item, bot)
        if item and bot then
            lastBotOwner[item] = bot
        end
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
    -- The order should NOT be retained in the crew orders list (auto-dismiss)
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
                    
                    if itemToEquip and not itemToEquip.Removed then
                        -- Pick up the item
                        if character.CanInteractWith(itemToEquip, false, true) then
                            if tryEquipItem(itemToEquip, character) then
                                -- Add the forced tag to the item and track the bot owner
                                addForcedTag(itemToEquip)
                                trackBotOwner(itemToEquip, character)
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
        
        if item and instance.IsBot and isForcedItem(item) then
            -- Prevent unequipping force-equipped items
            ptable.PreventExecution = true
            return false
        end
    end, Hook.HookMethodType.Before)

    -- Patch to prevent dropping force-equipped items by bots
    -- This blocks ALL drop attempts for forced items that are in a bot inventory
    self:AddPatch("Barotrauma.Item", "Drop", nil,
    function(instance, ptable)
        if not isForcedItem(instance) then return end
        
        local dropper = ptable["dropper"] --[[@type Barotrauma.Character]]
        
        -- Check if the item is currently in a bot's inventory
        local inBot, botOwner = isItemInBotInventory(instance)
        if inBot then
            -- Always prevent dropping if item is in bot inventory
            -- (dropper may be nil when game auto-drops, or may be the bot itself)
            if not dropper or isBot(dropper) then
                ptable.PreventExecution = true
                return
            end
            -- If a PLAYER is causing the drop (transferring to their inventory), allow it
            -- The tag will be removed in inventoryPutItem hook when item enters player inventory
        end
    end, Hook.HookMethodType.Before)

    -- Patch to prevent removing forced items from bot inventory
    -- Allow removal only if a player is actively taking the item
    self:AddPatch("Barotrauma.Inventory", "RemoveItem", nil,
    function(instance, ptable)
        local item = ptable["item"] --[[@type Barotrauma.Item]]
        
        if item and isForcedItem(item) then
            local owner = instance.Owner
            -- If the inventory belongs to a bot, check if we should allow removal
            if isBot(owner) then
                -- Track the bot owner so we can detect player transfer
                trackBotOwner(item, owner)
                -- Don't prevent - let the player take items, the tag removal happens after
            end
        end
    end, Hook.HookMethodType.Before)

    -- Patch to prevent forced items from being removed via ForceRemoveFromSlot
    self:AddPatch("Barotrauma.Inventory", "ForceRemoveFromSlot", nil,
    function(instance, ptable)
        local item = ptable["item"] --[[@type Barotrauma.Item]]
        
        if item and isForcedItem(item) then
            local owner = instance.Owner
            -- If the inventory belongs to a bot, track the owner
            if isBot(owner) then
                trackBotOwner(item, owner)
            end
        end
    end, Hook.HookMethodType.Before)

    -- Hook AFTER item is put into inventory to detect when a PLAYER receives a forced item
    -- This is the ONLY way to remove forced status - player must have item in THEIR inventory
    self:AddHook("inventoryPutItem", function(inventory, item, user, slotIndex, removeItem)
        if not item then return end
        if not isForcedItem(item) then return end
        
        -- Get the NEW owner of the item (after the transfer)
        local newOwner = inventory and inventory.Owner
        
        -- Check if the new owner is a player (not a bot)
        if isPlayer(newOwner) then
            -- Item is now in a player's inventory - remove the forced tag
            removeForcedTag(item)
        elseif isBot(newOwner) then
            -- Item transferred to another bot, update the tracking
            trackBotOwner(item, newOwner)
        end
    end)

    -- Periodic check to re-equip forced items that somehow got dropped
    -- This is a safety net in case some game mechanic bypasses our patches
    self:AddHook("think", function()
        for item, bot in pairs(lastBotOwner) do
            if item and not item.Removed and isForcedItem(item) and bot and not bot.IsDead then
                local currentOwner = getCharacterOwner(item)
                -- If the item is no longer in the bot's inventory, try to re-equip it
                if currentOwner ~= bot then
                    -- Item was somehow removed - check if it's on the ground
                    if not item.ParentInventory then
                        -- Try to re-equip
                        if bot.CanInteractWith(item, false, true) then
                            tryEquipItem(item, bot)
                        end
                    end
                end
            end
        end
    end)

    -- Clean up forced tags when items are removed from the game
    self:AddHook("item.removed", function(item)
        if item then
            lastBotOwner[item] = nil
            if isForcedItem(item) then
                item.RemoveTag(FORCED_TAG)
            end
        end
    end)
end

---@param self Types.Module
local function deactivate(self)
    pendingForceEquip = nil
    lastBotOwner = nil
end

return Types.Module.new(activate, deactivate)
