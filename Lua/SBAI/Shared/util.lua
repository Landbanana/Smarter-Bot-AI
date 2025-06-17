local Constants = require("SBAI.Shared.constants")

local util = {}
util.config = {}
util.cotools = {}
util.debug = {}
util.functools = {}
util.itertools = {}
util.mathtools = {}

local LuaUserData = LuaUserData

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.ItemPrefab"], "tags")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.AIObjective"], "subObjectives")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.ItemContainer"], "slotRestrictions")
LuaUserData.RegisterType("Barotrauma.Items.Components.ItemContainer+SlotRestrictions")

do
    local band = bit32.band

    function util.mathtools.HasFlag(bitFlag, flag)
        return band(bitFlag, flag) == flag
    end
end

do
    local btest = bit32.btest

    function util.mathtools.HasAnyFlag(bitFlag, flag)
        return btest(bitFlag, flag)
    end
end

do
    local select = select

    ---@generic T
    ---@param ... T
    ---@return T[]
    ---@return integer
    function util.functools.GetArgs(...)
        return {...}, select("#", ...)
    end
end

do
    local select = select

    ---@generic T,R
    ---@param func fun(arg:T):R
    ---@param ... T
    ---@return R?
    local function TryAll(func, ...)
        local firstArg = (...)
        
        if firstArg then
            local out = func(firstArg)

            if out then
                return out
            else
                return TryAll(func, select(2, ...))
            end
        end
        return nil
    end

    util.functools.TryAll = TryAll
end

---@generic T1,T2,T3,T4,T5,T6,T7,T8,T9,R1,R2,R3,R4,R5,R6,R7,R8,R9
---@param f fun(a1:T1,a2:T2,a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):(R1,R2,R3,R4,R5,R6,R7,R8,R9)
---@param a1 T1
---@return fun(a2:T2,a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):(R1,R2,R3,R4,R5,R6,R7,R8,R9)
function util.functools.Partial1(f, a1)
    return function(...)
        return f(a1, ...)
    end
end

---@generic T1,T2,T3,T4,T5,T6,T7,T8,T9,R1,R2,R3,R4,R5,R6,R7,R8,R9
---@param f fun(a1:T1,a2:T2,a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):(R1,R2,R3,R4,R5,R6,R7,R8,R9)
---@param a1 T1
---@param a2 T2
---@return fun(a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):(R1,R2,R3,R4,R5,R6,R7,R8,R9)
function util.functools.Partial2(f, a1, a2)
    return function(...)
        return f(a1, a2, ...)
    end
end

---@generic T1,T2,T3,T4,T5,T6,T7,T8,T9,R1,R2,R3,R4,R5,R6,R7,R8,R9
---@param f fun(a1:T1,a2:T2,a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):(R1,R2,R3,R4,R5,R6,R7,R8,R9)
---@param a1 T1
---@param a2 T2
---@param a3 T3
---@return fun(a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):(R1,R2,R3,R4,R5,R6,R7,R8,R9)
function util.functools.Partial3(f, a1, a2, a3)
    return function(...)
        return f(a1, a2, a3, ...)
    end
end

---@generic T1,T2,T3,T4,T5,T6,T7,T8,T9,R1,R2,R3,R4,R5,R6,R7,R8,R9
---@param f fun(a1:T1,a2:T2,a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):(R1,R2,R3,R4,R5,R6,R7,R8,R9)
---@param a1 T1
---@param a2 T2
---@param a3 T3
---@param a4 T4
---@return fun(a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):(R1,R2,R3,R4,R5,R6,R7,R8,R9)
function util.functools.Partial4(f, a1, a2, a3, a4)
    return function(...)
        return f(a1, a2, a3, a4, ...)
    end
end

---@generic T1,T2,T3,T4,T5,T6,T7,T8,T9,R1,R2,R3,R4,R5,R6,R7,R8,R9
---@param f fun(a1:T1,a2:T2,a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):(R1,R2,R3,R4,R5,R6,R7,R8,R9)
---@param a1 T1
---@param a2 T2
---@param a3 T3
---@param a4 T4
---@param a5 T5
---@return fun(a6:T6,a7:T7,a8:T8,a9:T9):(R1,R2,R3,R4,R5,R6,R7,R8,R9)
function util.functools.Partial5(f, a1, a2, a3, a4, a5)
    return function(...)
        return f(a1, a2, a3, a4, a5, ...)
    end
end

---@generic T1,T2,T3,T4,T5,T6,T7,T8,T9,R1,R2,R3,R4,R5,R6,R7,R8,R9
---@param f fun(a1:T1,a2:T2,a3:T3,a4:T4,a5:T5,a6:T6,a7:T7,a8:T8,a9:T9):(R1,R2,R3,R4,R5,R6,R7,R8,R9)
---@param a1 T1
---@param a2 T2
---@param a3 T3
---@param a4 T4
---@param a5 T5
---@param a6 T6
---@return fun(a7:T7,a8:T8,a9:T9):(R1,R2,R3,R4,R5,R6,R7,R8,R9)
function util.functools.Partial6(f, a1, a2, a3, a4, a5, a6)
    return function(...)
        return f(a1, a2, a3, a4, a5, a6, ...)
    end
end

do
    local select = select
    local unpack = table.unpack

    function util.functools.GetSpecificArgs(lastArg, ...)
        return {select(lastArg + 1, ...)}, select("#", ...) - lastArg, unpack({...}, 1, lastArg)
    end
end

do
    local create = coroutine.create
    local error = error
    local GetSpecificArgs = util.functools.GetSpecificArgs
    local resume = coroutine.resume
    local status = coroutine.status
    local unpack = table.unpack

    ---@generic T
    ---@param func fun(...):...
    ---@param t {[T]:fun(...):...}
    ---@param k T
    ---@return fun(...):...
    ---@overload fun(func:fun(...):...):fun(...):...
    function util.cotools.pwrap(func, t, k)
        local isManagingData = t ~= nil and k ~= nil
        local co = create(func)

        ---@param ... any
        ---@return any
        local function coOut(...)
            local success, out
            
            if status(co) ~= "dead" then
                local n

                out, n, success = GetSpecificArgs(1, resume(co, ...))

                if success then return unpack(out, n) end
            end

            if isManagingData then
                t[k] = nil
            end

            if success == false then error(out[1], 2) end
        end

        if isManagingData then
            t[k] = coOut
        end

        return coOut
    end
end

do
    ---@param success boolean
    ---@param err any
    ---@param ... any
    ---@return ...
    local function addLevel(success, err, ...)
        if success then return err, ... end
        if type(err) == "string" then err = err:sub(8) end
        error(err, 4)
    end

    ---@generic T:any...
    ---@generic R:any...
    ---@param func fun(args:T):R
    ---@param ... T
    ---@return R
    function util.debug.upcall(func, ...)
        return addLevel(pcall(func, ...))
    end
end
local upcall = util.debug.upcall

---@param t table
function util.itertools.ClearTable(t)
    for k in next, t do
        t[k] = nil
    end
end

---@generic T1:table, T2:table
---@param t1 T1
---@param t2? T2
---@return T1|T2
function util.itertools.CopyTable(t1, t2)
    t2 = t2 or {}

    for k, v in next, t1 do
        t2[k] = v
    end
    return t2
end

---@generic K
---@param t table<K,any>
---@param ... K
function util.itertools.RemoveKeys(t, ...)
    for k in {...} do
        t[k] = nil
    end
end

---@generic V
---@param t table<any,V>
---@param value V
function util.itertools.RemoveValue(t, value)
    for k, v in next, t do
        if v == value then
            t[k] = nil
            return
        end
    end
end

---@generic V
---@param t table<any,V>
---@param ... V
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
---@param t V[]
---@param predicate? fun(v:V):boolean
---@return boolean
function util.itertools.Any(t, predicate)
    if predicate then
        for v in t do
            if predicate(v) then return true end
        end
    else
        for v in t do
            if v then return true end
        end
    end
    return false
end

---@generic V
---@param t V[]
---@param predicate? fun(v:V):boolean
---@return boolean
function util.itertools.All(t, predicate)
    if predicate then
        for v in t do
            if not predicate(v) then return false end
        end
    else
        for v in t do
            if not v then return false end
        end
    end
    return true
end

---@generic V
---@param t V[]
---@param predicate? fun(v:V):boolean
---@return boolean
function util.itertools.None(t, predicate)
    if predicate then
        for v in t do
            if predicate(v) then return false end
        end
    else
        for v in t do
            if v then return false end
        end
    end
    return true
end

---@generic V
---@param t V[]
---@param v V
---@return boolean
function util.itertools.Contains(t, v)
    for _v in t do
        if _v == v then
            return true
        end
    end
    return false
end

do
    local wrap = coroutine.wrap
    local yield = coroutine.yield

    local function co(l, p)
        yield()
        for v in l do
            if p(v) then
                yield(v)
            end
        end
    end
    
    ---@generic T
    ---@param l Iterable<T>
    ---@param p fun(v:T):boolean
    ---@return fun():T?
    function util.itertools.FilterList(l, p)
        local out = wrap(co)

        out(l, p)
        return out
    end
end

---@generic T
---@param t Iterable<T>
---@param p fun(v:T):boolean
---@return fun():T?
function util.itertools.GetFirst(t, p)
    for v in t do
        if p(v) then
            return v
        end
    end
end

---@generic T
---@param f fun():T?
---@return T[]
function util.itertools.ToList(f)
    local i = 0
    local t = {}

    for v in f do
        i = i + 1
        t[i] = v
    end
    return t
end

do
    local wrap = coroutine.wrap
    local yield = coroutine.yield
    
    ---@generic T1,T2
    ---@param t Iterable<T>
    ---@param f fun(v:T1):T2
    ---@return fun():T2?
    function util.itertools.PostList(t, f)
        return wrap(
        function()
            for v in t do
                yield(f(v))
            end
        end)
    end
end

do
    local next = next
    local wrap = coroutine.wrap
    local yield = coroutine.yield

    local function co(t, p)
        yield()
        for k, v in next, t do
            if p(k, v) then
                yield(k, v)
            end
        end
    end
    
    ---@generic K
    ---@generic V
    ---@param t table<K,V>|fun():(K?,V?)
    ---@param p fun(k:K, v:V):boolean
    ---@return fun():(K?,V?)
    function util.itertools.FilterTable(t, p)
        local out = wrap(co)

        out(t, p)
        return out
    end
end

---@generic K
---@generic V
---@param func fun():(K?,V?)
---@return table<K,V>
function util.itertools.ToTable(func)
    local t = {}

    for k, v in func do
        t[k] = v
    end
    return t
end

do
    local wrap = coroutine.wrap
    local yield = coroutine.yield

    ---@generic T
    ---@param ... T[]
    ---@return fun():T
    function util.itertools.Chain(...)
        local out = wrap(
        function(lists)
            yield()
            for l in lists do
                for v in l do
                    yield(v)
                end
            end
        end)
        
        out({...})
        return out
    end
end

do
    local OTHER = Constants.ITEMS_PER_FRAME.OTHER

    local wrap = coroutine.wrap
    local yield = coroutine.yield

    ---@generic T
    ---@param iter Iterable<T>
    ---@param n ITEMS_PER_FRAME
    ---@return boolean|fun():T?
    function util.itertools.Limiter(iter, n)
        local out = wrap(
        function(_iter, _n, i)
            for v in _iter do
                if i >= _n then
                    i = 0
                    yield(nil)
                    yield(true)
                end
                i = i + 1
                yield(v)
            end
            yield(nil)
            return false
        end)

        n = n or OTHER
        out(iter, n, n)
        return out
    end
end

do
    local next = next
    local Parial1 = util.functools.Partial1
    local wrap = coroutine.wrap
    local yield = coroutine.yield

    ---@generic T
    ---@param l T[]
    ---@param n integer
    ---@return T
    local function iterLooper(l, n)
        local i = 0

        while true do
            yield()
            for _=1,n,1 do
                i = i + 1

                local v = l[i]

                if v == nil then
                    i = 1
                    v = l[i]
                end
                yield(v)
            end
        end
    end

    ---@generic K,V
    ---@param t table<K,V>
    ---@param n integer
    ---@return K,V
    local function nextLooper(t, n)
        local k

        while true do
            yield()
            for _=1,n,1 do
                local v
                k, v = next(t, k)
                
                if k == nil then
                    k, v = next(t)
                end
                
                yield(k, v)
            end
        end
    end

    ---@generic K,V
    ---@param f fun():(K,V)
    ---@param t table<K,V>
    ---@param n? integer
    ---@return fun():(K,V)
    local function looper(f, t, n)
        local _Looper = wrap(f)

        _Looper(t, (n == nil or n < 1) and 1 or n)
        return _Looper
    end

    ---@generic T
    ---@type fun(l:T[], n:integer?):fun():T
    util.itertools.LoopList = Parial1(looper, iterLooper)
    ---@generic K,V
    ---@type fun(t:table<K,V>, n:integer?):fun():(K,V)
    util.itertools.LoopTable = Parial1(looper, nextLooper)
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

---@generic T
---@return T[]
---@return fun(v:T)
function util.itertools.CreateBuilder()
    local t = {}
    local i = 0

    return t, function(v)
        i = i + 1
        t[i] = v
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

        local HasFlag = util.mathtools.HasFlag
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
                if HasFlag(CLEAR_REG[flag], flags) then
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

        local HasFlag = util.mathtools.HasFlag
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
                if HasFlag(CLEAR_REG[flag], flags) then
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
    function util.mathtools.AddNoise(value, deviation)
        return value*(1 + deviation*(2*random() - 1))
    end
end

---@param ... any
function util.None(...)
end

---@param ... any
---@return true
---@nodiscard
function util.True(...)
    return true
end

do
    local WAIT = Constants.ID_OBJECTIVE_BASE.WAIT

    ---@param instance Barotrauma.AIObjectiveGoTo
    ---@return boolean
    function util.IsAtWaitObjective(instance)
        return  instance.Identifier == WAIT and
            instance.IsCloseEnough
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
    local Contained = LuaUserData.CreateEnumTable("Barotrauma.RelatedItem+RelationType")["Contained"]
    local ItemContainer = Components.ItemContainer
    
    ---@param container Barotrauma.Item
    ---@param targetTags Set<Barotrauma.Identifier>
    ---@return integer[]?
    function util.GetSpecificSlots(container, targetTags)
        local itemContainer = container.GetComponent(ItemContainer)

        if itemContainer then
            local slotIdx = 0
            local validSlots = {}
            local i = 0

            for slotR in itemContainer.slotRestrictions do
                local isChecked = false
                local ContainableItems = slotR.ContainableItems

                if ContainableItems then
                    for relatedItem in slotR.ContainableItems do
                        if  relatedItem.Type == Contained and
                            not relatedItem.RequireEmpty
                        then
                            for id in relatedItem.Identifiers do
                                if targetTags[id] then
                                    i = i + 1
                                    validSlots[i] = slotIdx
                                    isChecked = true
                                    break
                                end
                            end
                        end
                        if isChecked then break end
                    end
                end
                slotIdx = slotIdx + 1
            end
            return i > 0 and validSlots or nil
        end
        return nil
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

do
    local dontTakeItemsId = Identifier("donttakeitems")

    ---@param item Barotrauma.Item
    ---@return boolean
    function util.ParentItemsHaveDontTakeItemsTag(item)
        local container = item.Container
        
        while container do
            if container.HasTag(dontTakeItemsId) then return true end
            container = container.Container
        end
        return false
    end
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
                    (not targetContainableItemTag or FindItem(nil, inventory.GetAllItems(false), targetContainableItemTag, targetConditionPercentageRange))
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
    local pi = math.pi
    
    local cos = math.cos
    local sin = math.sin
    local Vector2 = Vector2

    ---@param center Microsoft.Xna.Framework.Vector2
    ---@param radius number
    ---@param points integer
    ---@param firstAngle number
    ---@return Microsoft.Xna.Framework.Vector2[]
    function util.mathtools.GetPointsOnCircumference(center, radius, points, firstAngle)
        local maxAngle = 2*pi
        local angleStep = maxAngle/points;

        local coordinates = {}
        for i=1,points,1 do
            local angle = firstAngle + (i*angleStep)
            
            if angle > maxAngle then angle = angle - maxAngle end
            coordinates[i] = Vector2(
                center.X + radius*cos(angle),
                center.Y + radius*sin(angle)
            )
        end
        return coordinates
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

-- do
--     local Contains = util.itertools.Contains

--     ---@type fun(instance:Barotrauma.AIObjective, objective:AIObjective, constructor:fun():(Barotrauma.AIObjective), onCompletedGenerator:fun(Barotrauma.AIObjective), onAbandonGenerator:fun(Barotrauma.AIObjective)):boolean
--     ---@generic T:Barotrauma.AIObjective
--     ---@param instance Barotrauma.AIObjective
--     ---@param objective nil
--     ---@param constructor fun():T
--     ---@param onCompletedGenerator fun(Barotrauma.AIObjective: any)
--     ---@param onAbandonGenerator fun(Barotrauma.AIObjective: any)
--     ---@return boolean
--     ---@return T?
--     function util.TryAddSubObjective(instance, objective, constructor, onCompletedGenerator, onAbandonGenerator)
--         if objective ~= nil then
--             return false, Contains(instance.subObjectives, objective) and objective or nil
--         else
--             objective = constructor()

--             if Contains(instance.subObjectives, objective) then return false, objective end
--             if instance.AllowMultipleInstances then
--                 objective.SourceObjective = instance
--                 instance.subObjectives.Add(objective)
--             else
--                 instance.AddSubObjective(objective)
--             end
--             if onCompletedGenerator ~= nil then
--                 objective.Completed.add(onCompletedGenerator(objective))
--             end
--             if onAbandonGenerator ~= nil then
--                 objective.Abandoned.add(onAbandonGenerator(objective))
--             end
--             return true, objective
--         end
--     end
-- end

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

do
    local Game = Game
    local XElement = XElement

    function util.debug.PrintOrders()
        local session = Game.GameSession

        if not session then return end

        local orderData = XElement.__new("OrderData")

        session.CrewManager.SaveActiveOrders(orderData)
        print(orderData)
    end
end

---@param descriptor MoonSharp.Interpreter.Interop.IUserDataDescriptor
---@return System.Type
function util.DescriptorToType(descriptor)
    return descriptor.Type
end

do
    local Descriptors = Descriptors
    
    local AddMethod = LuaUserData.AddMethod
    local DescriptorToType = util.DescriptorToType
    local FilterTable = util.itertools.FilterTable
    local IsRegistered = LuaUserData.IsRegistered
    local HasMember = LuaUserData.HasMember
    local IsTargetType = LuaUserData.IsTargetType
    local RegisterType = LuaUserData.RegisterType
    local RemoveMember = LuaUserData.RemoveMember

    local MethodData

    do
        local mt = {
            __index=function(t, k)
                local typeData = {}

                t[k] = typeData
                return typeData
            end
        }
        ---@type {[string]:{[string]:fun(...):...}}
        MethodData = setmetatable({}, {
            __index=function(t, k)
                local typeData = setmetatable({}, mt)

                t[k] = typeData
                return typeData
            end
        })
    end

    ---@param className string
    ---@return MoonSharp.Interpreter.Interop.IUserDataDescriptor
    local function AutoRegisterType(className)
        local descriptor

        if  IsRegistered(className) then
            descriptor = Descriptors[className]
        end

        if  descriptor == nil then
            descriptor = upcall(RegisterType, className)

            local type = descriptor.Type

            for typeName, typeMethodData in FilterTable(MethodData, function(typeName, typeMethodData) return IsTargetType(type, typeName) end) do
                for methodName, method in next, typeMethodData do
                    AddMethod(descriptor, methodName, method)
                end
            end
        end
        return descriptor
    end

    util.AutoRegisterType = AutoRegisterType

    ---@generic T
    ---@param className `T`
    ---@param methodName string
    ---@param method fun(instance:T, ...):...
    function util.AddMethod(className, methodName, method)
        upcall(AutoRegisterType, className)

        methodName = Constants.Acronym.."_"..methodName
        for typeName, descriptor in FilterTable(Descriptors,
        function(typeName, descriptor)
            local success, type = pcall(DescriptorToType, descriptor)
            
            return success and IsTargetType(type, className)
        end) do
            AddMethod(descriptor, methodName, method)
        end
        MethodData[className][methodName] = method
    end

    ---@param className string
    ---@param methodName string
    function util.RemoveMethod(className, methodName)
        for typeName, descriptor in FilterTable(Descriptors,
        function(typeName, descriptor)
            local success, type = pcall(DescriptorToType, descriptor)
            
            return success and
                IsTargetType(type, className) and
                HasMember(type, methodName)
        end) do
            RemoveMember(descriptor, methodName)
        end
        MethodData[className][methodName] = nil
    end
end

do
    local AutoRegisterType = util.AutoRegisterType

    ---@param ... string
    function util.AutoRegisterAll(...)
        for typeName in {...} do
            upcall(AutoRegisterType, typeName)
        end
    end
end

do
    local UnregisterType = LuaUserData.UnregisterType

    ---@param ... string
    function util.UnregisterAll(...)
        for typeName in {...} do
            upcall(UnregisterType, typeName)
        end
    end
end

do
    local unpack = table.unpack
    local AutoRegisterAll = util.AutoRegisterAll
    local UnregisterAll = util.UnregisterAll

    ---@generic T:any...
    ---@generic R:any...
    ---@param typeNames string[]
    ---@param func fun(args:T):R
    ---@param ... T
    ---@return R
    function util.DoWithTemporaryRegistrations(typeNames, func, ...)
        upcall(AutoRegisterAll, unpack(typeNames))

        local out = {upcall(func, ...)}

        upcall(UnregisterAll, unpack(typeNames))
        return unpack(out)
    end
end

-- do
--     DoWithTemporaryRegistrations = util.DoWithTemporaryRegistrations

--     ---@generic T
--     ---@param generator fun():T
--     ---@param typeName `T`
--     ---@param ... string
--     ---@return T
--     function util.GetStrongRef(generator, typeName, ...)
--         return 
--     end
-- end

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
    local type = type

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

        local preOptionString, subOptionString = optionString:match("(.+[^%.]+)%.([^%.]+)$")

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
        local GetType = LuaUserData.GetType

        ---@param className string
        ---@return string[]
        local function inner(className)
            for v in GetType(className).GetMethods(4 + 8 + 16 + 32) do
                local name = v.Name --[[@type string]]
                
                print(name)
            end
        end

        ---@param className string
        function util.debug.PrintAllMethodNames(className)
            return DoWithTemporaryRegistrations({
                "System.Type",
                "System.Reflection.RuntimeMethodInfo"
            }, inner, className)
        end
    end
    
    do
        local DoWithTemporaryRegistrations = util.DoWithTemporaryRegistrations
        local GetType = LuaUserData.GetType

        ---@param className string
        ---@return string[]
        local function inner(className)
            for v in GetType(className).GetFields(4 + 8 + 16 + 32) do
                local name = v.Name --[[@type string]]
                
                print(name)
            end
        end

        ---@param className string
        function util.debug.PrintAllFieldNames(className)
            return DoWithTemporaryRegistrations({
                "System.Type",
                "System.Reflection.RuntimeFieldInfo"
            }, inner, className)
        end
    end

    do
        local DoWithTemporaryRegistrations = util.DoWithTemporaryRegistrations
        local GetType = LuaUserData.GetType

        ---@param className string
        ---@param mainFuncName string
        ---@param nestedFuncName string
        ---@return string?
        local function inner(className, mainFuncName, nestedFuncName)
            local pattern = "<"..mainFuncName..">g__"..nestedFuncName.."|"

            for k, v in next, GetType(className).GetMethods(4 + 8 + 16 + 32) do
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

do
    local Character = Character
    local CharacterInfo = CharacterInfo
    local Game = Game
    local XElement = XElement

    local characterOrders
    
    function util.SaveCharacterOrders()
        local session = Game.GameSession

        if not session then return end

        characterOrders = {}

        for charInfo in session.CrewManager.GetCharacterInfos() do
            local xElement = XElement.__new("Orders")

            CharacterInfo.SaveOrderData(charInfo, xElement)
            characterOrders[charInfo.Name] = xElement
        end
        return characterOrders
    end

    function util.LoadCharacterOrders()
        if characterOrders == nil then return end

        local session = Game.GameSession

        if not session then return end

        for character in Character.CharacterList do
            local charInfo = character.Info

            if  charInfo and
                characterOrders[charInfo.Name]
            then
                CharacterInfo.ApplyOrderData(character, characterOrders[character.Info.Name])
            end
        end
        characterOrders = nil
    end
end

do
    local Identifier = Identifier

    ---@param ... string
    ---@return Barotrauma.Identifier[]
    function util.AsIdentifiers(...)
        local ids = {}
        local i = 0

        for s in {...} do
            i = i + 1
            ids[i] = Identifier(s)
        end

        return ids
    end
end

do
    local parseT --[[@type table<string, fun(builder:fun(v:System.Xml.Linq.XElement|string), e:System.Xml.Linq.XElement|string, s:string)>]]

    ---@param builder fun(v:System.Xml.Linq.XElement|string)
    ---@param e System.Xml.Linq.XElement|string
    ---@param s string
    local function parse(builder, e, s)
        if s == "" then
            return builder(e)
        elseif (select(2, s:gsub("^([%[/@])(.+)$",
                function(_s1, _s2)
                    return parseT[_s1](builder, e, _s2)
                end))) <= 0
        then
        -- else
            local s1, s2 = s:match("^([^%[%]/|=@]+)(.-)$") --[[@type string, string]]

            if s1 then
                for e1 in e.Elements(s1) do
                    parse(builder, e1, s2)
                end
            end

            -- if s1 then
            --     for e1 in e.Elements(s1) do
            --         parse(builder, e1, s2)
            --     end
            -- else
            --     return parseT[s:sub(1,1)](builder, e, s:sub(2))
            -- end
        end
    end
    
    parseT = { --[[@type table<string, fun(builder:fun(v:System.Xml.Linq.XElement|string), e:System.Xml.Linq.XElement|string, s:string)>]]
        ["/"]=function(builder, e, s)
            if s:sub(1, 1) == "/" then return parseT["//"](builder, e, s:sub(2)) end

            local s1, s2 = s:match("^([^%[%]/|=@]+)(.-)$") --[[@type string, string]]
            
            if s1 then
                for e1 in e.Elements(s1) do
                    parse(builder, e1, s2)
                end
            end
        end,
        ["//"]=function(builder, e, s)
            local s1, s2 = s:match("^([^%[%]/|=@]+)(.-)$") --[[@type string, string]]
            
            if s1 then
                for e1 in e.Descendants(s1) do
                    parse(builder, e1, s2)
                end
            else
                for e1 in e.Descendants() do
                    parse(builder, e1, s)
                end
            end
        end,
        ["["]=function(builder, e, s)
            local cond = false
            local s1, s2 = ("["..s):match("^(%b[])(.-)$") --[[@type string, string]]

            s1:gsub("^%[([^=]+)=?(.-)%]$",
            function(s3, s4)
                parse(function(v) cond = cond or s4 == "" or v == s4 end, e, s3)
            end, 1)

            --parse(function() print("test") cond=true end, e, s1)
            
            if cond then
                return parse(builder, e, s2)
            end

            -- local s1, s2 = ("["..s):match("^(%b[])(.-)$") --[[@type string, string]]
            -- if parse(builder, e, s1:sub(2, -2)) then
            --     return parse(builder, e, s2)
            -- end
        end,
        ["@"]=function(builder, e, s)
            local attr = e.GetAttributeString(s)

            if attr then
                parse(builder, attr, "")
            end

            -- local s1, s2 = s:match("^([^%[%]/|=@]+)=?(.-)$") --[[@type string, string]]
            -- local attr = e.GetAttributeString(s1)

            -- if s2 ~= nil and s2 ~= "" and s2 == attr or attr ~= nil then
            --     return parse(builder, e, s2)
            -- end
        end
    }

    local CreateBuilder = util.itertools.CreateBuilder
    local error = error
    local Partial2 = util.functools.Partial2

    ---@param xElement System.Xml.Linq.XElement
    ---@param xPathStr string
    ---@return Iterable<System.Xml.Linq.XElement|string>
    function util.xPath(xElement, xPathStr)
        if xElement == nil then error("xElement cannot be nil", 2) end
        if xPathStr == nil then error("xPathStr cannot be nil", 2) end

        local out, builder = CreateBuilder()
        
        -- for s in xPathStr:gmatch("([^|]+)|?") do
        --     parse(builder, xElement, s)
        -- end
        xPathStr:gsub("([^|]+)|?", Partial2(parse, builder, xElement))
        return out
    end
end

do
    local TryAll = util.functools.TryAll

    ---@param contElement System.Xml.Linq.XElement
    ---@return Iterable<Barotrauma.Identifier>?
    ---@overload fun(riElement:System.Xml.Linq.XElement):(Iterable<Barotrauma.Identifier>?)
    function util.xGetItemTags(contElement)
        return TryAll(contElement.GetAttributeIdentifierArray, "items", "item", "identifiers", "identifier", "tags", "tag")
    end
end

do
    local TryAll = util.functools.TryAll

    ---@param seElement System.Xml.Linq.XElement
    ---@return Iterable<Barotrauma.Identifier>?
    function util.xGetStatusEffectTargets(seElement)
        return TryAll(seElement.GetAttributeIdentifierArray, "targetnames", "targets", "targetidentifiers", "targettags")
    end
end

do
    local TryAll = util.functools.TryAll

    ---@param seElement System.Xml.Linq.XElement
    ---@return string?
    function util.xGetStatusEffectTargetType(seElement)
        return TryAll(seElement.GetAttributeString, "target", "targettype")
    end
end

---@alias QualityValue `0`|`1`|`2`|`3`

---@alias ItemData {itemPrefab:Barotrauma.ItemPrefab?, itemIds:table<Barotrauma.Identifier, boolean>?, minQuality:QualityValue?, minAmount:integer?}

do
    local parseItemIds do
        local Identifier = Identifier

        ---@private
        ---@param itemIds table<Barotrauma.Identifier, boolean>
        ---@param v `""`|`"!"`
        ---@param itemIdStr string
        function parseItemIds(itemIds, v, itemIdStr)
            itemIds[Identifier(itemIdStr)] = v ~= "!"
        end
    end

    local next = next
    local Partial1 = util.functools.Partial1
    local tonumber = tonumber

    local Normal = Constants.Quality.Normal
    local Prefabs = ItemPrefab.Prefabs

    ---@public
    ---@param itemStr string
    ---@return ItemData
    function util.StringToItemData(itemStr)
        local itemData = {}
        local itemIds = {}
        local idStrs, extra = itemStr:match("^([^|]*)(|?.*)$") --[[@type string, string]]
        local _, i = idStrs:gsub("(!?)([^%+]+)", Partial1(parseItemIds, itemIds))

        if i <= 0 then
            itemData.minQuality = Normal
        else
            local firstVal = (next(itemIds))

            if  i == 1 and
                Prefabs.ContainsKey(firstVal)
            then
                itemData.itemPrefab = Prefabs[firstVal]
            else
                itemData.itemIds = itemIds
            end

            local minAmount = extra:match("|A([%d]*)")

            itemData.minAmount = minAmount ~= nil and tonumber(minAmount) or 1

            local minQuality = extra:match("|Q([0-3]*)")
            
            itemData.minQuality = minQuality ~= nil and tonumber(minQuality) or Normal
        end

        return itemData
    end
end

do
    local parseItemData do
        local StringToItemSlotData = util.StringToItemData

        ---@param builder fun(v:ItemData)
        ---@param itemStr string
        function parseItemData(builder, itemStr)
            builder(StringToItemSlotData(itemStr))
        end
    end

    ---@param builder fun(v:ItemData)
    ---@param cache table<string, ItemData>
    ---@param itemStr string
    local function parseItemData_cached(builder, cache, itemStr)
        builder(cache[itemStr])
    end

    local CreateBuilder = util.itertools.CreateBuilder
    local Partial1 = util.functools.Partial1
    local Partial2 = util.functools.Partial2
    local setmetatable = setmetatable
    local StringToItemSlotData = util.StringToItemData

    ---@param loadoutStr string
    ---@param isCached? boolean
    ---@return ItemData[]
    function util.StringToLoadoutData(loadoutStr, isCached)
        local loadoutData, builder = CreateBuilder()
        
        if isCached then
            local cache = setmetatable({}, {
                __index=function(self, s)
                    local itemData = StringToItemSlotData(s)

                    self[s] = itemData
                    return itemData
                end
            })
            loadoutStr:gsub("([^:;]*);", Partial2(parseItemData_cached, builder, cache))
        else
            loadoutStr:gsub("([^:;]*);", Partial1(parseItemData, builder))
        end
        return loadoutData
    end
end

do
    local parseJobIdAndLoadoutData do
        local StringToLoadoutData = util.StringToLoadoutData

        local Identifier = Identifier

        ---@param allLoadoutData table<Barotrauma.Identifier, Iterable<ItemData>>
        ---@param isCached? boolean
        ---@param jobIdStr string
        ---@param loadoutStr string
        function parseJobIdAndLoadoutData(allLoadoutData, isCached, jobIdStr, loadoutStr)
            allLoadoutData[Identifier(jobIdStr)] = StringToLoadoutData(loadoutStr, isCached)
        end
    end
    
    local Partial2 = util.functools.Partial2

    ---@param allLoadoutStr string
    ---@param isCached? boolean
    ---@return table<Barotrauma.Identifier, ItemData[]>
    function util.StringToAllLoadout(allLoadoutStr, isCached)
        local allLoadoutData = {}
        local _parseJobIdAndLoadoutData = Partial2(parseJobIdAndLoadoutData, allLoadoutData, isCached)

        allLoadoutStr:gsub("([^:;]+):([^:]+;)", _parseJobIdAndLoadoutData)
        return allLoadoutData
    end
end

do
    local concat = table.concat
    local CreateBuilder = util.itertools.CreateBuilder
    local type = type

    ---@param itemDataOrPrefab? ItemData|Barotrauma.ItemPrefab
    ---@param itemIds? Iterable<Barotrauma.Identifier>
    ---@param minAmount? integer
    ---@param minQuality? QualityValue
    ---@return string
    ---@overload fun(itemPrefab?:Barotrauma.ItemPrefab, itemIds:Iterable<Barotrauma.Identifier>, minAmount:integer, minQuality:QualityValue):string
    ---@overload fun(itemData:ItemData):string
    function util.ItemDataToString(itemDataOrPrefab, itemIds, minAmount, minQuality)
        local itemPrefab

        if type(itemDataOrPrefab) == "table" then
            itemPrefab = itemDataOrPrefab.itemPrefab
            itemIds = itemDataOrPrefab.itemIds
            minAmount = itemDataOrPrefab.minAmount
            minQuality = itemDataOrPrefab.minQuality
        else
            itemPrefab = itemDataOrPrefab --[[@cast itemPrefab Barotrauma.ItemPrefab?]]
        end

        local itemDataStr do
            if itemPrefab then
                itemDataStr = itemPrefab.Identifier.Value
                --itemDataStr = itemDataStr..itemPrefab.Identifier.Value
            elseif itemIds then
                local joinT, builder = CreateBuilder()

                for itemId, v in next, itemIds do
                    if not v then
                        builder("!")
                    end
                    builder(itemId.Value)
                end
                itemDataStr = concat(joinT, "+")
            end
        end

        local joinT, builder = CreateBuilder()

        builder(itemDataStr)

        if  minQuality ~= nil and
            0 < minQuality
        then
            builder("|Q")
            builder(minQuality)
        end

        if  minAmount ~= nil and
            1 < minAmount
        then
            builder("|A")
            builder(minAmount)
        end
        
        return concat(joinT)
    end
end

do
    local concat = table.concat
    local CreateBuilder = util.itertools.CreateBuilder
    local ItemDataToString = util.ItemDataToString

    ---@param loadoutData Iterable<ItemData>
    function util.LoadoutToString(loadoutData)
        local joinT, builder = CreateBuilder()

        for itemData in loadoutData do
            builder(ItemDataToString(itemData))
        end
        builder("")
        return concat(joinT, ";")
    end
end

do
    local concat = table.concat
    local CreateBuilder = util.itertools.CreateBuilder
    local LoadoutToString = util.LoadoutToString
    local next = next

    ---@param allLoadoutData table<Barotrauma.Identifier, Iterable<ItemData>>
    ---@return string
    function util.AllLoadoutToString(allLoadoutData)
        local joinT, builder = CreateBuilder()

        for jobId, loadoutData in next, allLoadoutData do
            builder(jobId.Value)
            builder(":")
            builder(LoadoutToString(loadoutData))
        end
        return concat(joinT)
    end
end

-- do
--     local D_CREW_LOADOUT_SLOTS = Constants.D_CREW_LOADOUT_SLOTS
--     local D_HUMAN_INV_N = Constants.D_HUMAN_INV_N
--     local D_HUMAN_INV_N_ANY = Constants.D_HUMAN_INV_N_ANY
--     local Prefabs = ItemPrefab.Prefabs
--     local Identifier = Identifier

--     local CopyTable = util.itertools.CopyTable
--     local next = next
--     local rawget = rawget
--     local setmetatable = setmetatable
--     local tonumber = tonumber
--     local type = type

--     ---@param s string
--     ---@return Iterable<table<Barotrauma.Identifier, {id:(table<Barotrauma.Identifier, boolean>|Barotrauma.Identifier)?, quality:integer?, quantity:integer?}[]>>
--     function util.StringToLoadout(s)
--         local mt_itemStrMap = {
--             ---@param self table
--             ---@param itemStr string
--             ---@return table
--             __index=function(self, itemStr)
--                 local out = {}
--                 local id = {} --[[@type table<Barotrauma.Identifier, boolean>]]
--                 local idStrs, qa = itemStr:match("^([^|]*)(|?.*)$") --[[@type string, string]]
--                 local quality = qa:match("|Q([%-%d]*)")
--                 local amount = qa:match("|A([%d]*)")
--                 local i = 0

--                 for idStr in idStrs:gmatch("([^%+]+)") do
--                     i = i + 1
--                     id[Identifier(idStr)] = idStr:sub(1, 1) ~= "!"
--                 end

--                 if  idStrs ~= "" and
--                     i > 0
--                 then
--                     local firstVal = (next(id))

--                     if Prefabs.ContainsKey(firstVal) then
--                         out.id = firstVal
--                     else
--                         out.id = id
--                     end
--                 end
                
--                 out.quality = quality ~= nil and tonumber(quality) or nil
--                 out.amount = amount ~= nil and tonumber(amount) or nil

--                 self[itemStr] = out
--                 return out
--             end
--         }
--         local data = {}
--         local i = 0

--         for job, loadoutStr in s:gmatch("([^:;]+):([^:]+;)") do --[[@cast loadoutStr string?]]
--             local itemStrMap = setmetatable({}, mt_itemStrMap) --[[@type table<string, {id:(table<Barotrauma.Identifier, boolean>|Barotrauma.Identifier)?, quality:integer?, amount:integer?}>]]
--             local limbSlots = {} --[[@type table<{id:Barotrauma.Identifier, quality:integer?, amount:integer?}, {single:Set<Barotrauma.InvSlotType>, multi:table<integer, Set<Barotrauma.InvSlotType>>, partial:table<integer, {id:(table<Barotrauma.Identifier, boolean>|Barotrauma.Identifier)?, quality:integer?, amount:integer?}>}>]]
--             local loadoutData = {} --[[@type Iterable<{id:(table<Barotrauma.Identifier, boolean>|Barotrauma.Identifier)?, quality:integer?, amount:integer?}>]]
--             local j = 0
            
--             for itemStr in loadoutStr:gmatch("([^:;]*);") do
--                 local isFirst = rawget(itemStrMap, itemStr) == nil
--                 local itemData = itemStrMap[itemStr]
--                 local id = itemData.id
                
--                 j = j + 1

--                 if type(id) == "table" then
--                     loadoutData[j] = {id=id, quality=itemData.quality, amount=itemData.amount}
--                 elseif id == nil then
--                     loadoutData[j] = {}
--                 else
--                     local prefab = Prefabs[id]

--                     if isFirst then
--                         local single, multi = prefab:SBAI_getInvSlots()
--                         local itemLimbSlots = {single=single, multi=multi}

--                         if j > D_HUMAN_INV_N_ANY then
--                             local curSlot = D_CREW_LOADOUT_SLOTS[j]
                            
--                             if not single[curSlot] then
--                                 local matchingCombo

--                                 for comboSlot, slotSet in next, multi do
--                                     if slotSet[curSlot] then
--                                         matchingCombo = comboSlot
--                                         slotSet:Remove(curSlot)
--                                         break
--                                     end
--                                 end
--                                 itemLimbSlots.partial = {[matchingCombo]=itemData}
--                             end
--                             limbSlots[itemData] = itemLimbSlots
--                         end
--                         loadoutData[j] = itemData
--                     else
--                         if j > D_HUMAN_INV_N_ANY then
--                             local curSlot = D_CREW_LOADOUT_SLOTS[j]
--                             local itemLimbSlots = limbSlots[itemData]

--                             if not itemLimbSlots.single[curSlot] then
--                                 local multi = itemLimbSlots.multi

--                                 for comboSlot, slotSet in next, multi do
--                                     if slotSet[curSlot] then
--                                         slotSet:Remove(curSlot)
--                                         loadoutData[j] = itemLimbSlots.partial[comboSlot]
--                                         if slotSet:IsEmpty() then
--                                             multi[comboSlot] = nil
--                                             itemStrMap[itemStr] = nil
--                                         end
--                                         break
--                                     end
--                                 end
--                                 goto skip
--                             end
--                         end
--                         loadoutData[j] = CopyTable(itemData)
--                     end
--                 end
--                 ::skip::
--                 if j >= D_HUMAN_INV_N then break end
--             end
--             i = i + 1
--             data[i] = {[Identifier(job)]=loadoutData}
--         end
--         return data
--     end
-- end

return util