local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")

local Types = {}

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

---@private
---@generic T
---@param funcName string
---@param func fun(T):any
---@param ... T
function Types.Module:pcall(funcName, func, ...)
    local success, errMsg = pcall(func, self, ...)

    if not success then
        Logger.LogError(self.namespace().."."..funcName..": "..errMsg)
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


---@class Types.TimedCharacterData
---@field private [Barotrauma.Character] {timer:Types.Timer}
---@field private timeBetween number
Types.TimedCharacterData = {}
Types.TimedCharacterData.__index = Types.TimedCharacterData

do
    local Timer = Types.Timer

    ---@public
    ---@param character Barotrauma.Character
    function Types.TimedCharacterData:Add(character)
        self[character] = {timer=Timer.new(self.timeBetween)}
    end
end

---@public
---@param character Barotrauma.Character
---@return { timer: Types.Timer }
function Types.TimedCharacterData:Get(character)
    if not self[character] then
        self:Add(character)
    end
    return self[character]
end

---@public
---@param module Types.Module
---@param timeBetween? number
---@return Types.TimedCharacterData
function Types.TimedCharacterData.new(module, timeBetween)
    timeBetween = timeBetween or module.options["timeBetween"]
    
    local t = module:RegisterTable({timeBetween=timeBetween}, "ROUND_END", "CHARACTER_DEATH")

    return setmetatable(t, Types.TimedCharacterData)
end

return Types

---@class Barotrauma.Item
---@field public GetComponent fun(componentType:Barotrauma.Item.T):Barotrauma.Item.T

---@class Barotrauma.AIObjectiveMoveItem: Barotrauma.AIObjectiveDecontainItem