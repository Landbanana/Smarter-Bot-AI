local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")

LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.AIObjective"], "ConcurrentObjectives")
LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.AIObjectiveOperateItem"], "ConcurrentObjectives")
LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.AIObjectiveIdle"], "ConcurrentObjectives")
LuaUserData.MakePropertyAccessible(Descriptors["Barotrauma.AIObjectiveGoTo"], "ConcurrentObjectives")

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjective"], "get_ConcurrentObjectives")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveOperateItem"], "get_ConcurrentObjectives")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveIdle"], "get_ConcurrentObjectives")
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.AIObjectiveGoTo"], "get_ConcurrentObjectives")

--local balancer = GetType("Set").new()

local allPropertyData = {}
--print("=====", tostring(#balancer), "=====")
local getSelf --[[@type fun()CommonModule]]

local stateChecker do
    local makePatch do
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

        local ID_OBJECTIVE_BASE = Constants.ID_OBJECTIVE_BASE
        local ID_OBJECTIVE_TO_BASE = Constants.ID_OBJECTIVE_TO_BASE
        local TYPE_OBJECTIVE_BASE = Constants.TYPE_OBJECTIVE_BASE

        local Partial1 = util.functools.Partial1
        
        ---@param propertyName string
        ---@param objId Barotrauma.Identifier
        ---@param subObjId? Barotrauma.Identifier
        ---@param value any
        function makePatch(propertyName, objId, subObjId, value)
            
            --balancer:Remove(table.concat({propertyName, objId.Value, subObjId.Value, tostring(value)}, "."))
            --print(table.concat({propertyName, objId.Value, subObjId.Value, tostring(value)}, "."))
            --print("=====", tostring(#balancer), "=====")
            --print(propertyName, objId, subObjId, value)
            local self = getSelf()
            local tempPropertyName = "get_"..propertyName
            local baseObjPatched = false
            local typeStr
            local patch = Partial1(subObjId == ID_EMPTY and patchBase or patchMainSubBase, propertyName)

            for k, v in next, ID_OBJECTIVE_BASE do
                if v == objId then
                    typeStr = TYPE_OBJECTIVE_BASE[k]
                    break
                end
            end

            if not typeStr then
                for k1, v1 in next, ID_OBJECTIVE_TO_BASE do
                    if k1 == objId then
                        for k2, v2 in next, ID_OBJECTIVE_BASE do
                            if v1 == v2 then
                                typeStr = TYPE_OBJECTIVE_BASE[k2]
                                break
                            end
                        end
                        break
                    end
                end
            end

            if not typeStr then error("Cannot find objective type: "..objId.Value, 4) end
            
            self.Namespace = self.Namespace + propertyName
            self.Namespace = self.Namespace + objId.Value

            subObjId = subObjId or ID_EMPTY
            self.Namespace = self.Namespace + (subObjId == ID_EMPTY and "Main" or subObjId.Value)
            
            if  not pcall(self.AddPatch, self, typeStr, tempPropertyName, nil, patch, true) and
                not baseObjPatched
            then
                self.Namespace = self.Namespace() + "Base"
                self:PatchHook(TYPE_OBJECTIVE_BASE.BASE, tempPropertyName, nil, patch, true)
                baseObjPatched = true
                self.Namespace = self.Namespace()
            end
            self.Namespace = self.Namespace + tostring(value)
            self.Namespace = self.Namespace()
            self.Namespace = self.Namespace()
            self.Namespace = self.Namespace()
            self.Namespace = self.Namespace()
        end
    end

    local select = select

    local cleanYield do
        ---@param ...any
        ---@return string, any...
        function cleanYield(...)
            local arg1, arg2, arg3, arg4 = ...
            
            if  select("#", ...) == 4
            then
                return "STORE", ...
            elseif arg1 == "ACTIVE" then
                return  "ACTIVE", arg2
            else
                return "YIELD"
            end
        end
    end

    local select = select

    stateChecker = GetType("StateMachine").new()
    stateChecker{
        CALL={
            CALL=function(stateName, isActive,  ...)
                if select("#", ...) < 4 then
                    return "YIELD", isActive
                else
                    makePatch(...)
                    return "CALL", isActive, select(5, ...)
                end
            end,
        },
        ACTIVE={
            ACTIVE=function(stateName, isActive, ...)
                return "STORE", isActive, ...
            end
        },
        STORE={
            STORE=function(stateName, isActive, ...)
                
                if isActive then
                    
                    return "CALL", isActive,  ...
                else
                    return "YIELD", isActive,  ...
                end
            end,
        },
        YIELD={
            ACTIVE=function(stateName, isActive, newIsActive, ...)
                if isActive ~= nil then
                    return "ACTIVE", newIsActive, ...
                end
            end,
            YIELD=function(stateName, isActive, ...)
                local nextState, arg1, arg2g, arg3, arg4 = cleanYield(yield())
                
                
                if nextState ==  "ACTIVE" then
                    return "ACTIVE", arg1, ...
                elseif nextState == "STORE" then
                    return "STORE", isActive, arg1, arg2g, arg3, arg4, ...
                else
                    return "YIELD", isActive, ...
                end
            end
        }
    }
end

local stateCheckerCallback = stateChecker:Start("ACTIVE", false) ---@type fun(propertyName:string, objId:Barotrauma.Identifier, subObjId?:Barotrauma.Identifier, value:any)

local uniquePropertyData do
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
                                --print(propertyName.."."..objId.Value.."."..subObjId.Value.."."..tostring(value))]
                                --balancer:Add(table.concat({propertyName, objId.Value, subObjId.Value, tostring(value)}, "."))
                                --print(table.concat({propertyName, objId.Value, subObjId.Value, tostring(value)}, "."))
                                --print("=====", tostring(#balancer), "=====")
                                stateCheckerCallback(propertyName, objId, subObjId, value)
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

        if stateCheckerCallback == nil then
           stateCheckerCallback = stateChecker:Start("ACTIVE", false)
        end

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

---@param self CommonModule
local function activate(self)
    getSelf = function() return self end
    --print("ACTIVENOW")
    if stateCheckerCallback == nil then
        stateCheckerCallback = stateChecker:Start("ACTIVE", false)
    end
    return stateCheckerCallback("ACTIVE", true)
end

local deactivate do
    local ClearTable = util.itertools.ClearTable
 
    function deactivate(self)
        ClearTable(allPropertyData)
        stateCheckerCallback = nil
        -- getSelf = nil
        -- return stateCheckerCallback()
    end
end

return GetType("CommonModule").new(activate, deactivate), ModObjProp