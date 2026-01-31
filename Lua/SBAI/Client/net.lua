---@class (partial) Net
local Net = require("SBAI.Shared.net")

Net.init = Functools.partial3(Net.writeSend,"INIT", nil, SBAI.Version)

do
    local Reliable = DeliveryMethod.Reliable
    local Send = Networking.Send

    ---@public
    ---@param msg Barotrauma.Networking.IWriteMessage
    function Net.send(msg)
        return Send(msg, Reliable)
    end
end

do
    local stop = Net.stop

    Net.register("DEAD",
    function(msg, client)
        return stop()
    end)
end

return Net