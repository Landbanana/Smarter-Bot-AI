local SBAIUtils = require("SBAI.SBAIUtils")

-- Deconstruct Items: Deconstruct only within the sub if deconstructor is within sub, with optimized calls to get all deconstructors in map
local namespace, _ = SBAIUtils.CheckOptionGetNamespace("UseShipDeconstructorIfAvailable")
if not namespace then return end

local ItemGroup = require("SBAI.Server.ItemGroup")

LuaUserData.RegisterType("Barotrauma.AIObjectiveDeconstructItem")
ItemGroup.Register("deconstructor")

local playerSubmarineHasDeconstructor = nil
Hook.Add("roundEnd", namespace, function()
    -- bought a new sub, some mod adds deployable deconstructors, etc.
    playerSubmarineHasDeconstructor = nil --[[@type boolean|nil]]
end)

Hook.Patch(namespace, "Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor",
function(instance, ptable)
    local deconstructor --[[@type Barotrauma.Items.Components.Deconstructor]]
    local closestDeconstructor = nil --[[@type Barotrauma.Items.Components.Deconstructor|nil]]
    local bestDistFactor = 0.0 --[[@type System.Single]]
    local distFactor --[[@type System.Single]]

    ptable.PreventExecution = true

    if playerSubmarineHasDeconstructor == nil then
        local i, deconstructorItem = next(ItemGroup.List["deconstructor"], nil)

        while i and not playerSubmarineHasDeconstructor do
            playerSubmarineHasDeconstructor = deconstructorItem.InPlayerSubmarine
            i, deconstructorItem = next(ItemGroup.List["deconstructor"], i)
        end
    end

    for _, deconstructorItem in ipairs(ItemGroup.List["deconstructor"]) do
        if deconstructorItem == nil then goto continue end
        if playerSubmarineHasDeconstructor and not deconstructorItem.InPlayerSubmarine then goto continue end
        deconstructor = deconstructorItem.GetComponent(Components.Deconstructor) --[[@type Barotrauma.Items.Components.Deconstructor]]
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
end, Hook["HookMethodType"].Before)