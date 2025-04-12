local SBAI = require("SBAI")
local util = require("SBAI.Shared.util")

local LuaUserData = LuaUserData
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.SteeringManager"], "host")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.IndoorsSteeringManager"], "host")

local Vector2 = Vector2

local stuckData = setmetatable({}, {__index=function(t, k) t[k] = {timer=0}; return t[k] end})

return function(namespace, options)
    local timeBetween = options.timeBetween

    SBAI.Hook.Add("character.death", namespace(),
    ---@param character Barotrauma.Character
    function(character)
        stuckData[character] = nil
    end)

    SBAI.Hook.Add("roundEnd", namespace(),
    function()
        util.ClearTable(stuckData)
    end)

    SBAI.Hook.Patch(namespace(), "Barotrauma.IndoorsSteeringManager", "Update",
    ---@param instance Barotrauma.IndoorsSteeringManager
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function(instance, ptable)
        local controller = instance.host --[[@type Barotrauma.HumanAIController]]
        local character = controller.Character --[[@type Barotrauma.Character]]
        local stuckDataInstance = stuckData[character]

        if  character.SpeciesName == "Human" and
            stuckDataInstance.timer <= 0
        then
            if  instance.GetCurrentLadder() and
                character.IsClimbing and
                controller.Steering.Length() > 1
            then
                local oldSimPos = stuckDataInstance.simPos --[[@type Microsoft.Xna.Framework.Vector2]]
                local simPos = controller.SimPosition --[[@type Microsoft.Xna.Framework.Vector2]]

                if oldSimPos then
                    if Vector2.Distance(simPos, oldSimPos) < 0.01 then
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
                                    stuckDataInstance.simPos = nil
                                    currentPath.SkipToNode(potentialIndex)
                                    break
                                end
                            end
                        end
                    else
                        stuckDataInstance.simPos = nil
                    end
                    stuckDataInstance.timer = timeBetween
                else
                    stuckDataInstance.simPos = simPos
                end
            else
                stuckDataInstance.simPos = nil
            end
        else
            stuckDataInstance.timer = stuckData[character].timer - 1
        end
    end, Hook.HookMethodType.Before)
end,
function()
    util.ClearTable(stuckData)
end