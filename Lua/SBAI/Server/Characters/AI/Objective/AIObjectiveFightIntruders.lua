local SBAIUtils = require("SBAI.SBAIUtils")

-- Fight Intruders: Prevent attacking any handcuffed people, regardless of being knocked down
local namespace, _ = SBAIUtils.CheckOptionGetNamespace("PreventAttackingHandcuffed")
if not namespace then return end

Hook.Patch(namespace, "Barotrauma.AIObjectiveFightIntruders", "IsValidTarget", {"Barotrauma.Character"},
function(_, ptable)
    return ptable.ReturnValue and not ptable["target"].IsHandcuffed
end, Hook["HookMethodType"].After)