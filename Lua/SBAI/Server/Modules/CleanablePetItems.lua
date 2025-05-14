local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.ItemPrefab"], "PreferredContainers")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Item"], "_cleanableItems")

local petItemIds = Types.Set.new()

do
    local GetItemPrefab = ItemPrefab.GetItemPrefab
    local xPath = util.xPath

    for prefab in CharacterPrefab.Prefabs do
        for xSubElement in xPath(prefab.ConfigElement, "ai/petbehavior/itemproduction/item") do --[[@cast xSubElement Barotrauma.ContentXElement]]
            if xSubElement then
                local itemId = xSubElement.GetAttributeIdentifier("identifier")

                if itemId.Value ~= "" then
                    petItemIds:Add(itemId)
                end
            end
        end
    end

    for id in next, petItemIds do
        local prefab = GetItemPrefab(id)

        if prefab then
            local xElement = prefab.ConfigElement

            if #xPath(xElement, "PreferredContainer") > 0 then
                petItemIds:Remove(id)
            end
        end
    end
end

---@param self Types.Module
local function activate(self)
    local Item = Item
    local GetItemPrefab = ItemPrefab.GetItemPrefab

    return util.DoWithTemporaryRegistrations({
        "System.Collections.Immutable.ImmutableArray`1[[Barotrauma.PreferredContainer,"..Constants.CLR_TYPE_POSTFIX.."]]",
        "System.Collections.Generic.List`1[[Barotrauma.Item]]"
    },
    function()
        local newPrefConts = GetItemPrefab(Constants.D_PETITEM_TEMPLATE).PreferredContainers

        for id in next, petItemIds do
            local prefab = GetItemPrefab(id)
    
            if #prefab.PreferredContainers <= 0 then
                prefab.PreferredContainers = newPrefConts
            end
        end

        local cleanableItems = Item._cleanableItems --[[@type System.Collections.Generic.List*1Barotrauma*Item]]

        for item in Item.ItemList do --[[@cast item Barotrauma.Item]]
            if  petItemIds[item.Prefab.Identifier] and
                not cleanableItems.Contains(item)
            then
                Item._cleanableItems.Add(item)
            end
        end
    end)
end

---@param self Types.Module
local function deactivate(self)
    local Item = Item
    local GetItemPrefab = ItemPrefab.GetItemPrefab

    local DoWithTemporaryRegistrations = util.DoWithTemporaryRegistrations
    local sort = table.sort

    return DoWithTemporaryRegistrations({"System.Collections.Immutable.ImmutableArray`1[[Barotrauma.PreferredContainer,"..Constants.CLR_TYPE_POSTFIX.."]]"},
    function()
        for id in next, petItemIds do
            local prefab = GetItemPrefab(id)
            local oldPrefConts = prefab.PreferredContainers
    
            if #oldPrefConts > 0 then
                prefab.PreferredContainers = oldPrefConts.Clear()
            end
        end

        local cleanableList = Item._cleanableItems --[=[@type Barotrauma.Item[]]=]

        return DoWithTemporaryRegistrations({"System.Collections.Generic.List`1[[Barotrauma.Item]]"},
        function()
            local numIndices = 0
            local removeIndices = {} --[=[@type integer[]]=]

            for i, item in ipairs(cleanableList) do
                if petItemIds[item.Prefab.Identifier] then
                    numIndices = numIndices + 1
                    removeIndices[numIndices] = i - 1
                end
            end

            sort(removeIndices, function(i1, i2) return i1 > i2 end)

            for i in removeIndices do --[[@cast i integer]]
                Item._cleanableItems.RemoveAt(i)
            end
        end)
    end)
end

return Types.Module.new(activate, deactivate)