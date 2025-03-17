table.insert(SBAI.Namespace, "AIObjective")

local function Reset()
    -- bought a new sub, some mod adds deployable deconstructors, etc.
    SBAI.playerSubmarineHasDeconstructor = nil --[[@type boolean|nil]]
end

Hook.Add("roundEnd", SBAI.GetNamespace()..".Reset", Reset)
Reset()

LuaUserData.RegisterType("Barotrauma.AIObjectiveDeconstructItem") 

-- Deconstruct Items: Deconstruct only within the sub if deconstructor is within sub, with optimized calls to get all deconstructors in map
Hook.Patch(SBAI.GetNamespace()..".UseShipDeconstructorIfAvailable", "Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor", function(instance, ptable)
    ptable.PreventExecution = true

    local closestDeconstructor = nil --[[@type Barotrauma.Items.Components.Deconstructor|nil]]
    local bestDistFactor = 0.0 --[[@type System.Single]]

    if SBAI.playerSubmarineHasDeconstructor == nil then
        local i, deconstructorItem = next(SBAI.itemGroups["allDeconstructors"], nil)

        while i and not SBAI.playerSubmarineHasDeconstructor do
            SBAI.playerSubmarineHasDeconstructor = deconstructorItem.InPlayerSubmarine
            i, deconstructorItem = next(SBAI.itemGroups["allDeconstructors"], i)
        end
    end

    local deconstructor --[[@type Barotrauma.Items.Components.Deconstructor]]
    local distFactor --[[@type System.Single]]

    for _, deconstructorItem in ipairs(SBAI.GetUsableDeconstructors()) do
        if deconstructorItem == nil then goto continue end
        if SBAI.playerSubmarineHasDeconstructor and not deconstructorItem.InPlayerSubmarine then goto continue end
        deconstructor = deconstructorItem.GetComponentString("Deconstructor") --[[@type Barotrauma.Items.Components.Deconstructor]]
        if not deconstructor.InputContainer.Inventory.CanBePut(instance.Item) then goto continue end
        if not deconstructorItem.HasAccess(instance.character) then goto continue end

        distFactor = AIObjective.GetDistanceFactor(instance.Item.WorldPosition, deconstructorItem.WorldPosition, 0.2)
            if distFactor > bestDistFactor then
            closestDeconstructor = deconstructor
                bestDistFactor = distFactor
            end
            ::continue::
        end
    return closestDeconstructor
end, Hook['HookMethodType'].Before)

-- Fight Intruders: Prevent attacking any handcuffed people, regardless of being knocked down
Hook.Patch(SBAI.GetNamespace()..".PreventAttackingHandcuffed", "Barotrauma.AIObjectiveFightIntruders", "IsValidTarget", {"Barotrauma.Character"}, function(_, ptable)
    return ptable.ReturnValue and not ptable["target"].IsHandcuffed
end, Hook['HookMethodType'].After)

-- Operate Weapons: Prevent attacking handcuffed people
Hook.Patch(SBAI.GetNamespace()..".PreventAttackingHandcuffed", "Barotrauma.AIObjectiveCombat", "GetPriority", function(instance, _)
    if instance.Enemy.IsHandcuffed then return 0 end
end, Hook['HookMethodType'].Before)

table.remove(SBAI.Namespace)