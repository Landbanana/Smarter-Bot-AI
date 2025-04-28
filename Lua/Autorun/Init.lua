SBAI = require("SBAI")
local Config = require("SBAI.Shared.config")
local networking = require("SBAI.Shared.networking")

if  SERVER or
    Game.IsSingleplayer
then
    SBAI.Control.Activate()
end

if  CLIENT or
    Game.IsSingleplayer
then
    require("SBAI.Client.configGui")(SBAI.namespace)
end