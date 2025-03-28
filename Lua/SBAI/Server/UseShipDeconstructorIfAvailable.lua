local SBAI = require("SBAI")

local descriptor = SBAI.LuaUserData.RegisterType("Barotrauma.AIObjectiveDeconstructItem")
SBAI.LuaUserData.MakePropertyAccessible(descriptor, "AllowInFriendlySubs")

---@param namespace Namespace
---@param options table
return function(namespace, options)
    local playerSubmarineHasNoDeconstructor = nil

    -- bought a new sub, some mod adds deployable deconstructors, etc.
    SBAI.Hook.Add("roundEnd", namespace(), function()
        playerSubmarineHasNoDeconstructor = nil --[[@type boolean|nil]]
    end)

    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveDeconstructItem", "get_AllowInFriendlySubs",
    ---@param instance Barotrauma.AIObjective
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function(instance, ptable)
        ptable.PreventExecution = true

        if playerSubmarineHasNoDeconstructor == nil then
            playerSubmarineHasNoDeconstructor = util.FindItem(nil, Item.ItemList, "deconstructor", nil,
            function(character, item)
                return item.InPlayerSubmarine
            end) ~= nil
        end
        
        return playerSubmarineHasNoDeconstructor
    end, Hook.HookMethodType.Before)

    -- SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor",
    -- function(instance, ptable)
    --     local deconstructor --[[@type Barotrauma.Items.Components.Deconstructor]]
    --     local closestDeconstructor = nil --[[@type Barotrauma.Items.Components.Deconstructor|nil]]
    --     local bestDistFactor = 0.0 --[[@type System.Single]]
    --     local distFactor --[[@type System.Single]]

    --     ptable.PreventExecution = true

    --     if playerSubmarineHasDeconstructor == nil then
    --         local i, deconstructorItem = next(SBAI.itemGroup["deconstructor"], nil)

    --         while i and not playerSubmarineHasDeconstructor do
    --             playerSubmarineHasDeconstructor = deconstructorItem.InPlayerSubmarine
    --             i, deconstructorItem = next(SBAI.itemGroup["deconstructor"], i)
    --         end
    --     end

    --     for _, deconstructorItem in ipairs(SBAI.itemGroup["deconstructor"]) do
    --         if deconstructorItem == nil then goto continue end
    --         if playerSubmarineHasDeconstructor and not deconstructorItem.InPlayerSubmarine then goto continue end
    --         deconstructor = deconstructorItem.GetComponent(Components.Deconstructor) --[[@type Barotrauma.Items.Components.Deconstructor]]
    --         if not deconstructor.InputContainer.Inventory.CanBePut(instance.Item) then goto continue end
    --         if not deconstructorItem.HasAccess(instance.character) then goto continue end

    --         distFactor = AIObjective.GetDistanceFactor(instance.Item.WorldPosition, deconstructorItem.WorldPosition, 0.2)
    --         if distFactor > bestDistFactor then
    --             closestDeconstructor = deconstructor
    --             bestDistFactor = distFactor
    --         end
    --         ::continue::
    --     end
    --     return closestDeconstructor
    -- end, Hook.HookMethodType.Before)
end