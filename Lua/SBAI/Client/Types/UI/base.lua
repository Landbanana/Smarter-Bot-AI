---@namespace UI

---@class Base: Object
---@field public cls Base
---@field public style? string
---@field public attrs Partial<Barotrauma.GUIComponent>
---@field public flip fun(self, a?:Barotrauma.Anchor, p?:Barotrauma.Pivot):(self)
---@field public id? string
---@field public ignoreLayoutGroups boolean
---@field public r fun(self):(self)
---@field public tofunction fun(self):(fun(parent:Barotrauma.RectTransform))
---@field protected _addChild fun(self, v:Base, a?:Barotrauma.Anchor, p?:Barotrauma.Pivot):(self)
---@field protected _anchor Barotrauma.Anchor
---@field protected _pivot Barotrauma.Pivot
---@field protected _r boolean
---@field protected _tofunction fun(self):(string)
---@field package children {n:integer, [integer]:Base}
---@field package _style string
Types.UI.Base = Types.new--[[@<UI.Base, Object>]]("UI.Base", nil, {
    style = Types.Desc.Property(nil, Types.Desc.Property.getT,
    ---@param self Desc.Property
    ---@param cls Base
    ---@param obj Base
    ---@param v? string
    function(self, cls, obj, v)
        if v == "nil" then
            v = nil
        elseif v == nil then
            v = cls._style
        end
        return self:setT(cls, obj, v)
    end);
    ignoreLayoutGroups = false;
    _anchor = GUI.Anchor.TopLeft;
    _pivot = GUI.Pivot.TopLeft;
    _r = false;
    _style = "";
    tofunction = Types.AbstractFunction;
})

local UIBase = Types.UI.Base

do
    local weigh = Functools.partial1(Vector3.Dot, Vector3(0.2126, 0.7152, 0.0722)) ---@as fun(rgb:Microsoft.Xna.Framework.Vector3):(number)

    ---@source https://stackoverflow.com/a/56678483
    ---@param color Microsoft.Xna.Framework.Color
    ---@return number
    ---@nodiscard
    function UIBase.colorToLuminance(color)
        local rgb = color.ToVector3()

        for c in ("XYZ"):gmatch("%a") do
            local v = rgb[c]

            rgb[c] = v <= 0.04045 and (v/12.92) or (((v + 0.055)/1.055)^2.4)
        end
        local Y = weigh(rgb)

        return Y <= (216/24389) and (Y*(24389/2700)) or (Y^(1/3)*1.16 - 0.16)
    end
end

do
    local Color = Color

    ---@param color Microsoft.Xna.Framework.Color
    ---@return Microsoft.Xna.Framework.Color
    ---@nodiscard
    function UIBase.colorInvert(color)
        return Color(255 - color.R, 255 - color.G, 255 - color.B, 0 + color.A)
    end
end

do
    local base = GUI.Style.GetComponentStyle(Stringtools.prefixAcronym("ColorBase", "_")).Color ---@type Microsoft.Xna.Framework.Color
    local isBright = UIBase.colorToLuminance(base) >= 0.5

    local hover = Color.Lerp(base, Color[isBright and "White" or "Black"] --[=[@as Microsoft.Xna.Framework.Color]=], 0.5)
    local selected = Color.Lerp(base, Color[isBright and "White" or "Black"] --[=[@as Microsoft.Xna.Framework.Color]=], 0.75)
    local pressed = Color.Lerp(base, Color[isBright and "Black" or "White"] --[=[@as Microsoft.Xna.Framework.Color]=], 0.5)
    local disabled = Color(Color(125, 125, 125, 255).ToVector4()*base.ToVector4())


    UIBase.colors = {
        base = base,
        base_invert = UIBase.colorInvert(base),
        hover = hover,
        hover_invert = UIBase.colorInvert(hover),
        selected = selected,
        selected_invert = UIBase.colorInvert(selected),
        pressed = pressed,
        pressed_invert = UIBase.colorInvert(pressed),
        disabled = disabled,
        disabled_invert = UIBase.colorInvert(disabled)
    } ---@readonly
end

---@public
---@param style? string ""
---@param color? boolean|"invert" true
---@param id? string nil
---@param ... any
---@return Base
---@nodiscard
function UIBase:__new(style, color, id, ...)
    local out = UIBase.super.__new(self, ...)
    local attrs = {}

    out.style = style

    local colors = self.colors

    if color == "invert" then
        attrs.Color = colors.base_invert
        attrs.HoverColor = colors.hover_invert
        attrs.SelectedColor = colors.selected_invert
        attrs.PressedColor = colors.pressed_invert
        attrs.DisabledColor = colors.disabled_invert
    elseif color ~= false then
        attrs.Color = colors.base
        attrs.HoverColor = colors.hover
        attrs.SelectedColor = colors.selected
        attrs.PressedColor = colors.pressed
        attrs.DisabledColor = colors.disabled
    end

    out.attrs = attrs
    out.id = id

    return out
end

do
    local anchorMatch ---@[lsp_optimization("delayed_definition")]
    local pivotMatch ---@[lsp_optimization("delayed_definition")]

    do
        local gsub = string.gsub

        local match = {"Anchor", "Pivot"} ---@type {[1]:("Anchor"|Match<Barotrauma.Anchor, Barotrauma.Anchor>), [2]:("Pivot"|Match<Barotrauma.Pivot, Barotrauma.Pivot>)}
        local opposites = {
            Left="Right",
            Right="Left",
            Top="Bottom",
            Bottom="Top",
            Center="Center"
        }

        for i=1,2 do
            local enum = GUI[match[i]] ---@type Barotrauma.Anchor|Barotrauma.Pivot
            local _match = Types.Match() ---@type Match<Barotrauma.Anchor, Barotrauma.Anchor>|Match<Barotrauma.Pivot, Barotrauma.Pivot>

            for k, v  in next, enum do
                _match:case(v, enum[gsub(k, "%u%l+", opposites)])
            end
            match[i] = _match
        end
        anchorMatch = match[1] ---@as Match<Barotrauma.Anchor, Barotrauma.Anchor>
        pivotMatch = match[2] ---@as Match<Barotrauma.Pivot, Barotrauma.Pivot>
    end

    function UIBase.flip(obj, a, p)
        if a ~= nil then a = anchorMatch:eval(a) end
        if p ~= nil then p = pivotMatch:eval(p) end

        if obj == nil then
            return a, p
        end
        obj._anchor = anchorMatch:eval(a or obj._anchor)
        obj._pivot = pivotMatch:eval(p or obj._pivot)
        return obj
    end

end

function UIBase:r()
    self._r = not self._r
    return self
end

do
    local Anchor = GUI.Anchor
    local Pivot = GUI.Pivot

    ---@generic A:keyof Barotrauma.Anchor, P:keyof Barotrauma.Pivot
    ---@param anchor? std.ConstTpl<A>
    ---@param pivot? std.ConstTpl<P>
    ---@return self
    function UIBase:setPosition(anchor, pivot)
        if anchor then self._anchor = Anchor[anchor] end
        if pivot then self._pivot = Pivot[pivot] end
        return self
    end
end

do
    function UIBase:_addChild(v, a, p)
        local children = self.children

        if not children then
            children = {n=0, v}
            self.children = children
        end

        local n = children.n + 1
        children.n = n
        children[n] = v

        if v._r then
            v:flip(a, p)
        end
        return self
    end
end

do

    function UIBase:_tofunction()
        return [[]]
    end
end

return Types.UI.Base