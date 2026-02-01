---@class Itertools
local Itertools = {}

do
    local yield = coroutine.yield

    ---@async
    ---@generic T:std.NotNull<any>
    ---@param iter Iterable<T>
    ---@param pred fun(v:T):boolean
    ---@return T
    ---@nodiscard
    function Itertools.co_filter(iter, pred)
        for v in iter do
            if pred(v) then
             yield(v)
            end
        end
        return nil
    end
end

do
    local co_chain_start do
        local yield = coroutine.yield

        ---@async
        ---@generic T
        ---@param iter1 Iterable<T>
        ---@param iter2? Iterable<T>
        ---@param ... Iterable<T>
        ---@return T
        ---@nodiscard
        local function co_chain(iter1, iter2, ...)
            for v in iter1 do
                yield(v)
            end
            if iter2 == nil then
                return nil
            else
                return co_chain(iter2, ...)
            end
        end

        Itertools.co_chain = co_chain

        ---@async
        ---@generic T:std.NotNull<any>
        ---@param iter1 Iterable<T>
        ---@param ... Iterable<T>
        ---@return T
        co_chain_start = function (iter1, ...)
            yield()
            return co_chain(iter1, ...)
        end
    end

    local wrap = coroutine.wrap


    ---@generic T:std.NotNull<any>
    ---@param iter1 Iterable<T>
    ---@param ... Iterable<T>
    ---@return Iterator<T>
    ---@nodiscard
    function Itertools.chain(iter1, ...)
        local co = wrap(co_chain_start)

        co(iter1, ...)
        return co
    end
end

do
    ---@generic T:std.NotNull<any>
    ---@param ... Iterable<T>
    ---@return Iterator<T>
    local function chain(...)
        local i = 1
        local j = 1
        local n = select("#", ...)
        local iters = {select(2, ...)}
        local iter = (...)

        return function(t, k)
            local out = t

            if out == nil then
                j = j + 1
                iter = iters[j]

                if iter == nil then
                    return nil
                end
            end

            i = i + 1

        end
    end
end

---@generic V
---@param t fun():(V)
---@param v V
---@return boolean
---@nodiscard
function Itertools.contains(t, v)
    for _v in t do
        if _v == v then return true end
    end
    return false
end

---@generic V
---@param t fun():(V)
---@param p? fun(v:V):boolean
---@return boolean
---@nodiscard
function Itertools.any(t, p)
    if p then
        for v in t do
            if p(v) then return true end
        end
    else
        for v in t do
            if v ~= nil then return true end
        end
    end
    return false
end

-- do
--     local ferror = ferror

--     ---@overload fun<K,V>(t:table<K,V>, k:K, v:V):(integer)
--     ---@overload fun<K,V>(t:table<K,V>, k:nil, v:V):(integer, K)
--     ---@overload fun<K,V>(t:table<K,V>, k:K):(integer, V)
--     function Itertools.indexKBNum(t, k, v)
--         kocal i = 0
--         if k == nil then
--             if v == nil then
--                 return ferror("No key and / or value to index")
--             else
--                 for k, v in next, t do
--                     if
--                 end
--                 b in
--             end
--         elseif v == nil then

--         else


--         end
--     end
-- end

do
    -- ---@overload fun(iterable:fun():(T?), default:std.ConstTpl<D>, pred:fun(v:T):(boolean)):(T|D)
    -- ---@overload fun(iterable:fun():(T?), default:std.ConstTpl<D>, pred:fun(v:T):(boolean)):(T|D)
    -- ---@overload fun(iterable:fun():(T?), default:nil, pred:fun(v:T):(boolean)):(T?)
    -- ---@overload fun(iterable:fun():(T?)):(T?)

    ---@generic T
    ---@param iterable fun():(T?)
    ---@param pred? fun(v:T):(boolean)
    ---@return T?
    ---@nodiscard
    ---@overload fun(iterable:fun():(T?), pred:fun(v:T):(boolean)):(T?)
    ---@overload fun(iterable:T[], pred:fun(v:T):(boolean)):(T?)
    ---@overload fun(iterable:fun():(T?)):(T?)
    ---@overload fun(iterable:T[]):(T?)
    function Itertools.first(iterable, pred)
        if pred then
            for v in iterable do
                if pred(v) then
                    return v
                end
            end
        else
            for v in iterable do
                if v ~= false then
                    return v
                end
            end
        end
        return nil
    end
end

do
    local ferror = ferror
    local first = Itertools.first

    ---@generic D, T, I
    ---@param iterable I
    ---@param default? std.ConstTpl<D>
    ---@param pred? fun(v:T):(boolean)
    ---@return T|D?
    ---@nodiscard
    ---@overload fun(iterable:I, default:std.ConstTpl<D>, pred:fun(v:T):(boolean)):(T|D)
    ---@overload fun(iterable:I, default:std.ConstTpl<D>):(T|D)
    ---@overload fun(iterable:I, pred:fun(v:T):(boolean)):(T?)
    ---@overload fun(iterable:I):(T?)
    function Itertools.firstOrDefault(iterable, default, pred)
        local out = first(iterable, pred)

        if out == nil then
            if default == nil then
                return ferror("No values found and default was not set", 2)
            else
                return default
            end
        else
            return out
        end
    end
end

return Itertools