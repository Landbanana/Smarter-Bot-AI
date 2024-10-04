-- Deconstruct only within the sub
Hook.Patch("PrintDeconstructor", "Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor", function(instance, ptable)
    if ptable.ReturnValue and (not ptable.ReturnValue.Item.InPlayerSubmarine) then return nil end
end, Hook.HookMethodType.After)