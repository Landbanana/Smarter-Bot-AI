---@class Match<K,V>: Object
---@field public cls Match<K,V>
---@field public case fun(self, fc:fun(k:K):(boolean)|K, v?:V):(self)
---@field public default fun(self, v:V):(self)
---@field public eval fun(self, k:K):(V)
---@field protected __new fun<S:Match<K,V>>(self:S, ...:any):(S)
---@field protected _awaiting Deque<(fun(k:K):boolean)|K>
---@field protected _default? V
---@field protected _cases {[K]:any}
---@field protected _results Deque<V>
---@field protected _case fun(self, fc:fun(k:K):(boolean)|K, v?:V):(self)
---@field protected _predicates Deque<fun(k:K):boolean>
Types.Match = Types.new--[[@<Match<K,V>, Object>]]("Match")

local Match = Types.Match

do
    local Deque = Types.Deque

    ---@nodiscard
    function Match:__new(...)
        local obj = Match.super.__new(self, ...) ---@as Match

        obj._awaiting = Deque()
        obj._cases = {}
        obj._predicates = Deque()
        obj._results = Deque()
        return obj
    end
end

function Match:case(fc, v)
    local awaiting = self._awaiting

    if v == nil then
        awaiting:push(fc)
    else
        repeat self:_case(fc, v)
            fc = awaiting:popL()
        until fc == nil
    end
    return self
end

---@nodiscard
function Match:default(v)
    self._default = v
    self._awaiting:clear()
    return self
end

---@nodiscard
function Match:eval(k)
    local v = self._cases[k]

    if v ~= nil then return v end

    local predicates = self._predicates

    for n=predicates.i,predicates.j do
        if predicates[n](k) then
            return self._results[n]
        end
    end
    return self._default
end

do
    local type = type

    function Match:_case(fc, v)
        if type(fc) == "function" then
            self._predicates:push(fc)
            self._results:push(v)
        else
            self._cases[fc] = v
        end
        return self
    end
end

return Types.Match
