local HF = require("SBAI.Shared.helperfunctions")

local function GetLikelyBeds()
    local likelyBeds = {}

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
                            table.insert(likelyBeds, prefab)
                        end
                    end
                end
            end
        end
    end
    return likelyBeds
end

return function(namespace, options)
    for prefab in GetLikelyBeds() do
        HF.AddTagsToPrefab(prefab, Identifier("chair"))
    end
end,
function()
    for prefab in GetLikelyBeds() do
        HF.RemoveTagsFromPrefab(prefab, Identifier("chair"))
    end
end