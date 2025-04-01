local SBAI = require("SBAI")
local Config = require("SBAI.config")
local Network = {}

---@enum NetworkMsg
Network.NETWORK_MSG = {
    ConfigUpdate=SBAI.namespace..".ConfigUpdate",
    ConfigRequest=SBAI.namespace..".ConfigRequest"
}

---@return string
function Network.SerializeConfig()
    return json.serialize(Config.data)
end

---@param message Barotrauma.Networking.IReadMessage
function Network.UnserializeConfig(message)
    Config.data = json.parse(message.ReadString())
    Config.Save()
    SBAI.Control.Reactivate()
end

return Network