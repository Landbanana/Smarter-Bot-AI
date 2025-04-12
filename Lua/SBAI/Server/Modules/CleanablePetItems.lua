local LuaUserData = LuaUserData

LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.ItemPrefab"], "PreferredContainers")

local petItemIdentifiers = {"poop", "mucusball", "chitin"}
local creepingorangePrefab = ItemPrefab.Find("", "creepingorange")

return function(namespace, options)
    LuaUserData.RegisterType("System.Collections.Immutable.ImmutableArray`1")

    local creepingorangeContainers = creepingorangePrefab.PreferredContainers

    for t in petItemIdentifiers do
        local success, prefab = pcall(ItemPrefab.Find, "", t)

        if  success and
            #prefab.PreferredContainers <= 0
        then
            prefab.PreferredContainers = creepingorangeContainers
        end
    end

    LuaUserData.UnregisterType("System.Collections.Immutable.ImmutableArray`1")
end