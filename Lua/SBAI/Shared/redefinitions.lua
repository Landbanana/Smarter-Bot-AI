local HF = require("SBAI.Shared.helperfunctions")
local P = {}

---@generic T:Barotrauma.AIObjective
---@param instance Barotrauma.AIObjective
---@param objective? T
---@param constructor fun():(Barotrauma.AIObjective)
---@param onCompletedGenerator fun(Barotrauma.AIObjective)
---@param onAbandonGenerator fun(Barotrauma.AIObjective)
---@return boolean
---@return T
function P.TryAddSubObjective(instance, objective, constructor, onCompletedGenerator, onAbandonGenerator)
    if objective ~= nil then
        if not HF.ListContains(instance.subObjectives, objective) then objective = nil end
        return false, nil
    else
        objective = constructor()
        if HF.ListContains(instance.subObjectives, objective) then return false, objective end
        if instance.AllowMultipleInstances then
            objective.SourceObjective = instance
            instance.subObjectives.Add(objective)
        else
            instance.AddSubObjective(objective)
        end
        if onCompletedGenerator ~= nil then
            objective.Completed.add(onCompletedGenerator(objective))
        end
        if onAbandonGenerator ~= nil then
            objective.Abandoned.add(onAbandonGenerator(objective))
        end
        return true, objective
    end
end

P.LuaUserData = setmetatable({}, {__index=LuaUserData})
P.Hook = setmetatable({
    list={
        add={}, --[[@type Set<{name:string, identifier:string}>]]
        patch={}--[[@type Set<{identifier:string, className:string, methodName:string, parameterTypes:string[]?, hookType:Barotrauma.LuaCsHook.HookMethodType}>]]
    },
    ---@param name string
    ---@param identifier string
    ---@param func fun(...):...
    Add=function(name, identifier, func)
        P.Hook.list.add[{name=name, identifier=identifier}] = true
        Hook.Add(name, identifier, func)
    end,
    ---@param identifier string
    ---@param className string
    ---@param methodName string
    ---@param parameterTypes? string[]
    ---@param patch fun(instance:any, ptable:Barotrauma.LuaCsHook.ParameterTable):MoonSharp.Interpreter.DynValue
    ---@param hookType Barotrauma.LuaCsHook.HookMethodType
    Patch=function(identifier, className, methodName, parameterTypes, patch, hookType)
        if not hookType then
            hookType = patch
            patch = parameterTypes
            parameterTypes = nil
        end
        P.Hook.list.patch[{identifier=identifier, className=className, methodName=methodName, parameterTypes=parameterTypes, hookType=hookType}] = true
        Hook.Patch(identifier, className, methodName, parameterTypes, patch, hookType)
    end
}, {__index=Hook})


P.ItemGroup={} --[[@type table<string,Barotrauma.Item[]>]]
setmetatable(P.ItemGroup, {
    __index = function(t, k)
        local name = P.namespace.base..".ItemGroup."..k
        local isRegistered, table = pcall(Util.GetItemGroup, name)
        
        if isRegistered then
            t[k] = table
        else
            Util.RegisterItemGroup(name, function(item)
                return item.HasTag(k)
            end)
            t[k] = Util.GetItemGroup(name)
        end
        return t[k]
    end
})

return P