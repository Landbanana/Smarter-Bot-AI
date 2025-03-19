table.insert(SBAI.Namespace, "ItemGroup")

local itemGroup_mt = {__index = function(t, k)
    t[k] = Util.GetItemGroup("SBAI."..k)
    return t[k]
end}

local function Reset()
    SBAI.itemGroup = {} --[[@type table<string, Barotrauma.Item[]>]]
    setmetatable(SBAI.itemGroup, itemGroup_mt)
end

-- needed since Util.itemGroup is reset at roundEnd
Hook.Add("roundEnd", SBAI.GetNamespace()..".Reset", Reset)
Reset()

---@type fun(groupName:string, func:fun(item:Barotrauma.Item):boolean)
local function RegisterItemGroup(groupName, func)
    Util.RegisterItemGroup("SBAI."..groupName, func)
end

RegisterItemGroup("allChargers", function(item)
    if  item.HasTag(Identifier("batterycellrecharger")) and
        item.InPlayerSubmarine              then
        return true
    else
        return false
    end
end)

RegisterItemGroup("allDeconstructors", function(item)
    if  item.GetComponent(Components.Deconstructor) ~= nil then
        return true
    else
        return false
    end
end)

RegisterItemGroup("allCharged", function(item)
    if  item.HasTag(Identifier("SBAICharged")) then
        return true
    else
        return false
    end
end)

RegisterItemGroup("allBatteries", function(item)
    if  item.HasTag(Identifier("mobileBattery")) then
        return true
    else
        return false
    end
end)

table.remove(SBAI.Namespace)