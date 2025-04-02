local Config = require("SBAI.Shared.config")
local HF = require("SBAI.Shared.helperfunctions")
local P = {
    Name="Smarter Bot AI",
    Version="1.2.0",
    Path=table.pack(...)[1]
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
            t = setmetatable({i=obj1.i, base=obj1.base, stack=HF.CopyTable(obj1.stack)}, getmetatable(obj1))
            s = obj2
        elseif type(obj1) == "string" and type(obj2) == "table" then
            t = setmetatable({i=obj2.i, base=obj2.base, stack=HF.CopyTable(obj2.stack)}, getmetatable(obj2))
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
        local tNew = setmetatable({i=t.i, base=t.base, stack=HF.CopyTable(t.stack)}, getmetatable(t))
        
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

P.namespace=setmetatable({i=0, base="SBAI", stack={}}, Namespace_mt) --[[@type Namespace]]

---@alias ModuleFuncs {Activate:fun(namespace:Namespace, options:table), Cleanup:fun()?}

local function GetModules()
    local modules = {} --[[@type table<string,ModuleFuncs>]]

    for _, v in ipairs(Config.defaults()) do
        local Activate, Cleanup = require("SBAI.Server."..v.name)
        
        modules[v.name] = {Activate=Activate, Cleanup=Cleanup}
    end

    return modules
end

P.Control = {}

---@param modules? table<string,ModuleFuncs>
function P.Control.Activate(modules)
    if modules == nil then modules = GetModules() end
    
    for postfix, module in pairs(GetModules()) do
        local namespace = P.namespace + postfix
        local options = Config.data[postfix]
        if options.enable then
            module.Activate(namespace, options)
        end
    end
end

---@param modules? table<string,ModuleFuncs>
function P.Control.Deactivate(modules)
    if modules == nil then modules = GetModules() end

    for k, _ in pairs(P.Hook.list.add) do
        Hook.Remove(k.name, k.identifier)
    end
    
    for k, _ in pairs(P.Hook.list.patch) do
        Hook.RemovePatch(k.identifier, k.className, k.methodName, k.parameterTypes, k.hookType)
    end

    for _, module in pairs(modules) do
        if module.Cleanup then module.Cleanup() end
    end
end

function P.Control.Reactivate()
    local modules = GetModules()

    P.Control.Deactivate(modules)
    P.Control.Activate(modules)
end



-- needed since SBAI.ItemGroup is reset at roundEnd
Hook.Add("roundEnd", P.namespace.base..".ItemGroup.Reset",
function()
    HF.ClearTable(P.ItemGroup)
end)

return P