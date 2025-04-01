local SBAI = require("SBAI")

if SERVER or Game.IsSingleplayer then
    require("SBAI.Server.networking")

    SBAI.Control.Activate()
end

if CLIENT or Game.IsSingleplayer then
    Activate = require("SBAI.Client.configGui")

    Activate(SBAI.namespace, SBAI.Config.data)
end