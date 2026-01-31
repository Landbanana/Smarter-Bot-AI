---@class Event<F:function>: Object
---@field public cls Event<F>
---@field public add fun(self, f:F)
---@field public call F
---@field public callProtected boolean
---@field public clearOnCall boolean
---@field protected __new fun<S:Event<F>>(self:S, clearOnCall?:boolean, callProtected?:boolean, ...:any):(S)
---@field private _callbacks Deque<F>
---@field private _clearIter fun():(F)
Types.Event = Types.new--[[@<Event<F>>]]("Event", "Object", {

})

local Event = Types.Event

do
    local Deque = Types.Deque

    ---@nodiscard
    function Event:__new(clearOnCall, callProtected, ...)
        local obj = Event.super.__new(...) ---@as Event

        obj.clearOnCall = clearOnCall ~= false
        obj.callProtected = callProtected == true
        obj._callbacks = Deque()
        return obj
    end
end

do
    ---@nodiscard
    function Event:_clearIter()
        return self._callbacks:pop()
    end
end

function Event:add(f)
    return self._callbacks:push(f)
end

do
    local pcall = pcall
    local logError = Errortools.logError

    function Event:call(...)
        local iter ---@[lsp_optimization("delayed_definition")]

        if self._clearIter ~= nil then
            iter = self._clearIter
        else
            iter = self._callbacks
        end

        if self.callProtected then
            for f in iter do
                local success, msg = pcall(f, ...)

                if not success then
                    logError("Shared.Types.Event.Call", ("Error during protected event callback: %s"):format(msg))
                end
            end
        else
            for f in self._callbacks do
                f(...)
            end
        end
    end
end


return Types.Event