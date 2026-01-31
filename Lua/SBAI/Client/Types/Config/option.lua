---@class (partial) Config.Option<J:Json>
---@field protected _drawSetter fun(self, valueFrame:Barotrauma.GUIFrame)
local ConfigOption = Types.Config.Option

rawset(ConfigOption, "_drawSetter", Types.AbstractFunction)

local GUIHelper = Types.GUIHelper

do
    local LargeFont = GUI.Style.Fonts[Identifier("LargeFont")] ---@as Barotrauma.GUIFont
    local One = Vector2.One
    local Point = Point
    local sizeConfig = Vector2(GUIHelper.Sizes.Config_W, GUIHelper.Sizes.Config_H)
    local sizeIcon_A = GUIHelper.Sizes.Icon_A
    local sizeIconSmall_A = GUIHelper.Sizes.IconSmall_A
    local sizeItemUIHandle_A = GUIHelper.Sizes.ItemUIHandle_A
    local sizeLine_A = GUIHelper.Sizes.Line_A
    local sizePadding_A = GUIHelper.Sizes.Padding_A
    local SubHeadingFont = GUI.Style.Fonts[Identifier("SubHeadingFont")] ---@as Barotrauma.GUIFont
    local Vector2 = Vector2
    local ZeroV4 = Vector4.Zero

    local addButton = GUIHelper.addButton
    local addDragHandle = GUIHelper.addDragHandle
    local addFrame = GUIHelper.addFrame
    local addIconButton = GUIHelper.addIconButton
    local addImage = GUIHelper.addImage
    local addLayoutGroup = GUIHelper.addLayoutGroup
    local addLine = GUIHelper.addLine
    local addListBox = GUIHelper.addListBox
    local addSpacer = GUIHelper.addSpacer
    local addTextBlock = GUIHelper.addTextBlock
    local ceil = math.ceil
    local padInnerFrame = GUIHelper.padInnerFrame
    local rT = GUIHelper.rT
    local setPosition = GUIHelper.setPosition

    function ConfigOption:draw(parent)
        local compFrameOuter, compFrameInner = addFrame(
            rT(
                One,
                parent,
                "TopLeft",
                "TopLeft"
            ),
            "nil",
            false,
            false,
            nil
        )
        local OffsetX = 0

        local infoIcon---@[lsp_optimization("delayed_definition")]
        local updateIcon --[=[@[lsp_optimization("delayed_definition")]]=] do
            local sizeIconSmall = Point(sizeIconSmall_A, sizeIconSmall_A)
            local infoImageRT = rT(
                sizeIconSmall,
                compFrameInner,
                "TopLeft",
                "TopLeft",
                nil,
                true
            )
            local updateImageRT = rT(
                sizeIconSmall,
                compFrameInner,
                "TopLeft",
                "TopLeft",
                nil,
                true
            )

            infoIcon = addImage(
                infoImageRT,
                "WorkshopMenu.InfoButton",
                true,
                true
            )
            infoImageRT.AbsoluteOffset = Point(OffsetX, 0)
            OffsetX = OffsetX + sizeIconSmall_A + sizePadding_A

            updateIcon = addImage(
                updateImageRT,
                "WorkshopMenu.InfoButtonUpdate",
                true,
                true
            )
            updateImageRT.AbsoluteOffset = Point(OffsetX, 0)
            OffsetX = OffsetX + sizeIconSmall_A + sizePadding_A

            infoIcon.Visible = false
            updateIcon.Visible = false
        end

        local keyTextBlock --[=[@[lsp_optimization("delayed_definition")]]=] do 
            local keyText = self.name..":"
            local keyTextSizeX = ceil(SubHeadingFont.MeasureString(keyText, false).X)
            
            keyTextBlock = addTextBlock(
                rT(
                    Point(keyTextSizeX, 0),
                    compFrameInner,
                    "TopLeft",
                    "TopLeft",
                    nil,
                    true
                ),
                nil,
                true,
                true,
                false,
                keyText,
                "TopLeft",
                false,
                "SubHeadingFont",
                false,
                false
            )
            keyTextBlock.Padding = ZeroV4
            OffsetX = OffsetX + keyTextSizeX
        end
        local valueFrameOuter---@[lsp_optimization("delayed_definition")]
        local valueFrameInner --[=[@type Barotrauma.GUIFrame]=] do
            valueFrameOuter, valueFrameInner = addFrame(
                rT(
                    Point(parent.Rect.Width - OffsetX, keyTextBlock.Rect.Height),
                    compFrameInner,
                    "TopLeft",
                    "TopLeft",
                    nil,
                    true
                ),
                "nil",
                false,
                false,
                nil
            )
        end

        self:_drawSetter(valueFrameInner)
        valueFrameOuter.InheritTotalChildrenHeight()

        return compFrameOuter
    end
end

return Types.Config.Option