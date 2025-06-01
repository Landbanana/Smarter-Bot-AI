local Constants = require("SBAI.Shared.constants")
local guiUtil = require("SBAI.Client.guiUtil")

local ForceUpperCase = guiUtil.Constants.ForceUpperCase

local D_PADDING = guiUtil.Constants.D_PADDING
local D_SLOT_SIZE = guiUtil.Constants.D_SLOT_SIZE

local D_WIDTH = guiUtil.Constants.D_WIDTH
local D_HEIGHT = guiUtil.Constants.D_HEIGHT

local D_ICON_VH = guiUtil.Constants.D_ICON_VH

local RectTransform = GUI.RectTransform

local function createItemPickerGui()
    local screenSize = Game.GameScreen.Frame.Rect.Size

    local mainFrame = GUI.Frame(RectTransform(Point(screenSize.X*0.4, screenSize.Y*0.6), nil, GUI.Anchor.Center), "ItemUI")
    guiUtil.AssignColors(mainFrame)

    local dragHandle = GUI.DragHandle(RectTransform(Vector2.One, mainFrame.RectTransform, GUI.Anchor.Center), mainFrame.RectTransform, nil)

    local innerFrame = guiUtil.AddFrame(mainFrame, mainFrame.Rect.Size - Point(2*D_PADDING, 4*D_PADDING), GUI.Anchor.Center, "InnerFrameDark", true)
    innerFrame.RectTransform.AbsoluteOffset = Point(0, D_PADDING/2)
    
    guiUtil.AddItemPicker(innerFrame, nil)
    
    return mainFrame
end

return createItemPickerGui()