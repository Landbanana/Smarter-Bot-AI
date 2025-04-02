local P = setmetatable({}, {__index=require("SBAI.Shared.networking")})

function P.SendConfig()
    local message = Networking.Start(P.NETWORK_MSG.ConfigUpdate)

    message.WriteString(P.SerializeConfig())
    Networking.Send(message)
end

function P.RequestConfig()
    Networking.Send(Networking.Start(P.NETWORK_MSG.ConfigRequest))
end

Networking.Receive(P.NETWORK_MSG.ConfigUpdate,
---@param message Barotrauma.Networking.IReadMessage
function(message)
	P.UnserializeConfig(message)
end)

return P