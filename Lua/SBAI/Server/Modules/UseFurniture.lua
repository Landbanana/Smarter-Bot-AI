local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Item"], "_chairItems")

---@class Barotrauma.Item
---@field _chairItems System.Collections.Generic.List*1Barotrauma*Item

---@enum (key) FURNITURE
local FURNITURE = {
    BED=1,
    CHAIR=2
}

local ids --[[@type table<FURNITURE,Set>]]
local bedPredicate
local chairPredicate

do
    local Contains = util.itertools.Contains

    ---@param prefab Barotrauma.ItemPrefab
    ---@return boolean
    function chairPredicate(prefab)
        return Contains(prefab.Tags, "chair")
    end
end

do
    local MapEntityCategoryDecorative = LuaUserData.CreateEnumTable("Barotrauma.MapEntityCategory").Decorative
    
    local xPath = util.xPath
    
    ---@param prefab Barotrauma.ItemPrefab
    ---@return boolean
    function bedPredicate(prefab)
        if prefab.Category == MapEntityCategoryDecorative then
            local requiredItems = xPath(prefab.ConfigElement, "Controller[@canbeselected=true]/RequiredItem[@items=deepdivinglarge]")
    
            if  requiredItems and
                requiredItems[1].GetAttributeBool("requireempty", false)
            then
                return true
            end
        end
        return false
    end
end

local _chairItems

---@param self Types.Module
---@param options table
local function activateAutoUseWhenIdle(self, options)
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
local function activateStayInBedIfHurt(self, options)
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
    do
        ---@type table<FURNITURE,fun(prefab:Barotrauma.ItemPrefab):boolean>
        local predicateMap = {
            [FURNITURE.BED]=bedPredicate,
            [FURNITURE.CHAIR]=chairPredicate
        }

        local Prefabs = ItemPrefab.Prefabs
        local new = Types.Set.new

        ---@type table<FURNITURE,Set>
        ids = setmetatable({}, {
            ---@param t table<FURNITURE,table<Barotrauma.Identifier,true>>
            ---@param k FURNITURE
            ---@return table<Barotrauma.Identifier,true>
            __call=function(t, k) return t[k] end,
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

    self:DoOption("AutoUseWhenIdle", activateAutoUseWhenIdle)
    self:DoOption("stayInBedIfHurt", activateStayInBedIfHurt)

    setmetatable(ids, nil)
end

---@param self Types.Module
local function deactivate(self)
    if _chairItems then
        _chairItems.Clear()
        for item in util.FindItems(nil, Item.ItemList, "chair") do
            _chairItems.Add(item)
        end
        _chairItems = nil
    end
end

return Types.Module.new(activate, deactivate)