local SBAI = require("SBAI")

---@param namespace Namespace
---@param options table
return function(namespace, options)
    -- Operate Weapons: Prevent attacking handcuffed people
    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveCombat", "GetPriority",
    ---@param instance Barotrauma.AIObjectiveCombat
    ---@param _ Barotrauma.LuaCsHook.ParameterTable
    ---@return integer
    function(instance, _)
        if instance.Enemy.IsHandcuffed then return 0 end
    end, Hook["HookMethodType"].Before)

    -- Fight Intruders: Prevent attacking any handcuffed people, regardless of being knocked down
    SBAI.Hook.Patch(namespace(), "Barotrauma.AIObjectiveFightIntruders", "IsValidTarget", {"Barotrauma.Character"},
    ---@param _ Barotrauma.AIObjectiveFightIntruders
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    ---@return boolean
    function(_, ptable)
        return ptable.ReturnValue and not ptable["target"].IsHandcuffed
    end, Hook["HookMethodType"].After)
end