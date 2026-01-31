---@namespace Config

---@class (partial) OptionBool: Option<boolean>
---@field public cls OptionBool
---@field public super Option<boolean>
---@field protected __new fun<S:OptionBool>(self:S, name:string, default:boolean, ...:any):(S)
Types.Config.OptionBool = Types.new--[=[@<OptionBool, Option<boolean>>]=]("Config.OptionBool", "Config.Option")

local ConfigOptionBool = Types.Config.OptionBool

---@nodiscard
function ConfigOptionBool:__new(name, default, ...)
    return ConfigOptionBool.super.__new(self, name, default ~= false) ---@as OptionBool
end

---@protected
---@param v? any
---@return boolean
---@nodiscard
function ConfigOptionBool:_validate(v)
    if v then
        return true
    else
        return false
    end
end

if Net ~= false then
    ConfigOptionBool._serialType = "Boolean"
end

return Types.Config.OptionBool