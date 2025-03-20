local SBAIUtils = {}

local readOnlyTable__newindex = function(_, _, _) error("attempted to modify a read-only table", 2) end
---@type fun(t:table):table
function SBAIUtils.MakeReadOnlyTable(t)
    local proxy = {} --[[@type table]]
    local mt = {__index=t, __newindex=readOnlyTable__newindex}

    setmetatable(proxy, mt)
    return proxy
end

---@type fun(list:any[], obj:any):boolean
function SBAIUtils.ListContains(list, obj)
    for v in list do
        if v == obj then
            return true
        end
    end
    return false
end

local ItemContainer_Descriptor = LuaUserData.RegisterType("Barotrauma.Items.Components.ItemContainer")
LuaUserData.MakeFieldAccessible(ItemContainer_Descriptor, "slotRestrictions")
LuaUserData.RegisterType("Barotrauma.Items.Components.ItemContainer+SlotRestrictions")

---@type fun(item: Barotrauma.Item, item: Barotrauma.Item): boolean
function SBAIUtils.IsSpecifiedContainer(container, item)
    local itemContainer = container.GetComponent(Components.ItemContainer) --[[@type Barotrauma.Items.Components.ItemContainer|nil]]

    if itemContainer == nil then return false end

    for s in itemContainer.slotRestrictions do
        if s.MatchesItem(item) and s.MaxStackSize == 1 then
            return true
        end
    end
    return false
end

SBAIUtils = SBAIUtils.MakeReadOnlyTable(SBAIUtils)
return SBAIUtils