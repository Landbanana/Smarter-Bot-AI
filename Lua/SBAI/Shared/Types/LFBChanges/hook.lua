---@namespace LFBChanges

local _Hook = _ENV.OLD.Hook ---@diagnostic disable-line: access-invisible

---@class Hook: Object
---@field public cls Hook
---@field public Add fun(hookSuffix:string, eventName:string, f:fun(...:any):(any))
---@field public Call fun(eventName:string, ...):(any)
---@field public Remove fun(hookSuffix:string, eventName:string)
Types.LFBChanges.Hook = Types.new("LFBChanges.Hook", nil, {
    Call = _Hook.Call
})

local Hook = Types.LFBChanges.Hook

local raise = raise

do
    local Add = _Hook.Add
    local prefixAcronym = Stringtools.prefixAcronym

    function Hook.Add(hookSuffix, eventName , f)
        return raise(Add, eventName, prefixAcronym(hookSuffix), f)
    end
end

do
    local After = _Hook.HookMethodType.After
    local Before = _Hook.HookMethodType.Before

    local AccessMethod = LuaUserData.AccessMethod
    local AccessProperty = LuaUserData.AccessProperty
    local Patch = _Hook.Patch ---@as fun(identifier:string, className:string, methodName:string, parameterTypes?:string[], patch:fun(instance: System.Object, ptable: Barotrauma.LuaCsHook.ParameterTable), hookType:Barotrauma.LuaCsHook.HookMethodType):(string)
    local pcall = pcall
    local prefixAcronym = Stringtools.prefixAcronym

    ---@public
    ---@generic T
    ---@param hookSuffix string
    ---@param typeName `T`
    ---@param methodName keyof T
    ---@param parameterTypes? string[]
    ---@param hookType "Before"|"After"
    ---@param f fun(instance:T, ptable:Barotrauma.LuaCsHook.ParameterTable):(any)
    ---@return string
    function Hook.Patch(hookSuffix, typeName, methodName, parameterTypes, hookType, f)

        hookType = hookType == "After" and After or Before ---@diagnostic disable-line: assign-type-mismatch

        local hookName = prefixAcronym(hookSuffix)

        if (pcall(Patch, hookName, typeName, methodName--[[@as string]], parameterTypes, f, hookType)) then
            return hookName
        else
            local propertyName = methodName:match("^[gs]et_(.+)$")

            if propertyName == nil then
                raise(AccessMethod, typeName, methodName, parameterTypes)
            else
                raise(AccessProperty, typeName, propertyName)
            end
        end
        return raise(Patch, hookName, typeName, methodName --[[@as string]], parameterTypes, f, hookType)
    end
end

do
    local prefixAcronym = Stringtools.prefixAcronym
    local Remove = _Hook.Remove

    function Hook.Remove(hookSuffix, eventName)
        return raise(Remove, eventName, prefixAcronym(hookSuffix))
    end
end

do
    local After = _Hook.HookMethodType.After
    local Before = _Hook.HookMethodType.Before

    local prefixAcronym = Stringtools.prefixAcronym
    local RemovePatch = _Hook.RemovePatch

    ---@public
    ---@generic T:System.Object
    ---@param hookSuffix string
    ---@param typeName `T`
    ---@param methodName keyof T
    ---@param parameterTypes? string[]
    ---@param hookType "Before"|"After"
    ---@return boolean
    function Hook.RemovePatch(hookSuffix, typeName, methodName, parameterTypes, hookType)
        return raise(RemovePatch, prefixAcronym(hookSuffix), typeName, methodName, parameterTypes, hookType == "After" and After or Before)
    end
end

return Types.LFBChanges.Hook