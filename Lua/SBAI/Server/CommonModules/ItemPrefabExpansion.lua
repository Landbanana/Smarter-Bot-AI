---@class (constructor) Barotrauma.ItemPrefab
---@field public SBAI_getInvSlots fun(instance:Barotrauma.ItemPrefab):(Set<Barotrauma.InvSlotType>, table<integer, Set<Barotrauma.InvSlotType>>)
---@field public SBAI_getSpecifiedContainables fun(instance:Barotrauma.ItemPrefab):Set<Barotrauma.Identifier>
---@field public SBAI_hasCategory fun(instance:Barotrauma.ItemPrefab, categoryStr:MapEntityCategory):boolean
---@field public SBAI_hasIdentifierOrTag fun(instance:Barotrauma.ItemPrefab, idOrTag:Barotrauma.Identifier|string):boolean
---@field public SBAI_hasTag fun(instance:Barotrauma.ItemPrefab, tag:Barotrauma.Identifier|string):boolean
---@field public SBAI_isHoldable fun(instance:Barotrauma.ItemPrefab):boolean

---@param self CommonModule
local function activate(self)
    local addMethod = Functools.partial2(self.addMethod, self, "Barotrauma.ItemPrefab")

    do
        local contains = Itertools.contains

        ---@param instance Barotrauma.ItemPrefab
        ---@param tag Barotrauma.Identifier|string
        ---@return boolean
        local function hasTag(instance, tag)
            return contains(instance.Tags, tag)
        end

        addMethod("hasTag", hasTag)
    end

    do
        ---@param instance Barotrauma.ItemPrefab
        ---@param tag Barotrauma.Identifier|string
        ---@return boolean
        local function hasIdentifierOrTag(instance, tag)
            return instance.Identifier == tag or instance:SBAI_hasTag(tag)
        end

        addMethod("hasIdentifierOrTag", hasIdentifierOrTag)
    end

    do
        local Set = Types.Set
        
        local xGetItemTags = util.xGetItemTags
        local xPath = util.xPath

        ---@param instance Barotrauma.ItemPrefab
        ---@return boolean
        local function getSpecifiedContainables(instance)
            local tags = Set()

            for contElement in xPath(instance.ConfigElement.Element, "//ItemContainer//Containable") do
                tags:update(xGetItemTags(contElement))
            end
            return tags
        end

        addMethod("getSpecifiedContainables", getSpecifiedContainables)
    end

    do
        local MapEntityCategory = util.registration.GetEnum("Barotrauma.MapEntityCategory")

        ---@alias MapEntityCategory
        ---|"None"
        ---|"Structure"
        ---|"Decorative"
        ---|"Machine"
        ---|"Medical"
        ---|"Weapon"
        ---|"Diving"
        ---|"Equipment"
        ---|"Fuel"
        ---|"Electrical"
        ---|"Material"
        ---|"Alien"
        ---|"Wrecked"
        ---|"ItemAssembly"
        ---|"Legacy"
        ---|"Misc"
        
        local HasFlag = Mathtools.hasFlag


        ---@param instance Barotrauma.ItemPrefab
        ---@param categoryStr MapEntityCategory
        ---@return boolean
        local function hasCategory(instance, categoryStr)
            return HasFlag(instance.Category, MapEntityCategory[categoryStr])
        end

        addMethod("hasCategory", hasCategory)
    end

    do
        local InvSlotType = InvSlotType
        local Set = Types.Set
        local xPath = util.xPath

        ---@param instance Barotrauma.ItemPrefab
        ---@return Set<Barotrauma.InvSlotType>
        ---@return table<integer, Set<Barotrauma.InvSlotType>>
        local function getInvSlots(instance)
            local reg = Set()
            local comp = {}

            for slotComp in xPath(instance.ConfigElement.Element, "//[@slots]") do
                for slotGroup in slotComp.GetAttributeString("slots", ""):gmatch("([^,]+),?") do
                    local set = Set()
                    local slot = 0

                    for addedSlot in slotGroup:gmatch("([^%+]+)%+?") do
                        local newSlot = InvSlotType[addedSlot]

                        slot = slot + newSlot
                        set:add(newSlot)
                    end
                    if set[slot] then
                        reg:add(slot)
                    else
                        comp[slot] = set
                    end
                end
            end
            return reg, comp
        end
        addMethod("getInvSlots", getInvSlots)
    end

    do
        local any = Itertools.any
        local xPath = util.xPath

        ---@param instance Barotrauma.ItemPrefab
        ---@return boolean
        local function isHoldable(instance)
            return any(xPath(instance.ConfigElement.Element, "//[@slots]"))
        end
        addMethod("isHoldable", isHoldable)
    end
end

return Types.CommonModule("ItemPrefabExpansion", activate)