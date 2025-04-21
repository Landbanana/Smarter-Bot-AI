local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.RegisterType("Barotrauma.AIObjectiveDeconstructItem")

---@class Barotrauma.AIObjectiveDeconstructItem: Barotrauma.AIObjective
---@field Item Barotrauma.Item

---@param self Types.Module
local function activate(self)
    local Deconstructor = Components.Deconstructor

    local GetClosest = util.GetClosest
    local FindItems = util.FindItems
    local PoweredItemHasNeededPower = util.PoweredItemHasNeededPower

    local deconData = setmetatable(self:RegisterTable("ROUND_END"), {
        ---@param t table
        ---@return Barotrauma.Item[]
        __call=function(t)
            if not t.data then
                t.data = FindItems(nil, Item.ItemList, nil, nil,
                function(_, i)
                    return i.InPlayerSubmarine and
                        i.GetComponent(Deconstructor) ~= nil
                end)
            end
            return t.data
        end
    })
    
    self:AddPatch("Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor", nil,
    function(instance, ptable)
        local character = instance.character
        local playerSubDecons = deconData() --[=[@type Barotrauma.Item[]]=]
        
        if  #playerSubDecons > 0 and
            character.IsOnPlayerTeam
        then
            ---@type Barotrauma.Item
            local closestDeconItem = GetClosest(character.WorldPosition, FindItems(nil, playerSubDecons, nil, nil,
            function(_, i)
                return i.GetComponent(Deconstructor).InputContainer.Inventory.CanBePut(instance.Item) and
                    i.HasAccess(character) and
                    PoweredItemHasNeededPower(i)
            end)) 

            ptable.PreventExecution = true
            
            return closestDeconItem and closestDeconItem.GetComponent(Deconstructor) or nil
        end
    end, Hook.HookMethodType.Before)
end

return Types.Module.new(activate)