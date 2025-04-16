SBAI = require("SBAI")

if SERVER or Game.IsSingleplayer then
    SBAI.Control.Activate()
end

if CLIENT or Game.IsSingleplayer then
    local Activate = require("SBAI.Client.configGui")

    Activate(SBAI.namespace)
end