local SBAIUtils = require("SBAI.SBAIUtils")

local AIObjectiveLoadItems_Descriptor = LuaUserData.RegisterType("Barotrauma.AIObjectiveLoadItems")
LuaUserData.MakePropertyAccessible(AIObjectiveLoadItems_Descriptor, "TargetCondition")
LuaUserData.MakePropertyAccessible(AIObjectiveLoadItems_Descriptor, "TargetContainerTags")

for itemTagString, section in pairs({
    -- Replace Batteries: Replace batteries in charged tools (flashlight, handheld sonar, etc.) with full batteries from charging docks
    ["mobilebattery"] = "ReplaceBatteryCells",
    -- Replace Oxygen Tanks: Replace oxygen tanks in oxygenated tools (diving mask, plasma welder, etc.) with full oxygen tanks from refillers
    ["refillableoxygensource"] = "ReplaceOxygenTanks"}) do

    local minimumCondition = nil
    local namespace, configSection = SBAIUtils.CheckOptionGetNamespace(section)
    if not namespace then goto continue end

    minimumCondition = configSection.minimumCondition

    Hook.Patch(namespace, "Barotrauma.AIObjectiveLoadItems", "ItemMatchesTargetCondition",
    function(_, ptable)
        local item = ptable["item"]

        if item.HasTag(Identifier(itemTagString)) then
            ptable.PreventExecution = true
            
            return item.Container ~= nil and
                SBAIUtils.IsSpecifiedContainer(item.Container, item) and
                item.ConditionPercentage >= minimumCondition or
                item.IsFullCondition
        end
    end, Hook["HookMethodType"].Before)
    ::continue::
end