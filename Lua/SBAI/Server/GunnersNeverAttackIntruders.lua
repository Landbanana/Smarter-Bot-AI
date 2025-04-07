local SBAI = require("SBAI")

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.HumanAIController"], "IsBotInTheCrew")

return function(namespace, options)
    local onlyIfNoOtherBotsFightingIntruders = options["OnlyIfNoOtherBotsFightingIntruders"] --[[@type boolean]]

    local function CrewHasBotSetFightIntruders(character)
        local aiController = character.AIController

        for _, otherCharacter in ipairs(Character.CharacterList) do
            if  otherCharacter and
                aiController.IsBotInTheCrew(character, otherCharacter)
            then
                local otherOrder = otherCharacter.AIController.objectiveManager.CurrentOrder

                if  otherOrder and
                    otherOrder.Identifier == "fightintruders" and
                    otherCharacter.IsIncapacitated == false and
                    otherCharacter.LockHands == false and
                    otherCharacter.HasEquippedItem("weapon", false)
                then
                    return true
                end
            end
        end
        return false
    end

    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveCombat", "GetPriority",
    ---@param instance Barotrauma.AIObjectiveCombat
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function(instance, ptable)
        local character = instance.character
        local order = character.AIController.objectiveManager.CurrentOrder --[[@type Barotrauma.Order]]
        
        if  order and
            order.Identifier == "operateweapons" and
            not onlyIfNoOtherBotsFightingIntruders or CrewHasBotSetFightIntruders(character)
        then
            ptable.PreventExecution = true
            return 0
        end
    end, Hook.HookMethodType.Before)
end