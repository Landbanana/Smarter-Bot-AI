local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = {}


---@enum TYPES
Types.TYPES = {
    SET=1
}

---@class Set<T>: {[T]: true}
---@field public type Types.TYPES.SET
Types.Set = {type=Types.TYPES.SET}
Types.Set.__index = Types.Set

do
    local next = next
    
    ---@generic T
    ---@param t Set<T>
    ---@param k T
    ---@return T
    local function _iter(t, k)
        k = next(t, k)
        return k
    end

    ---@private
    ---@generic T
    ---@param self Set<T>
    ---@return fun(t:Set<T>, k:T):T
    ---@return Set<T>
    function Types.Set:__iterator()
        return _iter, self
    end
end

---@private
---@return integer
function Types.Set:__len()
    local i = 0

    for _ in self do
        i = i + 1
    end
    return i
end

do
    local Set = Types.Set
    local setmetatable = setmetatable

    ---@generic T
    ---@param t table
    ---@return Set<T>
    function Types.Set.new(t)
        if t then
            local _t = {}

            for v in t do
                _t[v] = true
            end
            return setmetatable(_t, Set)
        end
        return setmetatable({}, Set)
    end
end

do
    local SET = Types.TYPES.SET

    function Types.Set.IsSet(t)
        return  type(t) == "table" and
            t.type == SET
    end
end

---@generic T
---@param self Set<T>
---@param k T
function Types.Set:Add(k)
    self[k] = true
end

---@generic T
---@param self Set<T>
---@param k T
function Types.Set:Remove(k)
    self[k] = nil
end

---@generic T
---@param self Set<T>
---@param t T[]|Set<T>|fun(...):T
function Types.Set:Update(t)
    for k in t do
        self:Add(k)
    end
end

do
    local new = Types.Set.new
    
    ---@generic T
    ---@param self Set<T>
    ---@return Set<T>
    function Types.Set:Copy()
        local out = new()

        out:Update(self)
        return out
    end
end

---@generic T
---@param self Set<T>
---@param t T[]|Set<T>|fun(...):T
function Types.Set:Union(t)
    local out = self:Copy()
    
    out:Update(t)
    return out
end

do
    local IsSet = Types.Set.IsSet

    local new = Types.Set.new
    local next = next

    ---@generic T
    ---@param self Set<T>
    ---@param t T[]|Set<T>|fun(...):T
    function Types.Set:Intersection_Update(t)
        if not IsSet(t) then
            local _t = new()

            for v in t do
                _t:Add(v)
            end
            t = _t
        end

        for k in next, self do
            if t[k] == nil then
                self:Remove(k)
            end
        end
    end
end

---@generic T
---@param self Set<T>
---@param t T[]|Set<T>|fun(...):T
---@return Set<T>
function Types.Set:Intersection(t)
    local out = self:Copy()

    out:Intersection_Update(t)
    return out
end

---@generic T
---@param self Set<T>
---@param t T[]|Set<T>|fun(...):T
function Types.Set:Difference_Update(t)
    for k in t do
        self:Remove(k)
    end
end

---@generic T
---@param self Set<T>
---@param t T[]|Set<T>|fun(...):T
---@return Set<T>
function Types.Set:Difference(t)
    local out = self:Copy()

    out:Difference_Update(t)
    return out
end

---@generic T
---@param self Set<T>
---@param t T[]|Set<T>|fun(...):T
function Types.Set:Symmetric_Difference_Update(t)
    for k in t do
        self[k] = not self[k] and true or nil
    end
end

---@generic T
---@param self Set<T>
---@param t T[]|Set<T>|fun(...):T
function Types.Set:Symmetric_Difference(t)
    local out = self:Copy()

    out:Symmetric_Difference_Update(t)
    return out
end

do
    local next = next

    ---@generic T
    ---@param self Set<T>
    ---@return boolean
    function Types.Set:IsEmpty()
        return next(self) == nil
    end
end

do
    local ClearTable = util.itertools.ClearTable

    ---@generic T
    ---@param self Set<T>
    function Types.Set:Clear()
        return ClearTable(self)
    end
end

---@generic T
---@param self Set<T>
---@return T[]
function Types.Set:ToList()
    local out = {}
    local i = 0

    for k in self do
        i = i + 1
        out[i] = k
    end
    return out
end

---@class Types.Timer
---@field private lastClock number
---@field private time number
---@field private delay number
---@field private noise number
Types.Timer = {}
Types.Timer.__index = Types.Timer

---@private
function Types.Timer:ResetNoNoise()
    self.time = self.delay
end

do
    local clock = os.clock
    local D_TIMER_NOISE = Constants.D_TIMER_NOISE
    local Timer = Types.Timer

    ---@public
    ---@param delay Types.Timer
    ---@param noise number
    ---@return Types.Timer
    function Types.Timer.new(delay, noise)
        local t = {
            lastClock=clock(),
            delay=delay,
            noise=noise or D_TIMER_NOISE
        }

        if not noise or noise <= 0 then
            t.Reset = Timer.ResetNoNoise
        end

        setmetatable(t, Timer)
        t:Reset()
        return t
    end
end

do
    local AddNoise = util.mathtools.AddNoise

    ---@public
    function Types.Timer:Reset()
        self.time = AddNoise(self.delay, self.noise)
    end
end

---@public
---@param deltaTime number
---@return boolean
function Types.Timer:Update(deltaTime)
    self.time = self.time - deltaTime
    if self.time <= 0 then
        self:Reset()
        return true
    end
    
    return false
end

do
    local clock = os.clock
    local difftime = os.difftime

    ---@public
    ---@return boolean
    function Types.Timer:UpdateClock()
        local curClock = clock()
        local deltaTime = difftime(curClock, self.lastClock)

        self.lastClock = curClock
        return self:Update(deltaTime)
    end
end

---@class Types.Module
---@field private commonModules table<string,Types.CommonModule>
---@field private hooks {identifier:string, name:string}[]
---@field private initializers fun()[]
---@field private methodRegistry Set<string>
---@field private patches {identifier:string, className:string, methodName:string, parameterTypes:string[]?, hookType:Barotrauma.LuaCsHook.HookMethodType}[]
---@field private tables {t:table, flags:number}[]
---@field private activate fun(self:Types.Module)
---@field private deactivate fun(self:Types.Module)?
---@field public options table?
---@field public namespace Namespace?
Types.Module = {}
Types.Module.__index = Types.Module

do
    local GetArgs = util.functools.GetArgs
    local LogError = Logger.LogError
    local remove = table.remove
    local unpack = table.unpack

    ---@protected
    ---@generic T,R
    ---@param name? string
    ---@param func fun(...:T):R
    ---@param ... T
    ---@return boolean, R
    function Types.Module:pcall(name, func, ...)
        local results, n = GetArgs(pcall(func, self, ...))
        local success = remove(results, 1)

        n = n - 1

        name = name == nil and "" or "."..name

        if not success then
            LogError(self.namespace()..name..": "..unpack(results))
            return false
        else
            return true, unpack(results, 1, n)
        end
    end
end

do
    local Game = Game

    ---@protected
    function Types.Module:init()
        if not Game.GameSession or not self.initializers then return end
        for func in self.initializers do --[[@cast func fun()]]
            func()
        end
    end
end

---@public
---@param activate fun(self: Types.Module)
---@param deactivate? fun(self: Types.Module)
---@return Types.Module
function Types.Module.new(activate, deactivate)
    local t = {}

    t.activate = activate
    t.deactivate = deactivate

    return setmetatable(t, Types.Module)
end

---@public
---@return string
function Types.Module:GetSection()
    local stack = self.namespace.stack

    return stack[#stack]
end

do
    local AutoRegisterType = util.AutoRegisterType
    local CreateStatic = LuaUserData.CreateStatic
    local upcall = util.debug.upcall

    local Statics = setmetatable({}, {
        ---@param self table<string,System.Object>
        ---@param typeName string
        ---@return System.Object
        __index=function(self, typeName)
            upcall(AutoRegisterType, typeName)

            local static = upcall(CreateStatic, typeName)

            self[typeName] = static
            return static
        end
    })

    ---@generic T
    ---@param typeName `T`
    ---@return function|T
    function Types.Module:RegisterStatic(typeName)
        return Statics[typeName]
    end
end

do
    --local AutoRegisterType = util.AutoRegisterType
    local CreateEnumTable = LuaUserData.CreateEnumTable
    local upcall = util.debug.upcall

    local Enums = setmetatable({}, {
        ---@param self table<string,System.Object>
        ---@param typeName string
        ---@return System.Object
        __index=function(self, typeName)
            local enum = upcall(CreateEnumTable, typeName)

            self[typeName] = enum
            return enum
        end
    })

    ---@generic T
    ---@param typeName `T`
    ---@return function|T
    function Types.Module:RegisterEnumTable(typeName)
        return Enums[typeName]
    end
end

do
    local G = _G

    local AutoRegisterType = util.AutoRegisterType
    local DoWithTemporaryRegistrations = util.DoWithTemporaryRegistrations
    local MakePropertyAccessible = LuaUserData.MakePropertyAccessible
    local MakeFieldAccessible = LuaUserData.MakeFieldAccessible
    local upcall = util.debug.upcall

    local function getVar(containingVar, varName, varType)
        return DoWithTemporaryRegistrations({varType}, function() return containingVar[varName] end)
    end

    ---@public
    ---@generic T
    ---@param varPath string
    ---@param varType `T`
    ---@param containingVarType string
    ---@param callBack fun(strongRef:T)
    function Types.Module:RegisterStrongRef(varPath, varType, containingVarType, callBack)
        local globalOrTypeName, varName = varPath:match("^(.+)%.([^%.]+)$") --[[@type string, string]]
        
        local descriptor = upcall(AutoRegisterType, containingVarType)

        if not pcall(MakeFieldAccessible, descriptor, varName) then upcall(MakePropertyAccessible, descriptor, varName) end

        local out

        if containingVarType then
            function out()
                local globalVar = G

                for field in globalOrTypeName:gmatch("([^%.]+)%.?") do
                    globalVar = globalVar[field]
                end

                return getVar(globalVar, varName, varType)
            end
        else
            function out()
                return getVar(self:RegisterStatic(globalOrTypeName), varName, varType)
            end
        end
        
        self:AddInit(function() return callBack(out()) end)

        -- if isGlobal then
        --     function doCallBack()
        --         if not Game.GameSession then return end
        --         DoWithTemporaryRegistrations({refType},
        --         function()
        --             local classObj = G

        --             for field in globalOrClassName:gmatch("([^%.]+)%.?") do
        --                 classObj = classObj[field]
        --             end

        --             return callBack(classObj[refName])
        --         end)
        --     end
        -- else
        --     local fullName = globalOrClassName.."."..refName

        --     upcall(isProperty and MakePropertyAccessible or MakeFieldAccessible, upcall(AutoRegisterType, globalOrClassName), fullName)

        --     local classObj = self.Statics[globalOrClassName]

        --     if not classObj then error("Unable to find globalOrClassName: "..(globalOrClassName or "nil")) end
        --     function doCallBack()
        --         if not Game.GameSession then return end
        --         DoWithTemporaryRegistrations({refType},
        --         function()
        --             return callBack(classObj[refName])
        --         end)
        --     end
        -- end
        -- self:AddInit(doCallBack)
    end
end

do
    local GetArgs = util.functools.GetArgs
    local require = require
    local unpack = table.unpack

    ---@public
    ---@param requirePath string
    ---@return ...
    function Types.Module:AddCommonModule(requirePath)
        local commonModules = self.commonModules
        
        if not commonModules then
            commonModules = {}
            self.commonModules = commonModules
        end

        local commonModule = commonModules[requirePath]
        local requireOut, n = GetArgs(require(requirePath))

        if commonModule == nil then
            local newNamespace = -self.namespace
            
            commonModule = requireOut[1]
            commonModules[requirePath] = commonModule
            
            newNamespace.i = 0
            newNamespace.stack = {}

            for stackAdd in requirePath:sub(Constants.Acronym:len() + 2):gmatch("([^%.]+)%.?") do
                newNamespace = newNamespace + stackAdd
            end
            
            commonModule:Activate(self, newNamespace)
        end
        return unpack(requireOut, 2, n)
    end
end

---@public
---@param name string
---@param func fun(...):any
function Types.Module:AddHook(name, func)
    if not self.hooks then self.hooks = {} end
    local identifier = self.namespace()

    table.insert(self.hooks, {identifier=identifier, name=name})
    Hook.Add(name, identifier, func)
end

do
    local AutoRegisterType = util.AutoRegisterType
    local insert = table.insert
    local MakeMethodAccessible = LuaUserData.MakeMethodAccessible
    local MakePropertyAccessible = LuaUserData.MakePropertyAccessible
    local Patch = Hook.Patch
    local upcall = util.debug.upcall

    ---@public
    ---@generic T
    ---@param className `T`
    ---@param methodName string
    ---@param parameterTypes? string[]
    ---@param patch fun(instance:T, ptable:Barotrauma.LuaCsHook.ParameterTable)|`function(instance, ptable) end`
    ---@param hookType Barotrauma.LuaCsHook.HookMethodType
    ---|`Hook.HookMethodType.Before`
    ---|`Hook.HookMethodType.After`
    function Types.Module:AddPatch(className, methodName, parameterTypes, patch, hookType)
        if not self.patches then self.patches = {} end

        local identifier = self.namespace()
        
        local descriptor = upcall(AutoRegisterType, className)

        if not hookType then
            hookType = patch
            patch = parameterTypes
            parameterTypes = nil
        end

        if not pcall(Patch, identifier, className, methodName, parameterTypes, patch, hookType) then
            if  methodName:match("^[gs]et_(.+)$") then
                upcall(MakePropertyAccessible, descriptor, methodName:sub(5))
            else
                upcall(MakeMethodAccessible, descriptor, methodName)
            end
            upcall(Patch, identifier, className, methodName, parameterTypes, patch, hookType)
        end

        insert(self.patches, {identifier=identifier, className=className, methodName=methodName, parameterTypes=parameterTypes, hookType=hookType})
    end
end

do
    local AddMethod = util.AddMethod
    local new = Types.Set.new

    ---@generic T
    ---@param className `T`
    ---@param methodName string
    ---@param method fun(instance:T, ...):...
    function Types.Module:AddMethod(className, methodName, method)
        if not self.methodRegistry then
            self.methodRegistry = new()
        end
        AddMethod(className, methodName, method)
        return self.methodRegistry:Add(className.."."..Constants.Acronym.."_"..methodName)
    end
end

do
    local defaultNestedMethodNames = Constants.defaultNestedMethodNames

    local CheckNestedMethodName = util.debug.CheckNestedMethodName
    
    ---@public
    ---@generic T
    ---@param className `T`
    ---@param mainMethodName string
    ---@param nestedMethodName string
    ---@param parameterTypes? string[]
    ---@param patch fun(instance:T, ptable:Barotrauma.LuaCsHook.ParameterTable)
    ---@param hookType Barotrauma.LuaCsHook.HookMethodType
    function Types.Module:AddNestedPatch(className, mainMethodName, nestedMethodName, parameterTypes, patch, hookType)
        local pattern = "<"..mainMethodName..">g__"..nestedMethodName.."|"
        local methodName = CheckNestedMethodName(className, mainMethodName, nestedMethodName, defaultNestedMethodNames[className.."["..pattern.."]"])

        return self:AddPatch(className, methodName, parameterTypes, patch, hookType)
    end
end

do
    local CLEAR_REG = util.CLEAR_REG

    local RegisterTable = util.RegisterTable
    local insert = table.insert

    ---@public
    ---@param init? table
    ---@param ... util.CLEAR_REG
    ---@return table
    function Types.Module:RegisterTable(init, ...)
        if not self.tables then self.tables = {} end
        local flags = 0

        for flag in {...} do --[[@cast flag util.CLEAR_REG]]
            flags = flags + CLEAR_REG[flag]
        end

        local t = {}

        RegisterTable(t, init, flags)
        insert(self.tables, {t=t, flags=flags})
        return t
    end
end

---@public
---@param namespace Namespace
---@param options table
function Types.Module:Activate(namespace, options)
    self:Deactivate(options)
    if not options.enable then return end
    
    self.namespace = namespace
    self.options = options

    for name, func in next, {activate=self.activate, init=self.init} do
        if not self:pcall(name, func) then return self:Deactivate(options) end
    end

    -- if self.commonModules then
    --     for requirePath, commonModule in next, self.commonModules do --[[@cast commonModule Types.CommonModule]]
    --         local newNamespace = -namespace
            
    --         newNamespace.i = 0
    --         newNamespace.stack = {}

    --         for stackAdd in requirePath:sub(Constants.Acronym:len() + 2):gmatch("([^%.]+)%.?") do
    --             newNamespace = newNamespace + stackAdd
    --         end
    --         commonModule:Activate(self, newNamespace)
    --     end
    -- end
    
    self:AddHook("roundStart", function() return self:init() end)
end

do
    local insert = table.insert

    ---@public
    ---@param func fun()
    ---|`fun() end`
    function Types.Module:AddInit(func)
        if not self.initializers then self.initializers = {} end
        insert(self.initializers, func)
    end
end

do
    local RemoveHook = Hook.Remove
    local RemoveMethod = util.RemoveMethod
    local RemovePatch = Hook.RemovePatch
    local UnregisterTable = util.UnregisterTable

    ---@public
    ---@param options table
    function Types.Module:Deactivate(options)
        if self.namespace then
            self.options = options

            if self.commonModules then
                for v in self.commonModules do  --[[@cast v Types.CommonModule]]
                    v:Deactivate(self)
                end
            end

            if self.hooks then
                for v in self.hooks do --[[@cast v {name:string, identifier:string}]]
                    RemoveHook(v.name, v.identifier)
                end
            end

            if self.methodRegistry then
                for v in self.methodRegistry do --[[@cast v string]]
                    local className, methodName = v:match("^(.+)%.([%w_]+)$") --[[@type string,string]]

                    RemoveMethod(className, methodName)
                end
            end

            if self.patches then
                for v in self.patches do --[=[@cast v {identifier:string, className:string, methodName:string, parameterTypes:string[]?, hookType:Barotrauma.LuaCsHook.HookMethodType}]=]
                    RemovePatch(v.identifier, v.className, v.methodName, v.parameterTypes, v.hookType)
                end
            end

            if self.tables then
                for v in self.tables do --[[@cast v {t:table, flags:number}]]
                    UnregisterTable(v.t, v.flags)
                end
            end

            if self.deactivate then
                self:pcall("deactivate", self.deactivate)
            end

            self.namespace = nil
            self.options = nil
        end
        self.commonModules = nil
        self.initializers = nil
        self.hooks = nil
        self.methodRegistry = nil
        self.patches = nil
        self.tables = nil
    end
end

do
    local GetArgs = util.functools.GetArgs
    local Get = util.config.Get
    local unpack = table.unpack

    ---@public
    ---@generic T
    ---@param name string?
    ---@param func fun(self:Types.Module, options:table, ...:T)
    ---@param ... T
    ---@return false|any
    function Types.Module:DoOption(name, func, ...)
        local newNamespace = name and self.namespace + name or self.namespace
        local options = Get(self.options, newNamespace, 2)

        if options then
            if  type(options) == "table" and
                not options.enable
            then
                return false
            end
            
            if name then
                self.namespace = self.namespace + name
            end

            local results, n = GetArgs(self:pcall(nil, func, options, ...))

            if name then
                self.namespace = -self.namespace
            end
            return unpack(results, 1, n)
        end
    end
end

---@class Types.CommonModule: Types.Module
---@field private moduleRefs Set<Types.Module>
Types.CommonModule = setmetatable({}, Types.Module)
Types.CommonModule.__index = Types.CommonModule

---@param activate fun(self: Types.Module)
---@param deactivate? fun(self: Types.Module)
---@return Types.CommonModule
function Types.CommonModule.new(activate, deactivate)
    local t = Types.Module.new(activate, deactivate)

    return setmetatable(t, Types.CommonModule)
end

do
    local Activate = Types.Module.Activate
    local new = Types.Set.new

    ---@public
    ---@param callingModule Types.Module
    ---@param namespace Namespace
    function Types.CommonModule:Activate(callingModule, namespace)
        if not self.moduleRefs then self.moduleRefs = new() end
        if self.moduleRefs:IsEmpty() then Activate(self, namespace, {enable=true}) end
        return self.moduleRefs:Add(callingModule)
    end
end

---@public
---@param callingModule Types.Module
function Types.CommonModule:Deactivate(callingModule)
    if callingModule.new == nil then return end
    if not self.moduleRefs then return end
    self.moduleRefs:Remove(callingModule)
    if self.moduleRefs:IsEmpty() then
        Types.Module.Deactivate(self, {enable=false})
        self.moduleRefs = nil
    end
end

---@class Types.TimedCharacterData
---@field private timer Types.Timer
---@field public [any] any
Types.TimedCharacterData = {}
Types.TimedCharacterData.__index = Types.TimedCharacterData

do
    local new = Types.Timer.new

    ---@public
    ---@param delay number
    ---@param noise? number
    ---@return Types.TimedCharacterData
    function Types.TimedCharacterData.new(delay, noise)
        local t = {timer=new(delay, noise)}

        return setmetatable(t, Types.TimedCharacterData)
    end
end

---@public
function Types.TimedCharacterData:Reset()
    return self.timer:Reset()
end

---@public
---@param deltaTime number
---@return boolean
function Types.TimedCharacterData:Update(deltaTime)
    return self.timer:Update(deltaTime)
end

---@public
---@return boolean
function Types.TimedCharacterData:UpdateClock()
    return self.timer:UpdateClock()
end

---@class Types.AllTimedCharacterData
---@field private [Barotrauma.Character] Types.TimedCharacterData
---@field private timeBetween number
---@field protected delay number
---@field protected noise number
Types.AllTimedCharacterData = {}
Types.AllTimedCharacterData.__index = Types.AllTimedCharacterData

do
    local CopyTable = util.itertools.CopyTable

    ---@public
    ---@param module Types.Module
    ---@param delay? number
    ---@param noise? number
    ---@param init? table
    ---@return Types.AllTimedCharacterData
    function Types.AllTimedCharacterData.new(module, delay, noise, init)
        init = init and CopyTable(init) or {}
        init.delay = delay or module.options["timeBetween"]
        init.noise = noise

        local t = module:RegisterTable(init, "ROUND_END", "CHARACTER_DEATH")

        return setmetatable(t, Types.AllTimedCharacterData)
    end
end

do
    local new = Types.TimedCharacterData.new

    ---@public
    ---@param character Barotrauma.Character
    function Types.AllTimedCharacterData:Add(character)
        self[character] = new(self.delay, self.noise)
    end
end

---@public
---@param character Barotrauma.Character
---@return Types.TimedCharacterData
function Types.AllTimedCharacterData:Get(character)
    if not self[character] then
        self:Add(character)
    end
    return self[character]
end

---@class Types.NetworkMember
---@field private handlers table<MSG,{base:fun(data:any, client:Barotrauma.Networking.Client?),set:Set}>
Types.NetworkMember = {}
Types.NetworkMember.__index = Types.NetworkMember

do
    local Initialize = Networking.Initialize
    local parse = json.parse

    ---@protected
    ---@param self Set
    ---@param data Barotrauma.Networking.IReadMessage
    ---@param client? Barotrauma.Networking.Client
    ---@return any
    local function BaseHandler(self, data, client)
        local dataString = data.ReadString()
        local jsonData

        if dataString and dataString ~= "" then
            jsonData = parse(dataString)
        end

        for func in next, self do
            func(jsonData, client)
        end
    end

    local new = Types.Set.new
    local Partial1 = util.functools.Partial1
    local Receive = Networking.Receive

    local handlersMT = {
        ---@param t table<MSG,{base:fun(data:any, client:Barotrauma.Networking.Client?),set:Set}>
        ---@param k MSG
        ---@return {base:fun(data:any),set:Set}
        __index=function(t, k)
            t[k] = {set=new()}
            
            local handler = Partial1(BaseHandler, t[k].set)

            t[k].base=handler

            Receive(k, handler)
            return t[k]
        end
    }

    ---@public
    ---@return Types.NetworkMember
    function Types.NetworkMember.new()
        Initialize()

        local t = {
            handlers=setmetatable({}, handlersMT)
        }
        return setmetatable(t, Types.NetworkMember)
    end
end

---@public
---@param msgType MSG
---@param func fun(data:any, client?:Barotrauma.Networking.Client):any
function Types.NetworkMember:AddHandler(msgType, func)
    self.handlers[msgType].set:Add(func)
end

---@public
---@param msgType MSG
---@param func fun(data:any, client?:Barotrauma.Networking.Client):any
function Types.NetworkMember:AddTempHandler(msgType, func)
    local handlers = self.handlers[msgType].set
    local bouncer
    
    function bouncer(...)
        handlers:Remove(bouncer)
        return func(...)
    end

    handlers:Add(bouncer)
end

---@public
---@param msgType MSG
---@param func fun(data:any, client?:Barotrauma.Networking.Client):any
function Types.NetworkMember:RemoveHandler(msgType, func)
    self.handlers[msgType].set:Remove(func)
end

do
    local Reliable = DeliveryMethod.Reliable

    local serialize = json.serialize
    local Send2 = Networking.Send
    local Start = Networking.Start

    if CLIENT then
        local oldSend = Send2

        ---@param data Barotrauma.Networking.IWriteMessage
        ---@param client Barotrauma.Networking.Client
        ---@param deliveryMethod Barotrauma.Networking.DeliveryMethod
        function Send2(data, client, deliveryMethod)
            return oldSend(data, deliveryMethod)
        end
    end

    ---@public
    ---@param msgType MSG
    ---@param client? Barotrauma.Networking.Client
    ---@param deliveryMethod? Barotrauma.Networking.DeliveryMethod
    ---@param data? table
    function Types.NetworkMember:Send(msgType, client, deliveryMethod, data)
        local msg = data

        if  not data or
            type(data) == "table"
        then
            msg = Start(msgType)
            if data then
                msg.WriteString(serialize(data))
            end
        end

        deliveryMethod = deliveryMethod or Reliable

        return Send2(msg, client and client.Connection or nil, deliveryMethod)
    end
end

return Types

---@class Barotrauma.Item
---@field public GetComponent fun(componentType:Barotrauma.Item.T):Barotrauma.Item.T

---@class Barotrauma.AIObjectiveMoveItem: Barotrauma.AIObjectiveDecontainItem

---@class Barotrauma.Character
---@field public AIController Barotrauma.AIController|Barotrauma.HumanAIController|Barotrauma.EnemyAIController
