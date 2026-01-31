---@namespace Config

---@class (partial) SectionMajor: SectionToggle
---@operator div(Base[]):SectionMajor
---@field public cls SectionMajor
---@field public super SectionToggle
Types.Config.SectionMajor = Types.new("Config.SectionMajor", "Config.SectionToggle")

local ConfigSectionMajor = Types.Config.SectionMajor

---@return Config.SectionMajor
---@nodiscard
function ConfigSectionMajor:__new(name, enable, ...)
    return ConfigSectionMajor.super.__new(self, name, enable, ...)
end



return Types.Config.SectionMajor