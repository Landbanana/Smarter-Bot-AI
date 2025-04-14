local util = {Hook=Hook, LuaUserData=LuaUserData}
local Constants = require("SBAI.Shared.constants")

local LuaUserData = LuaUserData

do
    local Descriptors = Descriptors
    
    LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.ItemPrefab"], "tags")

    LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.AIObjective"], "subObjectives")
    LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.ItemContainer"], "slotRestrictions")
    LuaUserData.RegisterType("Barotrauma.Items.Components.ItemContainer+SlotRestrictions")
end

do
    local dataKey = {}

    util.RoundEndTemp = {
        [dataKey]={},
        ---@param self table
        ---@param name string
        ---@param base? boolean
        ---@return table
        Add=function(self, name, base)
            self[dataKey][name] = {}

            return self[dataKey][name]
        end,
        ---@param self table
        ---@param name string
        Remove=function(self, name)
            self[dataKey][name] = nil
        end,
        ---@param self table
        ClearAll=function(self)
            for k, t in pairs(self[dataKey]) do
                util.ClearTable(t)
            end
        end
    }

    Hook.Add("roundEnd", Constants.Acronym..".RoundEndReset",
    function()
        util.RoundEndTemp:ClearAll()
    end)
end

---@type table<string,Barotrauma.Item[]>
util.ItemGroup = setmetatable(util.RoundEndTemp:Add("ItemGroup"), {
    __index = function(t, k)
        local name = Constants.Acronym..".ItemGroup."..k
        local isRegistered, table = pcall(Util.GetItemGroup, name)

        if isRegistered then
            t[k] = table
        else
            Util.RegisterItemGroup(name, function(item)
                return item.HasTag(k)
            end)
            t[k] = Util.GetItemGroup(name)
        end
        return t[k]

        -- if rawget(t, k) == nil then
        --     local isRegistered, table = pcall(Util.GetItemGroup, name)

        --     if not isRegistered then
        --         Util.RegisterItemGroup(name, function(item)
        --             return item.HasTag(k)
        --         end)
        --         t[k] = Util.GetItemGroup(name)
        --     elseif rawget(t, k) == nil then
        --         t[k] = table
        --     end
        -- end
        -- return rawget(t, k)
    end
})

do
    local random = math.random

    ---@param value number
    ---@param deviation number
    ---@return number
    function util.AddNoise(value, deviation)
        return value*(1 + deviation*(2*random() - 1))
    end
end

---@return true
---@nodiscard
function util.True()
    return true
end

---@generic T
---@param list T[]
---@param value T
---@return boolean
function util.ValsContain(list, value)
    for v in list do
        if v == value then
            return true
        end
    end
    return false
end

---@generic T
---@param dict table<T,any>
---@param key T
---@return boolean
function util.KeysContain(dict, key)
    for k, _ in pairs(dict) do
        if k == key then
            return true
        end
    end
    return false
end

---@generic T
---@param t T
---@return T
function util.CopyTable(t)
    local tNew = {}

    for k, v in pairs(t) do
        tNew[k] = v
    end
    return tNew
end

---@param t table
function util.ClearTable(t)
    for k, _ in pairs(t) do
        t[k] = nil
    end
end

---@param t table<Barotrauma.Character,any>
---@param identifier string
---@param hookAddFunc fun(name:string, identifier:string, func?:fun(...))
function util.ClearTableKeyOnCharacterDeath(t, identifier, hookAddFunc)
    (hookAddFunc or Hook.Add)("character.death", identifier,
    function(character)
        t[character] = nil
    end)
end

---@param t table<integer,any>[]
---@return fun()
---@nodiscard
function util.Variator(t)
    local i = 0
    local n = #t

    if i >= n then return function() end end

    local ni = #t[1]

    return function()
        i = i + 1

        if i <= n then
        if #t[i] ~= ni then error("table sizes must be the same", 2) end
            return table.unpack(t[i])
        end
    end
end


---@param itemContainer Barotrauma.Items.Components.ItemContainer
---@param itemTag Barotrauma.Identifier
---@return integer?
function util.GetSpecificSlot(itemContainer, itemTag)
    if itemContainer then
        local i = 0

        for s in itemContainer.slotRestrictions do
            for c in s.ContainableItems do
                for t in c.Identifiers do
                    if t == itemTag then return i end
                end
            end
            i = i + 1
        end
    end
end

---@param container Barotrauma.Item
---@param itemTag Barotrauma.Item
---@return boolean
---@overload fun(container:Barotrauma.Item, itemTag:Barotrauma.Identifier):boolean
function util.IsSpecifiedContainer(container, itemTag)
    local itemContainer = container.GetComponent(Components.ItemContainer)

    if type(itemTag) == "string" then
        return util.GetSpecificSlot(itemContainer, itemTag) ~= nil
    end
    local isContainerPreferreditemTag, isPreferencesDefined, isSecondary = itemTag.IsContainerPreferred(itemContainer, false, false)

    return isContainerPreferreditemTag and isPreferencesDefined and not isSecondary
end

---@param character Barotrauma.Character
---@param item Barotrauma.Item
---@return boolean
---@nodiscard
function util.HasSimpleAccess(character, item)
    if  item == nil or
        item.Removed or
        item.currentHull == nil or
        item.IsClaimedByBallastFlora
    then
        return false
    end

    local isOnPlayerTeam = character.IsOnPlayerTeam

    if  item.Illegitimate == isOnPlayerTeam or
        (item.SpawnedInCurrentOutpost and not item.AllowStealing) == isOnPlayerTeam
    then
        return false
    end

    local submarine = item.Submarine
    local owner = item.GetRootInventoryOwner()

    if  LuaUserData.IsTargetType(owner, "Barotrauma.Character") and owner ~= character or
        not item.HasAccess(character) or
        submarine == nil or
        submarine.TeamID ~= character.TeamID or
        not character.Submarine.IsConnectedTo(submarine)
    then
        return false
    end
    return true
end

---@param item Barotrauma.Item
---@param targetConditionPercentageRange? number|number[]
---@return boolean
---@nodiscard
local function ItemMatchesConditionPercentageRange(item, targetConditionPercentageRange)
    if targetConditionPercentageRange == nil then
        return true
    elseif type(targetConditionPercentageRange) == "table" then
        return targetConditionPercentageRange[1] <= item.ConditionPercentage and item.ConditionPercentage <= targetConditionPercentageRange[2]
    else
        return item.ConditionPercentage == targetConditionPercentageRange
    end
end

---@param item Barotrauma.Item
---@return boolean
function util.PoweredItemHasNeededPower(item)
    local poweredComponent = item.GetComponent(Components.Powered)

    if  not poweredComponent or
        not (poweredComponent.PowerConsumption > 0 and
        poweredComponent.HasPower == false)
    then
        return false
    end
end

---@param character? Barotrauma.Character
---@param item Barotrauma.Item
---@param targetTag? Barotrauma.Identifier
---@param targetConditionPercentageRange? number|number[]
---@param predicate? fun(character?:Barotrauma.Character, item?:Barotrauma.Item):boolean
---@return boolean
---@nodiscard
function util.MatchItem(character, item, targetTag, targetConditionPercentageRange, predicate)
    return  item ~= nil and
            (not targetTag or item.HasTag(targetTag)) and
            (not targetConditionPercentageRange or ItemMatchesConditionPercentageRange(item, targetConditionPercentageRange)) and
            (not character or util.HasSimpleAccess(character, item)) and
            (not predicate or predicate(character, item))
end

---@param character? Barotrauma.Character
---@param itemList Barotrauma.Item[]
---@param targetTag? Barotrauma.Identifier
---@param targetConditionPercentageRange? number|number[]
---@param predicate? fun(character?:Barotrauma.Character, item?:Barotrauma.Item):boolean
---@return Barotrauma.Item?
function util.FindItem(character, itemList, targetTag, targetConditionPercentageRange, predicate)
    -- if not itemList then error("itemList must be provided", 2) end
    for item in itemList do --[[@cast item Barotrauma.Item]]
        if util.MatchItem(character, item, targetTag, targetConditionPercentageRange, predicate) then
            return item
        end
    end
end

---@param character Barotrauma.Character
---@param itemList Barotrauma.Item[]
---@param targetTag? Barotrauma.Identifier
---@param targetConditionPercentageRange? number|number[]
---@param predicate? fun(character?:Barotrauma.Character, item?:Barotrauma.Item):boolean
---@return Barotrauma.Item[] items
function util.FindItems(character, itemList, targetTag, targetConditionPercentageRange, predicate)
    local i = 0 --[[@type integer]]
    local items = {} --[=[@type Barotrauma.Item[]]=]

    for item in itemList do --[[@cast item Barotrauma.Item]]
        if util.MatchItem(character, item, targetTag, targetConditionPercentageRange, predicate) then
            i = i + 1
            items[i] = item
        end
    end

    return items
end

---@param item Barotrauma.Item
---@return boolean
function util.ParentItemsHaveDontTakeItemsTag(item)
    local container = item.Container
    
    while container do
        if container.HasTag("donttakeitems") then return true end
        container = container.Container
    end
    return false
end

---@param character? Barotrauma.Character
---@param containerList Barotrauma.Item[]
---@param targetContainableItemTag Barotrauma.Identifier
---@param targetContainerTag? Barotrauma.Identifier
---@param targetConditionPercentageRange? number|number[]
---@param hasEmptySlots? boolean
---@param isSpecifiedAlready? boolean
---@param predicate? fun(character?:Barotrauma.Character, item?:Barotrauma.Item):boolean
---@return Barotrauma.Item[]
function util.FindSpecificContainers(character, containerList, targetContainableItemTag, targetContainerTag, targetConditionPercentageRange, hasEmptySlots, isSpecifiedAlready, predicate)
    local i = 0 --[[@type integer]]
    local containers = {} --[=[@type Barotrauma.Item[]]=]

    local function containerPredicate(_, container)
        return  util.IsSpecifiedContainer(container, targetContainableItemTag) and
                (not predicate or predicate(character, container))
    end
    -- if not containerList then error("containerList must be provided", 2) end
    for _, container in ipairs(containerList) do --[[@cast container Barotrauma.Item]]
        if util.MatchItem(character, container, targetContainerTag, nil, not isSpecifiedAlready and containerPredicate or predicate) then
            local inventory = container.OwnInventory

            if  (not hasEmptySlots or inventory.EmptySlotCount > 0) and
                (not targetContainableItemTag or util.FindItem(nil, inventory.FindAllItems(nil, true), targetContainableItemTag, targetConditionPercentageRange))
                    then
                i = i + 1
                containers[i] = container
            end
        end
    end
    return containers
end

---@param startPosition Microsoft.Xna.Framework.Vector
---@param ... Barotrauma.Item[]
---@return Barotrauma.Item item
function util.GetClosest(startPosition, ...)
    local arg = {...}
    local closestItem = nil
    local bestDistanceFactor = 0.0

    for _, items in ipairs(arg) do
        for _, item in ipairs(items) do
            local distanceFactor = AIObjective.GetDistanceFactor(startPosition, item.WorldPosition, 0.2)

            if distanceFactor > bestDistanceFactor then
                closestItem = item
                bestDistanceFactor = distanceFactor
            end
        end
    end
    return closestItem
end

---@type fun(instance:Barotrauma.AIObjective, objective:AIObjective, constructor:fun():(Barotrauma.AIObjective), onCompletedGenerator:fun(Barotrauma.AIObjective), onAbandonGenerator:fun(Barotrauma.AIObjective)):boolean
---@generic T:Barotrauma.AIObjective
---@param instance Barotrauma.AIObjective
---@param objective nil
---@param constructor fun():T
---@param onCompletedGenerator fun(Barotrauma.AIObjective: any)
---@param onAbandonGenerator fun(Barotrauma.AIObjective: any)
---@return boolean
---@return T?
function util.TryAddSubObjective(instance, objective, constructor, onCompletedGenerator, onAbandonGenerator)
    if objective ~= nil then
        if not util.ValsContain(instance.subObjectives, objective) then objective = nil end
        return false
    else
        objective = constructor()

        if util.ValsContain(instance.subObjectives, objective) then return false end
        if instance.AllowMultipleInstances then
            objective.SourceObjective = instance
            instance.subObjectives.Add(objective)
        else
            instance.AddSubObjective(objective)
        end
        if onCompletedGenerator ~= nil then
            objective.Completed.add(onCompletedGenerator(objective))
        end
        if onAbandonGenerator ~= nil then
            objective.Abandoned.add(onAbandonGenerator(objective))
        end
        return true
    end
end

do
    local clock = os.clock

    function util.Benchmark(func, ...)
        local t1 = clock()
        func(...)
        local t2 = clock()
        return os.difftime(t2, t1)
    end
end

---@type table<string, {Descriptor:MoonSharp.Interpreter.Interop.IUserDataDescriptor, Static:System.Object}>
util.UnregisteredStaticDescriptors = setmetatable({}, {
    __index=function(t, typeName)
        t[typeName] = {
            Descriptor=LuaUserData.RegisterType(typeName),
            Static=LuaUserData.CreateStatic(typeName)
        }
        LuaUserData.UnregisterType(typeName)
        return t[typeName]
    end
})

---@param ... string
function util.RegisterAll(...)
    local args = table.pack(...)

    args.n = nil

    for typeName in args do
        local success, _ = pcall(LuaUserData.RegisterType, typeName)

        if not success then
            Logger.LogError("Can't register typeName: "..typeName)
        end
    end
end

---@param ... string
function util.UnregisterAll(...)
    local args = table.pack(...)

    args.n = nil

    for typeName in args do
        local success, _ = pcall(LuaUserData.UnregisterType, typeName)

        if not success then
            Logger.LogError("Can't unregister typeName: "..typeName)
        end
    end
end

---@generic T:any...
---@generic R:any...
---@param typeNames string[]
---@param func fun(args:T):R
---@param ... T
---@return R
function util.DoWithTemporaryRegistrations(typeNames, func, ...)
    util.RegisterAll(table.unpack(typeNames))

    local out = table.pack(pcall(func, ...))

    out.n = nil

    util.UnregisterAll(table.unpack(typeNames))

    local success = out[1]
    local results = select(2, table.unpack(out))

    if not success then
        error(results, 2)
    end
    
    return results
end

---@param ... string
function util.LogErrors(...)
    local args = table.pack(...)

    args.n = nil

    for s in args do
        Logger.LogError(s)
    end
end

do
    LuaUserData.RegisterType("System.Collections.Immutable.ImmutableHashSet`1+Builder")
    LuaUserData.RegisterType("System.Collections.Immutable.ImmutableHashSet`1")
    LuaUserData.RegisterType("System.Collections.Immutable.ImmutableHashSet")
    
    local ImmutableHashSet = LuaUserData.CreateStatic("System.Collections.Immutable.ImmutableHashSet")
    ImmutableHashSet.CreateBuilder(Identifier).ToImmutable().ToBuilder().Add(Identifier("chair"))           -- needed or Moonsharp forgets
    
    LuaUserData.UnregisterType("System.Collections.Immutable.ImmutableHashSet")
    LuaUserData.UnregisterType("System.Collections.Immutable.ImmutableHashSet`1")
    LuaUserData.UnregisterType("System.Collections.Immutable.ImmutableHashSet`1+Builder")

    ---@param prefab Barotrauma.ItemPrefab
    ---@param ... Barotrauma.Identifier-arr
    function util.AddTagsToPrefab(prefab, ...)
        local builder = ImmutableHashSet.CreateBuilder(Identifier)
        local newTags = table.pack(...)

        for i=1,newTags.n do
            builder.Add(newTags[i])
        end

        for tag in prefab.tags do
            builder.Add(tag)
        end
        prefab.tags = builder.ToImmutable()
    end

    ---@param prefab Barotrauma.ItemPrefab
    ---@param ... Barotrauma.Identifier-arr
    function util.RemoveTagsFromPrefab(prefab, ...)
        local builder = ImmutableHashSet.CreateBuilder(Identifier)
        local badTags = table.pack(...)

        local temp = {}

        for i=1,badTags.n do
            temp[i] = badTags[i]
        end

        for tag in prefab.tags do
            for badTag in temp do
                if tag == badTag then goto continue end
            end
            builder.Add(tag)
            ::continue::
        end
        prefab.tags = builder.ToImmutable()
    end
end

return util