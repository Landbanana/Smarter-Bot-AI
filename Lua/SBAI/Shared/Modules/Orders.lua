local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.RegisterType("Barotrauma.CrewManager+ActiveOrder")

local ID_ORDER = Constants.ID_ORDER

local IGNORE_ROOM = ID_ORDER.IGNORE_ROOM
local FABRICATE_ITEMS = ID_ORDER.FABRICATE_ITEMS
local PERFORM = ID_ORDER.PERFORM
local SBAI_CATEGORY = ID_ORDER.SBAI_CATEGORY
local UNIGNORE_ROOM = ID_ORDER.UNIGNORE_ROOM

local orderCategoryPrefix = SBAI_CATEGORY.Value.."_" --[[@type string]]

local ignoredHulls
local activeOrders --[=[@type Barotrauma.CrewManager.ActiveOrder[]]=]

---@param self Types.Module
---@return Types.Set<Barotrauma.Hull>
local function activateIgnoreRoomOrder(self)
    ignoredHulls = Types.Set.new(self:RegisterTable(nil, "ROUND_END")) --[[@type Types.Set<Barotrauma.Hull>]]

    self:RegisterStrongRef("Game.GameSession.CrewManager.ActiveOrders", "System.Collections.Generic.List`1[[Barotrauma.CrewManager+ActiveOrder]]", "Barotrauma.CrewManager",
    function(strongRef)
        activeOrders = strongRef
    end)

    self:AddInit(
    function()
        for activeOrder in activeOrders do
            local curOrder = activeOrder.Order --[[@type Barotrauma.Order]]
    
            if curOrder.Identifier == IGNORE_ROOM then
                ignoredHulls:Add(curOrder.TargetEntity)
            end
        end
    end)

    self:AddPatch("Barotrauma.CrewManager", "AddOrder", nil,
    function(instance, ptable)
        local order = ptable["order"] --[[@type Barotrauma.Order]]
        local id = order.Identifier --[[@type Barotrauma.Identifier]]

        if id:StartsWith(orderCategoryPrefix) then
            if id == IGNORE_ROOM then
                if ptable["fadeOutTime"] then
                    ptable.PreventExecution = true

                    return instance.AddOrder(order)
                else
                    ignoredHulls:Add(order.TargetEntity)
                end
            elseif id == UNIGNORE_ROOM then
                local targetHull = order.TargetEntity --[[@type Barotrauma.Hull]]

                ptable.PreventExecution = true
                
                for activeOrder in activeOrders do
                    local curOrder = activeOrder.Order --[[@type Barotrauma.Order]]

                    if  curOrder.Identifier == IGNORE_ROOM and
                        curOrder.TargetEntity == targetHull
                    then
                        activeOrders.Remove(activeOrder)
                        break
                    end
                end
                ignoredHulls:Remove(targetHull)
                return true
            end
        end
    end, Hook.HookMethodType.Before)
end

---@param self Types.Module
local function activate(self)
    if not ignoredHulls then
        activateIgnoreRoomOrder(self)
    end
    return ignoredHulls
    
    -- self:AddInit(
    -- function()
    --     local session = Game.GameSession

    --     if not session then return end
    --     activeOrders = GetStrongRef(function() return session.CrewManager.ActiveOrders end,
    --     "System.Collections.Generic.List`1[[Barotrauma.CrewManager+ActiveOrder]]")

    --     -- optionNodes = GetStrongRef(function() return session.CrewManager.optionNodes end,
    --     -- "System.Collections.Generic.List`1[[Barotrauma.CrewManager+OptionNode]]")

    --     for activeOrder in activeOrders do
    --         local curOrder = activeOrder.Order --[[@type Barotrauma.Order]]

    --         if curOrder.Identifier == IGNORE_ROOM then
    --             ignoredHulls:Add(curOrder.TargetEntity)
    --         end
    --     end
    -- end)
end

---@param self Types.Module
local function deactivate(self)
    if not self.options.enable then
        local session = Game.GameSession

        if session then
            if activeOrders then
                local removeIndices = {}
                local i = 0
                local j = 0
                
                for order in activeOrders do
                    local orderId = order.Order.Identifier --[[@type Barotrauma.Identifier]]
        
                    if orderId:StartsWith(orderCategoryPrefix) then
                        j = j + 1
                        removeIndices[j] = i
                    end
                    i = i + 1
                end
        
                table.sort(removeIndices, function(k1, k2) return k1 > k2 end)
                for k in removeIndices do --[[@cast k integer]]
                    activeOrders.RemoveAt(k)
                end
            end

            util.DoWithTemporaryRegistrations({"System.Collections.Generic.List`1[[Barotrauma.Order]]"},
            function()
                local sort = table.sort

                for character in Character.CharacterList do --[[@cast character Barotrauma.Character]]
                    if  character.IsHuman and
                        character.IsBot
                    then
                        local CurrentOrders = character.AIController.ObjectiveManager.CurrentOrders --[[@type System.Collections.Generic.List*1Barotrauma*Order]]
                        local removeIndices = {}
                        local i = 0
                        local j = 0
            
                        for order in CurrentOrders do
                            local orderId = order.Identifier --[[@type Barotrauma.Identifier]]
            
                            if orderId:StartsWith(orderCategoryPrefix) then
                                j = j + 1
                                removeIndices[j] = i
                            end
                            i = i + 1
                        end
            
                        sort(removeIndices, function(k1, k2) return k1 > k2 end)
                        for k in removeIndices do --[[@cast k integer]]
                            CurrentOrders.RemoveAt(k)
                        end
                    end
                end
            end)
        end
    end
    ignoredHulls = nil
    activeOrders = nil
end

return {activate, deactivate}