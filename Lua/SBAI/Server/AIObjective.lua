LuaUserData.RegisterType("Barotrauma.AIObjectiveDeconstructItem") 

-- deconstruct only within the sub if deconstructor is within sub, with optimized calls to get all deconstructors in map
Hook.Patch("SBAI.FindDeconstructor", "Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor", function(instance, ptable)
    ptable.PreventExecution = true

    local closestDeconstructor = nil
    local bestDistFactor = 0

    for attempt = 1, 2, 1 do
        for i, potentialDeconstructor in ipairs(SBAI.DeconstructorList) do
            local distFactor
            if potentialDeconstructor == nil then goto continue end
            if potentialDeconstructor.InputContainer == nil then goto continue end
            if not potentialDeconstructor.InputContainer.Inventory.CanBePut(instance.Item) then goto continue end
            if not potentialDeconstructor.Item.HasAccess(instance.character) then goto continue end
            distFactor = AIObjective.GetDistanceFactor(instance.Item.WorldPosition, potentialDeconstructor.Item.WorldPosition, 0.2)
            if distFactor > bestDistFactor then
                closestDeconstructor = potentialDeconstructor
                bestDistFactor = distFactor
            end
            ::continue::
        end
        
        -- regenerate the deconstructor list the old way if failed
        if closestDeconstructor == nil and attempt == 1 then SBAI.GenerateDeconstructorList() end
    end

    return closestDeconstructor
end, Hook.HookMethodType.Before)