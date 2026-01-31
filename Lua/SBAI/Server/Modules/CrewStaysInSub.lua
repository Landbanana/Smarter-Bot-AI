return Types.Module(
function(self, config)
    self:addPatch("Barotrauma.Level", "ShouldSpawnCrewInsideOutpost", nil, "Before",
    function(instance, ptable)
        ptable.PreventExecution = true
        return false
    end)
end)