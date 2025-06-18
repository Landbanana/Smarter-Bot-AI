local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

local configTypes = {}

---@enum OPTION_TYPE
local OPTION_TYPE = {
    string="string",
    int="int",
    float="float",
    boolean="boolean"
}
configTypes.OPTION_TYPE = OPTION_TYPE

---@class ConfigOption
---@field public specialData any
---@field public value string|boolean|number
---@field public optionType string|boolean|number
---@field public specialType? string
---@field public min? number
---@field public max? number
local ConfigOption = {}
ConfigOption.__index = ConfigOption
configTypes.ConfigOption = ConfigOption

do
    local specialDataLoadout do
        
        local concat = table.concat
        local CreateBuilder = util.itertools.CreateBuilder
        local new = Types.Set.new

        ---@param allLoadoutStr string
        ---@return string
        function specialDataLoadout(allLoadoutStr)
            local jobIdStrs = new()

            for prefab in JobPrefab.Prefabs do
                if not prefab.HiddenJob then
                    jobIdStrs:Add(prefab.Identifier.Value)
                end
            end
            
            local allLoadoutStrs, builder = CreateBuilder()
            local n = Constants.D_HUMAN_INV_N

            allLoadoutStr:gsub("([%w%s]+):([%w%s|;]+;)",
            ---@param jobIdStr string
            ---@param loadoutStr string
            ---@return string|nil
            function(jobIdStr, loadoutStr)
                builder(jobIdStr)
                builder(":")
                jobIdStrs:Remove(jobIdStr)
                local i = 0

                for itemIdx=1,n,1 do
                    local _, j = loadoutStr:find("[%w%s|]*;", i + 1)
                    --print(jobIdStr)
                    if j == nil then
                        builder(loadoutStr:sub(1, i))
                        builder((";"):rep(n - itemIdx + 1))
                        return false
                    end
                    i = j
                end
                builder(loadoutStr)
                return false
            end)

            for jobIdStr in jobIdStrs do
                builder(jobIdStr)
                builder(":")
                builder((";"):rep(n))
            end
            return concat(allLoadoutStrs)
        end
    end

    local setmetatable = setmetatable

    ---@param default boolean|string|number
    ---@param optionType OPTION_TYPE
    ---@param specialType? string
    ---@param min? number
    ---@param max? number
    ---@return ConfigOption
    ---@overload fun(default:string, optionType:OPTION_TYPE.string, specialType:nil):ConfigOption
    ---@overload fun(default:number, optionType:OPTION_TYPE.int|OPTION_TYPE.float, specialType:nil, min:number, max:number):ConfigOption
    ---@overload fun(default:string, optionType:OPTION_TYPE.int, specialType:"radio"):ConfigOption
    ---@overload fun(default:boolean, optionType:OPTION_TYPE.boolean, specialType:nil):ConfigOption
    function ConfigOption.new(default, optionType, specialType, min, max)
        local t = setmetatable({}, ConfigOption) ---@type ConfigOption
        
        if specialType then
            if specialType == "radio" then --[[@cast default string]]
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
            elseif specialType == "loadout" then
               t.specialData = specialDataLoadout
               default = specialDataLoadout("")
            end
        end

        t.optionType = optionType
        t.specialType = specialType
        t.min = min
        t.max = max
        t:Set(default)
        return t
    end
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
configTypes.ConfigSection = ConfigSection

do
    setmetatable = setmetatable

    ---@public
    ---@return ConfigSection
    function ConfigSection.new()
        return setmetatable({}, ConfigSection)
    end
end

---@public
---@param name string
---@param default string|number|boolean
---@param optionType configTypes.OPTION_TYPE
---@param specialType? string
---@param min? number
---@param max? number
---@return ConfigOption
---@overload fun(self:ConfigSection, name:string, default:string, optionType:configTypes.OPTION_TYPE.string, specialType:nil):ConfigOption
---@overload fun(self:ConfigSection, name:string, default:string, optionType:configTypes.OPTION_TYPE.int, specialType:"radio"):ConfigOption
---@overload fun(self:ConfigSection, name:string, default:number, optionType:configTypes.OPTION_TYPE.int|configTypes.OPTION_TYPE.float, specialType:nil, min:number, max:number):ConfigOption
---@overload fun(self:ConfigSection, name:string, default:boolean, optionType:configTypes.OPTION_TYPE.boolean, specialType:nil):ConfigOption
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
    
    for k, v in next, self do --[[@cast k string]]  --[[@cast v ConfigSection|ConfigOption]]
        t[k] = v:Flatten()
    end
    return t
end

return configTypes