local util = require("SBAI.Shared.util")
local Config = require("SBAI.Shared.config")
local Constants = require("SBAI.Shared.constants")
local networking = require("SBAI.Shared.networking")

local SBAI = {}

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
            t = setmetatable({i=obj1.i, base=obj1.base, stack=util.itertools.CopyTable(obj1.stack)}, getmetatable(obj1))
            s = obj2
        elseif type(obj1) == "string" and type(obj2) == "table" then
            t = setmetatable({i=obj2.i, base=obj2.base, stack=util.itertools.CopyTable(obj2.stack)}, getmetatable(obj2))
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
        local tNew = setmetatable({i=t.i, base=t.base, stack=util.itertools.CopyTable(t.stack)}, getmetatable(t))
        
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

local namespace = setmetatable({i=0, base=Constants.Acronym, stack={}}, Namespace_mt) --[[@type Namespace]]

SBAI.namespace = namespace

---@class ModuleController
---@field private namespace Namespace
---@field private modules {[string]:Types.Module}
---@field private prefix fun()
---@field private postfix fun()
local ModuleController = {}
ModuleController.__index = ModuleController

do
    local path = Constants.Path
    
    local CleanUpPath = ToolBox.CleanUpPath
    local Exists = File.Exists

    ---@public
    ---@param namespace Namespace
    ---@return ModuleController
    function ModuleController.new(namespace)
        local lastStack = namespace.stack[#namespace.stack]
        local t = {
            namespace=namespace,
            modules={}
        }

        local specifiedPath = CleanUpPath(path.."/Lua/SBAI/"..lastStack.."/Modules/")

        for k in next, Config.defaults.CONFIG do
            
            if Exists(specifiedPath..k..".lua") then
                t.modules[k] = require("SBAI."..lastStack..".Modules."..k)
            end
        end
        return setmetatable(t, ModuleController)
    end
end

---@public
function ModuleController:Activate()
    for k, module in next, self.modules do
        module:Activate(self.namespace + k, Config.data[k])
    end
end

---@public
function ModuleController:Deactivate()
    for k, module in next, self.modules do
        module:Deactivate(Config.data[k])
    end
end

function ModuleController:Reactivate()
    self:Deactivate()
    self:Activate()
end

SBAI.Control = {}

if  SERVER or
    Game.IsSingleplayer
then
    local SaveOrders = util.SaveOrders
    local LoadOrders = util.LoadOrders

    function SBAI.Control.Reactivate()
        SaveOrders()
        SBAI.Control.Deactivate()
        SBAI.Control.Activate()
        LoadOrders()
    end

    local oldSave = Config.Save

    function Config.Save()
        oldSave()
        Config.Load()
        SBAI.Control.Reactivate()
    end

    SBAI.Server = ModuleController.new(namespace + "Server")
else
    ---@param isUpdated boolean
    function SBAI.Control.Reactivate(isUpdated)
        SBAI.Control.Deactivate()
        SBAI.Control.Activate(isUpdated)
    end
end

if  CLIENT or
    Game.IsSingleplayer
then
    SBAI.Client = ModuleController.new(namespace + "Client")
end

if  CLIENT and
    Game.IsMultiplayer
then
    local CONF_UPDATE = networking.MSG.CONF_UPDATE
    local member =  networking.member

    local ActivateLater = util.functools.Partial1(SBAI.Client.Activate, SBAI.Client)

    function SBAI.Control.Activate(isUpdated)
        if isUpdated then
            SBAI.Client:Activate()
        else
            member:AddTempHandler(CONF_UPDATE, ActivateLater)
            Config.Load()
        end
    end

    function SBAI.Control.Deactivate()
        SBAI.Client:Deactivate()
    end

    member:AddHandler(CONF_UPDATE,
    function(data, client)
        Config.data = data

        SBAI.Control.Reactivate(true)
    end)
elseif SERVER then
    function SBAI.Control.Activate()
        Config.Load()
        SBAI.Server:Activate()
    end

    function SBAI.Control.Deactivate()
        SBAI.Server:Deactivate()
    end
else
    function SBAI.Control.Activate()
        Config.Load()
        SBAI.Server:Activate()
        SBAI.Client:Activate()
    end

    function SBAI.Control.Deactivate()
        SBAI.Server:Deactivate()
        SBAI.Client:Deactivate()
    end
end

return SBAI