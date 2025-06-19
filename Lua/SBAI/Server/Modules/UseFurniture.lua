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
---@param ids table<FURNITURE,Set<Barotrauma.Identifier>>
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

    self:AddInit(
    function()
        _chairItems.Clear()
        for item in Item.ItemList do
            if idleFurnitureIds[item.Prefab.Identifier] then
                _chairItems.Add(item)
            end
        end
    end)
end

---@param self Types.Module
---@param options boolean
---@param ids table<FURNITURE, Set<Barotrauma.Identifier>>
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
    self:AddCommonModule("SBAI.Server.CommonModules.ItemPrefabExpansion")

    local chairId = Identifier("chair")
    local MapEntityCategory = util.registration.GetEnum("Barotrauma.MapEntityCategory")

    local Any = util.itertools.Any
    local new = Types.Set.new
    local setmetatable = setmetatable
    local xPath = util.xPath

    ---@type table<FURNITURE, fun(itemPrefab:Barotrauma.ItemPrefab):boolean>
    local predicateMap = {
        [FURNITURE.BED]=function(itemPrefab)
            if itemPrefab.Category == MapEntityCategory.Decorative then
                return Any(
                    xPath(itemPrefab.ConfigElement.Element,
                        "Controller[@canbeselected=true][@drawuserbehind=true]/RequiredItem[@items=deepdivinglarge][@requireempty=true]"))
            end
            return false
        end,
        [FURNITURE.CHAIR]=function(itemPrefab)
            return itemPrefab:SBAI_hasTag(chairId)
        end
    }

    local ids = setmetatable({}, { --[[@type table<FURNITURE, Set<Barotrauma.Identifier>>]]
        __index=function(t, k)
            local p = predicateMap[k]
            local out = new()
            t[k] = out
            
            for itemPrefab in ItemPrefab.Prefabs do
                if p(itemPrefab) then
                    out:Add(itemPrefab.Identifier)
                end
            end
            return out
        end
    })
    
    self:DoOption("AutoUseWhenIdle", activateAutoUseWhenIdle, ids)
    self:DoOption("stayInBedIfHurt", activateStayInBedIfHurt, ids)

    setmetatable(ids, nil)
end
    

---@param self Types.Module
local function deactivate(self)
    if _chairItems then
        local chairId = Identifier("chair")
        
        _chairItems.Clear()
        for item in Item.ItemList do
            if item.Prefab.Identifier == chairId then
                _chairItems.Add(item)
            end
        end
        _chairItems = nil
    end
end

return Types.Module.new(activate, deactivate)