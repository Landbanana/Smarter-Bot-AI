local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.ItemPrefab"], "PreferredContainers")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Item"], "_cleanableItems")

local petItemIds = {"poop", "mucusball", "chitin"}

---@param self Types.Module
local function activate(self)
    return util.DoWithTemporaryRegistrations({
        "System.Collections.Immutable.ImmutableArray`1[[Barotrauma.PreferredContainer,Barotrauma]]",
        "System.Collections.Generic.List`1[[Barotrauma.Item]]"
    },
    function()
        local newPrefConts = ItemPrefab.GetItemPrefab(Constants.D_PETITEM_TEMPLATE).PreferredContainers

        for t in petItemIds do
            local prefab = ItemPrefab.GetItemPrefab(t)
    
            if #prefab.PreferredContainers <= 0 then
                prefab.PreferredContainers = newPrefConts
            end
        end

        local cleanableItems = Item._cleanableItems --[[@type System.Collections.Generic.List*1Barotrauma*Item]]

        for item in Item.ItemList do --[[@cast item Barotrauma.Item]]
            if  util.ValsContain(petItemIds, item.Prefab.Identifier.Value) and
                not cleanableItems.Contains(item)
            then
                Item._cleanableItems.Add(item)
            end
        end
    end)
end

---@param self Types.Module
local function deactivate(self)
    return util.DoWithTemporaryRegistrations({"System.Collections.Immutable.ImmutableArray`1[[Barotrauma.PreferredContainer,Barotrauma]]"},
    function()
        for t in petItemIds do
            local prefab = ItemPrefab.GetItemPrefab(t)
            local oldPrefConts = prefab.PreferredContainers
    
            if #oldPrefConts > 0 then
                prefab.PreferredContainers = oldPrefConts.Clear()
            end
        end

        local cleanableList = Item._cleanableItems --[=[@type Barotrauma.Item[]]=]

        return util.DoWithTemporaryRegistrations({"System.Collections.Generic.List`1[[Barotrauma.Item]]"},
        function()
            local numIndices = 0
            local removeIndices = {} --[=[@type number[]]=]

            for i, item in ipairs(cleanableList) do
                if util.ValsContain(petItemIds, item.Prefab.Identifier.Value) then
                    numIndices = numIndices + 1
                    removeIndices[numIndices] = i - 1
                end
            end

            table.sort(removeIndices, function(i1, i2) return i1 > i2 end)

            for i in removeIndices do --[[@cast i number]]
                Item._cleanableItems.RemoveAt(i)
            end
        end)
    end)
end

return Types.Module.new(activate, deactivate)