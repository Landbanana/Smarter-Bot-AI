LuaUserData.RegisterType("Barotrauma.AIObjectiveDeconstructItem") 

-- Deconstruct Items: Deconstruct only within the sub if deconstructor is within sub, with optimized calls to get all deconstructors in map
Hook.Patch("SBAI.FindDeconstructor", "Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor", function(instance, ptable)
    ptable.PreventExecution = true

    local closestDeconstructor = nil
    local bestDistFactor = 0

    for attempt = 1, 2, 1 do
        for i, potentialDeconstructor in ipairs(SBAI.DeconstructorList) do
            local distFactor
            if potentialDeconstructor == nil then goto continue end
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
end, Hook['HookMethodType'].Before)

-- Fight Intruders: Prevent attacking any handcuffed people, regardless of being knocked down
Hook.Patch("SBAI.PreventAttackingHandcuffedFightIntruders", "Barotrauma.AIObjectiveFightIntruders", "IsValidTarget", {"Barotrauma.Character"}, function(instance, ptable)
    return ptable.ReturnValue and not ptable["target"].IsHandcuffed
end, Hook['HookMethodType'].After)

-- Operate Weapons: Prevent attacking handcuffed people
Hook.Patch("SBAI.PreventAttackingHandcuffedCombat", "Barotrauma.AIObjectiveCombat", "GetPriority", function(instance, ptable)
    if instance.Enemy.IsHandcuffed then return 0 end
end, Hook['HookMethodType'].Before)

-- Cleanup Items: Don't pick up pet food that is within a certain distance of a pet
Hook.Patch("SBAI.DontStarvePets", "Barotrauma.AIObjectiveCleanupItems", "IsValidTarget",
    {"Barotrauma.Item", "Barotrauma.Character", "System.Boolean", "System.Boolean", "System.Boolean", "System.Boolean"}, function(instance, ptable)
    if ptable.ReturnValue == true and string.find(ptable["item"].tags, "petfood%w") then
        local petIsNearby = false
        for pet in SBAI.PetList do
            petIsNearby = petIsNearby or (AIObjective.GetDistanceFactor(pet.WorldPosition, ptable["item"].WorldPosition, 0, 3, 200) ~= 0)
        end
        return not petIsNearby
    end
end, Hook['HookMethodType'].After)