local util = require("SBAI.Shared.util")
local guiUtil = {}
guiUtil.Constants = {}

LuaUserData.RegisterType("Barotrauma.GUIColor")

local PlusButtonStyle
local MinusButtonStyle
local RectTransform = GUI.RectTransform
local RandomizeSprite = Sprite("Content/UI/UIAtlasGeneral.png", Rectangle(436,772,46,46), Vector2(0.5, 0.5))

local ForceUpperCase = LuaUserData.CreateEnumTable("Barotrauma.ForceUpperCase") --[[@type Barotrauma.ForceUpperCase]]
local MapEntityCategory = LuaUserData.CreateEnumTable("Barotrauma.MapEntityCategory") --[[@type Barotrauma.MapEntityCategory]]
local DragMode = LuaUserData.CreateEnumTable("Barotrauma.GUIListBox+DragMode") --[[@type Barotrauma.GUIListBox.DragMode]]

local D_BUTTON_TEXT_ALIGN = GUI.Alignment.Center
local D_BUTTON_STYLE = "GUIButton"
local D_FRAME_STYLE = "GUIFrame"
local D_LISTBOX_STYLE = "GUIListBox"

local D_COLOR = Color(235, 225, 193)
local D_COLOR_HOVER = Color(255, 245, 213)
local D_COLOR_SELECTED = Color(215, 205, 173)
local D_COLOR_DISABLED = Color(100, 100, 100)
local D_COLOR_PRESSED = Color(128, 129, 83)
local D_COLOR_OUTLINE = Color(50, 50, 50)

local D_COLOR_TEXT = Color(225, 221, 184)
local D_COLOR_HOVER_TEXT = Color(245, 241, 204)
local D_COLOR_SELECTED_TEXT = Color(205, 201, 164)

guiUtil.Constants.ForceUpperCase = ForceUpperCase
guiUtil.Constants.ScaleBasis = LuaUserData.CreateEnumTable("Barotrauma.ScaleBasis") --[[@type Barotrauma.ScaleBasis]]

guiUtil.Constants.D_PADDING = 10
guiUtil.Constants.D_SLOT_SIZE = 55
guiUtil.Constants.D_CATEGORY_SIZE = 35

guiUtil.Constants.D_WIDTH = 0.6
guiUtil.Constants.D_HEIGHT = 0.6

guiUtil.Constants.D_ICON_VH = 0.04

local D_PADDING = guiUtil.Constants.D_PADDING
local D_SLOT_SIZE = guiUtil.Constants.D_SLOT_SIZE
local D_CATEGORY_SIZE = guiUtil.Constants.D_CATEGORY_SIZE

do
    local numberInput = GUI.NumberInput(RectTransform(Point(guiUtil.Constants.D_PADDING, guiUtil.Constants.D_PADDING)), NumberType.Int)

    
    PlusButtonStyle = numberInput.PlusButton.Style
    MinusButtonStyle = numberInput.MinusButton.Style

    PlusButtonStyle.Element.FirstElement().SetAttributeValue("maintainaspectratio", "false")
    MinusButtonStyle.Element.FirstElement().SetAttributeValue("maintainaspectratio", "false")
end

---@param component Barotrauma.GUIComponent
local function AssignColors(component)
    component.Color = D_COLOR
    component.HoverColor = D_COLOR_HOVER
    component.SelectedColor = D_COLOR_SELECTED
    component.DisabledColor = D_COLOR_DISABLED
    component.PressedColor = D_COLOR_PRESSED
    component.OutlineColor = D_COLOR_OUTLINE
end
guiUtil.AssignColors = AssignColors

---@param component Barotrauma.GUIButton|Barotrauma.GUITextBlock
local function AssignTextColors(component)
    component.TextColor = D_COLOR_TEXT
    component.HoverTextColor = D_COLOR_HOVER_TEXT
    component.SelectedTextColor = D_COLOR_SELECTED_TEXT
end
guiUtil.AssignTextColors = AssignTextColors

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
---@param anchor? Barotrauma.Anchor
---@param text? string
---@param style? string
---@param font? string
---@param alignment? Barotrauma.Alignment
---@param wrap? boolean
---@param ignoreColors? boolean
---@param forceUpperCase? boolean
---@return Barotrauma.GUITextBlock
function guiUtil.AddTextBlock(parent, size, anchor, text, style, font, alignment, wrap, ignoreColors, forceUpperCase)
    local textBlock = GUI.TextBlock(
        RectTransform(
            size,
            parent.RectTransform,
            anchor
        ),
        text or "",
        nil,
        font and GUI.Style.Fonts[Identifier(font)],
        alignment or GUI.Alignment.Center,
        wrap
    )
    if not ignoreColors then
        AssignColors(textBlock)
        AssignTextColors(textBlock)
    end
    if not forceUpperCase then textBlock.ForceUpperCase = ForceUpperCase.No end
    return textBlock
end

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
---@param anchor? Barotrauma.Anchor
---@param text? string
---@param style? string
---@param ignoreColors? boolean
---@param onClicked? fun(button: Barotrauma.GUIButton, obj: any):boolean
---@return Barotrauma.GUIButton
function guiUtil.AddButton(parent, size, anchor, text, style, ignoreColors, onClicked)
    if style == "null" then
        style = nil
    else
        style = style or D_BUTTON_STYLE
    end

    local button = GUI.Button(
        RectTransform(
            size,
            parent ~= nil and parent.rectTransform or nil,
            anchor
        ),
        text or "",
        D_BUTTON_TEXT_ALIGN,
        style
    )
    if not ignoreColors then
        AssignColors(button)
        AssignTextColors(button)
    end
    button.ForceUpperCase = ForceUpperCase.No
    button.OnClicked = onClicked
    return button
end

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
---@param anchor? Barotrauma.Anchor
---@param style? string
---@param isHorizontal? boolean
---@param ignoreColors? boolean
---@return Barotrauma.GUIListBox
function guiUtil.AddListBox(parent, size, anchor, style, isHorizontal, ignoreColors)
    if style == "null" then
        style = nil
    else
        style = style or D_LISTBOX_STYLE
    end

    local listBox = GUI.ListBox(
        RectTransform(
            size,
            parent.rectTransform,
            anchor
        ),
        isHorizontal,
        nil,
        style,
        true,
        true
    )
    if not ignoreColors then AssignColors(listBox) end
    return listBox
end

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
---@param anchor? Barotrauma.Anchor
---@param style? string
---@param ignoreColors? boolean
---@return Barotrauma.GUIFrame
function guiUtil.AddFrame(parent, size, anchor, style, ignoreColors)
    if style == "null" then
        style = nil
    else
        style = style or D_FRAME_STYLE
    end
    

    local frame = GUI.Frame(
        RectTransform(
            size,
            parent.rectTransform,
            anchor
        ),
        style
        
    )
    if not ignoreColors then AssignColors(frame) end
    return frame
end

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
---@param anchor? Barotrauma.Anchor
---@return Barotrauma.GUIComponent
function guiUtil.AddInvisibleFrame(parent, size, anchor)
    local frame = GUI.Frame(
        RectTransform(
            size,
            parent.rectTransform,
            anchor
        )
    )
    frame.Visible = false
    return frame
end

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
---@param anchor? Barotrauma.Anchor
---@param pivot? Barotrauma.Pivot
---@param isHorizontal? boolean
---@param childAnchor? Barotrauma.Anchor
---@return Barotrauma.GUILayoutGroup
function guiUtil.AddLayoutGroup(parent, size, anchor, pivot, isHorizontal, childAnchor)
    local group = GUI.LayoutGroup(
        RectTransform(
            size,
            parent.rectTransform,
            anchor,
            pivot
        ),
        isHorizontal,
        childAnchor
    )
    return group
end

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
---@param anchor? Barotrauma.Anchor
---@param pivot? Barotrauma.Pivot
---@return Barotrauma.GUIScissorComponent
function guiUtil.CutComponent(parent, size, anchor, pivot)
    local scissor = GUI.ScissorComponent(RectTransform(size, parent.RectTransform, anchor, pivot))
    
    scissor.CanBeFocused = false
    return scissor
end

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
---@param anchor? Barotrauma.Anchor
---@param sprite Barotrauma.Sprite|string
---@param scaleToFit? boolean
---@return Barotrauma.GUIImage
function guiUtil.AddImage(parent, size, anchor, sprite, scaleToFit)
    return GUI.Image(
        RectTransform(
            size,
            parent.rectTransform,
            anchor
        ),
        sprite,
        scaleToFit == true
    )
end

do
    local betterSlotSprite = Sprite("Content/UI/InventoryUIAtlas.png", Rectangle(13, 10, 114, 114), nil, 0)

    ---@param parent Barotrauma.GUIComponent
    ---@param anchor? Barotrauma.Anchor
    ---@param slotType? Barotrauma.InvSlotType
    ---@param makeButton? boolean
    ---@return Barotrauma.GUIImage|Barotrauma.GUIButton
    function guiUtil.AddEmptyItemSlot(parent, anchor, slotType, makeButton)
        local size = Point(D_SLOT_SIZE, D_SLOT_SIZE)
        local buttonOrParent

        if makeButton then
            buttonOrParent = guiUtil.AddButton(parent, size, anchor, nil, "null")
            size = Vector2.One
            anchor = GUI.Anchor.Center
            
        else
            buttonOrParent = parent
        end

        local slotImage = guiUtil.AddImage(buttonOrParent, size, anchor, betterSlotSprite, true)
        local invSlotGetter

        if makeButton then
            invSlotGetter = buttonOrParent
            slotImage.CanBeFocused = false
            slotImage.UserData = D_PADDING
        else
            invSlotGetter = slotImage
        end

        if slotType and slotType ~= InvSlotType.None then
            local invSlotImage = guiUtil.AddImage(slotImage, Vector2.One, nil, CharacterInventory.LimbSlotIcons[slotType], true)

            invSlotImage.Color = GUI.Style.EquipmentSlotIconColor.Value
            invSlotImage.HoverColor = Color.PaleGoldenrod
            --slotImage.SelectedColor = GUI.Style.EquipmentSlotIconColor.Value

            invSlotImage.CanBeFocused = false
            invSlotGetter.UserData = slotType
        else
            invSlotGetter.UserData = InvSlotType.Any
        end
        slotImage.SelectedColor = GUI.Style.EquipmentSlotIconColor.Value
        slotImage.HoverColor = Color.PaleGoldenrod
        return invSlotGetter
    end
end

-- ---@param slot Barotrauma.GUIImage
-- function guiUtil.AddButtonToItemSlot(slot)
--     local parent = slot.Parent

--     --slot.GlowOnSelect = true
--     slot.HoverColor = Color.PaleGoldenrod

--     local i = parent.GetChildIndex(slot) + 1

--     parent.RemoveChild(slot)

--     local moveChildren = {} --[[@type Barotrauma.GUIComponent[]|fun():Barotrauma.GUIComponent]]
--     local k = 0
--     local j = 0
--     for child in parent.GetAllChildren() do
--         j = j + 1
--         if j >= i then
--             k = k + 1
--             moveChildren[k] = child
--         end
--     end

--     local button = guiUtil.AddButton(parent, slot.Rect.Size, slot.RectTransform.Anchor, nil, "null")

--     for child in moveChildren do
--         child.SetAsLastChild()
--     end

--     slot.RectTransform.Parent = button.RectTransform
--     slot.CanBeFocused = false
--     button.UserData = slot.UserData
--     return button
-- end

---@param slot Barotrauma.GUIButton|Barotrauma.GUIImage
---@param itemData {prefab:Barotrauma.ItemPrefab, quality:integer?, quantity:integer?}
---@param prefab? Barotrauma.ItemPrefab
---@return Barotrauma.GUIImage
function guiUtil.AddItemToSlot(slot, itemData, prefab)
    prefab = prefab or itemData.prefab

    local oldToolTip = prefab.GetTooltip().ToString()
    local itemName, itemDescription = oldToolTip:match("^([^\n]+)(\n.+)$")

    if itemName then
        slot.ToolTip = RichString.Rich(itemName.." (ID: "..prefab.Identifier.Value..")"..itemDescription)
    else
        slot.ToolTip = RichString.Rich(oldToolTip.." (ID: "..prefab.Identifier.Value..")")
    end
    
    local itemImage = guiUtil.AddImage(slot, Vector2(0.95, 0.95), GUI.Anchor.Center, prefab.InventoryIcon or prefab.Sprite, true)

    itemImage.UserData = itemData or prefab
    itemImage.CanBeFocused = false
    return slot
end


do
    local n = -1

    for _ in next, MapEntityCategory do
        n = n + 1
    end

    ---@param parent Barotrauma.GUIComponent
    ---@param anchor? Barotrauma.Anchor
    ---@param callback? fun()
    ---@return Barotrauma.GUIListBox
    function guiUtil.AddItemCategoryList(parent, anchor, callback)
        local sizeRatio = math.min((parent.Rect.Height - D_CATEGORY_SIZE)/(n*D_CATEGORY_SIZE), 1)
        local categoryButtonSize = Point(sizeRatio*D_CATEGORY_SIZE, sizeRatio*D_CATEGORY_SIZE)
        local listSize = Point(2*categoryButtonSize.X, math.ceil(n/2)*categoryButtonSize.Y)
        local list = guiUtil.AddListBox(parent, listSize, anchor, "GUIListBoxNoBorder", false, true)
        list.Content.RectTransform.Resize(listSize)
        list.UseGridLayout = true
        list.ScrollBarEnabled = false
        list.Spacing = 0
        list.Padding = Vector4(0,0,0,0)
        list.ContentBackground.Visible = false
        -- local group = guiUtil.AddLayoutGroup(parent, Point(2*categoryButtonSize.X, parent.Rect.Height), anchor, nil, true, GUI.Anchor.CenterLeft)
        -- local group1 = guiUtil.AddLayoutGroup(group, Point(categoryButtonSize.X, group.Rect.Height), anchor, nil, false, GUI.Anchor.TopCenter)
        -- local group2 = guiUtil.AddLayoutGroup(group, Point(categoryButtonSize.X, group.Rect.Height), anchor, nil, false, GUI.Anchor.TopCenter)

        --list.RectTransform.AbsoluteOffset = Point(D_PADDING, D_PADDING)
        list.Content.UserData = MapEntityCategory.None

        for category, value in next, MapEntityCategory, "None" do
            local button = guiUtil.AddButton(list.Content, categoryButtonSize, nil, nil, "CategoryButton."..category, true)

            button.ToolTip = TextManager.Get("MapEntityCategory."..category)
            button.UserData = value
        end
        guiUtil.MakeButtonsExclusive(list.Content, MapEntityCategory.None, callback)
        return list
    end
end

do
    ---@param allButtons Barotrauma.GUIButton
    ---@param default any
    ---@param button Barotrauma.GUIButton
    ---@param obj any
    ---@return boolean
    local function exclusiveCheck(allButtons, default, button, obj)
        local parent = button.Parent

        if obj == parent.UserData then
            parent.UserData = default
            button.Selected = false
            return false
        else
            parent.UserData = obj
            for otherButton in allButtons do
                otherButton.Selected = otherButton.UserData == obj
            end
            return true
        end
    end

    ---@param parent Barotrauma.GUIComponent
    ---@param default any
    ---@param onClicked? fun(button:Barotrauma.GUIButton, obj:any):boolean
    function guiUtil.MakeButtonsExclusive(parent, default, onClicked)
        local allButtons = {}
        local i = 0
        local _exclusiveCheck = util.functools.Partial2(exclusiveCheck, allButtons, default)

        for button in parent.GetAllChildren(GUI.Button) do --[[@cast button Barotrauma.GUIButton]]
            i = i + 1
            allButtons[i] = button

            if onClicked then
                ---@param button Barotrauma.GUIButton
                ---@param obj any
                ---@return boolean
                button.OnClicked = function(button, obj)
                    local out = _exclusiveCheck(button, obj)

                    onClicked(button, obj)
                    return out
                end
            else
                button.OnClicked = _exclusiveCheck
            end
        end
    end
end

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
---@param anchor? Barotrauma.Anchor
---@param enumerator fun():Barotrauma.ItemPrefab
---@param n integer
---@return Barotrauma.ItemPrefab?
function guiUtil.AddItemPickerRow(parent, size, anchor, enumerator, n)
    -- local group = guiUtil.AddLayoutGroup(parent, size, anchor, nil, true, GUI.Anchor.CenterLeft)
    -- group.AbsoluteSpacing = D_PADDING

    local hList = guiUtil.AddListBox(parent, size, anchor, "GUIListBoxNoBorder", true, true)

    --hList.Padding = Vector4(0,0,0,0)
    hList.CurrentDragMode = DragMode.DragOutsideBox
    hList.ScrollBarEnabled = false
    --hList.KeepSpaceForScrollBar = false
    --hList.ResizeContentToMakeSpaceForScrollBar = false
    hList.Spacing = D_PADDING/2
    --hList.RemoveChild(hList.ScrollBar)
    hList.Content.RectTransform.Resize(size)
    --hList.ContentBackground.Visible = false
    hList.HideChildrenOutsideFrame = false
    
    local prefab

    for j=1,n,1 do
        prefab = enumerator()

        if prefab == nil then break end

        local slot = guiUtil.AddEmptyItemSlot(hList.Content, GUI.Anchor.TopLeft)

        guiUtil.AddItemToSlot(slot, prefab)
    end

    return prefab
end

---@param parent Barotrauma.GUIComponent
---@param selectedSlots table<Barotrauma.InvSlotType, Set<Barotrauma.GUIButton>>
---@param callback fun(button: Barotrauma.GUIButton, itemData:{prefab:Barotrauma.ItemPrefab?, quality:integer?, quantity:integer?})
---@return Barotrauma.GUILayoutGroup
---@return fun(filter:fun(prefab:Barotrauma.ItemPrefab):boolean)
function guiUtil.AddItemPicker(parent, selectedSlots, callback)
    local innerGroup = guiUtil.AddLayoutGroup(parent, parent.Rect.Size - Point(2*D_PADDING, 2*D_PADDING), GUI.Anchor.TopLeft, nil, false, GUI.Anchor.TopCenter)
    local topBarGroup = guiUtil.AddLayoutGroup(innerGroup, Point(innerGroup.Rect.Width, 3*D_PADDING), GUI.Anchor.TopCenter, nil, true, GUI.Anchor.Center)
    local bodyGroup = guiUtil.AddLayoutGroup(innerGroup, Point(innerGroup.Rect.Width, innerGroup.Rect.Height - topBarGroup.Rect.Height), GUI.Anchor.Center, nil, true, GUI.Anchor.TopLeft)
    
    local orderedPrefabList = {} --[[@type Iterable<Barotrauma.ItemPrefab>]]
    local categoryList
    local searchBox
    local list
    local _filter = util.True

    do
        local i = 0

        for prefab in ItemPrefab.Prefabs do
            if  prefab.Name.Value:len() > 0 then
                i = i + 1
                orderedPrefabList[i] = prefab
            end
        end

        table.sort(orderedPrefabList, function(p1, p2) return p1.Name < p2.Name end)
    end

    
    
    local function reload()
        list.ClearChildren()
        
        local enumerator
        
        do
            local HasFlag = util.mathtools.HasFlag
            local yield = coroutine.yield
            
            enumerator = coroutine.wrap(
            function()
                local selectedCategory = categoryList.Content.UserData
                local searchtext = searchBox.Text:lower()

                if searchtext:len() > 0 then
                    if selectedCategory == MapEntityCategory.None then
                        for prefab in orderedPrefabList do
                            if  prefab.Name.Value:lower():match(searchtext) and
                                _filter(prefab)
                            then
                                yield(prefab)
                            end
                        end
                    else
                        for prefab in orderedPrefabList do
                            if  HasFlag(prefab.Category, selectedCategory) and
                                prefab.Name.Value:lower():match(searchtext) and
                                _filter(prefab)
                            then
                                yield(prefab)
                            end
                        end
                    end
                else
                    if selectedCategory == MapEntityCategory.None then
                        for prefab in orderedPrefabList do
                            if _filter(prefab) then
                                yield(prefab)
                            end
                        end
                    else
                        for prefab in orderedPrefabList do
                            if  HasFlag(prefab.Category, selectedCategory) and
                                _filter(prefab)
                            then
                                yield(prefab)
                            end
                        end
                    end
                end
            end)
        end

        for prefab in enumerator do
            guiUtil.AddItemToSlot(guiUtil.AddEmptyItemSlot(list.Content, GUI.Anchor.TopLeft), nil, prefab).UserData = prefab
        end
    end

    ---@param filter fun(prefab:Barotrauma.ItemPrefab):boolean
    local function setFilter(filter)
        _filter = filter or util.True
        reload()
    end

    categoryList = guiUtil.AddItemCategoryList(bodyGroup, GUI.Anchor.TopLeft, reload)

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

    ---@param component Barotrauma.GUIComponent
    ---@param obj Barotrauma.ItemPrefab
    list.AfterSelected = function(component, obj)
        local slots = {} --[[@type Iterable<Set<Barotrauma.GUIButton>>]]
        local i = 0

        if #selectedSlots <= 0 then return end
        
        for elementName in {"//Holdable", "//Wearable", "//Pickable", "//MeleeWeapon", "//Throwable"} do
            for holdable in util.xPath2(obj.ConfigElement.Element, elementName) do
                for slotGroup in holdable.Attribute("slots").Value:gmatch("([^,]+),?") do
                    local slotType

                    for addedSlot in slotGroup:gmatch("([^%+]+)%+?") do
                        slotType = InvSlotType[addedSlot]

                        local matchingSlots = selectedSlots[slotType]

                        if  not matchingSlots or
                            matchingSlots:IsEmpty()
                        then
                            slots = {}
                            i = 0
                            break
                        end
                        i = i + 1
                        slots[i] = matchingSlots
                    end
                    if i > 0 then
                        local itemData = {prefab=obj}

                        for set in slots do
                            local button = next(set) --[[@type Barotrauma.GUIButton]]
                            
                            selectedSlots[slotType]:Remove(button)
                            button.GetChildByUserData(D_PADDING).Color = Color.White
                            button.ToolTip = nil
                            guiUtil.AddItemToSlot(button, itemData)
                            callback(button, itemData)
                        end
                        return
                    end
                end
            end
        end
    end
    
    --list.HideDraggedElement = true

    searchBox = guiUtil.AddSearchBar(topBarGroup, GUI.Anchor.Center, reload)

    reload()
    return innerGroup, setFilter
end

---@param parent Barotrauma.GUIComponent
---@param anchor? Barotrauma.Anchor
---@param callback? fun(button:Barotrauma.GUIButton, obj:any):boolean
function guiUtil.AddSearchBar(parent, anchor, callback)
    local textBox = GUI.TextBox(
        RectTransform(
            Point(D_SLOT_SIZE*4, D_SLOT_SIZE/2),
            parent.RectTransform,
            anchor
        ),
        nil,
        nil,
        nil,
        GUI.Alignment.CenterLeft,
        false,
        "",
        nil,
        true,
        true
    )

    if callback then textBox.OnTextChangedDelegate = callback end
    return textBox
end

-- ---@param parent Barotrauma.GUIComponent
-- ---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
-- ---@param anchor? Barotrauma.Anchor
-- ---@param includeRandomOption? boolean
-- ---@param ... Barotrauma.ItemPrefab
-- ---@return Barotrauma.GUISelectionCarousel
-- function guiUtil.AddItemCarousel(parent, size, anchor, includeRandomOption, ...)
--     local ids = {} --[=[@type Barotrauma.Identifier[]]=]
--     local icons = {} --[=[@type Barotrauma.Sprite[]]=]
--     local max = 0 --[[@type integer]]
--     local i = 1

--     for prefab in {...} do --[[@cast prefab Barotrauma.ItemPrefab]]
--         max = max + 1
--         ids[max] = prefab.Identifier
--         icons[max] = prefab.InventoryIcon or prefab.Sprite
--     end

--     local frame = guiUtil.AddFrame(parent, size, anchor, "InnerFrameDark", true)
--     --local slotGroup = guiUtil.AddLayoutGroup(frame, Vector2.One, GUI.Anchor.Center, nil, nil, GUI.Anchor.CenterLeft)
--     --local innerFrame = guiUtil.AddFrame(slotGroup, Point(size.X, size.X), nil, "InnerFrameDark")

--     if max == 0 then return frame end

--     if  (includeRandomOption == nil or
--         includeRandomOption == true) and
--         max > 1
--     then
--         max = max + 1
--         ids[max] = Identifier.Empty
--         icons[max] = RandomizeSprite
--     end

--     local icon = GUI.Image(RectTransform(Vector2(0.9, 0.9), frame.RectTransform, GUI.Anchor.Center), icons[i], false)
--     local leftButton = guiUtil.AddButton(icon, Vector2(0.5, 1), GUI.Anchor.CenterLeft, "<", "null", true)
--     local rightButton = guiUtil.AddButton(icon, Vector2(0.5, 1), GUI.Anchor.CenterRight, ">", "null", true)

--     for button in {leftButton, rightButton} do --[[@cast button Barotrauma.GUIButton]]
--         button.Font = GUI.Style.Fonts[Identifier("LargeFont")]
--         button.TextBlock.TextColor = Color.Ivory
--         button.TextBlock.SelectedTextColor = Color.DarkGray
--         button.TextBlock.HoverTextColor = Color.Gray
--     end

--     leftButton.TextBlock.TextAlignment = GUI.Alignment.CenterLeft
--     rightButton.TextBlock.TextAlignment = GUI.Alignment.CenterRight

--     leftButton.OnClicked = function(button, obj)
--         i = (i == 1) and max or (i - 1)
--         icon.Sprite = icons[i]
--         frame.UserData = ids[i]
--         return false
--     end

--     rightButton.OnClicked = function(button, obj)
--         i = (i == max) and 1 or (i + 1)
--         icon.Sprite = icons[i]
--         frame.UserData = ids[i]
--         return false
--     end

--     leftButton.RectTransform.RelativeOffset = Vector2(-0.1, 0)
--     rightButton.RectTransform.RelativeOffset = Vector2(-0.1, 0)
    

--     -- button.UserData = 1
--     -- button.OnClicked = function(self, selection)
--     --     selection = selection == max and 1 or (selection + 1)
--     --     icon.Sprite = icons[selection]
--     --     self.UserData = selection
--     -- end
    
    
--     --topButton.ApplyStyle(PlusButtonStyle)
--     --bottomButton.ApplyStyle(MinusButtonStyle)


--     -- topButton.RectTransform.RelativeSize = Vector2(0.75, 0.05)
--     -- bottomButton.RectTransform.RelativeSize = Vector2(0.75, 0.05)
--     -- 
--     -- local topButton
--     -- 
--     -- local bottomButton

    
--     --local icon = GUI.Image(RectTransform(Vector2.One, carousel.RectTransform, GUI.Anchor.Center), ItemPrefab.GetItemPrefab("poop").Sprite, false)
--     --icon.CanBeFocused = false

    
-- end

do
    local function doUserData(button, obj)
        for f in obj do
            f(button, obj)
        end
    end

    local function basicClose(button, obj)
        local parent = button.Parent

        if parent then
            local grandParent = parent.Parent

            if grandParent then
                grandParent.RemoveChild(parent)
            end
        end
    end

    ---@param parent Barotrauma.GUIComponent
    ---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
    ---@param anchor Barotrauma.Anchor
    ---@return Barotrauma.GUIButton
    function guiUtil.AddCloseButton(parent, size, anchor)
        local button = guiUtil.AddButton(parent, size, anchor or GUI.Anchor.TopRight, nil, "AlienButtonRed", true)

        guiUtil.AddImage(button, Vector2.One, nil, "MissionFailedIcon", true).CanBeFocused = false
        button.ToolTip = TextManager.Get("GUI.tooltips.button.closemenu")
        button.OnClicked = doUserData
        button.UserData = {[1]=basicClose}
        return button
    end
end

return guiUtil