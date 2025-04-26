local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

do
    local descriptor = Descriptors["Barotrauma.Inventory"]

    LuaUserData.MakeFieldAccessible(descriptor, "slots")

    descriptor = Descriptors["Barotrauma.AIObjectiveCombat"]
    LuaUserData.MakeMethodAccessible(descriptor, "IsEnemyClose")
    LuaUserData.MakeFieldAccessible(descriptor, "CloseDistance")

    ---@class Barotrauma.AIObjectiveCombat
    ---@field CloseDistance System.Single

    LuaUserData.RegisterType("Barotrauma.TalentStatIdentifier")
    
    ---@class Barotrauma.TalentStatIdentifier
    ---@field Stat Barotrauma.TalenItemStats
    ---@field TalentIdentifier Barotrauma.Identifier
    ---@field UniqueCharacterId System.UInt32
    ---@field Save System.Boolean

    LuaUserData.MakeFieldAccessible(LuaUserData.RegisterType("Barotrauma.ItemStatManager"), "talentStats")

    ---@class Barotrauma.ItemStatManager
    ---@field talentStats System.Collections.Generic.Dictionary*1Barotrauma*TalentStatIdentifier*1System*Single
    
    descriptor = Descriptors["Barotrauma.AIObjectiveGoTo"]
    LuaUserData.MakePropertyAccessible(descriptor, "PathSteering")
    LuaUserData.MakePropertyAccessible(descriptor, "SteeringManager")
end

local allTalentRanges --[[@type table<Barotrauma.Identifier,{maxDistance:number, allowSelf:boolean}>]]

do
    local MAX_FLOAT = Constants.MAX_FLOAT
    local TalentPrefab = TalentPrefab

    ---@type table<Barotrauma.Identifier,{maxDistance:number, allowSelf:boolean}>
    allTalentRanges = setmetatable({}, {
        ---@param t table<Barotrauma.Identifier,{maxDistance:number, allowSelf:boolean}>
        ---@param k Barotrauma.Identifier
        ---@return number
        __index=function(t, k)
            local prefab = TalentPrefab.TalentPrefabs[k]

            if prefab then
                local configElement = prefab.ConfigElement
                
                for abilityGroupEffect in configElement.GetChildElements("AbilityGroupEffect") do
                    if abilityGroupEffect.GetAttributeString("abilityeffecttype") == "OnUseRangedWeapon" then
                        for applyStatusEffect in abilityGroupEffect.Element.Descendants("CharacterAbilityApplyStatusEffectsToAllies") do
                            t[k] = {
                                maxDistance=applyStatusEffect.GetAttributeFloat("maxdistance", MAX_FLOAT),
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


local isInstrumentsInit = false
local activateInstrumentTalent

do
    ---@class UseTalents.allCharacterInstrumentData: Types.TimedCharacterData
    ---@field private [Barotrauma.Character] {timer:Types.Timer, isPlaying:boolean, instrument:Barotrauma.Item?, lastObjective:Barotrauma.AIObjective?}
    ---@field public Get fun(self:UseTalents.allCharacterInstrumentData, character:Barotrauma.Character):{timer:Types.Timer, isPlaying:boolean, instrument:Barotrauma.Item?, lastObjective:Barotrauma.AIObjective?}
    local allCharacterInstrumentData
    local allInstrumentTalentData --[[@type table<Barotrauma.Identifier,{afflictionId:Barotrauma.Identifier, validInstruments:Barotrauma.Identifier[]}>]]
    local instrumentData --[[@type {[Barotrauma.Identifier]:{slotTypes:Barotrauma.InvSlotType[]}}]]

    local initInstruments
    local playInstruments
    local shouldOnlyBuff

    do
        local Contains = util.itertools.Contains
        local ItemPrefab = ItemPrefab
        local TalentPrefab = TalentPrefab
    
        ---@type {[Barotrauma.Identifier]:{afflictionId:Barotrauma.Identifier, validInstruments:Barotrauma.Identifier[]}}
        allInstrumentTalentData = setmetatable({}, {
            ---@param t {[Barotrauma.Identifier]:{afflictionId:Barotrauma.Identifier, validInstruments:Barotrauma.Identifier[]}}
            ---@param k Barotrauma.Identifier
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
    
                                            if not Contains(prefabTags, "traitormissionitem") then
                                                for tag in tags do
                                                    if Contains(prefabTags, tag) then
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

    do
        ---@type {[Barotrauma.Identifier]:{slotTypes:Barotrauma.InvSlotType[]}}
        instrumentData = setmetatable({}, {
            ---@param t {[Barotrauma.Identifier]:{slotTypes:Barotrauma.InvSlotType[]}}
            ---@param k Barotrauma.Identifier
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
    end

    do
        local Add
        local Reset

        do
            local oldAdd = Types.TimedCharacterData.Add --[[@type fun(self:Types.TimedCharacterData, character:Barotrauma.Character)]]
            
            ---@param self UseTalents.allCharacterInstrumentData
            ---@param character Barotrauma.Character
            function Add(self, character)
                oldAdd(self, character)
                self[character].isPlaying = false
            end
        end
    
        do
            local Aim = InputType.Aim
            local Shoot = InputType.Shoot
            
            ---@param self UseTalents.allCharacterInstrumentData
            ---@param character Barotrauma.Character
            function Reset(self, character)
                local t = self[character]
        
                t.isPlaying = false
                t.lastObjective = nil
                character.ClearInput(Aim)
                character.ClearInput(Shoot)
                character.TryPutItemInAnySlot(t.instrument)
            end
        end

        ---@param self Types.Module
        function initInstruments(self)
            if isInstrumentsInit then return end
            isInstrumentsInit = true

            allCharacterInstrumentData = Types.TimedCharacterData.new(self, nil, {Add=Add, Reset=Reset}) --[[@cast allCharacterInstrumentData UseTalents.allCharacterInstrumentData]]

            self:AddPatch("Barotrauma.Item", "TryInteract", nil,
            function(instance, ptable)
                local character = ptable["user"] --[[@type Barotrauma.Character]]
                local characterData = allCharacterInstrumentData[character]
                
                if  characterData and
                    characterData.isPlaying
                then
                    allCharacterInstrumentData:Reset(character)
                end
            end, Hook.HookMethodType.Before)

            if self.options["idle"] then
                self:AddPatch("Barotrauma.AIObjectiveIdle", "get_AllowAutomaticItemUnequipping", nil,
                function(instance, ptable)
                    local character = instance.character
                    local characterData = allCharacterInstrumentData[character]

                    if  characterData and
                        characterData.isPlaying
                    then
                        ptable.PreventExecution = true
                        return false
                    end
                end, Hook.HookMethodType.Before)
            end
        end
    end

    do
        local RangedWeapon = Components.RangedWeapon
        local Aim = InputType.Aim
        local Shoot = InputType.Shoot
    
        local FindItem = util.FindItem
        local GenerateIdPredicate = util.GenerateIdPredicate
        local HasSimpleAccess = util.HasSimpleAccess
        local Contains = util.itertools.Contains
    
        ---@param instrumentIds Barotrauma.Identifier[]
        ---@param instance Barotrauma.AIObjective
        ---@param character Barotrauma.Character
        ---@param characterData {timer:Types.Timer, isPlaying:boolean, instrument:Barotrauma.Item?, lastObjective:Barotrauma.AIObjective?}
        function playInstruments(instrumentIds, instance, character, characterData)
            if instance ~= characterData.lastObjective then
                characterData.lastObjective = instance
                instance.Deselected.add(
                function()
                    return allCharacterInstrumentData:Reset(character)
                end)
            end
    
            local instrument = characterData.instrument
            local inventory = character.Inventory
            
            if  not (
                    instrument and
                    HasSimpleAccess(character, instrument)
                )
            then
                instrument = FindItem(character, inventory.GetAllItems(true), nil, nil, GenerateIdPredicate(instrumentIds))
                
                characterData.instrument = instrument
            end
            
            if  instrument and (
                    Contains(character.HeldItems, instrument) or
                    inventory.TryPutItem(instrument, character, instrumentData[instrument.Prefab.Identifier].slotTypes, true, false)
                )
            then
                if  instrument.HasTag("hornitem") and
                    instrument.GetComponent(RangedWeapon).WasUsed
                then
                    return allCharacterInstrumentData:Reset(character)
                end
    
                characterData.isPlaying = true
                character.SetInput(Aim, false, true)
                character.SetInput(Shoot, false, true)
            else
                
                return allCharacterInstrumentData:Reset(character)
            end
        end
    end

    do
        local Character = Character
        local Distance = Vector2.Distance

        ---@param afflictionId Barotrauma.Identifier
        ---@param maxDistance number
        ---@param allowSelf boolean
        ---@param validInstruments Barotrauma.Item[]
        ---@param instance Barotrauma.AIObjective
        ---@param character Barotrauma.Character
        ---@param characterData {timer:Types.Timer, isPlaying:boolean, instrument:Barotrauma.Item?, lastObjective:Barotrauma.AIObjective?}
        function shouldOnlyBuff(afflictionId, maxDistance, allowSelf, validInstruments, instance, character, characterData)
            local startPos = character.WorldPosition
            local foundUnbuffed = false
            
            for crewmate in Character.GetFriendlyCrew(character) do
                if  not allowSelf and
                    crewmate == character
                then
                    goto continue
                end

                if  not crewmate.CharacterHealth.GetAffliction(afflictionId, false) and
                    Distance(startPos, crewmate.WorldPosition) <= maxDistance
                then
                    foundUnbuffed = true
                    break
                end
                ::continue::
            end
            
            if foundUnbuffed then
                return playInstruments(validInstruments, instance, character, characterData)
            else
                return allCharacterInstrumentData:Reset(character)
            end
        end
    end

    ---@param self Types.Module
    ---@param options table
    function activateInstrumentTalent(self, options)
        local talentId = Identifier(self.namespace.stack[#self.namespace.stack])
        local afflictionId
        local validInstruments
        local maxDistance
        local allowSelf
        local allInstrumentObjData = {
            ["idle"]={
                fullTypeName="Barotrauma.AIObjectiveIdle",
                prePatch=util.True
            },
            ["wait"]={
                fullTypeName="Barotrauma.AIObjectiveGoTo",
                prePatch=util.IsWaitObjective
            }
        }

        do
            local instrumentTalentData = allInstrumentTalentData[talentId]
            local range = allTalentRanges[talentId]

            afflictionId = instrumentTalentData.afflictionId
            validInstruments = instrumentTalentData.validInstruments
            maxDistance = range.maxDistance
            allowSelf = range.allowSelf
        end

        initInstruments(self)
        
        ---@type fun(character:Barotrauma.Character, instance:Barotrauma.AIObjective, characterData:{timer:Types.Timer, isPlaying:boolean, instrument:Barotrauma.Item?, lastObjective:Barotrauma.AIObjective?})
        local tryPlayInstrument = options["stopAfterBuffed"] and
        util.functools.Partial4(shouldOnlyBuff, afflictionId, maxDistance, allowSelf, validInstruments) or
        util.functools.Partial1(playInstruments, validInstruments)

        for objName, objData in next, allInstrumentObjData do
            if not self.options[objName] then goto continue end

            self:AddPatch(objData.fullTypeName, "Act", nil,
            function(instance, ptable)
                local character = instance.character
                
                if  character.HasTalent(talentId) then
                    
                    local characterData = allCharacterInstrumentData:Get(character)
                
                    if  characterData.timer:Update(ptable["deltaTime"]) and
                        objData.prePatch(instance)
                    then
                        return tryPlayInstrument(instance, character, characterData)
                    end
                    if characterData.isPlaying then
                        playInstruments(validInstruments, instance, character, characterData)
                    end
                end
            end, Hook.HookMethodType.Before)

            ::continue::
        end
    end
end

local Assistant = {}

Assistant.InspiringTunes = activateInstrumentTalent

---@param self Types.Module
---@param options table
function Assistant.NonThreatening(self, options)
    local talentId = Identifier(self.namespace.stack[#self.namespace.stack])
    local ragdollHealthPercent = options["ragdollHealthPercent"] --[[@type number]]
    local appliedStun = Constants.D_NONTHREATENING_STUN

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
end

---@param self Types.Module
---@param options table
function Assistant.JengaMaster(self, options)
    local talentId = Identifier(self.namespace.stack[#self.namespace.stack])
    local untouchedContainers = self:RegisterTable(nil, "ROUND_END") --[[@type {set:Types.Set}]]
    local allCharacterData = Types.TimedCharacterData.new(self, options["timeBetween"])

    local containerNotTouched
    local anyJengaMasters

    function containerNotTouched(container)
        for k in next, container.StatManager.talentStats do
            if k.TalentIdentifier == talentId then
                return false
            end
        end
        return true
    end

    do
        local Holdable = Components.Holdable
        local ItemContainer = Components.ItemContainer
        local Wearable = Components.Wearable
        local Submarine = Submarine

        local FindItems = util.FindItems
        local new = Types.Set.new

        setmetatable(untouchedContainers, {
            ---@param t table
            ---@return Set
            __call=function(t)
                if not t.set then
                    local set = new()

                    for containerItem in FindItems(nil, Submarine.MainSub.GetItems(true), "Container", nil,
                    function (_, item)
                        if not item.GetComponent(Holdable) and
                            not item.GetComponent(Wearable) and
                            containerNotTouched(item)
                        then
                            local container = item.GetComponent(ItemContainer) --[[@type Barotrauma.Items.Components.ItemContainer]]

                            if container then
                                local containableIds = container.ContainableItemIdentifiers
                                
                                if  containableIds.Contains("smallitem") and
                                    containableIds.Contains("mediumitem")
                                then
                                    return true
                                end
                            end
                        end
                        return false
                    end) do
                        set:Add(containerItem)
                    end
                    t.set = (not set:IsEmpty()) and set or nil
                end
                return t.set
            end
        })
    end

    do
        local Character = Character
        
        function anyJengaMasters()
            for character in Character.CharacterList do --[[@cast character Barotrauma.Character]]
                if  character.IsHuman and
                    character.IsBot and
                    character.IsOnPlayerTeam and
                    character.HasTalent(talentId)
                then
                    return untouchedContainers()
                end
            end
        end
    end

    self:AddHook("roundStart", anyJengaMasters)

    do
        local AIObjectiveGoTo = AIObjectiveGoTo

        local FindItems = util.FindItems
        local GetClosest = util.GetClosest
        local TryAddSubObjective = util.TryAddSubObjective

        self:AddPatch("Barotrauma.AIObjectiveIdle", "Wander", nil,
        function(instance, ptable)
            local character = instance.character
            local set = untouchedContainers.set

            if  set and
                not set:IsEmpty() and
                character.HasTalent(talentId) and
                character.IsOnPlayerTeam
            then
                local characterData = allCharacterData:Get(character)
                
                if  not characterData["goToObj"] and
                    characterData.timer:Update(ptable["deltaTime"])
                then
                    local closestContainer = GetClosest(character.WorldPosition, FindItems(character, set:ToList())) --[[@type Barotrauma.Item]]

                    if closestContainer then
                        ---@return Barotrauma.AIObjectiveGoTo
                        ---@nodiscard
                        local function constructor()
                            local objective = AIObjectiveGoTo(closestContainer, character, instance.objectiveManager, false, false, 1, 50.0)
                            
                            objective.SpeakIfFails = false
                            objective.DebugLogWhenFails = false
                            objective.AllowGoingOutside = false
                            return objective
                        end
                        ---@param objective Barotrauma.AIObjectiveGoTo
                        ---@return fun()
                        local function onCompletedGenerator(objective)
                            ---@type fun()
                            local function onCompleted()
                                if  set and
                                    not set:IsEmpty() and
                                    character.CanInteractWith(closestContainer) and
                                    containerNotTouched(closestContainer)
                                then
                                    character.SelectedItem = closestContainer

                                    if not containerNotTouched(closestContainer) then
                                        set:Remove(closestContainer)
                                    end
                                    objective.SteeringManager.Reset()
                                    objective.PathSteering.ResetPath()
                                end
                                characterData["goToObj"] = nil
                                instance.RemoveSubObjective(AIObjectiveGoTo, objective)
                            end
                            return onCompleted
                        end

                        ---@param objective Barotrauma.AIObjectiveGoTo
                        ---@return fun()
                        local function onAbandonGenerator(objective)
                            ---@type fun()
                            local function onAbandon()
                                characterData["goToObj"] = nil
                                instance.RemoveSubObjective(AIObjectiveGoTo, objective)
                            end
                            return onAbandon
                        end

                        local goToObj --[[@type Barotrauma.AIObjectiveGoTo]]

                        for objective in instance.subObjectives do --[[@cast objective Barotrauma.AIObjective]]
                            if objective.Identifier == talentId then
                                goToObj = objective
                                break
                            end
                        end
                        
                        _, characterData["goToObj"] = TryAddSubObjective(instance, goToObj, constructor, onCompletedGenerator, onAbandonGenerator)
                    end
                end
            end
        end, Hook.HookMethodType.Before)
    end
    anyJengaMasters()
end

---@param self Types.Module
---@param options table
local function activateAssistant(self, options)
    self:DoOption("InspiringTunes", Assistant.InspiringTunes)
    self:DoOption("NonThreatening", Assistant.NonThreatening)
    self:DoOption("JengaMaster", Assistant.JengaMaster)
end

local Captain = {}

Captain.SteadyTune = activateInstrumentTalent

---@param self Types.Module
---@param options table
local function activateCaptain(self, options)
    self:DoOption("SteadyTune", Captain.SteadyTune)
end

---@param self Types.Module
local function activate(self)
    self:DoOption("Assistant", activateAssistant)
    self:DoOption("Captain", activateCaptain)
end

local function deactivate(self)
    isInstrumentsInit = false
end

return Types.Module.new(activate, deactivate)