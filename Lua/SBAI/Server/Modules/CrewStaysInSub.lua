local SBAI = require("SBAI")

return function(namespace, _)
    SBAI.Hook.Patch(namespace(), "Barotrauma.Level", "ShouldSpawnCrewInsideOutpost",
    ---@param _ Barotrauma.Level
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function (_, ptable)
        ptable.PreventExecution = true
        
        return false
    end, Hook.HookMethodType.Before)
end