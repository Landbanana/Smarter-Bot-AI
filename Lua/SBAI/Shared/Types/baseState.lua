---@class BaseState: Object
---@field public cls BaseState
---@field public key string
---@field public enter fun(self)
---@field public exit fun(self)
---@field public update fun(self):(string?)
---@field protected __new fun<S:BaseState>(self:S, key:string, enter?:fun(self:S), update?:fun(self:S), exit?:fun(self:S), ...:any):(S)
Types.BaseState = Types.new("BaseState")

local BaseState = Types.BaseState

BaseState.enter = Functools.devnull
BaseState.exit = Functools.devnull
BaseState.update = Functools.devnull

---@nodiscard
function BaseState:__new(key, enter, update, exit, ...)
    local obj = BaseState.super.__new(self, ...) ---@as BaseState

    obj.key = key
    obj.enter = enter
    obj.exit = exit
    obj.update = update
    return obj
end

return Types.BaseState