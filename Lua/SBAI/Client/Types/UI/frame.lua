---@namespace UI

---@class Frame: Base
---@operator add(Base|Base[]):(Frame)
---@operator concat(Base):(Frame)
---@operator div(Base|Base[]):(Frame)
---@operator mod(Base):(Frame)
---@operator pow(Base):(Frame)
---@field public cls Frame
---@field public super Base
---@field public addSeparators boolean
---@field public hasLayoutGroup boolean
---@field protected __new fun(self, )
---@field protected _layoutGroup {childAnchor:Barotrauma.Anchor, children:Base[], n:integer}
---@field protected _addChildren fun(self, v:Base[], a?:Barotrauma.Anchor, p?:Barotrauma.Pivot):(self)
---@field protected _addChildren fun(self, v:Base):(self)
---@field package __add fun(self, v:(Base|Base[])):(self)
---@field package __concat fun(self, v:Base):(self)
---@field package __div fun(self, v:(Base|Base[])):(self)
---@field package __mod fun(self, v:Base):(self)
---@field package __pow fun(self, v:Base):(self)
---@field package __unm fun(self):(self)
Types.UI.Frame = Types.new("UI.Frame", "UI.Base", {
    hasLayoutGroup = Types.Desc.TiedConstant--[=[@as Desc.TiedConstant<UI.Frame>]=](
    function(self, cls, obj)
        return obj._layoutGroup ~= nil ---@diagnostic disable-line: access-invisible
    end);
    addSeparators = true;
    _style = "GUIFrame";
})

local UIFrame = Types.UI.Frame

---@public
---@param addSeparators? boolean true
---@param style? string "GUIFrame"
---@param color? boolean|"invert" true
---@param id? string nil
---@param ... any
---@return Frame
---@nodiscard
function UIFrame:__new(addSeparators, style, color, id, ...)
    local out = UIFrame.super.__new(self, style, color, id, ...) ---@as Frame

    out.addSeparators = addSeparators ~= false
    return out
end

do
    function UIFrame:_addChild(v, a, p)
        local _layoutGroup = self._layoutGroup

        if _layoutGroup == nil or v.ignoreLayoutGroups == true then
            return UIFrame.super._addChild(self, v, a, p)
        else
            local n = _layoutGroup.n + 1

            _layoutGroup.n = n
            _layoutGroup.children[n] = v
        end
        return self
    end
end

do
    local first = Itertools.first
    local isObject = Types.isObject

    function UIFrame:_addChildren(v, a, p)
        if isObject(v) then
            return self:_addChild(v)
        elseif not self.hasLayoutGroup then ---@cast v -Base
            self._layoutGroup = {
                childAnchor=first--[[@<Base>]](v):flip()._anchor,
                children=v,
                n=#v
            }
        else
            for _v in v do
                self:_addChild(_v, a, p)
            end
        end
        return self
    end
end

do
    local Anchor = GUI.Anchor
    local Pivot = GUI.Pivot

    local function fBase(fStr, apStr, self, v)
        return self[fStr](self, v, Anchor[apStr], Pivot[apStr])
    end

    local partial2 = Functools.partial2
    local fStr = "_addChild" ---@type string?

    UIFrame.__concat = partial2(fBase, fStr, "Center")
    UIFrame.__mod = partial2(fBase, fStr, "BottomRight")
    UIFrame.__pow = partial2(fBase, fStr, "TopRight")

    fStr = fStr.."ren"

    UIFrame.__add = partial2(fBase, fStr, "CenterRight")
    UIFrame.__div = partial2(fBase, fStr, "BottomCenter")
    fStr = nil
end

return Types.UI.Frame