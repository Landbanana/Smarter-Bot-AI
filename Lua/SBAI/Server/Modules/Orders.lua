local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

---@param self Types.Module
local function activateIgnoreRoom(self)
    -- local allHullData = self:RegisterTable(nil, "ROUND_END") --[[@type {set:Types.Set}]]
    self:AddPatch("Barotrauma.Hull", "get_AvoidStaying", nil,
    function(instance, ptable)
        return true
    end, Hook.HookMethodType.After)
    -- do
    --     local new = Types.Set.new

    --     setmetatable(allHullData,{
    --         ---@param t {set:Types.Set}
    --         ---@return Types.Set
    --         __call=function(t)
    --             if not t.set then
    --                 t.set = new()
    --             end
    --             return t.set
    --         end
    --     })
    -- end
    
    -- if CLIENT then

    --     LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CrewManager"], "contextualOrders")
    --     LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CrewManager"], "itemContext")

    --     local ignoreRoomId = Identifier("ignoreroom")
    --     local unignoreRoomId = Identifier("unignoreroom")

    --     do
            
    --         local ignoreRoomPrefab = OrderPrefab.Prefabs[ignoreRoomId]
    --         local unignoreRoomPrefab = OrderPrefab.Prefabs[unignoreRoomId]
    --         local Character = Character
    --         local playerTeamId = Submarine.MainSub.TeamID

    --         local DoWithTemporaryRegistrations = util.DoWithTemporaryRegistrations

    --         local contextualOrders
            
    --         self:AddNestedPatch("Barotrauma.CrewManager", "CreateContextualOrderNodes", "AddIgnoreOrder", nil,
    --         function(instance, ptable)
    --             local item = instance.itemContext
                
    --             if  item then
    --                 local hull = item.CurrentHull

    --                 if  hull and
    --                     hull.Submarine.TeamID == playerTeamId
    --                 then
    --                     local prefab = allHullData.set[hull] and unignoreRoomPrefab or ignoreRoomPrefab
    --                     print(prefab.Identifier)
    --                     local order = Order.__new(allHullData.set[hull] and unignoreRoomPrefab or ignoreRoomPrefab, hull, nil, Character.Controlled)
                        
    --                     if contextualOrders then
    --                         contextualOrders.Add(order)
    --                     else
    --                         DoWithTemporaryRegistrations({"System.Collections.Generic.List`1[[Barotrauma.Order]]"},
    --                         function()
    --                             contextualOrders = instance.contextualOrders
    --                             return contextualOrders.Add(order)
    --                         end)
    --                     end
    --                 end
    --             end
    --         end, Hook.HookMethodType.Before)
    --     end

    --     self:AddPatch("Barotrauma.CrewManager", "SetCharacterOrder", nil,
    --     function(instance, ptable)
    --         local order = ptable["order"] --[[@type Barotrauma.Order]]
    --         local orderId = order.Identifier
    --         local hull = order.TargetEntity --[[@type Barotrauma.Hull]]
            
    --         if orderId == ignoreRoomId then
    --             allHullData.set:Add(hull)
    --         elseif orderId == unignoreRoomId then
    --             allHullData.set:Remove(hull)
    --         end
    --     end, Hook.HookMethodType.Before)

    --     self:AddPatch("Barotrauma.Order", "GetChatMessage", nil,
    --     function(instance, ptable)
    --         print(ptable.ReturnValue == "")
    --     end, Hook.HookMethodType.After)
    
    -- end
    -- allHullData()
end

---@param self Types.Module
local function activate(self)
    self:DoOption("ignoreRoom", activateIgnoreRoom)
end

return Types.Module.new(activate)