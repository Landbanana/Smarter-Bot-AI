local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

local IUpdateable = require("SBAI.Shared.Types.IUpdateable")

---@class Regis: IUpdateable
---@field private curState Regis.Registate
local Regis = {}
Regis.__index = Regis

---@class Regis.Registate: IUpdateable
Regis.Registate = {Init=util.None}
Regis.Registate.__index = Regis.Registate

do
    local AllStates = Regis.AllStates
    local Registate = Regis.Registate

    local setmetatable = setmetatable

    ---@public
    ---@param id string
    ---@param update fun(instance:Regis, dt:float)
    ---@param init? fun(instance:Regis, ...)
    ---@return Registate
    function Regis.Registate.new(id, update, init)
        local self = setmetatable({
            Identifier=id,
            Update=update,
            Init=init
        }, Registate)

        AllStates[id] = self

        return self
    end
end

Regis.AllStates = {} --[[@type table<string, Regis.Registate>]]

do
    local CopyTable = util.itertools.CopyTable
    local setmetatable = setmetatable

    ---@public
    ---@param userData? {[any]:any}
    ---@param copy? boolean
    function Regis.new(userData, copy)
        return setmetatable(userData ~= nil and (copy == false and userData or CopyTable(userData)) or {}, Regis)
    end
end

do
    local error = error
    local tostring = tostring

    ---@public
    ---@param id string
    ---@param ... any
    function Regis:UpdateState(id, ...)
        local state = self.AllStates[id]

        if state == nil then error("Unknown Registate ID: "..tostring(id), 2) end

        self.curState = state
        self.Identifier = state.Identifier
        return state.Init(self, ...)
    end
end

do
    local error = error
    local upcall = util.debug.upcall

    ---@public
    ---@param id string
    ---@param ... any
    function Regis:Init(id, ...)
        if self.Identifier ~= nil then error("Regis is already initialized", 2) end

        return upcall(self:UpdateState(id, ...))
    end
end

---@param dt number
function Regis:Update(dt)
    return self.curState.Update(self, dt)
end

return Regis