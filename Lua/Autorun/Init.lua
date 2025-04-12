SBAI = require("SBAI")

if SERVER or Game.IsSingleplayer then
    SBAI.Control.Activate()
end

if CLIENT or Game.IsSingleplayer then
    Activate = require("SBAI.Client.configGui")

    Activate(SBAI.namespace, SBAI.Config.data)
end

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.AIObjectiveManager"], "character")

Hook.Patch("test", "Barotrauma.AIObjectiveManager", "CreateAutonomousObjectives",
---@param instance Barotrauma.AIObjectiveManager
---@param ptable Barotrauma.LuaCsHook.ParameterTable
function(instance, ptable)
    print(instance.character.Name)
end, Hook.HookMethodType.Before)