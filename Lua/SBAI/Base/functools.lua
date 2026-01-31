---@class Functools
local Functools = {}

---@param ... any
function Functools.devnull(...) end

---@param ... any
---@return true
function Functools.yesMan(...) return true end

do
    local select = select
    local unpack = table.unpack

    ---@generic P
    ---@param nArgs? integer 1
    ---@param f fun(...:P)
    ---@param ... (P...)[]
    function Functools.map(nArgs, f, ...)
        local n = select("#", ...)
        local args = {...}

        if nArgs == nil then nArgs = 1 end

        if nArgs == 1 then
            for i=1,n do
                f(args[i])
            end
        else
            for i=1,n,nArgs do
                f(unpack(args, i, i + nArgs - 1))
            end
        end
    end
end

---@generic A1, P, R
---@param f fun(a1:A1, ...:P)
---@param a1 A1
---@param ... P...
---@return A1
function Functools.dohere(f, a1, ...)
    f(a1, ...)
    return a1
end

---@generic P, R
---@param f fun(...:P...):R...
---@param a2 std.RawGet<Pick<std.Select<(P...),1>,[1]>,1>
---@param a1 std.RawGet<Pick<std.Select<(P...),1>,[0]>,1>
---@param ... Pick<std.Select<(P...),3>,[keyof std.Select<(P...),3>]>...
---@return R...
function Functools.swap12(f, a2, a1, ...)
    return f(a1, a2, ...)
end

-- ---@param viiii1 integer
-- ---@param vooloo2 boolean
-- ---@param vxxxx3 string
-- ---@param vzztt4 table
-- ---@param vnuym5 number
-- ---@return boolean
-- local function testF(viiii1, vooloo2, vxxxx3, vzztt4, vnuym5)
--     print(type(viiii1))
--     print(type(vooloo2))
--     print(type(vxxxx3))
--     print(type(vzztt4))
--     print(type(vnuym5))
--     return viiii1 < vnuym5
-- end

-- local swap12 = Functools.swap12

-- local s = swap12(testF, true, 1, "hi", {}, 5.5)
-- local t = swap12(testF, true, 6, "hg", {}, 3.0)

-- print("s: ", s, "\nt: ", t)

do
    ---@generic R1, R
    ---@param r1 R1
    ---@param ... R...
    ---@return R1, R1, R...
    local function _splitR1(r1, ...)
        return r1, r1, ...
    end

    ---@generic P, R1, R
    ---@param f (fun(...:P):R1, R...)
    ---@param ... P...
    ---@return R1, R1, R...
    function Functools.splitR1(f, ...)
        return _splitR1(f(...))
    end
end

do
    ---@generic V
    ---@param v V
    ---@return V, V
    function Functools.dup(v)
        return v, v
    end
end

---@generic P1, R1, R2
---@param f1 fun(...:P1...):R1
---@param f2 fun(...:R1...):R2
---@return fun(...:P1...):R2
---@nodiscard
function Functools.pipe(f1, f2)
    return function(...)
        return f2(f1(...))
    end
end

---@generic P, R, A1
---@param f fun(a1:A1, ...:P...):(R)
---@param a1 A1
---@return fun(...:P...):(R)
---@nodiscard
function Functools.partial1(f, a1)
    return function(...)
        return f(a1, ...)
    end
end

---@generic P, R, A1, A2
---@param f fun(a1:A1, a2:A2, ...:P...):(R)
---@param a1 A1
---@param a2 A2
---@return fun(...:P...):(R)
---@nodiscard
function Functools.partial2(f, a1, a2)
    return function(...)
        return f(a1, a2, ...)
    end
end

---@generic P, R, A1, A2, A3
---@param f fun(a1:A1, a2:A2, a3:A3, ...:P...):(R)
---@param a1 A1
---@param a2 A2
---@param a3 A3
---@return fun(...:P...):(R)
---@nodiscard
function Functools.partial3(f, a1, a2, a3)
    return function(...)
        return f(a1, a2, a3, ...)
    end
end

---@generic P, R, A1, A2, A3, A4
---@param f fun(a1:A1, a2:A2, a3:A3, a4:A4, ...:P...):(R)
---@param a1 A1
---@param a2 A2
---@param a3 A3
---@param a4 A4
---@return fun(...:P...):(R)
---@nodiscard
function Functools.partial4(f, a1, a2, a3, a4)
    return function(...)
        return f(a1, a2, a3, a4, ...)
    end
end

---@generic P, R, A1, A2, A3, A4, A5
---@param f fun(a1:A1, a2:A2, a3:A3, a4:A4, a5:A5, ...:P...):(R)
---@param a1 A1
---@param a2 A2
---@param a3 A3
---@param a4 A4
---@param a5 A5
---@return fun(...:P...):(R)
---@nodiscard
function Functools.partial5(f, a1, a2, a3, a4, a5)
    return function(...)
        return f(a1, a2, a3, a4, a5, ...)
    end
end

do
    local recurse do
        local unpack = table.unpack

        ---@generic P, R
        ---@param f fun(...:P...):R
        ---@param args [P...]
        ---@param n integer
        ---@param i integer
        ---@param v any
        ---@param ... any
        ---@return R
        recurse = function(f, args, n, i, v, ...)
            if i <= n then
                args[i] = v
                return recurse(f, args, n, i + 1, ...)
            else
                return f(unpack(args, 1, n))
            end
        end
    end

    local select = select
    local unpack = table.unpack

    ---@generic S, U, R
    ---@param f fun(s:S..., u:U...):R...
    ---@param ... S...
    ---@return fun(u:U...):R...
    ---@nodiscard
    function Functools.partialN(f, ...)
        local args = {...}
        local n = select("#", ...)

        return function(...)
            return recurse(f, {unpack(args, 1, n)}, n + select("#", ...), n + 1, ...)
        end
    end
end

do
    local Cache = Types.Cache

    ---@generic K, R
    ---@param f fun(k:K):(R)
    ---@return fun(k:K):(R)
    ---@return Cache<K,R>
    ---@nodiscard
    function Functools.memoize(f)
        local cache = Cache(f)

        return cache.cachedFunction, cache
    end
end

do
    local keyedCache do
        local function reset(t, k)
            t[k] = nil
        end

        local setmetatable = setmetatable
        local partial2 = Functools.partial2

        keyedCache = setmetatable({}, {
            __index=function(c1, t)
                local out1 = setmetatable({}, {
                    __index=function(c2, a1)
                        local out2 = partial2(reset, t, a1)

                        c2[a1] = out2
                        return out2
                    end
                })

                c1[t] = out1
                return out1
            end
        })
    end



    local wait = Types.SlowTimer.wait ---@[lsp_optimization("delayed_definition")]


    local keySet_mt = {}

    keySet_mt.__index=function(t, k)
        t[k] = true
        return wait(keyedCache[t][k], t[keySet_mt])
    end

    local setmetatable = setmetatable

    ---@generic A1, P
    ---@param f fun(a1:A1, ...:P...)
    ---@param delay integer
    ---@param keyOnArg1 boolean
    ---@return fun(a1:A1, ...:P...)
    ---@nodiscard
    function Functools.debounce(f, delay, keyOnArg1)
        if keyOnArg1 then
            local keySet = setmetatable({[keySet_mt]=delay}, keySet_mt)

            return function(a1, ...)
                if not keySet[a1] then
                    return f(a1, ...)
                end
            end
        else
            local isBlocked = false

            local function unblocker()
                isBlocked = false
            end

            return function(a1, ...)
                if not isBlocked then
                    isBlocked = true
                    wait(unblocker, delay)
                    return f(a1, ...)
                end
            end
        end
    end
end

return Functools