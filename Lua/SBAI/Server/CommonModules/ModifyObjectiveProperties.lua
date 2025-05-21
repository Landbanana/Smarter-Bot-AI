local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

local mod = {}

local objIdToTypeName = {} --[[@type table<Barotrauma.Identifier,string>]]
local allPropertyData = {} --[[@type table<string,table<Barotrauma.Identifier,any>>]]
local allMainSubPropertyData = {} --[[@type table<string,table<Barotrauma.Identifier,table<Barotrauma.Identifier,any>>>]]

---@param objId Barotrauma.Identifier
---@param objSuffix string
local function mapIdToTypeName(objId, objSuffix)
    local typeName = objIdToTypeName[objId]
    local newTypeName = "Barotrauma.AIObjective"..objSuffix

    if typeName then
        if typeName ~= newTypeName then
            error("Mismatching objective typeName: (old) "..typeName..", "..newTypeName, 3)
        end
    else
        objIdToTypeName[objId] = newTypeName
    end
end

---@param objId Barotrauma.Identifier
---@param objSuffix string
---@param propertyName string
---@param value any
function mod.ModObjProp(objId, objSuffix, propertyName, value)
    local propertyData = allPropertyData[propertyName]

    if not propertyData then
        propertyData = {}
        allPropertyData[propertyName] = propertyData
    elseif propertyData[objId] then
        error("Duplicate objId ("..objId.Value..") for property: "..propertyName, 2)
    end

    mapIdToTypeName(objId, objSuffix)
    propertyData[objId] = value
end

---@param mainObjId Barotrauma.Identifier
---@param mainObjSuffix string
---@param subObjId Barotrauma.Identifier
---@param propertyName string
---@param value any
function mod.ModMainObjProp(mainObjId, mainObjSuffix, subObjId, propertyName, value)
    local mainSubPropertyData = allMainSubPropertyData[propertyName]

    if not mainSubPropertyData then
        mainSubPropertyData = {}
        allMainSubPropertyData[propertyName] = mainSubPropertyData
    end

    local mainObjData = mainSubPropertyData[mainObjId]

    if not mainObjData then
        mainObjData = {}
        mainSubPropertyData[mainObjId] = mainObjData
    elseif mainObjData[subObjId] then
        error("Duplicate objId ("..subObjId.Value..") for property: "..propertyName, 2)
    end

    mapIdToTypeName(mainObjId, mainObjSuffix)
    mainObjData[subObjId] = value
end

local function activate(self)
    for propertyName, propertyData in next, allPropertyData do
        self.namespace = self.namespace + propertyName

        ---@param instance Barotrauma.AIObjective
        ---@param ptable Barotrauma.LuaCsHook.ParameterTable
        local function objPatch(instance, ptable)
            local value = propertyData[instance.Identifier]

            if value ~= nil then
                ptable.PreventExecution = true
                return value
            end
        end
        local propertyNameTemp = "get_"..propertyName
        local baseObjPatched = false

        for objId in next, propertyData do
            self.namespace = self.namespace + objId.Value
            if  not pcall(self.AddPatch, self, objIdToTypeName[objId], propertyNameTemp, nil, objPatch, Hook.HookMethodType.Before) and
                not baseObjPatched
            then
                self.namespace = (-self.namespace) + "Base"
                self:AddPatch("Barotrauma.AIObjective", propertyNameTemp, nil, objPatch, Hook.HookMethodType.Before)
                baseObjPatched = true
            end
            self.namespace = -self.namespace
        end
        self.namespace = -self.namespace
    end

    self.namespace = self.namespace + "Sub"
    for propertyName, mainSubPropertyData in next, allMainSubPropertyData do
        self.namespace = self.namespace + propertyName

        ---@param instance Barotrauma.AIObjective
        ---@param ptable Barotrauma.LuaCsHook.ParameterTable
        local function objPatch(instance, ptable)
            local mainObjData = mainSubPropertyData[instance.Identifier]

            if mainObjData then
                local curSubObj = instance.CurrentSubObjective

                if curSubObj then
                    local value = mainObjData[curSubObj.Identifier]

                    if value ~= nil then
                        ptable.PreventExecution = true
                        return value
                    end
                end
            end
        end
        local propertyNameTemp = "get_"..propertyName
        local baseObjPatched = false
        
        for mainObjId in next, mainSubPropertyData do
            self.namespace = self.namespace + mainObjId.Value
            if  not pcall(self.AddPatch, self, objIdToTypeName[mainObjId], propertyNameTemp, nil, objPatch, Hook.HookMethodType.Before) and
                not baseObjPatched
            then
                self.namespace = (-self.namespace) + "Base"
                self:AddPatch("Barotrauma.AIObjective", propertyNameTemp, nil, objPatch, Hook.HookMethodType.Before)
                baseObjPatched = true
            end
            self.namespace = -self.namespace
        end
        self.namespace = -self.namespace
    end
    self.namespace = -self.namespace
    



    -- self:AddPatch("Barotrauma.AIObjective", "get_ConcurrentObjectives", nil,
    -- function(instance, ptable)
    --     local subObj = concObj[instance.Identifier]

    --     if subObj then
    --         local curSubObj = instance.CurrentSubObjective

    --         if  curSubObj and
    --             subObj[curSubObj.Identifier]
    --         then
    --             ptable.PreventExecution = true
    --             return true
    --         end
    --     end
    -- end, Hook.HookMethodType.Before)
end

---@param self Types.Module
local function deactivate(self)
    local ClearTable = util.itertools.ClearTable

    ClearTable(objIdToTypeName)
    ClearTable(allPropertyData)
    ClearTable(allMainSubPropertyData)
end

return Types.CommonModule.new(activate, deactivate), mod