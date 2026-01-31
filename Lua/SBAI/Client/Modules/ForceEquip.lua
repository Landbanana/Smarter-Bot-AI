local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

-- Force Equip Client Module
-- Adds the "Force Equip" order to the contextual menu (Shift+Middle Mouse on items)
-- that can be equipped by characters

local FORCEEQUIP = Constants.ID_ORDER.FORCEEQUIP

do
    local MakeFieldAccessible = LuaUserData.MakeFieldAccessible
    local MakeMethodAccessible = LuaUserData.MakeMethodAccessible
    local Descriptors = Descriptors
    local descriptor

    descriptor = Descriptors["Barotrauma.CrewManager"]
    MakeFieldAccessible(descriptor, "itemContext")
    MakeFieldAccessible(descriptor, "contextualOrders")
    MakeFieldAccessible(descriptor, "isContextual")
end

LuaUserData.RegisterType("System.Collections.Generic.List`1[[Barotrauma.Order]]")

---@param self Types.Module
local function activate(self)
    local Character = Character
    local OrderPrefab = OrderPrefab
    local Order = Order
    local Pickable = Components.Pickable

    print("[SBAI ForceEquip] Module activating...")

    -- Get the Force Equip order prefab
    local forceEquipPrefab = nil
    for prefab in OrderPrefab.Prefabs do
        if prefab.Identifier == FORCEEQUIP then
            forceEquipPrefab = prefab
            break
        end
    end

    if not forceEquipPrefab then
        print("[SBAI ForceEquip] ERROR: Could not find order prefab sbai_forceequip")
        return
    end
    
    print("[SBAI ForceEquip] Found order prefab: " .. tostring(forceEquipPrefab.Identifier))

    -- Helper function to check if an item can be picked up
    ---@param item Barotrauma.Item
    ---@return boolean
    local function canBePickedUp(item)
        if not item then return false end
        
        -- Check if the item has a Pickable component
        local pickable = item.GetComponent(Pickable)
        
        -- If it has a Pickable component, it can be picked up
        return pickable ~= nil
    end

    -- Helper function to check if item is available for pickup
    ---@param item Barotrauma.Item
    ---@return boolean
    local function isItemAvailable(item)
        if not item then return false end
        
        -- Check ParentInventory - if nil, item is on the ground/in world
        local parentInventory = item.ParentInventory
        
        if parentInventory then
            -- Check if the inventory belongs to a character
            local owner = parentInventory.Owner
            if owner and owner.IsCharacter then
                return false
            end
        end
        
        return true
    end

    -- Patch to add Force Equip order to contextual menu BEFORE nodes are created
    self:AddPatch("Barotrauma.CrewManager", "CreateContextualOrderNodes", nil,
    function(instance, ptable)
        local itemContext = instance.itemContext --[[@type Barotrauma.Item]]
        
        print("[SBAI ForceEquip] CreateContextualOrderNodes called, itemContext: " .. tostring(itemContext))
        
        if itemContext then
            local canPickUp = canBePickedUp(itemContext)
            local isAvailable = isItemAvailable(itemContext)
            
            print("[SBAI ForceEquip] canPickUp: " .. tostring(canPickUp) .. ", isAvailable: " .. tostring(isAvailable))
            
            if canPickUp and isAvailable then
                local contextualOrders = instance.contextualOrders
                
                print("[SBAI ForceEquip] contextualOrders: " .. tostring(contextualOrders))
                
                if contextualOrders then
                    local controlledCharacter = Character.Controlled
                    
                    -- Create the order with the item as target entity
                    local forceEquipOrder = Order(forceEquipPrefab, itemContext, nil, controlledCharacter)
                    
                    print("[SBAI ForceEquip] Adding order to contextual menu")
                    
                    -- Add to the list of contextual orders
                    contextualOrders.Add(forceEquipOrder)
                end
            end
        end
    end, Hook.HookMethodType.Before)
    
    print("[SBAI ForceEquip] Module activated successfully")
end

return Types.Module.new(activate)
