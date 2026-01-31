---@class Cache<K,R>: Object
---@field public cls Cache<K,R>
---@field public baseFunction fun(k:K):(R)
---@field public cachedFunction fun(k:K):(R)
---@field public clear fun(self)
---@field public deleteEntry fun(self, k:K)
---@field protected __new fun<S:Cache<K,R>>(self:S, f:fun(k:K):(R), ...:any):(S)
---@field package data {[K]:R}
---@field package memoize_mt metatable
Types.Cache = Types.new--[=[@<Cache<K,R>, Object>]=]("Cache", "Object", {
    baseFunction = Types.Desc.Readonly();
})

local Cache = Types.Cache

do
    local memoize_mt = {}
    function memoize_mt.__index(t, k)
        local out = t[memoize_mt](k)

        t[k] = out
        return out
    end

    Cache.memoize_mt = memoize_mt

    local setmetatable = setmetatable

    ---@nodiscard
    function Cache:__new(f, ...)
        local obj = Cache.super.__new(self, ...)
        local data = setmetatable({[memoize_mt]=f}, memoize_mt)

        obj.baseFunction = f
        function obj.cachedFunction(k)
            return data[k]
        end
        obj.data = data

        return obj
    end
end

do
    local next = next

    function Cache:clear()
        local data = self.data

        for k in next, data do
            data[k] = nil
        end
    end
end

function Cache:deleteEntry(k)
    self.data[k] = nil
end

return Types.Cache