---@class Cotools
local Cotools = {}

---@alias Yield fun(...:any):(any...)

do
    local wrap = coroutine.wrap
    local yield = coroutine.yield

    ---@generic F:function
    ---@param f fun(yield:Yield, co?:F):co:F
    ---@return F
    ---@nodiscard
    function Cotools.wrap(f)
        local co = wrap(f)
        co(yield, co)
        return co
    end
end


do
    local pool = {}

    local wrap = coroutine.wrap

    ---@generic P, R
    ---@param id string
    ---@param f fun(...:P):(R)
    function Cotools.reuse(id, f)
        local co

        pool[id] = wrap(f)
        
        return function(reset, ...)
            if co == nil then
                co = pool[id]
                pool[id] = nil
                return co(reset, ...)
            elseif reset == true then
                co(reset)
                pool[id] = co
                co = nil
            else
                return co()
            end
        end

    end
end





return Cotools