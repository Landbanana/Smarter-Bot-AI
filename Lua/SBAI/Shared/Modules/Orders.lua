local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.RegisterType("Barotrauma.CrewManager+ActiveOrder")

---@enum ID_ORDER
local ID_ORDER = {
    FABRICATE_ITEMS = Identifier("sbai_fabricateitems"),
    IGNORE_ROOM = Identifier("sbai_ignoreroom"),
    PERFORM = Identifier("sbai_perform"),
    SBAI_CATEGORY = Identifier("sbai"),
    UNIGNORE_ROOM = Identifier("sbai_unignoreroom")
}

local IGNORE_ROOM = ID_ORDER.IGNORE_ROOM
local FABRICATE_ITEMS = ID_ORDER.FABRICATE_ITEMS
local PERFORM = ID_ORDER.PERFORM
local SBAI_CATEGORY = ID_ORDER.SBAI_CATEGORY
local UNIGNORE_ROOM = ID_ORDER.UNIGNORE_ROOM

local orderCategoryPrefix = SBAI_CATEGORY.Value.."_" --[[@type string]]


---@param self Types.Module
local function activate(self)
    local ignoredHulls

    if ignoredHulls then return ignoredHulls end
    ignoredHulls = Types.Set.new(self:RegisterTable(nil, "ROUND_END")) --[[@type Types.Set<Barotrauma.Hull>]]

    local Contains = util.itertools.Contains
    local GetTypedObj = util.GetTypedObj
    
    local activeOrders --[=[@type Barotrauma.CrewManager.ActiveOrder[]]=]

    self:AddInit(
    function()
        local session = Game.GameSession

        if not session then return end
        activeOrders = GetTypedObj(function() return session.CrewManager.ActiveOrders end,
        "System.Collections.Generic.List`1[[Barotrauma.CrewManager+ActiveOrder]]")

        -- optionNodes = GetTypedObj(function() return session.CrewManager.optionNodes end,
        -- "System.Collections.Generic.List`1[[Barotrauma.CrewManager+OptionNode]]")

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

    local instrumentData = setmetatable({}, {
        ---@param t {[Barotrauma.Identifier]:{slotTypes:Barotrauma.InvSlotType[]}}
        ---@param k Barotrauma.Identifier
        __index=function(t, k)
            local prefab = ItemPrefab.Prefabs[k]

            if prefab then
                local holdable = prefab.ConfigElement.GetChildElement("Holdable")
            
                if holdable then
                    local slotString = holdable.GetAttributeString("slots")
                    
                    if slotString then
                        local allowedSlots = {}
                        local i = 0
            
                        for slotCombination in slotString:gmatch("([^,]+),?") do
                            if slotCombination:lower() ~= "any" then
                                local slots = 0
            
                                i = i + 1
                                for specSlotString in slotCombination:gmatch("([^%+]+)%+?") do
                                    specSlotString = specSlotString:match("(%a+)")
                                    
                                    if specSlotString:lower() == "bothhands" then
                                        slots = InvSlotType.LeftHand + InvSlotType.RightHand
                                    end
            
                                    slots = slots + InvSlotType[specSlotString]
                                end
                                allowedSlots[i] = slots
                            end
                        end
                        if i > 0 then
                            t[k] = {slotTypes=allowedSlots}
                            return t[k]
                        end
                    end
                end
            end
            error("Unable to find instrument: "..k, 2)
        end
    })

    self:AddPatch("Barotrauma.Items.Components.ItemComponent", "CrewAIOperate", nil,
    function(instance, ptable)
        local obj = ptable["objective"]

        if obj.Identifier == PERFORM then
            local item = instance.Item
            local character = ptable["character"] --[[@type Barotrauma.Character]]

            character.AIController.SteeringManager.Reset()
            if  Contains(character.HeldItems, item) or
                character.inventory.TryPutItem(item, character, instrumentData[item.Prefab.Identifier].slotTypes, true, false)
            then
                character.SetInput(InputType.Aim, false, true)
                character.SetInput(InputType.Shoot, false, true)
            end
            return true
        end
    end, Hook.HookMethodType.Before)
    return ignoredHulls
end

---@param self Types.Module
local function deactivate(self)
    if self.options.enable then return end

    util.DoWithTemporaryRegistrations(
    {"System.Collections.Generic.List`1[[Barotrauma.CrewManager+ActiveOrder]]"},
    function()
        local session = Game.GameSession

        if not session then return end

        do
            local activeOrders = session.CrewManager.ActiveOrders --[[@type System.Collections.Generic.List*1Barotrauma*CrewManager*ActiveOrder]]
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

return activate, deactivate, ID_ORDER