---@class CommonModule: Module
---@field public cls CommonModule
---@field public super Module
---@field public export {[string]:any}
---@field protected __new fun<S:CommonModule>(self:S, name:string, activate:fun(self:CommonModule), deactivate?:fun(self:CommonModule), ...:any):(S)
---@field package addedMethods {[string]:string}
---@field package refs Set<string>
Types.CommonModule = Types.new("CommonModule", "Module", {
    export = Types.Desc.Lazy(Tabletools.new);
    addedMethods = Types.Desc.Lazy(Tabletools.new);
    refs = Types.Desc.Lazy(Types.Set.newF);
    _activateOption = Types.AbstractFunction;
    _deactivateOption = Types.AbstractFunction
})

local CommonModule = Types.CommonModule;

do
    ---@nodiscard
    function CommonModule:__new(name, activate, deactivate, ...)
        local obj = CommonModule.super.__new(self, activate, deactivate, ...) ---@as CommonModule

        obj.moduleName = name
        obj._namespace:push(name)
        return obj
    end
end

do
    local AddMethod = LuaUserData.AddMethod

    ---@generic T:System.Object
    ---@param typeName `T`
    ---@param methodName string
    ---@param f fun(self:T, ...:any):(any...)
    function CommonModule:addMethod(typeName, methodName, f)
        AddMethod(typeName, methodName, f)
        self.addedMethods[typeName] = methodName
    end
end

do
    local _instances = CommonModule._instances

    ---@public
    function CommonModule.forceDeactivateAll()
        for commonModule in _instances --[=[@as fun():(CommonModule)]=] do
            commonModule:forceDeactivate()
        end
    end
end

do
    ---@public
    function CommonModule:forceDeactivate()
        self.refs:clear()
        return self:_deactivateBase()
    end
end

do

    local _deactivateBase = CommonModule.super._deactivateBase ---@diagnostic disable-line: access-invisible
    local next = next
    local rawget = rawget
    local RemoveMethod = LuaUserData.RemoveMethod

    function CommonModule:_deactivateBase(data)
        local addedMethods = rawget(self, "addedMethods")

        if addedMethods ~= nil then
            for typeName, methodName in next, addedMethods do
                RemoveMethod(typeName, methodName)
                addedMethods[typeName] = nil
            end
        end

        return _deactivateBase(self, data)
    end
end

do
    ---@public
    ---@param refName string
    function CommonModule:activate(refName)
        local refs = self.refs

        if (not refs.isEmpty) or self:_activateBase(false) then
            return refs:add(refName)
        end
    end
end

do
    ---@public
    ---@param refName string
    function CommonModule:deactivate(refName)
        local refs = self.refs

        refs:remove(refName)
        if refs.isEmpty then
            return self:_deactivateBase(false)
        end
    end
end

return Types.CommonModule