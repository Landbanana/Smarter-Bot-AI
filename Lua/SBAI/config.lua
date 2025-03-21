local config = {data = {}} --[[@type table]]
local modConfigsDir = Game.SaveFolder .. "/ModConfigs" --[[@type string]]
local configPath = modConfigsDir .. "/SBAI.json" --[[@type string]]

---@class ConfigName
---@field public name string

---@class ConfigOption: ConfigName
---@field public default any
---@field public min number?
---@field public max number?

---@class ConfigSection: ConfigName
---@field public enabled boolean
---@field public options ConfigOption[]?

---@type fun(name:string, enabled:boolean, options:(ConfigOption|ConfigSection)[]?):ConfigSection
local function MakeSection(name, enabled, options)
    return {name=name, enabled=enabled, options=options}
end

---@type fun(name:string, default:any, min:number?, max:number?):ConfigOption
local function MakeOption(name, default, min, max)
    if (min or max) and type(default) ~= "number" then error("cannot assign min or max to a "..type(default)) end
    return {name=name, default=default, min=min, max=max}
end

---@type ConfigSection[]
local defaultConfig = {
    MakeSection("PreventAttackingHandcuffed", true),
    MakeSection("UseShipDeconstructorIfAvailable", true),
    MakeSection("ReplaceOxygenTanks", true, {
        MakeOption("minimumCondition", 90.0, 0.0, 100.0)
    }),
    MakeSection("ReplaceBatteryCells", true, {
        MakeOption("minimumCondition", 90.0, 0.0, 100.0)
    })
}

---@type fun()
function config.Save()
    if Game.IsMultiplayer and CLIENT and Game.Client.MyClient.IsOwner then return end

    File.CreateDirectory(modConfigsDir)
	File.Write(configPath, json.serialize(config.data))
end

---@type fun()
function config.Load()
    config.data = (File.Exists(configPath) and json.parse(File.Read(configPath))) or {}

    ---@type fun(option:table, optionDefault:ConfigSection|ConfigOption)
    local function LoadRecurse(option, optionDefault)
        local optionDefaultName = optionDefault.name
        local optionValue = option[optionDefaultName]
        local optionType = type(optionDefault.default)

        if string.lower(optionDefaultName) == "enabled" then error("cannot use option name \"enabled\"") end

        if optionDefault.default ~= nil then --[[@cast optionDefault -ConfigSection]]
            if optionValue == nil or type(optionValue) ~= optionType then
                option[optionDefaultName] = optionDefault.default
            elseif optionType == "number" then
                option[optionDefaultName] = math.clamp(optionValue, optionDefault.min, optionDefault.max)
            end
        else --[[@cast optionDefault -ConfigOption]]
            if optionValue == nil then
                option[optionDefaultName] = {enabled=optionDefault.enabled}
            end
            if optionDefault.options ~= nil then
                for _, subOptionDefault in ipairs(optionDefault.options) do
                    LoadRecurse(option[optionDefaultName], subOptionDefault)
                end
            end
        end
    end

    for _, subOptionDefault in ipairs(defaultConfig) do
        LoadRecurse(config.data, subOptionDefault)
    end
end

config.Load()
config.Save()

return config