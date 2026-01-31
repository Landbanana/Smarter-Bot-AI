local Constants = require("SBAI.Shared.constants")
local Types = require("SBAI.Shared.types")

local networking = {}

do
    local Acronym = Constants.Acronym

    ---@enum MSG
    networking.MSG = {
        CONF_UPDATE=Acronym..".CONF_UPDATE",
        CONF_REQUEST=Acronym..".CONF_REQUEST",
        ORDER_UPDATE=Acronym..".ORDER_UPDATE",
        ORDER_REQUEST=Acronym..".ORDER_REQUEST"
    }
end

networking.member = Types.NetworkMember.new()

return networking