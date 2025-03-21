local SBAI = require("SBAI")
local SBAIUtils = require("SBAI.SBAIUtils")

local Namespace = SBAI.Namespace.."ItemGroup."
local ItemGroup = {}

---@type fun(tagString:string)
function ItemGroup.Register(tagString)
    Util.RegisterItemGroup(Namespace..tagString, function(item)
        return item.HasTag(Identifier(tagString))
    end)
end

local ItemGroup_List_mt = {__index = function(t, k)
    t[k] = Util.GetItemGroup(Namespace..k)
    return t[k]
end}
ItemGroup.List = {}
local ItemGroup_Original = ItemGroup
setmetatable(ItemGroup.List, ItemGroup_List_mt)
Hook.Add("roundEnd", Namespace.."Reset", function() -- needed since Util.itemGroup is reset at roundEnd
    ItemGroup_Original.List = {} --[[@type table<string, Barotrauma.Item[]>]]
    setmetatable(ItemGroup_Original.List, ItemGroup_List_mt)
end)

ItemGroup = SBAIUtils.MakeReadOnlyTable(ItemGroup)
return ItemGroup