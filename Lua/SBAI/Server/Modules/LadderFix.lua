local SBAI = require("SBAI")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.SteeringManager"], "host")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.IndoorsSteeringManager"], "host")

---@param namespace Namespace
---@param options table
return function(namespace, options)
    ---@type table<Barotrauma.Character,Types.Timer>
    local characterData = setmetatable({}, {
        ---@param t table<Barotrauma.Character,Types.Timer>
        ---@param k Barotrauma.Character
        __index=function(t, k)
            t[k] = Types.Timer.new(options["timeBetween"], 0)
            return t[k]
        end}
    )

    util.RegisterClear(characterData, util.CLEAR_REG.ROUND_END + util.CLEAR_REG.CHARACTER_DEATH)

    local Distance = Vector2.Distance

    SBAI.Hook.Patch(namespace(), "Barotrauma.IndoorsSteeringManager", "Update",
    ---@param instance Barotrauma.IndoorsSteeringManager
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function(instance, ptable)
        local controller = instance.host --[[@type Barotrauma.HumanAIController]]
        local character = controller.Character --[[@type Barotrauma.Character]]
        local characterDataInstance = characterData[character]

        if  character.SpeciesName == "Human" and
            characterDataInstance:Update(1)
        then
            if  instance.GetCurrentLadder() and
                character.IsClimbing and
                controller.Steering.Length() > 1
            then
                local oldSimPos = characterDataInstance["simPos"] --[[@type Microsoft.Xna.Framework.Vector2]]
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
                                    characterDataInstance["simPos"] = nil
                                    currentPath.SkipToNode(potentialIndex)
                                    break
                                end
                            end
                        end
                    else
                        characterDataInstance["simPos"] = nil
                    end
                    characterDataInstance:Reset()
                else
                    characterDataInstance["simPos"] = simPos
                end
            else
                characterDataInstance["simPos"] = nil
            end
        end
    end, Hook.HookMethodType.Before)
end