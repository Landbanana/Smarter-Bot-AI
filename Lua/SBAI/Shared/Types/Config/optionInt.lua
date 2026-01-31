---@namespace Config

---@class (partial) OptionInt: OptionFloat
---@field public cls OptionInt
---@field public super OptionFloat
---@field public min integer
---@field public max integer
---@field protected __new fun<S:OptionInt>(self:S, name:string, default?:integer, min?:integer, max?:integer, ...:any):(S)
Types.Config.OptionInt = Types.new("Config.OptionInt", "Config.OptionFloat")

local ConfigOptionInt = Types.Config.OptionInt

do
    local tointeger = Mathtools.tointeger

    ---@protected
    ---@param v? any
    ---@return integer?
    ---@nodiscard
    function ConfigOptionInt:_validate(v)
        return tointeger(ConfigOptionInt.super._validate(self, v))
    end

end

if Net ~= false then
    do
        local matchInt = (Types.Match() --[=[@as Match<integer,string>]=])
            :case(1, "RangedInteger")
            :case(2, "UInt32")
            :case(3, "UInt64")

        local abs = math.abs
        local _max = math.max

        rawset(Types.Config.OptionInt, "__new",
        ---@nodiscard
        function(self, name, default, min, max, ...)
            local obj = ConfigOptionInt.super.__new(self, name, default, min, max, ...)
            local _serialType = obj._serialType


            if _serialType == nil then
                min, max = obj.min, obj.max

                if (min >= (-2^31)) and (max <= (2^31 - 1)) then
                    _serialType = "RangedInteger"
                elseif min >= 0 then
                    for i=1,3 do

                        if max <= (2^31)*(2^((33 + (i % 3)) % 34)) - 1 then
                           _serialType = matchInt:eval(i)
                            break
                        end
                    end
                end
                obj._serialType = _serialType or "Double" and ((_max(abs(min), max) > ((2-(2^-23))*(2^127))))
            end
            return obj
        end)
    end

    do
        function ConfigOptionInt:parse(msg)
            local _serialType = self._serialType
            local f = msg["Read".._serialType]

            if _serialType == "RangedInteger" --[=[@as boolean]=] then
                return self:set(f(self.min, self.max))
            else
                return self:set(f())
            end
        end
    end

    do
        function ConfigOptionInt:serialize(msg)
            local _serialType = self._serialType
            local f = msg["Write".._serialType]

            if _serialType == "RangedInteger" --[=[@as boolean]=] then
                return f(self:get(), self.min, self.max)
            else
                return f(self:get())
            end
        end
    end
end

return Types.Config.OptionInt