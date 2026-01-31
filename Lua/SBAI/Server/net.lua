---@class (partial) Net
local Net = require("SBAI.Shared.net")

Net.init = Functools.partial2(Net.writeSend,"INIT", nil) ---@type fun() ---@public

do
    local Reliable = DeliveryMethod.Reliable
    local Send = Networking.Send

    ---@public
    ---@param msg Barotrauma.Networking.IWriteMessage
    ---@param client? Barotrauma.Networking.Client
    function Net.send(msg, client)
        return Send(msg, client ~= nil and client.Connection or nil, Reliable)
    end
end

do
    local Version = SBAI.Version

    local logWarn = Errortools.logWarn
    local writeSend = Net.writeSend

    Net.register("INIT",
    function(msg, client)
        local clientVersion = msg.ReadString()

        if clientVersion ~= Version then
            writeSend("DEAD", client)
            return logWarn("Client '%s' has a different SBAI mod Version (%s) than the Server (%s). All Smarter Bot AI mod networking has been suspended for this Client!",
                client.Character.LogName, clientVersion, Version)
        end
    end)
end

return Net