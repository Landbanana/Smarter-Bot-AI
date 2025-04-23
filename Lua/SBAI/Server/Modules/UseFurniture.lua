local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Item"], "_chairItems")

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveIdle"], "Act")

---@enum (key) FURNITURE
local FURNITURE = {
    BED=1,
    CHAIR=2
}

local ids --[[@type table<FURNITURE,table<Barotrauma.Identifier,true>>]]
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
    local idleFurniture = {}
    local idleFurnitureList = setmetatable(self:RegisterTable("ROUND_END"), {
        __call=function(t)
            if not t.data then
                do
                    local ItemList = util.UnregisteredStaticDescriptors["System.Collections.Generic.List`1[[Barotrauma.Item]]"]

                    t.data = LuaUserData.CreateUserDataFromDescriptor(ItemList.Static(Item, {}), ItemList.Descriptor)
                end

                for item in Item.ItemList do --[[@cast item Barotrauma.Item]]
                    local id = item.Prefab.Identifier

                    for idSet in idleFurniture do
                        if idSet[id] then
                            t.data.Add(item)
                            break
                        end
                    end
                end
            end
            return t.data
        end
    })

    do
        local optionToFurniture = {
            beds=FURNITURE.BED,
            chairs=FURNITURE.CHAIR
        }
        local i = 0

        for k, v in pairs(options) do
            if  k ~= "enable" and
                v == true
            then
                i = i + 1
                idleFurniture[i] = ids[optionToFurniture[k]]
            end
        end
    end

    self:AddHook("roundStart",
    function()
        return idleFurnitureList()
    end)

    self:AddPatch("Barotrauma.Item", "get_ChairItems", nil,
    function(instance, ptable)
        ptable.PreventExecution = true

        return idleFurnitureList()
    end, Hook.HookMethodType.Before)

    idleFurnitureList()
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
    ---@type table<FURNITURE,fun(prefab:Barotrauma.ItemPrefab):boolean>
    local predicateMap = {
        [FURNITURE.BED]=bedPredicate,
        [FURNITURE.CHAIR]=chairPredicate
    }

    ---@type table<FURNITURE,table<Barotrauma.Identifier,true>>
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

            local idSet = {}

            for prefab in ItemPrefab.Prefabs do
                if predicate(prefab) then
                    idSet[prefab.Identifier] = true
                end
            end
            t[k] = idSet
            return t[k]
        end
    })

    local optionName = "AutoUseWhenIdle"
    local section = self.options[optionName]

    if section.enable then
        self.namespace = self.namespace + optionName
        activateAutoUseWhenIdle(self, section)
        self.namespace = -self.namespace
    end

    optionName = "stayInBedIfHurt"

    if self.options[optionName] then
        self.namespace = self.namespace + optionName
        activateStayInBedIfHurt(self)
        self.namespace = -self.namespace
    end
end

return Types.Module.new(activate)