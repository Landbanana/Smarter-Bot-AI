local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

do
    local descriptor = Descriptors["Barotrauma.Inventory"]

    LuaUserData.MakeFieldAccessible(descriptor, "slots")

    descriptor = Descriptors["Barotrauma.AIObjectiveCombat"]
    LuaUserData.MakeFieldAccessible(descriptor, "CloseDistance")

    ---@class Barotrauma.AIObjectiveCombat
    ---@field CloseDistance System.Single
end

local allTalentRanges

do
    local MaxValueSingle = Single(util.UnregisteredStaticDescriptors["System.Single"].Static.MaxValue)

    ---@type table<string,{maxDistance:number, allowSelf:boolean}>
    allTalentRanges = setmetatable({}, {
        ---@param t table<string,{maxDistance:number, allowSelf:boolean}>
        ---@param k string
        ---@return number
        __index=function(t, k)
            local prefab = TalentPrefab.TalentPrefabs[k]

            if prefab then
                local configElement = prefab.ConfigElement
                
                for abilityGroupEffect in configElement.GetChildElements("AbilityGroupEffect") do
                    if abilityGroupEffect.GetAttributeString("abilityeffecttype") == "OnUseRangedWeapon" then
                        for applyStatusEffect in abilityGroupEffect.Element.Descendants("CharacterAbilityApplyStatusEffectsToAllies") do
                            t[k] = {
                                maxDistance=applyStatusEffect.GetAttributeFloat("maxdistance", MaxValueSingle),
                                allowSelf=applyStatusEffect.GetAttributeBool("allowself", true)
                            }
                            return t[k]
                        end
                        
                    end
                end
            end
            error("Unable to find talent: "..k, 2)
        end
    })
end

---@type table<Barotrauma.Character,{instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self), timer:Types.Timer?}>
local allCharacterData
local allInstrumentTalentData

local ---@type {[string]:{slotTypes:Barotrauma.InvSlotType[]}}
instrumentData = setmetatable({}, {
    ---@param t {[string]:{slotTypes:Barotrauma.InvSlotType[]}}
    ---@param k string
    __index=function(t, k)
        local prefab = ItemPrefab.Prefabs[k]

        if prefab then
            local holdable = prefab.ConfigElement.GetChildElement("Holdable")
        
            if holdable then
                local slotString = holdable.GetAttributeString("slots")
                
                if slotString then
                    local allowedSlots = {}
                    local i = 0
        
                    for slotCombination in slotString:gmatch("([^,]+),?") do
                        if slotCombination:lower() ~= "any" then
                            local slots = 0
        
                            i = i + 1
                            for specSlotString in slotCombination:gmatch("([^%+]+)%+?") do
                                specSlotString = specSlotString:match("(%a+)")
                                
                                if specSlotString:lower() == "bothhands" then
                                    slots = InvSlotType.LeftHand + InvSlotType.RightHand
                                end
        
                                slots = slots + InvSlotType[specSlotString]
                            end
                            allowedSlots[i] = slots
                        end
                    end
                    if i > 0 then
                        t[k] = {slotTypes=allowedSlots}
                        return t[k]
                    end
                end
            end
        end
        error("Unable to find instrument: "..k, 2)
    end
})

do
    local ValsContain = util.itertools.ValsContain
    local ItemPrefab = ItemPrefab

    ---@type {[string]:{afflictionId:Barotrauma.Identifier, validInstruments:Barotrauma.Identifier[]}}
    allInstrumentTalentData = setmetatable({}, {
        ---@param t {[string]:{afflictionId:Barotrauma.Identifier, validInstruments:Barotrauma.Identifier[]}}
        ---@param k string
        __index=function(t, k)
            local prefab = TalentPrefab.TalentPrefabs[k]

            if prefab then
                local configElement = prefab.ConfigElement
                
                for abilityGroupEffect in configElement.GetChildElements("AbilityGroupEffect") do
                    if abilityGroupEffect.GetAttributeString("abilityeffecttype") == "OnUseRangedWeapon" then
                        local validInstruments

                        for itemCondition in abilityGroupEffect.Element.Descendants("AbilityConditionItem") do
                            validInstruments = itemCondition.GetAttributeIdentifierArray("identifiers")

                            if not validInstruments then
                                local tags = itemCondition.GetAttributeIdentifierArray("tags")

                                if tags then
                                    local i = 0

                                    validInstruments = {}
                                    for itemPrefab in ItemPrefab.Prefabs do
                                        local prefabTags = itemPrefab.Tags

                                        if not ValsContain(prefabTags, "traitormissionitem") then
                                            for tag in tags do
                                                if ValsContain(prefabTags, tag) then
                                                    i = i + 1
                                                    validInstruments[i] = itemPrefab.Identifier
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        
                        if #validInstruments > 0 then
                            for id in validInstruments do --[[@cast id Barotrauma.Identifier]]
                                local _ = instrumentData[id.Value]
                            end
                            for applyStatusEffect in abilityGroupEffect.Element.Descendants("CharacterAbilityApplyStatusEffectsToAllies") do
                                if applyStatusEffect then
                                    for statusEffect in applyStatusEffect.Descendants("StatusEffect") do
                                        if statusEffect then
                                            local affliction = statusEffect.Element("Affliction")

                                            if affliction then
                                                local id = affliction.GetAttributeIdentifier("identifier")

                                                if id then
                                                    t[k] = {
                                                        afflictionId=id,
                                                        validInstruments=validInstruments
                                                    }
                                                    return t[k]
                                                end
                                            end
                                        end
                                    end

                                end
                            end
                        end
                    end
                end
            end
            error("Unable to find talent: "..k, 2)
        end
    })
end

local instrumentTalentEnabled = false
local playInstruments
local allObjData = {
    ["Idle"]={
        fullTypeName="Barotrauma.AIObjectiveIdle",
        prePatch=util.True
    },
    ["Wait"]={
        fullTypeName="Barotrauma.AIObjectiveGoTo",
        prePatch=util.IsWaitObjective
    }
}

do
    local RangedWeapon = Components.RangedWeapon
    local Aim = InputType.Aim
    local Shoot = InputType.Shoot

    local FindItem = util.FindItem
    local GenerateIdPredicate = util.GenerateIdPredicate
    local HasSimpleAccess = util.HasSimpleAccess
    local ValsContain = util.itertools.ValsContain

    ---@param character Barotrauma.Character
    ---@param instrumentIds string[]
    function playInstruments(character, instrumentIds)
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
            instrument = characterData.instrument
        end

        if  instrument and (
                ValsContain(character.HeldItems, instrument) or
                inventory.TryPutItem(instrument, character, instrumentData[instrument.Prefab.Identifier.Value].slotTypes, true, false)
            )
        then
            if  instrument.HasTag("hornitem") and
                instrument.GetComponent(RangedWeapon).WasUsed
            then
                return characterData:Reset()
            end

            characterData.isPlaying = true
            character.SetInput(Aim, false, true)
            character.SetInput(Shoot, false, true)
        else
            return characterData:Reset()
        end
    end
end

local generatePatch

do
    ---@generic T:Barotrauma.AIObjective
    ---@param talentId string
    ---@param patch fun(character:Barotrauma.Character, characterData:{instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self), ["timer"]:Types.Timer}, ptable:Barotrauma.LuaCsHook.ParameterTable)
    ---@param prePatch fun(instance:T)
    ---@return fun(instance:T, ptable:Barotrauma.LuaCsHook.ParameterTable):MoonSharp.Interpreter.DynValue
    local function prePatcher(talentId, patch, prePatch)
        local validInstruments = allInstrumentTalentData[talentId].validInstruments

        ---@param instance Barotrauma.AIObjective
        ---@param ptable Barotrauma.LuaCsHook.ParameterTable
        return function(instance, ptable)
            local character = instance.character
            
            if character.HasTalent(talentId) then
                local characterData = allCharacterData[character]

                if characterData.timer:Update(ptable["deltaTime"]) then
                    if  not prePatch or
                        prePatch(instance)
                    then
                        return patch(character, characterData)
                    end
                end
                if characterData.isPlaying then
                    playInstruments(character, validInstruments)
                end
            end
        end
    end

    ---@generic T:Barotrauma.AIObjective
    ---@param talentId string
    ---@param stopAfterBuffed boolean
    ---@param prePatch fun(instance:T)
    ---@return fun(instance:T, ptable:Barotrauma.LuaCsHook.ParameterTable):MoonSharp.Interpreter.DynValue
    function generatePatch(talentId, stopAfterBuffed, prePatch)
        local afflictionID
        local validInstruments

        do
            local instrumentTalentData = allInstrumentTalentData[talentId]

            afflictionID = instrumentTalentData.afflictionId
            validInstruments = instrumentTalentData.validInstruments
        end
        
        if stopAfterBuffed then
            
            local Distance = Vector2.Distance

            return prePatcher(talentId,
            ---@param character Barotrauma.Character
            ---@param characterData {instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self), ["timer"]:Types.Timer}
            function(character, characterData)
                local startPos = character.WorldPosition
                local foundUnbuffed = false
                local maxDistance
                local allowSelf
                
                do
                    local range = allTalentRanges[talentId]

                    maxDistance = range.maxDistance
                    allowSelf = range.allowSelf
                end
                
                for crewmate in Character.GetFriendlyCrew(character) do
                    if  not allowSelf and
                        crewmate == character
                    then
                        goto continue
                    end

                    if  not crewmate.CharacterHealth.GetAffliction(afflictionID, false) and
                        Distance(startPos, crewmate.WorldPosition) <= maxDistance
                    then
                        foundUnbuffed = true
                        break
                    end
                    ::continue::
                end
                if foundUnbuffed then
                    return playInstruments(character, validInstruments)
                else
                    return characterData:Reset()
                end
            end, prePatch)
        else
            return prePatcher(talentId,
            ---@param character Barotrauma.Character
            ---@param characterData {instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self), ["timer"]:Types.Timer}
            function(character, characterData)
                return playInstruments(character, validInstruments)
            end, prePatch)
        end
    end
end

---@param self Types.Module
---@param options table
local function activateAssistant(self, options)
    local talentId = "InspiringTunes"
    local suboptions = options[talentId]

    if suboptions.enable then
        self.namespace = self.namespace + talentId
        for objData in allObjData do
            instrumentTalentEnabled = true

            self:AddPatch(objData.fullTypeName, "Act", nil,
            generatePatch(talentId, suboptions["StopAfterBuffed"], objData.prePatch), Hook.HookMethodType.Before)
        end
        self.namespace = -self.namespace
    end
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
    
    talentId = "NonThreatening"
    suboptions = options[talentId]

    if suboptions.enable then
        local ragdollHealthPercent = suboptions["ragdollHealthPercent"] --[[@type number]]
        local appliedStun = Constants.D_NONTHREATENING_STUN
        
        self.namespace = self.namespace + talentId
        
        talentId = talentId:lower()

        self:AddPatch("Barotrauma.AIObjectiveCombat", "Act", nil,
        function(instance, ptable)
            local character = instance.character

            if  character.HasTalent(talentId) and
                not (character.Stun > 0) and
                not character.Params.Health.StunImmunity and
                instance.IsEnemyClose(instance.CloseDistance) and
                character.HealthPercentage < ragdollHealthPercent
            then
                local controller = character.AIController --[[@type Barotrauma.HumanAIController]]
                local curHull = character.CurrentHull
                local needsDivingGear, needsSuit = controller.NeedsDivingGear(curHull, controller.objectiveManager) --[[@type boolean, boolean]]

                if  (not needsDivingGear or
                    controller.HasDivingSuit(character, 0, true, true) or
                    not needsSuit and
                    controller.HasDivingGear(character, 0, true)) and
                    curHull.FireCount <= 0
                then
                    ptable.PreventExecution = true
                    character.Stun = appliedStun
                end
            end
        end, Hook.HookMethodType.Before)
        self.namespace = -self.namespace
    end
end

---@param self Types.Module
---@param options table
local function activateCaptain(self, options)
    local talentId = "SteadyTune"
    local suboptions = options[talentId]
    
    if suboptions.enable then
        self.namespace = self.namespace + talentId
        for objData in allObjData do
            instrumentTalentEnabled = true
                
            self:AddPatch(objData.fullTypeName, "Act", nil,
            generatePatch(talentId, suboptions["StopAfterBuffed"], objData.prePatch), Hook.HookMethodType.Before)
        end
        self.namespace = -self.namespace
    end
end

-- ---@param self Types.Module
-- ---@param options table
-- local function activateEngineer(self, options)
    
-- end

---@param self Types.Module
local function activate(self)
    local jobMap = {
        Assistant=activateAssistant,
        Captain=activateCaptain--,
        -- Engineer=activateEngineer
    }

    do
        local toRemove = {}
        local i = 0

        for k, _ in pairs(allObjData) do
            if not self.options[k] then
                i = i + 1
                toRemove[i] = k
            end
        end

        for k in toRemove do
            allObjData[k] = nil
        end
    end

    for job, jobActivate in pairs(jobMap) do
        local sectionOptions = self.options[job]

        if sectionOptions.enable then
            self.namespace = self.namespace + job
            jobActivate(self, sectionOptions)
            self.namespace = -self.namespace
        end
    end

    if instrumentTalentEnabled then
        local buffCheckDelay = self.options["timeBetween"] --[[@type number]]

        local Timer = Types.Timer
        local Aim = InputType.Aim
        local Shoot = InputType.Shoot

        ---@type table<Barotrauma.Character,{instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self), ["timer"]:Types.Timer}>
        allCharacterData = setmetatable(self:RegisterTable("ROUND_END", "CHARACTER_DEATH"), {
        ---@param t table<Barotrauma.Character,{instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self), ["timer"]:Types.Timer}>
        ---@param k Barotrauma.Character
        ---@return table<Barotrauma.Character,{instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self), ["timer"]:Types.Timer}>
            __index = function(t, k)
                t[k] = {
                    isPlaying=false,
                    ---@public
                    Reset=function(self)
                        self.isPlaying = false
                        self.lastObjective = nil
                        k.ClearInput(Aim)
                        k.ClearInput(Shoot)
                        k.TryPutItemInAnySlot(self.instrument)
                    end,
                    timer=Timer.new(buffCheckDelay)
                }
                return t[k]
            end
        })

        self:AddPatch("Barotrauma.AIObjectiveIdle", "get_AllowAutomaticItemUnequipping", nil,
        function(instance, ptable)
            local character = instance.character
            local characterData = rawget(allCharacterData, character) --[[@type {instrument:Barotrauma.Item?, isPlaying:boolean, lastObjective:Barotrauma.AIObjective, Reset:fun(self)}?]]

            if characterData then
                if characterData.isPlaying then
                    ptable.PreventExecution = true
                    return false
                end
            end
        end, Hook.HookMethodType.Before)
    end
end

return Types.Module.new(activate)