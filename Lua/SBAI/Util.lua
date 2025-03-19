SBAI.Util = {}

function SBAI.Util.ListContains(list, item)
    for v in list do
        if v == item then
            return true
        end
    end
    return false
end

---@type fun(item:Barotrauma.Item):boolean
function SBAI.Util.IsCharged(item)
    local itemContainer = item.GetComponentString("ItemContainer") --[[@type Barotrauma.Items.Components.ItemContainer]]
    
    if itemContainer == nil then return false end
    
    for s in itemContainer.slotRestrictions do
        if s.MatchesItem(Identifier("mobilebattery")) and s.MaxStackSize == 1 then
            return true
        end
    end
    return false
end