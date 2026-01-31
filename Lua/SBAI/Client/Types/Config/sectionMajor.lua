---@namespace Config

---@class (partial) SectionMajor
---@field private _iconSprite? string|Barotrauma.Sprite
local ConfigSectionMajor = Types.Config.SectionMajor

---@public
---@param sprite? string|Barotrauma.Sprite
function ConfigSectionMajor:setIcon(sprite)
    self._iconSprite = sprite
end

local GUIHelper = Types.GUIHelper

do
    local ComponentState = GUIHelper.ComponentState
    local Point = Point
    local sizeIcon_A = GUIHelper.Sizes.Icon_A
    local sizeIconSmall_A = GUIHelper.Sizes.IconSmall_A
    local sizePadding_A = GUIHelper.Sizes.Padding_A
    local SubHeadingFont = GUI.Style.Fonts[Identifier("SubHeadingFont")] ---@as Barotrauma.GUIFont
    local SubHeadingFontLineHeight = SubHeadingFont.LineHeight
    

    local addFrame = GUIHelper.addFrame
    local addImage = GUIHelper.addImage
    local addSpacesBetween = Stringtools.addSpacesBetween
    local addTextBlock = GUIHelper.addTextBlock
    local max = math.max
    local MaxPoint = GUI.RectTransform.MaxPoint
    local round = Mathtools.round
    local rT = GUIHelper.rT
    local Vector2 = Vector2

    ---@param moduleListContent Barotrauma.GUIFrame
    ---@return Barotrauma.GUIFrame
    function ConfigSectionMajor:drawLabel(moduleListContent)
        local moduleFrameOuter, moduleFrameInner = addFrame(
            rT(
                Vector2(1, 0),
                moduleListContent,
                "TopCenter",
                "TopCenter",
                nil,
                Point(moduleListContent.Rect.Size.X, round(max(SubHeadingFontLineHeight, sizeIcon_A) + 2*sizePadding_A))
            ),
            "GUITextBlock",
            true,
            false
        )
        moduleFrameOuter.UserData = self

        local moduleIcon = addImage(
            rT(
                Point(sizeIcon_A, sizeIcon_A),
                moduleFrameInner,
                "CenterLeft",
                "CenterLeft",
                nil,
                true
            ),
            self._iconSprite,
            true,
            false
        )
        --moduleIcon.CanBeFocused = false
        
        local textBlockOffset = sizeIcon_A + sizePadding_A

        local textBlock = addTextBlock(
            rT(
                Vector2(1, 0),
                moduleFrameInner,
                "CenterLeft",
                "CenterLeft",
                nil,
                nil,
                Point(moduleFrameInner.Rect.Width - textBlockOffset - sizeIconSmall_A - sizePadding_A, MaxPoint.Y)
            ),
            "nil",
            true,
            true,
            false,
            addSpacesBetween(self.name, "%l", "%u"),
            "Left",
            true,
            "SubHeadingFont",
            false,
            false
        )
        --textBlock.AutoScaleVertical = true
        --textBlock.CanBeFocused = false
        textBlock.RectTransform.AbsoluteOffset = Point(textBlockOffset, 0)

        local enabledLight = addImage(
            rT(
                Point(sizeIconSmall_A, sizeIconSmall_A),
                moduleFrameInner,
                "CenterRight",
                "CenterRight",
                nil,
                true
            ),
            "IndicatorLightGreen",
            true,
            true
        )

        --enabledLight.CanBeFocused = false
        enabledLight.OverrideState = ComponentState[self.isEnabled and "Selected" or "None"]
        
        return moduleFrameOuter
    end
end

do
    local One = Vector2.One
    local ComponentState = GUIHelper.ComponentState
    local Point = Point
    local sizeIcon_A = GUIHelper.Sizes.Icon_A
    local sizeIconSmall_A = GUIHelper.Sizes.IconSmall_A
    local sizePadding_A = GUIHelper.Sizes.Padding_A
    local Vector2 = Vector2
    local LargeFont = GUI.Style.Fonts[Identifier("LargeFont")] ---@as Barotrauma.GUIFont
    local LargeFontLineHeight = LargeFont.LineHeight
    local ZeroV4 = Vector4.Zero
    
    local addButton = GUIHelper.addButton
    local addClosebutton = GUIHelper.addCloseButton
    local addDragHandle = GUIHelper.addDragHandle
    local addFrame = GUIHelper.addFrame
    local addIconButton = GUIHelper.addIconButton
    local addImage = GUIHelper.addImage
    local addLayoutGroup = GUIHelper.addLayoutGroup
    local addLine = GUIHelper.addLine
    local addListBox = GUIHelper.addListBox
    local addSpacer = GUIHelper.addSpacer
    local addSpacesBetween = Stringtools.addSpacesBetween
    local addTextBlock = GUIHelper.addTextBlock
    local cut = GUIHelper.cut
    local rT = GUIHelper.rT


    function ConfigSectionMajor:draw(parent)
        local parentRT = parent.RectTransform
        
        ConfigSectionMajor.super.draw(self, parent)
        return
    end
end

return Types.Config.SectionMajor