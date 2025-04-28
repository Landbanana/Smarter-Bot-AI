local Constants = require("SBAI.Shared.constants")

local networking = require("SBAI.Shared.networking")
local member = networking.member
local MSG = networking.MSG

local Config = {data={}}

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
    MIN_TIME_BETWEEN = 5,
    MAX_TIME_BETWEEN = 1000,
    CONFIG = {}
}

---@class (exact) ConfigBase
---@field public new fun(...):ConfigBase
---@field public Flatten fun(self:ConfigBase):string|boolean|number|table
---@field public __index ConfigBase

---@class (exact) ConfigOption: ConfigBase
---@field public value string|boolean|number
---@field public optionType string|boolean|number
---@field public min? number
---@field public max? number
---@field public new fun(default:string|boolean|number, optionType:Config.OPTION_TYPE, min:number?, max:number?):ConfigOption
---@field public Set fun(self:ConfigOption, value:string|boolean|number)
---@field public Flatten fun(self:ConfigOption):string|boolean|number
local ConfigOption = {}
ConfigOption.__index = ConfigOption

function ConfigOption.new(default, optionType, min, max)
    local t = setmetatable({}, ConfigOption) ---@type ConfigOption

    t.optionType = optionType
    t.min = min
    t.max = max
    t:Set(default)
    return t
end

do
    local clamp = math.clamp

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

function ConfigOption:Flatten()
    return self.value
end

---@class (exact) ConfigSection: ConfigBase
---@field public new fun():ConfigSection
---@field public CreateOption fun(self:ConfigSection, name:string, default:string|boolean|number, optionType:Config.OPTION_TYPE, min:number?, max:number?):ConfigOption
---@field public CreateSection fun(self:ConfigSection, name:string):ConfigSection
---@field public Flatten fun(self:ConfigSection):table
---@field public [string] ConfigSection|ConfigOption
local ConfigSection = {}
ConfigSection.__index = ConfigSection

function ConfigSection.new()
    local t = setmetatable({}, ConfigSection) ---@type ConfigSection
    return t
end

function ConfigSection:CreateOption(name, default, optionType, min, max)
    self[name] = ConfigOption.new(default, optionType, min, max)
    return self[name]
end

function ConfigSection:CreateSection(name)
    self[name] = ConfigSection.new()
    self[name]:CreateOption("enable", true, "boolean")
    return self[name]
end

function ConfigSection:Flatten()
    local t = {}
    
    for k, v in pairs(self) do --[[@cast k string]]  --[[@cast v ConfigBase]]
        t[k] = v:Flatten()
    end
    return t
end

do
    local defaults = ConfigSection.new()
    local section
    local subsection
    local subsubsection
    
    ---section = defaults:CreateSection("CleaningAdditions")
    ---subsection = section:CreateSection("CleanWalls")
    ---subsection:CreateOption("timeBetween", 60, Config.OPTION_TYPE.int, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    defaults:CreateSection("CleanablePetItems")

    defaults:CreateSection("CrewStaysInSub")

    section = defaults:CreateSection("EquipArmor")
    section:CreateOption("timeBetween", 60, Config.OPTION_TYPE.int, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    section = defaults:CreateSection("LadderFix")
    section:CreateOption("timeBetween", 30, Config.OPTION_TYPE.int, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    section = defaults:CreateSection("Orders")
    section:CreateOption("ignoreRoom", true, Config.OPTION_TYPE.boolean)

    defaults:CreateSection("PreventAttackingHandcuffed")

    section = defaults:CreateSection("ReplenishInventory")
    subsection = section:CreateSection("Idle")
    subsection:CreateOption("onlyAtFriendlyOutposts", false, Config.OPTION_TYPE.boolean)

    subsection = section:CreateSection("Wait")
    subsection:CreateOption("onlyAtFriendlyOutposts", true, Config.OPTION_TYPE.boolean)

    section:CreateOption("timeBetween", 30, Config.OPTION_TYPE.int, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    subsection = section:CreateSection("Ammunition")
    subsection:CreateOption("minimumCondition", 80, Config.OPTION_TYPE.int, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 80, Config.OPTION_TYPE.int, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("BatteryCells")
    subsection:CreateOption("minimumCondition", 75, Config.OPTION_TYPE.int, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, Config.OPTION_TYPE.int, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("OxygenTanks")
    subsection:CreateOption("minimumCondition", 95, Config.OPTION_TYPE.int, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, Config.OPTION_TYPE.int, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("WeldingFuel")
    subsection:CreateOption("minimumCondition", 75, Config.OPTION_TYPE.int, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, Config.OPTION_TYPE.int, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)    

    section = defaults:CreateSection("SmarterLoadItems")

    subsection = section:CreateSection("BatteryCells")
    
    subsection:CreateOption("minimumCondition", 90, Config.OPTION_TYPE.int, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("OxygenTanks")
    subsection:CreateOption("minimumCondition", 90, Config.OPTION_TYPE.int, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    section = defaults:CreateSection("UseFurniture")
    subsection = section:CreateSection("AutoUseWhenIdle")
    subsection:CreateOption("beds", true, Config.OPTION_TYPE.boolean)
    subsection:CreateOption("chairs", true, Config.OPTION_TYPE.boolean)

    section:CreateOption("stayInBedIfHurt", true, Config.OPTION_TYPE.boolean)

    defaults:CreateSection("UseShipDeconstructorIfAvailable")

    section = defaults:CreateSection("UseTalents")
    section:CreateOption("idle", true, Config.OPTION_TYPE.boolean)
    section:CreateOption("wait", true, Config.OPTION_TYPE.boolean)
    section:CreateOption("timeBetween", 15, Config.OPTION_TYPE.int, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    subsection = section:CreateSection("Assistant")
    subsubsection = subsection:CreateSection("InspiringTunes")
    subsubsection:CreateOption("stopAfterBuffed", true, Config.OPTION_TYPE.boolean)
    
    subsubsection = subsection:CreateSection("JengaMaster")
    subsubsection:CreateOption("timeBetween", 120, Config.OPTION_TYPE.int, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    subsubsection = subsection:CreateSection("NonThreatening")
    subsubsection:CreateOption("ragdollHealthPercent", 75.0, Config.OPTION_TYPE.float, 10, 90) 
    -- subsubsection:CreateOption("Accordion", true, Config.OPTION_TYPE.boolean)
    -- subsubsection:CreateOption("Bikehorn", true, Config.OPTION_TYPE.boolean)
    -- subsubsection:CreateOption("Guitar", true, Config.OPTION_TYPE.boolean)
    -- subsubsection:CreateOption("Harmonica", true, Config.OPTION_TYPE.boolean)
    
    -- subsection:CreateOption("ChonkyHonks", true, Config.OPTION_TYPE.boolean)

    subsection = section:CreateSection("Captain")
    subsubsection = subsection:CreateSection("SteadyTune")
    subsubsection:CreateOption("stopAfterBuffed", true, Config.OPTION_TYPE.boolean)

    -- subsection = section:CreateSection("Engineer")
    -- subsubsection = subsection:CreateSection("MelodicRespite")
    -- subsubsection:CreateOption("stopAfterBuffed", false, Config.OPTION_TYPE.boolean)

    Config.defaults.CONFIG = defaults
end

if  SERVER or
    Game.IsSingleplayer
then
    function Config.Load()
        local rawConfig = File.Exists(Constants.ConfigPath) and json.parse(File.Read(Constants.ConfigPath)) or nil
        local config = Config.data
        
        ---@param name string
        ---@param raw table
        ---@param default ConfigOption|ConfigSection
        local function LoadRecurse(name, raw, default)
            local defaultValue = default.value
            local defaultType = type(defaultValue)
            local rawValue
            
            if raw then
                rawValue = raw[name]
            end

            if defaultValue ~= nil then --[[@cast default -ConfigSection]]
                if type(rawValue) ~= defaultType then
                    return defaultValue
                elseif defaultType == "number" then
                    return math.clamp(rawValue, default.min, default.max)
                else
                    return rawValue
                end
            else --[[@cast default -ConfigOption]]
                if rawValue == nil then
                    return default:Flatten()
                else
                    local out = {}
                    local i = 0

                    for k, v in next, default do
                        i = i + 1
                        out[k] = LoadRecurse(k, rawValue, v)
                    end
                    return out
                end
            end
        end

        for k, v in next, Config.defaults.CONFIG do
            local success, result = pcall(LoadRecurse, k, rawConfig, v) --[[@type boolean, any]]
            
            if success == false then
                Logger.LogError("Config.Load."..k..": "..result)
                config[k] = v:Flatten()
            else
                config[k] = result
            end
        end
    end

    do
        local ModConfigsDirPath = Constants.ModConfigsDirPath
        local ConfigPath = Constants.ConfigPath

        local CreateDirectory = File.CreateDirectory
        local serialize = json.serialize
        local Write = File.Write

        function Config.Save()
            CreateDirectory(ModConfigsDirPath)
            Write(ConfigPath, serialize(Config.data))
        end
    end

    if Game.IsMultiplayer then
        member:AddHandler(MSG.CONF_REQUEST,
        function(data, client)
            if not client then return end
            Config.Load()
            return member:Send(MSG.CONF_UPDATE, client, nil, Config.data)
        end)
    
        do
            local ManageSettings = ClientPermissions.ManageSettings
    
            member:AddHandler(MSG.CONF_UPDATE,
            function(data, client)
                if not client.HasPermission(ManageSettings) then return end
    
                Config.data = data
                Config.Save()
            end)
        end
    end
end

if  Game.IsMultiplayer and
    CLIENT
then
    function Config.Load()
        return member:Send(MSG.CONF_REQUEST)
    end
    
    function Config.Save()
        if not Config.data then return end
        return member:Send(MSG.CONF_UPDATE, nil, nil, Config.data)
    end
    
    member:AddHandler(MSG.CONF_UPDATE,
    function(data, client)
        Config.data = data
    end)
end

return Config