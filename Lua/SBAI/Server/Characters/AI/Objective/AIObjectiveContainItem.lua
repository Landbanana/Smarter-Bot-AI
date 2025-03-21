local SBAIUtils = require("SBAI.SBAIUtils")

local ItemTagToGeneralItemTag = {
    ["mobilebattery"] = "mobilebattery",
    ["refillableoxygensource"] = "oxygensource"}

local ItemTagToRefiller = {
    ["mobilebattery"] = "batterycellrecharger",
    ["refillableoxygensource"] = "oxygentankrefiller"}

    ---@type fun(itemContainer:Barotrauma.Items.Components.ItemContainer, generalItemTag:Barotrauma.Identifier):integer
    local function GetTargetSlot(itemContainer, generalItemTag)
        local index = 0

        for s in itemContainer.slotRestrictions do
            if s.ContainableItems ~= nil and s.MatchesItem(generalItemTag) and s.MaxStackSize == 1 then
                return index
            end
            index = index + 1
        end
        return -1
    end

for itemTagString, section in pairs({
    -- Replace Batteries: Replace batteries in charged tools (flashlight, handheld sonar, etc.) with full batteries from charging docks
    ["mobilebattery"] = "ReplaceBatteryCells",
    -- Replace Oxygen Tanks: Replace oxygen tanks in oxygenated tools (diving mask, plasma welder, etc.) with full oxygen tanks from refillers
    ["refillableoxygensource"] = "ReplaceOxygenTanks"}) do
    
    local namespace, _ = SBAIUtils.CheckOptionGetNamespace(section)
    if not namespace then goto continue end

    Hook.Patch(namespace, "Barotrauma.AIObjectiveContainItem", "Act",
        function(instance, _)
            if  instance.TargetSlot == nil and
                instance.SourceObjective ~= nil and
                instance.SourceObjective.SourceObjective ~= nil and
                LuaUserData.IsTargetType(instance.SourceObjective.SourceObjective, "Barotrauma.AIObjectiveLoadItem") and
                instance.SourceObjective.SourceObjective.TargetContainerTags[1] == Identifier(ItemTagToRefiller[itemTagString]) then
                    local index = GetTargetSlot(instance.container, Identifier(ItemTagToGeneralItemTag[itemTagString]))
                    if index > -1 then instance.TargetSlot = index end
            end
        end, Hook["HookMethodType"].Before)
    ::continue::
end