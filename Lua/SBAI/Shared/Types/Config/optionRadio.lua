---@namespace Config

---@class (partial) OptionRadio: OptionInt
---@field public cls OptionRadio
---@field public super OptionInt
---@field public options string[]
Types.Config.OptionRadio = Types.new("Config.OptionRadio", "Config.OptionInt" , {
    options = Types.Desc.Property(nil, Types.Desc.Property.getT,
    ---@param cls OptionRadio
    ---@param obj OptionRadio
    function(self, cls, obj, v)
        obj.max = #v
        return self:setT(cls, obj, v)
    end)
})

local ConfigOptionRadio = Types.Config.OptionRadio

do
    local _max = math.max

    ---@public
    ---@param name string
    ---@param default? integer
    ---@param options string[]
    ---@param ... any
    ---@return OptionRadio
    ---@nodiscard
    function ConfigOptionRadio:__new(name, default, options, ...)
        local obj = ConfigOptionRadio.super.__new(self, name, _max(1, default), 1, #options, ...) ---@as OptionRadio

        obj.options = options
        return obj
    end
end

if Net ~= false then
    ConfigOptionRadio.serialType = "RangedInteger"
end

return Types.Config.OptionRadio