local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Item"], "_chairItems")

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveIdle"], "Act")

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
    
    ---@param prefab Barotrauma.ItemPrefab
    ---@return boolean
    function bedPredicate(prefab)
        if prefab.Category == MapEntityCategoryDecorative then
            for controller in prefab.ConfigElement.Element.Elements("Controller") do
                if  controller.GetAttributeBool("canbeselected", false) and
                    controller.GetAttributeBool("drawuserbehind", false)
                then
                    for requiredItem in controller.Elements("RequiredItem") do
                        local itemsArray = requiredItem.GetAttributeIdentifierArray("items")

                        if  itemsArray and
                            #itemsArray == 1 and
                            itemsArray[1] == "deepdivinglarge" and
                            requiredItem.GetAttributeBool("requireempty", false)
                        then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end
end

---@param self Types.Module
---@param options table
local function activateAutoUseWhenIdle(self, options)
    -- local data

    -- do
    --     local ItemList = util.UnregisteredStaticDescriptors["System.Collections.Generic.List`1[[Barotrauma.Item]]"]
    --     data = LuaUserData.CreateUserDataFromDescriptor(ItemList.Static(Item, {}), ItemList.Descriptor)
    -- end

    -- local idleFurniture = self:RegisterTable({data=data, init=false}, "ROUND_END")

    -- do
    --     local idleFurnitureIds = Types.Set.new()

    --     do
    --         local optionToFURNITURE = {
    --             beds=FURNITURE.BED,
    --             chairs=FURNITURE.CHAIR
    --         }
    --         for k, v in pairs(options) do
    --             if  k ~= "enable" and
    --                 v == true
    --             then
    --                 idleFurnitureIds:Update(ids[optionToFURNITURE[k]])
    --             end
    --         end
    --     end

    --     local Item = Item

    --     setmetatable(idleFurniture, {
    --         __call=function(t)
    --             if t.init == false then
                    
    --             end
    --             return t.data
    --         end
    --     })
    -- end
    local idleFurnitureIds = Types.Set.new()
    local loadChairItems

    do
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
    end

    do
        local Item = Item

        local DoWithTemporaryRegistrations = util.DoWithTemporaryRegistrations
        local Partial2 = util.functools.Partial2

        loadChairItems = Partial2(DoWithTemporaryRegistrations, {"System.Collections.Generic.List`1[[Barotrauma.Item]]"},
        function()
            local chairItems = Item._chairItems

            chairItems.Clear()
            for item in Item.ItemList do --[[@cast item Barotrauma.Item]]   
                if idleFurnitureIds[item.Prefab.Identifier] then
                    chairItems.Add(item)
                end
            end
        end)
    end

    self:AddHook("roundStart", loadChairItems)

    -- self:AddPatch("Barotrauma.Item", "get_ChairItems", nil,
    -- function(instance, ptable)
    --     ptable.PreventExecution = true

    --     return idleFurniture()
    -- end, Hook.HookMethodType.Before)

    loadChairItems()
end

---@param self Types.Module
local function activateStayInBedIfHurt(self)
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
    return util.DoWithTemporaryRegistrations({"System.Collections.Generic.List`1[[Barotrauma.Item]]"},
    function()
        local chairItems = Item._chairItems

        chairItems.Clear()
        for item in util.FindItems(nil, Item.ItemList, "chair") do
            chairItems.Add(item)
        end
    end)
end

return Types.Module.new(activate, deactivate)