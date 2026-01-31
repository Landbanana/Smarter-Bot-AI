---@namespace Config

---@class (partial) SectionToggle: Section
---@operator div(Base[]):SectionToggle
---@field public cls SectionToggle
---@field public super Section
---@field public enable OptionBool
---@field public isEnabled boolean
---@field public [integer] Base
Types.Config.SectionToggle = Types.new("Config.SectionToggle", "Config.Section", {
    isEnabled = Types.Desc.Property--[[@as Desc.Property<SectionToggle>]](nil,

    function(self, cls, obj)
        return obj.enable:get()
    end,
    ---@param v boolean
    function(self, cls, obj, v)
        obj.enable:set(v)
    end)
})

local ConfigSectionToggle = Types.Config.SectionToggle

do
    local OptionBool = Types.Config.OptionBool

    ---@public
    ---@param name string
    ---@param enable? boolean
    ---@param ... any
    ---@return SectionToggle
    ---@nodiscard
    function ConfigSectionToggle:__new(name, enable, ...)
        local obj = ConfigSectionToggle.super.__new(self, name, ...) ---@as SectionToggle

        obj.enable = OptionBool("enable", enable)
        obj[1] = "enable"
        return obj
    end
end

do
    local insert = table.insert

    function ConfigSectionToggle:__div(t)
        insert(t, 1, self.enable)
        --t.enable = self.enable
        return ConfigSectionToggle.super.__div(self, t)
    end
end


if Net ~= false then
    -- do
    --     function ConfigSectionToggle:parse(msg)
    --         self:set("enable", msg.ReadBoolean() == true)
    --         return ConfigSectionToggle.super.parse(self, msg)
    --     end
    -- end

    -- do
    --     function ConfigSectionToggle:serialize(msg)
    --         msg.WriteBoolean(self:get("enable"))
    --         return ConfigSectionToggle.super.serialize(self, msg)
    --     end
    -- end
end

return Types.Config.SectionToggle