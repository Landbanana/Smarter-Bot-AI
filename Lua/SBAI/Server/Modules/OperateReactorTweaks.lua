local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

-- LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Items.Components.Reactor"], "TooMuchFuel")
-- LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Items.Components.Reactor"], "NeedMoreFuel")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Reactor"], "fireTimer")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Reactor"], "signalControlledTargetFissionRate")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Reactor"], "signalControlledTargetTurbineOutput")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.ItemInventory"], "slots")

---@param self Types.Module
local function activate(self)
    local containItemId = Identifier("contain item")
    local operateReactorId = Identifier("operatereactor")
    local powerUpId = Identifier("powerup")

    local numFuelRods = self.options["numFuelRods"] --[[@type integer]]
    local minimumCondition = self.options["minimumCondition"] --[[@type integer]]
    local behavior = self.options["behavior"] --[[@type integer]]

    if behavior ~= 1 then
        local preventOperate

        if behavior == 2 then
            ---@param instance Barotrauma.Items.Components.Reactor
            ---@return boolean
            function preventOperate(instance)
                return instance.signalControlledTargetFissionRate ~= nil or instance.signalControlledTargetTurbineOutput ~= nil
            end
        else
            preventOperate = util.True
        end

        self:AddPatch("Barotrauma.Items.Components.Reactor", "set_AutoTemp", nil,
        function(instance, ptable)
            if  instance.Item.InPlayerSubmarine and
                preventOperate(instance)
            then
                ptable.PreventExecution = true
            end
        end, Hook.HookMethodType.Before)

        self:AddPatch("Barotrauma.Items.Components.Reactor", "UpdateAutoTemp", nil,
        function(instance, ptable)
            if  instance.Item.InPlayerSubmarine and
                preventOperate(instance) and
                ptable["speed"] < 100.0
            then
                ptable.PreventExecution = true
            end
        end, Hook.HookMethodType.Before)
    end

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

            return getNumFuelRods(instance) < numFuelRods and
                instance.fireTimer <= 0.0
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
                
                if objective.Identifier == containItemId then --[[@cast objective Barotrauma.AIObjectiveContainItem]]
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

        if  sourceObj.Identififer == operateReactorId then --[[@cast instance Barotrauma.AIObjectiveOperateItem]]
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