local Config = {data={}}
local modConfigsDir = Game.SaveFolder.."/ModConfigs" --[[@type string]]
local configPath = modConfigsDir.."/SBAI.json" --[[@type string]]

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
    MAX_TIME_BETWEEN = 1000,
    START_TIME_BETWEEN = 1,
    CONFIG = {}
}

---@class ConfigBase
---@field public new fun(self:ConfigBase, ...):ConfigBase
---@field public Flatten fun(self:ConfigBase):string|boolean|number|table
---@field public __index ConfigBase

---@class (exact) ConfigOption: ConfigBase 
---@field public value string|boolean|number
---@field public optionType string|boolean|number
---@field public min? number
---@field public max? number
---@field public new fun(self:ConfigOption, default:string|boolean|number, optionType:Config.OPTION_TYPE, min:number?, max:number?):ConfigOption
---@field public Set fun(self:ConfigOption, value:string|boolean|number)
---@field public Flatten fun(self:ConfigOption):string|boolean|number
local ConfigOption = {}

function ConfigOption.new(self, default, optionType, min, max)
    local t = setmetatable({}, self) ---@type ConfigOption
    self.__index = self

    t.optionType = optionType
    t.min = min
    t.max = max
    t:Set(default)
    return t
end

do
    local clamp = math.clamp

    function ConfigOption.Set(self, value)
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

function ConfigOption.Flatten(self)
    return self.value
end

---@class (exact) ConfigSection: ConfigBase
---@field public new fun(self:ConfigSection):ConfigSection
---@field public CreateOption fun(self:ConfigSection, name:string, default:string|boolean|number, optionType:Config.OPTION_TYPE, min:number?, max:number?):ConfigOption
---@field public CreateSection fun(self:ConfigSection, name:string, description:string?):ConfigSection
---@field public Flatten fun(self:ConfigSection):table
local ConfigSection = {}

function ConfigSection.new(self)
    local t = setmetatable({}, self) ---@type ConfigSection
    self.__index = self

    return t
end

function ConfigSection.CreateOption(self, name, default, optionType, min, max)
    self[name] = ConfigOption:new(default, optionType, min, max)
    return self[name]
end

function ConfigSection.CreateSection(self, name)
    self[name] = ConfigSection:new()
    self[name]:CreateOption("enable", true, "boolean")
    return self[name]
end

function ConfigSection.Flatten(self)
    local t = {}
    
    for k, v in pairs(self) do --[[@cast k string]]  --[[@cast v ConfigBase]]
        t[k] = v:Flatten()
    end
    return t
end

do
    local defaults = ConfigSection:new()
    local section = defaults:CreateSection("EquipArmor")
    
    section:CreateOption("timeBetween", 30, Config.OPTION_TYPE.int, 5, Config.defaults.MAX_TIME_BETWEEN)

    defaults:CreateSection("PreventAttackingHandcuffed")

    section = defaults:CreateSection("GunnersNeverAttackIntruders")
    section:CreateOption("OnlyIfOtherBotsFightingIntruders", true, "boolean")

    defaults:CreateSection("UseShipDeconstructorIfAvailable")

    section = defaults:CreateSection("SmarterLoadItems")

    local subsection = section:CreateSection("BatteryCells")
    
    subsection:CreateOption("minimumCondition", 90, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("OxygenTanks")
    subsection:CreateOption("minimumCondition", 90, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    section = defaults:CreateSection("ReplenishInventory")
    subsection = section:CreateSection("Idle")
    subsection:CreateOption("OnlyAtFriendlyOutposts", false, Config.OPTION_TYPE.boolean)

    subsection = section:CreateSection("Wait")
    subsection:CreateOption("OnlyAtFriendlyOutposts", true, Config.OPTION_TYPE.boolean)

    subsection = section:CreateSection("BatteryCells")
    subsection:CreateOption("minimumCondition", 75, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("OxygenTanks")
    subsection:CreateOption("minimumCondition", 95, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    section:CreateOption("timeBetween", 30, Config.OPTION_TYPE.int, 5, Config.defaults.MAX_TIME_BETWEEN)

    defaults:CreateSection("IdleUseBed")

    defaults:CreateSection("CrewStaysInSub")

    section = defaults:CreateSection("LadderFix")
    section:CreateOption("timeBetween", 1000, Config.OPTION_TYPE.float, 10, Config.defaults.MAX_TIME_BETWEEN)

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
if not File.Exists(configPath) then Config.Save() end

return Config