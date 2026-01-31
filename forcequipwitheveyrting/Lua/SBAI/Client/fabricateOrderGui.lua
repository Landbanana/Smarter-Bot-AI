local Constants = require("SBAI.Shared.constants")
local guiUtil = require("SBAI.Client.guiUtil")

local ForceUpperCase = guiUtil.Constants.ForceUpperCase

local D_PADDING = guiUtil.Constants.D_PADDING
local D_SLOT_SIZE = guiUtil.Constants.D_SLOT_SIZE

local D_WIDTH = guiUtil.Constants.D_WIDTH
local D_HEIGHT = guiUtil.Constants.D_HEIGHT

local D_ICON_VH = guiUtil.Constants.D_ICON_VH

local AddTextBlock = guiUtil.AddTextBlock
local AddButton = guiUtil.AddButton
local AddListBox = guiUtil.AddListBox
local AddFrame = guiUtil.AddFrame
local AddInvisibleFrame = guiUtil.AddInvisibleFrame
local AddLayoutGroup = guiUtil.AddLayoutGroup
local CutComponent = guiUtil.CutComponent

local RectTransform = GUI.RectTransform
local TypeOf = LuaUserData.TypeOf

local selectedItem

---@param parent Barotrauma.GUIComponent
---@return Barotrauma.GUIListBox
local function createItemList(parent)
    local itemList = AddListBox(parent, Vector2(1, 0.8), nil, nil)

    itemList.PlaySoundOnSelect = true

    itemList.OnSelected = function(component, obj)
        if TypeOf(obj) == "Barotrauma.FabricationRecipe" then
            selectedItem = obj
            return true
        else
            return false
        end
    end

    return itemList
end

local function createFabricatorGUI()
    local screenSize = Game.GameScreen.Frame.Rect.Size

    local mainFrame = GUI.Frame(RectTransform(Point(screenSize.X*0.4, screenSize.Y*0.6), nil, GUI.Anchor.Center), "ItemUI")
    guiUtil.AssignColors(mainFrame)

    local dragHandle = GUI.DragHandle(RectTransform(Vector2.One, mainFrame.RectTransform, GUI.Anchor.Center), mainFrame.RectTransform, nil)

    local paddedGroup = AddLayoutGroup(mainFrame, Vector2(0.95, 0.9), GUI.Anchor.Center, nil, nil, GUI.Anchor.TopCenter)

    AddTextBlock(paddedGroup, Vector2(1, 0.05), nil, TextManager.Get("GUI.fabricateordertitle"), nil, Identifier("SubHeadingFont"), GUI.Alignment.Center, nil, true, true).AutoScaleVertical = true

    local innerGroup = AddLayoutGroup(paddedGroup, Vector2(1, 0.95), GUI.Anchor.Center, nil, true)

    innerGroup.RelativeSpacing = 0.01
    innerGroup.Stretch = true
    innerGroup.CanBeFocused = true

    local mainGroup = AddLayoutGroup(innerGroup, Vector2.One, nil, nil, nil, GUI.Anchor.TopCenter)
    mainGroup.RelativeSpacing = 0.02
    mainGroup.Stretch = true
    mainGroup.CanBeFocused = true

    local topFrame = AddFrame(mainGroup, Vector2(1, 0.8), nil, "InnerFrameDark")

    local itemListGroup = AddLayoutGroup(topFrame, Vector2(0.5, 1), nil, nil, nil, GUI.Anchor.Center)

    local paddedItemGroup = AddLayoutGroup(itemListGroup, Vector2(0.9, 0.95), nil, nil, false)
    paddedItemGroup.Stretch = true

    local filterGroup = AddLayoutGroup(paddedItemGroup, Vector2(1, 0.15), nil, nil, true)
    filterGroup.Stretch = true
    filterGroup.RelativeSpacing = 0.03
    filterGroup.UserData = "filterarea"

    local filterTextblock = AddTextBlock(filterGroup, Vector2(0.4, 1), nil, TextManager.Get("serverlog.filter"), "", Identifier("SubHeadingFont"), GUI.Alignment.CenterLeft, nil, true, true)
    filterTextblock.Padding = Vector4.Zero
    filterTextblock.AutoScaleVertical = true

    local itemFilterBox = GUI.TextBox(RectTransform(Vector2(0.8, 1), filterGroup.RectTransform), nil, nil, nil, nil, nil, "", nil, true)
    itemFilterBox.OverflowClip = true
    -- function itemFilterBox.OnTextChanged(textBox, text)
    --     --TODO
    --     return true
    -- end

    do
        local rectTransform = filterGroup.RectTransform
        rectTransform.MinSize = Point(0, itemFilterBox.Rect.Height)
        rectTransform.MaxSize = Point(Constants.MAX_INT, itemFilterBox.Rect.Height)
    end

    local itemList = createItemList(paddedItemGroup)

    AddFrame(topFrame, Vector2(0.01, 0.9), GUI.Anchor.Center, "VerticalLine")

    local outputGroup = AddLayoutGroup(topFrame, Vector2(0.5, 1), GUI.Anchor.TopRight, nil, nil, GUI.Anchor.Center)
    local paddedOutputGroup = AddLayoutGroup(outputGroup, Vector2(0.95, 0.95))
    paddedOutputGroup.Stretch = true
    local outputTopGroup = AddLayoutGroup(paddedOutputGroup, Vector2(1, 0.5), GUI.Anchor.Center, nil, true)

    local outputSlot = AddFrame(outputTopGroup, Vector2(0.4, 0.4), nil, "null", true)
    outputSlot.RectTransform.ScaleBasis = guiUtil.Constants.ScaleBasis.BothWidth

    local outputInventoryHolder = AddFrame(outputSlot, Vector2(1, 1), GUI.Anchor.BottomCenter, "null", true)
    --new GUICustomComponent(new RectTransform(Vector2.One, outputInventoryHolder.RectTransform), DrawOutputOverLay) { CanBeFocused = false }

    local selectedItemFrame = AddFrame(outputTopGroup, Vector2(0.6, 1), nil, "null", true)

    local selectedItemReqsFrame = AddFrame(paddedOutputGroup, Vector2(1, 0.5), nil, "null", true)

    local bottomFrame = AddFrame(mainGroup, Vector2(1, 0.2), nil, "null", true)

    local separatorGroup = AddLayoutGroup(bottomFrame, Vector2(0.95, 0.15), GUI.Anchor.TopCenter, nil, true, GUI.Anchor.CenterLeft)
    separatorGroup.Stretch = true
    separatorGroup.RelativeSpacing = 0.03

    local inputLabel = AddTextBlock(separatorGroup, Vector2.One, nil, TextManager.Get("fabricator.input", "uilabel.input"), nil, Identifier("SubHeadingFont"), nil, nil, true, true)
    inputLabel.Padding = Vector4.Zero
    inputLabel.RectTransform.Resize(Point(inputLabel.Font.MeasureString(inputLabel.Text).X, inputLabel.RectTransform.Rect.Height))

    AddFrame(separatorGroup, Vector2.One, nil, "HorizontalLine")

    local inputGroup = AddLayoutGroup(bottomFrame, Vector2(0.95, 1), GUI.Anchor.BottomCenter, nil, true, GUI.Anchor.BottomLeft)
    
    local inputInventoryFrame = AddFrame(inputGroup, Vector2(0.7, 0.8), nil, "null", true)
    local inputInventoryGroup = guiUtil.AddLayoutGroup(inputInventoryFrame, Vector2.One, GUI.Anchor.Center, nil, true, GUI.Anchor.CenterLeft)
    inputInventoryGroup.RelativeSpacing = 0.03

    local minEdgeSize = math.min(inputInventoryFrame.Rect.Width, inputInventoryFrame.Rect.Height)*0.8

    --guiUtil.AddItemCarousel(inputInventoryGroup, Point(minEdgeSize, minEdgeSize), nil, true, ItemPrefab.GetItemPrefab("bikehorn"), ItemPrefab.GetItemPrefab("poop"))

    return mainFrame
end

return createFabricatorGUI()