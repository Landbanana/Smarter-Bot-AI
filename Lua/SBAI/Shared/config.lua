local Constants = require("SBAI.Shared.constants")

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
            print(self.optionType)
            print(optionType)
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
    
    defaults:CreateSection("CleanablePetItems")

    defaults:CreateSection("CrewStaysInSub")

    section = defaults:CreateSection("EquipArmor")
    section:CreateOption("timeBetween", 60, Config.OPTION_TYPE.int, 5, Config.defaults.MAX_TIME_BETWEEN)

    section = defaults:CreateSection("IdleUseFurniture")
    section:CreateOption("Beds", true, Config.OPTION_TYPE.boolean)
    section:CreateOption("Chairs", true, Config.OPTION_TYPE.boolean)

    section = defaults:CreateSection("LadderFix")
    section:CreateOption("timeBetween", 1000, Config.OPTION_TYPE.float, 10, Config.defaults.MAX_TIME_BETWEEN)

    defaults:CreateSection("PreventAttackingHandcuffed")

    defaults:CreateSection("UseShipDeconstructorIfAvailable")

    section = defaults:CreateSection("ReplenishInventory")
    subsection = section:CreateSection("Idle")
    subsection:CreateOption("OnlyAtFriendlyOutposts", false, Config.OPTION_TYPE.boolean)

    subsection = section:CreateSection("Wait")
    subsection:CreateOption("OnlyAtFriendlyOutposts", true, Config.OPTION_TYPE.boolean)

    subsection = section:CreateSection("Ammunition")
    subsection:CreateOption("minimumCondition", 80, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 80, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("BatteryCells")
    subsection:CreateOption("minimumCondition", 75, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("OxygenTanks")
    subsection:CreateOption("minimumCondition", 95, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("WeldingFuel")
    subsection:CreateOption("minimumCondition", 75, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)    

    section:CreateOption("timeBetween", 30, Config.OPTION_TYPE.int, 5, Config.defaults.MAX_TIME_BETWEEN)

    section = defaults:CreateSection("SmarterLoadItems")

    subsection = section:CreateSection("BatteryCells")
    
    subsection:CreateOption("minimumCondition", 90, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("OxygenTanks")
    subsection:CreateOption("minimumCondition", 90, Config.OPTION_TYPE.float, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

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

if SERVER or Game.IsSingleplayer then
    function Config.Load()
        Config.data = File.Exists(Constants.ConfigPath) and json.parse(File.Read(Constants.ConfigPath)) or {}
    
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

    function Config.Save()
        File.CreateDirectory(Constants.ModConfigsDirPath)
        File.Write(Constants.ConfigPath, json.serialize(Config.data))
    end
end

if Game.IsMultiplayer then
    ---@enum NetworkMsg
    local NETWORK_MSG = {
        ConfigUpdate=Constants.Acronym..".ConfigUpdate",
        ConfigRequest=Constants.Acronym..".ConfigRequest"
    }

    ---@return string
    local function SerializeConfig()
        return json.serialize(Config.data)
    end

    ---@param message Barotrauma.Networking.IReadMessage
    local function UnserializeConfig(message)
        Config.data = json.parse(message.ReadString())
    end

    if SERVER then
        ---@param client Barotrauma.Networking.Client
        local function SendConfig(client)
            local message = Networking.Start(NETWORK_MSG.ConfigUpdate)
    
            message.WriteString(SerializeConfig())
            return Networking.Send(message, client and client.Connection or nil)
        end
    
        Networking.Receive(NETWORK_MSG.ConfigUpdate,
        ---@param message Barotrauma.Networking.IReadMessage
        ---@param client Barotrauma.Networking.Client
        function(message, client)
            if not client.HasPermission(ClientPermissions.ManageSettings) then return end
    
            UnserializeConfig(message)
            return Config.Save()
        end)
    
        Networking.Receive(NETWORK_MSG.ConfigRequest,
        ---@param _ Barotrauma.Networking.IReadMessage
        ---@param client Barotrauma.Networking.IReadMessage
        function(_, client)
            if not client then return end
    
            return SendConfig(client)
        end)
    else
        local function SendConfig()
            local message = Networking.Start(NETWORK_MSG.ConfigUpdate)

            message.WriteString(SerializeConfig())
            return Networking.Send(message)
        end
    
        local function RequestConfig()
            return Networking.Send(Networking.Start(NETWORK_MSG.ConfigRequest))
        end

        function Config.Load()
            return RequestConfig()
        end
    
        function Config.Save()
            return SendConfig()
        end
    
        Networking.Receive(NETWORK_MSG.ConfigUpdate,
        ---@param message Barotrauma.Networking.IReadMessage
        function(message)
            return UnserializeConfig(message)
        end)
    end
end

return Config