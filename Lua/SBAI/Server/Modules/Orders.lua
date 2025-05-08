
local Types = require("SBAI.Shared.types")

local activateShared, deactivateShared, ID_ORDER = require("SBAI.Shared.Modules.Orders")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Hull"], "avoidStaying")

local IGNORE_ROOM = ID_ORDER.IGNORE_ROOM
local FABRICATE_ITEMS = ID_ORDER.FABRICATE_ITEMS
local PERFORM = ID_ORDER.PERFORM
local SBAI_CATEGORY = ID_ORDER.SBAI_CATEGORY
local UNIGNORE_ROOM = ID_ORDER.UNIGNORE_ROOM

---@param self Types.Module
local function activate(self)
    local ignoredHulls = activateShared(self)


    
    -- self:RegisterStrongRef("Game.GameSession.CrewManager", "ActiveOrders", "System.Collections.Generic.List`1[[Barotrauma.CrewManager+ActiveOrder]]", true, false,
    -- function(activeOrders)
    --     for activeOrder in activeOrders do
    --         local curOrder = activeOrder.Order --[[@type Barotrauma.Order]]
    
    --         if curOrder.Identifier == IGNORE_ROOM then
    --             ignoredHulls:Add(curOrder.TargetEntity)
    --         end
    --     end
    -- end)

    -- self:AddInit(
    -- function()
    --     local session = Game.GameSession

    --     if not session then return end
    --     activeOrders = GetStrongRef(function() return session.CrewManager.ActiveOrders end,
    --     "System.Collections.Generic.List`1[[Barotrauma.CrewManager+ActiveOrder]]")

    --     for activeOrder in activeOrders do
    --         local curOrder = activeOrder.Order --[[@type Barotrauma.Order]]

    --         if curOrder.Identifier == IGNORE_ROOM then
    --             ignoredHulls:Add(curOrder.TargetEntity)
    --         end
    --     end
    -- end)

    self:AddPatch("Barotrauma.Hull", "get_AvoidStaying", nil,
    function(instance, ptable)
        ptable.PreventExecution = true
        return instance.avoidStaying or instance.IsWetRoom or (ignoredHulls[instance] ~= nil)
    end, Hook.HookMethodType.Before)

    self:AddPatch("Barotrauma.AIObjectiveOperateItem", "get_AllowAutomaticItemUnequipping", nil,
    function(instance, ptable)
        if instance.Identifier == PERFORM then
            ptable.PreventExecution = true
            return false
        end
    end, Hook.HookMethodType.Before)

    self:AddPatch("Barotrauma.AIObjectiveOperateItem", "get_AllowMultipleInstances", nil,
    function(instance, ptable)
        if instance.Identifier == PERFORM then
            ptable.PreventExecution = true
            return false
        end
    end, Hook.HookMethodType.Before)

    

    -- self:AddPatch("Barotrauma.AIObjectiveOperateItem", ".ctor", nil,
    -- function(instance, ptable)
    
    -- end, Hook.HookMethodType.Before)
end

return Types.Module.new(activate, Game.IsMultiplayer and deactivateShared or nil)