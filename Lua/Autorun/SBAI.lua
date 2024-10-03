SBAI = {}

SBAI.Path = ...

-- Deconstruct only within the sub
Hook.Patch("PrintDeconstructor", "Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor", function(instance, ptable)
    if not ptable.ReturnValue.Item.InPlayerSubmarine then return nil end
end, Hook.HookMethodType.After)