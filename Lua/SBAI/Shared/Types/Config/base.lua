---@namespace Config

---@class (partial) Base<J:Json>: Object
---@field public cls Base<J>
---@field public name string
---@field public parse? fun(self, msg:Barotrauma.Networking.IReadMessage)
---@field public serialize? fun(self, msg:Barotrauma.Networking.IWriteMessage)
---@field public get fun(self):(J)
---@field public set fun(self, v?:J)
---@field protected __new fun<S:Base<J>>(self:S, name:string, ...:any):(S)
Types.Config.Base = Types.new--[=[@<Base<J>, Object>]=]("Config.Base", "Object", {
    get = Types.AbstractFunction;
    set = Types.AbstractFunction;
    __tostring = Types.AbstractFunction;
})

local ConfigBase = Types.Config.Base

---@nodiscard
function ConfigBase:__new(name, ...)
    local obj = ConfigBase.super.__new(self, ...) ---@as Base



    obj.name = name
    return obj
end

if Net ~= false then
    ConfigBase.serialize = Types.AbstractFunction
    ConfigBase.parse = Types.AbstractFunction
end

return Types.Config.Base