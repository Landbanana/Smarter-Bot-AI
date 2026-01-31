local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

local activateShared, deactivateShared = table.unpack(require("SBAI.Shared.Modules.Orders"))
if Game.IsSingleplayer then
    deactivateShared = nil
end

do
    local MakeFieldAccessible = LuaUserData.MakeFieldAccessible
    local MakeMethodAccessible = LuaUserData.MakeMethodAccessible
    local AutoRegisterType = util.AutoRegisterType
    local Descriptors = Descriptors
    local descriptor

    AutoRegisterType("Barotrauma.CrewManager+OptionNode")
    AutoRegisterType("Barotrauma.Order+OrderTargetType")

    MakeFieldAccessible(Descriptors["Barotrauma.Hull"], "avoidStaying")

    --LuaUserData.RegisterType("System.Collections.Generic.List`1[[Barotrauma.CrewManager+OptionNode]]")
    -- LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CrewManager"], "CreateShortcutNodes")
    descriptor = Descriptors["Barotrauma.CrewManager"]
    MakeFieldAccessible(descriptor, "nodeDistance")
    MakeFieldAccessible(descriptor, "availableCategories")
    MakeFieldAccessible(descriptor, "optionNodes")
    MakeFieldAccessible(descriptor, "isContextual")
    MakeFieldAccessible(descriptor, "commandFrame")
    MakeFieldAccessible(descriptor, "contextualOrders")
    MakeFieldAccessible(descriptor, "hullContext")
    MakeFieldAccessible(descriptor, "wallContext")
    MakeFieldAccessible(descriptor, "characterContext")
    MakeFieldAccessible(descriptor, "itemContext")
    MakeFieldAccessible(descriptor, "nodeSize")
    MakeMethodAccessible(descriptor, "GetFirstNodeAngle")
    MakeMethodAccessible(descriptor, "GetTargetSubmarine")
    MakeMethodAccessible(descriptor, "CreateShortcutNodes")
    MakeMethodAccessible(descriptor, "CanCharacterBeHeard")
    MakeMethodAccessible(descriptor, "GetFirstNodeAngle")
    MakeMethodAccessible(descriptor, "GetCircumferencePointCount")
    MakeMethodAccessible(descriptor, "IsOrderAvailable", {"Barotrauma.OrderPrefab"})
    MakeMethodAccessible(descriptor, "CreateOrderCategoryNodes")
    MakeMethodAccessible(descriptor, "CreateOrderCategoryNode")
    MakeMethodAccessible(descriptor, "CreateOrderNodes")
    MakeMethodAccessible(descriptor, "CreateOrderNode")
    MakeMethodAccessible(descriptor, "CreateNodes")
    MakeMethodAccessible(descriptor, "CreateNodeIcon",
    {"Microsoft.Xna.Framework.Vector2", "Barotrauma.RectTransform", "Barotrauma.Sprite", "Microsoft.Xna.Framework.Color", "Barotrauma.LocalizedString"})
    

    MakeFieldAccessible(Descriptors["Barotrauma.AIObjectiveManager"], "character")
end

local ID_ORDER = Constants.ID_ORDER

local IGNORE_ROOM = ID_ORDER.IGNOREROOM
local FABRICATE_ITEMS = ID_ORDER.FABRICATEITEMS
local FORALL = ID_ORDER.FORALL
local PERFORM = ID_ORDER.PERFORM
local SBAI_CATEGORY = ID_ORDER.SBAICATEGORY
local UNIGNORE_ROOM = ID_ORDER.UNIGNORE_ROOM

local orderCategoryPrefix = SBAI_CATEGORY.Value.."_" --[[@type string]]

---@param self Types.Module
local function activateOrderGui(self)
    local Character = Character
    -- local fabricateItemsId = Identifier("sbai_fabricateitems")
    local HotPink = Color.HotPink
    local One = Vector2.One
    local OptionNode = self:RegisterStatic("Barotrauma.CrewManager+OptionNode")
    local OrderPrefabs = OrderPrefab.Prefabs
    local OrderTargetTypeEntity = OrderPrefab.OrderTargetType.Entity
    local Sprite = Sprite
    local TextManager = TextManager
    local Zero = Vector2.Zero

    local Any = util.itertools.Any
    local GetPointsOnCircumference = util.mathtools.GetPointsOnCircumference
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
    
    self:RegisterStrongRef("Game.GameSession.CrewManager.optionNodes", "System.Collections.Generic.List`1[[Barotrauma.CrewManager+OptionNode]]", "Barotrauma.CrewManager",
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

    

    do
        local rad = math.rad
        local yield = coroutine.yield

        local addCategory = coroutine.wrap(
        function()
            while true do
                local state, offsets = yield()
                
                if state == 1 then
                    local i = 1
                    
                    state = yield(true)
                    
                    while state == 2 do
                        state = yield(offsets[i].ToPoint())
                        i = i + 1
                    end
                    yield(true)
                    yield(offsets[i].ToPoint(), i)
                end
            end
        end)
        addCategory()

        self:AddPatch("Barotrauma.CrewManager", "CreateOrderCategoryNodes", nil,
        function(instance, ptable)
            addCategory(1, GetPointsOnCircumference(Zero, instance.nodeDistance, #instance.availableCategories + 1, rad(197.5)))
        end, Hook.HookMethodType.Before)

        self:AddPatch("Barotrauma.CrewManager", "CreateOrderCategoryNode", nil,
        function(instance, ptable)
            local offset = addCategory(2)
            
            if offset then
                ptable["offset"] = offset
            end
        end, Hook.HookMethodType.Before)

        self:AddPatch("Barotrauma.CrewManager", "CreateOrderCategoryNodes", nil,
        function(instance, ptable)
            if addCategory(3) then
                instance.CreateOrderCategoryNode(orderCategory, addCategory())

                local optionNodes = instance.optionNodes

                optionNode = optionNodes[#optionNodes]
            end

            local tooltip = TextManager.Get("ordercategorytitle."..SBAI_CATEGORY.Value)

            instance.CreateNodeIcon(One, optionNode.Button.RectTransform, sprite, HotPink, tooltip)

            local button = optionNode.Button --[[@type Barotrauma.GUIButton]]

            button.GetChild(Int32(button.CountChildren - 2)).RectTransform.SetAsLastChild() --[[@type Barotrauma.GUIImage]]
        end, Hook.HookMethodType.After)
    end

    local keyMap = {Keys.D0, Keys.D1, Keys.D2, Keys.D3, Keys.D4, Keys.D5, Keys.D6, Keys.D7, Keys.D8, Keys.D9}
    local prefabs = {}

    self:AddPatch("Barotrauma.CrewManager", "CreateOrderNodes", nil,
    function(instance, ptable)
        if ptable["orderCategory"] == orderCategory then
            local currentCharacter = Character.Controlled
            local targetHull = currentCharacter.CurrentHull

            ptable.PreventExecution = true

            local i = 0

            for prefab in OrderPrefabs do
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

    -- local forAllFuncMap = {
    --     Identifier("")
    -- }
    
    self:AddPatch("Barotrauma.CrewManager", "SetCharacterOrder", nil,
    function(instance, ptable)
        local order = ptable["order"] --[[@type Barotrauma.Order]]
        local id = order.Identifier

        
        if id:StartsWith(orderCategoryPrefix) then
            local currentCharacter = Character.Controlled

            if  id == IGNORE_ROOM or
                id == UNIGNORE_ROOM
            then
                local targetHull = currentCharacter.CurrentHull

                if  targetHull ~= nil and
                    targetHull.Submarine.TeamID == currentCharacter.TeamID
                then
                    instance.AddOrder(order.Clone().WithTargetEntity(targetHull))
                end
            elseif id == FORALL then
                local itemContainer = order.TargetItemComponent --[[@type Barotrauma.Items.Components.ItemContainer]]

                for item in itemContainer.Inventory:SBAI_findAllItems(false, true,
                function(inventory, item)
                end) do
                    
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

    

    -- LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Items.Components.Fabricator"], "CreateGUI")
    

    -- self:AddPatch("Barotrauma.Items.Components.Fabricator", "CreateGUI", nil,
    -- function(instance, ptable)

    -- end, Hook.HookMethodType.After)
end

---@param self Types.Module
local function activatePerformOrder(self)
    local AIObjectiveOperateItem = AIObjectiveOperateItem
    local RangedWeapon = Components.RangedWeapon

    self:AddPatch("Barotrauma.AIObjectiveManager", "CreateObjective", nil,
    function(instance, ptable)
        local order = ptable["order"] --[[@type Barotrauma.Order]]
        local id = order.Identifier --[[@type Barotrauma.Identifier]]

        if id:StartsWith(orderCategoryPrefix) then
            if id == PERFORM then
                ptable.PreventExecution = true

                local targetItemComponent = order.TargetItemComponent or order.TargetEntity.GetComponent(RangedWeapon)
                local newObj = AIObjectiveOperateItem(targetItemComponent, instance.character, instance, order.Option, true)

                newObj.Identifier = PERFORM
                
                return newObj
            end
        end
    end, Hook.HookMethodType.Before)
end

local function activate(self)
    self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")
    -- if Game.IsMultiplayer then
    --     local session = Game.GameSession

    --     if session then
    --         local networking = require("SBAI.Shared.networking")

    --         Networking.Receive(networking.MSG.ORDER_UPDATE,
    --         ---@param msg Barotrauma.Networking.IReadMessage
    --         ---@param client Barotrauma.Networking.Client
    --         function(msg, client)
    --             if msg.ReadBoolean() then
    --                 session.CrewManager.ClientReadActiveOrders(msg)
    --             end
                
    --             activateOrderGui(self)
    --         end)
    --         networking.member:Send(networking.MSG.ORDER_REQUEST)
    --     else
    --         activateOrderGui(self)
    --     end
    -- else
    --     activateOrderGui(self)
    -- end
    activateOrderGui(self)
    activatePerformOrder(self)
end

return Types.Module.new(activate, deactivateShared)