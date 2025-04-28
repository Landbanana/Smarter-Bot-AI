local SBAI = require("SBAI")
local util = require("SBAI.Shared.util")
local Config = require("SBAI.Shared.config")
local Constants = require("SBAI.Shared.constants")

local ForceUpperCase = LuaUserData.CreateEnumTable("Barotrauma.ForceUpperCase") --[[@type Barotrauma.ForceUpperCase]]

local descriptor = Descriptors["Barotrauma.GUITextBlock"]
LuaUserData.MakeMethodAccessible(descriptor, "MeasureText", {"System.String"})

descriptor = Descriptors["Barotrauma.RectTransform"]
LuaUserData.MakeFieldAccessible(descriptor, "ChildrenChanged")

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

local D_BIGBRAIN_SIZE = Point(120, 92)

local D_PADDING = 10

local D_WIDTH = 0.6
local D_HEIGHT = 0.6

local D_ICON_VH = 0.04

---@param component Barotrauma.GUIComponent
local function AssignColors(component)
    component.Color = D_COLOR
    component.HoverColor = D_COLOR_HOVER
    component.SelectedColor = D_COLOR_SELECTED
    component.DisabledColor = D_COLOR_DISABLED
    component.PressedColor = D_COLOR_PRESSED
    component.OutlineColor = D_COLOR_OUTLINE
end

---@param component Barotrauma.GUIButton|Barotrauma.GUITextBlock
local function AssignTextColors(component)
    component.TextColor = D_COLOR_TEXT
    component.HoverTextColor = D_COLOR_HOVER_TEXT
    component.SelectedTextColor = D_COLOR_SELECTED_TEXT
end

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
---@param anchor? Barotrauma.Anchor
---@param text? string
---@param style? string
---@param font? string
---@param alignment? Barotrauma.Alignment
---@param wrap? boolean
---@param ignoreColors? boolean
---@return Barotrauma.GUITextBlock
local function AddTextBlock(parent, size, anchor, text, style, font, alignment, wrap, ignoreColors)
    local textBlock = GUI.TextBlock(
        GUI.RectTransform(
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
    textBlock.ForceUpperCase = ForceUpperCase.No
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
local function AddButton(parent, size, anchor, text, style, ignoreColors, onClicked)
    local button = GUI.Button(
        GUI.RectTransform(
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
local function AddListBox(parent, size, anchor, style, isHorizontal, ignoreColors)
    local listBox = GUI.ListBox(
        GUI.RectTransform(
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
local function AddFrame(parent, size, anchor, style, ignoreColors)
    local frame = GUI.Frame(
        GUI.RectTransform(
            size,
            parent.rectTransform,
            anchor
        ),
        style or D_FRAME_STYLE
    )
    if not ignoreColors then AssignColors(frame) end
    return frame
end

---@param parent any
---@param size Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
---@param anchor? any
---@return Barotrauma.GUIComponent
local function AddInvisibleFrame(parent, size, anchor)
    local frame = GUI.Frame(
        GUI.RectTransform(
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
local function AddLayoutGroup(parent, size, anchor, pivot, isHorizontal, childAnchor)
    local group = GUI.LayoutGroup(
        GUI.RectTransform(
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
local function CutComponent(parent, size, anchor, pivot)
    local scissor = GUI.ScissorComponent(GUI.RectTransform(size, parent.RectTransform, anchor, pivot))
    scissor.CanBeFocused = false
    return scissor
end

local function AddTitleText(parent, text, font, noUnderline, ignoreColors)
    local canvas = GUI.Frame(GUI.RectTransform(parent.Rect.Size, GUI.Canvas.Instance))
    local textBlock = AddTextBlock(canvas, Vector2(1, 0), nil, text, nil, font, GUI.Alignment.CenterX, false, ignoreColors)
    local ySize = textBlock.Rect.Height
    local line = nil
    
    textBlock.Color = Color.Transparent
    
    if not noUnderline then
        line = AddFrame(canvas, Vector2(1, 0), nil, "HorizontalLine", ignoreColors)
        ySize = ySize + line.Rect.Height
    end
    
    local spacer = AddInvisibleFrame(canvas, Point(parent.Rect.Width, D_PADDING))

    ySize = ySize + spacer.Rect.Height

    local titleGroup = AddLayoutGroup(parent, Vector2(1, 0))

    titleGroup.RectTransform.Resize(Point(parent.Rect.Width, ySize), false)
    textBlock.RectTransform.Parent = titleGroup.RectTransform
    if line then line.RectTransform.Parent = titleGroup.RectTransform end
    spacer.RectTransform.Parent = titleGroup.RectTransform
    return titleGroup
end

local mainFrame --[[@type Barotrauma.GUIFrame?]]
local clickableSize --[[@type number?]]
local clickableSizePoint --[[@type number?]]

---@param frame Barotrauma.GUIFrame
local function UpdateClickableSizes(frame)
    clickableSize = math.clamp(D_ICON_VH/D_HEIGHT*frame.Rect.Height, 16, 60)
    clickableSizePoint = Point(clickableSize, clickableSize)
end

local function CloseSBAIMenu()
    if mainFrame then
        mainFrame.Parent.RemoveChild(mainFrame)
        mainFrame = nil
        clickableSize = nil
        clickableSizePoint = nil
    end
end

---@param optionsFrame Barotrauma.GUIFrame
---@param sectionName string
local function LoadSectionOptionsToGUI(optionsFrame, sectionName)
    optionsFrame.ClearChildren()
    
    local namespace = SBAI.namespace
    local xMax = optionsFrame.Rect.Width
    local xSpacing = 0 --[[@type number?]]
    local currentOptionCut --[[@type Barotrauma.GUIScissorComponent?]]
    -- local currentOption --[[@type string]]
    -- local currentValue --[[@type string|number|boolean|table]]

    local typeTable --[[@type table<OptionType|"table", fun(defaults:ConfigSection, option:table, value:`optionType`|table)>]]

    local match = string.match
    local endsWith = string.endsWith
    local sub = string.sub

    ---@param defaults ConfigSection|ConfigOption
    ---@param option string
    local function MakeNamedCut(defaults, option)
        local font = xSpacing > 0 and "SubHeadingFont" or "LargeFont"
        local xText = GUI.Style.Fonts[Identifier(font)].MeasureString(option..":", false).X + 2*D_PADDING

        currentOptionCut = CutComponent(optionsFrame, Point(xMax - xSpacing, clickableSize))
        currentOptionCut.RectTransform.Translate(Point(xSpacing, 0))

        local textBlock = AddTextBlock(currentOptionCut.Content, Point(xText, clickableSize), GUI.Anchor.CenterLeft, option..":", "", font, GUI.Alignment.Center, false, true)

        textBlock.ForceUpperCase = ForceUpperCase.No
        --textBlock.ToolTip = defaults.description
        
        local textTag = "GUI.tooltips."..match(namespace(), "^SBAI%.(.+)$")
        
        if endsWith(textTag, ".enable") then
            textTag = sub(textTag, 1, #textTag - 7)
        end

        if textTag ~= nil then textBlock.ToolTip = TextManager.get(textTag) end
    end

    ---@param defaults ConfigSection|ConfigOption
    ---@param option string
    ---@param value number
    ---@param optionType OptionType
    local function processNumber(defaults, option, value, optionType)
        MakeNamedCut(defaults, option)

        local configRef = util.config.Get(Config.data, -namespace)
        local key = namespace.stack[#namespace.stack]
        local numberInput = GUI.NumberInput(
            GUI.RectTransform(
                Point(2*clickableSize, clickableSize),
                currentOptionCut.Content.RectTransform,
                GUI.Anchor.CenterLeft
            ),
            optionType == Config.OPTION_TYPE.float and NumberType.Float or optionType == Config.OPTION_TYPE.int and NumberType.Int,
            nil,
            GUI.Alignment.Left
        )

        local zeroCheck = false
        local forcedDefault = false

        if optionType == Config.OPTION_TYPE.float then
            numberInput.MinValueFloat = defaults.min
            numberInput.MaxValueFloat = defaults.max
            numberInput.FloatValue = value

            ---@param numberIn Barotrauma.GUINumberInput
            numberInput.OnValueEntered = function(numberIn)
                if forcedDefault then
                    numberIn.FloatValue = defaults.value
                    forcedDefault = false
                end

                configRef[key] = numberIn.FloatValue
            end

            ---@param numberIn Barotrauma.GUINumberInput
            numberInput.OnValueChanged = function(numberIn)
                local oldZeroCheck = zeroCheck
                
                zeroCheck = numberIn.FloatValue == 0
                forcedDefault = forcedDefault or (oldZeroCheck and zeroCheck)
            end
        else
            numberInput.MinValueInt = defaults.min
            numberInput.MaxValueInt = defaults.max
            numberInput.IntValue = value
            
            ---@param numberIn Barotrauma.GUINumberInput
            numberInput.OnValueEntered = function(numberIn)
                if forcedDefault then
                    numberIn.IntValue = defaults.value
                    forcedDefault = false
                end

                configRef[key] = numberIn.IntValue
            end

            ---@param numberIn Barotrauma.GUINumberInput
            numberInput.OnValueChanged = function(numberIn)
                local oldZeroCheck = zeroCheck

                zeroCheck = numberIn.IntValue == 0
                forcedDefault = forcedDefault or (oldZeroCheck and zeroCheck)
            end
        end
        
        --AssignColors(numberInput)
        --numberInput.
        numberInput.RectTransform.Translate(Point(currentOptionCut.Content.GetChild(Int32(0)).Rect.Width, 0))
    end
    
    ---@param defaults ConfigSection|ConfigOption
    ---@param option string
    ---@param value `OptionType`|table
    local function LoadOptionsRecurse(defaults, option, value)
        namespace = namespace + option
        typeTable[defaults.optionType or "table"](defaults, option, value)
        namespace = -namespace
    end

    ---@type table<OptionType|"table", fun(defaults:ConfigSection|ConfigOption, option:table, value:`optionType`|table)>
    typeTable = {
        [Config.OPTION_TYPE.string]=function(defaults, option, value) --[[@cast value string]]
        
        end,
        [Config.OPTION_TYPE.float]=function(defaults, option, value) return processNumber(defaults, option, value, Config.OPTION_TYPE.float) end,
        [Config.OPTION_TYPE.int]=function(defaults, option, value) return processNumber(defaults, option, value, Config.OPTION_TYPE.int) end,
        [Config.OPTION_TYPE.boolean]=function(defaults, option, value) --[[@cast value boolean]]
            if option == "enable" then
                xSpacing = xSpacing - 4*D_PADDING
                MakeNamedCut(defaults, namespace.stack[#namespace.stack - 1])
                xSpacing = xSpacing + 4*D_PADDING
            else
                MakeNamedCut(defaults, option)
            end
            
            local configRef = util.config.Get(Config.data, -namespace)
            
            local key = namespace.stack[#namespace.stack]
            local button = AddButton(currentOptionCut.Content, clickableSizePoint, GUI.Anchor.CenterLeft, nil, "SwitchHorizontal", false,
            ---@param button Barotrauma.GUIButton
            ---@param obj any
            ---@return boolean
            function(button, obj)
                button.Selected = not button.Selected
                configRef[key] = button.Selected
                return button.Selected
            end)
            button.RectTransform.Translate(Point(currentOptionCut.Content.GetChild(Int32(0)).Rect.Width, 0))
            button.Selected = value
        end,
        ["table"]=function(defaults, option, value) --[[@cast value table]]
            xSpacing = xSpacing + 4*D_PADDING
            for k, v in pairs(defaults) do --[[@cast v ConfigSection|ConfigOption]]
                LoadOptionsRecurse(v, k, value[k])
            end
            xSpacing = xSpacing - 4*D_PADDING
        end
    }
    LoadOptionsRecurse(Config.defaults.CONFIG[sectionName], sectionName, Config.data[sectionName])
end

---@param sectionList Barotrauma.GUIListBox
local function LoadConfigSectionsToGUI(sectionList)
    local oldSelectionText = sectionList.SelectedComponent and sectionList.SelectedComponent.Text.SanitizedValue --[[@type Barotrauma.GUITextBlock]]

    sectionList.ClearChildren()
    for sectionName, _ in pairs(Config.defaults.CONFIG) do
        local sectionBlock = AddTextBlock(sectionList.Content, Point(sectionList.Content.Rect.Width, clickableSize), GUI.Anchor.TopLeft, sectionName, nil, "SubHeading", GUI.Alignment.Left, false)
        
        sectionBlock.Color = Color.Transparent
        sectionBlock.AutoScaleHorizontal = true
        sectionBlock.RectTransform.IsFixedSize = true
        if oldSelectionText and oldSelectionText == sectionName then
            sectionList.Select({sectionBlock})
            oldSelectionText = nil
        end
    end
end

---@param parent Barotrauma.GUIComponent
---@param sectionList Barotrauma.GUIListBox
---@param anchor Barotrauma.Anchor
---@return Barotrauma.GUIButton
local function AddLoadConfigButton(parent, sectionList, anchor)
    local button = AddButton(parent, clickableSizePoint, anchor or GUI.Anchor.TopLeft, nil, "GUIButtonRefresh", false,
    function()
        Config.Load()
        LoadConfigSectionsToGUI(sectionList)
    end)
    button.ToolTip = "Reload the saved config to GUI"
    return button
end

---@param parent Barotrauma.GUIComponent
---@param anchor Barotrauma.Anchor
---@return Barotrauma.GUIButton
local function AddSaveButton(parent, anchor)
    local button = AddButton(parent, clickableSizePoint, anchor or GUI.Anchor.TopLeft, nil, "SaveButton", false,
    function()
        Config.Save()
    end)
    
    button.ToolTip = "Save and apply config changes"
    return button
end

---@param parent Barotrauma.GUIComponent
---@param anchor Barotrauma.Anchor
---@return Barotrauma.GUIButton
local function AddCloseButton(parent, anchor)
    local button = AddButton(parent, clickableSizePoint, anchor or GUI.Anchor.TopRight, nil, "AlienButtonRed", true, CloseSBAIMenu)

    GUI.Image(
        GUI.RectTransform(
            button.Rect.Size,
            button.RectTransform
        ),
        "MissionFailedIcon",
        true
    ).CanBeFocused = false
    button.toolTip = "Close menu"
    return button
end

---@param parent Barotrauma.GUIComponent
local function MakeSBAIMenu(parent)
    local framePadding = Point(2*D_PADDING, 2*D_PADDING)

    mainFrame = AddFrame(parent, Vector2(D_WIDTH, D_HEIGHT), GUI.Anchor.Center, "ItemUI")
    
    UpdateClickableSizes(mainFrame)
    
    local mainInnerGroup = AddLayoutGroup(mainFrame, mainFrame.Rect.Size - Point(32, 45), GUI.Anchor.Center)
    mainInnerGroup.RectTransform.Translate(Point(-1, 5))

    local topFrame = AddFrame(mainInnerGroup, Point(mainInnerGroup.Rect.Width, clickableSize + framePadding.Y), nil, "UpgradeUIFrame", true)
    local topMiddleCut = CutComponent(topFrame, Point(2*clickableSize + 2*D_PADDING, topFrame.Rect.Height), GUI.Anchor.TopCenter)

    local combinedSettingsFrame = AddFrame(mainInnerGroup, Point(mainInnerGroup.Rect.Width, mainInnerGroup.Rect.Height - topFrame.Rect.Height))

    local sectionsScissor = CutComponent(combinedSettingsFrame, Point(combinedSettingsFrame.Rect.Width*0.3 - 1.5*D_PADDING, combinedSettingsFrame.Rect.Height - 2*D_PADDING))
    local optionsScissor = CutComponent(combinedSettingsFrame, Point(combinedSettingsFrame.Rect.Width*0.7 - 1.5*D_PADDING, combinedSettingsFrame.Rect.Height - 2*D_PADDING), GUI.Anchor.TopRight)

    sectionsScissor.RectTransform.AbsoluteOffset = Point(D_PADDING, D_PADDING)
    optionsScissor.RectTransform.AbsoluteOffset = Point(D_PADDING, D_PADDING)

    local sectionsTitle = AddTitleText(sectionsScissor.Content, "Section", "LargeFont")
    local optionsTitle = AddTitleText(optionsScissor.Content, "Options", "LargeFont")
    local titleYSize = optionsTitle.Rect.Height
    
    local sectionList = AddListBox(sectionsScissor.Content, Point(sectionsScissor.Content.Rect.Width, 8*clickableSize))
    local optionList = AddListBox(optionsScissor.Content, optionsScissor.Content.Rect.Size - Point(0, titleYSize))

    sectionList.ResizeContentToMakeSpaceForScrollBar = false
    optionList.ResizeContentToMakeSpaceForScrollBar = false

    sectionList.RectTransform.Translate(Point(0, titleYSize))
    optionList.RectTransform.Translate(Point(0, titleYSize))

    sectionList.RectTransform.IsFixedSize = true
    optionList.RectTransform.IsFixedSize = true

    local loadConfigButton = AddLoadConfigButton(topMiddleCut.Content, sectionList, GUI.Anchor.CenterLeft)
    local saveButton = AddSaveButton(topMiddleCut.Content, GUI.Anchor.CenterRight)
    local closeButton = AddCloseButton(topFrame, GUI.Anchor.CenterRight)
    closeButton.RectTransform.Translate(Point(-D_PADDING, 0))
    
    LoadConfigSectionsToGUI(sectionList)
    
    ---@param component Barotrauma.GUITextBlock
    ---@param _ System.Object
    ---@return boolean
    sectionList.OnSelected = function(component, _)
        LoadSectionOptionsToGUI(optionList.Content, component.Text.SanitizedValue)
        return true
    end

    local bottomRightCut = CutComponent(sectionsScissor.Content, Point(sectionsScissor.Rect.Width, sectionsScissor.Rect.Height - sectionList.Rect.Height - sectionsTitle.Rect.Height - D_PADDING), GUI.Anchor.BottomCenter)

    local bigBrain = GUI.Image(
        GUI.RectTransform(
            D_BIGBRAIN_SIZE,
            bottomRightCut.Content.RectTransform,
            GUI.Anchor.BottomCenter
        ),
        "BigBrain"
    )
    bigBrain.ToolTip = "big brain"
    
    local availableTextWidth = (bottomRightCut.Rect.Width - D_BIGBRAIN_SIZE.X - D_PADDING)/2

    AddTextBlock(bottomRightCut.Content, Point(availableTextWidth, 0), GUI.Anchor.CenterLeft, Constants.Name, nil, "MonospacedFont", GUI.Alignment.CenterX, true, true)
    AddTextBlock(bottomRightCut.Content, Point(availableTextWidth, 0), GUI.Anchor.CenterRight, Constants.Version, nil, "MonospacedFont", GUI.Alignment.CenterX, false, true)

    --combinedSettingsGroupH.AbsoluteSpacing = D_PADDING

    -- local sectionOptionDrag = GUI.DragHandle(
    --     GUI.RectTransform(
    --         Vector2(0.05, 1),
    --         combinedSettingsGroupH.RectTransform
    --     ),
    --     sectionFrame.RectTransform
    -- )

    -- print(sprite)    

    -- GUI.Image(
    --     GUI.RectTransform(
    --         Vector2(0.25, 0.25),
    --         mainGUIFrame.rectTransform,
    --         GUI.Anchor.Center
    --     ), sprite,
    --     rectangle,
    --     true
    -- )

    if  Game.IsMultiplayer and
        not Game.Client.HasPermission(ClientPermissions.ManageSettings)
    then
        mainFrame.Enabled = false
		for comp in mainFrame.GetAllChildren() do
			comp.enabled = false
		end
	end
end

---@param parent Barotrauma.GUIComponent
local function ShowSBAIMenu(parent)
    if not mainFrame then
        Config.Load()
        return MakeSBAIMenu(parent)
    end
end

---@param namespace Namespace
return function(namespace)
    Hook.Patch((namespace + "PauseMenuButton")(), "Barotrauma.GUI", "TogglePauseMenu", {}, function(instance, ptable)
        if GUI.GUI.PauseMenuOpen then
            local pauseFrame = GUI.GUI.PauseMenu.GetChild(Int32(1)) --[[@type Barotrauma.GUIFrame]]
            local layoutGroup = pauseFrame.GetChild(Int32(0)) --[[@type Barotrauma.GUILayoutGroup]]

            AddButton(layoutGroup, Vector2(1, 0.05), GUI.Anchor.BottomCenter, Constants.Name, "GUIButtonSmall", false,
            function()
                return ShowSBAIMenu(GUI.GUI.PauseMenu)
            end)

            local ySize = 0
            for component in layoutGroup.Children do
                ySize = ySize + component.Rect.Height + layoutGroup.AbsoluteSpacing
            end

            ySize = ySize/layoutGroup.RectTransform.RelativeSize.Y + layoutGroup.AbsoluteSpacing
            pauseFrame.RectTransform.MinSize = Point(pauseFrame.RectTransform.MinSize.X, math.max(ySize, pauseFrame.RectTransform.MinSize.Y))
        else
            CloseSBAIMenu()
        end
    end, Hook.HookMethodType.After)
end