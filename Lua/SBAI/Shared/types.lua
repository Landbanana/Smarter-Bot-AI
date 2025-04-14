local Constants = require("SBAI.Shared.constants")

local Types = {}

---@class Types.Timer
---@field private time number
---@field private delay number
---@field private noise number
---@field public new fun(self:Types.Timer, delay:number, noise:number):Types.Timer
---@field public Update fun(self:Types.Timer, deltaTime:number):boolean
---@field public Reset fun(self:Types.Timer)
Types.Timer = {}

function Types.Timer:new(delay, noise)
    local t = {
        delay=delay,
        noise=noise or Constants.D_TIMER_NOISE
    }
    setmetatable(t, self)
    self.__index = self

    t:Reset()
    return t
end

do
    local random = math.random

    function Types.Timer:Reset()
        self.time = self.delay*(1 + self.noise*(2*random() - 1))
    end
end

function Types.Timer:Update(deltaTime)
    self.time = self.time - deltaTime
    if self.time <= 0 then
        self:Reset()
        return true
    end
    return false
end

return Types

---@class Barotrauma.Item
---@field public GetComponent fun(componentType:Barotrauma.Item.T):Barotrauma.Item.T