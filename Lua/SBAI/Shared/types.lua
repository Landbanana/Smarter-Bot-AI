local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = {}

---@enum TYPES
Types.TYPES = {
    SET=1
}

---@class Types.Set
---@field public type Types.TYPES.SET
Types.Set = {type=Types.TYPES.SET}
Types.Set.__index = Types.Set

---@return Types.Set
function Types.Set.new()
    local t = {}

    setmetatable(t, Types.Set)
    return t
end

do
    local SET = Types.TYPES.SET

    function Types.Set.IsSet(t)
        return  type(t) == "table" and
            t.type == SET
    end
end

---@param k any
function Types.Set:Add(k)
    self[k] = true
end

---@param k any
function Types.Set:Remove(k)
    self[k] = nil
end

do
    local IsSet = Types.Set.IsSet

    ---@param t any[]|Types.Set
    function Types.Set:Update(t)
        if IsSet(t) then
            for k in next, t do
                self:Add(k)
            end
        else
            for v in t do
                self:Add(v)
            end
        end
    end
end

do
    local new = Types.Set.new
    
    ---@return Types.Set
    function Types.Set:Copy()
        local out = new()

        out:Update(self)
        return out
    end
end

---@param t any[]|Types.Set
function Types.Set:Union(t)
    local out = self:Copy()
    
    out:Update(t)
    return out
end

do
    local IsSet = Types.Set.IsSet

    local new = Types.Set.new

    ---@param t any[]|Types.Set
    function Types.Set:Intersection_Update(t)
        if not IsSet(t) then
            local temp = new()

            for v in t do
                temp:Add(v)
            end
            t = temp
        end

        for k in next, self do
            if t[k] == nil then
                self:Remove(k)
            end
        end
    end
end

---@param t any[]|Types.Set
---@return Types.Set
function Types.Set:Intersection(t)
    local out = self:Copy()

    out:Intersection_Update(t)
    return out
end

do
    local IsSet = Types.Set.IsSet

    ---@param t any[]|Types.Set
    function Types.Set:Difference_Update(t)
        if IsSet(t) then
            for k in next, t do
                self:Remove(k)
            end
        else
            for v in t do
                self:Remove(v)
            end
        end
    end
end

---@param t any[]|Types.Set
---@return Types.Set
function Types.Set:Difference(t)
    local out = self:Copy()

    out:Difference_Update(t)
    return out
end

do
    local IsSet = Types.Set.IsSet

    ---@param t any[]|Types.Set
    function Types.Set:Symmetric_Difference_Update(t)
        if IsSet(t) then
            for k in next, t do
                self[k] = not self[k] and true or nil
            end
        else
            for v in t do
                self[v] = not self[v] and true or nil
            end
        end
    end
end

---@param t any[]|Types.Set
function Types.Set:Symmetric_Difference(t)
    local out = self:Copy()

    out:Symmetric_Difference_Update(t)
    return out
end

---@return boolean
function Types.Set:IsEmpty()
    for _ in next, self do
        return false
    end
    return true
end

do
    local ClearTable = util.itertools.ClearTable

    function Types.Set:Clear()
        return ClearTable(self)
    end
end

---@return any[]
function Types.Set:ToList()
    local out = {}
    local i = 0

    for k in next, self do
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

do
    local clock = os.clock
    local D_TIMER_NOISE = Constants.D_TIMER_NOISE

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

        setmetatable(t, Types.Timer)
        t:Reset()
        return t
    end
end

do
    local AddNoise = util.AddNoise

    ---@public
    function Types.Timer:Reset()
        self.time = AddNoise(self.delay, self.noise)
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
---@field private hooks {identifier:string, name:string}[]
---@field private patches {identifier:string, className:string, methodName:string, parameterTypes:string[]?, hookType:Barotrauma.LuaCsHook.HookMethodType}[]
---@field private tables {t:table, flags:number}[]
---@field private activate fun(self:Types.Module)
---@field private deactivate fun(self:Types.Module)?
---@field public options table?
---@field public namespace Namespace?
Types.Module = {}
Types.Module.__index = Types.Module

do
    local Logger = Logger
    local remove = table.remove
    local unpack = table.unpack

    ---@private
    ---@generic T,R
    ---@param name? string
    ---@param func fun(...:T):R
    ---@param ... T
    ---@return R
    function Types.Module:pcall(name, func, ...)
        local results = {pcall(func, self, ...)}
        local success = remove(results, 1)

        name = name == nil and "" or "."..name

        if not success then
            Logger.LogError(self.namespace()..name..": "..results[1])
        else
            return unpack(results)
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
---@param name string
---@param func fun(any...):any
function Types.Module:AddHook(name, func)
    local identifier = self.namespace()

    table.insert(self.hooks, {identifier=identifier, name=name})
    Hook.Add(name, identifier, func)
end

---@public
---@generic T
---@param className `T`
---@param methodName string
---@param parameterTypes? string[]
---@param patch fun(instance:T, ptable:Barotrauma.LuaCsHook.ParameterTable)
---@param hookType Barotrauma.LuaCsHook.HookMethodType
function Types.Module:AddPatch(className, methodName, parameterTypes, patch, hookType)
    local identifier = self.namespace()

    if not hookType then
        hookType = patch
        patch = parameterTypes
        parameterTypes = nil
    end

    table.insert(self.patches, {identifier=identifier, className=className, methodName=methodName, parameterTypes=parameterTypes, hookType=hookType})
    Hook.Patch(identifier, className, methodName, parameterTypes, patch, hookType)
end

do
    local defaultNestedMethodNames = Constants.defaultNestedMethodNames

    CheckNestedMethodName = util.debug.CheckNestedMethodName
    
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
    self:Deactivate()
    if not options.enable then return end
    
    self.namespace = namespace
    self.options = options

    return self:pcall("activate", self.activate)
end

do
    local UnregisterTable = util.UnregisterTable

    ---@public
    function Types.Module:Deactivate()
        if self.namespace then
            for v in self.hooks do --[[@cast v {name:string, identifier:string}]]
                Hook.Remove(v.name, v.identifier)
            end

            for v in self.patches do --[=[@cast v {identifier:string, className:string, methodName:string, parameterTypes:string[]?, hookType:Barotrauma.LuaCsHook.HookMethodType}]=]
                Hook.RemovePatch(v.identifier, v.className, v.methodName, v.parameterTypes, v.hookType)
            end

            for v in self.tables do --[[@cast v {t:table, flags:number}]]
                UnregisterTable(v.t, v.flags)
            end

            if self.deactivate then
                return self:pcall("deactivate", self.deactivate)
            end

            self.namespace = nil
            self.options = nil
        end

        self.hooks = {}
        self.patches = {}
        self.tables = {}
    end
end

do
    local Get = util.config.Get
    local insert = table.insert
    local select = select
    local unpack = table.unpack

    ---@public
    ---@generic T
    ---@param name string
    ---@param func fun(self:Types.Module, options:table, ...:T)
    ---@param ... T
    function Types.Module:DoOption(name, func, ...)
        local newNamespace = self.namespace + name
        local options = Get(self.options, newNamespace, 2)

        if options then
            local args = {...}
            local n = select("#", ...)

            if type(options) == "table" then
                if not options.enable then return end
                insert(args, 1, options)
                n = n + 1
            end
            self.namespace = self.namespace + name
            local results = {self:pcall(nil, func, unpack(args, 1, n))}
            self.namespace = -self.namespace
            return unpack(results)
        end
    end
end

---@class Types.TimedCharacterData
---@field private [Barotrauma.Character] {timer:Types.Timer}
---@field private timeBetween number
Types.TimedCharacterData = {}
Types.TimedCharacterData.__index = Types.TimedCharacterData

do
    local new = Types.Timer.new

    ---@public
    ---@param character Barotrauma.Character
    function Types.TimedCharacterData:Add(character)
        self[character] = {timer=new(self.timeBetween)}
    end
end

---@public
---@param character Barotrauma.Character
---@return {timer:Types.Timer}
function Types.TimedCharacterData:Get(character)
    if not self[character] then
        self:Add(character)
    end
    return self[character]
end

do
    local CopyTable = util.itertools.CopyTable

    ---@public
    ---@param module Types.Module
    ---@param timeBetween? number
    ---@param init? table
    ---@return Types.TimedCharacterData
    function Types.TimedCharacterData.new(module, timeBetween, init)
        init = init and CopyTable(init) or {}
        init.timeBetween = timeBetween or module.options["timeBetween"]
        
        local t = module:RegisterTable(init, "ROUND_END", "CHARACTER_DEATH")

        return setmetatable(t, Types.TimedCharacterData)
    end
end

---@class Types.NetworkMember
---@field private handlers table<MSG,{base:fun(data:any, client:Barotrauma.Networking.Client?),set:Types.Set}>
Types.NetworkMember = {}
Types.NetworkMember.__index = Types.NetworkMember

do
    local Initialize = Networking.Initialize
    local parse = json.parse

    ---@protected
    ---@param self Types.Set
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
        ---@param t table<MSG,{base:fun(data:any, client:Barotrauma.Networking.Client?),set:Types.Set}>
        ---@param k MSG
        ---@return {base:fun(data:any),set:Types.Set}
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
---@param msg MSG
---@param func fun(data:any, client?:Barotrauma.Networking.Client):any
function Types.NetworkMember:AddHandler(msg, func)
    self.handlers[msg].set:Add(func)
end

---@public
---@param msg MSG
---@param func fun(data:any, client?:Barotrauma.Networking.Client):any
function Types.NetworkMember:AddTempHandler(msg, func)
    local handlers = self.handlers[msg].set
    local bouncer

    function bouncer(...)
        handlers:Remove(bouncer)
        return func(...)
    end

    handlers:Add(bouncer)
end

---@public
---@param msg MSG
---@param func fun(data:any, client?:Barotrauma.Networking.Client):any
function Types.NetworkMember:RemoveHandler(msg, func)
    self.handlers[msg].set:Remove(func)
end

do
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
    ---@param msg MSG
    ---@param client? Barotrauma.Networking.Client
    ---@param deliveryMethod? Barotrauma.Networking.DeliveryMethod
    ---@param jsonData table
    function Types.NetworkMember:Send(msg, client, deliveryMethod, jsonData)
        local data = Start(msg)

        deliveryMethod = deliveryMethod or DeliveryMethod.Reliable

        if jsonData then
            data.WriteString(serialize(jsonData))
        end

        return Send2(data, client and client.Connection or nil, deliveryMethod)
    end
end

return Types

---@class Barotrauma.Item
---@field public GetComponent fun(componentType:Barotrauma.Item.T):Barotrauma.Item.T

---@class Barotrauma.AIObjectiveMoveItem: Barotrauma.AIObjectiveDecontainItem