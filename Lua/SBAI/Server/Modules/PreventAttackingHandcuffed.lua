local SBAI = require("SBAI")

---@param namespace Namespace
---@param options table
return function(namespace, options)
    LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.AIObjectiveCombat"], "TargetEliminated")

    -- Operate Weapons: Prevent attacking handcuffed people
    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveCombat", "get_TargetEliminated",
    ---@param instance Barotrauma.AIObjectiveCombat
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    ---@return integer
    function(instance, ptable)
        return ptable.ReturnValue or (instance.character.IsOnPlayerTeam and instance.Enemy.IsHandcuffed)
    end, Hook.HookMethodType.Before)
end