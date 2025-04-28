SBAI = require("SBAI")

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