---@namespace Config

---@class (partial) OptionFloat: Option<number>
---@field public cls OptionFloat
---@field public super Option<number>
---@field public min number
---@field public max number
---@field protected __new fun<S:OptionFloat>(self:S, name:string, default?:number, min?:number, max?:number, ...:any):(S)
Types.Config.OptionFloat = Types.new--[[@<OptionFloat, Option<number>>]]("Config.OptionFloat", "Config.Option", {
    min = (-math.huge);
    max = math.huge
})

local ConfigOptionFloat = Types.Config.OptionFloat

do
    local ferror = Errortools.ferror

    ---@nodiscard
    function ConfigOptionFloat:__new(name, default, min, max, ...)
        local obj = ConfigOptionFloat.super.__new(self, name, default, ...) ---@as OptionFloat

        obj.min = obj:_validate(min)
        obj.max = obj:_validate(max)

        if min > max then
            return ferror("'min' (%f) is greater than 'max' (%f)", 2, min, max)
        else
            return obj
        end
    end
end

do
    local clamp = Mathtools.clamp
    local tonumber = tonumber

    ---@protected
    ---@param v? any
    ---@return number?
    ---@nodiscard
    function ConfigOptionFloat:_validate(v)
        v = tonumber(v)
        if v == nil then
            return nil
        else
            return clamp(v, self.min, self.max)
        end
    end
end

if Net ~= false then
    ConfigOptionFloat._serialType = "Single"
    do
        local abs = math.abs
        local _max = math.max
        local __new = ConfigOptionFloat.__new

        rawset(Types.Config.OptionFloat, "__new",
        ---@param name string
        ---@param default integer
        ---@param min? integer
        ---@param max? integer
        ---@param ... any
        ---@return OptionFloat
        ---@nodiscard
        function(self, name, default, min, max, ...)
            local obj = __new(self, name, default, min, max, ...)

            if (_max(abs(obj.min), obj.max) > ((2-(2^-23))*(2^127))) then obj._serialType = "Double" end
            return obj ---@as Config.OptionFloat
        end)
    end
end

return Types.Config.OptionFloat