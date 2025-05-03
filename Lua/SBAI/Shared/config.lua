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

---@class ConfigOption
---@field public specialData any
---@field public value string|boolean|number
---@field public optionType string|boolean|number
---@field public specialType? string
---@field public min? number
---@field public max? number
local ConfigOption = {}
ConfigOption.__index = ConfigOption

---@param default boolean|string|number
---@param optionType Config.OPTION_TYPE
---@param specialType? string
---@param min? number
---@param max? number
---@return ConfigOption
---@overload fun(default:string, optionType:Config.OPTION_TYPE.string, specialType:nil):ConfigOption
---@overload fun(default:number, optionType:Config.OPTION_TYPE.int|Config.OPTION_TYPE.float, specialType:nil, min:number, max:number):
---@overload fun(default:string, optionType:Config.OPTION_TYPE.int, specialType:"radio"):ConfigOption
---@overload fun(default:boolean, optionType:Config.OPTION_TYPE.boolean, specialType:nil):ConfigOption
function ConfigOption.new(default, optionType, specialType, min, max)
    local t = setmetatable({}, ConfigOption) ---@type ConfigOption

    if optionType == Config.OPTION_TYPE.int then --[[@cast default string]]
        if specialType == "radio" then
            local newDefault = 1
            local specialData = {}
            
            min = 1
            max = 0

            for o in default:gmatch("([^;]+);?") do
                if o:startsWith("*") then
                    o = o:sub(2)
                    newDefault = max + 1
                end
                max = max + 1
                specialData[max] = o
            end
            t.specialData = specialData
            default = newDefault
            min = 1
        end
    end

    t.optionType = optionType
    t.specialType = specialType
    t.min = min
    t.max = max
    t:Set(default)
    return t
end

do
    local clamp = math.clamp

    ---@param value boolean|string|number
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

---@public
---@return table
function ConfigOption:Flatten()
    return self.value
end

---@class ConfigSection
local ConfigSection = {}
ConfigSection.__index = ConfigSection

---@public
---@return ConfigSection
function ConfigSection.new()
    local t = setmetatable({}, ConfigSection) ---@type ConfigSection
    return t
end

---@public
---@param name string
---@param default string|number|boolean
---@param optionType Config.OPTION_TYPE
---@param specialType? string
---@param min? number
---@param max? number
---@return ConfigOption
---@overload fun(self:ConfigSection, name:string, default:string, optionType:Config.OPTION_TYPE.string, specialType:nil):ConfigOption
---@overload fun(self:ConfigSection, name:string, default:string, optionType:Config.OPTION_TYPE.int, specialType:"radio"):ConfigOption
---@overload fun(self:ConfigSection, name:string, default:number, optionType:Config.OPTION_TYPE.int|Config.OPTION_TYPE.float, specialType:nil, min:number, max:number):ConfigOption
---@overload fun(self:ConfigSection, name:string, default:boolean, optionType:Config.OPTION_TYPE.boolean, specialType:nil):ConfigOption
function ConfigSection:CreateOption(name, default, optionType, specialType, min, max)
    self[name] = ConfigOption.new(default, optionType, specialType, min, max)
    return self[name]
end

---@public
---@param name string
---@param default? boolean
---@return ConfigSection
function ConfigSection:CreateSection(name, default)
    if default == nil then default = true end

    self[name] = ConfigSection.new()
    self[name]:CreateOption("enable", default, "boolean")
    return self[name]
end

---@public
---@return table
function ConfigSection:Flatten()
    local t = {}
    
    for k, v in pairs(self) do --[[@cast k string]]  --[[@cast v ConfigSection|ConfigOption]]
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

    --defaults:CreateSection("CombatTweaks")

    defaults:CreateSection("CrewStaysInSub")

    section = defaults:CreateSection("EquipArmor")
    section:CreateOption("timeBetween", 60, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    section = defaults:CreateSection("LadderFix")
    section:CreateOption("timeBetween", 30, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    section = defaults:CreateSection("OperateReactorTweaks")
    section:CreateOption("behavior", "vanilla;*fuelOnlyWhenController;fuelOnly", Config.OPTION_TYPE.int, "radio")
    section:CreateOption("numFuelRods", 1, Config.OPTION_TYPE.int, nil, 1, 4)
    section:CreateOption("minimumCondition", 10, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    section = defaults:CreateSection("Orders", false)

    defaults:CreateSection("PreventAttackingHandcuffed")

    section = defaults:CreateSection("ReplenishInventory")
    subsection = section:CreateSection("Idle")
    subsection:CreateOption("onlyAtFriendlyOutposts", false, Config.OPTION_TYPE.boolean)

    subsection = section:CreateSection("Wait")
    subsection:CreateOption("onlyAtFriendlyOutposts", true, Config.OPTION_TYPE.boolean)

    section:CreateOption("timeBetween", 30, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    subsection = section:CreateSection("Ammunition")
    subsection:CreateOption("minimumCondition", 80, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 80, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("BatteryCells")
    subsection:CreateOption("minimumCondition", 75, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("OxygenTanks")
    subsection:CreateOption("minimumCondition", 95, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("WeldingFuel")
    subsection:CreateOption("minimumCondition", 75, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)    

    section = defaults:CreateSection("SmarterLoadItems")

    subsection = section:CreateSection("BatteryCells")
    
    subsection:CreateOption("minimumCondition", 90, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("OxygenTanks")
    subsection:CreateOption("minimumCondition", 90, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    section = defaults:CreateSection("UseFurniture")
    subsection = section:CreateSection("AutoUseWhenIdle")
    subsection:CreateOption("beds", true, Config.OPTION_TYPE.boolean)
    subsection:CreateOption("chairs", true, Config.OPTION_TYPE.boolean)

    section:CreateOption("stayInBedIfHurt", true, Config.OPTION_TYPE.boolean)

    defaults:CreateSection("UseShipDeconstructorIfAvailable")

    section = defaults:CreateSection("UseTalents")
    section:CreateOption("idle", true, Config.OPTION_TYPE.boolean)
    section:CreateOption("wait", true, Config.OPTION_TYPE.boolean)
    section:CreateOption("timeBetween", 15, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    subsection = section:CreateSection("Assistant")
    subsubsection = subsection:CreateSection("InspiringTunes")
    subsubsection:CreateOption("stopAfterBuffed", true, Config.OPTION_TYPE.boolean)
    
    subsubsection = subsection:CreateSection("JengaMaster")
    subsubsection:CreateOption("timeBetween", 120, Config.OPTION_TYPE.int, nil, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    subsubsection = subsection:CreateSection("NonThreatening")
    subsubsection:CreateOption("ragdollHealthPercent", 75.0, Config.OPTION_TYPE.float, nil, 10, 90) 
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