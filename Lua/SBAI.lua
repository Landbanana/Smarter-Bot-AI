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
    local True = util.True

    ---@public
    ---@param prefix? fun()
    ---@param postfix? fun()
    ---@param namespace Namespace
    ---@return ModuleController
    function ModuleController.new(prefix, postfix, namespace)
        local lastStack = namespace.stack[#namespace.stack]
        local t = {
            namespace=namespace,
            modules={},
            prefix=True or prefix,
            postfix=True or postfix
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

---@private
function ModuleController:activate()
    for k, module in next, self.modules do
        module:Activate(self.namespace + k, Config.data[k])
    end
end

---@private
function ModuleController:deactivate()
    for k, module in next, self.modules do
        module:Deactivate(Config.data[k])
    end
end

---@private
function ModuleController:reactivate()
    self:activate()
    self:deactivate()
end

---@public
function ModuleController:Activate()
    self:prefix()
    self:activate()
    self:postfix()
end

---@public
function ModuleController:Deactivate()
    self:prefix()
    self:deactivate()
    self:postfix()
end

---@public
function ModuleController:Reactivate()
    self:prefix()
    self:reactivate()
    self:postfix()
end

if  SERVER or
    Game.IsSingleplayer
then
    local allOrderData

    local function saveAllOrderData()
        if allOrderData then error("allOrderData must not be set", 2) end

        allOrderData = {}

        for character in Character.CharacterList do --[[@cast character Barotrauma.Character?]]
            if  character and
                character.IsBot
            then
                local info = character.Info

                if info then
                    local orderData = XElement.__new("orders")
                    
                    CharacterInfo.SaveOrderData(info, orderData)
                    allOrderData[character] = orderData
                end
            end
        end
    end

    local function loadAllOrderData()
        if not allOrderData then error("allOrderData must be set first", 2) end

        for character in Character.CharacterList do --[[@cast character Barotrauma.Character?]]
            if  character and
                character.IsBot
            then
                local orderData = allOrderData[character]

                if orderData then
                    local info = character.Info

                    if info then
                        CharacterInfo.ApplyOrderData(character, orderData)
                    end
                end
            end
        end

        allOrderData = nil
    end

    do
        local oldSave = Config.Save
        function Config.Save(reactivate)
            oldSave()
            Config.Load()
            if reactivate == nil or reactivate then
                SBAI.Control.Reactivate()
            end
        end
    end

    if not File.Exists(Constants.ConfigPath) then Config.Save(false) end
    SBAI.Server = ModuleController.new(saveAllOrderData, loadAllOrderData, namespace + "Server")
end

if CLIENT or Game.IsSingleplayer then
    SBAI.Client = ModuleController.new(nil, nil, namespace + "Client")
end

SBAI.Control = {}

do
    local CONF_UPDATE
    local ActivateLater
    local DeactivateLater

    if  CLIENT and
        Game.IsMultiplayer
    then
        CONF_UPDATE = networking.MSG.CONF_UPDATE

        ActivateLater = util.functools.Partial1(SBAI.Client.Activate, SBAI.Client)
        DeactivateLater = util.functools.Partial1(SBAI.Client.Deactivate, SBAI.Client)
    end

    function SBAI.Control.Activate()
        if SBAI.Server then
            SBAI.Server:Activate()
        end
        if SBAI.Client then
            if  CLIENT and
                Game.IsMultiplayer
            then
                networking.member:AddTempHandler(CONF_UPDATE, ActivateLater)
                Config.Load()
            else
                Config.Load()
                SBAI.Client:Activate()
            end
        end
    end

    function SBAI.Control.Deactivate()
        if SBAI.Server then
            SBAI.Server:Deactivate()
        end
        if SBAI.Client then
            if  CLIENT and
                Game.IsMultiplayer
            then
                networking.member:AddTempHandler(CONF_UPDATE, DeactivateLater)
                Config.Load()
            else
                Config.Load()
                SBAI.Client:Activate()
            end
        end
    end
end

function SBAI.Control.Reactivate()
    SBAI.Control.Deactivate()
    SBAI.Control.Activate()
end

return SBAI