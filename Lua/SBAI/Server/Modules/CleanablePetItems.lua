local util = require("SBAI.Shared.util")

LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.ItemPrefab"], "PreferredContainers")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Item"], "_cleanableItems")

local petItemIdentifiers = {"poop", "mucusball", "chitin"}

return function(namespace, options)
    local D_TEMPLATE_IDENTIFIER = "creepingorange"

    return util.DoWithTemporaryRegistrations({
        "System.Collections.Immutable.ImmutableArray`1[[Barotrauma.PreferredContainer,Barotrauma]]",
        "System.Collections.Generic.List`1[[Barotrauma.Item]]"
    },
    function()
        for t in petItemIdentifiers do
            local prefab = ItemPrefab.GetItemPrefab(t)
    
            if #prefab.PreferredContainers <= 0 then
                prefab.PreferredContainers = ItemPrefab.GetItemPrefab(D_TEMPLATE_IDENTIFIER).PreferredContainers
            end
        end

        local cleanableItems = Item._cleanableItems

        for item in Item.ItemList do --[[@cast item Barotrauma.Item]]
            if  util.ValsContain(petItemIdentifiers, item.Prefab.Identifier.Value) and
                not cleanableItems.Contains(item)
            then
                Item._cleanableItems.Add(item)
            end
        end
    end)
end,
function()
    return util.DoWithTemporaryRegistrations({"System.Collections.Immutable.ImmutableArray`1[[Barotrauma.PreferredContainer,Barotrauma]]"},
    function()
        for t in petItemIdentifiers do
            local prefab = ItemPrefab.GetItemPrefab(t)
            local oldPreferredContainers = prefab.PreferredContainers
    
            if #oldPreferredContainers > 0 then
                prefab.PreferredContainers = oldPreferredContainers.Clear()
            end
        end

        local cleanableList = Item._cleanableItems --[=[@type Barotrauma.Item[]]=]

        return util.DoWithTemporaryRegistrations({"System.Collections.Generic.List`1[[Barotrauma.Item]]"},
        function()
            local numIndices = 0
            local removeIndices = {} --[=[@type number[]]=]

            for i, item in ipairs(cleanableList) do
                if util.ValsContain(petItemIdentifiers, item.Prefab.Identifier.Value) then
                    numIndices = numIndices + 1
                    removeIndices[numIndices] = i - 1
                end
            end

            table.sort(removeIndices, function(i1, i2) return i1 > i2 end)

            for i in removeIndices do
                Item._cleanableItems.RemoveAt(i)
            end
        end)
    end)
end