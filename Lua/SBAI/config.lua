local Config = {data={}}
local modConfigsDir = Game.SaveFolder.."/ModConfigs" --[[@type string]]
local configPath = modConfigsDir.."/SBAI.json" --[[@type string]]

---@class ConfigOption
---@field public value string|boolean|number
---@field public optionType string|boolean|number
---@field public description string
---@field public min? number
---@field public max? number
---@field public new fun(self:ConfigOption, default:string|boolean|number, optionType:Config.OPTION_TYPE, description:string, min:number?, max:number?):ConfigOption
---@field public Set fun(self:ConfigOption, value:string|boolean|number)

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

local ConfigOption = {}

---@param self ConfigOption
---@param default string|boolean|number
---@param optionType Config.OPTION_TYPE
---@param description string
---@param min? number
---@param max? number
---@return ConfigOption
function ConfigOption:new(default, optionType, description, min, max)
    local t = setmetatable({}, self)
    self.__index = self

    t.optionType = optionType
    t.description = description
    t.min = min
    t.max = max
    t:Set(default)
    return t
end

do
    local clamp = math.clamp

    ---@param self ConfigOption
    ---@param value string|boolean|number
    function ConfigOption:Set(value)
        local optionType = type(value)

        if optionType == "number" and self.optionType == "float" or self.optionType == "int" then
            self.value = clamp(value, self.min, self.max)
        elseif optionType ~= self.optionType then
            error("incorrect option type provided (should be a "..self.optionType.." not a "..optionType..")", 2)
        else
            self.value = value
        end
    end
end

---@class ConfigSection
---@field public description string
---@field public new fun(self:ConfigSection, description:string):ConfigSection
---@field public CreateOption fun(self:ConfigSection, name:string, default:string|boolean|number, optionType:Config.OPTION_TYPE, description:string, min:number?, max:number?):ConfigOption
---@field public CreateSection fun(self:ConfigSection, name:string, description:string?):ConfigSection
---@field public Flatten fun(self:ConfigSection):table

local ConfigSection = {}

---@param description? string
---@return ConfigSection
function ConfigSection:new(description)
    local t = setmetatable({}, self)
    self.__index = self

    if description then t:CreateOption("enable", true, "boolean", description) end
    return t
end

---@param self ConfigSection
---@param name string
---@param default string|boolean|number
---@param optionType Config.OPTION_TYPE
---@param description string
---@param min? number
---@param max? number
---@return ConfigOption
function ConfigSection:CreateOption(name, default, optionType, description, min, max)
    self[name] = ConfigOption:new(default, optionType, description, min, max)
    return self[name]
end

---@param self ConfigSection
---@param name string
---@param description string
---@return ConfigSection
function ConfigSection:CreateSection(name, description)
    self[name] = ConfigSection:new(description)
    return self[name]
end

---@param self ConfigSection
---@return table
function ConfigSection:Flatten()
    local t = {}

    for k, v in pairs(self) do
        if type(v.Set) == "function" then
            t[k] = v.value
        else
            t[k] = v:Flatten()
        end
    end
    return t
end


do
    local defaults = ConfigSection:new()
    local section = defaults:CreateSection("EquipArmor", "AI will attempt to equip armor inside their inventory every so often. This helps solve the issue of AI sometimes \"forgetting\" to put a helmet back on after using a diving mask, for example")
    section:CreateOption("timeBetween", 30, Config.OPTION_TYPE.int, "Increases the delay between AI attempting to equip armor. Lower=faster, but it really doesn't need to be low at all", 0, Config.defaults.MAX_TIME_BETWEEN)

    defaults:CreateSection("PreventAttackingHandcuffed", "AI will no longer attack anyone who's handcuffed, both in regard to ship weapons and attacking intruders. Helps with getting ransoms")
    defaults:CreateSection("UseShipDeconstructorIfAvailable", "If a ship has a deconstructor, the AI can ONLY use that in all circumstances. Prevents them going into a hostile outpost to deconstruct or other funny shenanigans")

    section = defaults:CreateSection("SmarterLoadItems", "AI set to load these items will bring full ones to the empty tool/container first, replacing them in the slot, rather than just emptying the partially depleted ones and leaving your artifact case without a battery")

    local subsection = section:CreateSection("BatteryCells", "Apply this setting to AI loading battery cells")
    subsection:CreateOption("minimumCondition", 90, Config.OPTION_TYPE.float, "Minimum condition before AI ordered to load batteries will replace batteries", Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("OxygenTanks", "Apply this setting to AI loading oxygen tanks")
    subsection:CreateOption("minimumCondition", 90, Config.OPTION_TYPE.float, "Minimum condition before AI ordered to load oxygen tanks will replace oxygen tanks", Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    section = defaults:CreateSection("ReplenishInventory", "AI will refill some of their empty reloadables while idling/waiting")
    subsection = section:CreateSection("Idle", "Allow an AI that has no active order to occasionally leave their post to refill their inventory")
    subsection:CreateOption("OnlyAtFriendlyOutposts", false, Config.OPTION_TYPE.boolean, "AI will only replenish when docked at an outpost while idling")

    subsection = section:CreateSection("Wait", "Allow an AI that is set to the \"wait\" order to occasionally leave their post to refill their inventory")
    subsection:CreateOption("OnlyAtFriendlyOutposts", true, Config.OPTION_TYPE.boolean, "AI will only replenish when docked at an outpost while set to wait (THEY WILL BRIEFLY LEAVE THEIR POST)")

    subsection = section:CreateSection("BatteryCells", "Let the AI replenish their battery cells")
    subsection:CreateOption("minimumCondition", 75, Config.OPTION_TYPE.float, "Minimum condition of batteries in an idling/waiting AI's inventory (not equipped) before replacing them", Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, Config.OPTION_TYPE.float, "Minimum condition of batteries equipped by an idling/waiting AI before replacing them", Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("OxygenTanks", "Let the AI replenish their oxygen tanks")
    subsection:CreateOption("minimumCondition", 95, Config.OPTION_TYPE.float, "Minimum condition of oxygen tanks in an idling/waiting AI's inventory (not equipped) before replacing them", Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, Config.OPTION_TYPE.float, "Minimum condition of oxygen tanks equipped by an idling/waiting AI before replacing them", Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    section:CreateOption("timeBetween", 30, Config.OPTION_TYPE.int, "Increases the delay between AI attempting to replenish their inventory. Lower=faster, but it really doesn't need to be low at all", 0, Config.defaults.MAX_TIME_BETWEEN)

    defaults:CreateSection("IdleUseBed", "Bots will use the bed when they idle, just like chairs (NOTE: Takes effect after the round ends)")

    Config.defaults.CONFIG = defaults
end

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
    Config.data = File.Exists(configPath) and json.parse(File.Read(configPath)) or {}

    ---@param option table
    ---@param optionName string
    ---@param optionDefault ConfigOption|ConfigSection
    local function LoadRecurse(option, optionName, optionDefault)
        local optionValue = option[optionName]
        local optionType = type(optionDefault.value)

        if optionDefault.value ~= nil then --[[@cast optionDefault -ConfigSection]]
            if optionValue == nil or type(optionValue) ~= optionType then
                option[optionName] = optionDefault.value
            elseif optionType == "number" then
                option[optionName] = math.clamp(optionValue, optionDefault.min, optionDefault.max)
            end
        else --[[@cast optionDefault -ConfigOption]]
            if optionValue == nil then
                option[optionName] = optionDefault:Flatten()
            else
                for k, v in pairs(optionDefault) do
                    LoadRecurse(option[optionName], k, v)
                end
            end
        end
    end

    for k, v in pairs(Config.defaults.CONFIG) do
        LoadRecurse(Config.data, k, v)
    end
end

Config.Load()
Config.Save()

return Config