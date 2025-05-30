local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

---@param self Types.CommonModule
local function activate(self)
    local AddMethod = util.functools.Partial2(self.AddMethod, self, "Barotrauma.ItemPrefab")

    do
        local Contains = util.itertools.Contains

        ---@param instance Barotrauma.ItemPrefab
        ---@param tag Barotrauma.Identifier|string
        ---@return boolean
        local function hasTag(instance, tag)
            return Contains(instance.Tags, tag)
        end

        AddMethod("hasTag", hasTag)
        ---@class Barotrauma.ItemPrefab
        ---@field public SBAI_hasTag fun(instance:Barotrauma.ItemPrefab, tag:Barotrauma.Identifier|string):boolean
    end

    do
        ---@param instance Barotrauma.ItemPrefab
        ---@param tag Barotrauma.Identifier|string
        ---@return boolean
        local function hasIdentifierOrTag(instance, tag)
            return instance.Identifier == tag or instance:SBAI_hasTag(tag)
        end

        AddMethod("hasIdentifierOrTag", hasIdentifierOrTag)
        ---@class Barotrauma.ItemPrefab
        ---@field public SBAI_hasIdentifierOrTag fun(instance:Barotrauma.ItemPrefab, idOrTag:Barotrauma.Identifier|string):boolean
    end

    do
        local new = Types.Set.new
        local xGetItemTags = util.xGetItemTags
        local xPath2 = util.xPath2

        ---@param instance Barotrauma.ItemPrefab
        ---@return boolean
        local function getSpecifiedContainables(instance)
            local tags = new()

            for contElement in xPath2(instance.ConfigElement.Element, "//ItemContainer//Containable") do
                tags:Update(xGetItemTags(contElement))
            end
            return tags
        end

        AddMethod("getSpecifiedContainables", getSpecifiedContainables)
        ---@class Barotrauma.ItemPrefab
        ---@field public SBAI_getSpecifiedContainables fun(instance:Barotrauma.ItemPrefab):Types.Set<Barotrauma.Identifier>
    end

    do
        local mapEntityCategories = self:RegisterEnumTable("Barotrauma.MapEntityCategory")

        ---@alias MapEntityCategory
        ---|`"None"`
        ---|`"Structure "`
        ---|`"Decorative"`
        ---|`"Machine"`
        ---|`"Medical"`
        ---|`"Weapon"`
        ---|`"Diving"`
        ---|`"Equipment"`
        ---|`"Fuel"`
        ---|`"Electrical"`
        ---|`"Material"`
        ---|`"Alien"`
        ---|`"Wrecked"`
        ---|`"ItemAssembly"`
        ---|`"Legacy"`
        ---|`"Misc"`
        
        local HasFlag = util.mathtools.HasFlag

        ---@param instance Barotrauma.ItemPrefab
        ---@param categoryStr MapEntityCategory
        ---@return boolean
        local function hasCategory(instance, categoryStr)
            local targetCategory = mapEntityCategories[categoryStr]

            return HasFlag(instance.Category, targetCategory)
        end

        AddMethod("hasCategory", hasCategory)
        ---@class Barotrauma.ItemPrefab
        ---@field public SBAI_hasCategory fun(instance:Barotrauma.ItemPrefab, categoryStr:MapEntityCategory):boolean
    end

end

return Types.CommonModule.new(activate)