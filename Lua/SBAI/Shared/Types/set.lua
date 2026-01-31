---@class Set<T>: AbstractCollection<T>
---@operator len:integer
---@field public cls Set<T>
---@field public super AbstractCollection<T>
---@field public [T] true
---@field public add fun(self, v:T)
---@field public difference fun<V>(self, t:Iterable<V>):Set<T&-V>
---@field public differenceUpdate fun<V>(self, t:Iterable<V>)
---@field public intersection fun<V>(self, t:Iterable<V>):Set<T&V>
---@field public intersectionUpdate fun<V>(self, t:Iterable<V>)
---@field public remove fun(self, v:T)
---@field public symmetricDifference fun<V>(self, t:Iterable<V>):Set<(T&-V)&(V&-T)>
---@field public symmetricDifferenceUpdate fun<V>(self, t:Iterable<V>)
---@field public union fun<V>(self, t:Iterable<V>):Set<T+V>
---@field public update fun(self, t:Iterable<T>)
---@field protected __new fun<S:Set<T>>(self:S, iter?:fun():(T), ...:any):(S)
---@field package __iterator fun(self):((fun(self:Set<T>, k:T):T), Set<T>)
Types.Set = Types.new--[[@<Set<T>, AbstractCollection<T>>]]("Set", "AbstractCollection", {
    isEmpty = Types.Desc.TiedConstant(
    function(self, cls, obj)
        for k in obj do
            return false
        end
        return true
    end);
})


local t = {} ---@type Set<integer>


local Set = Types.Set

onGlobalLoad("Tabletools",
function(v)
    Set.clear = v.clear
end)

---@nodiscard
function Set:__new(iter, ...)
    local obj = Set.super.__new(self, ...) ---@as Set

    if iter ~= nil then
        self:update(iter)
    end
    return obj
end

do
    local next = next

    ---@generic T
    ---@param t Set<T>
    ---@param k T
    ---@return T
    local function _iter(t, k)
        k = (next(t, k))
        if k == "cls" then
            return (next(t, k))
        else
            return k
        end
    end

    function Set:__iterator()
        return _iter, self
    end
end


function Set:__len()
    local i = 0

    for _ in self do
        i = i + 1
    end
    return i
end

function Set:add(v)
    self[v] = true
end

function Set:remove(v)
    self[v] = nil
end

function Set:update(t)
    for v in t do
        self:add(v)
    end
end

function Set:copy()
    return Set(self)
end

function Set:union(t)
    local out = self:copy()

    out:update(t)
    return out
end

function Set:intersectionUpdate(t)
    for v in self do
        if t[v] == nil then
            self:Remove(v)
        end
    end
end

function Set:intersection(t)
    local out = self:copy()

    out:intersectionUpdate(t)
    return out
end

function Set:differenceUpdate(t)
    for v in t do
        self:remove(v)
    end
end

function Set:difference(t)
    local out = self:copy()

    out:differenceUpdate(t)
    return out
end

function Set:symmetricDifferenceUpdate(t)
    for v in t do
        self[v] = not self[v] and true or nil
    end
end

function Set:symmetricDifference(t)
    local out = self:copy()

    out:symmetricDifferenceUpdate(t)
    return out
end

return Set