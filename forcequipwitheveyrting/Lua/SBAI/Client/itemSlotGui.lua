local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")
local guiUtil = require("SBAI.Client.guiUtil")

---@class ItemSlot
---@field public slotType Barotrauma.InvSlotType
---@field protected mainButton Barotrauma.GUIButton
---@field protected betterSlotSprite Barotrauma.Sprite
---@field protected slots? table<Barotrauma.InvSlotType, Set<ItemSlot>>
---@field protected group? Set<ItemSlot>
---@field private amountText Barotrauma.GUITextBlock
---@field private invSlotImage? Barotrauma.GUIImage
---@field private itemImage Barotrauma.GUIImage
---@field private itemData ItemData
---@field private lastItemData ItemData
---@field private filteredItemPrefabs Iterable<Barotrauma.ItemPrefab>
---@field private qualityImage Barotrauma.GUIImage
---@field private slotImage Barotrauma.GUIImage
---@field private tagImage Barotrauma.GUIImage
local ItemSlot = {
    itemData={
        minAmount=1,
        minQuality=Constants.Quality.Normal
    },
    slotType=InvSlotType.None
}
ItemSlot.__index = ItemSlot

ItemSlot.betterSlotSprite = Sprite(Inventory.SlotSpriteSmall.FilePath.Value, Rectangle(13, 10, 114, 114), nil, 0)

---@public
---@param v? boolean
---@return boolean?
function ItemSlot:Selected(v)
    if v == nil then
        if self.slots == nil then
            return not self:IsSet()
        else
            return self.mainButton.Selected
        end
    else
        self.mainButton.Selected = v
    end
end

---@public
---@return ItemData
function ItemSlot:GetItemData()
    return self.itemData
end

---@public
---@param itemData? ItemData
---@return boolean
function ItemSlot:SetItemData(itemData)
    if  itemData and
        not self:Selected()
    then
        return false
    end
    return self:setItemData(itemData)
end

do
    local Empty = Identifier.Empty

    local next = next

    ---@public
    ---@return Barotrauma.Identifier
    function ItemSlot:GetItemTag()
        local itemPrefab = self:GetItemPrefab()

        if itemPrefab then
            return itemPrefab.Identifier
        else
            local itemIds = self.itemData.itemIds

            if itemIds then
                local tag, v = next(itemIds)

                if v then return tag end
            end
        end
        return Empty
    end
end

do
    local Empty = Identifier.Empty

    ---@public
    ---@return boolean
    function ItemSlot:IsSet()
        return self:GetItemTag() ~= Empty
    end
end

---@public
---@return Barotrauma.ItemPrefab?
function ItemSlot:GetItemPrefab()
    return self.itemData.itemPrefab
end

do
    local Any = InvSlotType.Any
    local None = InvSlotType.None

    local new = Types.Set.new

    ---@public
    ---@param itemPrefab? Barotrauma.ItemPrefab
    ---@return boolean
    function ItemSlot:SetItemPrefab(itemPrefab)
        if itemPrefab then
            local allSlotsFound = false

            if self:Selected() then
                local reg, comp = itemPrefab:SBAI_getInvSlots()
                local slotType = self.slotType

                if  reg[slotType] or
                    slotType == None
                then
                    allSlotsFound = true
                    goto trySetItemData
                elseif slotType ~= Any then
                    local slots = self.slots

                    if slots then
                        local group

                        for slotTypeSet in comp do --[[@cast slotTypeSet Set<Barotrauma.InvSlotType>]]
                            slotTypeSet:Remove(slotType)
                            group = new()
                            for slotTypeTarget in slotTypeSet do --[[@cast slotTypeTarget Barotrauma.InvSlotType]]
                                for otherItemSlot in slots[slotTypeTarget] do --[[@cast otherItemSlot ItemSlot]]
                                    if otherItemSlot:Selected() then
                                        group:Add(otherItemSlot)
                                        slotTypeSet:Remove(otherItemSlot.slotType)
                                        if slotTypeSet:IsEmpty() then
                                            allSlotsFound = true
                                            self.group = group
                                            goto trySetItemData
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                ::trySetItemData::
                if allSlotsFound then
                    local itemData = self:getDefaultItemData(true)

                    itemData.itemPrefab = itemPrefab
                    return self:SetItemData(itemData)
                end
            end
        else
            return self:SetItemData()
        end
        return false
    end
end

do
    local Prefabs = ItemPrefab.Prefabs

    local CreateBuilder = util.itertools.CreateBuilder

    ---@public
    ---@return Iterable<Barotrauma.Identifier>
    function ItemSlot:GetItemIds()
        local itemIds = self.itemData.itemIds
        local out, builder = CreateBuilder()
        
        if itemIds then
            for prefab in Prefabs do
                local id = prefab.Identifier
                local v = itemIds[id]

                if v == false then goto continue end

                for tag in prefab.Tags do
                    local u = itemIds[tag]

                    if u == false then
                        v = false
                        break
                    end

                    v = v or u
                end
                if v == true then
                    builder(id)
                end
                ::continue::
            end
        else
            local itemPrefab = self:GetItemPrefab()
            
            if itemPrefab then
                for tag in itemPrefab.Tags do
                    builder(tag)
                end
            end
        end
        return out
    end
end

---@public
---@param itemIds? table<Barotrauma.Identifier, boolean>
---@return boolean
function ItemSlot:SetItemIds(itemIds)
    if self.slots then
        if itemIds then
            if self:Selected() then
                local itemData = self:getDefaultItemData(true)

                itemData.itemIds = itemIds
                return self:SetItemData(itemData)
            end
        else
            return self:SetItemData()
        end
    end
    return false
end

---@public
---@return QualityValue
function ItemSlot:GetMinQuality()
    return self.itemData.minQuality
end

do
    local Quality = Constants.Quality

    ---@public
    ---@return QualityValue
    function ItemSlot:GetMinQualityStr()
        local minQuality = self.itemData.minQuality

        for minQualityStr, q in next, Quality do
            if q == minQuality then return minQualityStr end
        end
    end
end

---@public
---@param minQuality? Quality
---@return boolean
function ItemSlot:SetMinQuality(minQuality)
    if  minQuality and
        not self:IsSet()
    then
        return false
    end
    return self:setMinQuality(minQuality)
end

---@public
---@return integer
function ItemSlot:GetMinAmount()
    return self.itemData.minAmount
end

---@public
---@param minAmount? integer
---@return boolean
function ItemSlot:SetMinAmount(minAmount)
    if  minAmount and
        not self:IsSet()
    then
        return false
    end
    return self:setMinAmount(minAmount)
end

---@public
---@return Barotrauma.GUIComponent?
function ItemSlot:GetParent()
    return self.mainButton.Parent
end

---@public
---@param component? Barotrauma.GUIComponent
function ItemSlot:SetParent(component)
    self.mainButton.Parent = component
end

---@public
---@param f fun(mainButton:Barotrauma.GUIButton, itemSlot:ItemSlot):boolean
function ItemSlot:SetOnClicked(f)
    self.mainButton.OnClicked = f
end

---@public
---@param f fun(mainButton:Barotrauma.GUIButton, itemSlot:ItemSlot):boolean
function ItemSlot:SetOnSecondaryClicked(f)
    self.mainButton.OnSecondaryClicked = f
end

do
    local AddButton = guiUtil.AddButton
    local AddImage = guiUtil.AddImage
    local AddTextBlock = guiUtil.AddTextBlock
    local new = Types.Set.new
    local setmetatable = setmetatable
    
    local betterSlotSprite = ItemSlot.betterSlotSprite
    
    local AlignmentBottomRight = GUI.Alignment.BottomRight
    local AnchorBottomRight = GUI.Anchor.BottomRight
    local Center = GUI.Anchor.Center
    local D_SLOT_SIZE_POINT = Point(55, 55)
    local EquipmentSlotIconColor = GUI.Style.EquipmentSlotIconColor
    local LimbSlotIcons = CharacterInventory.LimbSlotIcons
    local None = InvSlotType.None
    local One = Vector2.One
    local PaleGoldenrod = Color.PaleGoldenrod
    local TopLeft = GUI.Anchor.TopLeft
    local Vector2 = Vector2
    local Vector4 = Vector4

    local mt_slots = {
        __index=function(self, slotType)
            local out = new()

            self[slotType] = out
            return out
        end
    }
    
    ---@public
    ---@param parent Barotrauma.GUIComponent
    ---@param anchor Barotrauma.Anchor
    ---@param slotType? Barotrauma.InvSlotType
    ---@param slots? table<Barotrauma.InvSlotType, Set<ItemSlot>>
    ---@param filteredItemPrefabs Iterable<Barotrauma.ItemPrefab>
    ---@return ItemSlot
    function ItemSlot.new(parent, anchor, slotType, slots, filteredItemPrefabs)
        local self = setmetatable({filteredItemPrefabs=filteredItemPrefabs}, ItemSlot)

        local mainButton = AddButton(parent, D_SLOT_SIZE_POINT, anchor, nil, "null")
        self.mainButton = mainButton
        mainButton.UserData = self
        
        local slotImage = AddImage(mainButton, One, Center, betterSlotSprite, true)
        self.slotImage = slotImage
        slotImage.CanBeFocused = false
        slotImage.SelectedColor = EquipmentSlotIconColor.Value
        slotImage.HoverColor = PaleGoldenrod

        if slotType then
            self.slotType = slotType

            local invSlotImage = AddImage(slotImage, One, Center, LimbSlotIcons[slotType], true)
            self.invSlotImage = invSlotImage
            invSlotImage.CanBeFocused = false
            invSlotImage.Color = EquipmentSlotIconColor.Value
            invSlotImage.HoverColor = PaleGoldenrod
        end

        if slots then
            setmetatable(slots, mt_slots)
            if slotType ~= None then
                slots[slotType]:Add(self)
                self.slots = slots
            end
        else
            mainButton.CanBeSelected = false
        end

        local qualityImage = AddImage(slotImage, One, Center, "InnerGlowSmall", true)
        self.qualityImage = qualityImage
        qualityImage.Visible = false
        qualityImage.CanBeFocused = false

        local itemImage = AddImage(slotImage, Vector2(0.95, 0.95), Center, nil, true)
        self.itemImage = itemImage
        itemImage.CanBeFocused = false

        local tagImage do
            local tagColor = PaleGoldenrod*0.75

            tagImage = AddImage(slotImage, Vector2(0.5, 0.5), TopLeft, "StoreDealIcon", true)
            self.tagImage = tagImage
            tagImage.Visible = false
            tagImage.CanBeFocused = false
            tagImage.Color = tagColor
            tagImage.HoverColor = tagColor
            tagImage.SelectedColor = tagColor
            tagImage.PressedColor = tagColor
        end
        
        local amountText = AddTextBlock(slotImage, Vector2(0.5, 0.5), AnchorBottomRight, "x1", nil, "SmallFont", AlignmentBottomRight, false, true, false)
        self.amountText = amountText
        amountText.Visible = false
        amountText.CanBeFocused = false
        amountText.Padding = Vector4(0,0,4,2)
        return self
    end
end

do
    local CopyTable = util.itertools.CopyTable
    local getmetatable = getmetatable

    ---@protected
    ---@param makeCopy boolean
    ---@return ItemData
    function ItemSlot:getDefaultItemData(makeCopy)
        local defaultItemData = getmetatable(self).itemData

        defaultItemData = (not makeCopy) and defaultItemData or CopyTable(defaultItemData)

        return defaultItemData
    end
end

do
    local Quality = Constants.Quality

    ---@protected
    ---@param itemData? ItemData
    ---@return boolean
    function ItemSlot:setItemData(itemData)
        self.itemData = itemData

        if itemData then
            local itemPrefab = itemData.itemPrefab
            local itemIds = itemData.itemIds

            if itemPrefab then
                self:setItemPrefab(itemPrefab)
            elseif itemIds then
                self:setItemIds(itemIds)
            else
                return false
            end

            self:setMinAmount(itemData.minAmount or 1)

            local quality
            local minQuality = itemData.minQuality

            repeat
                local qualityValue

                quality, qualityValue = next(Quality, quality)
            until qualityValue == minQuality or quality == nil
            self:setMinQuality(quality or "Normal")

            local group = self.group
            
            if group then
                for itemSlot in group do --[[@cast itemSlot ItemSlot]]
                    itemSlot:setItemData(itemData)
                    itemSlot.group = group
                end
                group:Add(self)
            end
            self:Selected(false)
        else
            local group = self.group

            if group then
                self.group = nil
                group:Remove(self)
                for itemSlot in group do --[[@cast itemSlot ItemSlot]]
                    itemSlot:setItemData()
                end
            end
            self:setItemIds()
            self:setMinAmount()
            self:setMinQuality()
        end
        local invSlotImage = self.invSlotImage

        if invSlotImage then
            self.invSlotImage.Visible = self.itemImage.Sprite == nil
        end
        return true
    end
end

---@protected
---@param itemPrefab? Barotrauma.ItemPrefab
---@return boolean
function ItemSlot:setItemPrefab(itemPrefab)
    local sprite = itemPrefab.InventoryIcon or itemPrefab.Sprite
    local group = self.group

    if group then
        for itemSlot in group do --[[@cast itemSlot ItemSlot]]
                itemSlot.itemImage.Sprite = sprite
                itemSlot:updateToolTip()
            end
        end
    self.itemImage.Sprite = sprite
    return self:updateToolTip()
end

---@protected
---@param itemIds? table<Barotrauma.Identifier, boolean>
---@return boolean
function ItemSlot:setItemIds(itemIds)
    local tagVisible = false
    local sprite

    if itemIds then
        local targetTag = self:GetItemTag()
        local itemPrefab

        for prefab in self.filteredItemPrefabs do
            if prefab:SBAI_hasTag(targetTag) then
                if prefab.ContentPackage.NameMatches("Vanilla") then
                    itemPrefab = prefab
                    break
                elseif not itemPrefab then
                    itemPrefab = prefab
                end
            end
        end
        if itemPrefab then
            sprite = itemPrefab.InventoryIcon or itemPrefab.Sprite
            tagVisible = true
        end
    end

    local group = self.group

    if group then
        for itemSlot in group do --[[@cast itemSlot ItemSlot]]
            itemSlot.tagImage.Visible = tagVisible
            itemSlot.itemImage.Sprite = sprite
            itemSlot:updateToolTip()
        end
    end
    self.tagImage.Visible = tagVisible
    self.itemImage.Sprite = sprite
    return self:updateToolTip()
end

do
    local Transparent = Color.Transparent
    local Normal = Constants.Quality.Normal
    local Quality = Constants.Quality
    local GetQualityColor = GUI.Style.GetQualityColor

    ---@protected
    ---@param minQuality Quality
    ---@return boolean
    function ItemSlot:setMinQuality(minQuality)
        local color
        local isVisible
        local minQualityValue

        if  minQuality ~= nil and
            minQuality ~= "Normal"
        then
            isVisible = true
            minQualityValue = Quality[minQuality]
            color = GetQualityColor(minQualityValue)*0.7
        else
            isVisible = false
            minQualityValue = Normal
            color = Transparent
        end

        local group = self.group
        
        if group then
            for itemSlot in group do
                local qualityImage = itemSlot.qualityImage
                qualityImage.Color = color
                qualityImage.Visible = isVisible

                itemSlot.itemData.minQuality = minQualityValue
                itemSlot:updateToolTip()
            end
        end
        local qualityImage = self.qualityImage
        qualityImage.Color = color
        qualityImage.Visible = isVisible

        self.itemData.minQuality = minQualityValue
        return self:updateToolTip()
    end
end

do
    ---@param minAmount integer
    ---@return boolean
    function ItemSlot:setMinAmount(minAmount)
        local isVisible

        if  minAmount ~= nil and
            minAmount > 1
        then
            isVisible = true
        else
            isVisible = false
        end

        local group = self.group

        if group then
            for itemSlot in group do
                itemSlot.amountText.Visible = isVisible
                itemSlot.itemData.minAmount = minAmount
                itemSlot:updateToolTip()
            end
        end
        self.amountText.Visible = isVisible
        self.itemData.minAmount = minAmount
        return self:updateToolTip()
    end
end

do
    local concat = table.concat
    local CreateBuilder = util.itertools.CreateBuilder
    local Get = TextManager.Get
    local GetWithVariable = TextManager.GetWithVariable
    local Rich = RichString.Rich
    local tostring = tostring
    local xPath = util.xPath

    ---@protected
    ---@return boolean
    function ItemSlot:updateToolTip()
        local itemData = self.itemData
        -- local doUpdate = false do
        --     local lastItemData = self.lastItemData

        --     if lastItemData ~= itemData then
        --         doUpdate = true
        --         self.lastItemData = itemData
        --     else
        --         for k, v in next, itemData do
        --             if lastItemData[k] ~= v then
        --                 doUpdate = true
        --                 break
        --             end
        --         end
        --     end
        -- end

        -- if doUpdate then
            local itemPrefab = itemData.itemPrefab
            local itemIds = itemData.itemIds
            local toolTip

            if itemPrefab then
                local itemPrefabToolTip = itemPrefab.GetTooltip().Value
                local itemName, itemDescription = itemPrefabToolTip:match("^([^\n]+)(\n.+)$")
                local joinT, builder = CreateBuilder()

                builder(itemName or itemPrefabToolTip)
                builder(" (ID: ")
                builder(itemPrefab.Identifier.Value)
                builder(")")
                if (next(xPath(itemPrefab.ConfigElement.Element, "//Quality"))) ~= nil then
                    builder("\n")
                    builder(GetWithVariable("itemname.quality"..tostring(self:GetMinQuality()), "[itemname]", "").TrimStart().Value)
                end
                if itemName then builder(itemDescription) end
                toolTip = concat(joinT)
            elseif itemIds then
                local targetTag = self:GetItemTag()
                local joinT, builder = CreateBuilder()

                builder(Get("sp.item.tags.name").Value)
                builder(": ")
                builder(targetTag.Value)

                local excludedT, excludedBuilder = CreateBuilder()
                local hasExclusions = false

                for id, v in next, itemIds do
                    if not v then
                        excludedBuilder(id.Value)
                        hasExclusions = true
                    end
                end
                if hasExclusions then
                    builder("\nExcluding: ")
                    builder(concat(excludedT, ", "))
                end
                toolTip = concat(joinT)
            else
                self.mainButton.ToolTip = nil
            end
            self.mainButton.ToolTip = Rich(toolTip)
            return true
        -- end
    end
end

return ItemSlot