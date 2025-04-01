local SBAI = require("SBAI")
local Network = require("SBAI.Shared.networking")

function Network.SendConfig()
    local message = Networking.Start(Network.NETWORK_MSG.ConfigUpdate)

    message.WriteString(Network.SerializeConfig())
    networking.Send(message)
end

function Network.RequestConfig()
    Networking.Send(Networking.Start(Network.NETWORK_MSG.ConfigRequest))
end

Networking.Receive(Network.NETWORK_MSG.ConfigUpdate,
---@param message Barotrauma.Networking.IReadMessage
function(message)
	Network.UnserializeConfig(message)
end)

return Network