local P = setmetatable({}, {__index=require("SBAI.Shared.networking")})

---@param client Barotrauma.Networking.Client
function P.SendConfig(client)
    local message = Networking.Start(P.NETWORK_MSG.ConfigUpdate)

    message.WriteString(P.SerializeConfig())
    Networking.Send(message, client and client.Connection or nil)
end

Networking.Receive(P.NETWORK_MSG.ConfigUpdate,
---@param message Barotrauma.Networking.IReadMessage
---@param client Barotrauma.Networking.Client
function(message, client)
    if not client.HasPermission(ClientPermissions.ManageSettings) then return end

    P.UnserializeConfig(message)
end)

Networking.Receive(P.NETWORK_MSG.ConfigRequest,
---@param _ Barotrauma.Networking.IReadMessage
---@param client Barotrauma.Networking.IReadMessage
function(_, client)
    if not client then return end

    P.SendConfig(client)
end)

return P