SBAI.DeconstructorList = {}

-- reset SBAI.DeconstructorList at the start of every round, just in case
Hook.Add("roundStart", "SBAI.EmptyDeconstructorList", function()
    SBAI.DeconstructorList = {}
end)

-- same as vanilla AIObjectiveDeconstructItem.FindDeconstructor, but prevents outside deconstructors from being used if the sub has a deconstructor
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