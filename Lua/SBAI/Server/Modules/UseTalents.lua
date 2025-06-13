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

local allInstrumentTalentData --[[@type {[Barotrauma.Identifier]:{afflictionId:Barotrauma.Identifier, allowSelf:boolean, maxDistance:number, validInstruments:Set<Barotrauma.Identifier>, allTimedCharacterData:Types.AllTimedCharacterData, performAbort:fun(character:Barotrauma.Character):boolean}}]]
local idleInstrumentPatchMade, waitInstrumentPatchMade

local activateInstrumentTalent do
    do
        local activateObj do
            local patch2 do
                local coPatch do
                    local AIObjectiveGetItem = AIObjectiveGetItem
                    local AIObjectiveOperateItem = AIObjectiveOperateItem
                    local GETITEM = Constants.ID_OBJECTIVE_BASE.GETITEM
                    local PERFORM = Constants.ID_OBJECTIVE.PERFORM
                    local RangedWeapon = Components.RangedWeapon

                    local Partial5 = util.functools.Partial5
                    local wrap = coroutine.wrap
                    local yield = coroutine.yield

                    ---@param afflictionData {afflictionId:Barotrauma.Identifier, allowSelf:boolean, maxDistance:number, validInstruments:Set<Barotrauma.Identifier>, allTimedCharacterData:Types.AllTimedCharacterData, performAbort:fun(character:Barotrauma.Character):boolean}
                    ---@param getItemAbort fun(objective:Barotrauma.AIObjective):boolean
                    ---@param character Barotrauma.Character
                    ---@param characterData Types.TimedCharacterData
                    ---@param curObj Barotrauma.AIObjectiveGoTo|Barotrauma.AIObjectiveIdle
                    function coPatch(afflictionData, getItemAbort, character, characterData, curObj)
                        yield()

                        local validInstruments = afflictionData.validInstruments
                        local instrument = character.Inventory:SBAI_findAllItems(nil, true, function(inventory, item) return validInstruments[item.Prefab.Identifier] end)()

                        if not instrument then
                            local function constructor()
                                local objective = AIObjectiveGetItem(character, validInstruments:ToList(), curObj.objectiveManager, true, false)

                                objective.AllowDangerousPressure = false
                                objective.AllowStealing = false
                                objective.AllowToFindDivingGear = false
                                objective.AllowVariants = true

                                if getItemAbort then
                                    objective.AbortCondition = getItemAbort
                                end
                                local cleanup = Partial5(curObj.SBAI_cleanupSubObj, curObj, objective, AIObjectiveGetItem)
                                
                                objective.Completed.add(function()
                                    instrument = objective.TargetItem
                                    return cleanup()
                                end)
                                objective.Abandoned.add(cleanup)
                                return objective
                            end
                            yield(curObj:SBAI_tryAddSubObjective(nil, nil, GETITEM, false, true, constructor))
                        end
                        
                        if instrument then
                            local performAbort = afflictionData.performAbort
                            local coPerformAbort

                            if performAbort then
                                coPerformAbort = wrap(performAbort)

                                if coPerformAbort(character) then coPerformAbort = nil end
                            end

                            if  not performAbort or
                                coPerformAbort
                            then
                                local function constructor()
                                    local objective = AIObjectiveOperateItem(instrument.GetComponent(RangedWeapon), character, curObj.objectiveManager, instrument.Prefab.Identifier, true)

                                    objective.Identifier = PERFORM

                                    objective.OverridePriority = 1.0

                                    if coPerformAbort then
                                        function objective:AbortCondition()
                                            return coPerformAbort()
                                        end
                                    end

                                    local cleanup = Partial5(curObj.SBAI_cleanupSubObj, curObj, objective, AIObjectiveOperateItem, characterData, "performObj")

                                    objective.Completed.add(cleanup)
                                    objective.Abandoned.add(cleanup)
                                    return objective
                                end

                                yield(curObj:SBAI_tryAddSubObjective(characterData, "performObj", PERFORM, true, false, constructor))
                            end
                        end
                    end
                end

                local next = next
                local pwrap = util.cotools.pwrap

                ---@param getItemAbort fun(objective:Barotrauma.AIObjective):boolean
                ---@param instance Barotrauma.AIObjectiveGoTo|Barotrauma.AIObjectiveIdle
                ---@param ptable Barotrauma.LuaCsHook.ParameterTable
                function patch2(getItemAbort, instance, ptable)
                    local character = instance.character

                    for talentId, afflictionData in next, allInstrumentTalentData do
                        if character.HasTalent(talentId) then
                            local characterData = afflictionData.allTimedCharacterData:Get(character)
                            local coOngoing = characterData.coOngoing
                            
                            if characterData.coOngoing then
                                
                                characterData.coOngoing()
                            elseif characterData:Update(ptable["deltaTime"]) and
                                not characterData.performObj
                            then
                                instance.Deselected.add(
                                function()
                                    characterData.coOngoing = nil
                                end)
                                coOngoing = pwrap(coPatch, characterData, "coOngoing")
                                coOngoing(afflictionData, getItemAbort, character, characterData, instance)
                            end
                        end
                    end
                end
            end

            local buffCheck do
                local GetFriendlyCrew = Character.GetFriendlyCrew
                local Distance = Vector2.Distance
                local new = Types.Timer.new
                local yield = coroutine.yield

                ---@param afflictionId Barotrauma.Identifier
                ---@param maxDistance number
                ---@param allowSelf boolean
                ---@param timeBetween number
                ---@param character Barotrauma.Character
                function buffCheck(afflictionId, maxDistance, allowSelf, timeBetween, character)
                    local timer = new(timeBetween, 0.0)
                    local crewCache = {}
                    
                    do
                        local i = 0
                        
                        if allowSelf then
                            for crewmate in GetFriendlyCrew(character) do
                                i = i + 1
                                crewCache[i] = crewmate
                            end
                        else
                            for crewmate in GetFriendlyCrew(character) do
                                if crewmate ~= character then
                                    i = i + 1
                                    crewCache[i] = crewmate
                                end
                            end
                        end
                    end

                    local startPos = character.WorldPosition
                    
                    repeat
                        local isAllBuffed = true

                        for crewmate in crewCache do
                            if  not crewmate.CharacterHealth.GetAffliction(afflictionId, false) and
                                Distance(startPos, crewmate.WorldPosition) <= maxDistance and
                                character.CanSeeTarget(crewmate, nil, true, false)
                            then
                                isAllBuffed = false
                                repeat
                                    yield(false)
                                until timer:UpdateClock()
                                break
                            end
                        end
                    until isAllBuffed

                    return true
                end
            end

            ---@param self Types.Module
            ---@param options table
            ---@param objId Barotrauma.Identifier
            ---@param timeBetween number
            ---@param stopAfterBuffed boolean
            function activateObj(self, options, objId, talentId, timeBetween, stopAfterBuffed)
                if not allInstrumentTalentData[talentId] then
                    local prefab = TalentPrefab.TalentPrefabs[talentId]

                    if not prefab then error("Unable to find talentPrefab: "..tostring(talentId.Value), 2) end
                    
                    local xElement = prefab.ConfigElement.Element --[[@type Barotrauma.ContentXElement]]
                    local abilityConditionItem = util.xPath2(xElement, "AbilityGroupEffect[@abilityeffecttype=OnUseRangedWeapon]/Conditions/AbilityConditionItem")[1]
                    local characterAbilityApplyStatusEffectsToAllies = util.xPath2(xElement, "AbilityGroupEffect[@abilityeffecttype=OnUseRangedWeapon]/Abilities/CharacterAbilityApplyStatusEffectsToAllies")[1]
                    local afflictionId = util.xPath2(characterAbilityApplyStatusEffectsToAllies, "StatusEffects/StatusEffect/Affliction[@identifier]")[1].GetAttributeIdentifier("identifier")
                    
                    if not afflictionId then error("Unable to find afflictions for talent: "..tostring(talentId.Value), 2) end
                    
                    local instrumentIds = Types.Set.new()

                    do
                        local ids = abilityConditionItem.GetAttributeIdentifierArray("identifiers")

                        if ids then
                            instrumentIds:Update(ids)
                        end
                    end
                    
                    if instrumentIds:IsEmpty() then
                        local tags = abilityConditionItem.GetAttributeIdentifierArray("tags")
                        local traitorMissionItemId = Identifier("traitormissionitem")
                        
                        for prefab in ItemPrefab.Prefabs do
                            for tag in tags do --[[@cast tag Barotrauma.Identifier]]
                                if  util.itertools.Contains(prefab.Tags, tag) and
                                    not util.itertools.Contains(prefab.Tags, traitorMissionItemId)
                                then
                                    instrumentIds:Add(prefab.Identifier)
                                    break
                                end
                            end
                        end
                    end
                    if instrumentIds:IsEmpty() then error("Unable to find instruments for talent: "..tostring(talentId.Value), 2) end
                    
                    local maxDistance = characterAbilityApplyStatusEffectsToAllies.GetAttributeFloat("maxdistance", Constants.MAX_FLOAT)
                    local allowSelf = characterAbilityApplyStatusEffectsToAllies.GetAttributeBool("allowself", true)
                    
                    allInstrumentTalentData[talentId] = {afflictionId=afflictionId, allowSelf=allowSelf, maxDistance=maxDistance, validInstruments=instrumentIds, allTimedCharacterData=Types.AllTimedCharacterData.new(self, timeBetween), performAbort=stopAfterBuffed and util.functools.Partial4(buffCheck, afflictionId, maxDistance, allowSelf, timeBetween) or nil}
                end

                local patch1

                if  objId == Constants.ID_OBJECTIVE_BASE.IDLE and
                    not idleInstrumentPatchMade
                then
                    patch1 = util.functools.Partial1(patch2, nil)
                elseif  objId == Constants.ID_OBJECTIVE_BASE.WAIT and
                    not waitInstrumentPatchMade
                then
                    local Distance = Vector2.Distance
                    local IsAtWaitObjective = util.IsAtWaitObjective

                    local wait_patch2 = util.functools.Partial1(patch2,
                    function(objective)
                        local item = objective.TargetItem

                        if  item and
                            Distance(item.WorldPosition, objective.character.WorldPosition) > objective.MaxReach
                        then
                            return true
                        end
                        return false
                    end)

                    ---@param instance Barotrauma.AIObjectiveGoTo
                    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
                    function patch1(instance, ptable)
                        if IsAtWaitObjective(instance) then
                            return wait_patch2(instance, ptable)
                        end
                    end
                end

                if patch1 then
                    local fullObjType = Constants.TYPE_OBJECTIVE_BASE[objId.Value:upper()]
                    self:AddPatch(fullObjType, "Act", nil, patch1, Hook.HookMethodType.Before)
                end
            end
        end

        ---@param self Types.Module
        ---@param options table
        function activateInstrumentTalent(self, options)
            if not allInstrumentTalentData then
                local IDLE = Constants.ID_OBJECTIVE_BASE.IDLE
                local PERFORM = Constants.ID_OBJECTIVE.PERFORM
                local WAIT = Constants.ID_OBJECTIVE_BASE.WAIT

                allInstrumentTalentData = {}

                self:AddCommonModule("SBAI.Server.CommonModules.AIObjectiveExpansion")
                self:AddCommonModule("SBAI.Server.CommonModules.InventoryExpansion")
                ModObjProp = self:AddCommonModule("SBAI.Server.CommonModules.ModifyObjectiveProperties") --[[@type fun(propertyName:string, objId:Barotrauma.Identifier, subObjId:Barotrauma.Identifier, value:any)]]
                ModObjProp("ConcurrentObjectives", IDLE, PERFORM, true)
                ModObjProp("ConcurrentObjectives", WAIT, PERFORM, true)
                self:AddCommonModule("SBAI.Server.CommonModules.PerformInstruments")
                self:AddCommonModule("SBAI.Server.CommonModules.XElementExpansion")

                local Aim = InputType.Aim
                local Shoot = InputType.Shoot

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
            
            local talentId = Identifier(self:GetSection())
            local timeBetween = options["timeBetween"]
            local stopAfterBuffed = options["stopAfterBuffed"]

            for objId in {Constants.ID_OBJECTIVE_BASE.IDLE, Constants.ID_OBJECTIVE_BASE.WAIT} do
                self:DoOption(objId.Value:lower(), activateObj, objId, talentId, timeBetween, stopAfterBuffed)
            end
        end
    end
end

---@param self Types.Module
---@param options table
local function assistant_JengaMaster(self, options)
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
---@param options table
local function assistant_NonThreatening(self, options)
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
local function activateAssistant(self)
    self:DoOption("InspiringTunes", activateInstrumentTalent)
    self:DoOption("NonThreatening", assistant_NonThreatening)
    self:DoOption("JengaMaster", assistant_JengaMaster)
end

---@param self Types.Module
local function activateCaptain(self)
    self:DoOption("SteadyTune", activateInstrumentTalent)
end

---@param self Types.Module
local function activateEngineer(self)
    self:DoOption("MelodicRespite", activateInstrumentTalent)
end

---@param self Types.Module
local function activate(self)
    self:DoOption("Assistant", activateAssistant)
    self:DoOption("Captain", activateCaptain)
    self:DoOption("Engineer", activateEngineer)
end

---@param self Types.Module
local function deactivate(self)
    allInstrumentTalentData = nil
    idleInstrumentPatchMade = nil
    waitInstrumentPatchMade = nil
end

return Types.Module.new(activate, deactivate)