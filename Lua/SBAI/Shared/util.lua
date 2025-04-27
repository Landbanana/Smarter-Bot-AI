local Constants = require("SBAI.Shared.constants")

local util = {}
util.config = {}
util.debug = {}
util.functools = {}
util.itertools = {}

local LuaUserData = LuaUserData

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.ItemPrefab"], "tags")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.AIObjective"], "subObjectives")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.ItemContainer"], "slotRestrictions")
LuaUserData.RegisterType("Barotrauma.Items.Components.ItemContainer+SlotRestrictions")

---@param t table
function util.itertools.ClearTable(t)
    for k in next, t do
        t[k] = nil
    end
end

---@generic T:table
---@param t1 T
---@param t2? table
---@return T
function util.itertools.CopyTable(t1, t2)
    t2 = t2 or {}

    for k, v in next, t1 do
        t2[k] = v
    end
    return t2
end

---@generic T
---@param t table<T,any>
---@param ... T
function util.itertools.RemoveKeys(t, ...)
    for k in {...} do
        t[k] = nil
    end
end

---@generic T
---@param t table<T,any>
---@param value T
function util.itertools.RemoveValue(t, value)
    for k, v in next, t do
        if v == value then
            t[k] = nil
            return
        end
    end
end

---@generic T
---@param t table<T,any>
---@param ... T
function util.itertools.RemoveValues(t, ...)
    local values = {...}

    for k, v in next, t do
        for value in values do
            if v == value then
                t[k] = nil
                break
            end
        end
    end
end

---@generic K,V
---@param t table<K,V>
---@param predicate fun(k:K, v:V):boolean
function util.itertools.RemoveSpecifiedItem(t, predicate)
    for k, v in next, t do
        if predicate(k, v) then
            t[k] = nil
            break
        end
    end
end

---@generic K,V
---@param t table<K,V>
---@param predicate fun(k:K, v:V):boolean
function util.itertools.RemoveSpecifiedItems(t, predicate)
    for k, v in next, t do
        if predicate(k, v) then
            t[k] = nil
        end
    end
end

---@generic V
---@param predicate fun(v:V):boolean
---@param t? V[]
---@param ... V
---@return boolean
function util.itertools.Any(predicate, t, ...)
    for obj in (t ~= nil and t or {...}) do
        if predicate(obj) then return true end
    end
    return false
end

---@generic V
---@param predicate fun(v:V):boolean
---@param t? V[]
---@param ... V
---@return boolean
function util.itertools.All(predicate, t, ...)
    for obj in (t or {...}) do
        if not predicate(obj) then return false end
    end
    return true
end

---@generic V
---@param t V[]
---@param v V
---@return boolean
function util.itertools.Contains(t, v)
    for val in t do
        if val == v then
            return true
        end
    end
    return false
end

---@param ... any[]
---@return fun():any
function util.itertools.Chain(...)
    local tableList = {...}
    local tableIdx = 0
    local tableListMax = #tableList
    local tableCur
    local n = 0
    local i = 0

    return function()
        i = i + 1
        while i > n do
            tableIdx = tableIdx + 1
            if tableIdx > tableListMax then return end
            tableCur = tableList[tableIdx]
            n = #tableCur
            i = 1
        end
        return tableCur[i]
    end
end

do
    local Contains = util.itertools.Contains
    local RemoveSpecifiedItems = util.itertools.RemoveSpecifiedItems

    ---@generic T
    ---@param t table<T,any>
    ---@param ... T
    function util.itertools.RemoveVals(t, ...)
        local compVals =  {...}

        return RemoveSpecifiedItems(t, function(_, v)
            return Contains(compVals, v)
        end)
    end
end

do
    local unpack = table.unpack

    ---@param t table<integer,any>[]
    ---@return fun()
    ---@nodiscard
    function util.itertools.Variator(t)
        local i = 0
        local n = #t

        if i >= n then return function() end end

        local ni = #t[1]

        return function()
            i = i + 1

            if i <= n then
            if #t[i] ~= ni then error("table sizes must be the same", 2) end
                return unpack(t[i])
            end
        end
    end
end

---@enum (key) util.CLEAR_REG
util.CLEAR_REG = {
    ROUND_END=2,
    CHARACTER_DEATH=4,
    ITEM_REMOVED=8
}

do
    local roundEnd = {} --[=[@type table<any,any>[]]=]
    local characterDeath = {} --[=[@type table<Barotrauma.Character,any>[]]=]
    local itemRemoved = {} --[=[@type table<Barotrauma.Item,any>[]]=]

    local initKey = {}

    do
        local CLEAR_REG = util.CLEAR_REG

        local btest = bit32.btest
        local CopyTable = util.itertools.CopyTable
        local insert = table.insert

        ---@param t table
        ---@param init? table
        ---@param flags number
        function util.RegisterTable(t, init, flags)
            if type(t) ~= "table" then error("t is a "..type(t)..", expecting a table", 2) end

            for flag, subRegistry in pairs({
                ROUND_END=roundEnd,
                CHARACTER_DEATH=characterDeath,
                ITEM_REMOVED=itemRemoved
            }) do
                if btest(CLEAR_REG[flag], flags) then
                    insert(subRegistry, t)
                end
            end
            if init then
                CopyTable(init, t)
                t[initKey] = init
            end
        end
    end

    do
        local CLEAR_REG = util.CLEAR_REG

        local btest = bit32.btest
        local RemoveValue = util.itertools.RemoveValue

        ---@param t table
        ---@param flags number
        function util.UnregisterTable(t, flags)
            if type(t) ~= "table" then error("t is a "..type(t)..", expecting a table", 2) end

            for flag, subRegistry in pairs({
                ROUND_END=roundEnd,
                CHARACTER_DEATH=characterDeath,
                ITEM_REMOVED=itemRemoved
            }) do
                if btest(CLEAR_REG[flag], flags) then
                    RemoveValue(subRegistry, t)
                end
            end
            t[initKey] = nil
        end
    end

    do
        local ClearTable = util.itertools.ClearTable
        local CopyTable = util.itertools.CopyTable

        Hook.Add("roundEnd", Constants.Acronym..".RoundEndClear",
        function()
            for t in roundEnd do --[[@cast t table]]
                local init = rawget(t, initKey)
            
                ClearTable(t)
                if init then
                    CopyTable(init, t)
                    t[initKey] = init
                end
            end
        end)
    end

    Hook.Add("character.death", Constants.Acronym..".CharacterDeathClear",
    ---@param character Barotrauma.Character
    function(character)
        for t in characterDeath do --[[@cast t table]]
            t[character] = nil
        end
    end)

    Hook.Add("item.removed", Constants.Acronym..".ItemRemovedClear",
    ---@param item Barotrauma.Item
    function(item)
        for t in itemRemoved do --[[@cast t table]]
            t[item] = nil
        end
    end)
end

do
    local Acronym = Constants.Acronym

    local GetItemGroup = Util.GetItemGroup
    local RegisterItemGroup = Util.RegisterItemGroup

    ---@type table<string,Barotrauma.Item[]>
    util.ItemGroup = setmetatable({}, {
        __index = function(t, k)
            local name = Acronym..".ItemGroup."..k
            local isRegistered, table = pcall(GetItemGroup, name)

            if isRegistered then
                t[k] = table
            else
                RegisterItemGroup(name, function(item)
                    return item.HasTag(k)
                end)
                t[k] = GetItemGroup(name)
            end
            return t[k]
        end
    })
end

util.RegisterTable(util.ItemGroup, nil, util.CLEAR_REG.ROUND_END)

do
    local clamp = math.clamp

    local function InverseLerp(min, max, v)
        local diff = max - min;
        
        if (diff == 0) then return v >= max and 1 or 0 end
        return clamp((v - min) / diff, 0, 1);
    end
end

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

---@param instance Barotrauma.AIObjectiveGoTo
---@return boolean
function util.IsWaitObjective(instance)
    return instance.IsWaitOrder
end

---@generic T1,T2,T3,T4,T5,T6,T7,T8,T9,R
---@param func fun(a1:T1,a2:T2,a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):R
---@param a1 T1
---@return fun(a2:T2,a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):R
function util.functools.Partial1(func, a1)
    return function(...)
        return func(a1, ...)
    end
end

---@generic T1,T2,T3,T4,T5,T6,T7,T8,T9,R
---@param func fun(a1:T1,a2:T2,a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):R
---@param a1 T1
---@param a2 T2
---@return fun(a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):R
function util.functools.Partial2(func, a1, a2)
    return function(...)
        return func(a1, a2, ...)
    end
end

---@generic T1,T2,T3,T4,T5,T6,T7,T8,T9,R
---@param func fun(a1:T1,a2:T2,a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):R
---@param a1 T1
---@param a2 T2
---@param a3 T3
---@return fun(a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):R
function util.functools.Partial3(func, a1, a2, a3)
    return function(...)
        return func(a1, a2, a3, ...)
    end
end

---@generic T1,T2,T3,T4,T5,T6,T7,T8,T9,R
---@param func fun(a1:T1,a2:T2,a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):R
---@param a1 T1
---@param a2 T2
---@param a3 T3
---@param a4 T4
---@return fun(a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):R
function util.functools.Partial4(func, a1, a2, a3, a4)
    return function(...)
        return func(a1, a2, a3, a4, ...)
    end
end

do
    local HULL_SAFETY_THRESHOLD = LuaUserData.CreateStatic("Barotrauma.HumanAIController").HULL_SAFETY_THRESHOLD

    ---@param character Barotrauma.Character
    function util.HumanInSafeHull(character)
        return character.IsHuman and
            character.AIController.CurrentHullSafety >= HULL_SAFETY_THRESHOLD
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

do
    local ItemContainer = Components.ItemContainer

    local GetSpecificSlot = util.GetSpecificSlot

    ---@param container Barotrauma.Item
    ---@param itemTag Barotrauma.Item
    ---@return boolean
    ---@overload fun(container:Barotrauma.Item, itemTag:Barotrauma.Identifier):boolean
    function util.IsSpecifiedContainer(container, itemTag)
        local itemContainer = container.GetComponent(ItemContainer)

        if type(itemTag) == "string" then
            return GetSpecificSlot(itemContainer, itemTag) ~= nil
        end
        local isContainerPreferreditemTag, isPreferencesDefined, isSecondary = itemTag.IsContainerPreferred(itemContainer, false, false)

        return isContainerPreferreditemTag and isPreferencesDefined and not isSecondary
    end
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


do
    local Powered = Components.Powered

    ---@param item Barotrauma.Item
    ---@return boolean
    function util.PoweredItemHasNeededPower(item)
        local poweredComponent = item.GetComponent(Powered) --[[@type Barotrauma.Items.Components.Powered]]

        return not poweredComponent or
            poweredComponent.PowerConsumption <= 0 or
            poweredComponent.HasPower == true
    end
end

do
    local HasSimpleAccess = util.HasSimpleAccess

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
                (not character or HasSimpleAccess(character, item)) and
                (not predicate or predicate(character, item))
    end
end

do
    local MatchItem = util.MatchItem

    ---@param character? Barotrauma.Character
    ---@param itemList Barotrauma.Item[]
    ---@param targetTag? Barotrauma.Identifier
    ---@param targetConditionPercentageRange? number|number[]
    ---@param predicate? fun(character?:Barotrauma.Character, item?:Barotrauma.Item):boolean
    ---@return Barotrauma.Item?
    function util.FindItem(character, itemList, targetTag, targetConditionPercentageRange, predicate)
        -- if not itemList then error("itemList must be provided", 2) end
        for item in itemList do --[[@cast item Barotrauma.Item]]
            if MatchItem(character, item, targetTag, targetConditionPercentageRange, predicate) then
                return item
            end
        end
    end
end
    

do
    local MatchItem = util.MatchItem

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
            if MatchItem(character, item, targetTag, targetConditionPercentageRange, predicate) then
                i = i + 1
                items[i] = item
            end
        end

        return items
    end
end

do
    local Contains = util.itertools.Contains
    
    ---@param ids Barotrauma.Identifier[]
    ---@return fun(character:Barotrauma.Character, item:Barotrauma.Item):boolean
    function util.GenerateIdPredicate(ids)
        ---@param character Barotrauma.Character
        ---@param item Barotrauma.Item
        return function(character, item)
            return Contains(ids, item.Prefab.Identifier)
        end
    end
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

do
    local FindItem = util.FindItem
    local IsSpecifiedContainer = util.IsSpecifiedContainer
    local MatchItem = util.MatchItem

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
            return  IsSpecifiedContainer(container, targetContainableItemTag) and
                    (not predicate or predicate(character, container))
        end
        -- if not containerList then error("containerList must be provided", 2) end
        for container in containerList do --[[@cast container Barotrauma.Item]]
            if MatchItem(character, container, targetContainerTag, nil, not isSpecifiedAlready and containerPredicate or predicate) then
                local inventory = container.OwnInventory

                if  (not hasEmptySlots or inventory.EmptySlotCount > 0) and
                    (not targetContainableItemTag or FindItem(nil, inventory.FindAllItems(nil, true), targetContainableItemTag, targetConditionPercentageRange))
                        then
                    i = i + 1
                    containers[i] = container
                end
            end
        end
        return containers
    end
end

do
    local AIObjective = AIObjective
    
    ---@param startPosition Microsoft.Xna.Framework.Vector2
    ---@param endPosition Microsoft.Xna.Framework.Vector2
    ---@param maxDistanceFactor number
    ---@param verticalDistanceFactor? number
    ---@param maxDistance? number
    ---@param minDistanceFactor? number
    function util.GetDistanceFactor(startPosition, endPosition, maxDistanceFactor, verticalDistanceFactor, maxDistance, minDistanceFactor)
        return AIObjective.GetDistanceFactor(startPosition, endPosition, maxDistanceFactor, verticalDistanceFactor, maxDistance, minDistanceFactor)
    end
end

do
    local GetDistanceFactor = util.GetDistanceFactor

    ---@param startPosition Microsoft.Xna.Framework.Vector2
    ---@param ... Barotrauma.ISpatialEntity[]
    ---@return Barotrauma.ISpatialEntity
    function util.GetClosest(startPosition, ...)
        local closest = nil
        local bestDistanceFactor = 0.0

        ---@param item Barotrauma.ISpatialEntity
        local function testClosest(item)
            local distanceFactor = GetDistanceFactor(startPosition, item.WorldPosition, 0.2)

            if distanceFactor > bestDistanceFactor then
                closest = item
                bestDistanceFactor = distanceFactor
            end
        end

        for items in {...} do
            if type(items) == "table" then --[=[@cast items Barotrauma.ISpatialEntity[]]=]
                for item in items do --[[@cast item Barotrauma.ISpatialEntity]]
                    testClosest(item)
                end
            else --[[@cast items Barotrauma.ISpatialEntity]]
                testClosest(items)
            end
        end
        return closest
    end
end

do
    local Contains = util.itertools.Contains

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
            if not Contains(instance.subObjectives, objective) then objective = nil end
            return false
        else
            objective = constructor()

            if util.itertools.Contains(instance.subObjectives, objective) then return false end
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
end

do
    local clock = os.clock
    local difftime = os.difftime

    ---@generic T:any
    ---@param n number
    ---@param func fun(...:T):any
    ---@param ... T
    ---@return number
    function util.debug.Benchmark(n, func, ...)
        local timeTotal = 0

        n = (n >= 1) and n or 100
        for _=1,n,1 do
            local t1 = clock()
            func(...)
            local t2 = clock()

            timeTotal = timeTotal + difftime(t2, t1)
        end
        return timeTotal/n
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
    for typeName in {...} do
        local success, _ = pcall(LuaUserData.RegisterType, typeName)

        if not success then
            Logger.LogError("Can't register typeName: "..typeName)
        end
    end
end

---@param ... string
function util.UnregisterAll(...)
    for typeName in {...} do
        local success, _ = pcall(LuaUserData.UnregisterType, typeName)

        if not success then
            Logger.LogError("Can't unregister typeName: "..typeName)
        end
    end
end

do
    local unpack = table.unpack
    local RegisterAll = util.RegisterAll
    local UnregisterAll = util.UnregisterAll
    

    ---@generic T:any...
    ---@generic R:any...
    ---@param typeNames string[]
    ---@param func fun(args:T):R
    ---@param ... T
    ---@return R
    function util.DoWithTemporaryRegistrations(typeNames, func, ...)
        RegisterAll(unpack(typeNames))

        local out = {pcall(func, ...)}

        UnregisterAll(unpack(typeNames))

        local success = out[1]
        local results = select(2, unpack(out))

        if not success then
            error(results, 2)
        end
        
        return results
    end
end

---@param config table
---@param optionString string
---@param skip integer
---@return OptionType
---@overload fun(config, optionList:Namespace)
function util.config.Get(config, optionString, skip)
    skip = skip or 0

    if type(optionString) == "string" then
        for _=0,skip,1 do
            optionString = optionString:match("[^%.]+%.(.+)")
        end
        for sub in optionString:gmatch("([^%.]+)") do
            config = config[sub]
        end
    else
        local i = 0

        for sub in optionString.stack do
            if i >= skip then
                config = config[sub]
            else
                i = i + 1
            end
        end
    end
    return config
end

do
    local Get = util.config.Get
    local match = string.match

    ---@param config table
    ---@param optionString string
    ---@param skip integer
    ---@param value any
    ---@overload fun(optionList:Namespace, value:OptionType)
    function util.config.Set(config, optionString, value, skip)
        if type(optionString) == "table" then
            Get(config, -optionString, skip)[optionString.stack[#optionString.stack]] = value
            return
        end

        local preOptionString, subOptionString = match(optionString, "(.+[^%.]+)%.([^%.]+)$")

        Get(config, preOptionString, skip)[subOptionString] = value
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

    local pack = table.pack

    ---@param prefab Barotrauma.ItemPrefab
    ---@param ... Barotrauma.Identifier-arr
    function util.AddTagsToPrefab(prefab, ...)
        local builder = ImmutableHashSet.CreateBuilder(Identifier)
        local newTags = pack(...)

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
        local badTags = pack(...)

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

do
    local upper = string.upper

    function util.CapFirstLetter(str)
        return str:gsub("^%l", upper)
    end
end

---@param className string
---@param mainFuncName string
---@param nestedFuncName string
---@param default string
---@return string?
function util.debug.CheckNestedMethodName(className, mainFuncName, nestedFuncName, default)
    return default
end

if CSActive then
    do
        local DoWithTemporaryRegistrations = util.DoWithTemporaryRegistrations
        local LuaUserData = LuaUserData

        ---@param className string
        ---@param mainFuncName string
        ---@param nestedFuncName string
        ---@return string?
        local function inner(className, mainFuncName, nestedFuncName)
            local type = LuaUserData.GetType(className)
            local pattern = "<"..mainFuncName..">g__"..nestedFuncName.."|"

            for k, v in next, type.GetMethods(4 + 8 + 16 + 32) do
                local name = v.Name --[[@type string]]
                
                if name:match(pattern) then
                    return name
                end
            end
        end

        ---@param className string
        ---@param mainFuncName string
        ---@param nestedFuncName string
        ---@return string
        function util.debug.GetNestedMethodName(className, mainFuncName, nestedFuncName)
            return DoWithTemporaryRegistrations({
                "System.Type",
                "System.Reflection.RuntimeMethodInfo"
            }, inner, className, mainFuncName, nestedFuncName)
        end
    end

    do
        local GetNestedFunc = util.debug.GetNestedMethodName

        ---@param className string
        ---@param mainFuncName string
        ---@param nestedFuncName string
        ---@param default string
        ---@return string
        function util.debug.CheckNestedMethodName(className, mainFuncName, nestedFuncName, default)
            return GetNestedFunc(className, mainFuncName, nestedFuncName) or default
        end
    end
end

return util