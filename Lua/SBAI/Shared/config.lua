local Constants = require("SBAI.Shared.constants")
local configTypes = require("SBAI.Shared.Types.configTypes")

local networking = require("SBAI.Shared.networking")
local member = networking.member
local MSG = networking.MSG

local Config = {data={}}

Config.defaults = {
    MAX_CONDITION_PERCENTAGE = 95,
    MIN_CONDITION_PERCENTAGE = 0,
    MIN_TIME_BETWEEN = 5,
    MAX_TIME_BETWEEN = 1000,
    MIN_MIN_HEALTH_PERCENTAGE = 10.0,
    MAX_MIN_HEALTH_PERCENTAGE = 90.0,
    CONFIG = {}
}

local defaultCrewLoadout = ""

do
    local allPrefabData = {}
    local i = 0

    for prefab in JobPrefab.Prefabs do
        if not prefab.HiddenJob then
            i = i + 1
            allPrefabData[i] = {prefab.Name, prefab.Identifier}
        end
    end
    table.sort(allPrefabData, function(p1, p2) return p1[1] < p2[1] end)
    for prefabData in allPrefabData do
        defaultCrewLoadout = defaultCrewLoadout..prefabData[2].Value..":;;;;;;;;;;;;;;;;;"
    end
end

do
    local defaults = configTypes.ConfigSection.new()
    local section
    local subsection
    local subsubsection
    
    ---section = defaults:CreateSection("CleaningAdditions")
    ---subsection = section:CreateSection("CleanWalls")
    ---subsection:CreateOption("timeBetween", 60, configTypes.OPTION_TYPE.int, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    section = defaults:CreateSection("CombatTweaks")

    section:CreateOption("PreventAttackingHandcuffed", true, configTypes.OPTION_TYPE.boolean)

    subsection = section:CreateSection("ArrestHumansInPlayerSub")
    subsection:CreateOption("onlyPreviouslyCuffed", false, configTypes.OPTION_TYPE.boolean)
    subsection:CreateOption("minHealth", 75.0, configTypes.OPTION_TYPE.float, nil, Config.defaults.MIN_MIN_HEALTH_PERCENTAGE, Config.defaults.MAX_MIN_HEALTH_PERCENTAGE)

    subsection = section:CreateSection("PreSpinTurrets")
    subsection:CreateOption("reduceNoise", true, configTypes.OPTION_TYPE.boolean)

    section = defaults:CreateSection("CleaningAdditions")
    subsection = section:CreateSection("PurchasedItemCrates", false)
    subsection:CreateOption("autoOrder", "*deconstruct;ignore", configTypes.OPTION_TYPE.int, "radio")

    subsection = section:CreateSection("DeconstructInBulk")
    subsection:CreateOption("maxCheck", 32, configTypes.OPTION_TYPE.int, nil, 2, 128)

    section:CreateOption("OnlyUseShipDeconstructor", true, configTypes.OPTION_TYPE.boolean)

    defaults:CreateSection("CrewStaysInSub")

    section = defaults:CreateSection("EquipItems")
    section:CreateOption("CrewLoadout", defaultCrewLoadout, configTypes.OPTION_TYPE.string, "loadout")
    section:CreateOption("timeBetween", 60, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    section = defaults:CreateSection("LadderFix")
    section:CreateOption("timeBetween", 30, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    section = defaults:CreateSection("MuteSingleplayerBotConversations", false)
    section:CreateOption("BlockAllBotChat", false, configTypes.OPTION_TYPE.boolean)

    section = defaults:CreateSection("OperateReactorTweaks")
    section:CreateOption("behavior", "mostlyVanilla;*fuelOnlyWhenController;fuelOnly", configTypes.OPTION_TYPE.int, "radio")
    section:CreateOption("numFuelRods", 1, configTypes.OPTION_TYPE.int, nil, 1, 4)
    section:CreateOption("minimumCondition", 10, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    section = defaults:CreateSection("Orders", false)

    section = defaults:CreateSection("ReplenishInventory")
    subsection = section:CreateSection("Idle")
    subsection:CreateOption("onlyAtFriendlyOutposts", false, configTypes.OPTION_TYPE.boolean)

    subsection = section:CreateSection("Wait")
    subsection:CreateOption("onlyAtFriendlyOutposts", true, configTypes.OPTION_TYPE.boolean)

    section:CreateOption("timeBetween", 30, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)
    section:CreateOption("fillEmpty", true, configTypes.OPTION_TYPE.boolean)
    section:CreateOption("forceSameItemType", false, configTypes.OPTION_TYPE.boolean)
    section:CreateOption("forceQualityGEQ", true, configTypes.OPTION_TYPE.boolean)

    subsection = section:CreateSection("Ammunition")
    subsection:CreateOption("minimumCondition", 80, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 80, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("BatteryCells")
    subsection:CreateOption("minimumCondition", 75, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("OxygenTanks")
    subsection:CreateOption("minimumCondition", 95, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("WeldingFuel")
    subsection:CreateOption("minimumCondition", 75, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)
    subsection:CreateOption("minimumEquippedCondition", 10, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)    

    section = defaults:CreateSection("SmarterLoadItems")

    subsection = section:CreateSection("BatteryCells")
    
    subsection:CreateOption("minimumCondition", 90, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    subsection = section:CreateSection("OxygenTanks")
    subsection:CreateOption("minimumCondition", 90, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_CONDITION_PERCENTAGE, Config.defaults.MAX_CONDITION_PERCENTAGE)

    section = defaults:CreateSection("SmarterPets")

    subsection = section:CreateSection("EatFoodInInventory")
    subsection:CreateOption("timeBetween", 15, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)
    subsection:CreateOption("overrideProtectOwner", true, configTypes.OPTION_TYPE.boolean)

    subsection = section:CreateSection("BotsPlayWhenIdle")
    subsection:CreateOption("timeBetween", 15, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    section:CreateSection("CleanableProduce")

    section = defaults:CreateSection("UseFurniture")
    subsection = section:CreateSection("AutoUseWhenIdle")
    subsection:CreateOption("beds", true, configTypes.OPTION_TYPE.boolean)
    subsection:CreateOption("chairs", true, configTypes.OPTION_TYPE.boolean)

    section:CreateOption("stayInBedIfHurt", true, configTypes.OPTION_TYPE.boolean)

    section = defaults:CreateSection("UseTalents")
    section:CreateOption("idle", true, configTypes.OPTION_TYPE.boolean)
    section:CreateOption("wait", true, configTypes.OPTION_TYPE.boolean)
    section:CreateOption("timeBetween", 15, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    subsection = section:CreateSection("Assistant")
    subsubsection = subsection:CreateSection("InspiringTunes")
    subsubsection:CreateOption("stopAfterBuffed", true, configTypes.OPTION_TYPE.boolean)
    
    subsubsection = subsection:CreateSection("JengaMaster")
    subsubsection:CreateOption("timeBetween", 120, configTypes.OPTION_TYPE.int, nil, Config.defaults.MIN_TIME_BETWEEN, Config.defaults.MAX_TIME_BETWEEN)

    subsubsection = subsection:CreateSection("NonThreatening")
    subsubsection:CreateOption("minHealth", 75.0, configTypes.OPTION_TYPE.float, nil, Config.defaults.MIN_MIN_HEALTH_PERCENTAGE, Config.defaults.MAX_MIN_HEALTH_PERCENTAGE)
    -- subsubsection:CreateOption("Accordion", true, configTypes.OPTION_TYPE.boolean)
    -- subsubsection:CreateOption("Bikehorn", true, configTypes.OPTION_TYPE.boolean)
    -- subsubsection:CreateOption("Guitar", true, configTypes.OPTION_TYPE.boolean)
    -- subsubsection:CreateOption("Harmonica", true, configTypes.OPTION_TYPE.boolean)
    
    -- subsection:CreateOption("ChonkyHonks", true, configTypes.OPTION_TYPE.boolean)

    subsection = section:CreateSection("Captain")
    subsubsection = subsection:CreateSection("SteadyTune")
    subsubsection:CreateOption("stopAfterBuffed", true, configTypes.OPTION_TYPE.boolean)

    subsection = section:CreateSection("Engineer")
    subsubsection = subsection:CreateSection("MelodicRespite")
    subsubsection:CreateOption("stopAfterBuffed", true, configTypes.OPTION_TYPE.boolean)

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

    if not File.Exists(Constants.ConfigPath) then Config.Save() end

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
                member:Send(MSG.CONF_UPDATE, nil, nil, Config.data)
                return Config.Save()
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
end

return Config