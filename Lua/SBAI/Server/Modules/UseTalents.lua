local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

do
    LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Inventory"], "slots")

    local descriptor =  Descriptors["Barotrauma.AIObjectiveCombat"]
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

    LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveGetItem"], "Act")
end

local activateInstrumentTalent

do
    local allCharacterInstrumentData --[[@type Types.TimedCharacterData]]
    local allInstrumentTalentData --[[@type {[Barotrauma.Identifier]:{afflictionId:Barotrauma.Identifier, allowSelf:boolean, maxDistance:number, validInstruments:Barotrauma.Identifier[]}}>]]
    local allInstrumentObjectiveData

    local makeOperateObjective
    local anyNeedBuff

    do
        local AIObjectiveOperateItem = AIObjectiveOperateItem
        local PERFORM = Constants.ID_ORDER.PERFORM

        ---@param character Barotrauma.Character
        ---@param itemComponent Barotrauma.Items.Components.ItemComponent
        ---@param itemId Barotrauma.Identifier
        ---@param objectiveManager Barotrauma.AIObjectiveManager
        ---@return Barotrauma.AIObjectiveOperateItem
        function makeOperateObjective(character, itemComponent, itemId, objectiveManager)
            local objective = AIObjectiveOperateItem(itemComponent, character, objectiveManager, itemId, true)

            objective.Identifier = PERFORM

            return objective
        end
    end

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
        
        local Aim = InputType.Aim
        local Identifier = Identifier
        local ItemPrefab = ItemPrefab
        local MAX_FLOAT = Constants.MAX_FLOAT
        local PERFORM = Constants.ID_ORDER.PERFORM
        local Shoot = InputType.Shoot
        local TalentPrefab = TalentPrefab
        local traitorMissionItemId = Identifier("traitormissionitem")

        local Contains = util.itertools.Contains
        local xPath = util.xPath

        allCharacterInstrumentData = Types.TimedCharacterData.new(self)

        ---@type {[Barotrauma.Identifier]:{afflictionId:Barotrauma.Identifier, allowSelf:boolean, maxDistance:number, validInstruments:Barotrauma.Identifier[]}}
        allInstrumentTalentData = setmetatable({}, {
            ---@param t {[Barotrauma.Identifier]:{afflictionId:Barotrauma.Identifier, allowSelf:boolean, maxDistance:number, validInstruments:Barotrauma.Identifier[]}}
            ---@param k Barotrauma.Identifier
            __index=function(t, k)
                local prefab = TalentPrefab.TalentPrefabs[k]

                if not prefab then error("Unable to find talentPrefab: "..tostring(k), 2) end
                local configElement = prefab.ConfigElement --[[@type Barotrauma.ContentXElement]]
                local abilityConditionItem = xPath(configElement, "AbilityGroupEffect[@abilityeffecttype=OnUseRangedWeapon]/Conditions/AbilityConditionItem")[1]
                local characterAbilityApplyStatusEffectsToAllies = xPath(configElement, "AbilityGroupEffect[@abilityeffecttype=OnUseRangedWeapon]/Abilities/CharacterAbilityApplyStatusEffectsToAllies")[1]
                local afflictionId = xPath(characterAbilityApplyStatusEffectsToAllies, "StatusEffects/StatusEffect/Affliction[@identifier]")[1].GetAttributeIdentifier("identifier")
                if not afflictionId then error("Unable to find afflictions for talent: "..tostring(k), 2) end
                
                local instrumentIds = abilityConditionItem.GetAttributeIdentifierArray("identifiers")
                if not instrumentIds then
                    local tags = abilityConditionItem.GetAttributeIdentifierArray("tags")
                    local i = 0
                    
                    instrumentIds = {}
                    for prefab in ItemPrefab.Prefabs do
                        for tag in tags do --[[@cast tag Barotrauma.Identifier]]
                            if  Contains(prefab.Tags, tag) and
                                not Contains(prefab.Tags, traitorMissionItemId)
                            then
                                i = i + 1
                                instrumentIds[i] = prefab.Identifier
                                break
                            end
                        end
                    end
                end
                if #instrumentIds <= 0 then error("Unable to find instruments for talent: "..tostring(k), 2) end
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

                    if curSubObjective and
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
        local getItemId = Identifier("get item")
        local PERFORM = Constants.ID_ORDER.PERFORM
        local RangedWeapon = Components.RangedWeapon
        local waitId = Identifier("wait")

        local Distance = Vector2.Distance
        local Partial3 = util.functools.Partial3
        local TryAddSubObjective = util.TryAddSubObjective

        local stopAfterBuffed = options["stopAfterBuffed"] --[[@type boolean]]
        local talentId = Identifier(self.namespace.stack[#self.namespace.stack])
        local afflictionId --[[@type Barotrauma.Identifier]]
        local allowSelf --[[@type boolean]]
        local maxDistance --[[@type number]]
        local validInstruments --[=[@type Barotrauma.Identifier[]]=]

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
            function(instance, ptable)
                local character = instance.character --[[@type Barotrauma.Character]]
                
                if  character.HasTalent(talentId) then
                    local characterData = allCharacterInstrumentData:Get(character)
                    local curSubObjective = instance.CurrentSubObjective --[[@type Barotrauma.AIObjective]]
                
                    if  characterData.timer:Update(ptable["deltaTime"]) and
                        prePatch(instance) and
                        not characterData["getItemObjective"] and
                        (not curSubObjective or
                        curSubObjective.Identifier ~= getItemId)
                    then
                        local performObjective = characterData["performObjective"] --[[@type Barotrauma.AIObjectiveOperateItem]]
                        
                        if  not stopAfterBuffed or
                            anyNeedBuffFull(character) or
                            (not performObjective and
                            curSubObjective and
                            curSubObjective.Identifier == PERFORM)
                        then
                            local function constructor()
                                local objective = AIObjectiveGetItem(character, validInstruments, instance.objectiveManager, true, true)

                                objective.AllowDangerousPressure = false
                                objective.AllowToFindDivingGear = false
                                objective.AllowStealing = false
                                objective.AllowVariants = true

                                if instance.Identifier == waitId then
                                    objective.AbortCondition = abortWaitGetItem
                                end
                                return objective
                            end

                            ---@param objective Barotrauma.AIObjectiveGetItem
                            local function onCompletedGenerator(objective)
                                return function()
                                    characterData["getItemObjective"] = nil
                                    instance.RemoveSubObjective(AIObjectiveGetItem, objective)
                                    
                                    local item = objective.TargetItem

                                    if item == nil then return end
                                    
                                    local function operateConstructorFull()
                                        return makeOperateObjective(character, item.GetComponent(RangedWeapon), item.Prefab.Identifier, instance.objectiveManager)
                                    end

                                    ---@param subObjective Barotrauma.AIObjectiveOperateItem
                                    ---@return fun()
                                    local function cleanupGenerator(subObjective)
                                        return function()
                                            instance.RemoveSubObjective(AIObjectiveOperateItem, subObjective)
                                            characterData["performObjective"] = nil
                                        end
                                    end
                                    
                                    for subObjective in instance.subObjectives do --[[@cast subObjective Barotrauma.AIObjective]]
                                        if subObjective.Identifier == PERFORM then
                                            performObjective = subObjective
                                            break
                                        end
                                    end
                                    _, characterData["performObjective"] = TryAddSubObjective(instance, performObjective, operateConstructorFull, cleanupGenerator, cleanupGenerator)
                                end
                            end

                            local function onAbandonGenerator(objective)
                                return function()
                                    characterData["getItemObjective"] = nil
                                    instance.RemoveSubObjective(AIObjectiveGetItem, objective)
                                end
                            end

                            local getItemObjective

                            for objective in instance.subObjectives do --[[@cast objective Barotrauma.AIObjective]]
                                if objective.Identifier == "get item" then
                                    getItemObjective = objective
                                    break
                                end
                            end
                            _, characterData["getItemObjective"] = TryAddSubObjective(instance, getItemObjective, constructor, onCompletedGenerator, onAbandonGenerator)
                        elseif performObjective then
                            performObjective.Abandon = true
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

    local ragdollHealthPercent = options["ragdollHealthPercent"] --[[@type number]]

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
    local AIObjectiveGoTo = AIObjectiveGoTo
    local Character = Character
    local goToObjId = Identifier("go to")
    local Holdable = Components.Holdable
    local ItemContainer = Components.ItemContainer
    local Wearable = Components.Wearable
    local Submarine = Submarine

    local Any = util.itertools.Any
    local FindItems = util.FindItems
    local GetClosest = util.GetClosest
    local TryAddSubObjective = util.TryAddSubObjective

    local talentId = Identifier(self.namespace.stack[#self.namespace.stack])
    local untouchedContainers = Types.Set.new(self:RegisterTable(nil, "ROUND_END"))
    local allCharacterData = Types.TimedCharacterData.new(self, options["timeBetween"])

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
            
            if  characterData.timer:Update(ptable["deltaTime"]) and
                not characterData["goToObj"]
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
                            characterData["goToObj"] = nil
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

                    local goToObj --[[@type Barotrauma.AIObjectiveGoTo]]

                    for objective in instance.subObjectives do --[[@cast objective Barotrauma.AIObjective]]
                        if objective.Identifier == goToObjId then
                            goToObj = objective
                            break
                        end
                    end
                    
                    local success, newObj = TryAddSubObjective(instance, goToObj, constructor)

                    if success then
                        ptable.PreventExecution = true
                        characterData["goToObj"] = newObj
                    end
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