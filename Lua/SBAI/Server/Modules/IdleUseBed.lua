local util = require("SBAI.Shared.util")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Item"], "_chairItems")

local function GetLikelyBeds()
    local likelyBeds = {}
    local i = 0

    for prefab in ItemPrefab.Prefabs do
        if prefab.Category == 2 then
            for element in prefab.ConfigElement.Elements() do
                if  element.Name.ToString():lower() == "controller" and
                    element.GetAttribute("canbeselected") then
                    for subElement in element.Elements() do
                        if subElement.Name.ToString():lower() == "requireditem" and
                            subElement.GetAttribute("items").value == "deepdivinglarge" and
                            subElement.GetAttribute("requireempty").Value == "true"
                        then
                            i = i + 1
                            likelyBeds[i] = prefab
                        end
                    end
                end
            end
        end
    end
    return likelyBeds
end

---@param namespace Namespace
---@param options table
return function(namespace, options)
    for prefab in GetLikelyBeds() do
        util.AddTagsToPrefab(prefab, "chair")
    end
end,
function()
    local likelyBeds = GetLikelyBeds()

    for prefab in likelyBeds do
        util.RemoveTagsFromPrefab(prefab, "chair")
    end
    
    for _, item in ipairs(Item.ItemList) do
        for prefab in likelyBeds do
            if item.Prefab == prefab then
                item.RemoveTag("chair")
            end
        end
    end
end