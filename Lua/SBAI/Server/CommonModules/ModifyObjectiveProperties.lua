local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.AIObjective"], "ConcurrentObjectives")
LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.AIObjectiveOperateItem"], "ConcurrentObjectives")
LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.AIObjectiveIdle"], "ConcurrentObjectives")
LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.AIObjectiveGoTo"], "ConcurrentObjectives")

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjective"], "get_ConcurrentObjectives")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveOperateItem"], "get_ConcurrentObjectives")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveIdle"], "get_ConcurrentObjectives")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveGoTo"], "get_ConcurrentObjectives")

local allPropertyData = {}

local getSelf --[[@type fun():Types.CommonModule]]

local makePatch

do
    local ID_EMPTY = Constants.ID_EMPTY

    ---@param propertyName string
    ---@param instance Barotrauma.AIObjective
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    local function patchMainSubBase(propertyName, instance, ptable)
        local objData = allPropertyData[propertyName][instance.Identifier]

        if objData then
            local subObj = instance.CurrentSubObjective

            if subObj then
                local value = objData[subObj.Identifier]

                if value ~= nil then
                    ptable.PreventExecution = true
                    return value
                end
            end
        end
    end

    ---@param propertyName string
    ---@param instance Barotrauma.AIObjective
    ---@param ptable Barotrauma.LuaCsHook.ParameterTable
    local function patchBase(propertyName, instance, ptable)
        local objData = allPropertyData[propertyName][instance.Identifier]

        if objData then
            local value = objData[ID_EMPTY]
            
            if value ~= nil then
                ptable.PreventExecution = true
                return value
            end
        end
    end

    local Before = Hook.HookMethodType.Before
    local ID_OBJECTIVE = Constants.ID_OBJECTIVE
    local ID_OBJECTIVE_BASE = Constants.ID_OBJECTIVE_BASE
    local TYPE_OBJECTIVE_BASE = Constants.TYPE_OBJECTIVE_BASE

    local Partial1 = util.functools.Partial1
    
    ---@param propertyName string
    ---@param objId Barotrauma.Identifier
    ---@param subObjId? Barotrauma.Identifier
    ---@param value any
    local function _makePatch(propertyName, objId, subObjId, value)
        local self = getSelf()
        local allObjIds = {ID_OBJECTIVE, ID_OBJECTIVE_BASE}
        local tempPropertyName = "get_"..propertyName
        local baseObjPatched = false
        local typeStr
        local patch = Partial1(subObjId == ID_EMPTY and patchBase or patchMainSubBase, propertyName)

        for ids in allObjIds do
            for k, v in next, ids do
                if v == objId then
                    typeStr = TYPE_OBJECTIVE_BASE[k]
                    break
                end
            end
            if typeStr then break end
        end

        self.namespace = self.namespace + propertyName
        self.namespace = self.namespace + objId.Value

        subObjId = subObjId or ID_EMPTY
        self.namespace = self.namespace + (subObjId == ID_EMPTY and "Main" or subObjId.Value)
        
        if  not pcall(self.AddPatch, self, typeStr, tempPropertyName, nil, patch, Before) and
            not baseObjPatched
        then
            self.namespace = (-self.namespace) + "Base"
            self:AddPatch(TYPE_OBJECTIVE_BASE.BASE, tempPropertyName, nil, patch, Before)
            baseObjPatched = true
            self.namespace = -self.namespace
        end
        self.namespace = self.namespace + tostring(value)
        self.namespace = -self.namespace
        self.namespace = -self.namespace
        self.namespace = -self.namespace
        self.namespace = -self.namespace
    end

    local unpack = table.unpack
    local yield = coroutine.yield

    ---@type fun(propertyName:string, objId:Barotrauma.Identifier, subObjId?:Barotrauma.Identifier, value:any)
    makePatch = coroutine.wrap(
    function(propertyName, objId, subObjId, value)
        local data = {}
        local i = 0
        
        while not getSelf do
            i = i + 1
            data[i] = {yield()}
        end

        makePatch = _makePatch

        for t in data do
            _makePatch(unpack(t, 1, 4))
        end
    end)
end

local uniquePropertyData

do
    local setmetatable = setmetatable
    local rawset = rawset
    local tostring = tostring

    local function readOnlyNewIndex(t, k, v)
        if t[k] ~= v then error(2, "Read-only table") end
    end

    uniquePropertyData = setmetatable({}, {
    __index=function(t1, k1)
        local out1 = setmetatable({propertyName=k1}, {
            __index=function(t2, k2)
                local out2 = setmetatable({
                    propertyName=t2.propertyName,
                    objId=k2
                }, {
                    __index=function(t3, k3)
                        local out3 = setmetatable({
                            propertyName=t3.propertyName,
                            objId=t3.objId,
                            subObjId=k3
                        }, {
                            __index=function(t4, k4)
                                local propertyName = t4.propertyName
                                local objId = t4.objId
                                local subObjId = t4.subObjId
                                local value = k4

                                allPropertyData[propertyName][objId][subObjId] = value
                                --print(propertyName.."."..objId.Value.."."..subObjId.Value.."."..tostring(value))
                                makePatch(propertyName, objId, subObjId, value)
                                rawset(t4, tostring(k4), tostring(value))
                                return true
                            end,
                            __newindex=readOnlyNewIndex
                        })

                        rawset(t3, k3, out3)
                        return out3
                    end,
                    __newindex=readOnlyNewIndex
                })

                rawset(t2, k2, out2)
                return out2
            end,
            __newindex=readOnlyNewIndex
        })
        
        rawset(t1, k1, out1)
        return out1
    end,
    __newindex=readOnlyNewIndex
})
end

local ModObjProp

do
    local ID_EMPTY = Constants.ID_EMPTY

    ---@param propertyName string
    ---@param objId Barotrauma.Identifier
    ---@param subObjId? Barotrauma.Identifier
    ---@param value any
    function ModObjProp(propertyName, objId, subObjId, value)
        local propertyData = allPropertyData[propertyName]

        subObjId = subObjId or ID_EMPTY
        if not propertyData then
            propertyData = {}
            allPropertyData[propertyName] = propertyData
        end

        local objData = propertyData[objId]

        if not objData then
            objData = {}
            propertyData[objId] = objData
        end

        local subObjData = objData[subObjId]
        
        if not subObjData then
            subObjData = value
            objData[subObjId] = subObjData
        elseif subObjData ~= value then
            local suffix

            if subObjId then
                suffix = "/"..subObjId.Value
            else
                suffix = ""
            end
            error("Duplicate objId ("..objId.Value..suffix..") for property: "..propertyName, 2)
        else
            
            return
        end

        local _ = uniquePropertyData[propertyName][objId][subObjId][value]
        
        --makePatch(propertyName, objId, subObjId, value)
    end
end

---@param self Types.CommonModule
local function activate(self)
    getSelf = function() return self end
end

local deactivate

do
    local ClearTable = util.itertools.ClearTable

    function deactivate(self)
        ClearTable(allPropertyData)
    end
end

return Types.CommonModule.new(activate, deactivate), ModObjProp