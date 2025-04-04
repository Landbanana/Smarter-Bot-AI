local Config = {data={}}
local modConfigsDir = Game.SaveFolder .. "/ModConfigs" --[[@type string]]
local configPath = modConfigsDir .. "/SBAI.json" --[[@type string]]

---@class ConfigName
---@field public name string
---@field public description? string

---@class BaseConfigOption: ConfigName
---@field public min? number
---@field public max? number

---@class ConfigOption: BaseConfigOption
---@field public default number|boolean|string
---@field public optionType OptionType

---@class ConfigSection: ConfigName
---@field public enable boolean
---@field public options?(ConfigOption|ConfigSection)[]

---@enum OptionType
Config.OPTION_TYPE = {
    string="string",
    int="int",
    float="float",
    boolean="boolean"
}

Config.defaults = {
    MAX_CONDITION_PERCENTAGE = 95,
    MIN_CONDITION_PERCENTAGE = 0,
    MAX_TIME_BETWEEN = 300,
    START_TIME_BETWEEN = 1,
    CONFIG = {}
}

---@param name string
---@param enable boolean
---@param description? string
---@param options (ConfigOption|ConfigSection)[]
---@return ConfigSection section
---@overload fun(name:string, enable:boolean, description: string):section:ConfigSection
local function MakeSection(name, enable, description, options)
    return {name=name, enable=enable, description=description, options=options}
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
---@param optionType OptionType
---@param description? string
---@param min? number
---@param max? number
---@return ConfigOption
---@overload fun(name:string|BaseOption, default:boolean|string, optionType:OptionType, description:string):ConfigOption
local function MakeOption(nameOrBase, default, optionType, description, min, max)
    if type(nameOrBase) ~= Config.OPTION_TYPE.string then ---@cast nameOrBase BaseConfigOption
        min = nameOrBase.min
        max = nameOrBase.max
        nameOrBase = nameOrBase.name
    end
    
    if (min or max) and (optionType ~= Config.OPTION_TYPE.float and optionType ~= Config.OPTION_TYPE.int) then error("cannot assign min or max to a "..optionType, 2) end
    return {name=nameOrBase, default=default, optionType=optionType, description=description, min=min, max=max}
end

---@return ConfigSection[]
local function getData()
    ---@type ConfigSection[]
    return {
        MakeSection("EquipArmor", true, "AI will attempt to equip armor inside their inventory every so often. This helps solve the issue of AI sometimes \"forgetting\" to put a helmet back on after using a diving mask, for example", {
            MakeOption(BASEOPTION.timeBetween, 30, Config.OPTION_TYPE.int, "Increases the delay between AI attempting to equip armor. Lower=faster, but it really doesn't need to be low at all")
        }),
        MakeSection("PreventAttackingHandcuffed", true, "AI will no longer attack anyone who's handcuffed, both in regard to ship weapons and attacking intruders. Helps with getting ransoms"),
        MakeSection("UseShipDeconstructorIfAvailable", true, "If a ship has a deconstructor, the AI can ONLY use that in all circumstances. Prevents them going into a hostile outpost to deconstruct or other funny shenanigans"),
        MakeSection("SmarterLoadItems", true, "AI set to load these items will bring full ones to the empty tool/container first, replacing them in the slot, rather than just emptying the partially depleted ones and leaving your artifact case without a battery", {
            MakeSection("BatteryCells", true, "Apply this setting to AI loading battery cells", {
                MakeOption(BASEOPTION.minimumCondition, 90, Config.OPTION_TYPE.float, "Minimum condition before AI ordered to load batteries will replace batteries")
            }),
            MakeSection("OxygenTanks", true, "Apply this setting to AI loading oxygen tanks",{
                MakeOption(BASEOPTION.minimumCondition, 90, Config.OPTION_TYPE.float, "Minimum condition before AI ordered to load oxygen tanks will replace oxygen tanks")
            })
        }),
        MakeSection("ReplenishInventory", true, "AI will refill some of their empty reloadables while idling/waiting", {
            MakeSection("Idle", true, "Allow an AI that has no active order to occasionally leave their post to refill their inventory", {
                MakeOption("OnlyAtFriendlyOutposts", false, Config.OPTION_TYPE.boolean, "AI will only replenish when docked at an outpost while idling")
            }),
            MakeSection("Wait", true, "Allow an AI that is set to the \"wait\" order to occasionally leave their post to refill their inventory", {
                MakeOption("OnlyAtFriendlyOutposts", true, Config.OPTION_TYPE.boolean, "AI will only replenish when docked at an outpost while set to wait (THEY WILL BRIEFLY LEAVE THEIR POST)")
            }),
            MakeSection("BatteryCells", true, "Let the AI replenish their battery cells", {
                MakeOption(BASEOPTION.minimumCondition, 75, Config.OPTION_TYPE.float, "Minimum condition of batteries in an idling/waiting AI's inventory (not equipped) before replacing them"),
                MakeOption(BASEOPTION.minimumEquippedCondition, 10, Config.OPTION_TYPE.float, "Minimum condition of batteries equipped by an idling/waiting AI before replacing them")
            }),
            MakeSection("OxygenTanks", true, "Let the AI replenish their oxygen tanks", {
                MakeOption(BASEOPTION.minimumCondition, 95, Config.OPTION_TYPE.float, "Minimum condition of oxygen tanks in an idling/waiting AI's inventory (not equipped) before replacing them"),
                MakeOption(BASEOPTION.minimumEquippedCondition, 10, Config.OPTION_TYPE.float, "Minimum condition of oxygen tanks equipped by an idling/waiting AI before replacing them")
            })-- ,
            -- MakeOption(BASEOPTION.timeBetween, 30, Config.OPTION_TYPE.int, "Increases the delay between AI attempting to replenish their inventory. Lower=faster, but it really doesn't need to be low at all")
        })
    }
end

Config.defaults = setmetatable(Config.defaults, {
    __call=function() return getData() end
})


---@param optionString string
---@param value OptionType
---@overload fun(optionList:Namespace, value:OptionType)
function Config.Set(optionString, value)
    if type(optionString) == "table" then
        Config.Get(-optionString)[optionString.stack[#optionString.stack]] = value
        return
    end

    local preOptionString, subOptionString = string.match(optionString, "(.+[^%.]+)%.([^%.]+)$")

    Config.Get(preOptionString)[subOptionString] = value
end

---@param optionString string
---@return OptionType
---@overload fun(optionList:Namespace)
function Config.Get(optionString)
    local config = Config.data

    if type(optionString) == "string" then
        for sub in string.gmatch(optionString, "([^%.]+)") do
            config = config[sub]
        end
    else
        for sub in optionString.stack do
            config = config[sub]
        end
    end

    return config
end

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

        if optionDefaultName:lower() == "enable" then error("cannot use option name \"enable\"") end

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

    for _, subOptionDefault in ipairs(Config.defaults()) do
        LoadRecurse(Config.data, subOptionDefault)
    end
end

Config.Load()
Config.Save()

return Config