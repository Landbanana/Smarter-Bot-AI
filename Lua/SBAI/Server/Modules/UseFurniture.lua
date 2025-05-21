local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Item"], "_chairItems")

---@class Barotrauma.Item
---@field _chairItems System.Collections.Generic.List*1Barotrauma*Item

---@enum FURNITURE
local FURNITURE = {
    BED=1,
    CHAIR=2
}

local _chairItems

---@param self Types.Module
---@param options table
---@param ids table<FURNITURE,Set>
local function activateAutoUseWhenIdle(self, options, ids)
    local Item = Item

    self:RegisterStrongRef("Item._chairItems", "System.Collections.Generic.List`1[[Barotrauma.Item]]", "Barotrauma.Item",
    function(strongRef)
        _chairItems = strongRef
    end)

    local idleFurnitureIds = Types.Set.new()
    local optionToFURNITURE = {
        beds=FURNITURE.BED,
        chairs=FURNITURE.CHAIR
    }

    for k, v in next, options do
        if  k ~= "enable" and
            v == true
        then
            idleFurnitureIds:Update(ids[optionToFURNITURE[k]])
        end
    end

    self:AddInit(function()
        for item in Item.ItemList do --[[@cast item Barotrauma.Item]]
            if idleFurnitureIds[item.Prefab.Identifier] then
                _chairItems.Add(item)
            end
        end
    end)
end

---@param self Types.Module
---@param options boolean
---@param ids table<FURNITURE,Set>
local function activateStayInBedIfHurt(self, options, ids)
    local HumanInSafeHull = util.HumanInSafeHull
    local bedIds = ids[FURNITURE.BED]

    self:AddPatch("Barotrauma.AIObjectiveIdle", "Act", nil,
    function(instance, ptable)
        local character = instance.character
        local selectedItem = character.SelectedItem

        if  selectedItem and
            bedIds[selectedItem.Prefab.Identifier] and
            character.HealthPercentage < 100.0 and
            HumanInSafeHull(character)
        then
            ptable.PreventExecution = true
            return
        end
    end, Hook.HookMethodType.Before)
end

---@param self Types.Module
local function activate(self)
    local ids = {}

    do
        local chairId = Identifier("chair")
        local Decorative = self:RegisterEnumTable("Barotrauma.MapEntityCategory").Decorative
        local Prefabs = ItemPrefab.Prefabs

        local Any = util.itertools.Any
        local Contains = util.itertools.Contains
        local new = Types.Set.new
        local xPath = util.xPath

        ---@type table<FURNITURE,fun(prefab:Barotrauma.ItemPrefab):boolean>
        local predicateMap = {
            [FURNITURE.BED]=function(prefab)
                if prefab.Category == Decorative then
                    return Any(xPath(prefab.ConfigElement, "Controller[@canbeselected=true]/RequiredItem[@items=deepdivinglarge]"), function(item) return item.GetAttributeBool("requireempty", false) end)
                end
                return false
            end,
            [FURNITURE.CHAIR]=function(prefab)
                return Contains(prefab.Tags, chairId)
            end
        }

        ---@type table<FURNITURE,Set>
        setmetatable(ids, {
            ---@param t table<FURNITURE,table<Barotrauma.Identifier,true>>
            ---@param k FURNITURE
            ---@return table<Barotrauma.Identifier,true>
            __index=function(t, k)
                local predicate = predicateMap[k]

                if not predicate then error("Value not recognized as FURNITURE", 2) end

                local idSet = new()

                for prefab in Prefabs do
                    if predicate(prefab) then
                        idSet:Add(prefab.Identifier)
                    end
                end
                t[k] = idSet
                return t[k]
            end
        })
    end
    
    self:DoOption("AutoUseWhenIdle", activateAutoUseWhenIdle, ids)
    self:DoOption("stayInBedIfHurt", activateStayInBedIfHurt, ids)

    setmetatable(ids, nil)
end

---@param self Types.Module
local function deactivate(self)
    if _chairItems then
        local chairId = Identifier("chair")

        _chairItems.Clear()
        for item in Item.ItemList do --[[@cast item Barotrauma.Item]]
            if item.Prefab.Identifier == chairId then _chairItems.Add(item) end
        end
        _chairItems = nil
    end
end

return Types.Module.new(activate, deactivate)