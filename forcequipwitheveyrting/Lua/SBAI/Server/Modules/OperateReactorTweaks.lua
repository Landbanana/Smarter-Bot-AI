local Constants = require("SBAI.Shared.constants")
local Types = require("SBAI.Shared.types")

do
    local MakeFieldAccessible = LuaUserData.MakeFieldAccessible
    local MakeMethodAccessible = LuaUserData.MakeMethodAccessible
    local Descriptors = Descriptors
    local descriptor

    descriptor = Descriptors["Barotrauma.Items.Components.Reactor"]
    MakeFieldAccessible(descriptor, "fireTimer")
    MakeFieldAccessible(descriptor, "lastReceivedTurbineOutputSignalTime")
    MakeFieldAccessible(descriptor, "lastReceivedFissionRateSignalTime")
    MakeFieldAccessible(descriptor, "meltDownTimer")
    MakeMethodAccessible(descriptor, "GetGeneratedHeat")

    MakeFieldAccessible(Descriptors["Barotrauma.ItemInventory"], "slots")
end

---@param self Types.Module
local function activate(self)
    self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")

    local CONTAIN_ITEM = Constants.ID_OBJECTIVE_BASE.CONTAINITEM
    local OPERATE_REACTOR = Constants.ID_OBJECTIVE_BASE.OPERATEREACTOR
    local POWER_UP = Constants.ID_OBJECTIVE_BASE.POWERUP

    local numFuelRods = self.options["numFuelRods"] --[[@type integer]]
    local minimumCondition = self.options["minimumCondition"] --[[@type integer]]
    local behavior = self.options["behavior"] --[[@type integer]]

    ---@param instance Barotrauma.Items.Components.Reactor
    ---@return integer
    local function getNumFuelRods(instance)
        local i = 0

        for item in instance.Item.OwnInventory:SBAI_findAllItems(false, false, function(inventory, item) return item.ConditionPercentage > minimumCondition end) do
            i = i + 1
        end
        return i
    end

    if behavior ~= 1 then
        local allCharacterData

        if  behavior ~= 2 then
            local dummyTable = {isAutoReactorOn=true}

            allCharacterData = setmetatable({
                Get=function(t, character)
                    return t.character
                end
            }, {
                __index=function(t, k)
                    t[k] = dummyTable
                    return t[k]
                end
            })
        else
            local Powered = Components.Powered
            local Reactor = Components.Reactor

            allCharacterData = Types.AllTimedCharacterData.new(self, 10.0, nil, {
                ---@param self Types.AllTimedCharacterData
                ---@param character Barotrauma.Character
                Add=function(self, character)
                    getmetatable(self).Add(self, character)

                    local t = self[character]

                    t.isAutoReactorOn = false
                    t.buffer = 0
                    t.lastTurbine = 0
                    t.lastFission = 0
                end
            })

            self:AddPatch("Barotrauma.AIObjectiveOperateItem", "Act", nil,
            function(instance, ptable)
                local id = instance.Identifier

                if  id == OPERATE_REACTOR then
                    local character = instance.character
                    local characterData = allCharacterData:Get(character)
                    
                    if characterData:Update(ptable["deltaTime"]) then
                        local item = instance.Component.Item
                        local reactor = item.GetComponent(Reactor) --[[@type Barotrauma.Items.Components.Reactor]]
                        local isAutoReactorOn = characterData.isAutoReactorOn --[[@type boolean]]
                        local buffer = characterData.buffer --[[@type integer]]
                        local turbineTime = reactor.lastReceivedTurbineOutputSignalTime
                        local fissionTime = reactor.lastReceivedFissionRateSignalTime

                        if  isAutoReactorOn then
                            buffer = (buffer + 1)*((turbineTime == characterData.lastTurbine or fissionTime == characterData.lastFission) and
                            item.GetComponent(Powered).CurrPowerConsumption < 0 and
                            1 or 0)
                        else
                            buffer = (buffer + 1)*((turbineTime ~= characterData.lastTurbine and fissionTime ~= characterData.lastFission) and
                            1 or 0)
                        end
                        
                        if buffer >= 2 then
                            isAutoReactorOn = not isAutoReactorOn
                            buffer = 0
                        end

                        if isAutoReactorOn then
                            reactor.AutoTemp = false
                            if not characterData.isAutoReactorOn then 
                                character.Speak(TextManager.Get("orderdialogself.operatereactor.powerup.sbai").Value, nil, 0.0,
                                Identifier("orderdialogself.operatereactor.powerup.sbai"), 300.0)
                            end
                        end

                        characterData.isAutoReactorOn = isAutoReactorOn
                        characterData.buffer = buffer
                        characterData.lastTurbine = turbineTime
                        characterData.lastFission = fissionTime
                    end
                end
            end, Hook.HookMethodType.Before)
        end

        self:AddPatch("Barotrauma.Items.Components.Reactor", "set_AutoTemp", nil,
        function(instance, ptable)
            if  instance.Item.InPlayerSubmarine and
                instance.LastAIUser ~= nil and
                allCharacterData:Get(instance.LastAIUser).isAutoReactorOn
            then
                ptable.PreventExecution = true
            end
        end, Hook.HookMethodType.Before)

        self:AddPatch("Barotrauma.Items.Components.Reactor", "UpdateAutoTemp", nil,
        function(instance, ptable)
            if  instance.Item.InPlayerSubmarine and
                instance.LastAIUser ~= nil and
                allCharacterData:Get(instance.LastAIUser).isAutoReactorOn and
                ptable["speed"] < 100.0
            then
                ptable.PreventExecution = true
            end
        end, Hook.HookMethodType.Before)

        self:AddPatch("Barotrauma.AIObjectiveOperateItem", "GetPriority", nil,
        function(instance, ptable)
            if  instance.Identifier == OPERATE_REACTOR and
                allCharacterData:Get(instance.character).isAutoReactorOn and
                getNumFuelRods(instance.Component) == numFuelRods
            then
                ptable.PreventExecution = true

                instance.Priority = 0
                return instance.Priority
            end
        end, Hook.HookMethodType.Before)
    end

    self:AddPatch("Barotrauma.Items.Components.Reactor", "TooMuchFuel", nil,
    function(instance, ptable)
        if instance.Item.InPlayerSubmarine then
            ptable.PreventExecution = true
            
            return getNumFuelRods(instance) > numFuelRods
        end
    end, Hook.HookMethodType.Before)

    self:AddPatch("Barotrauma.Items.Components.Reactor", "NeedMoreFuel", nil,
    function(instance, ptable)
        if instance.Item.InPlayerSubmarine then
            ptable.PreventExecution = true

            if  getNumFuelRods(instance) < numFuelRods and
                instance.PowerOn
            then
                return (instance.GetGeneratedHeat(instance.FissionRate) - instance.TurbineOutput - instance.Temperature) < 5.0 and
                    instance.fireTimer <= 0.0 and
                    instance.meltDownTimer <= 0.0
            end
            return false
        end
    end, Hook.HookMethodType.Before)

    self:AddPatch("Barotrauma.AIObjective", "AddSubObjective", nil,
    function(instance, ptable)
        local id = instance.Identifier

        if  id == OPERATE_REACTOR then --[[@cast instance Barotrauma.AIObjectiveOperateItem]]
            local curOrder = instance.objectiveManager.CurrentOrder

            if  curOrder and
                curOrder.Identifier == OPERATE_REACTOR and
                instance.Option == POWER_UP
            then
                local objective = ptable["objective"]
                
                if  objective.Identifier == CONTAIN_ITEM then --[[@cast objective Barotrauma.AIObjectiveContainItem]]
                    objective.ConditionLevel = minimumCondition
                    objective.RemoveEmpty = true
                    objective.RemoveExistingWhenNecessary = true

                    local i = 0

                    for slot in objective.container.Inventory.slots do --[[@cast slot Barotrauma.Inventory.ItemSlot]]
                        if  slot.Empty() or
                            slot.First().ConditionPercentage < minimumCondition
                        then
                            objective.TargetSlot = i
                            break
                        end
                        i = i + 1
                    end
                end
            end
        end
    end, Hook.HookMethodType.Before)

    self:AddPatch("Barotrauma.AIObjectiveContainItem", "<Act>b__75_4", nil,
    function(instance, ptable)
        local sourceObj = instance.SourceObjective

        if  sourceObj.Identifier == OPERATE_REACTOR then --[[@cast instance Barotrauma.AIObjectiveOperateItem]]
            local curOrder = instance.objectiveManager.CurrentOrder

            if  curOrder and
                curOrder.Identifier == OPERATE_REACTOR and
                sourceObj.Option == POWER_UP
            then
                ptable.ReturnValue.TargetCondition = 1
            end
        end
    end, Hook.HookMethodType.After)
end

return Types.Module.new(activate)