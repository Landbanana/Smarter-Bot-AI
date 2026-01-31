local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")

local Registry = require("SBAI.Shared.Types.Registry") --[[@type Registry<table<string, any>>]]

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.AIObjectiveManager"], "character")

---@param self CommonModule
local function activate(self)
    local idToConstructor = {} --[[@type table<string|Barotraumas.Identifier, fun(character:Barotrauma.Character, objectiveManager:Barotrauma.AIObjectiveManager, priorityModifier:number):Barotrauma.AIObjective>]]

    self:PatchHook("Barotrauma.AIObjectiveManager", "CreateObjective", nil,
    function(instance, ptable)
        local order = ptable["order"] --[[@type Barotrauma.Order]]
        local id = order.Identifier
        local constructor = idToConstructor[id]

        if constructor then
            if  order == nil or
                order.IsDismissal
            then
                return nil
            end

            ptable.PreventExecution = true

            local newObjective = constructor(instance.character, instance, ptable["priorityModifier"]) --[[@type Barotrauma.AIObjective]]
            
            if newObjective ~= nil then
                newObjective.Identifier = id
            end
            newObjective.IgnoreAtOutpost = order.IgnoreAtOutpost
            return newObjective
        end
    end, true)
    
    ---@param id string
    ---@param constructor fun(character:Barotrauma.Character, objectiveManager:Barotrauma.AIObjectiveManager, priorityModifier:number):Barotrauma.AIObjective
    local function RegisterOrder(id, constructor)
        
    end

    RegisterOrder()
end

return GetType("CommonModule").new(activate)