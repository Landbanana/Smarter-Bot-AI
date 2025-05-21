local Types = require("SBAI.Shared.types")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Reactor"], "fireTimer")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Reactor"], "meltDownTimer")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Reactor"], "lastReceivedTurbineOutputSignalTime")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Reactor"], "lastReceivedFissionRateSignalTime")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.ItemInventory"], "slots")

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Items.Components.Reactor"], "GetGeneratedHeat")

---@param self Types.Module
local function activate(self)
    local containItemId = Identifier("contain item")
    local operateReactorId = Identifier("operatereactor")
    local powerUpId = Identifier("powerup")

    local numFuelRods = self.options["numFuelRods"] --[[@type integer]]
    local minimumCondition = self.options["minimumCondition"] --[[@type integer]]
    local behavior = self.options["behavior"] --[[@type integer]]

    ---@param instance Barotrauma.Items.Components.Reactor
    ---@return integer
    local function getNumFuelRods(instance)
        local i = 0

        for item in instance.Item.OwnInventory.GetAllItems(false) do
            if item.ConditionPercentage > minimumCondition then
                i = i + 1
            end
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
            local new = Types.Timer.new

            allCharacterData = Types.TimedCharacterData.new(self, 10.0, {
                ---@param self Types.TimedCharacterData
                ---@param character Barotrauma.Character
                Add=function(self, character)
                    self[character] = {timer=new(self.timeBetween), isAutoReactorOn=false, buffer=0, lastTurbine=0, lastFission=0}
                end})

            self:AddPatch("Barotrauma.AIObjectiveOperateItem", "Act", nil,
            function(instance, ptable)
                local id = instance.Identifier

                if  id == operateReactorId then
                    local character = instance.character
                    local characterData = allCharacterData:Get(character)
                    
                    if characterData.timer:Update(ptable["deltaTime"]) then
                        local item = instance.Component.Item
                        local reactor = item.GetComponent(Reactor) --[[@type Barotrauma.Items.Components.Reactor]]
                        local isAutoReactorOn = characterData["isAutoReactorOn"] --[[@type boolean]]
                        local buffer = characterData["buffer"] --[[@type integer]]
                        local turbineTime = reactor.lastReceivedTurbineOutputSignalTime
                        local fissionTime = reactor.lastReceivedFissionRateSignalTime

                        if  isAutoReactorOn then
                            buffer = (buffer + 1)*((turbineTime == characterData["lastTurbine"] or fissionTime == characterData["lastFission"]) and
                            item.GetComponent(Powered).CurrPowerConsumption < 0 and
                            1 or 0)
                        else
                            buffer = (buffer + 1)*((turbineTime ~= characterData["lastTurbine"] and fissionTime ~= characterData["lastFission"]) and
                            1 or 0)
                        end
                        
                        if buffer >= 2 then
                            isAutoReactorOn = not isAutoReactorOn
                            buffer = 0
                        end

                        if isAutoReactorOn then
                            reactor.AutoTemp = false
                            if not characterData["isAutoReactorOn"] then 
                                character.Speak(TextManager.Get("orderdialogself.operatereactor.powerup.sbai").Value, nil, 0.0,
                                Identifier("orderdialogself.operatereactor.powerup.sbai"), 300.0)
                            end
                        end

                        characterData["isAutoReactorOn"] = isAutoReactorOn
                        characterData["buffer"] = buffer
                        characterData["lastTurbine"] = turbineTime
                        characterData["lastFission"] = fissionTime
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
            if  instance.Identifier == operateReactorId and
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

        if  id == operateReactorId then --[[@cast instance Barotrauma.AIObjectiveOperateItem]]
            local curOrder = instance.objectiveManager.CurrentOrder

            if  curOrder and
                curOrder.Identifier == operateReactorId and
                instance.Option == powerUpId
            then
                local objective = ptable["objective"]
                
                if  objective.Identifier == containItemId then --[[@cast objective Barotrauma.AIObjectiveContainItem]]
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

        if  sourceObj.Identifier == operateReactorId then --[[@cast instance Barotrauma.AIObjectiveOperateItem]]
            local curOrder = instance.objectiveManager.CurrentOrder

            if  curOrder and
                curOrder.Identifier == operateReactorId and
                sourceObj.Option == powerUpId
            then
                ptable.ReturnValue.TargetCondition = 1
            end
        end
    end, Hook.HookMethodType.After)
end

return Types.Module.new(activate)