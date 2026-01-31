---@class Semaphore: Object
---@operator len:integer
---@field public cls Semaphore
---@field public fQ Deque<fun()>
---@field public i integer
---@field public isBlocking boolean
---@field public isQEmpty boolean
---@field package bound integer
Types.Semaphore = Types.new("Semaphore", nil, {
    isBlocking = Types.Desc.TiedConstant(
    ---@param cls Semaphore
    ---@param obj Semaphore
    function(self, cls, obj)
        return obj.i <= 0
    end);
    isQEmpty = Types.Desc.TiedConstant(
    ---@param cls Semaphore
    ---@param obj Semaphore
    function(self, cls, obj)
        return obj.fQ.isEmpty
    end);
})

local Semaphore = Types.Semaphore

do
    local Deque = Types.Deque
    local huge = math.huge ---@as integer

    ---@public
    ---@param bound? integer
    ---@param ... any
    ---@nodiscard
    function Semaphore:__new(bound, ...)
        local obj = Semaphore.super.__new(self, ...) ---@as Semaphore
        
        bound = (bound ~= nil and bound >= 0) and bound or huge

        obj.i = bound
        obj.bound = bound
        obj.fQ = Deque()
        return obj
    end
end

do
    local select = select
    local unpack = table.unpack

    ---@public
    ---@generic P
    ---@param blocking? boolean|true
    ---@param f? fun(...:P...)
    ---@param ... P
    ---@return boolean
    function Semaphore:acquire(blocking, f, ...)
        local i = self.i
        
        if i > 0 then
            self.i = i - 1
            if f ~= nil then
                f(...)
            end
            return true
        else
            if f ~= nil then
                if blocking ~= false then
                    local n = select("#", ...)

                    if n <= 0 then
                        self.fQ:push(f)
                    else
                        local args = {...}

                        self.fQ:push(function()
                            return f(unpack(args, 1, n))
                        end)
                    end
                end
            end
            return false
        end
    end
end

do
    ---@public
    function Semaphore:clear()
        self.fQ:clear()
        return self
    end
end

---@private
---@return integer
---@nodiscard
function Semaphore:__len()
    return self.i
end

do
    local min = math.min

    ---@public
    ---@param n? integer|1
    function Semaphore:release(n)
        local fQ = self.fQ
        local i = self.i
        local j = min(self.bound, n or 1)

        for _=1,j do
            local f = fQ:popL()

            i = i + 1
            if f ~= nil then
                f()
            end
        end
        self.i = i
    end
end
return Types.Semaphore