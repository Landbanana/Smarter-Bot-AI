local Constants = require("SBAI.Shared.constants")
local Types = require("SBAI.Shared.types")

local activateShared, deactivateShared = table.unpack(require("SBAI.Shared.Modules.Orders"))

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Hull"], "avoidStaying")

local ID_ORDER = Constants.ID_ORDER

local IGNORE_ROOM = ID_ORDER.IGNOREROOM
local FABRICATE_ITEMS = ID_ORDER.FABRICATEITEMS
local PERFORM = ID_ORDER.PERFORM
local SBAI_CATEGORY = ID_ORDER.SBAICATEGORY
local UNIGNORE_ROOM = ID_ORDER.UNIGNORE_ROOM

---@param self Types.Module
local function activateFollowOrder(self)
    
end

---@param self Types.Module
local function activateIgnoreRoomOrder(self)
    local ignoredHulls = activateShared(self)

    self:AddPatch("Barotrauma.Hull", "get_AvoidStaying", nil,
    function(instance, ptable)
        ptable.PreventExecution = true
        return instance.avoidStaying or instance.IsWetRoom or (ignoredHulls[instance] ~= nil)
    end, Hook.HookMethodType.Before)
end

---@param self Types.Module
local function activatePerformOrder(self)
    self:AddCommonModule("SBAI.Server.CommonModules.PerformInstruments")
end

---@param self Types.Module
local function activate(self)
    activateIgnoreRoomOrder(self)
    activatePerformOrder(self)
end

return Types.Module.new(activate, deactivateShared)