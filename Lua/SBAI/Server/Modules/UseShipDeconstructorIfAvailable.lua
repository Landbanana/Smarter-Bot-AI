local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.RegisterType("Barotrauma.AIObjectiveDeconstructItem")

---@class Barotrauma.AIObjectiveDeconstructItem: Barotrauma.AIObjective
---@field Item Barotrauma.Item

---@param self Types.Module
local function activate(self)
    
    local Deconstructor = Components.Deconstructor
    local Submarine = Submarine

    local GetClosest = util.GetClosest
    local FindItems = util.FindItems
    local PoweredItemHasNeededPower = util.PoweredItemHasNeededPower

    local playerDeconstructors = self:RegisterTable(nil, "ROUND_END") --[=[@type {n:number, list:Barotrauma.Item[]}]=]

    setmetatable(playerDeconstructors, {
    ---@param t table
    ---@param k string
    ---@return Barotrauma.Item[]
    __index=function(t, k)
        if k == "list" or k == "n" then
            local list = {}
            local i = 0

            for deconstructor in FindItems(nil, Submarine.MainSub.GetItems(true), nil, nil,
            function(_, j)
                return j.GetComponent(Deconstructor) ~= nil
            end) do
                i = i + 1
                list[i] = deconstructor
            end

            t.n = i
            t.list = list
            return t[k]
        end
    end})

    local anyDeconOrder

    do
        local Character = Character
        local deconObj = LuaUserData.CreateStatic("Barotrauma.AIObjectiveDeconstructItem")

        ---@return number
        function anyDeconOrder()
            for character in Character.CharacterList do --[[@cast character Barotrauma.Character]]
                if  character.IsHuman and
                    character.IsBot and
                    character.IsOnPlayerTeam and
                    character.AIController.objectiveManager.HasOrder(deconObj)
                then
                    return playerDeconstructors.n
                end
            end
        end
    end

    self:AddHook("roundStart", anyDeconOrder)
    
    self:AddPatch("Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor", nil,
    function(instance, ptable)
        local character = instance.character
        
        if  playerDeconstructors.n > 0 and
            character.IsOnPlayerTeam
        then
            ---@type Barotrauma.Item
            local closestDeconItem = GetClosest(character.WorldPosition, FindItems(nil, playerDeconstructors.list, nil, nil,
            function(_, i)
                return i.GetComponent(Deconstructor).InputContainer.Inventory.CanBePut(instance.Item) and
                    i.HasAccess(character) and
                    PoweredItemHasNeededPower(i)
            end))

            ptable.PreventExecution = true
            
            return closestDeconItem and closestDeconItem.GetComponent(Deconstructor) or nil
        end
    end, Hook.HookMethodType.Before)

    return anyDeconOrder()
end

return Types.Module.new(activate)