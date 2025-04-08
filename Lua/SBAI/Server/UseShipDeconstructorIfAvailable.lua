SBAI = require("SBAI")

SBAI.LuaUserData.RegisterType("Barotrauma.AIObjectiveDeconstructItem")

---@param namespace Namespace
---@param options table
return function(namespace, options)
    local playerSubmarineDeconstructors --[=[@type Barotrauma.Item[]?]=]

    -- bought a new sub, some mod adds deployable deconstructors, etc.
    SBAI.Hook.Add("roundEnd", namespace(), function()
        playerSubmarineDeconstructors = nil
    end)

    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor",
    ---@param instance Baroreauma.AIObjective
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    ---@return Barotrauma.Item
    function(instance, ptable)
        local character = instance.character

        if not playerSubmarineDeconstructors then
            playerSubmarineDeconstructors = {}
            local i = 0

            for item in Item.ItemList do --[[@cast item Barotrauma.Item]]
                if  item ~= nil and
                    item.GetComponent(Components.Deconstructor) ~= nil and
                    item.InPlayerSubmarine
                then
                    i = i + 1
                    playerSubmarineDeconstructors[i] = item
                end
            end
        end

        if #playerSubmarineDeconstructors > 0 then
            local closestDeconstructorItem = SBAI.util.GetClosest(character.WorldPosition, SBAI.util.FindItems(nil, playerSubmarineDeconstructors, nil, nil,
            function(_, i)
                return i.GetComponent(Components.Deconstructor).InputContainer.Inventory.CanBePut(instance.Item) and
                    i.HasAccess(character)
            end))

            ptable.PreventExecution = true

            return closestDeconstructorItem and closestDeconstructorItem.GetComponent(Components.Deconstructor) or nil
        end
    end, Hook.HookMethodType.Before)
end