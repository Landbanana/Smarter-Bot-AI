local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.RegisterType("Barotrauma.CrewManager+OptionNode")
LuaUserData.RegisterType("Barotrauma.CrewManager+ActiveOrder")
LuaUserData.RegisterType("Barotrauma.Order+OrderTargetType")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Hull"], "avoidStaying")

--LuaUserData.RegisterType("System.Collections.Generic.List`1[[Barotrauma.CrewManager+OptionNode]]")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "CreateShortcutNodes")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CrewManager"], "isContextual")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CrewManager"], "commandFrame")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CrewManager"], "contextualOrders")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CrewManager"], "hullContext")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CrewManager"], "wallContext")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CrewManager"], "characterContext")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CrewManager"], "itemContext")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CrewManager"], "nodeSize")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "GetFirstNodeAngle")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "GetTargetSubmarine")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "CreateShortcutNodes")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "CanCharacterBeHeard")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "GetFirstNodeAngle")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "GetCircumferencePointCount")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "IsOrderAvailable", {"Barotrauma.OrderPrefab"})
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "CreateOrderCategoryNodes")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "CreateOrderCategoryNode")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "CreateOrderNodes")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "CreateOrderNode")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "CreateNodes")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "CreateNodeIcon",
{"Microsoft.Xna.Framework.Vector2", "Barotrauma.RectTransform", "Barotrauma.Sprite", "Microsoft.Xna.Framework.Color", "Barotrauma.LocalizedString"})
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CrewManager"], "nodeDistance")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CrewManager"], "availableCategories")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CrewManager"], "optionNodes")

local orderCategoryId = Identifier("sbai")
local orderCategoryPrefix = orderCategoryId.Value.."_" --[[@type string]]

---@param self Types.Module
local function activate(self)
    local ignoreRoomOrderId = Identifier("sbai_ignoreroom")
    local unignoreRoomOrderId = Identifier("sbai_unignoreroom")
    local orderCategory --[[@type Barotrauma.OrderCategory]]
    local optionNode  --[[@type Barotrauma.CrewManager.OptionNode]]
    local sprite --[[@type Barotrauma.Sprite]]
    local ignoredHulls = Types.Set.new(self:RegisterTable(nil, "ROUND_END"))
    local activeOrders
    local optionNodes

    for v in OrderCategory do
        orderCategory = (v > (orderCategory or -1)) and v or orderCategory
    end
    orderCategory = orderCategory + 1
    for s in Sprite.LoadedSprites do
        if s.Name == "Command_Category_SBAI" then
            sprite = s
            break
        end
    end

    do
        local Game = Game

        local DoWithTemporaryRegistrations = util.DoWithTemporaryRegistrations
        local new = Types.Set.new

        self:AddInit(
        function()
            local session = Game.GameSession

            if not session then return end
            DoWithTemporaryRegistrations({
                "System.Collections.Generic.List`1[[Barotrauma.CrewManager+ActiveOrder]]",
                "System.Collections.Generic.List`1[[Barotrauma.CrewManager+OptionNode]]"
            },
            function()
                optionNodes = session.CrewManager.optionNodes
                activeOrders = session.CrewManager.ActiveOrders
                for activeOrder in activeOrders do
                    local curOrder = activeOrder.Order --[[@type Barotrauma.Order]]

                    if curOrder.Identifier == ignoreRoomOrderId then
                        ignoredHulls:Add(curOrder.TargetEntity)
                    end
                end
            end)
        end)
    end

    do
        local offsets --[=[@type Microsoft.Xna.Framework.Vector2[]]=]
        local offsetIndex --[[@type integer]]

        do
            local firstAngle = math.rad(197.5)
            local Zero = Vector2.Zero

            local GetPointsOnCircumference = util.GetPointsOnCircumference

            self:AddPatch("Barotrauma.CrewManager", "CreateOrderCategoryNodes", nil,
            function(instance, ptable)
                offsets = GetPointsOnCircumference(Zero, instance.nodeDistance, #instance.availableCategories + 1, firstAngle)
                offsetIndex = 1
            end, Hook.HookMethodType.Before)
        end
    
        self:AddPatch("Barotrauma.CrewManager", "CreateOrderCategoryNode", nil,
        function(instance, ptable)
            if offsets then
                ptable["offset"] = offsets[offsetIndex].ToPoint()
                offsetIndex = offsetIndex + 1
            end
        end, Hook.HookMethodType.Before)

        do
            local One = Vector2.One
            local HotPink = Color.HotPink

            self:AddPatch("Barotrauma.CrewManager", "CreateOrderCategoryNodes", nil,
            function(instance, ptable)
                if offsets then
                    local offset = offsets[offsetIndex].ToPoint()
                    
                    offsets = nil
                    instance.CreateOrderCategoryNode(orderCategory, offset, offsetIndex)
                    offsetIndex = nil

                    local optionNodes = instance.optionNodes

                    optionNode = optionNodes[#optionNodes]
                end
                local tooltip = TextManager.Get("ordercategorytitle."..orderCategoryId.Value)

                instance.CreateNodeIcon(One, optionNode.Button.RectTransform, sprite, HotPink, tooltip)

                local button = optionNode.Button --[[@type Barotrauma.GUIButton]]

                button.GetChild(Int32(button.CountChildren - 2)).RectTransform.SetAsLastChild() --[[@type Barotrauma.GUIImage]]
            end, Hook.HookMethodType.After)
        end
    end

    do
        local defaultTargetType = OrderPrefab.OrderTargetType.Entity
        local keyMap = {Keys.D0, Keys.D1, Keys.D2, Keys.D3, Keys.D4, Keys.D5, Keys.D6, Keys.D7, Keys.D8, Keys.D9}
        local OptionNode = LuaUserData.CreateStatic("Barotrauma.CrewManager+OptionNode")
        local prefabs = {}
        local Zero = Vector2.Zero
        local Character = Character
        
        local Any = util.itertools.Any
        local GetPointsOnCircumference = util.GetPointsOnCircumference
        local None = util.itertools.None

        self:AddPatch("Barotrauma.CrewManager", "CreateOrderNodes", nil,
        function(instance, ptable)
            if ptable["orderCategory"] == orderCategory then
                local currentCharacter = Character.Controlled
                local targetHull = currentCharacter.CurrentHull

                ptable.PreventExecution = true

                local i = 0

                for prefab in OrderPrefab.Prefabs do
                    local id = prefab.Identifier

                    if  id:StartsWith(orderCategoryPrefix) and
                        not prefab.IsReport and
                        instance.IsOrderAvailable(prefab)
                    then
                        if  (id == ignoreRoomOrderId and
                            (targetHull == nil or
                            targetHull.Submarine.TeamID ~= currentCharacter.TeamID or
                            ignoredHulls[targetHull])) or
                            (id == unignoreRoomOrderId and
                            (targetHull == nil or
                            not ignoredHulls[targetHull]))
                        then
                            goto continue
                        end
                        i = i + 1
                        prefabs[i] = prefab
                    end
                    ::continue::
                end

                local order
                local disableNode
                local offsets = GetPointsOnCircumference(Zero, instance.nodeDistance, instance.GetCircumferencePointCount(i), instance.GetFirstNodeAngle(i))

                for j=1,i,1 do
                    local prefab = prefabs[j]
                    local id = prefab.Identifier

                    if  id == ignoreRoomOrderId or
                        id == unignoreRoomOrderId
                    then
                        order = Order(prefab, targetHull, nil, Character.Controlled)
                    else
                        order = prefab.CreateInstance(defaultTargetType) --[[@type Barotrauma.Order]]
                    end
                    disableNode = (not instance.CanCharacterBeHeard()) or
                        (order.MustSetTarget and (
                            order.ItemComponentType ~= nil or
                            Any(order.GetTargetItems()) or
                            Any(order.RequireItems)
                        ) and None(order.GetMatchingItems(true, instance.characterContext or Character.Controlled)))
                    optionNodes.Add(OptionNode(
                        instance.CreateOrderNode(instance.nodeSize, instance.commandFrame.RectTransform, offsets[j].ToPoint(), order, j % 10, disableNode, false),
                        (not disableNode) and keyMap[j + 1 % 10] or Keys.None))
                end
            end
        end, Hook.HookMethodType.Before)
    end

    do
        local Character = Character

        self:AddPatch("Barotrauma.CrewManager", "SetCharacterOrder", nil,
        function(instance, ptable)
            local order = ptable["order"] --[[@type Barotrauma.Order]]
            local id = order.Identifier

            if id:StartsWith(orderCategoryPrefix) then
                if  id == ignoreRoomOrderId or
                    id == unignoreRoomOrderId
                then
                    local currentCharacter = Character.Controlled
                    local targetHull = currentCharacter.CurrentHull

                    if  targetHull ~= nil and 
                        targetHull.Submarine.TeamID == currentCharacter.TeamID
                    then
                        instance.AddOrder(order.Clone().WithTargetEntity(targetHull))
                    end
                end
            end
        end, Hook.HookMethodType.Before)
    end

    
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

---@param self Types.Module
local function deactivate(self)
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

return Types.Module.new(activate, deactivate)