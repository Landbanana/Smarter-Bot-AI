---@namespace Config

---@class (partial) OptionBool
local ConfigOptionBool = Types.Config.OptionBool

local GUIHelper = Types.GUIHelper

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

function ConfigOptionBool:_drawSetter(valueFrame)
    local toggleButton = addButton(
        rT(
            One,
            valueFrame,
            "TopLeft",
            "TopLeft"
        ),
        "EquipmentToggleButton",
        true,
        false,
        false,
        "",
        nil
    )
    
    function toggleButton.OnClicked(button, UserData)
        local old = button.Selected
        local new = self:_validate(not old)
        
        button.Selected = new
        return new
    end
end

-- do
--     local __new_ = ConfigOptionBool.__new

--     ---@param name string
--     ---@param default? boolean true
--     ---@param ... any
--     ---@return Config.OptionBool
--     ---@nodiscard
--     function ConfigOptionBool:__new(name, default, ...)
--         local obj = __new_(self, name, default, ...)
--             obj.onDiscard:add()
--         return obj
--     end
-- end


return Types.Config.OptionBool