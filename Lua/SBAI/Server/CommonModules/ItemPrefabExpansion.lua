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
        ---@field public SBAI_getSpecifiedContainables fun(instance:Barotrauma.ItemPrefab):Set<Barotrauma.Identifier>
    end

    do
        local mapEntityCategories = self:RegisterEnumTable("Barotrauma.MapEntityCategory")

        ---@alias MapEntityCategory
        ---|`"None"`
        ---|`"Structure"`
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
            return HasFlag(instance.Category, mapEntityCategories[categoryStr])
        end

        AddMethod("hasCategory", hasCategory)
        ---@class Barotrauma.ItemPrefab
        ---@field public SBAI_hasCategory fun(instance:Barotrauma.ItemPrefab, categoryStr:MapEntityCategory):boolean
    end

    do
        local InvSlotType = InvSlotType
        local new = Types.Set.new
        local xPath2 = util.xPath2

        ---@param instance Barotrauma.ItemPrefab
        ---@return Set<Barotrauma.InvSlotType>
        ---@return table<integer, Set<Barotrauma.InvSlotType>>
        local function getInvSlots(instance)
            local reg = new()
            local comp = {}

            for elementName in {"//Holdable", "//Wearable", "//Pickable", "//MeleeWeapon", "//Throwable"} do
                for holdable in xPath2(instance.ConfigElement.Element, elementName) do
                    for slotGroup in holdable.Attribute("slots").Value:gmatch("([^,]+),?") do
                        local set = new()
                        local slot = 0

                        for addedSlot in slotGroup:gmatch("([^%+]+)%+?") do
                            local newSlot = InvSlotType[addedSlot]

                            slot = slot + newSlot
                            set:Add(newSlot)
                        end
                        if set[slot] then
                            reg:Add(slot)
                        else
                            comp[slot] = set
                        end
                    end
                end
            end
            return reg, comp
        end
        AddMethod("getInvSlots", getInvSlots)
        ---@class Barotrauma.ItemPrefab
        ---@field public SBAI_getInvSlots fun(instance:Barotrauma.ItemPrefab):(Set<Barotrauma.InvSlotType>, table<integer, Set<Barotrauma.InvSlotType>>)
    end
end

return Types.CommonModule.new(activate)