local SBAI = require("SBAI")
local config = require("SBAI.config")

require("SBAI.Server.Items.Components.ItemContainer")

local SBAIUtils = {}

local readOnlyTable__newindex = function(_, _, _) error("attempt to modify a read-only table", 2) end
---@generic T: table
---@param t T
---@return T
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

---@type fun(list:table<integer, any>, obj:any):boolean
function SBAIUtils.ITableContains(table, obj)
    for _, v in ipairs(table) do
        if v == obj then
            return true
        end
    end
    return false
end

---@type fun(section:string, prevSection:string?):(string?, any?)
function SBAIUtils.CheckOptionGetNamespace(section, prevNamespace)
    if config.data[section].enabled then return (prevNamespace or SBAI.Namespace)..section, config.data[section] end
    return nil, nil
end

---@type fun(item: Barotrauma.Item, item: Barotrauma.Item): boolean
function SBAIUtils.IsSpecifiedContainer(container, item)
    local itemContainer = container.GetComponent(Components.ItemContainer) --[[@type Barotrauma.Items.Components.ItemContainer|nil]]

    if itemContainer == nil then return false end

    for s in itemContainer.slotRestrictions do
        if s.ContainableItems ~= nil and s.MatchesItem(item) then
            return true
        end
    end
    return false
end

return SBAIUtils.MakeReadOnlyTable(SBAIUtils)