local SBAI = require("SBAI")

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.HumanAIController"], "CalculateHullSafety",
{"Barotrauma.Hull", "System.Collections.Generic.IEnumerable`1[[Barotrauma.Hull]]", "Barotrauma.Character", "System.Boolean", "System.Boolean", "System.Boolean", "System.Boolean", "System.Boolean"})

return function(namespace, options)
    SBAI.Hook.Patch("FindSafetyTest", "Barotrauma.HumanAIController", "CalculateHullSafety",
    {"Barotrauma.Hull", "System.Collections.Generic.IEnumerable`1[[Barotrauma.Hull]]", "Barotrauma.Character", "System.Boolean", "System.Boolean", "System.Boolean", "System.Boolean", "System.Boolean"},
    ---@param instance Barotrauma.HumanAIController
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    function(instance, ptable)
        if ptable["character"].IsProtectedFromPressure then ptable["ignoreWater"] = true end
    end, Hook.HookMethodType.Before)
end