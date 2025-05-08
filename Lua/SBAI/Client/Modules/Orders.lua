local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

local activateShared, deactivateShared, ID_ORDER = require("SBAI.Shared.Modules.Orders")

LuaUserData.RegisterType("Barotrauma.CrewManager+OptionNode")
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

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.AIObjectiveManager"], "character")

local IGNORE_ROOM = ID_ORDER.IGNORE_ROOM
local FABRICATE_ITEMS = ID_ORDER.FABRICATE_ITEMS
local PERFORM = ID_ORDER.PERFORM
local SBAI_CATEGORY = ID_ORDER.SBAI_CATEGORY
local UNIGNORE_ROOM = ID_ORDER.UNIGNORE_ROOM

local orderCategoryPrefix = SBAI_CATEGORY.Value.."_" --[[@type string]]

---@param self Types.Module
local function activate(self)
    local AIObjectiveOperateItem = AIObjectiveOperateItem
    local Character = Character
    -- local fabricateItemsId = Identifier("sbai_fabricateitems")
    local HotPink = Color.HotPink
    local One = Vector2.One
    local OptionNode = self.Statics["Barotrauma.CrewManager+OptionNode"]
    local OrderPrefab = OrderPrefab
    local OrderTargetTypeEntity = OrderPrefab.OrderTargetType.Entity
    local performId = Identifier("sbai_perform")
    local RangedWeapon = Components.RangedWeapon
    local Sprite = Sprite
    local TextManager = TextManager
    local Zero = Vector2.Zero

    local Any = util.itertools.Any
    
    local GetPointsOnCircumference = util.GetPointsOnCircumference
    local None = util.itertools.None
    local sort = table.sort

    local optionNodes --[=[@type Barotrauma.CrewManager.OptionNode[]]=]
    local optionNode  --[[@type Barotrauma.CrewManager.OptionNode]]
    local orderCategory --[[@type Barotrauma.OrderCategory]]
    local sprite --[[@type Barotrauma.Sprite]]

    local ignoredHulls = activateShared(self)

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

    -- self:RegisterStrongRef("Game.GameSession.CrewManager", "ActiveOrders", "System.Collections.Generic.List`1[[Barotrauma.CrewManager+ActiveOrder]]", true, false,
    -- function(strongRef)
    --     for activeOrder in strongRef do
    --         local curOrder = activeOrder.Order --[[@type Barotrauma.Order]]
    
    --         if curOrder.Identifier == IGNORE_ROOM then
    --             ignoredHulls:Add(curOrder.TargetEntity)
    --         end
    --     end
    -- end)

    self:RegisterStrongRef("Game.GameSession.CrewManager.optionNodes", "System.Collections.Generic.List`1[[Barotrauma.CrewManager+OptionNode]]", nil,
    function(strongRef)
        optionNodes = strongRef
    end)

    -- self:AddInit(
    -- function()
    --     local session = Game.GameSession

    --     if not session then return end
    --     activeOrders = GetStrongRef(function() return session.CrewManager.ActiveOrders end,
    --     "System.Collections.Generic.List`1[[Barotrauma.CrewManager+ActiveOrder]]")

    --     optionNodes = GetStrongRef(function() return session.CrewManager.optionNodes end,
    --     "System.Collections.Generic.List`1[[Barotrauma.CrewManager+OptionNode]]")

    --     for activeOrder in activeOrders do
    --         local curOrder = activeOrder.Order --[[@type Barotrauma.Order]]

    --         if curOrder.Identifier == IGNORE_ROOM then
    --             ignoredHulls:Add(curOrder.TargetEntity)
    --         end
    --     end

    --     -- DoWithTemporaryRegistrations({
    --     --     "System.Collections.Generic.List`1[[Barotrauma.CrewManager+ActiveOrder]]",
    --     --     "System.Collections.Generic.List`1[[Barotrauma.CrewManager+OptionNode]]"
    --     -- },
    --     -- function()
    --     --     optionNodes = session.CrewManager.optionNodes
    --     --     activeOrders = session.CrewManager.ActiveOrders
    --     --     for activeOrder in activeOrders do
    --     --         local curOrder = activeOrder.Order --[[@type Barotrauma.Order]]

    --     --         if curOrder.Identifier == ignoreRoomOrderId then
    --     --             ignoredHulls:Add(curOrder.TargetEntity)
    --     --         end
    --     --     end
    --     -- end)
    -- end)

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
        local tooltip = TextManager.Get("ordercategorytitle."..SBAI_CATEGORY.Value)

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
                    if  (id == IGNORE_ROOM and
                        (targetHull == nil or
                        targetHull.Submarine.TeamID ~= currentCharacter.TeamID or
                        ignoredHulls[targetHull])) or
                        (id == UNIGNORE_ROOM and
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

            sort(prefabs, function(p1, p2) return p1.Identifier < p2.Identifier end)

            local order
            local disableNode
            local offsets = GetPointsOnCircumference(Zero, instance.nodeDistance, instance.GetCircumferencePointCount(i), instance.GetFirstNodeAngle(i))

            for j=1,i,1 do
                local prefab = prefabs[j]
                local id = prefab.Identifier

                if  id == IGNORE_ROOM or
                    id == UNIGNORE_ROOM
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
            if  id == IGNORE_ROOM or
                id == UNIGNORE_ROOM
            then
                local currentCharacter = Character.Controlled
                local targetHull = currentCharacter.CurrentHull

                if  targetHull ~= nil and
                    targetHull.Submarine.TeamID == currentCharacter.TeamID
                then
                    instance.AddOrder(order.Clone().WithTargetEntity(targetHull))
                end

            -- elseif id == FABRICATE_ITEMS then
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

    self:AddPatch("Barotrauma.AIObjectiveManager", "CreateObjective", nil,
    function(instance, ptable)
        local order = ptable["order"] --[[@type Barotrauma.Order]]
        local id = order.Identifier --[[@type Barotrauma.Identifier]]

        if id:StartsWith(orderCategoryPrefix) then
            if id == performId then
                ptable.PreventExecution = true

                local targetItemComponent = order.TargetItemComponent or order.TargetEntity.GetComponent(RangedWeapon)
                local newObj = AIObjectiveOperateItem(targetItemComponent, instance.character, instance, order.Option, true)

                newObj.Identifier = order.Identifier

                -- ---@param operateObj Barotrauma.AIObjective
                -- ---@return boolean
                -- function newObj.AbortCondition(operateObj)
                --     return false
                -- end
                
                return newObj
            end
        end
    end, Hook.HookMethodType.Before)

    -- LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Items.Components.Fabricator"], "CreateGUI")
    

    -- self:AddPatch("Barotrauma.Items.Components.Fabricator", "CreateGUI", nil,
    -- function(instance, ptable)

    -- end, Hook.HookMethodType.After)
end

return Types.Module.new(activate, deactivateShared)