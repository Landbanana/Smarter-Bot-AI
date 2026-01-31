local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

local resetTurret do
    local Vector2 = Vector2

    local xPath = util.xPath

    ---@param instance Barotrauma.Items.Components.Turret
    function resetTurret(instance)
        local xElement = instance.Item.Prefab.ConfigElement.Element
        
        for turretElement in xPath(xElement, "[@identifier="..instance.Item.Prefab.Identifier.Value.."]//Turret") do
            local prefabPitchSlideAttribute = turretElement.Attribute("ChargeSoundWindupPitchSlide")

            if prefabPitchSlideAttribute then
                local x, y = prefabPitchSlideAttribute.Value:match("^([^,]+),([^,]+)$")

                if  x ~= nil and
                    y ~= nil
                then
                    instance.ChargeSoundWindupPitchSlide = Vector2(tonumber(x), tonumber(y)) end
            end
        end
    end
end

---@param self Types.Module
---@param options table
local function activatePreSpinTurrets(self, options)
    local muteV2 = Vector2(0.25, 0.25)
    
    local reduceNoise = options["reduceNoise"] --[[@type boolean]]
    
    if reduceNoise then
        self:AddPatch("Barotrauma.Items.Components.Turret", "Update", nil,
        function(instance, ptable)
            if instance.MaxChargeTime > 0.0 then
                local user = instance.ActiveUser

                if user then
                    if user.IsBot then
                        instance.ChargeSoundWindupPitchSlide = muteV2
                    else
                        resetTurret(instance)
                    end
                end
            end
        end, Hook.HookMethodType.Before)
    end
end

---@param self Types.Module
local function activate(self)
    self:DoOption("PreSpinTurrets", activatePreSpinTurrets)
end

---@param self Types.Module
local function deactivate(self)
    local Turret = Components.Turret

    for item in Item.ItemList do
        local turret = item.GetComponent(Turret) --[[@type Barotrauma.Items.Components.Turret]]

        if  turret and
            turret.MaxChargeTime > 0.0
        then
            resetTurret(turret)
        end
    end
end

return Types.Module.new(activate, deactivate)