local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.RegisterType("Barotrauma.CrewManager+ActiveOrder")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Hull"], "avoidStaying")

local orderCategoryId = Identifier("sbai")
local orderCategoryPrefix = orderCategoryId.Value.."_" --[[@type string]]

---@param self Types.Module
local function activate(self)
    if SERVER then
        local Game = Game
        local ignoreRoomOrderId = Identifier("sbai_ignoreroom")
        local unignoreRoomOrderId = Identifier("sbai_unignoreroom")
        
        local DoWithTemporaryRegistrations = util.DoWithTemporaryRegistrations

        local ignoredHulls = Types.Set.new(self:RegisterTable(nil, "ROUND_END")) --[[@type Types.Set<Barotrauma.Hull>]]
        local activeOrders

        self:AddInit(
        function()
            local session = Game.GameSession

            if not session then return end
            DoWithTemporaryRegistrations({
                "System.Collections.Generic.List`1[[Barotrauma.CrewManager+ActiveOrder]]"
            },
            function()
                activeOrders = session.CrewManager.ActiveOrders
                for activeOrder in activeOrders do
                    local curOrder = activeOrder.Order --[[@type Barotrauma.Order]]

                    if curOrder.Identifier == ignoreRoomOrderId then
                        ignoredHulls:Add(curOrder.TargetEntity)
                    end
                end
            end)
        end)

        self:AddPatch("Barotrauma.CrewManager", "AddOrder", nil,
        function(instance, ptable)
            local order = ptable["order"] --[[@type Barotrauma.Order]]
            local id = order.Identifier --[[@type Barotrauma.Identifier]]

            if id:StartsWith(orderCategoryPrefix) then
                if id == ignoreRoomOrderId then
                    if ptable["fadeOutTime"] then
                        ptable.PreventExecution = true
    
                        return instance.AddOrder(order)
                    else
                        ignoredHulls:Add(order.TargetEntity)
                    end
                elseif id == unignoreRoomOrderId then
                    local targetHull = order.TargetEntity --[[@type Barotrauma.Hull]]

                    ptable.PreventExecution = true

                    for activeOrder in activeOrders do
                        local curOrder = activeOrder.Order --[[@type Barotrauma.Order]]

                        if  curOrder.Identifier == ignoreRoomOrderId and
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

        self:AddPatch("Barotrauma.Hull", "get_AvoidStaying", nil,
        function(instance, ptable)
            ptable.PreventExecution = true
            
            return instance.avoidStaying or instance.IsWetRoom or (ignoredHulls[instance] ~= nil)
        end, Hook.HookMethodType.Before)
    end
end

---@param self Types.Module
local function deactivate(self)
    if SERVER then
        if self.options.enable then return end

        util.DoWithTemporaryRegistrations(
        {"System.Collections.Generic.List`1[[Barotrauma.CrewManager+ActiveOrder]]"},
        function()
            local session = Game.GameSession

            if not session then return end

            do
                local ActiveOrders = session.CrewManager.ActiveOrders --[[@type System.Collections.Generic.List*1Barotrauma*CrewManager*ActiveOrder]]
                local removeIndices = {}
                local i = 0
                local j = 0

                for order in ActiveOrders do
                    local orderId = order.Order.Identifier --[[@type Barotrauma.Identifier]]

                    if orderId:StartsWith(orderCategoryPrefix) then
                        j = j + 1
                        removeIndices[j] = i
                    end
                    i = i + 1
                end

                table.sort(removeIndices, function(k1, k2) return k1 > k2 end)
                for k in removeIndices do --[[@cast k integer]]
                    ActiveOrders.RemoveAt(k)
                end
            end

            for character in Character.CharacterList do --[[@cast character Barotrauma.Character]]
                if character.IsHuman then
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

                    table.sort(removeIndices, function(k1, k2) return k1 > k2 end)
                    for k in removeIndices do --[[@cast k integer]]
                        CurrentOrders.RemoveAt(k)
                    end
                end
            end
        end)
    end
end

return Types.Module.new(activate, deactivate)