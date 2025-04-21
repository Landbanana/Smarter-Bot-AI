local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Inventory"], "slots")

---@type table<string,number>
local talentRanges = setmetatable({}, {
    ---@param t table<string,number>
    ---@param k string
    ---@return number
    __index=function(t, k)
        local prefab = TalentPrefab.TalentPrefabs[Identifier(k)]

        if prefab then
            local configElement = prefab.ConfigElement
            
            for abilityGroupEffect in configElement.GetChildElements("AbilityGroupEffect") do
                
                if  abilityGroupEffect and
                    abilityGroupEffect.GetAttributeString("abilityeffecttype") == "OnUseRangedWeapon"
                then
                    local abilities = abilityGroupEffect.GetChildElement("Abilities")
                    if abilities then
                        local applyStatusEffectsAllies = abilities.GetChildElement("CharacterAbilityApplyStatusEffectsToAllies")
                        
                        if applyStatusEffectsAllies then
                            t[k] = applyStatusEffectsAllies.GetAttributeFloat("maxdistance", Single(util.UnregisteredStaticDescriptors["System.Single"].Static.MaxValue))
                            return t[k]
                        end
                    end
                end
            end
        end
        error("Unable to find maxdistance for talent: "..k, 2)
    end
})

---@type table<Barotrauma.Character,{instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self), timer:Types.Timer?}>
local allCharacterData
local instrumentData = {
    ["accordion"]={InvSlotType.LeftHand+InvSlotType.RightHand},
    ["bikehorn"]={InvSlotType.LeftHand, InvSlotType.RightHand},
    ["guitar"]={InvSlotType.LeftHand+InvSlotType.RightHand},
    ["harmonica"]={InvSlotType.LeftHand+InvSlotType.RightHand}
}
local instrumentTalentData = {
    SteadyTune={
        afflictionId="psychosisimmunity",
        validInstruments={"harmonica"}
    },
    InspiringTunes={
        afflictionId="inspiringtunes",
        validInstruments={"accordion", "bikehorn", "guitar", "harmonica"},

    }
}
local instrumentTalentEnabled = false
local anyStopAfterBuffed = false
local playInstruments

do
    local Aim = InputType.Aim
    local Shoot = InputType.Shoot

    local FindItem = util.FindItem
    local GenerateIdPredicate = util.GenerateIdPredicate
    local HasSimpleAccess = util.HasSimpleAccess
    local ValsContain = util.ValsContain

    ---@param self Types.Module
    ---@param character Barotrauma.Character
    ---@param instrumentIds string[]
    function playInstruments(self, character, instrumentIds)
        local characterData = allCharacterData[character]
        local instance = character.AIController.objectiveManager.CurrentObjective --[[@type Barotrauma.AIObjective]]

        if instance ~= characterData.lastObjective then
            characterData.lastObjective = instance
            instance.Deselected.add(
            function()
                return characterData:Reset()
            end)
        end

        local instrument = characterData.instrument
        local inventory = character.Inventory
        
        if  not (
                instrument and
                HasSimpleAccess(character, instrument)
            )
        then
            characterData.instrument = FindItem(character, inventory.FindAllItems(), nil, nil, GenerateIdPredicate(instrumentIds))
        end

        if  instrument and (
                ValsContain(character.HeldItems, instrument) or
                inventory.TryPutItem(instrument, character, instrumentData[instrument.Prefab.Identifier.Value], true, false)
            )
        then
            character.SetInput(Aim, false, true)
            character.SetInput(Shoot, false, true)
        else
            characterData.isPlaying = false
        end
    end
end

local generateWanderPatch

do
    local Distance = Vector2.Distance

    function generateWanderPatch(self, talentId, stopAfterBuffed)
        if stopAfterBuffed then
            anyStopAfterBuffed = true

            ---@param instance Barotrauma.AIObjectiveIdle
            ---@param ptable Barotrauma.LuaCsHook.ParameterTable
            return function(instance, ptable)
                local character = instance.character
                local characterData = allCharacterData[character]

                if character.HasTalent(talentId) then
                    if characterData.timer:Update(ptable["deltaTime"]) then
                        local startPos = character.WorldPosition
                        local range = talentRanges[talentId]
                        local foundUnbuffed = false

                        for crewmate in Character.GetFriendlyCrew(character) do
                            if not crewmate.CharacterHealth.GetAffliction(instrumentTalentData[talentId].afflictionId, false) and
                                Distance(startPos, crewmate.WorldPosition) <= range
                            then
                                foundUnbuffed = true
                                break
                            end
                        end
                        if foundUnbuffed then
                            characterData.isPlaying = true
                        else
                            characterData:Reset()
                        end
                    end
                    if characterData.isPlaying then
                        playInstruments(self, character, instrumentTalentData[talentId].validInstruments)
                    end
                end
            end
        else
            ---@param instance Barotrauma.AIObjectiveIdle
            ---@param ptable Barotrauma.LuaCsHook.ParameterTable
            return function(instance, ptable)
                local character = instance.character
                local characterData = allCharacterData[character]
        
                if character.HasTalent(talentId) then
                    characterData.isPlaying = true
                    playInstruments(self, character, instrumentTalentData[talentId].validInstruments)
                end
            end
        end
    end
end

---@param self Types.Module
---@param options table
local function activateAssistant(self, options)
    local talentId = "InspiringTunes"
    local suboptions = options[talentId]

    if suboptions.enable then
        instrumentTalentEnabled = true
        
        -- do
        --     local i = 0

        --     for instrument in instrumentTalentData[talentId].validInstruments do --[[@cast instrument string]]
        --         if not suboptions[util.CapFirstLetter(instrument)] then
        --             instrumentTalentData[talentId].validInstruments[i] = nil
        --         else
        --             i = i + 1
        --         end
        --     end
        -- end

        -- if #instrumentTalentData[talentId].validInstruments <= 0 then return end

        self:AddPatch("Barotrauma.AIObjectiveIdle", "Wander", nil,
        generateWanderPatch(self, talentId, suboptions["StopAfterBuffed"]), Hook.HookMethodType.Before)
    end
end

---@param self Types.Module
---@param options table
local function activateCaptain(self, options)
    local talentId = "SteadyTune"
    local suboptions = options[talentId]
    
    if suboptions.enable then
        instrumentTalentEnabled = true

        self:AddPatch("Barotrauma.AIObjectiveIdle", "Wander", nil,
        generateWanderPatch(self, talentId, suboptions["StopAfterBuffed"]), Hook.HookMethodType.Before)
    end
end

-- ---@param self Types.Module
-- ---@param options table
-- local function activateEngineer(self, options)
    
-- end

---@param self Types.Module
local function activate(self)
    

    ---@type table<string,fun(self:Types.Module, options:table)>
    local jobMap = {
        Assistant=activateAssistant,
        Captain=activateCaptain--,
        -- Engineer=activateEngineer
    }

    for job, jobActivate in pairs(jobMap) do
        local sectionOptions = self.options[job]

        if sectionOptions.enable then
            self.namespace = self.namespace + job
            jobActivate(self, sectionOptions)
            self.namespace = -self.namespace
        end
    end

    if instrumentTalentEnabled then
        ---@param t table<Barotrauma.Character,{instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self)}>
        ---@param k Barotrauma.Character
        ---@return table<Barotrauma.Character,{instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self)}>
        local function characterDataIndex(t, k)
            t[k] = {
                isPlaying=false,
                ---@public
                Reset=function(self)
                    self.isPlaying = false
                    self.lastObjective = nil
                end
            }
            return t[k]
        end

        if anyStopAfterBuffed then
            local baseCharacterDataIndex = characterDataIndex
            local buffCheckDelay = self.options["timeBetween"] --[[@type number]]

            local Timer = Types.Timer
            
            ---@param t table<Barotrauma.Character,{instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self), ["timer"]:Types.Timer}>
            ---@param k Barotrauma.Character
            ---@return table<Barotrauma.Character,{instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self), ["timer"]:Types.Timer}>
            characterDataIndex = function(t, k)
                t[k] = baseCharacterDataIndex(t, k)

                t[k].timer = Timer.new(buffCheckDelay)
                return t[k]
            end

            
        end

        ---@type table<Barotrauma.Character,{instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self), ["timer"]:Types.Timer?}>
        allCharacterData = setmetatable(self:RegisterTable("ROUND_END", "CHARACTER_DEATH"), {
            __index = characterDataIndex
        })

        self:AddPatch("Barotrauma.AIObjectiveIdle", "get_AllowAutomaticItemUnequipping", nil,
        function(instance, ptable)
            local character = instance.character
            local characterData = rawget(allCharacterData, character) --[[@type {instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self)}?]]

            if characterData then
                local instrument = characterData.instrument

                if  instrument and
                    characterData.isPlaying
                then
                    ptable.PreventExecution = true
                    return false
                end
            end
        end, Hook.HookMethodType.Before)
    end
end

return Types.Module.new(activate)