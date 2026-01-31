---@class (constructor) Barotrauma.Item
---@field public SBAI_cleanup fun(instance:Barotrauma.Item, character:Barotrauma.Character, t?:table<string, Barotrauma.AIObjective?>, k?:string, objId?:Barotrauma.Identifier):boolean

---@param self CommonModule
local function activate(self)
    self:addCommonModule("AIObjectiveExpansion")

    local addMethod = Functools.partial2(self.addMethod, self, "Barotrauma.Item")

    do
        local AIObjectiveCleanupItem = AIObjectiveCleanupItem
        local CLEANUPITEM = Constants.ID_OBJECTIVE_BASE.CLEANUPITEM

        local partial5 = Functools.partial5

        ---@param instance Barotrauma.Item
        ---@param character Barotrauma.Character
        ---@param t? table<string, Barotrauma.AIObjective?>
        ---@param k? string
        ---@param objId? Barotrauma.Identifier
        local function cleanup(instance, character, t, k, objId)
            local objectiveManager = character.AIController.ObjectiveManager
            local parentObj = objectiveManager.CurrentObjective

            local function constructor()
                local cleanObj = AIObjectiveCleanupItem(instance, character, objectiveManager)

                local _cleanup = partial5(parentObj.SBAI_cleanupSubObj, instance, cleanObj, AIObjectiveCleanupItem, t, k)

                cleanObj.Completed.add(_cleanup)
                cleanObj.Abandoned.add(_cleanup)
                
                return cleanObj
            end
            objId = objId or CLEANUPITEM
            return parentObj:SBAI_tryAddSubObjective(t, k, objId, objId ~= CLEANUPITEM, objId == CLEANUPITEM, constructor)
        end

        addMethod("cleanup", cleanup)
    end
end

return Types.CommonModule("ItemExpansion", activate)