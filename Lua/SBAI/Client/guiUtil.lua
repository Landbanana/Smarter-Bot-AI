local guiUtil = {}
guiUtil.Constants = {}

local RectTransform = GUI.RectTransform

local ForceUpperCase = LuaUserData.CreateEnumTable("Barotrauma.ForceUpperCase") --[[@type Barotrauma.ForceUpperCase]]

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

guiUtil.Constants.D_WIDTH = 0.6
guiUtil.Constants.D_HEIGHT = 0.6

guiUtil.Constants.D_ICON_VH = 0.04

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
        text,
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
    local button = GUI.Button(
        RectTransform(
            size,
            parent.rectTransform,
            anchor
        ),
        text,
        D_BUTTON_TEXT_ALIGN,
        style or D_BUTTON_STYLE
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
    local listBox = GUI.ListBox(
        RectTransform(
            size,
            parent.rectTransform,
            anchor
        ),
        isHorizontal,
        nil,
        style or D_LISTBOX_STYLE,
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

---@param parent any
---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
---@param anchor? any
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

return guiUtil