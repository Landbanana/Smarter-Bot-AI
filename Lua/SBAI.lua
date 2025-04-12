local util = require("SBAI.Shared.util")

SBAI = {
    Constants=require("SBAI.Shared.constants"),
    Config=require("SBAI.Shared.config")
}

---@class Set<T>: {[T]:true}[]

---@class Namespace
---@field public i integer
---@field public base string
---@field public stack string[]
---@operator add(string):Namespace
---@operator unm:Namespace
---@operator len:integer
---@operator call:string

local Namespace_mt = {
    ---@param obj1 Namespace|string
    ---@param obj2 Namespace|string
    ---@return string
    __add=function(obj1, obj2)
        local t, s
        if type(obj1) == "table" and type(obj2) == "string" then
            t = setmetatable({i=obj1.i, base=obj1.base, stack=util.CopyTable(obj1.stack)}, getmetatable(obj1))
            s = obj2
        elseif type(obj1) == "string" and type(obj2) == "table" then
            t = setmetatable({i=obj2.i, base=obj2.base, stack=util.CopyTable(obj2.stack)}, getmetatable(obj2))
            s = obj1
        else
            error("can only add strings to a Namespace", 2)
        end

        t.i = t.i + 1
        t.stack[t.i] = s
        return t
    end,
    ---@param t Namespace
    ---@return string
    __unm=function(t)
        local tNew = setmetatable({i=t.i, base=t.base, stack=util.CopyTable(t.stack)}, getmetatable(t))
        
        if tNew.i > 0 then
            
            tNew.stack[tNew.i] = nil
            tNew.i = tNew.i - 1
        end
        return tNew
    end,
    ---@param t Namespace
    ---@return string
    __call=function(t)
        return t.base.."."..table.concat(t.stack, ".")
    end,
    ---@param t Namespace
    ---@return integer
    __len=function(t)
        return t.i + 1
    end
}

SBAI.namespace=setmetatable({i=0, base=SBAI.Constants.Acronym, stack={}}, Namespace_mt) --[[@type Namespace]]

---@alias ModuleFuncs {Activate:fun(namespace:Namespace, options:table), Cleanup:fun()?}

SBAI.Hook = setmetatable({
    list={
        add={}, --[[@type Set<{name:string, identifier:string}>]]
        patch={}--[[@type Set<{identifier:string, className:string, methodName:string, parameterTypes:string[]?, hookType:Barotrauma.LuaCsHook.HookMethodType}>]]
    },
    ---@param name string
    ---@param identifier string
    ---@param func fun(...):...
    Add=function(name, identifier, func)
        SBAI.Hook.list.add[{name=name, identifier=identifier}] = true
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
        SBAI.Hook.list.patch[{identifier=identifier, className=className, methodName=methodName, parameterTypes=parameterTypes, hookType=hookType}] = true
        Hook.Patch(identifier, className, methodName, parameterTypes, patch, hookType)
    end
}, {__index=Hook})

SBAI.LuaUserData = setmetatable({}, {__index=LuaUserData})
SBAI.itemGroup={} --[[@type table<string,Barotrauma.Item[]>]]

local function GetModules()
    local modules = {} --[[@type table<string,ModuleFuncs>]]

    for k, _ in pairs(SBAI.Config.defaults.CONFIG) do
        local Activate, Cleanup = require("SBAI.Server."..k)
        
        modules[k] = {Activate=Activate, Cleanup=Cleanup}
    end

    return modules
end

SBAI.Control = {}

---@param modules? table<string,ModuleFuncs>
function SBAI.Control.Activate(modules)
    if modules == nil then modules = GetModules() end
    
    for postfix, module in pairs(GetModules()) do
        local namespace = SBAI.namespace + postfix
        local options = SBAI.Config.data[postfix]

        if  options.enable then
            module.Activate(namespace, options)
        end
    end
end

---@param modules? table<string,ModuleFuncs>
function SBAI.Control.Deactivate(modules)
    if modules == nil then modules = GetModules() end

    for k, _ in pairs(SBAI.Hook.list.add) do
        Hook.Remove(k.name, k.identifier)
    end
    
    for k, _ in pairs(SBAI.Hook.list.patch) do
        Hook.RemovePatch(k.identifier, k.className, k.methodName, k.parameterTypes, k.hookType)
    end

    for _, module in pairs(modules) do
        if module.Cleanup then module.Cleanup() end
    end
end

function SBAI.Control.Reactivate()
    local modules = GetModules()

    SBAI.Control.Deactivate(modules)
    SBAI.Control.Activate(modules)
end

setmetatable(SBAI.itemGroup, {
    __index = function(t, k)
        local name = SBAI.namespace.base..".itemGroup."..k
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

        -- if rawget(t, k) == nil then
        --     local isRegistered, table = pcall(Util.GetItemGroup, name)

        --     if not isRegistered then
        --         Util.RegisterItemGroup(name, function(item)
        --             return item.HasTag(k)
        --         end)
        --         t[k] = Util.GetItemGroup(name)
        --     elseif rawget(t, k) == nil then
        --         t[k] = table
        --     end
        -- end
        -- return rawget(t, k)
    end
})

-- needed since SBAI.itemGroup is reset at roundEnd
Hook.Add("roundEnd", SBAI.Constants.Acronym..".itemGroup.Reset",
function()
    util.ClearTable(SBAI.itemGroup)
end)

return SBAI