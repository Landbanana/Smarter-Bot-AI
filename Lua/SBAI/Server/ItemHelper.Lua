SBAI.DeconstructorList = {}

function SBAI.GenerateDeconstructorList()
    -- vanilla part
    local playerSubmarineHasDeconstructor = false
    local tempDeconstructorList = {}

    for i, otherItem in ipairs(Item.RepairableItems) do
        local potentialDeconstructor = otherItem.GetComponentString("Deconstructor")
        if potentialDeconstructor == nil then goto continue end
        if potentialDeconstructor.InputContainer == nil then goto continue end
        playerSubmarineHasDeconstructor = playerSubmarineHasDeconstructor or potentialDeconstructor.Item.InPlayerSubmarine
        table.insert(tempDeconstructorList, potentialDeconstructor)
        ::continue::
    end

    -- InPlayerSubmarine check
    if playerSubmarineHasDeconstructor then
        for i, potentialDeconstructorItem in ipairs(tempDeconstructorList) do
            if not potentialDeconstructorItem.Item.InPlayerSubmarine then
                tempDeconstructorList[i] = nil
            end
        end
    end

    SBAI.DeconstructorList = tempDeconstructorList
end

-- Reset SBAI.DeconstructorList
Hook.Add("roundStart", "SBAI.ResetDeconstructorListRoundStart", function()
    SBAI.DeconstructorList = {}
end)