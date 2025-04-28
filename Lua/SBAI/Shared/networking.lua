local Constants = require("SBAI.Shared.constants")
local Types = require("SBAI.Shared.types")

local networking = {}

do
    local Acronym = Constants.Acronym

    ---@enum MSG
    networking.MSG = {
        CONF_UPDATE=Acronym..".CONF_UPDATE",
        CONF_REQUEST=Acronym..".CONF_REQUEST"
    }
end

if  SERVER and
    Game.IsMultiplayer
then
    local registerId = Networking.RegisterId

    for k in next, networking.MSG do
        registerId(k)
    end
end

networking.member = Types.NetworkMember.new()

return networking