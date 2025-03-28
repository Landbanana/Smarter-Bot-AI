local Config = {data={}}
local modConfigsDir = Game.SaveFolder .. "/ModConfigs" --[[@type string]]
local configPath = modConfigsDir .. "/SBAI.json" --[[@type string]]

---@class ConfigName
---@field public name string

---@class BaseConfigOption: ConfigName
---@field public min? number
---@field public max? number

---@class ConfigOption: BaseConfigOption
---@field public default number|boolean|string

---@class ConfigSection: ConfigName
---@field public enable boolean
---@field public options?(ConfigOption|ConfigSection)[]

Config.defaults = {
    MAX_CONDITION_PERCENTAGE = 95,
    MIN_CONDITION_PERCENTAGE = 0,
    MAX_TIME_BETWEEN = 300,
    START_TIME_BETWEEN = 1,
    CONFIG = {}
}

---@param name string
---@param enable boolean
---@param options (ConfigOption|ConfigSection)[]
---@return ConfigSection section
---@overload fun(name:string, enable:boolean):section:ConfigSection
local function MakeSection(name, enable, options)
    return {name=name, enable=enable, options=options}
end

---@param name string
---@param min? number
---@param max? number
---@return BaseConfigOption
---@overload fun(name:string):BaseConfigOption
local function MakeBaseOption(name, min, max)
    return {name=name, min=min, max=max}
end

---@enum BaseOption
local BASEOPTION = {
    minimumCondition={Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE},
    minimumEquippedCondition={Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE},
    timeBetween={0, Config.defaults.MAX_TIME_BETWEEN}
}

for k, v in pairs(BASEOPTION) do
    BASEOPTION[k] = MakeBaseOption(k, v[1], v[2])
end

---@param nameOrBase string|BaseOption
---@param default number|boolean|string
---@param min? number
---@param max? number
---@return ConfigOption
---@overload fun(name:string|BaseOption, default:boolean|string):ConfigOption
local function MakeOption(nameOrBase, default, min, max)
    if type(nameOrBase) ~= "string" then ---@cast nameOrBase BaseConfigOption
        min = nameOrBase.min
        max = nameOrBase.max
        nameOrBase = nameOrBase.name
    end
    
    if (min or max) and (type(default) ~= "number") then error("cannot assign min or max to a "..type(default), 2) end
    return {name=nameOrBase, default=default, min=min, max=max}
end

---@type ConfigSection[]
Config.defaults.CONFIG = {
    MakeSection("EquipArmor", true, {
        MakeOption(BASEOPTION.timeBetween, 30)
    }),
    MakeSection("PreventAttackingHandcuffed", true),
    MakeSection("UseShipDeconstructorIfAvailable", true),
    MakeSection("SmarterLoadItems", true, {
        MakeSection("BatteryCells", true, {
            MakeOption(BASEOPTION.minimumCondition, 90)
        }),
        MakeSection("OxygenTanks", true, {
            MakeOption(BASEOPTION.minimumCondition, 90)
        })
    }),
    MakeSection("ReplenishInventory", true, {
        MakeSection("Idle", true, {
            MakeOption("OnlyAtFriendlyOutposts", false)
        }),
        MakeSection("Wait", true, {
            MakeOption("OnlyAtFriendlyOutposts", true)
        }),
        MakeSection("BatteryCells", true, {
            MakeOption(BASEOPTION.minimumCondition, 75),
            MakeOption(BASEOPTION.minimumEquippedCondition, 10)
        }),
        MakeSection("OxygenTanks", true, {
            MakeOption(BASEOPTION.minimumCondition, 95),
            MakeOption(BASEOPTION.minimumEquippedCondition, 10)
        }),
        MakeOption(BASEOPTION.timeBetween, 30)
    })
}

function Config.Save()
    if Game.IsMultiplayer and CLIENT and Game.Client.MyClient.IsOwner then return end

    File.CreateDirectory(modConfigsDir)
	File.Write(configPath, json.serialize(Config.data))
end

function Config.Load()
    Config.data = (File.Exists(configPath) and json.parse(File.Read(configPath))) or {}

    ---@type fun(option:table, optionDefault:ConfigSection|ConfigOption)
    local function LoadRecurse(option, optionDefault)
        local optionDefaultName = optionDefault.name
        local optionValue = option[optionDefaultName]
        local optionType = type(optionDefault.default)

        if string.lower(optionDefaultName) == "enable" then error("cannot use option name \"enable\"") end

        if optionDefault.default ~= nil then --[[@cast optionDefault -ConfigSection]]
            if optionValue == nil or type(optionValue) ~= optionType then
                option[optionDefaultName] = optionDefault.default
            elseif optionType == "number" then
                option[optionDefaultName] = math.clamp(optionValue, optionDefault.min, optionDefault.max)
            end
        else --[[@cast optionDefault -ConfigOption]]
            if optionValue == nil then
                option[optionDefaultName] = {enable=optionDefault.enable}
            end
            if optionDefault.options ~= nil then
                for _, subOptionDefault in ipairs(optionDefault.options) do
                    LoadRecurse(option[optionDefaultName], subOptionDefault)
                end
            end
        end
    end

    for _, subOptionDefault in ipairs(Config.defaults.CONFIG) do
        LoadRecurse(Config.data, subOptionDefault)
    end
end

Config.Load()
Config.Save()

return Config