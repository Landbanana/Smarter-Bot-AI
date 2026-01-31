---@class (constructor) Barotrauma.AIObjective
---@field public SBAI_cleanupSubObj fun(instance:Barotrauma.AIObjective, subObj:Barotrauma.AIObjective, subObjType:Barotrauma.AIObjective, t:table?, ...:string?):fun()
---@field public SBAI_isAtWaitObjective fun(instance:Barotrauma.AIObjectiveGoTo):boolean
---@field public SBAI_originalId fun(instance:Barotrauma.AIObjective):Barotrauma.Identifier
---@field public SBAI_tryAddSubObjective fun(instance:Barotrauma.AIObjective, t:table<string,Barotrauma.AIObjective?>?, k:string?, objId:Barotrauma.Identifier?, stopIdDuplicate:boolean?, stopBaseIdDuplicate:boolean?, constructor:fun():(Barotrauma.AIObjective)):boolean

---@param self CommonModule
local function activate(self)
    local AddMethod = util.functools.Partial2(self.AddMethod, self, "Barotrauma.AIObjective")

    do
        local ID_OBJECTIVE_TO_BASE = Constants.ID_OBJECTIVE_TO_BASE

        ---@param instance Barotrauma.AIObjective
        ---@return Barotrauma.Identifier
        local function originalId(instance)
            return ID_OBJECTIVE_TO_BASE[instance.Identifier]
        end

        AddMethod("originalId", originalId)

    end

    do
        ---@param instance Barotrauma.AIObjective
        ---@param subObj Barotrauma.AIObjective
        ---@param subObjType Barotrauma.AIObjective
        ---@param t table?
        ---@param ... string?
        local function cleanupSubObj(instance, subObj, subObjType, t, ...)
            if t then
                for k in {...} do
                    t[k] = nil
                end
            end
            return instance.RemoveSubObjective(subObjType, subObj)
        end

        AddMethod("cleanupSubObj", cleanupSubObj)

    end

    do
        local ID_OBJECTIVE_TO_BASE = Constants.ID_OBJECTIVE_TO_BASE
        local Contains = util.itertools.Contains

        ---@param instance Barotrauma.AIObjective
        ---@param t table<string,Barotrauma.AIObjective?>?
        ---@param k string?
        ---@param objId Barotrauma.Identifier?
        ---@param stopIdDuplicate boolean?
        ---@param stopBaseIdDuplicate boolean?
        ---@param constructor fun():Barotrauma.AIObjective
        ---@return boolean
        local function tryAddSubObjective(instance, t, k, objId, stopIdDuplicate, stopBaseIdDuplicate, constructor)
            local success = constructor ~= nil
            local objective = t ~= nil and t[k] or nil
            local isSubObj = false

            if  objId and
                (stopIdDuplicate or
                stopBaseIdDuplicate)
            then
                local baseObjId = ID_OBJECTIVE_TO_BASE[objId]

                for subObj in instance.subObjectives do --[[@cast subObj Barotrauma.AIObjective]]
                    if  (stopIdDuplicate and
                        subObj.Identifier == objId) or
                        (stopBaseIdDuplicate and
                        subObj:SBAI_originalId() == baseObjId)
                    then
                        if subObj ~= objective then
                            if objective then
                                objective.Abandon = true
                            end
                            objective = subObj
                        end
                        isSubObj = true
                        break
                    end
                end
            end

            if objective then
                if  not success or
                    not (isSubObj or
                    Contains(instance.subObjectives, objective))
                then
                    objective.Abandon = true
                    objective = nil
                end
                success = false
            else
                if success then
                    objective = constructor()
                    if instance.AllowMultipleInstances then
                        objective.SourceObjective = instance
                        instance.subObjectives.Add(objective)
                    else
                        instance.AddSubObjective(objective)
                    end
                end
            end

            if t then t[k] = objective end
            return success
        end

        AddMethod("tryAddSubObjective", tryAddSubObjective)
    end

    do

        self:AddMethod("Barotrauma.AIObjectiveGoTo", "isAtWaitObjective",
        ---@param instance Barotrauma.AIObjectiveGoTo
        ---@return boolean
        function(instance)
            return instance.IsWaitOrder and instance.IsCloseEnough ---@as boolean
        end)
    end
end