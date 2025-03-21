local SBAIUtils = require("SBAI.SBAIUtils")

-- Operate Weapons: Prevent attacking handcuffed people
local Namespace, _ = SBAIUtils.CheckOptionGetNamespace("PreventAttackingHandcuffed")
if not Namespace then return end

Hook.Patch(Namespace, "Barotrauma.AIObjectiveCombat", "GetPriority",
function(instance, _)
    if instance.Enemy.IsHandcuffed then return 0 end
end, Hook["HookMethodType"].Before)