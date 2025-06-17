local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")
local CreateItemPickerGui = require("SBAI.Client.itemPickerGui")
local ItemSlot = require("SBAI.Client.itemSlotGui")
local guiUtil = require("SBAI.Client.guiUtil")


local D_HUMAN_INV_N_ANY = Constants.D_HUMAN_INV_N_ANY
local D_HUMAN_INV_N = Constants.D_HUMAN_INV_N

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

---@param changeAdder fun(data:table<Barotrauma.Identifier, Iterable<ItemData>>)
---@param allLoadoutData table<Barotrauma.Identifier, Iterable<ItemData>>
---@return Barotrauma.GUIFrame
local function createCrewLoadoutGui(changeAdder, allLoadoutData)
    local screenSize = Game.GameScreen.Frame.Rect.Size

    local mainFrame = GUI.Frame(RectTransform(Point(screenSize.X*0.4, --[[128 + 2*D_SLOT_SIZE + 8*D_PADDING + ]]screenSize.Y*0.8), nil, GUI.Anchor.Center), "ItemUI")
    guiUtil.AssignColors(mainFrame)

    local dragHandle = GUI.DragHandle(RectTransform(Vector2.One, mainFrame.RectTransform, GUI.Anchor.Center), mainFrame.RectTransform, nil)

    local innerFrame = guiUtil.AddFrame(mainFrame, mainFrame.Rect.Size - Point(2*D_PADDING, 4*D_PADDING), GUI.Anchor.Center, "InnerFrameDark", true)
    innerFrame.RectTransform.AbsoluteOffset = Point(0, D_PADDING/2)

    

    -- local selectedSlots = {} --[[@type table<Barotrauma.InvSlotType, Set<Barotrauma.GUIButton>>]]

    -- for i=Constants.D_HUMAN_INV_N_ANY,D_HUMAN_INV_N,1 do
    --     selectedSlots[D_CREW_LOADOUT_SLOTS[i]] = Types.Set.new()
    -- end
    
    -- local basicSlots = {} --[[@type Iterable<Barotrauma.GUIButton>]]
    -- local limbSlots --[[@type Iterable<Barotrauma.GUIButton>]]

    -- local White = Color.White

    -- ---@param button Barotrauma.GUIButton
    -- ---@param obj any
    -- local function onSlotClicked(button, obj)
    --     local slot = button.GetChildByUserData(D_PADDING)

    --     if slot.Color == White then
    --         if button.ToolTip ~= nil then
    --             button.ToolTip = nil

    --             local itemImage = button.GetChild(Int32(button.CountChildren - 1))
    --             local itemData = itemImage.UserData --[[@type {id:(table<Barotrauma.Identifier, boolean>|Barotrauma.Identifier)?, quality:integer?, amount:integer?}]]
                
    --             if type(itemData.id) ~= "table" then
    --                 for i, otherButton in ipairs(limbSlots) do--[[@cast otherButton Barotrauma.GUIButton]]
    --                     local otherItemImage = otherButton.GetChild(Int32(otherButton.CountChildren - 1))
                        
    --                     if  otherItemImage and 
    --                         otherItemImage.UserData == itemData
    --                     then
    --                         local _, loadoutData = next(data[curJobIdx])

    --                         loadoutData[i + D_HUMAN_INV_N_ANY] = {}
    --                         selectedSlots[obj]:Remove(button)
    --                         otherButton.RemoveChild(otherItemImage)
    --                         otherButton.ToolTip = nil
    --                     end
    --                 end
    --             end
    --             callback(button)
    --             selectedSlots[obj]:Remove(button)
    --             button.RemoveChild(itemImage)
    --         else
    --             selectedSlots[obj]:Add(button)
    --             slot.Color = White*0.9
    --         end
    --     else
    --         selectedSlots[obj]:Remove(button)
    --         slot.Color = White
    --     end
    -- end
    local slots = {} --[[@type table<Barotrauma.InvSlotType, Set<ItemSlot>>]]
    local curJobIdx --[[@type integer]]
    local n = 0
    local jobIds = {} do  --[[@type Iterable<Barotrauma.Identifier>]]
        local jobPrefabs = {}

        for prefab in JobPrefab.Prefabs do
            if not prefab.HiddenJob then
                n = n + 1
                jobPrefabs[n] = prefab
            end
        end
        table.sort(jobPrefabs, function(v1, v2) return v1.Name.Value < v2.Name.Value end)

        for i=1,n,1 do
            jobIds[i] = jobPrefabs[i].Identifier
        end
    end
    
    
    local callback do
        local D_CREW_LOADOUT_SLOTS = Constants.D_CREW_LOADOUT_SLOTS

        ---@param itemPrefab? Barotrauma.ItemPrefab
        ---@param tag? Barotrauma.Identifier
        function callback(itemPrefab, tag)
            if itemPrefab then
                local foundAllSlots = false

                for slotSet in slots do --[[@cast slotSet Set<ItemSlot>]]
                    for slot in slotSet do --[[@cast slot ItemSlot]]
                        if slot:SetItemPrefab(itemPrefab) then
                            foundAllSlots = true
                            break
                        end
                    end
                    if foundAllSlots then break end
                end
            elseif tag then
                local itemIds = {[tag]=true}
                local foundSlot = false

                for slotSet in slots do --[[@cast slotSet Set<ItemSlot>]]
                    for slot in slotSet do --[[@cast slot ItemSlot]]
                        if slot:SetItemIds(itemIds) then
                            foundSlot = true
                            break
                        end
                    end
                    if foundSlot then break end
                end
            end

            local loadoutData do
                local builder
                local lastSlotType

                loadoutData, builder = util.itertools.CreateBuilder()

                for slotType in D_CREW_LOADOUT_SLOTS do --[[@cast slotType Barotrauma.InvSlotType]]
                    if slotType ~= lastSlotType then
                        for slot in slots[slotType] do --[[@cast slot ItemSlot]]
                            builder(slot:GetItemData())
                        end
                    end
                    lastSlotType = slotType
                end
            end
            --print(jobStrs[curJobIdx])
            
            allLoadoutData[jobIds[curJobIdx]] = loadoutData
            
            --print(allLoadoutStr)
            return changeAdder(allLoadoutData)

            --local _, loadoutData = next(allLoadoutStr[curJobIdx])

            -- for i, otherButton in ipairs(basicSlots) do
            --     if otherButton == button then
            --         loadoutData[i] = itemData
            --         return changeAdder(allLoadoutStr)
            --     end
            -- end
            -- for i, otherButton in ipairs(limbSlots) do
            --     if otherButton == button then
            --         loadoutData[i + D_HUMAN_INV_N_ANY] = itemData
            --         return changeAdder(allLoadoutStr)
            --     end
            -- end
        end
    end
    local innerGroup, orderedPrefabList = CreateItemPickerGui(innerFrame, callback, function(prefab) return prefab:SBAI_isHoldable() end)
--
    -- --local innerGroup = guiUtil.AddLayoutGroup(innerFrame, innerFrame.Rect.Size - Point(2*D_PADDING, 2*D_PADDING), GUI.Anchor.Center, nil, false, GUI.Anchor.TopCenter)
    innerGroup.AbsoluteSpacing = D_PADDING
    
    local topBarGroup = guiUtil.AddLayoutGroup(innerGroup, Point(innerGroup.Rect.Width - 4*D_PADDING, 128), GUI.Anchor.TopCenter, nil, true, GUI.Anchor.CenterLeft)
    --topBarGroup.CanBeFocused = true
    
    -- local jobs = {} --[[@type Barotrauma.JobPrefab[]|fun():Barotrauma.JobPrefab]]
    -- local n = 0

    -- for prefab in JobPrefab.Prefabs do
    --     if not prefab.HiddenJob then
    --         n = n + 1
    --         jobs[n] = prefab
    --     end
    -- end

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
    
    local leftArrowButton = guiUtil.AddButton(arrowGroup, Point(D_SLOT_SIZE, arrowGroup.Rect.Height/2), nil, "<", "GUIButtonRound", false)
    leftArrowButton.UserData = -1

    local numTextBlock = guiUtil.AddTextBlock(arrowGroup, Point(D_SLOT_SIZE, arrowGroup.Rect.Height), nil, "", nil, "SubheadingFont", GUI.Alignment.Center, false, true, false)
    
    local rightArrowButton = guiUtil.AddButton(arrowGroup, Point(D_SLOT_SIZE, arrowGroup.Rect.Height/2), nil, ">", "GUIButtonRound", false)
    rightArrowButton.UserData = 1

    --titleGroup.CanBeFocused = true
    local jobTextBlock = guiUtil.AddTextBlock(titleGroup, Point(titleGroup.Rect.Width, 3/4*D_SLOT_SIZE + D_PADDING), nil, nil, nil, "LargeFont", GUI.Alignment.BottomCenter, false, true, false)
    
    local separatorHorizontalLine = guiUtil.AddFrame(titleGroup, Vector2(1, 0), nil, "HorizontalLine")

    local titleTextBlock = guiUtil.AddTextBlock(titleGroup, Point(titleGroup.Rect.Width, 3/4*D_SLOT_SIZE), nil, TextManager.Get("GUI.config.crewloadouttitle"), nil, "LargeFont", GUI.Alignment.TopCenter, false, true, false)
    titleTextBlock.ToolTip = TextManager.get("GUI.tooltips.equipitems.crewloadouttitle")
    
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
    
    -- local SetQuality do
    --     local qualityColorSuffixes = {"Good", "Excellent", "Masterwork"}

    --     ---@param itemSlot Barotrauma.GUIButton
    --     ---@param itemData {id:(table<Barotrauma.Identifier, boolean>|Barotrauma.Identifier)?, quality:integer?, amount:integer?}
    --     function SetQuality(itemSlot, itemData)
    --         local quality = itemData.quality

    --         local qualityImage = itemSlot.GetChildByUserData(D_PADDING).GetChildByUserData("quality")
    --         qualityImage.Color = not quality ~= nil and GUI.Style["ItemQualityColor"..qualityColorSuffixes[quality + 1]] or Color.Transparent

    --         return callback(itemSlot, itemData)
    --     end
    -- end

    -- ---@param enableQuality boolean
    -- ---@param itemSlot Barotrauma.GUIButton
    -- ---@param userData any
    -- local function CreateRightClickMenu(enableQuality, itemSlot, userData)
    --     local itemData = itemSlot.GetChild(Int32(itemSlot.CountChildren - 1)).UserData --[[@type {id:(table<Barotrauma.Identifier, boolean>|Barotrauma.Identifier)?, quality:integer?, amount:integer?}]]
    --     local optionQuality = GUI.ContextMenuOption("sp.quality.qualitylevel.name", enableQuality)

    --     do
    --         local temp = {}

    --         for i=0,Components.Quality.MaxQuality,1 do
    --             temp[i + 1] = GUI.ContextMenuOption(TextManager.Capitalize(RichString.Rich(TextManager.GetFormatted("quality"..tostring(i))).SanitizedString), i ~= itemData.quality,
    --             function()
    --                 itemData.quality = i > 0 and i or nil
    --                 return SetQuality(itemSlot, itemData)
    --             end)
    --         end
    --         optionQuality.SubOptions = temp
    --     end

    --     return GUI.ContextMenu.CreateContextMenu(optionQuality)
    -- end

    local function setIndex(i)
        local curJobId = jobIds[i]

        curJobIdx = i

        local prefab = JobPrefab.Prefabs[curJobId]
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

        --local Prefabs = ItemPrefab.Prefabs

        -- for j=1,D_HUMAN_INV_N_ANY,1 do
        --     local itemData = loadoutData[j]
        --     local id = itemData.id
        --     local itemPrefab = type(id) == "userdata" and Prefabs[id] or nil
        --     local slot = basicSlots[j]

        --     if itemPrefab then
        --         local _itemData = {id=id, quality=itemData.quality, amount=itemData.amount}

        --         guiUtil.AddItemToSlot(slot, _itemData, itemPrefab)
        --         --slot.OnSecondaryClicked = util.functools.Partial1(CreateRightClickMenu, util.itertools.Any(util.xPath(itemPrefab.ConfigElement.Element, "//Quality")))
        --         --SetQuality(slot, _itemData)
        --     elseif id ~= nil then
        --         local _itemData = {id=id, quality=itemData.quality, amount=itemData.amount}

        --         guiUtil.AddTagsToSlot(slot, _itemData)
        --         --slot.OnSecondaryClicked = CreateRightClickMenu
        --         --SetQuality(slot, _itemData)
        --     end
        -- end
        -- for j=D_HUMAN_INV_N_ANY + 1,D_HUMAN_INV_N,1 do
        --     local itemData = loadoutData[j]
        --     local id = itemData.id
        --     local itemPrefab = type(id) == "userdata" and Prefabs[id] or nil --[[@type Barotrauma.ItemPrefab]]
        --     local slot = limbSlots[j - D_HUMAN_INV_N_ANY]
            
        --     if itemPrefab then
        --         guiUtil.AddItemToSlot(slot, itemData, itemPrefab)
        --         --slot.OnSecondaryClicked = util.functools.Partial1(CreateRightClickMenu, util.itertools.Any(util.xPath(itemPrefab.ConfigElement.Element, "//Quality")))
        --     elseif id ~= nil then
        --         local _itemData = {id=id, quality=itemData.quality, amount=itemData.amount}

        --         guiUtil.AddTagsToSlot(slot, _itemData)
        --         --slot.OnSecondaryClicked = CreateRightClickMenu
        --         --SetQuality(slot, _itemData)
        --     end
        -- end
    end

    ---@param mainButton Barotrauma.GUIButton
    ---@param itemSlot ItemSlot
    ---@return boolean
    local function onClicked(mainButton, itemSlot)
        if itemSlot:Selected() then
            return itemSlot:Selected(false)
        else
            if itemSlot:IsSet() then
                itemSlot:SetItemData()
                callback()
                return itemSlot:Selected(false)
            else
                return itemSlot:Selected(true)
            end
        end
    end

    local onSecondaryClicked do
        local Capitalize = TextManager.Capitalize
        local ContextMenuOption = GUI.ContextMenuOption
        local CreateBuilder = util.itertools.CreateBuilder
        local CreateContextMenu = GUI.ContextMenu.CreateContextMenu
        local Get = TextManager.Get
        local next = next
        local Partial1 = util.functools.Partial1
        local Rich = RichString.Rich
        local tostring = tostring
        local xPath = util.xPath

        local Quality = Constants.Quality

        -- ---@param itemSlot ItemSlot
        -- ---@param minAmount integer
        -- local function callbackAmount(itemSlot, minAmount)
        --     itemSlot:SetMinAmount(minAmount)
        --     return callback()
        -- end

        ---@param itemSlot ItemSlot
        ---@param minQuality Quality
        local function callbackQuality(itemSlot, minQuality)
            itemSlot:SetMinQuality(minQuality)
            return callback()
        end

        ---@param mainButton Barotrauma.GUIButton
        ---@param itemSlot ItemSlot
        ---@return boolean
        function onSecondaryClicked(mainButton, itemSlot)
            local itemPrefab = itemSlot:GetItemPrefab()
            local callbackQuality = Partial1(callbackQuality, itemSlot)
            --local callbackAmount = Partial1(callbackAmount, itemSlot)

            if itemPrefab then
                local minQualityValue = itemSlot:GetMinQuality()
                local optionQuality = ContextMenuOption("sp.quality.qualitylevel.name", (next(xPath(itemPrefab.ConfigElement.Element, "//Quality"))) ~= nil)
                local subOptionQuality, builder = CreateBuilder()

                for quality, qualityValue in next, Quality do
                    builder(ContextMenuOption(Capitalize(Rich(Get("quality"..tostring(qualityValue))).SanitizedString), minQualityValue ~= qualityValue, Partial1(callbackQuality, quality)))
                end

                optionQuality.SubOptions = subOptionQuality

                return CreateContextMenu(optionQuality)
            end
        end
    end

    local coIndex do
        local ClearTable = util.itertools.ClearTable
        local yield = coroutine.yield

        local Any = InvSlotType.Any
        local D_CREW_LOADOUT_SLOTS = Constants.D_CREW_LOADOUT_SLOTS

        coIndex = coroutine.wrap(
        function(i)
            while true do
                basicSlotsGroup.ClearChildren()
                limbSlotsGroup.ClearChildren()
                ClearTable(slots)
                --slots = {} --[[@type table<Barotrauma.InvSlotType, Set<ItemSlot>>]]

                do
                    local j = 0

                    for itemData in allLoadoutData[jobIds[i]] do
                        --print(itemData.itemPrefab)
                        j = j + 1

                        local slotType = D_CREW_LOADOUT_SLOTS[j]
                        local slot = ItemSlot.new(slotType == Any and basicSlotsGroup or limbSlotsGroup, nil, slotType, slots, orderedPrefabList)
                        
                        if  itemData.itemPrefab or
                            itemData.itemIds
                        then
                            slot:Selected(true)
                        end
                        slot:SetItemData(itemData)
                        slot:SetOnClicked(onClicked)
                        slot:SetOnSecondaryClicked(onSecondaryClicked)
                        --print(slot:GetItemPrefab())
                        
                        if j > D_HUMAN_INV_N then break end
                    end
                end
                -- basicSlotsGroup.ClearChildren()
                -- limbSlotsGroup.ClearChildren()
                -- for j=1,D_HUMAN_INV_N_ANY,1 do
                --     local button = guiUtil.AddEmptyItemSlot(basicSlotsGroup, nil, nil, true)

                --     button.OnClicked = onSlotClicked
                --     basicSlots[j] = button
                -- end
                -- limbSlots = {}
                -- for j=D_HUMAN_INV_N_ANY + 1,D_HUMAN_INV_N,1 do
                --     local button = guiUtil.AddEmptyItemSlot(limbSlotsGroup, nil, D_CREW_LOADOUT_SLOTS[j], true)

                --     button.OnClicked = onSlotClicked
                --     limbSlots[j - D_HUMAN_INV_N_ANY] = button
                -- end
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

    ---@param button Barotrauma.GUIButton
    ---@param obj `1`|`-1`
    local function onClicked(button, obj)
        return coIndex(obj)
    end

    leftArrowButton.OnClicked = onClicked
    leftArrowButton.ToolTip = TextManager.Get("previous")
    rightArrowButton.OnClicked = onClicked
    rightArrowButton.ToolTip = TextManager.Get("next")

    local closeButton = guiUtil.AddCloseButton(mainFrame, Point(D_SLOT_SIZE/2, D_SLOT_SIZE/2), GUI.Anchor.TopRight)
    closeButton.RectTransform.AbsoluteOffset = Point(2*D_PADDING, 4*D_PADDING)

    table.insert(closeButton.UserData,
    function(button, obj)
        return coIndex(0)
    end)

    coIndex(1)

    return mainFrame
end

return createCrewLoadoutGui