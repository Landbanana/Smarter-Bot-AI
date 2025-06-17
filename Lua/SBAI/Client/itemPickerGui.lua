local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")
local guiUtil = require("SBAI.Client.guiUtil")
local ItemSlot = require("SBAI.Client.itemSlotGui")

local ForceUpperCase = guiUtil.Constants.ForceUpperCase

local D_PADDING = guiUtil.Constants.D_PADDING
local D_SLOT_SIZE = guiUtil.Constants.D_SLOT_SIZE

local D_WIDTH = guiUtil.Constants.D_WIDTH
local D_HEIGHT = guiUtil.Constants.D_HEIGHT

local D_ICON_VH = guiUtil.Constants.D_ICON_VH

local RectTransform = GUI.RectTransform

local MapEntityCategory = LuaUserData.CreateEnumTable("Barotrauma.MapEntityCategory") --[[@type Barotrauma.MapEntityCategory]]

---@param parent Barotrauma.GUIComponent
---@param callback fun(itemPrefab?:Barotrauma.ItemPrefab, tag?:Barotrauma.Identifier)
---@param filter? fun(prefab:Barotrauma.ItemPrefab):boolean
---@return Barotrauma.GUILayoutGroup
---@return Iterable<Barotrauma.OrderPrefab>
local function createItemPickerGui(parent, callback, filter)
    local innerGroup = guiUtil.AddLayoutGroup(parent, parent.Rect.Size - Point(2*D_PADDING, 2*D_PADDING), GUI.Anchor.TopLeft, nil, false, GUI.Anchor.TopCenter)
    local topBarGroup = guiUtil.AddLayoutGroup(innerGroup, Point(innerGroup.Rect.Width, 3*D_PADDING), GUI.Anchor.TopCenter, nil, true, GUI.Anchor.Center)
    local bodyGroup = guiUtil.AddLayoutGroup(innerGroup, Point(innerGroup.Rect.Width, innerGroup.Rect.Height - topBarGroup.Rect.Height), GUI.Anchor.Center, nil, true, GUI.Anchor.TopLeft)
    
    local orderedPrefabList --[[@type Iterable<Barotrauma.ItemPrefab>]]
    local categoryList
    local searchBox
    local list

    local reload do
        local onSecondaryClicked do
            ---@param o1 Barotrauma.ContextMenuOption
            ---@param o2 Barotrauma.ContextMenuOption
            ---@return boolean
            local function tagSort(o1, o2)
                return o1.Label.Value < o2.Label.Value
            end

            local Contains = util.itertools.Contains
            local ContextMenuOption = GUI.ContextMenuOption
            local CreateBuilder = util.itertools.CreateBuilder
            local CreateContextMenu = GUI.ContextMenu.CreateContextMenu
            local Partial1 = util.functools.Partial1
            local sort = table.sort

            local ID_COMMON = Constants.ID_COMMON

            local callbackTag = Partial1(callback, nil)

            ---@param mainButton Barotrauma.GUIButton
            ---@param itemSlot ItemSlot
            ---@return boolean
            function onSecondaryClicked(mainButton, itemSlot)
                local itemPrefab = itemSlot:GetItemPrefab()

                if itemPrefab then
                    local optionTags = ContextMenuOption("sp.item.tags.name", true)
                    local subOptionTags, builder = CreateBuilder()

                    for tag in itemPrefab.Tags do --[[@cast tag Barotrauma.Identifier]]
                        if not Contains(ID_COMMON, tag) then
                            local tagOption = ContextMenuOption(tag.Value, true, Partial1(callbackTag, tag))

                            tagOption.Label = tag.Value
                        
                            builder(tagOption)
                        end
                    end

                    if next(subOptionTags) then
                        sort(subOptionTags, tagSort)
                        optionTags.SubOptions = subOptionTags
                    else
                        optionTags.IsEnabled = false
                    end

                    return CreateContextMenu(optionTags)
                end
            end
        end

        local TopLeft = GUI.Anchor.TopLeft

        local HasFlag = util.mathtools.HasFlag
        local new = ItemSlot.new
        local wrap = coroutine.wrap
        local yield = coroutine.yield

        function reload()
            list.ClearChildren()

            local enumerator = wrap(
            function()
                local selectedCategory = categoryList.Content.UserData
                local searchtext = searchBox.Text:lower()

                if searchtext:len() > 0 then
                    if selectedCategory == MapEntityCategory.None then
                        for prefab in orderedPrefabList do
                            if prefab.Name.Value:lower():match(searchtext) then
                                yield(prefab)
                            end
                        end
                    else
                        for prefab in orderedPrefabList do
                            if  HasFlag(prefab.Category, selectedCategory) and
                                prefab.Name.Value:lower():match(searchtext)
                            then
                                yield(prefab)
                            end
                        end
                    end
                else
                    if selectedCategory == MapEntityCategory.None then
                        for prefab in orderedPrefabList do
                            yield(prefab)
                        end
                    else
                        for prefab in orderedPrefabList do
                            if HasFlag(prefab.Category, selectedCategory) then
                                yield(prefab)
                            end
                        end
                    end
                end
            end)

            local Content = list.Content

            for prefab in enumerator do
                local slot = new(Content, TopLeft, nil, nil, orderedPrefabList)
                slot:SetItemPrefab(prefab)

                slot:SetOnSecondaryClicked(onSecondaryClicked)
            end
        end
    end
    local setCategoryFilter

    categoryList, setCategoryFilter = guiUtil.AddItemCategoryList(bodyGroup, GUI.Anchor.TopLeft, reload)

    bodyGroup.RectTransform.Resize(Point(bodyGroup.Rect.Width, categoryList.Rect.Height), false)
    innerGroup.RectTransform.Resize(Point(innerGroup.Rect.Width, categoryList.Rect.Height + topBarGroup.Rect.Height), false)
    innerGroup.RectTransform.AbsoluteOffset = Point(D_PADDING, D_PADDING)

    list = guiUtil.AddListBox(bodyGroup, Point(bodyGroup.Rect.Width - categoryList.Rect.Width, categoryList.Rect.Height), nil, nil, false, true)
    list.KeepSpaceForScrollBar = true
    --list.HideChildrenOutsideFrame = false
    list.UseGridLayout = true
    list.Spacing = D_PADDING
    --list.CurrentDragMode = DragMode.DragOutsideBox
    list.Padding = Vector4(D_PADDING, D_PADDING, D_PADDING, D_PADDING)

    ---@param button Barotrauma.GUIButton
    ---@param itemSlot ItemSlot
    list.AfterSelected = function(button, itemSlot)
        -- if #selectedSlots <= 0 then return end
        callback(itemSlot:GetItemPrefab())
        -- local slots = {} --[[@type Iterable<Set<Barotrauma.GUIButton>>]]
        -- local i = 0
        
        -- for slotComp in util.xPath(obj.ConfigElement.Element, "//[@slots]") do
        --     for slotGroup in slotComp.GetAttributeString("slots"):gmatch("([^,]+),?") do
        --         local slotType

        --         for addedSlot in slotGroup:gmatch("([^%+]+)%+?") do
        --             slotType = InvSlotType[addedSlot]

        --             local matchingSlots = selectedSlots[slotType]

        --             if  not matchingSlots or
        --                 matchingSlots:IsEmpty()
        --             then
        --                 slots = {}
        --                 i = 0
        --                 break
        --             end
        --             i = i + 1
        --             slots[i] = matchingSlots
        --         end
        --         if i > 0 then
        --             local itemData = {id=obj.Identifier}

        --             for set in slots do
        --                 local button = next(set) --[[@type Barotrauma.GUIButton]]
                        
        --                 selectedSlots[slotType]:Remove(button)
        --                 button.GetChildByUserData(D_PADDING).Color = Color.White
        --                 button.ToolTip = nil
        --                 guiUtil.AddItemToSlot(button, itemData, obj)
        --                 callback(button, itemData)
        --             end
        --             return
        --         end
        --     end
        -- end
    end
    searchBox = guiUtil.AddSearchBar(topBarGroup, GUI.Anchor.Center, reload)

    do
        local bor = bit32.bor
        local sort = table.sort

        local categoryFlags = 0
        local builder

        orderedPrefabList, builder = util.itertools.CreateBuilder()

        if filter == nil then
            for prefab in ItemPrefab.Prefabs do
                if prefab.Name.Value:len() > 0 then
                    builder(prefab)
                    categoryFlags = bor(categoryFlags, prefab.Category)
                end
            end
        else
            for prefab in ItemPrefab.Prefabs do
                if  prefab.Name.Value:len() > 0 and
                    filter(prefab)
                then
                    builder(prefab)
                    categoryFlags = bor(categoryFlags, prefab.Category)
                end
            end
        end

        sort(orderedPrefabList, function(p1, p2) return p1.Name < p2.Name end)
        setCategoryFilter(categoryFlags)
        reload()
    end

    return innerGroup, orderedPrefabList
end

-- ---@return Barotrauma.GUIFrame
-- local function createItemPickerGui(size)
--     local screenSize = Game.GameScreen.Frame.Rect.Size

--     local mainFrame = GUI.Frame(RectTransform(Point(screenSize.X*0.4, screenSize.Y*0.6), nil, GUI.Anchor.Center), "ItemUI")
--     guiUtil.AssignColors(mainFrame)

--     local dragHandle = GUI.DragHandle(RectTransform(Vector2.One, mainFrame.RectTransform, GUI.Anchor.Center), mainFrame.RectTransform, nil)

--     local innerFrame = guiUtil.AddFrame(mainFrame, mainFrame.Rect.Size - Point(2*D_PADDING, 4*D_PADDING), GUI.Anchor.Center, "InnerFrameDark", true)
--     innerFrame.RectTransform.AbsoluteOffset = Point(0, D_PADDING/2)
    
--     AddItemPicker2(innerFrame, nil)
    
--     return mainFrame
-- end

return createItemPickerGui