local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveIdle"], "CleanupItems")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Hull"], "decals")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Decal"], "hull")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveOperateItem"], "CheckObjectiveState")

LuaUserData.RegisterType("Barotrauma.OrderTarget")
LuaUserData.RegisterType("Barotrauma.Entity")

LuaUserData.RegisterType("System.Func`2[[Barotrauma.PathNode, Barotrauma],[System.Boolean]]")


---@param self Types.Module
---@param options table
local function activateCleanWalls(self, options)
    local MIN_ALPHA = 0.001
    
    local allCharacterData = Types.TimedCharacterData.new(self, options["timeBetween"])
    local allHullData = self:RegisterTable(nil, "ROUND_END") --[[@type {[Barotrauma.Hull]:{decals:table<Barotrauma.OrderTarget,Barotrauma.Decal>, n:integer}}]]

    setmetatable(allHullData, {
        ---@param t {[Barotrauma.Hull]:{decals:table<Barotrauma.OrderTarget,Barotrauma.Decal>, n:integer}}
        ---@param k Barotrauma.Hull
        ---@return {decals:table<Barotrauma.OrderTarget,Barotrauma.Decal>, n:integer}
        __index=function(t, k)
            t[k] = {
                decals={},
                n=0
            }
            return t[k]
        end
    })

    ---@param character Barotrauma.Character
    local function resetCharacterData(character)
        local characterData = allCharacterData[character]

        characterData["orderTarget"] = nil
        characterData["target"] = nil
        characterData["findSprayerObj"] = nil
        characterData["refuelObj"] = nil
        characterData["goToObj"] = nil
        characterData["sprayObj"] = nil
    end

    do
        local OrderTarget = OrderTarget

        self:AddPatch("Barotrauma.Decal", ".ctor", nil,
        function(instance, ptable)
            local hull = ptable["hull"] --[[@type Barotrauma.Hull]]
            
            local sub = hull.Submarine
            local mainSub = Submarine.MainSub
            
            if  mainSub and
                sub.TeamID == mainSub.TeamID
            then
                local hullData = allHullData[hull]

                hullData.n = hullData.n + 1
                hullData.decals[OrderTarget(ptable["worldPosition"], hull, false)] = instance
            end
        end, Hook.HookMethodType.After)
    end

    local sprayObjId = Identifier("spray")

    do
        local AIObjectiveContainItem = AIObjectiveContainItem
        local AIObjectiveGetItem = AIObjectiveGetItem
        local AIObjectiveGoTo = AIObjectiveGoTo
        local AIObjectiveOperateItem = LuaUserData.CreateStatic("Barotrauma.AIObjectiveOperateItem") --[[@type Barotrauma.AIObjectiveOperateItem]]
        local containItemObjId = Identifier("contain item")
        local ethanolId = Identifier("ethanol")
        local ItemContainer = Components.ItemContainer
        local Sprayer = Components.Sprayer
        local SprayerId = Identifier("sprayer")
        local getItemObjId = Identifier("get item")
        local goToObjId = Identifier("go to")

        local FindItem = util.FindItem
        local GetClosest = util.GetClosest
        local Partial4 = util.functools.Partial4
        local rawget = rawget
        local TryAddSubObjective = util.TryAddSubObjective

        ---@param instance Barotrauma.AIObjective
        ---@param objType Barotrauma.AIObjective
        ---@param charData table
        ---@param charDataIdx string
        ---@param objective Barotrauma.AIObjective
        ---@return fun()
        local function generalAfterGenerator(instance, objType, charData, charDataIdx, objective)
            return function()
                charData[charDataIdx] = nil
                instance.RemoveSubObjective(objType, objective)
            end
        end

        local SprayerIdPredicate = util.GenerateIdPredicate({SprayerId})

        self:AddPatch("Barotrauma.AIObjectiveIdle", "CleanupItems", nil,
        function(instance, ptable)
            local character = instance.character
            local characterData = allCharacterData:Get(character)
            
            if characterData.timer:Update(ptable["deltaTime"]) then
                print(character.Name, ":")
                print(characterData["target"])
                print(characterData["orderTarget"])
                print(characterData["findSprayerObj"])
                print(characterData["refuelObj"])
                print(characterData["goToObj"])
                print(characterData["sprayObj"])

                if  characterData["findSprayerObj"] or
                    characterData["refuelObj"] or
                    characterData["goToObj"] or
                    characterData["sprayObj"]
                then
                    return
                end

                do
                    local hullDataList = {}
                    local i = 0

                    for hull in next, allHullData do
                        hullDataList[i] = hull
                    end

                    characterData["target"] = characterData["target"] or GetClosest(character.WorldPosition, hullDataList) --[[@type Barotrauma.Hull]]
                end
                
                local closestHull = characterData["target"] --[[@type Barotrauma.Hull]]
                
                if closestHull then
                    if rawget(allHullData, closestHull) then
                        local sprayer = FindItem(nil, character.Inventory.GetAllItems(false), nil, nil, SprayerIdPredicate)
                        
                        if not sprayer then
                            ---@return Barotrauma.AIObjectiveGetItem
                            ---@nodiscard
                            local function constructor()
                                return AIObjectiveGetItem(character, SprayerId, instance.objectiveManager, true, false, 1, false)
                            end

                            local onCompletedGenerator = Partial4(generalAfterGenerator, instance, AIObjectiveGetItem, characterData, "findSprayerObj")
                            local onAbandonGenerator = onCompletedGenerator
                            local findSprayerObj --[[@type Barotrauma.AIObjectiveGetItem]]

                            for objective in instance.subObjectives do --[[@cast objective Barotrauma.AIObjective]]
                                if objective.Identifier == getItemObjId then
                                    findSprayerObj = objective
                                    break
                                end
                            end
                            
                            _, characterData["findSprayerObj"] = TryAddSubObjective(instance, findSprayerObj, constructor, onCompletedGenerator, onAbandonGenerator)
                            return
                        else
                            local sprayerComponent = sprayer.GetComponent(Sprayer) --[[@type Barotrauma.Items.Components.Sprayer]]
                            local sprayerInventory = sprayer.OwnInventory
                            
                            if sprayerInventory ~= nil then
                                local hasFuel = false

                                for item in sprayerInventory.GetAllItems(false) do
                                    if item.Prefab.Identifier == ethanolId and item.Condition > 0.0 then
                                        hasFuel = true
                                        break
                                    end
                                end

                                if not hasFuel then
                                    ---@return Barotrauma.AIObjectiveContainItem
                                    ---@nodiscard
                                    local function constructor()
                                        local objective = AIObjectiveContainItem(character, ethanolId, sprayer.GetComponent(ItemContainer), instance.objectiveManager, 1, false)
                                        
                                        objective.RemoveExisting = true
                                        return objective
                                    end

                                    local onCompletedGenerator = Partial4(generalAfterGenerator, instance, AIObjectiveContainItem, characterData, "refuelObj")
                                    local onAbandonGenerator = onCompletedGenerator
                                    local refuelObj --[[@type Barotrauma.AIObjectiveContainItem]]
        
                                    for objective in instance.subObjectives do --[[@cast objective Barotrauma.AIObjective]]
                                        if objective.Identifier == containItemObjId then
                                            refuelObj = objective
                                            break
                                        end
                                    end
                                    
                                    _, characterData["refuelObj"] = TryAddSubObjective(instance, refuelObj, constructor, onCompletedGenerator, onAbandonGenerator)
                                    return
                                end
                            end

                            local reach = sprayerComponent.Range/2 + 2*ConvertUnits.ToDisplayUnits(character.AnimController.ArmLength)
                            local orderTarget

                            for k, v in next, allHullData[closestHull].decals do
                                orderTarget = k
                                break
                            end

                            if not orderTarget then
                                return
                            end

                            characterData["orderTarget"] = orderTarget
                            
                            ---@return Barotrauma.AIObjectiveGoTo
                            ---@nodiscard
                            local function constructor()
                                local objective = AIObjectiveGoTo(orderTarget, character, instance.objectiveManager, false, false, 1, reach)
                                
                                objective.endNodeFilter = AIObjectiveGetItem.CreateEndNodeFilter(orderTarget)
                                objective.AllowGoingOutside = false
                                objective.UseDistanceRelativeToAimSourcePos = true
                                return objective
                            end

                            ---@param objective Barotrauma.AIObjectiveGoTo
                            local function onCompletedGenerator(objective)
                                return function()
                                    characterData["goToObj"] = nil
                                    instance.RemoveSubObjective(AIObjectiveGoTo, objective)
                                    
                                    ---@return Barotrauma.AIObjectiveOperateItem
                                    ---@nodiscard
                                    local function constructor2()
                                        local objective2 = AIObjectiveOperateItem(sprayerComponent, character, instance.objectiveManager, sprayObjId, true, nil) --[[@type Barotrauma.AIObjectiveOperateItem]]
                                        
                                        return objective2
                                    end
                                    local onCompletedGenerator2 = Partial4(generalAfterGenerator, instance, AIObjectiveOperateItem, characterData, "sprayObj")
                                    local onAbandonGenerator2 = Partial4(generalAfterGenerator, instance, AIObjectiveOperateItem, characterData, "sprayObj")
                                    local sprayObj --[[@type Barotrauma.AIObjectiveOperateItem]]

                                    for objective2 in instance.subObjectives do --[[@cast objective2 Barotrauma.AIObjective]]
                                        if objective2.Identifier == sprayObj then
                                            sprayObj = objective2
                                            break
                                        end
                                    end
                                    
                                    _, characterData["goToObj"] = TryAddSubObjective(instance, sprayObj, constructor2, onCompletedGenerator2, onAbandonGenerator2)
                                end
                            end
                            local onAbandonGenerator = Partial4(generalAfterGenerator, instance, AIObjectiveGoTo, characterData, "goToObj")
                            local goToObj --[[@type Barotrauma.AIObjectiveContainItem]]

                            for objective in instance.subObjectives do --[[@cast objective Barotrauma.AIObjective]]
                                if objective.Identifier == goToObjId then
                                    goToObj = objective
                                    break
                                end
                            end
                            _, characterData["goToObj"] = TryAddSubObjective(instance, goToObj, constructor, onCompletedGenerator, onAbandonGenerator)
                        end
                    else
                        return resetCharacterData(character)
                    end
                end
            end
        end, Hook.HookMethodType.Before)
    end

    -- do
    --     self:AddPatch("Barotrauma.AIObjectiveOperateItem", "CheckObjectiveState", nil,
    --     function(instance, ptable)
    --         if instance.Option == sprayObjId then
    --             ptable.PreventExecution = true
                
    --             return #instance.OperateTarget.decals <= 0
    --         end
    --     end, Hook.HookMethodType.Before)
    -- end

    for hull in Submarine.MainSub.GetHulls(true) do --[[@cast hull Barotrauma.Hull]]
        local decals = hull.decals

        if #decals > 0 then
            local hullData = allHullData[hull]

            for decal in decals do --[[@cast decal Barotrauma.Decal]]
                hullData.n = hullData.n + 1
                hullData.decals[OrderTarget(decal.WorldPosition, hull, false)] = decal
            end
        end
    end

    do
        local Aim = InputType.Aim
        local Shoot = InputType.Shoot

        local player --[[@type Barotrauma.Character]]

        for c in Character.CharacterList do
            if c.IsPlayer then
                player = c
                break
            end
        end
        print(player.Name)

        self:AddPatch("Barotrauma.Items.Components.ItemComponent", "CrewAIOperate", nil,
        function(instance, ptable)
            if instance.Name:lower() == "sprayer" then
                local character = ptable["character"] --[[@type Barotrauma.Character]]
                local characterData = allCharacterData:Get(character)
                local target = characterData["orderTarget"] --[[@type Barotrauma.OrderTarget]]
                
                ptable.PreventExecution = true
                
                if not target then return true end

                if target then
                    character.CursorPosition = allHullData[target.Hull].decals[target].NonClampedPosition + target.Hull.WorldRect.Location.ToVector2() - target.Submarine.Position
                else
                    resetCharacterData(character)
                    return true
                end
                
                character.SetInput(Aim, false, true)
                --character.SetInput(Shoot, false, true)
                instance.Use(ptable["deltaTime"], character)
                return false
            end
        end, Hook.HookMethodType.Before)
    end

    self:AddPatch("Barotrauma.Hull", "CleanSection", nil,
    function(instance, ptable)
        print("hi")
    end, Hook.HookMethodType.Before)
    
    self:AddPatch("Barotrauma.Items.Components.Sprayer", "Spray", nil,
    function(instance, ptable)
        ptable["applyColors"] = true
    end, Hook.HookMethodType.Before)

    self:AddPatch("Barotrauma.AIObjectiveIdle", "get_AllowAutomaticItemUnequipping", nil,
    function(instance, ptable)
        local characterData = allCharacterData[instance.character]

        if  characterData and
            characterData["orderTarget"]
        then
            
            ptable.PreventExecution = true
            return false
        end
    end, Hook.HookMethodType.Before)

    do
        local RemoveValue = util.itertools.RemoveValue

        self:AddPatch("Barotrauma.Decal", "Clean", nil,
        function(instance, ptable)
            local hull = instance.hull --[[@type Barotrauma.Hull]]
            local hullData = rawget(allHullData, hull) --[[@type {decals:Types.Set, n:integer}]]

            if  hullData and
                instance.BaseAlpha <= MIN_ALPHA
            then
                local n = hullData.n - 1

                if n == 0 then
                    allHullData[hull] = nil
                else
                    hullData.n = n
                    RemoveValue(hullData.decals, instance)
                end
            end
        end, Hook.HookMethodType.After)
    end
end

---@param self Types.Module
local function activate(self)
    self:DoOption("CleanWalls", activateCleanWalls)
end

return Types.Module.new(activate)