local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

do
    local MakeFieldAccessible = LuaUserData.MakeFieldAccessible
    local MakeMethodAccessible = LuaUserData.MakeMethodAccessible
    local MakePropertyAccessible = LuaUserData.MakePropertyAccessible
    local AutoRegisterType = util.AutoRegisterType
    local Descriptors = Descriptors
    local descriptor

    AutoRegisterType("Barotrauma.TalentStatIdentifier")

    ---@class Barotrauma.TalentStatIdentifier
    ---@field Stat Barotrauma.TalenItemStats
    ---@field TalentIdentifier Barotrauma.Identifier
    ---@field UniqueCharacterId System.UInt32
    ---@field Save System.Boolean

    descriptor =  Descriptors["Barotrauma.AIObjectiveCombat"]
    MakeFieldAccessible(descriptor, "CloseDistance")
    MakeMethodAccessible(descriptor, "IsEnemyClose")

    ---@class Barotrauma.AIObjectiveCombat
    ---@field CloseDistance System.Single

    MakeFieldAccessible(Descriptors["Barotrauma.Inventory"], "slots")
    
    MakeFieldAccessible(AutoRegisterType("Barotrauma.ItemStatManager"), "talentStats")

    ---@class Barotrauma.ItemStatManager
    ---@field talentStats System.Collections.Generic.Dictionary*1Barotrauma*TalentStatIdentifier*1System*Single
    
    descriptor = Descriptors["Barotrauma.AIObjectiveGoTo"]
    MakePropertyAccessible(descriptor, "PathSteering")
    MakePropertyAccessible(descriptor, "SteeringManager")

    MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveGetItem"], "Act")
end

local activateInstrumentTalent

do
    local allCharacterInstrumentData --[[@type Types.AllTimedCharacterData]]
    local allInstrumentTalentData --[[@type {[Barotrauma.Identifier]:{afflictionId:Barotrauma.Identifier, allowSelf:boolean, maxDistance:number, validInstruments:Set<Barotrauma.Identifier>}}>]]
    local allInstrumentObjectiveData

    local anyNeedBuff

    do
        local Character = Character
        local Distance = Vector2.Distance

        ---@param afflictionId Barotrauma.Identifier
        ---@param maxDistance number
        ---@param allowSelf boolean
        ---@param character Barotrauma.Character
        function anyNeedBuff(afflictionId, maxDistance, allowSelf, character)
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
            return foundUnbuffed
        end
    end

    local function instrumentSetup(self)
        self:AddCommonModule("SBAI.Server.CommonModules.PerformInstruments")
        self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")
        
        local Aim = InputType.Aim
        local Identifier = Identifier
        local ItemPrefab = ItemPrefab
        local MAX_FLOAT = Constants.MAX_FLOAT
        local PERFORM = Constants.ID_OBJECTIVE.PERFORM
        local Shoot = InputType.Shoot
        local TalentPrefab = TalentPrefab
        local traitorMissionItemId = Identifier("traitormissionitem")

        local Contains = util.itertools.Contains
        local xPath = util.xPath

        allCharacterInstrumentData = Types.AllTimedCharacterData.new(self)

        ---@type {[Barotrauma.Identifier]:{afflictionId:Barotrauma.Identifier, allowSelf:boolean, maxDistance:number, validInstruments:Set<Barotrauma.Identifier>}}
        allInstrumentTalentData = setmetatable({}, {
            ---@param t {[Barotrauma.Identifier]:{afflictionId:Barotrauma.Identifier, allowSelf:boolean, maxDistance:number, validInstruments:Set<Barotrauma.Identifier>}}
            ---@param k Barotrauma.Identifier
            __index=function(t, k)
                local prefab = TalentPrefab.TalentPrefabs[k]

                if not prefab then error("Unable to find talentPrefab: "..tostring(k), 2) end
                local configElement = prefab.ConfigElement --[[@type Barotrauma.ContentXElement]]
                local abilityConditionItem = xPath(configElement, "AbilityGroupEffect[@abilityeffecttype=OnUseRangedWeapon]/Conditions/AbilityConditionItem")[1]
                local characterAbilityApplyStatusEffectsToAllies = xPath(configElement, "AbilityGroupEffect[@abilityeffecttype=OnUseRangedWeapon]/Abilities/CharacterAbilityApplyStatusEffectsToAllies")[1]
                local afflictionId = xPath(characterAbilityApplyStatusEffectsToAllies, "StatusEffects/StatusEffect/Affliction[@identifier]")[1].GetAttributeIdentifier("identifier")
                if not afflictionId then error("Unable to find afflictions for talent: "..tostring(k), 2) end
                
                local instrumentIds = Types.Set.new()

                do
                    local ids = abilityConditionItem.GetAttributeIdentifierArray("identifiers")

                    if ids then
                        instrumentIds:Update(ids)
                    end
                end
                
                if instrumentIds:IsEmpty() then
                    local tags = abilityConditionItem.GetAttributeIdentifierArray("tags")
                    
                    for prefab in ItemPrefab.Prefabs do
                        for tag in tags do --[[@cast tag Barotrauma.Identifier]]
                            if  Contains(prefab.Tags, tag) and
                                not Contains(prefab.Tags, traitorMissionItemId)
                            then
                                instrumentIds:Add(prefab.Identifier)
                                break
                            end
                        end
                    end
                end
                if instrumentIds:IsEmpty() then error("Unable to find instruments for talent: "..tostring(k), 2) end
                local maxDistance = characterAbilityApplyStatusEffectsToAllies.GetAttributeFloat("maxdistance", MAX_FLOAT)
                local allowSelf = characterAbilityApplyStatusEffectsToAllies.GetAttributeBool("allowself", true)

                local out = {afflictionId=afflictionId, allowSelf=allowSelf, maxDistance=maxDistance, validInstruments=instrumentIds}

                t[Identifier(k)] = out
                return out
            end
        })

        allInstrumentObjectiveData = {
            ["idle"]={
                fullTypeName="Barotrauma.AIObjectiveIdle",
                prePatch=util.True
            },
            ["wait"]={
                fullTypeName="Barotrauma.AIObjectiveGoTo",
                prePatch=util.IsAtWaitObjective
            }
        }

        self:AddPatch("Barotrauma.Item", "TryInteract", nil,
        function(instance, ptable)
            local character = ptable["user"] --[[@type Barotrauma.Character]]

            if  character.IsHuman and
                character.IsBot
            then
                local curObjective = character.AIController.objectiveManager.CurrentObjective --[[@type Barotrauma.AIObjective]]
                
                if curObjective then
                    local curSubObjective = curObjective.CurrentSubObjective

                    if  curSubObjective and
                        curSubObjective.Identifier == PERFORM
                    then
                        character.ClearInput(Aim)
                        character.ClearInput(Shoot)
                    end
                end
            end
        end, Hook.HookMethodType.Before)
    end

    ---@param self Types.Module
    ---@param options table
    function activateInstrumentTalent(self, options)
        if not allCharacterInstrumentData then instrumentSetup(self) end
        
        local AIObjectiveGetItem = AIObjectiveGetItem
        local AIObjectiveOperateItem = AIObjectiveOperateItem
        local GET_ITEM = Constants.ID_OBJECTIVE_BASE.GETITEM
        local PERFORM = Constants.ID_OBJECTIVE.PERFORM
        local RangedWeapon = Components.RangedWeapon
        local WAIT = Constants.ID_OBJECTIVE_BASE.WAIT

        local Any = util.itertools.Any
        local Distance = Vector2.Distance
        local GetItemPrefab = ItemPrefab.GetItemPrefab
        local Partial3 = util.functools.Partial3
        local Partial5 = util.functools.Partial5

        local stopAfterBuffed = options["stopAfterBuffed"] --[[@type boolean]]
        local talentId = Identifier(self.namespace.stack[#self.namespace.stack])
        local afflictionId --[[@type Barotrauma.Identifier]]
        local allowSelf --[[@type boolean]]
        local maxDistance --[[@type number]]
        local validInstruments --[[@type Set<Barotrauma.Identifier>]]

        do
            local instrumentTalentData = allInstrumentTalentData[talentId]

            afflictionId = instrumentTalentData.afflictionId
            allowSelf = instrumentTalentData.allowSelf
            maxDistance = instrumentTalentData.maxDistance
            validInstruments = instrumentTalentData.validInstruments
        end

        ---@param objective Barotrauma.AIObjectiveGetItem
        ---@return boolean
        local function abortWaitGetItem(objective)
            local item = objective.TargetItem

            if  item and
                Distance(item.WorldPosition, objective.character.WorldPosition) > objective.MaxReach
            then
                return true
            end
            return false
        end

        for objectiveName, objectiveData in next, allInstrumentObjectiveData do
            local prePatch
            local anyNeedBuffFull

            if not self.options[objectiveName] then goto continue end

            prePatch = objectiveData.prePatch
            anyNeedBuffFull = Partial3(anyNeedBuff, afflictionId, maxDistance, allowSelf)

            self:AddPatch(objectiveData.fullTypeName, "Act", nil,
            ---@param instance Barotrauma.AIObjective
            ---@param ptable Barotrauma.LuaCsHook.ParameterTable
            function(instance, ptable)
                local character = instance.character --[[@type Barotrauma.Character]]
                
                if character.HasTalent(talentId) then
                    local characterData = allCharacterInstrumentData:Get(character)
                    --local curSubObjective = instance.CurrentSubObjective --[[@type Barotrauma.AIObjective]]
                    
                    if  characterData:Update(ptable["deltaTime"]) and
                        prePatch(instance)
                    then
                        local inventory = character.Inventory
                        local instrument = characterData.instrument or
                            inventory:SBAI_findAllItems(nil, true, function(item) return validInstruments[item.Prefab.Identifier] end)()
                        
                        if  not instrument and
                            Any(validInstruments:ToList(), function(id) inventory.CanProbablyBePut(GetItemPrefab(id)) end)
                        then
                            local function constructor()
                                local objective = AIObjectiveGetItem(character, validInstruments, instance.objectiveManager, true, true)

                                objective.AllowDangerousPressure = false
                                objective.AllowToFindDivingGear = false
                                objective.AllowStealing = false
                                objective.AllowVariants = true

                                if instance.Identifier == WAIT then
                                    objective.AbortCondition = abortWaitGetItem
                                end

                                local cleanup = Partial3(instance.SBAI_cleanupSubObj, instance, objective, AIObjectiveGetItem)
                                
                                objective.Completed.add(function()
                                    characterData.instrument = objective.TargetItem
                                    return cleanup()
                                end)
                                objective.Abandoned.add(function()
                                    return cleanup(characterData, "instrument")
                                end)
                                return objective
                            end
                            ptable.PreventExecution = instance:SBAI_tryAddSubObjective(nil, nil, GET_ITEM, false, true, constructor)
                        else
                            local function constructor()
                                local objective = AIObjectiveOperateItem(instrument.GetComponent(RangedWeapon), character, instance.objectiveManager, instrument.Prefab.Identifier, true)

                                objective.Identifier = PERFORM

                                local cleanup = Partial5(instance.SBAI_cleanupSubObj, instance, objective, AIObjectiveOperateItem, characterData, "performObjective")

                                objective.Completed.add(cleanup)
                                objective.Abandoned.add(cleanup)
                                return objective
                            end
                            
                            ptable.PreventExecution = instance:SBAI_tryAddSubObjective(characterData, "performObjective", PERFORM, true, false, ((not stopAfterBuffed) or anyNeedBuffFull(character)) and constructor or nil)
                        end
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
    local appliedStun = Constants.D_NONTHREATENING_STUN
    local talentId = Identifier(self.namespace.stack[#self.namespace.stack])

    local minHealh = options["minHealh"] --[[@type number]]

    self:AddPatch("Barotrauma.AIObjectiveCombat", "Act", nil,
    function(instance, ptable)
        local character = instance.character

        if  character.HasTalent(talentId) and
            not (character.Stun > 0) and
            not character.Params.Health.StunImmunity and
            instance.IsEnemyClose(instance.CloseDistance) and
            character.HealthPercentage < minHealh
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
    local AIObjectiveGoTo = AIObjectiveGoTo
    local Character = Character
    local GOTO = Constants.ID_OBJECTIVE_BASE.GOTO
    local Holdable = Components.Holdable
    local ItemContainer = Components.ItemContainer
    local Wearable = Components.Wearable
    local Submarine = Submarine

    local Any = util.itertools.Any
    local FindItems = util.FindItems
    local GetClosest = util.GetClosest

    local talentId = Identifier(self.namespace.stack[#self.namespace.stack])
    local untouchedContainers = Types.Set.new(self:RegisterTable(nil, "ROUND_END"))
    local allCharacterData = Types.AllTimedCharacterData.new(self, options["timeBetween"])

    self:AddInit(
    function()
        if Any(Character.CharacterList,
            function(character)
                return character.IsHuman and
                    character.IsBot and
                    character.IsOnPlayerTeam and
                    character.HasTalent(talentId)
            end)
        then
            for item in Submarine.MainSub.GetItems(true) do --[[@cast item Barotrauma.Item]]
                local container = item.GetComponent(ItemContainer) --[[@type Barotrauma.Items.Components.ItemContainer]]

                if  container and
                    not item.GetComponent(Holdable) and
                    not item.GetComponent(Wearable)
                then
                    for k in next, item.StatManager.talentStats do
                        if k.TalentIdentifier == talentId then
                            goto continue
                        end
                    end
                    local containableIds = container.ContainableItemIdentifiers
                        
                    if  containableIds.Contains("smallitem") and
                        containableIds.Contains("mediumitem")
                    then
                        untouchedContainers:Add(item)
                    end
                end
                ::continue::
            end
        end
    end)

    self:AddPatch("Barotrauma.AIObjectiveIdle", "Wander", nil,
    function(instance, ptable)
        local character = instance.character

        if  not untouchedContainers:IsEmpty() and
            character.HasTalent(talentId) and
            character.IsOnPlayerTeam
        then
            local characterData = allCharacterData:Get(character)
            
            if  characterData:Update(ptable["deltaTime"]) and
                not characterData.goToObj
            then
                local closestContainer = GetClosest(character.WorldPosition, FindItems(character, untouchedContainers:ToList())) --[[@type Barotrauma.Item]]

                if closestContainer then
                    ---@return Barotrauma.AIObjectiveGoTo
                    ---@nodiscard
                    local function constructor()
                        local objective = AIObjectiveGoTo(closestContainer, character, instance.objectiveManager, false, false, 1, 50.0)

                        objective.DebugLogWhenFails = false
                        objective.AllowGoingOutside = false
                        objective.SpeakIfFails = false

                        local function cleanup()
                            characterData.goToObj = nil
                            instance.RemoveSubObjective(AIObjectiveGoTo, objective)
                        end

                        objective.Completed.add(
                        function()
                            if character.CanInteractWith(closestContainer) then
                                untouchedContainers:Remove(closestContainer)
                                character.SelectedItem = closestContainer
                                objective.SteeringManager.Reset()
                                objective.PathSteering.ResetPath()
                            end
                            return cleanup()
                        end)
                        objective.Abandoned.add(cleanup)
                        return objective
                    end
                    
                    ptable.PreventExecution = instance:SBAI_tryAddSubObjective(characterData, "goToObj", GOTO, false, true, constructor)
                end
            end
        end
    end, Hook.HookMethodType.Before)
end

---@param self Types.Module
local function activateAssistant(self)
    self:DoOption("InspiringTunes", Assistant.InspiringTunes)
    self:DoOption("NonThreatening", Assistant.NonThreatening)
    self:DoOption("JengaMaster", Assistant.JengaMaster)
end

local Captain = {}

Captain.SteadyTune = activateInstrumentTalent

---@param self Types.Module
local function activateCaptain(self)
    self:DoOption("SteadyTune", Captain.SteadyTune)
end

local Engineer = {}

Engineer.MelodicRespite = activateInstrumentTalent

---@param self Types.Module
local function activateEngineer(self)
    self:DoOption("MelodicRespite", Engineer.MelodicRespite)
end

---@param self Types.Module
local function activate(self)
    self:DoOption("Assistant", activateAssistant)
    self:DoOption("Captain", activateCaptain)
    self:DoOption("Engineer", activateEngineer)
end

return Types.Module.new(activate)