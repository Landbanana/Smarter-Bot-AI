local Constants = require("SBAI.Shared.constants")
local guiUtil = require("SBAI.Client.guiUtil")
local Types = require("SBAI.Shared.types")

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

local function createCrewManagerGui()
    local screenSize = Game.GameScreen.Frame.Rect.Size

    local mainFrame = GUI.Frame(RectTransform(Point(screenSize.X*0.4, --[[128 + 2*D_SLOT_SIZE + 8*D_PADDING + ]]screenSize.Y*0.8), nil, GUI.Anchor.Center), "ItemUI")
    guiUtil.AssignColors(mainFrame)

    local dragHandle = GUI.DragHandle(RectTransform(Vector2.One, mainFrame.RectTransform, GUI.Anchor.Center), mainFrame.RectTransform, nil)

    local innerFrame = guiUtil.AddFrame(mainFrame, mainFrame.Rect.Size - Point(2*D_PADDING, 4*D_PADDING), GUI.Anchor.Center, "InnerFrameDark", true)
    innerFrame.RectTransform.AbsoluteOffset = Point(0, D_PADDING/2)

    local selectedSlots = {--[[@type table<Barotrauma.InvSlotType, Types.Set<Barotrauma.GUIButton>>]]
        [InvSlotType.Any]=Types.Set.new(),
        [InvSlotType.LeftHand]=Types.Set.new(),
        [InvSlotType.RightHand]=Types.Set.new(),
        [InvSlotType.Bag]=Types.Set.new(),
        [InvSlotType.OuterClothes]=Types.Set.new(),
        [InvSlotType.InnerClothes]=Types.Set.new(),
        [InvSlotType.Head]=Types.Set.new(),
        [InvSlotType.Headset]=Types.Set.new(),
    }

    local basicSlots = {}
    local limbSlots

    local White = Color.White

    ---@param button Barotrauma.GUIButton
    ---@param obj any
    local function onSlotClicked(button, obj)
        local slot = button.GetChildByUserData(D_PADDING)

        if slot.Color == White then
            if button.ToolTip ~= nil then
                button.ToolTip = nil

                local itemImage = button.GetChild(Int32(button.CountChildren - 1))
                local prefab = itemImage.UserData --[[@type Barotrauma.ItemPrefab]]
                
                --button.RemoveChild(itemImage)
                --selectedSlots[obj]:Remove(button)
                --slot.Color = White

                local reg, comp = prefab:SBAI_getInvSlots()

                if not reg[obj] then
                    for slotSet in comp do --[[@cast slotSet Types.Set<Barotrauma.InvSlotType>]]
                        local matchingButtons = {}
                        local i = 0

                        slotSet:Remove(obj)
                        for slotType in next, slotSet do
                            local j = i

                            for otherButton in limbSlots do--[[@cast otherButton Barotrauma.GUIButton]]
                                if otherButton.ToolTip ~= nil and
                                    otherButton.GetChild(Int32(otherButton.CountChildren - 1)).UserData == prefab
                                then
                                    i = i + 1
                                    matchingButtons[i] = otherButton
                                    slotSet:Remove(slotType)
                                    break
                                end
                            end
                            if j == i then
                                break
                            end
                        end
                        
                        if slotSet:IsEmpty() then
                            for otherButton in matchingButtons do
                                selectedSlots[obj]:Remove(button)
                                otherButton.RemoveChild(otherButton.GetChild(Int32(otherButton.CountChildren - 1)))
                                otherButton.ToolTip = nil
                            end
                        end
                    end
                end
                selectedSlots[obj]:Remove(button)
                button.RemoveChild(itemImage)
            else
                selectedSlots[obj]:Add(button)
                slot.Color = White*0.9
            end
        else
            selectedSlots[obj]:Remove(button)
            slot.Color = White
        end
    end

    local innerGroup, setFilter = guiUtil.AddItemPicker(innerFrame, selectedSlots)

    -- --local innerGroup = guiUtil.AddLayoutGroup(innerFrame, innerFrame.Rect.Size - Point(2*D_PADDING, 2*D_PADDING), GUI.Anchor.Center, nil, false, GUI.Anchor.TopCenter)
    innerGroup.AbsoluteSpacing = D_PADDING
    
    local topBarGroup = guiUtil.AddLayoutGroup(innerGroup, Point(innerGroup.Rect.Width - 4*D_PADDING, 128), GUI.Anchor.TopCenter, nil, true, GUI.Anchor.CenterLeft)
    --topBarGroup.CanBeFocused = true
    
    local jobs = {} --[[@type Barotrauma.JobPrefab[]|fun():Barotrauma.JobPrefab]]
    local n = 0

    for prefab in JobPrefab.Prefabs do
        if not prefab.HiddenJob then
            n = n + 1
            jobs[n] = prefab
        end
    end

    local jobIconLeft = GUI.Image(
        RectTransform(
            Point(128, 128),
            topBarGroup.RectTransform
        ),
        nil,
        false
    )
    
    local titleGroup = guiUtil.AddLayoutGroup(topBarGroup, Point(topBarGroup.Rect.Width - 2*128, 128), nil, nil, false, GUI.Anchor.BottomCenter)
    
    local arrowGroup = guiUtil.AddLayoutGroup(titleGroup, Point(D_SLOT_SIZE*3, 3/4*D_SLOT_SIZE), GUI.Anchor.TopCenter, nil, true, GUI.Anchor.CenterLeft)
    
    local leftArrowButton = guiUtil.AddButton(arrowGroup, Point(D_SLOT_SIZE, arrowGroup.Rect.Height/2), nil, "<", "GUIButtonRound", true)
    leftArrowButton.UserData = -1

    local numTextBlock = guiUtil.AddTextBlock(arrowGroup, Point(D_SLOT_SIZE, arrowGroup.Rect.Height), nil, "", nil, "LargeFont", GUI.Alignment.TopCenter, false, true, false)
   
    local rightArrowButton = guiUtil.AddButton(arrowGroup, Point(D_SLOT_SIZE, arrowGroup.Rect.Height/2), nil, ">", "GUIButtonRound", true)
    rightArrowButton.UserData = 1

    --titleGroup.CanBeFocused = true
    local jobTextBlock = guiUtil.AddTextBlock(titleGroup, Point(titleGroup.Rect.Width, 3/4*D_SLOT_SIZE), nil, nil, nil, "LargeFont", GUI.Alignment.BottomCenter, false, true, false)
    --jobTextBlock.AutoScaleHorizontal = true
    
    --arrowGroup.CanBeFocused = true

    local largeFont = GUI.Style.Fonts[Identifier("LargeFont")]
    for textBlock in {leftArrowButton, rightArrowButton} do --[[@cast textBlock Barotrauma.GUITextBlock]]
        textBlock.Font = largeFont
    end

    local jobIconRight = GUI.Image(
        RectTransform(
            Point(128, 128),
            topBarGroup.RectTransform
        ),
        nil,
        false
    )

    local basicSlotsGroup = guiUtil.AddLayoutGroup(innerGroup, Point(10*(D_SLOT_SIZE + D_PADDING) - D_PADDING, D_SLOT_SIZE), nil, nil, true, GUI.Anchor.CenterLeft)
    --basicSlotsGroup.CanBeFocused = true
    basicSlotsGroup.AbsoluteSpacing = D_PADDING

    local limbSlotsGroup = guiUtil.AddLayoutGroup(innerGroup, Point(7*(D_SLOT_SIZE + D_PADDING) - D_PADDING, D_SLOT_SIZE), nil, nil, true, GUI.Anchor.CenterLeft)
    --limbSlotsGroup.CanBeFocused = true
    limbSlotsGroup.AbsoluteSpacing = D_PADDING

    local function setIndex(i)
        local prefab = jobs[i]
        local uiColor = prefab.UIColor
        
        jobTextBlock.Text = prefab.Name
        jobTextBlock.TextColor = uiColor

        local icon = prefab.Icon

        for image in {jobIconLeft, jobIconRight} do --[[@cast image Barotrauma.GUIImage]]
            image.Sprite = icon
            image.Color = uiColor
        end

        numTextBlock.Text = tostring(i).."/"..tostring(n)
        numTextBlock.TextColor = uiColor
    end

    local coIndex

    do
        local yield = coroutine.yield

        coIndex = coroutine.wrap(
        function(i)
            while true do
                basicSlotsGroup.ClearChildren()
                limbSlotsGroup.ClearChildren()
                for j=1,10,1 do
                    local slot = guiUtil.AddEmptyItemSlot(basicSlotsGroup, nil, nil, true)

                    slot.OnClicked = onSlotClicked
                    basicSlots[j] = slot
                end
                limbSlots = {
                    [1]=guiUtil.AddEmptyItemSlot(limbSlotsGroup, nil, InvSlotType.LeftHand, true),
                    [2]=guiUtil.AddEmptyItemSlot(limbSlotsGroup, nil, InvSlotType.RightHand, true),
                    [3]=guiUtil.AddEmptyItemSlot(limbSlotsGroup, nil, InvSlotType.Bag, true),
                    [4]=guiUtil.AddEmptyItemSlot(limbSlotsGroup, nil, InvSlotType.OuterClothes, true),
                    [5]=guiUtil.AddEmptyItemSlot(limbSlotsGroup, nil, InvSlotType.InnerClothes, true),
                    [6]=guiUtil.AddEmptyItemSlot(limbSlotsGroup, nil, InvSlotType.Head, true),
                    [7]=guiUtil.AddEmptyItemSlot(limbSlotsGroup, nil, InvSlotType.Headset, true)
                }
                for button in limbSlots do --[[@cast button Barotrauma.GUIButton]]
                    button.OnClicked = onSlotClicked
                end
                i = (i + yield(setIndex(i)) - 1) % n + 1
            end
        end)
    end

    -- local White = Color.White
    -- button.OnClicked = function()
    --     slot.Color = slot.Color == White and White*0.9 or White
    -- end
    
    innerGroup.RectTransform.Resize(Point(innerGroup.Rect.Size.X, innerGroup.Rect.Size.Y + titleGroup.Rect.Size.Y + basicSlotsGroup.Rect.Size.Y + limbSlotsGroup.Rect.Size.Y + 4*D_PADDING), false)
    innerFrame.RectTransform.Resize(innerGroup.Rect.Size + Point(2*D_PADDING, 2*D_PADDING), false)
    mainFrame.RectTransform.Resize(innerFrame.Rect.Size + Point(2*D_PADDING, 4*D_PADDING), false)
    dragHandle.RectTransform.Resize(Vector2.One, false)

    local onClicked = function(button, obj)
        coIndex(obj)
    end

    leftArrowButton.OnClicked = onClicked
    rightArrowButton.OnClicked = onClicked

    coIndex(1)

    return mainFrame
end

return createCrewManagerGui()