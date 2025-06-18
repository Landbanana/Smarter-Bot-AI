local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

---@param self Types.CommonModule
local function activate(self)
    self:AddCommonModule("SBAI.Server.CommonModules.AIObjectiveExpansion")

    local AddMethod = util.functools.Partial2(self.AddMethod, self, "Barotrauma.Item")

    do
        local AIObjectiveCleanupItem = AIObjectiveCleanupItem
        local CLEANUPITEM = Constants.ID_OBJECTIVE_BASE.CLEANUPITEM

        local Partial5 = util.functools.Partial5

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

                local _cleanup = Partial5(parentObj.SBAI_cleanupSubObj, instance, cleanObj, AIObjectiveCleanupItem, t, k)

                cleanObj.Completed.add(_cleanup)
                cleanObj.Abandoned.add(_cleanup)
                
                return cleanObj
            end
            objId = objId or CLEANUPITEM
            return parentObj:SBAI_tryAddSubObjective(t, k, objId, objId ~= CLEANUPITEM, objId == CLEANUPITEM, constructor)
        end

        AddMethod("cleanup", cleanup)
        ---@class Barotrauma.Item
        ---@field public SBAI_cleanup fun(instance:Barotrauma.Item, character:Barotrauma.Character, t?:table<string, Barotrauma.AIObjective?>, k?:string, objId?:Barotrauma.Identifier):boolean
    end

    ---@class Barotrauma.Item
    ---@field public ChairItems System.Collections.Generic.IReadOnlyCollection*1Barotrauma*Item|Iterable<Barotrauma.Item>
    ---@field public UnequipAutomatically boolean
end

return Types.CommonModule.new(activate)