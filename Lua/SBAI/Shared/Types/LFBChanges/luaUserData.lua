---@namespace LFBChanges

local _LuaUserData = _ENV.OLD.LuaUserData ---@diagnostic disable-line: access-invisible

_ENV.LuaUserData = nil

--[[
---@field package _AddField fun(IUUD:MoonSharp.Interpreter.Interop.IUserDataDescriptor, fieldName:string, value:any) ---@readonly
---@field package _AddMethod fun(IUUD:MoonSharp.Interpreter.Interop.IUserDataDescriptor, methodName:string, luaKey__function:function) ---@readonly
---@field package _RegisterExtensionType fun<T:System.Object>(typename:`T`) ---@readonly
---@field package _RegisterGenericType fun<T:System.Object, S:System.Object>(typename:`T`, ...:`S`):(MoonSharp.Interpreter.Interop.IUserDataDescriptor) ---@readonly
---@field package _RemoveMember fun(IUUD:MoonSharp.Interpreter.Interop.IUserDataDescriptor, memberName:string) ---@readonly
---@field package _UnregisterGenericType fun<T:System.Object, S:System.Object>(typeName:`T`, ...:`S`) ---@readonly
---@field package _CreateUserDataFromDescriptor fun(scriptObject:any, desiredTypeDescriptor:MoonSharp.Interpreter.Interop.IUserDataDescriptor):(userdata) ---@readonly
---@field package _CreateUserDataFromType fun(scriptObject:any, desiredType:System.Type):(userdata) ---@readonly
---@field package _MakeFieldAccessible fun(IUUD:MoonSharp.Interpreter.Interop.IUserDataDescriptor, fieldName:string) ---@readonly
---@field package _MakeMethodAccessible fun(IUUD:MoonSharp.Interpreter.Interop.IUserDataDescriptor, methodName:string, parameters?:string[]) ---@readonly
---@field package _MakePropertyAccessible fun(IUUD:MoonSharp.Interpreter.Interop.IUserDataDescriptor, propertyName:string) ---@readonly
--]]
-----@field public CreateEnum fun<T:System.Object>(typeName:`T`):(Pick<T,keyof T>)

---@class LuaUserData: Object
---@field public cls LuaUserData
---@field public CreateEnum fun<T:System.Object, E:keyof T>(containerTypeName:`T`, baseTypeName:E):(E extends "" and Pick<T, keyof T> or Pick<std.RawGet<T,E>, keyof std.RawGet<T,E>>)
---@field public CreateStatic fun<T:System.Object>(typeName:`T`):(T)
---@field public DoWithTempRegistrations fun<T...:System.Object, P, R>(typeNames:`T`[], f:fun(...:P...):(R...), ...:P...):(R...)
---@field public GetType fun<T:System.Object>(typeName:`T`):(System.Type)
---@field public IsRegistered fun<T:System.Object>(typeName:`T`):(boolean)
---@field public IsTargetType fun<T:System.Object>(obj:any, typeName:`T`):(TypeGuard<T>)
---@field public RegisterType fun<T:System.Object>(typeName:`T`):(MoonSharp.Interpreter.Interop.IUserDataDescriptor)
---@field public RegisterExtensionType fun<T:System.Object>(typeName:`T`)
---@field public TypeOf fun<T:System.Object>(obj:std.ConstTpl<T>):(`T`)
---@field public UnregisterType fun<T:System.Object>(typeName:`T`)
---@field package Descriptors {[string]: MoonSharp.Interpreter.Interop.IUserDataDescriptor}
---@field package enumCache Cache<string, System.Object>
---@field package staticCache Cache<string, System.Object>
Types.LFBChanges.LuaUserData = Types.new("LFBChanges.LuaUserData", nil, {
    Descriptors = setmetatable({}, {__index=Descriptors});

    GetType = _LuaUserData.GetType;
    HasMember = _LuaUserData.HasMember;
    IsTargetType = _LuaUserData.IsTargetType;
    RegisterExtensionType = _LuaUserData.RegisterExtensionType;
    TypeOf = _LuaUserData.TypeOf;

    _AddField = _LuaUserData.AddField;
    _AddMethod = _LuaUserData.AddMethod;
    _CreateUserDataFromDescriptor = _LuaUserData.CreateUserDataFromDescriptor;
    _CreateUserDataFromType = _LuaUserData.CreateUserDataFromType;
    _MakeFieldAccessible = _LuaUserData.MakeFieldAccessible;
    _MakeMethodAccessible = _LuaUserData.MakeMethodAccessible;
    _MakePropertyAccessible = _LuaUserData.MakePropertyAccessible;

    _RegisterGenericType = _LuaUserData.RegisterGenericType;
    _RemoveMember = _LuaUserData.RemoveMember;
    _UnregisterGenericType = _LuaUserData.UnregisterGenericType;
    _UnregisterType = _LuaUserData.UnregisterType;
})

local LuaUserData = Types.LFBChanges.LuaUserData

do
    local TypeOf = LuaUserData.TypeOf

    ---@generic T1:System.Object, T2:T1
    ---@param obj std.ConstTpl<T1>
    ---@param typeName `T2`
    ---@return TypeGuard<T2>
    function LuaUserData.IsTypeOf(obj, typeName)
        return TypeOf(obj) == typeName
    end
end

do
    local Descriptors = LuaUserData.Descriptors

    local IsRegistered = _LuaUserData.IsRegistered ---@as fun(typeName:string):(boolean)

    function LuaUserData.IsRegistered(typeName)
        if IsRegistered(typeName) then
            if Descriptors[typeName] --[=[@as boolean]=] then
                return true
            else
                return false
            end
        else
            return false
        end
    end
end

local addedMethods = setmetatable({}, {__index = function(t, k) local out = {}; t[k] = out; return out end}) ---@type {[string]:{[string]:function}}

local raise = raise

do
    local Descriptors = LuaUserData.Descriptors


    local AddMethod ---@[lsp_optimization("delayed_definition")]
    local IsRegistered = LuaUserData.IsRegistered
    local IsTargetType ---@[lsp_optimization("delayed_definition")]
    local next = next
    local RegisterType = _LuaUserData.RegisterType

    onGlobalLoad("LuaUserData",
    function(v)
        AddMethod = v.AddMethod
        IsTargetType = v.IsTargetType
    end)

    function LuaUserData.RegisterType(typeName)
        if IsRegistered(typeName) then
            return Descriptors[typeName]
        else
            local descriptor = raise(RegisterType, typeName)
            local _type = descriptor.Type

            for otherTypeName, methods in next, addedMethods do
                if IsTargetType(_type, otherTypeName) then
                    for methodName, f in next, methods do
                        AddMethod(typeName, methodName, f)
                    end
                end
            end

            Descriptors[typeName] = descriptor
            return descriptor
        end
    end
end

do
    local CreateStatic = _LuaUserData.CreateStatic
    local RegisterType = LuaUserData.RegisterType

    LuaUserData.staticCache = Types.Cache(
    function (typeName)
        RegisterType(typeName)
        return raise(CreateStatic, typeName)
    end)
    LuaUserData.CreateStatic = LuaUserData.staticCache.cachedFunction
end

do
    do
        local CreateEnumTable = _LuaUserData.CreateEnumTable
        --local RegisterType = LuaUserData.RegisterType


        LuaUserData.enumCache = Types.Cache(
        function(typeName)
            --raise(RegisterType, typeName)
            return raise(CreateEnumTable, typeName)
        end)
    end

    local concat = table.concat

    local createEnum = LuaUserData.staticCache.cachedFunction

    function LuaUserData.CreateEnum(containerTypeName, baseTypeName)
        return raise(createEnum, baseTypeName == "" and containerTypeName or concat({containerTypeName, baseTypeName}, "+"))
    end
end

do
    local Descriptors = LuaUserData.Descriptors

    local next = next
    local RemoveMethod  ---@[lsp_optimization("delayed_definition")]
    local UnregisterType = _LuaUserData.UnregisterType

    onGlobalLoad("LuaUserData",
    function(v)
        RemoveMethod = v.RemoveMethod
    end)

    function LuaUserData.UnregisterType(typeName)
        local typeMethods = addedMethods[typeName]

        if typeMethods ~= nil then
            for methodName in next, typeMethods do
                RemoveMethod(typeName, methodName)
            end
        end

        raise(UnregisterType, typeName)
        Descriptors[typeName] = nil
    end
end

do
    local Deque = Types.Deque
    local Descriptors = Descriptors ---@as table<string, MoonSharp.Interpreter.Interop.IUserDataDescriptor>

    local ferror  = ferror
    local IsRegistered = LuaUserData.IsRegistered
    local pack = table.pack
    local pcall = pcall
    local RegisterType = _LuaUserData.RegisterType
    local unpack = table.unpack
    local UnregisterType = _LuaUserData.UnregisterType


    function LuaUserData.DoWithTempRegistrations(typeNames, f, ...)
        local toUnregister = Deque() ---@type Deque<string>

        for i=1,#typeNames do
            local typeName = typeNames[i]

            if not IsRegistered(typeName) then
                print(typeName)
                RegisterType(typeName)
                print(typeName,"::")
                toUnregister:push(typeName)
            end
        end
        local out = pack(pcall(f, ...))

        for typeName in toUnregister do
            raise(UnregisterType, typeName)
            Descriptors[typeName] = nil
        end

        if out[1] == false then
            return ferror(out[2], 2)
        end

        return unpack(out, 2, out.n --[=[@as integer]=])
    end
end

do
    local Descriptors = Descriptors

    local AddMethod = _LuaUserData.AddMethod ---@as fun(IUUD:MoonSharp.Interpreter.Interop.IUserDataDescriptor, methodName:string, f:function)
    local IsTargetType = LuaUserData.IsTargetType
    local next = next
    local prefixAcronym = Stringtools.prefixAcronym
    local RegisterType = LuaUserData.RegisterType

    ---@public
    ---@generic T:System.Object
    ---@param typeName `T`
    ---@param methodName string
    ---@param f fun(self:T, ...:any):(any...)
    function LuaUserData.AddMethod(typeName, methodName, f)
        raise(RegisterType, typeName)

        methodName = prefixAcronym(methodName, "_")

        for otherTypeName, descriptor in next, Descriptors --[=[@as fun():(MoonSharp.Interpreter.Interop.IUserDataDescriptor)]=] do
            if IsTargetType(descriptor.Type, typeName) then
                AddMethod(descriptor, methodName, f)
                addedMethods[otherTypeName][methodName] = f
            end
        end
    end
end

do
    local Descriptors = Descriptors

    local RemoveMember = _LuaUserData.RemoveMember ---@as fun(IUUD:MoonSharp.Interpreter.Interop.IUserDataDescriptor, methodName:string)
    local HasMember = LuaUserData.HasMember
    local IsTargetType = LuaUserData.IsTargetType
    local next = next
    local prefixAcronym = Stringtools.prefixAcronym
    local RegisterType = LuaUserData.RegisterType

    ---@public
    ---@generic T:System.Object
    ---@param typeName `T`
    ---@param methodName string
    function LuaUserData.RemoveMethod(typeName, methodName)
        raise(RegisterType, typeName)

        methodName = prefixAcronym(methodName, "_")

        for otherTypeName, descriptor in next, Descriptors --[=[@as fun():(MoonSharp.Interpreter.Interop.IUserDataDescriptor)]=] do
            local _type = descriptor.Type

            if IsTargetType(_type, typeName) and HasMember(_type, methodName) then
                RemoveMember(descriptor, methodName)

                local addedOtherTypeMethods = addedMethods[otherTypeName]

                addedOtherTypeMethods[methodName] = nil

                if next(addedOtherTypeMethods) == nil then
                    addedMethods[otherTypeName] = nil
                end
            end
        end
    end
end

do
    local MakeFieldAccessible = _LuaUserData.MakeFieldAccessible
    local RegisterType = LuaUserData.RegisterType

    ---@public
    ---@generic T:System.Object
    ---@param typeName `T`
    ---@param fieldName keyof T
    function LuaUserData.AccessField(typeName, fieldName)
        return raise(MakeFieldAccessible, RegisterType(typeName), fieldName --[=[@as string]=])
    end
end

do
    local MakeMethodAccessible = _LuaUserData.MakeMethodAccessible
    local RegisterType = LuaUserData.RegisterType

    ---@public
    ---@generic T:System.Object
    ---@param typeName `T`
    ---@param methodName keyof T
    ---@param parameterTypes? string[]
    function LuaUserData.AccessMethod(typeName, methodName, parameterTypes)
        return raise(MakeMethodAccessible, RegisterType(typeName), methodName --[=[@as string]=], parameterTypes)
    end
end



do
    local MakeMethodAccessible = _LuaUserData.MakeMethodAccessible
    local MakePropertyAccessible = _LuaUserData.MakePropertyAccessible
    local pcall = pcall
    local RegisterType = LuaUserData.RegisterType

    ---@public
    ---@generic T:System.Object
    ---@param typeName `T`
    ---@param propertyName keyof T
    function LuaUserData.AccessProperty(typeName, propertyName)
        local descriptor = RegisterType(typeName)

        raise(MakePropertyAccessible, descriptor, propertyName --[=[@as string]=])
        pcall(MakeMethodAccessible, descriptor, "get_"..propertyName)
        pcall(MakeMethodAccessible, descriptor, "set_"..propertyName)
    end
end

return Types.LFBChanges.LuaUserData