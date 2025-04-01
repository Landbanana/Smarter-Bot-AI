local SBAI = require("SBAI")
local Config = require("SBAI.config")
local Network = setmetatable({}, {__index=require("SBAI.Shared.networking")})

---@param client Barotrauma.Networking.Client
function Network.SendConfig(client)
    local message = Networking.Start(Network.NETWORK_MSG.ConfigUpdate)

    message.WriteString(Network.SerializeConfig())
    networking.Send(message, client and client.Connection or nil)
end

Networking.Receive(Network.NETWORK_MSG.ConfigUpdate,
---@param message Barotrauma.Networking.IReadMessage
---@param client Barotrauma.Networking.Client
function(message, client)
    if not client.HasPermission(ClientPermissions.ManageSettings) then return end

    Network.UnserializeConfig(message)
end)

Networking.Receive(Network.NETWORK_MSG.ConfigRequest,
---@param _ Barotrauma.Networking.IReadMessage
---@param client Barotrauma.Networking.IReadMessage
function(_, client)
    if not sender then return end

    Network.SendConfig(client)
end)

return Network