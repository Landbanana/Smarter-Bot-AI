---@namespace Config

---@class (partial) OptionFloat
local ConfigOptionFloat = Types.Config.OptionFloat

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
local addNumberInput = GUIHelper.addNumberInput
local addSpacer = GUIHelper.addSpacer
local addTextBlock = GUIHelper.addTextBlock
local ceil = math.ceil
local padInnerFrame = GUIHelper.padInnerFrame
local rT = GUIHelper.rT
local setPosition = GUIHelper.setPosition

---@protected
---@generic N:keyof Barotrauma.NumberType
---@param inputType N
function ConfigOptionFloat:_makeNumberInput(inputType)
    local valueTypeString = inputType.."Value"
    
    ---@param parent Barotrauma.GUIComponent
    ---@return Barotrauma.GUINumberInput
    function self:_drawSetter(parent)
        local numberInput = addNumberInput(
            rT(
                One,
                parent,
                "TopLeft",
                "TopLeft"
            ),
            inputType,
            self.max,
            self.min,
            "",
            true,
            "Center",
            nil,
            nil
        )

        local zeroCheck = false
        local forcedDefault = false

        ---@param numberIn Barotrauma.GUINumberInput
        function numberInput.OnValueEntered(numberIn)
            if forcedDefault then
                
                numberIn[valueTypeString] = self.default
                forcedDefault = false
            end
        end

        ---@param numberIn Barotrauma.GUINumberInput
        numberInput.OnValueChanged = function(numberIn)
            if numberInput.TextBox.Selected == true then
                local oldZeroCheck = zeroCheck
                
                zeroCheck = numberIn[valueTypeString] == 0
                forcedDefault = forcedDefault or (oldZeroCheck and zeroCheck)
            else
                forcedDefault = false
            end
        end
        return numberInput
    end
end
ConfigOptionFloat:_makeNumberInput("Float")



return Types.Config.OptionFloat