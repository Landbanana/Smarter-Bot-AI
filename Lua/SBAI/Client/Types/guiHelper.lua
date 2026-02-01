do
    local GUI = GUI

    ---@class GUIHelper: Object
    ---@field public cls GUIHelper
    ---@field public canvas Barotrauma.GUICanvas
    ---@field protected Colors GUIHelper.Colors
    ---@field protected Sizes GUIHelper.Sizes
    ---@field package rectTransform? Barotrauma.RectTransform
    Types.GUIHelper = Types.new("GUIHelper", "Object")
end

local GUIHelper = Types.GUIHelper

---@enum (key) GUIHelper.Sizes
GUIHelper.Sizes = {
    Padding_A = Mathtools.round(3/7*GUI.GUIStyle.ItemFrameTopBarHeight),
    Slot = 55,
    Category = 35,
    Config_W = 0.6,
    Config_H = 0.6,
    Max_A = 2^31 - 1,
    Line_A = GUI.GUIStyle.GetComponentStyle("VerticalLine").Width,
    Icon_A = Mathtools.round(3/2*GUI.GUIStyle.ItemFrameTopBarHeight),
    IconSmall_A = Mathtools.round(3/4*GUI.GUIStyle.ItemFrameTopBarHeight),
    ItemUIHandle_A = Mathtools.round(GUI.GUIStyle.ItemFrameTopBarHeight)
} ---@readonly

do
    local weigh = Functools.partial1(Vector3.Dot, Vector3(0.2126, 0.7152, 0.0722)) ---@as fun(rgb:Microsoft.Xna.Framework.Vector3):(number)

    ---@source https://stackoverflow.com/a/56678483
    ---@param color Microsoft.Xna.Framework.Color
    ---@return number
    ---@nodiscard
    function GUIHelper.colorToLuminance(color)
        local rgb = color.ToVector3()

        for c in ("XYZ"):gmatch("[XYZ]") do
            local v = rgb[c]

            rgb[c] = v <= 0.04045 and (v/12.92) or (((v + 0.055)/1.055)^2.4)
        end
        local Y = weigh(rgb)

        return Y <= (216/24389) and (Y*(24389/2700)) or (Y^(1/3)*1.16 - 0.16)
    end
end

do
    ---@class GUIHelper.Colors
    local Colors = {}

    local halfFactor = Color(125, 125, 125, 255).ToVector4() ---@type Microsoft.Xna.Framework.Vector4

    Colors.Base = Color(235, 225, 193, 255) ---@type Microsoft.Xna.Framework.Color
    --Colors.Base = GUI.Style.GetComponentStyle(Stringtools.prefixAcronym("ColorBase", "_")).Color
    Colors.Hover = Color.Lerp(Colors.Base, Color.White, 0.5)
    Colors.Selected = Color.Lerp(Colors.Base, Color.White, 0.75)
    Colors.Pressed = Color.Lerp(Colors.Base, Color.Black, 0.5)
    Colors.Disabled = Color(halfFactor*Colors.Base.ToVector4())

    local textColorBase = Color(225, 221, 184) ---@type Microsoft.Xna.Framework.Color
    local textColorBaseInverted = Color(255 - textColorBase.R, 255 - textColorBase.G, 255 - textColorBase.B, 255)
    local textColorBaseLuminance = GUIHelper.colorToLuminance(textColorBase)

    if textColorBaseLuminance >= 0.75 then
        Colors.TextLight = textColorBase
        Colors.TextDark = textColorBaseInverted
    elseif textColorBaseLuminance <= 0.25 then
        Colors.TextLight = textColorBaseInverted
        Colors.TextDark = textColorBase
    else
        Colors.TextLight = Color.Lerp(textColorBase, Color.White, 0.75)
        Colors.TextDark = Color.Lerp(textColorBase, Color.Black, 0.75)
    end

    Colors.Text = textColorBase
    Colors.HoverText = Color.Lerp(textColorBase, Color.White, 0.5)
    Colors.SelectedText = Color.Lerp(textColorBase, Color.White, 0.75)
    Colors.PressedText = Color.Lerp(textColorBase, Color.Black, 0.5)
    Colors.DisabledText = Color(halfFactor*Colors.Text.ToVector4())

    Colors.Outline = Color(50, 50, 50) ---@type Microsoft.Xna.Framework.Color
    GUIHelper.Colors = Colors
end
GUIHelper.ComponentState = LuaUserData.CreateEnum("Barotrauma.GUIComponent", "ComponentState")
GUIHelper.DragMode = LuaUserData.CreateEnum("Barotrauma.GUIListBox", "DragMode") ---@as {NoDragging:Barotrauma.GUIListBox.DragMode, DragWithinBox:Barotrauma.GUIListBox.DragMode, DragOutsideBox:Barotrauma.GUIListBox.DragMode}
GUIHelper.ForceUpperCase = LuaUserData.CreateEnum("Barotrauma.ForceUpperCase", "") ---@as {Inherit:Barotrauma.ForceUpperCase, No:Barotrauma.ForceUpperCase, Yes:Barotrauma.ForceUpperCase}
GUIHelper.ScaleBasis = LuaUserData.CreateEnum("Barotrauma.ScaleBasis", "")

-- do
--     ---@public
--     ---@param ... any
--     ---@return GUIHelper
--     ---@nodiscard
--     function GUIHelper:__new(...)
--         local obj = GUIHelper.super.__new(self, ...)

--         return obj
--     end
-- end
do
    local normalizeRT --[=[@[lsp_optimization("delayed_definition")]]=] do
        local IsTargetType = LuaUserData.IsTargetType

        ---@param obj Barotrauma.GUIComponent|Barotrauma.RectTransform|nil
        ---@return Barotrauma.RectTransform
        ---@nodiscard
        normalizeRT = function(obj)
            if obj and IsTargetType(obj, "Barotrauma.GUIComponent") then
                obj = obj.RectTransform
            end
            return obj
        end
        GUIHelper.normalizeRT = normalizeRT
    end

    local Anchor = GUI.Anchor
    local Pivot = GUI.Pivot
    local RectTransform = GUI.RectTransform
    local ScaleBasis = GUIHelper.ScaleBasis

    local IsTypeOf = LuaUserData.IsTypeOf

    ---@public
    ---@generic A:keyof Barotrauma.Anchor, P:keyof Barotrauma.Pivot, B:keyof Barotrauma.ScaleBasis
    ---@param size Microsoft.Xna.Framework.Point|Microsoft.Xna.Framework.Vector2
    ---@param parent? Barotrauma.GUIComponent|Barotrauma.RectTransform
    ---@param anchor? std.ConstTpl<A> "TopLeft"
    ---@param pivot? std.ConstTpl<P>
    ---@param scaleBasis? std.ConstTpl<B> "Normal"
    ---@param minSizeOrIsFixed? Microsoft.Xna.Framework.Point|boolean false
    ---@param maxSize? Microsoft.Xna.Framework.Point
    ---@return Barotrauma.RectTransform
    ---@nodiscard
    function GUIHelper.rT(size, parent, anchor, pivot, scaleBasis, minSizeOrIsFixed, maxSize)
        local _scaleBasis = ScaleBasis[scaleBasis or "Normal"]
        local var1, var2, var3

        if IsTypeOf(size, "Microsoft.Xna.Framework.Point") then
            var1 = _scaleBasis
            var2 = minSizeOrIsFixed ---@as boolean?
            var3 = nil
        else
            var1 = minSizeOrIsFixed ---@as Microsoft.Xna.Framework.Point?
            var2 = maxSize
            var3 = _scaleBasis
        end
        return RectTransform(size, normalizeRT(parent), Anchor[anchor or "TopLeft"], pivot ~= nil and Pivot[pivot] or nil, var1, var2, var3)
    end
end

do
    local Point = Point
    local sizePadding_A = GUIHelper.Sizes.Padding_A

    local select = select

    ---@public
    ---@param parent Barotrauma.GUIComponent
    ---@param padding? number
    ---@param isHorizontal boolean
    ---@param ... number
    ---@return Microsoft.Xna.Framework.Point[]
    function GUIHelper.relativeToFixed(parent, padding, isHorizontal, ...)
        local out = {...}
        local n = select("#", ...)
        local newSize = -(padding or sizePadding_A)*n

        if isHorizontal then
            newSize = newSize + parent.Rect.Size.X

            for i=1,n do
                out[i] = Point(out[i]*newSize, 0)
            end
        else
            newSize = newSize +  parent.Rect.Size.Y

            for i=1,n do
                out[i] = Point(0, out[i]*newSize)
            end
        end
        return out ---@as Microsoft.Xna.Framework.Point[]
    end
end

local colorComp --[=[@[lsp_optimization("delayed_definition")]]=] do
    local Base = GUIHelper.Colors.Base
    local Hover = GUIHelper.Colors.Hover
    local Selected = GUIHelper.Colors.Selected
    local Disabled = GUIHelper.Colors.Disabled
    local Pressed = GUIHelper.Colors.Pressed
    local Outline = GUIHelper.Colors.Outline
    local Text = GUIHelper.Colors.Text
    local HoverText = GUIHelper.Colors.HoverText
    local SelectedText = GUIHelper.Colors.SelectedText

    local Color = Color
    local One = Vector4.One
    local Transparent = Color.Transparent


    ---@generic T:Barotrauma.GUIComponent|Barotrauma.GUITextBlock|Barotrauma.GUIButton
    ---@param component T
    ---@param doTextColor? boolean true
    ---@param hasOutline? boolean false
    ---@return T
    colorComp = function(component, doTextColor, hasOutline)
        local style = component.Style

        if style ~= nil then
            local styleColor = style.Color

            if styleColor ~= Transparent then
                local styleColorFactor = styleColor.ToVector3()

                component.Color = Color(Base.ToVector3()*styleColorFactor)
                component.HoverColor = Color(Hover.ToVector3()*styleColorFactor)
                component.SelectedColor = Color(Selected.ToVector3()*styleColorFactor)
                component.PressedColor = Color(Pressed.ToVector3()*styleColorFactor)
            else
                component.Color = Base
                component.HoverColor =  Hover
                component.SelectedColor = Selected
                component.PressedColor = Pressed
            end
        end

        component.DisabledColor = Disabled

        if hasOutline == true then
            component.OutlineColor = Outline
        end

        if doTextColor ~= false then
            component.TextColor = Text
            component.HoverTextColor = HoverText
            component.SelectedTextColor = SelectedText
        end

        return component
    end
end

---@param comp Barotrauma.GUIButton
---@param userData {addF:fun(userData:{n:integer, [integer]:fun(comp:Barotrauma.GUIButton, userData:any):(boolean?, any?)}, f:fun(comp:Barotrauma.GUIButton, userData:any):(boolean?, any?)), data?:any, n:integer, [integer]:fun(comp:Barotrauma.GUIButton, userData:any):(boolean?, any?)}
local function onClicked_doUserData(comp, userData)
    local data = userData.data
    local n = userData.n

    for i=n,1,-1 do
        local doUpdate, newData = userData[i](comp, data)

        if doUpdate == true then
            data = newData
        end
    end
    userData.data = data
end

do
    ---@param userData {n:integer, [integer]:fun(comp:Barotrauma.GUIButton, userData:any):(boolean?, any?)}
    ---@param f fun(comp:Barotrauma.GUIButton, userData:any):(boolean?, any?))
    local function addF(userData, f)
        local n = userData.n + 1

        userData.n = n
        userData[n] = f
    end

    local Alignment = GUI.Alignment
    local Button = GUI.Button

    ---@public
    ---@generic A:keyof Barotrauma.Alignment
    ---@param rectTransform Barotrauma.RectTransform
    ---@param style? GUIHelper.Style "GUIButton"
    ---@param doColor? boolean true
    ---@param doTextColor? boolean true
    ---@param hasOutline? boolean false
    ---@param text? string|Barotrauma.LocalizedString ""
    ---@param textAlignment? std.ConstTpl<A> "Center"
    ---@param userData? any
    ---@param onClicked? fun(comp:Barotrauma.GUIButton, userData:any):(boolean?, any?)
    ---@return Barotrauma.GUIButton
    function GUIHelper.addButton(rectTransform, style, doColor, doTextColor, hasOutline, text, textAlignment, userData, onClicked)
        local out = Button(rectTransform,
            text or "",
            Alignment[textAlignment or "Center"],
            (style or "GUIButton") ~= "nil" and style or nil,
            nil
        )
        out.OnClicked = onClicked_doUserData
        out.UserData = {addF=addF, data=userData, n=(onClicked == nil and 0 or 1), [1]=onClicked}
        return doColor ~= false and colorComp(out, doTextColor, hasOutline) or out
    end
end



do
    local ScissorComponent = GUI.ScissorComponent

    ---@generic A:keyof Barotrauma.Anchor, P:keyof Barotrauma.Pivot
    ---@param rectTransform Barotrauma.RectTransform
    ---@return Barotrauma.GUIScissorComponent
    function GUIHelper.cut(rectTransform)
        local out = ScissorComponent(rectTransform)
        out.CanBeFocused = false
        return out
    end
end

do
    local Frame = GUI.Frame
    local Point = Point
    local sizePadding_A = GUIHelper.Sizes.Padding_A

    local cut = GUIHelper.cut
    local rT = GUIHelper.rT

    ---@public
    ---@param rectTransform Barotrauma.RectTransform
    ---@param style? GUIHelper.Style "GUIFrame"
    ---@param doColor? boolean true
    ---@param hasOutline? boolean false
    ---@param padding? integer sizePadding_A
    ---@return Barotrauma.GUIFrame, Barotrauma.GUIFrame?
    function GUIHelper.addFrame(rectTransform, style, doColor, hasOutline, padding)
        local outer = Frame(rectTransform, (style or "GUIFrame") ~= "nil" and style or nil)
        outer = doColor ~= false and colorComp(outer, false, hasOutline) or outer


        if padding == 0 then
            return outer
        else
            padding = padding or sizePadding_A

            local inner = cut(
                rT(
                    outer.Rect.Size - Point(2*padding, 2*padding),
                    rectTransform,
                    "Center",
                    "Center"
                )
            ).Content
            inner.CanBeFocused = false

            return outer, inner
        end
    end
end

do
    local Image = GUI.Image

    ---@public
    ---@param rectTransform Barotrauma.RectTransform
    ---@param sprite? Barotrauma.Sprite|string
    ---@param scaleToFit? boolean false
    ---@param doColor? boolean false
    ---@return Barotrauma.GUIImage
    function GUIHelper.addImage(rectTransform, sprite, scaleToFit, doColor)
        local out = Image(rectTransform, sprite, scaleToFit == true)

        return doColor == true and colorComp(out, false, false) or out
    end
end

do
    local Anchor = GUI.Anchor
    local sizePadding_A = GUIHelper.Sizes.Padding_A
    local LayoutGroup = GUI.LayoutGroup

    local round = Mathtools.round

    ---@public
    ---@param rectTransform Barotrauma.RectTransform
    ---@generic A:keyof Barotrauma.Anchor
    ---@param childAnchor? std.ConstTpl<A> "TopLeft"
    ---@param spacing? number sizePadding_A
    ---@param isHorizontal? boolean false
    ---@param stretch? boolean true
    ---@return Barotrauma.GUILayoutGroup
    function GUIHelper.addLayoutGroup(rectTransform, childAnchor, spacing, isHorizontal, stretch)
        local out = LayoutGroup(rectTransform, isHorizontal == true, Anchor[childAnchor or "TopLeft"])

        spacing = spacing == nil and sizePadding_A or spacing
        if spacing > 0 then
            if spacing > 1 then
                out.AbsoluteSpacing = round(spacing)
            else
                out.RelativeSpacing = spacing
            end
        end

        out.Stretch = stretch ~= false
        return out
    end
end

do
    local ListBox = GUI.ListBox

    ---@public
    ---@param rectTransform Barotrauma.RectTransform
    ---@param isHorizontal? boolean false
    ---@param isScrollBarOnDefaultSide? boolean true
    ---@param useMouseDownToSelect? boolean false
    ---@param keepSpaceForScrollBar? boolean false
    ---@param resizeContentToMakeSpaceForScrollBar? boolean true
    ---@param style? GUIHelper.Style ""
    ---@param doColor? boolean false
    ---@return Barotrauma.GUIListBox
    function GUIHelper.addListBox(rectTransform, isHorizontal, isScrollBarOnDefaultSide, useMouseDownToSelect, keepSpaceForScrollBar, resizeContentToMakeSpaceForScrollBar, style, doColor)
        local out = ListBox(rectTransform,
            isHorizontal == true,
            nil,
            (style or "") ~= "nil" and style or nil,
            isScrollBarOnDefaultSide ~= false,
            useMouseDownToSelect == true
        )
        out.KeepSpaceForScrollBar = keepSpaceForScrollBar == true
        out.ResizeContentToMakeSpaceForScrollBar = resizeContentToMakeSpaceForScrollBar ~= false
        return doColor == true and colorComp(out, false, false) or out
    end
end

do
    GUIHelper.NumberType = LuaUserData.CreateEnum("Barotrauma.NumberType", "")
    GUIHelper.ButtonVisibility = LuaUserData.CreateEnum("Barotrauma.GUINumberInput", "ButtonVisibility") ---@as {Automatic:Barotrauma.GUINumberInput.ButtonVisibility, Manual:Barotrauma.GUINumberInput.ButtonVisibility, ForceVisible:Barotrauma.GUINumberInput.ButtonVisibility, ForceHidden:Barotrauma.GUINumberInput.ButtonVisibility}

    local NumberType = GUIHelper.NumberType
    local ButtonVisibility = GUIHelper.ButtonVisibility


    local Alignment = GUI.Alignment
    local Fonts = GUI.Style.Fonts
    local ForceUpperCase = GUIHelper.ForceUpperCase
    local Identifier = Identifier
    local sizePadding_A = GUIHelper.Sizes.Padding_A
    local Vector2 = Vector2
    local NumberInput = GUI.NumberInput
    local round = Mathtools.round

    ---@public
    ---@generic N:keyof Barotrauma.NumberType, A:keyof Barotrauma.Alignment, V:keyof Barotrauma.GUINumberInput.ButtonVisibility
    ---@param rectTransform Barotrauma.RectTransform
    ---@param inputType std.ConstTpl<N>
    ---@param maxValue number
    ---@param minValue number
    ---@param style? GUIHelper.Style ""
    ---@param doColor? boolean true
    ---@param textAlignment? std.ConstTpl<A> "Left"
    ---@param relativeButtonAreaWidth? number nil
    ---@param buttonVisibility? std.ConstTpl<V> ButtonVisibility.Automatic
    ---@return Barotrauma.GUINumberInput
    function GUIHelper.addNumberInput(rectTransform, inputType, maxValue, minValue, style, doColor, textAlignment, relativeButtonAreaWidth, buttonVisibility)
        local out = NumberInput(
            rectTransform,
            NumberType[inputType],
            (style or "") ~= "nil" and style or nil,
            Alignment[textAlignment or "Left"],
            relativeButtonAreaWidth,
            ButtonVisibility[buttonVisibility or "Automatic"]
        )
        local assumeInt = round(maxValue) == maxValue and round(minValue) == minValue

        out[assumeInt and "MaxValueInt" or "MaxValueFloat"] = maxValue
        out[assumeInt and "MinValueInt" or "MinValueFloat"] = minValue

        return doColor ~= false and colorComp(out, false) or out
    end
end

do
    local Alignment = GUI.Alignment
    local Fonts = GUI.Style.Fonts
    local ForceUpperCase = GUIHelper.ForceUpperCase
    local Identifier = Identifier
    local sizePadding_A = GUIHelper.Sizes.Padding_A
    local Vector2 = Vector2

    local TextBlock = GUI.TextBlock

    ---@public
    ---@param rectTransform Barotrauma.RectTransform
    ---@generic A:keyof Barotrauma.Alignment
    ---@param style? GUIHelper.Style ""
    ---@param doColor? boolean true
    ---@param doTextColor? boolean true
    ---@param hasOutline? boolean false
    ---@param text? string|Barotrauma.RichString
    ---@param textAlignment? std.ConstTpl<A> "Left"
    ---@param wrap? boolean false
    ---@param font? GUIHelper.Font "Font"
    ---@param forceUpperCase? boolean false
    ---@param shrinkToText? boolean true
    ---@return Barotrauma.GUITextBlock
    function GUIHelper.addTextBlock(rectTransform, style, doColor, doTextColor, hasOutline, text, textAlignment, wrap, font, forceUpperCase, shrinkToText)
        local fontStyle = Fonts[Identifier(font or "Font")] ---@as Barotrauma.GUIFont

        local out = TextBlock(
            rectTransform,
            text,
            nil,
            fontStyle,
            Alignment[textAlignment or "Left"],
            wrap == true,
            (style or "") ~= "nil" and style or nil
        )

            out.ForceUpperCase = forceUpperCase == true and ForceUpperCase.Yes or ForceUpperCase.No

        if shrinkToText and font and text ~= "" then

            --out.AutoScaleVertical = true
            --rectTransform.Resize((fontStyle.MeasureString(text, false) + Vector2(2*sizePadding_A, 2*sizePadding_A)).ToPoint(), true)
            --rectTransform.IsFixedSize = true
            out.CalculateHeightFromText(2*sizePadding_A, false)
            out.AutoScaleHorizontal = true
        end

        return doColor ~= false and colorComp(out, doTextColor, hasOutline) or out
    end
end

do
    local One = Vector2.One
    local Point = Point
    local sizeIcon_A = GUIHelper.Sizes.Icon_A

    local addButton = GUIHelper.addButton
    local addFrame = GUIHelper.addFrame
    local addImage = GUIHelper.addImage
    local rT = GUIHelper.rT

    ---@public
    ---@generic A:keyof Barotrauma.Anchor, P:keyof Barotrauma.Pivot, B:keyof Barotrauma.ScaleBasis
    ---@param width? number GUIHelper.Sizes.Icon_A
    ---@param height? number GUIHelper.Sizes.Icon_A
    ---@param parent? Barotrauma.GUIComponent|Barotrauma.RectTransform
    ---@param anchor? std.ConstTpl<A> "TopLeft"
    ---@param pivot? std.ConstTpl<P>
    ---@param style? GUIHelper.Style "GUIButton"
    ---@param imageStyle? GUIHelper.Style
    ---@param doColor? boolean true
    ---@param imageDoColor? boolean true
    ---@param hasOutline? boolean false
    ---@param userData? any
    ---@param onClicked? fun(comp:Barotrauma.GUIButton, userData:any):(boolean?, any?)
    ---@return Barotrauma.GUIButton
    function GUIHelper.addIconButton(width, height, parent, anchor, pivot, style, imageStyle, doColor, imageDoColor, hasOutline, userData, onClicked)
        local buttonRT = rT(
            Point((width == nil or width == 0) and sizeIcon_A or width, (height == nil or height == 0) and sizeIcon_A or height),
            parent,
            anchor,
            pivot,
            nil,
            true
        )

        local out = addButton(
            buttonRT,
            style,
            doColor ~= false and style == "nil",
            false,
            hasOutline,
            "",
            "Center",
            userData,
            onClicked
        )

        if imageStyle then
            local image = addImage(
                rT(
                    One,
                    buttonRT,
                    "Center",
                    "Center",
                    "Normal"
                ),
                imageStyle,
                true,
                imageDoColor ~= false
            )
            image.CanBeFocused = false
        end
        return out
    end
end

do
    local ScissorComponent = GUI.ScissorComponent
    local Vector2 = Vector2

    local rT = GUIHelper.rT

    ---@param layoutGroup Barotrauma.GUILayoutGroup
    ---@return Barotrauma.GUIScissorComponent
    function GUIHelper.addSpacer(layoutGroup)
        local spacer = ScissorComponent(
            rT(
                layoutGroup.IsHorizontal == true and Vector2(0.01, 1) or Vector2(1, 0.01),
                layoutGroup,
                nil,
                nil
            )
        )
        spacer.CanBeFocused = false
        spacer.Content.Visible = false
        return spacer
    end
end

do
    local One = Vector2.One
    local Point = Point
    local Zero = Point.Zero

    local addFrame = GUIHelper.addFrame
    local rT = GUIHelper.rT

    ---@public
    ---@param parent Barotrauma.GUIComponent
    ---@param isHorizontal? boolean false
    ---@param offset? integer 0
    ---@param padding? integer 0
    ---@return Barotrauma.GUIFrame
    function GUIHelper.addLine(parent, isHorizontal, offset, padding)
        local size, style, offsetP

        if isHorizontal then
            size = Point(2, parent.Rect.Height)
            style = "VerticalLine"
            offsetP = Point(offset or 0, 0)
        else
            size = Point(parent.Rect.Width, 2)
            style = "HorizontalLine"
            offsetP = Point(0, offset or 0)
        end

        local out = addFrame(
            rT(
                size,
                parent,
                nil,
                nil,
                nil,
                true
            ),
            style,
            false,
            false,
            padding or 0
        )
        out.CanBeFocused = false
        offset = offset or 0


        if offsetP ~= Zero then
            out.RectTransform.AbsoluteOffset = offsetP
        end
        return out
    end
end

do
    local GUIScissorComponent = GUI.ScissorComponent
    local Point = Point
    local sizePadding_A = GUIHelper.Sizes.Padding_A

    local rT = GUIHelper.rT

    ---@public
    ---@param frame Barotrauma.GUIFrame
    ---@param paddingX? number GUIHelper.Sizes.Padding
    ---@param paddingY? number GUIHelper.Sizes.Padding
    ---@param unfocusOrginialFrame? boolean true
    ---@return Barotrauma.GUIFrame
    function GUIHelper.padInnerFrame(frame, paddingX, paddingY, unfocusOrginialFrame)
        local outerRT = frame.RectTransform
        local cutComponent = GUIScissorComponent(
            rT(
                outerRT.Rect.Size - Point(2*(paddingX or sizePadding_A), 2*(paddingY or sizePadding_A)),
                outerRT,
                "Center",
                "Center"
            )
        )
        cutComponent.CanBeFocused = false

        local out = cutComponent.Content

        if unfocusOrginialFrame ~= false then
            frame.CanBeFocused = false
            out.CanBeFocused = true
        end
        -- out.RectTransform.SizeChanged.add(function()
        --     outerRT.Resize()
        -- end)
        return out
    end
end

do

    --local dragHandleFrameTopSprite = Sprite("Content/UI/UIAtlasFrames.png", Rectangle(1,369,374, GUIHelper.Sizes.ItemUIHandle_A), Vector2(0.5, 0.5)) ---@as Barotrauma.Sprite

    --local UISprite = LuaUserData.CreateStatic("Barotrauma.UISprite")

    --print(UISprite.)
    local DragHandle = GUI.DragHandle
    local One = Vector2.One
    local Point = Point
    local sizeIcon_A = GUIHelper.Sizes.Icon_A
    local sizeMax_A = GUIHelper.Sizes.Max_A
    local sizePadding_A = GUIHelper.Sizes.Padding_A
    local sizeNewItemUIHandle_A = sizeIcon_A + 2*sizePadding_A

    local addImage = GUIHelper.addImage
    local rT = GUIHelper.rT

    ---@public
    ---@param frame Barotrauma.GUIFrame
    ---@return Barotrauma.GUIFrame, Barotrauma.GUIButton?
    function GUIHelper.addDragHandle(frame)
        local dragHandleRT = rT(
            One,
            frame,
            "TopCenter",
            "BottomCenter",
            nil,
            Point(0, sizeNewItemUIHandle_A),
            Point(sizeMax_A, sizeNewItemUIHandle_A)
        )

        local dragHandleIndicatorImage = addImage(
            rT(
                Point(sizeIcon_A, sizeIcon_A),
                dragHandleRT,
                "Center",
                "Center",
                "BothHeight",
                true
            ),
            "GUIDragIndicatorHorizontal",
            false,
            true
        )
        dragHandleIndicatorImage.CanBeFocused = false

        local dragHandle = DragHandle(
            dragHandleRT,
            frame.RectTransform,
            "SBAI_DragHandleBase"
        )
        return colorComp(dragHandle, false, false)
    end
end

do
    ---@param comp Barotrauma.GUIButton
    ---@param userData? Barotrauma.GUIComponent
    ---@return boolean?, nil
    local function onClicked_close(comp, userData)
        if userData then
            userData.Parent.RemoveChild(userData)
            return true, nil
        end
    end

    local Point = Point
    local sizePadding_A = GUIHelper.Sizes.Padding_A

    local addIconButton = GUIHelper.addIconButton

    ---@public
    ---@param parent Barotrauma.GUIFrame
    ---@param target? Barotrauma.GUIComponent parent
    ---@return Barotrauma.GUIButton
    function GUIHelper.addCloseButton(parent, target)
        local out = addIconButton(
                nil,
                nil,
                parent,
                "TopRight",
                "TopRight",
                "AlienButtonRed",
                "MissionFailedIcon",
                true,
                true,
                false,
                target or parent,
                onClicked_close
        )
        out.RectTransform.AbsoluteOffset = Point(sizePadding_A, sizePadding_A)
        return out
    end
end

do
    local Anchor = GUI.Anchor
    local Pivot = GUI.Pivot

    local IsTypeOf = LuaUserData.IsTypeOf

    ---@generic A:keyof Barotrauma.Anchor, P:keyof Barotrauma.Pivot
    ---@param comp Barotrauma.GUIComponent
    ---@param anchor std.ConstTpl<A>
    ---@param pivot? std.ConstTpl<P>
    ---@param offset Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
    function GUIHelper.setPosition(comp, anchor, pivot, offset)
        local rt = comp.RectTransform

        rt.SetPosition(Anchor[anchor], Pivot[pivot or anchor])
        if offset ~= nil then
            rt[IsTypeOf(offset, "Microsoft.Xna.Framework.Point") and "AbsoluteOffset" or "RelativeOffset"] = offset
        end
    end
end

-- do
    --LuaUserData.RegisterType("System.ValueTuple`2[Barotrauma.GUILayoutGroup, Barotrauma.GUILayoutGroup]")
    --LuaUserData.RegisterType("System.ValueTuple`3[Barotrauma.GUILayoutGroup, Barotrauma.GUIFrame, Barotrauma.GUILayoutGroup]")

--     LuaUserData.AccessMethod("Barotrauma.SettingsMenu", "CreateSidebars")
--     --LuaUserData.AccessMethod("Barotrauma.Steam.MutableWorkshopMenu", "CreateSidebars")


--     local CreateSidebars1 = LuaUserData.CreateStatic("Barotrauma.SettingsMenu").CreateSidebars
--     --local CreateSidebars2 = LuaUserData.CreateStatic("Barotrauma.Steam.MutableWorkshopMenu").CreateSidebars

--     local Int32 = Int32
--     local sizePadding_A = GUIHelper.Sizes.Padding_A

--     ---@param parent Barotrauma.GUIFrame
--     ---@param ratioLR? number 1
--     ---@param spacing? number sizePadding_A
--     ---@param split? boolean false
--     ---@return Barotrauma.GUILayoutGroup, Barotrauma.GUILayoutGroup
--     ---@nodiscard
--     function GUIHelper.CreateSidebars(parent, ratioLR, spacing, split)
--         local lgs = CreateSidebars1(parent, split)
--         local lgL, lgR = lgs.Item1 --[=[@as Barotrauma.GUILayoutGroup]=], lgs.Item2 --[=[@as Barotrauma.GUILayoutGroup]=] ---@diagnostic disable-line: undefined-field]

--         ratioLR = ratioLR or 0.5

--         local sizeL = ratioLR/(ratioLR + 1)
--         local sizeM = (1 - lgL.Parent.GetChild(Int32(1)).RectTransform.RelativeSize.X)
--         local sizeR = 1 - sizeL

--         lgL.RectTransform.Resize(Vector2(sizeL*sizeM, 1))
--         lgR.RectTransform.Resize(Vector2(sizeR*sizeM, 1))
--         lgL.AbsoluteSpacing = spacing or sizePadding_A
--         lgR.AbsoluteSpacing = spacing or sizePadding_A
--         return lgL, lgR
--     end
-- end

do
    local Frame = GUI.Frame
    local Anchor = GUI.Anchor
    local Pivot = GUI.Pivot
    local RectTransform = GUI.RectTransform
    local Vector2 = Vector2

    local normalizeRT = GUIHelper.normalizeRT

    ---@generic A:keyof Barotrauma.Anchor, P:keyof Barotrauma.Pivot
    ---@param parent Barotrauma.RectTransform|Barotrauma.GUIComponent
    ---@param height? number 0.03
    ---@param anchor? std.ConstTpl<A>
    ---@param pivot? std.ConstTpl<P>
    function GUIHelper.Spacer(parent, height, anchor, pivot)
        anchor = anchor ~= nil and Anchor[anchor] or nil

        local out = Frame(RectTransform(Vector2(1, height or 0.03), normalizeRT(parent), anchor, pivot ~= nil and Pivot[pivot] or anchor), nil)
        out.CanBeFocused = false
    end
end

return Types.GUIHelper