---@class StateMachine<D>: Object
---@field cls StateMachine<D>
---@field public curState BaseState
---@field public curStateKey keyof D
---@field public isStarted boolean
---@field public stateDict D
---@field public doUpdate fun()
---@field public set fun(self, nextStateKey:keyof D)
---@field public start fun(self, initStateKey?:string):(bool)
---@field protected _nextStateKey keyof D
---@field package initStateKey keyof D
---@field package isTransitioning boolean
Types.StateMachine = Types.new --[=[@<StateMachine<D>, Object>]=]("StateMachine", "Object", {
    curStateKey = Types.Desc.TiedConstant(
    ---@param cls StateMachine
    ---@param obj StateMachine
    function(self, cls, obj)
        return obj.curState.key
    end);
    initStateKey = Types.Desc.Readonly();
    stateDict = Types.Desc.Readonly();
    isStarted = false;
    isTransitioning = false;
    _nextStateKey = false;
})

local StateMachine = Types.StateMachine

do
    local partial1 = Functools.partial1

    ---@generic D
    ---@param stateDict D
    ---@param initStateKey keyof D
    ---@param ... any
    function StateMachine:__new(stateDict, initStateKey, ...)
        local obj = StateMachine.super.__new(self, ...) ---@as StateMachine<D>

        obj.doUpdate = partial1(obj.update, obj)
        obj.stateDict = stateDict
        obj.initStateKey = initStateKey
        return obj
    end
end


function StateMachine:start(initStateKey)

    if not self.isStarted then
        self.isStarted = true
        self.curState = self.stateDict[initStateKey or self.initStateKey]
        self.curState:enter()
        return true
    else
        return false
    end
end

---@public
---@return boolean
function StateMachine:stop()
    if self.isStarted then
        self.isStarted = nil
        self.curState = nil
        self._nextStateKey = false
        self.isTransitioning = nil
        return true
    else
        return false
    end
end

---@public
function StateMachine:update()
    if self.isTransitioning or not self.isStarted then return end
    local curState = self.curState
    local _nextStateKey = self._nextStateKey

    if _nextStateKey == false then
        local newNextStateKey = curState:update()

        if newNextStateKey then
            self._nextStateKey = newNextStateKey
        end

    else
        print(curState.key.."->")
        self.isTransitioning = true
        curState:exit()
        print(_nextStateKey, "????")
        self.curState = self.stateDict[_nextStateKey]
        self.curState:enter()
        print("\t->".._nextStateKey)
        self.isTransitioning = false
    end
end

-- do
--     local nextFrame = Types.SlowTimer.nextFrame
--     local partial1 = Functools.partial1

--     function StateMachine:deferUpdate()
--         if self.isStarted then
--             return self._deferUpdate()
--         end
--     end
-- end

-- function StateMachine:set(nextStateKey)
--     self._nextStateKey = nextStateKey
-- end

-- ---@public
-- function StateMachine:enter()
--     return self.curState:enter()
-- end

-- ---@public
-- function StateMachine:exit()
--     return self.curState:exit()
-- end

return Types.StateMachine