local util = require("SBAI.Shared.util")
local Constants = require("SBAI.Shared.constants")

local SBAI = {
    Constants=require("SBAI.Shared.constants"),
    Config=require("SBAI.Shared.config")
}

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

local namespace = setmetatable({i=0, base=SBAI.Constants.Acronym, stack={}}, Namespace_mt) --[[@type Namespace]]
local modules = {} --[[@type table<string,Types.Module>]]

for k, _ in pairs(SBAI.Config.defaults.CONFIG) do
    modules[k] = require("SBAI.Server.Modules."..k)
end

SBAI.namespace = namespace
SBAI.Control = {}

do
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

    function SBAI.Control.Activate()
        saveAllOrderData()
        
        for k in next, SBAI.Config.defaults.CONFIG do
            modules[k]:Activate(namespace + k, SBAI.Config.data[k])
        end

        loadAllOrderData()
    end

    function SBAI.Control.Deactivate()
        local loadOrders

        if allOrderData then
            loadOrders = false
        else
            saveAllOrderData()
            loadOrders = true
        end

        for k in next, SBAI.Config.defaults.CONFIG do
            modules[k]:Deactivate()
        end

        if loadOrders then loadAllOrderData() end
    end
end

if SERVER or Game.IsSingleplayer then
    local oldSave = SBAI.Config.Save

    SBAI.Config.Save = function(reactivate)
        oldSave()
        if reactivate == nil or reactivate then SBAI.Control.Activate() end
    end

    SBAI.Config.Load()
    if not File.Exists(SBAI.Constants.ConfigPath) then SBAI.Config.Save(false) end
end

return SBAI