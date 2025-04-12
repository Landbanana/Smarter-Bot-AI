local SBAI = require("SBAI")
local util = require("SBAI.Shared.util")

LuaUserData.RegisterType("Barotrauma.AIObjectiveDeconstructItem")

---@class Barotrauma.AIObjectiveDeconstructItem: Barotrauma.AIObjective
---@field Item Barotrauma.Item

---@param namespace Namespace
---@param options table
return function(namespace, options)
    local deconstructorData = util.RoundEndTemp:Add(namespace()) --[=[@type Barotrauma.Item[]?]=]

    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor",
    ---@param instance Barotrauma.AIObjectiveDeconstructItem
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    ---@return Barotrauma.Item
    function(instance, ptable)
        local character = instance.character

        if not deconstructorData["playerSubmarineDeconstructors"] then
            deconstructorData["playerSubmarineDeconstructors"] = {}
            local i = 0

            for item in Item.ItemList do --[[@cast item Barotrauma.Item]]
                if  item ~= nil and
                    item.GetComponent(Components.Deconstructor) ~= nil and
                    item.InPlayerSubmarine
                then
                    i = i + 1
                    deconstructorData["playerSubmarineDeconstructors"][i] = item
                end
            end
        end

        if #deconstructorData["playerSubmarineDeconstructors"] > 0 then
            local closestDeconstructorItem = util.GetClosest(character.WorldPosition, util.FindItems(nil, deconstructorData["playerSubmarineDeconstructors"], nil, nil,
            function(_, i)
                return i.GetComponent(Components.Deconstructor).InputContainer.Inventory.CanBePut(instance.Item) and
                    i.HasAccess(character)
            end))

            ptable.PreventExecution = true

            return closestDeconstructorItem and closestDeconstructorItem.GetComponent(Components.Deconstructor) or nil
        end
    end, Hook.HookMethodType.Before)
end