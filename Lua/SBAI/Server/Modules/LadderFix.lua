local Types = require("SBAI.Shared.types")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.SteeringManager"], "host")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.IndoorsSteeringManager"], "host")

---@param self Types.Module
local function activate(self)
    local Distance = Vector2.Distance

    local allCharacterData = Types.AllTimedCharacterData.new(self)

    self:AddPatch("Barotrauma.IndoorsSteeringManager", "Update", nil,
    function(instance, ptable)
        local controller = instance.host --[[@type Barotrauma.HumanAIController]]
        local character = controller.Character --[[@type Barotrauma.Character]]

        if  character.CanClimb then
            local characterData = allCharacterData:Get(character)

            if characterData:UpdateClock() then
                if  instance.GetCurrentLadder() and
                    character.IsClimbing and
                    controller.Steering.Length() > 1
                then
                    local oldSimPos = characterData.simPos --[[@type Microsoft.Xna.Framework.Vector2]]
                    local simPos = controller.SimPosition --[[@type Microsoft.Xna.Framework.Vector2]]

                    if oldSimPos then
                        if Distance(simPos, oldSimPos) < 0.01 then
                            local currentPath = instance.CurrentPath
                    
                            if  currentPath and
                                not currentPath.IsAtEndNode and
                                not currentPath.Unreachable
                            then
                                local currentIndex = currentPath.CurrentIndex
                                local nodes = currentPath.Nodes

                                for potentialIndex in {currentIndex > 0 and currentIndex - 1 or nil, currentIndex + 1} do
                                    local potentialNode = nodes[potentialIndex + 1]

                                    if  potentialNode.IsTraversable and (
                                            not potentialNode.ConnectedDoor or
                                            potentialNode.ConnectedDoor.HasAccess(character)
                                        )
                                    then
                                        characterData.simPos = nil
                                        currentPath.SkipToNode(potentialIndex)
                                        break
                                    end
                                end
                            end
                        else
                            characterData.simPos = nil
                        end
                        characterData:Reset()
                    else
                        characterData.simPos = simPos
                    end
                else
                    characterData.simPos = nil
                end
            end
        end
    end, Hook.HookMethodType.Before)
end

return Types.Module.new(activate)