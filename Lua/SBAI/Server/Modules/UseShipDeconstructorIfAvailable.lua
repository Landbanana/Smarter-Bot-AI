local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.RegisterType("Barotrauma.AIObjectiveDeconstructItem")

---@class Barotrauma.AIObjectiveDeconstructItem: Barotrauma.AIObjective
---@field Item Barotrauma.Item

---@param self Types.Module
local function activate(self)
    local Character = Character
    local Deconstructor = Components.Deconstructor
    local Submarine = Submarine

    local Any = util.itertools.Any
    local FindItems = util.FindItems
    local GetClosest = util.GetClosest
    local PoweredItemHasNeededPower = util.PoweredItemHasNeededPower

    local playerDeconData = self:RegisterTable(nil, "ROUND_END") --[=[@type {n:integer?, list:Barotrauma.Item[]?}]=]

    self:AddInit(
    function()
        local AIObjectiveDeconstructItem = self:CreateStatic("Barotrauma.AIObjectiveDeconstructItem")

        if Any(Character.CharacterList,
        function(character)
            return character.IsHuman and
                character.IsBot and
                character.IsOnPlayerTeam and
                character.AIController.objectiveManager.HasOrder(AIObjectiveDeconstructItem)
        end) then
            playerDeconData()
        end
    end)

    setmetatable(playerDeconData, {
    ---@param t {n:integer?, list:Barotrauma.Item[]?}
    ---@return Barotrauma.Item[]
    ---@return integer
    __call=function(t)
        if not t.list then
            local list = {}
            local i = 0

            for deconstructor in FindItems(nil, Submarine.MainSub.GetItems(true), nil, nil,
            function(_, item)
                return item.GetComponent(Deconstructor) ~= nil
            end) do
                i = i + 1
                list[i] = deconstructor
            end

            t.n = i
            t.list = list
        end
        return t.list, t.n
    end})

    self:AddPatch("Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor", nil,
    function(instance, ptable)
        local character = instance.character

        if character.IsOnPlayerTeam then
            local playerDeconList, n = playerDeconData() --[[@type Barotrauma.Item[], integer]]
            
            if n > 0 then
                ---@type Barotrauma.Item
                local closestDeconItem = GetClosest(character.WorldPosition, FindItems(nil, playerDeconList, nil, nil,
                function(_, i)
                    return i.GetComponent(Deconstructor).InputContainer.Inventory.CanBePut(instance.Item) and
                        i.HasAccess(character) and
                        PoweredItemHasNeededPower(i)
                end))

                ptable.PreventExecution = true
                
                return closestDeconItem and closestDeconItem.GetComponent(Deconstructor) or nil
            end
        end
    end, Hook.HookMethodType.Before)
end

return Types.Module.new(activate)