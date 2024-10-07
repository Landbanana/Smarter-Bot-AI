SBAI.DeconstructorList = {}
SBAI.PetList = {}

-- Create a list of pets to help with AIObjectiveCleanupItems
function SBAI.GeneratePetList()
	SBAI.PetList = {}
    for i, character in ipairs(Character.CharacterList) do
        if character.IsPet then
			print(character.Name)
			table.insert(SBAI.PetList, character)
		end
    end
end

-- Same as vanilla AIObjectiveDeconstructItem.FindDeconstructor, but prevents outside deconstructors from being used if the sub has a deconstructor
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

-- Generate list of pets at round start
Hook.Add("roundStart", "SBAI.GeneratePetListRoundStart", SBAI.GeneratePetList)

-- Generate list of pets after script load
Hook.Add("loaded", "SBAI.GeneratePetListLoaded", SBAI.GeneratePetList)