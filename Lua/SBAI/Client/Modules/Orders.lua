local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.RegisterType("Barotrauma.CrewManager+OptionNode")
LuaUserData.RegisterType("Barotrauma.CrewManager+ActiveOrder")
LuaUserData.RegisterType("Barotrauma.Order+OrderTargetType")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Hull"], "avoidStaying")

--LuaUserData.RegisterType("System.Collections.Generic.List`1[[Barotrauma.CrewManager+OptionNode]]")
-- LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "CreateShortcutNodes")
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
    local Character = Character
    -- local fabricateItemsId = Identifier("sbai_fabricateitems")
    local Game = Game
    local HotPink = Color.HotPink
    local ignoreRoomOrderId = Identifier("sbai_ignoreroom")
    local One = Vector2.One
    local OptionNode = self:CreateStatic("Barotrauma.CrewManager+OptionNode")
    local OrderTargetTypeEntity = OrderPrefab.OrderTargetType.Entity
    local unignoreRoomOrderId = Identifier("sbai_unignoreroom")
    local Zero = Vector2.Zero

    local Any = util.itertools.Any
    local DoWithTemporaryRegistrations = util.DoWithTemporaryRegistrations
    local GetPointsOnCircumference = util.GetPointsOnCircumference
    local None = util.itertools.None

    local ignoredHulls = Types.Set.new(self:RegisterTable(nil, "ROUND_END")) --[[@type Types.Set<Barotrauma.Hull>]]
    local activeOrders --[=[@type Barotrauma.CrewManager.ActiveOrder[]]=]
    local optionNodes --[=[@type Barotrauma.CrewManager.OptionNode[]]=]
    local orderCategory --[[@type Barotrauma.OrderCategory]]
    local optionNode  --[[@type Barotrauma.CrewManager.OptionNode]]
    local sprite --[[@type Barotrauma.Sprite]]

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

    local offsets --[=[@type Microsoft.Xna.Framework.Vector2[]]=]
    local offsetIndex --[[@type integer]]

    self:AddPatch("Barotrauma.CrewManager", "CreateOrderCategoryNodes", nil,
    function(instance, ptable)
        offsets = GetPointsOnCircumference(Zero, instance.nodeDistance, #instance.availableCategories + 1, math.rad(197.5))
        offsetIndex = 1
    end, Hook.HookMethodType.Before)

    self:AddPatch("Barotrauma.CrewManager", "CreateOrderCategoryNode", nil,
    function(instance, ptable)
        if offsets then
            ptable["offset"] = offsets[offsetIndex].ToPoint()
            offsetIndex = offsetIndex + 1
        end
    end, Hook.HookMethodType.Before)

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

    local keyMap = {Keys.D0, Keys.D1, Keys.D2, Keys.D3, Keys.D4, Keys.D5, Keys.D6, Keys.D7, Keys.D8, Keys.D9}
    local prefabs = {}

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
                    order = prefab.CreateInstance(OrderTargetTypeEntity) --[[@type Barotrauma.Order]]
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

    -- local mainFrame = GUI.Frame(GUI.RectTransform(Vector2.One))
    -- LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Items.Components.Fabricator"], "OnResolutionChanged")
    -- LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Items.Components.Fabricator"], "ReloadGuiFrame")
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
            -- elseif id == fabricateItemsId then
            --     local frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1), mainFrame.RectTransform, GUI.Anchor.Center),"ItemUi")
            --     local closeButton = GUI.Button(GUI.RectTransform(Vector2(1, 1), frame.RectTransform, GUI.Anchor.Center), "", GUI.Alignment.Center, nil)
            --     local identifier = self.namespace()

                
            --     --order.TargetItemComponent.GuiFrame.RectTransform.Parent = frame.RectTransform
            --     order.TargetItemComponent.ReloadGuiFrame()
            --     order.TargetItemComponent.CreateGUI()

            --     order.TargetItemComponent.GuiFrame.RectTransform.Parent = frame.RectTransform

            --     self:AddPatch("Barotrauma.GameScreen", "AddToGUIUpdateList", nil,
            --     function(instance, ptable)
            --         frame.AddToGUIUpdateList()
            --     end, Hook.HookMethodType.Before)
            --     order.TargetItemComponent.OnResolutionChanged()
                

            --     closeButton.OnClicked = function()
            --         print("close")
            --         frame = nil
            --         Hook.RemovePatch(identifier, "Barotrauma.GameScreen", "AddToGUIUpdateList", Hook.HookMethodType.Before)
            --         order.TargetItemComponent.ReloadGuiFrame()
            --         order.TargetItemComponent.CreateGUI()
            --         order.TargetItemComponent.OnResolutionChanged()
            --     end

            end
        end
    end, Hook.HookMethodType.Before)
    
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

--     -- self:AddPatch("Barotrauma.AIObjectiveOperateItem", ".ctor", nil,
--     -- function(instance, ptable)
--     --     print("Hi")
--     --     print(ptable["character"].Name)
--     --     print(ptable["item"])
--     -- end, Hook.HookMethodType.Before)

--     LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.AIObjectiveManager"], "character")

--     local instrumentData = setmetatable({}, {
--         ---@param t {[Barotrauma.Identifier]:{slotTypes:Barotrauma.InvSlotType[]}}
--         ---@param k Barotrauma.Identifier
--         __index=function(t, k)
--             local prefab = ItemPrefab.Prefabs[k]

--             if prefab then
--                 local holdable = prefab.ConfigElement.GetChildElement("Holdable")
            
--                 if holdable then
--                     local slotString = holdable.GetAttributeString("slots")
                    
--                     if slotString then
--                         local allowedSlots = {}
--                         local i = 0
            
--                         for slotCombination in slotString:gmatch("([^,]+),?") do
--                             if slotCombination:lower() ~= "any" then
--                                 local slots = 0
            
--                                 i = i + 1
--                                 for specSlotString in slotCombination:gmatch("([^%+]+)%+?") do
--                                     specSlotString = specSlotString:match("(%a+)")
                                    
--                                     if specSlotString:lower() == "bothhands" then
--                                         slots = InvSlotType.LeftHand + InvSlotType.RightHand
--                                     end
            
--                                     slots = slots + InvSlotType[specSlotString]
--                                 end
--                                 allowedSlots[i] = slots
--                             end
--                         end
--                         if i > 0 then
--                             t[k] = {slotTypes=allowedSlots}
--                             return t[k]
--                         end
--                     end
--                 end
--             end
--             error("Unable to find instrument: "..k, 2)
--         end
--     })

--     self:AddPatch("Barotrauma.AIObjectiveManager", "CreateObjective", nil,
--     function(instance, ptable)
--         local order = ptable["order"] --[[@type Barotrauma.Order]]
--         local id = order.Identifier --[[@type Barotrauma.Identifier]]

--         if id:StartsWith(orderCategoryPrefix) then
--             if id == performId then
--                 local success, targetComponent = order.TryGetTargetItemComponent(order.TargetEntity, Components.RangedWeapon)
--                 local newObj = AIObjectiveOperateItem(targetComponent, instance.character, instance, "", true)
--                 newObj.Identifier = order.Identifier
                
                
--                 print(order.TargetEntity)
--                 print(order.TargetEntity.GetComponent(Components.RangedWeapon))
--                 --
--                 --local newObj = AIObjectiveGetItem(instance.character, order.Option, instance, true, true, nil, false)

                
--                 --newObj.EquipSlotType = instrumentData[order.Option]
--                 --newObj.Completed.add(
--                     return newObj
--             end
--         end
--     end, Hook.HookMethodType.Before)
    
--     local Contains = util.itertools.Contains

--     self:AddPatch("Barotrauma.Items.Components.ItemComponent", "CrewAIOperate", nil,
--     function(instance, ptable)
--         local obj = ptable["objective"]

--         if obj.Identifier == performId then
--             local item = instance.Item
--             local character = ptable["character"] --[[@type Barotrauma.Character]]

--             character.AIController.SteeringManager.Reset()
--             if  Contains(character.HeldItems, item) or
--                 character.inventory.TryPutItem(item, character, instrumentData[item.Prefab.Identifier].slotTypes, true, false)
--             then
--                 character.SetInput(InputType.Aim, false, true)
--                 character.SetInput(InputType.Shoot, false, true)
--             end
--             return true
--         end
--     end, Hook.HookMethodType.Before)

--     self:AddPatch("Barotrauma.AIObjectiveOperateItem", "get_AllowAutomaticItemUnequipping", nil,
--     function(instance, ptable)
--         if instance.Identifier == performId then
--             ptable.PreventExecution = true
--             return false
--         end
--     end, Hook.HookMethodType.Before)

    -- LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Items.Components.Fabricator"], "CreateGUI")
    

    -- self:AddPatch("Barotrauma.Items.Components.Fabricator", "CreateGUI", nil,
    -- function(instance, ptable)

    -- end, Hook.HookMethodType.After)
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