local SBAI = require("SBAI.Shared.SBAI")

if SERVER or Game.IsSingleplayer then
    SBAI.Server.Activate()
    -- require("SBAI.Server.networking")

    -- SBAI.Control.Activate()
end

if CLIENT or Game.IsSingleplayer then
    SBAI.Client.Activate()
    -- Activate = require("SBAI.Client.configGui")

    -- Activate(SBAI.namespace, Config.data)
end