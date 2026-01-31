---@namespace Config

---@class (partial) Section
---@field public draw fun(self, parent:Barotrauma.GUIComponent)
local ConfigSection = Types.Config.Section

do

    function ConfigSection:draw(parent)
        return self:_drawChildren(parent)
    end
end

do
    local GUIHelper = Types.GUIHelper

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

    ---@protected
    ---@param parent Barotrauma.GUIComponent
    function ConfigSection:_drawChildren(parent)
        local parentRT = parent.RectTransform

        -- local rowLayout_H = addLayoutGroup(
        --     rT(
        --         Vector2(1, 1),
        --         parentRT,
        --         "TopLeft",
        --         "TopLeft"
        --     ),
        --     "TopLeft",
        --     sizePadding_A,
        --     true,
        --     false
        -- )
        
        for c in self --[=[@as fun():(Option|Section)]=] do
        --     local cFrameRT = rT(
        --         Vector2(1,0.1),
        --         parentRT,
        --         "TopLeft",
        --         "TopLeft",
        --         nil,
        --         nil,
        --         Point(parentRT.Rect.Width, parentRT.MaxPoint.Y)
        --     )
        --     --cFrameRT.AbsoluteOffset = Point(0, offset)
        --     local cFrame = addFrame(
        --         cFrameRT,
        --         "nil",
        --         false,
        --         false,
        --         nil
        --     )
            
            --offsetY = offsetY + sizeIcon_A

            c:draw(addFrame(
                rT(
                    Vector2(1, 0.1),
                    parent,
                    "TopLeft",
                    "TopLeft"
                ),
                "GUIFrame",
                false,
                false,
                nil
            ))

            
            -- local newFrame = addFrame(
            --     rT(
            --         One,
            --         parentRT,
            --         "TopLeft",
            --         "TopLeft",
            --         nil,
            --         nil,
            --         parentRT.Rect.Size - Point(offsetX, offsetY)
            --     ),
            --     "nil",
            --     false,
            --     false,
            --     0
            -- )  q 
            -- c:draw(,,
            --     maxW - sizeIcon_A
            -- )
        end
        

    end
end


return Types.Config.Section